# 02_clean.R — Excess Mortality Estimation & Dataset Integration (GAM-Only)
# ============================================================================
# Purpose: Estimate country-level excess mortality at standardized date (2023-05-05)
#          using GAM modeling only, ensuring methodological consistency
#
# Methodological Improvements:
# - Robust error handling prevents pipeline interruption when GAM fitting fails
# - Direct date prediction eliminates indexing errors in temporal alignment
# - Consistent GAM methodology ensures all estimates use identical smoothing approach
#
# Dependencies (from 01_loader.R):
# - Objects: age_median, age_65plus, gdp_data_clean, essential_health_data_clean,
#            vaccination_data_clean, excess_dat
#
# Outputs:
# - mortality_gam_2023-05-05.csv: Country-level excess mortality estimates (GAM-only)
# - analysis_table.csv: Integrated dataset for correlation analysis
# - gam_processing_summary.csv: Processing results summary
#
# Methodological Notes:
# - Only uses cubic spline GAM estimates y ~ s(x, bs="cs")
# - Countries requiring fallback methods are excluded for consistency
# - Target date (2023-05-05) chosen per WHO/OWID temporal standardization guidelines
# ============================================================================

source(here::here("00_library_loader.R"))

library(aods3)

# Verify required objects from loader
stopifnot(
  exists("excess_dat"), exists("vaccination_data_clean"),
  exists("age_median"), exists("age_65plus"),
  exists("gdp_data_clean"), exists("essential_health_data_clean")
)

TARGET_DATE <- as.Date("2023-05-05")

# ---- GAM-Only Estimation Function -------------------------------------------
# Estimates excess mortality using GAM only - returns NA for non-GAM cases
# Ensures methodological consistency by excluding fallback methods
est_excess_gam_only <- function(df, target = TARGET_DATE) {
  # Clean and prepare time series data
  df <- df %>%
    dplyr::filter(!is.na(Day), !is.na(cum_excess_per_million_proj_all_ages)) %>%
    dplyr::mutate(
      Day = as.Date(Day),
      x   = as.numeric(Day),
      y   = cum_excess_per_million_proj_all_ages
    )

  # Insufficient data - exclude from analysis
  if (nrow(df) == 0) {
    return(tibble::tibble(value = NA_real_, ci_low =  NA_real_, ci_up =  NA_real_, method = "no_data"))
  }

  # Insufficient unique time points for GAM - exclude from analysis
  n_uniq <- length(unique(df$x))
  if (n_uniq < 3L) {
    return(tibble::tibble(value = NA_real_, ci_low =  NA_real_, ci_up =  NA_real_, method = "insufficient_data"))
  }

  # Attempt GAM fitting with dynamic k parameter
  k_val <- max(3L, min(10L, n_uniq - 1L))
  fit <- try(mgcv::gam(y ~ s(x, bs = "cs", k = k_val), data = df), silent = TRUE)

  # GAM fitting failed - exclude from analysis
  if (inherits(fit, "try-error")) {
    return(tibble::tibble(value = NA_real_, ci_low =  NA_real_, ci_up =  NA_real_, method = "gam_failed"))
  }

  # Target date outside observed range - exclude from analysis
  # (avoids extrapolation beyond data support)
  if (target < min(df$Day) || target > max(df$Day)) {
    return(tibble::tibble(value = NA_real_, ci_low =  NA_real_, ci_up =  NA_real_, method = "outside_range"))
  }

  # Successful GAM prediction within observed range
  pred <- mgcv::predict.gam(fit, newdata = data.frame(x = as.numeric(target)), se.fit = TRUE)
  return(tibble::tibble(value = as.numeric(pred$fit),ci_low = (pred$fit - (1.96 * pred$se.fit)), ci_up = (pred$fit + (1.96 * pred$se.fit)),  method = "gam_success"))   #
}

# ---- Process Excess Mortality Data (GAM-Only) -------------------------------
message("[02_clean] Processing excess mortality data with GAM-only estimation...")

# Apply GAM estimation to all countries and track processing results
mortality_processing <- excess_dat %>%
  dplyr::mutate(Day = as.Date(Day)) %>%
  dplyr::group_by(Entity) %>%
  dplyr::group_modify(~ est_excess_gam_only(.x, TARGET_DATE)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(iso3c = map_iso3(Entity))

# Summarize processing results for transparency
processing_summary <- mortality_processing %>%
  dplyr::count(method, name = "countries") %>%
  dplyr::mutate(percentage = round(100 * countries / sum(countries), 1))

message("[02_clean] GAM Processing Summary:")
for (i in seq_len(nrow(processing_summary))) {
  method <- processing_summary$method[i]
  count <- processing_summary$countries[i]
  pct <- processing_summary$percentage[i]
  message("  - ", method, ": ", count, " countries (", pct, "%)")
}

# Keep only successful GAM estimates for analysis
mortality_data_clean <- mortality_processing %>%
  dplyr::filter(method == "gam_success", !is.na(iso3c), !is.na(value)) %>%
  dplyr::transmute(
    iso3c,
    cum_excess_per_million_proj_all_ages = value,
    low = ci_low,
    up = ci_up
  )

message("[02_clean] Successfully processed ", nrow(mortality_data_clean), " countries with GAM estimates")

# ---- Integrate All Datasets --------------------------------------------------
# Full joins preserve all available country data across datasets
# Only countries with GAM mortality estimates will have complete records
dat <- age_median %>%
  dplyr::full_join(age_65plus, by = "iso3c") %>%
  dplyr::full_join(
    vaccination_data_clean %>%
      dplyr::transmute(iso3c, vax_day = Day, vacc = vacc_per_100),
    by = "iso3c"
  ) %>%
  dplyr::full_join(
    mortality_data_clean %>%
      dplyr::transmute(iso3c, excess_mort = cum_excess_per_million_proj_all_ages),
    by = "iso3c"
  ) %>%
  dplyr::full_join(
    essential_health_data_clean %>%
      dplyr::transmute(iso3c, uhc = `UHC service coverage index`),
    by = "iso3c"
  ) %>%
  dplyr::full_join(
    gdp_data_clean %>%
      dplyr::transmute(iso3c, gdp = `GDP per capita, PPP (constant 2017 international $)`),
    by = "iso3c"
  )

# ---- Export Results -----------------------------------------------------------
out_dir <- here::here("data_manipulated")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Export GAM-only mortality estimates
readr::write_csv(
  mortality_data_clean,
  file.path(out_dir, "mortality_gam_2023-05-05.csv")
)

# Export processing summary for transparency
readr::write_csv(
  processing_summary,
  file.path(out_dir, "gam_processing_summary.csv")
)

# Export integrated analysis table
readr::write_csv(
  dat,
  file.path(out_dir, "analysis_table.csv")
)

# ---- Summary Statistics -------------------------------------------------------
n_countries_total <- dplyr::n_distinct(dat$iso3c, na.rm = TRUE)
n_complete_cases <- dat %>%
  dplyr::filter(
    !is.na(gdp), !is.na(median_age), !is.na(age_65plus), !is.na(vacc),
    !is.na(uhc), !is.na(excess_mort)
  ) %>%
  nrow()

gam_success_rate <- processing_summary %>%
  dplyr::filter(method == "gam_success") %>%
  dplyr::pull(percentage)
