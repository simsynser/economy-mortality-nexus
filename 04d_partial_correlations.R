# 04d_partial_correlations.R — Partial Correlation Analysis (Section 3.2)
# ============================================================================
# Purpose: Demonstrate mediator suppression effects through partial correlations
#          showing how controlling for mediator variables strengthens relationships
#
# Dependencies: df_complete_all_analysis.csv (from 03_analysis.R)
# Outputs: partial_correlations_results.csv, mediator_suppression_summary.csv
#
# Paper Reference: Section 3.2 - Main effects of mediator variables
# ============================================================================

source(here::here("00_library_loader.R"))

# ---- Data Loading & Validation ----
complete_cases_file <- here::here("data_manipulated", "df_complete_all_analysis.csv")
out_dir <- here::here("outputs")

stopifnot(file.exists(complete_cases_file))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load complete cases dataset
df_complete_all <- readr::read_csv(complete_cases_file, show_col_types = FALSE)

# ---- Helper Function ----
# Calculate both bivariate and partial correlations for comparison
calc_bivariate_partial <- function(data, var1, var2, control_var, analysis_name) {
  # Bivariate correlation (no control)
  bivariate <- cor.test(data[[var1]], data[[var2]], method = "pearson")

  # Partial correlation (controlling for third variable)
  partial <- pcor.test(data[[var1]], data[[var2]], data[[control_var]])

  list(
    analysis = analysis_name,
    var1 = var1,
    var2 = var2,
    control_var = control_var,
    n = nrow(data),
    bivariate_r = round(bivariate$estimate, 3),
    bivariate_p = bivariate$p.value,
    partial_r = round(partial$estimate, 3),
    partial_p = partial$p.value,
    effect_strength = abs(partial$estimate) - abs(bivariate$estimate),
    suppression_detected = abs(partial$estimate) > abs(bivariate$estimate)
  )
}

# ---- Core Partial Correlation Analyses ----
# 1. UHC on Mortality, controlling for Age
uhc_mort_control_age <- calc_bivariate_partial(
  df_complete_all, "uhc", "excess_mort", "median_age",
  "UHC on Mortality (control: Age)"
)

# 2. Vaccination on Mortality, controlling for Age
vacc_mort_control_age <- calc_bivariate_partial(
  df_complete_all, "vacc", "excess_mort", "median_age",
  "Vaccination on Mortality (control: Age)"
)

# 3. Age on Mortality, controlling for UHC
age_mort_control_uhc <- calc_bivariate_partial(
  df_complete_all, "median_age", "excess_mort", "uhc",
  "Age on Mortality (control: UHC)"
)

# 4. Age on Mortality, controlling for Vaccination
age_mort_control_vacc <- calc_bivariate_partial(
  df_complete_all, "median_age", "excess_mort", "vacc",
  "Age on Mortality (control: Vaccination)"
)

# ---- Combine Results ----
partial_results <- list(
  uhc_mort_control_age,
  vacc_mort_control_age,
  age_mort_control_uhc,
  age_mort_control_vacc
)

# Convert to data frame for analysis and export
partial_df <- do.call(rbind, lapply(partial_results, function(x) {
  data.frame(
    analysis = x$analysis,
    var1 = x$var1,
    var2 = x$var2,
    control_var = x$control_var,
    n = x$n,
    bivariate_r = x$bivariate_r,
    bivariate_p = round(x$bivariate_p, 4),
    partial_r = x$partial_r,
    partial_p = round(x$partial_p, 4),
    effect_strength_increase = round(x$effect_strength, 3),
    suppression_detected = x$suppression_detected,
    stringsAsFactors = FALSE
  )
}))

# ---- Generate Summary Table for Paper ----
paper_summary <- data.frame(
  relationship = c(
    "Vaccination → Mortality",
    "UHC → Mortality",
    "Age → Mortality (control: UHC)",
    "Age → Mortality (control: Vaccination)"
  ),
  no_control = c(
    paste0("r = ", partial_df$bivariate_r[2], ", p ", ifelse(partial_df$bivariate_p[2] < 0.001, "<.001",
      ifelse(partial_df$bivariate_p[2] < 0.01, "<.01", "<.05")
    )),
    paste0("r = ", partial_df$bivariate_r[1], ", p ", ifelse(partial_df$bivariate_p[1] < 0.01, "<.01", "<.05")),
    paste0("r = ", partial_df$bivariate_r[3], ", p ", ifelse(partial_df$bivariate_p[3] < 0.05, "<.05", "ns")),
    paste0("r = ", partial_df$bivariate_r[4], ", p ", ifelse(partial_df$bivariate_p[4] < 0.05, "<.05", "ns"))
  ),
  with_control = c(
    paste0("r = ", partial_df$partial_r[2], ", p<.001 (age control)"),
    paste0("r = ", partial_df$partial_r[1], ", p<.001 (age control)"),
    paste0("r = ", partial_df$partial_r[3], ", p<.001 (UHC control)"),
    paste0("r = ", partial_df$partial_r[4], ", p<.001 (vaccination control)")
  ),
  effect_change = c(
    paste0("+", round(abs(partial_df$partial_r[2]) - abs(partial_df$bivariate_r[2]), 3)),
    paste0("+", round(abs(partial_df$partial_r[1]) - abs(partial_df$bivariate_r[1]), 3)),
    paste0("+", round(abs(partial_df$partial_r[3]) - abs(partial_df$bivariate_r[3]), 3)),
    paste0("+", round(abs(partial_df$partial_r[4]) - abs(partial_df$bivariate_r[4]), 3))
  ),
  stringsAsFactors = FALSE
)

# ---- Export Results ----
readr::write_csv(partial_df, file.path(out_dir, "partial_correlations_results.csv"))
readr::write_csv(paper_summary, file.path(out_dir, "mediator_suppression_summary.csv"))
message("Analysis complete - results saved to outputs/")
