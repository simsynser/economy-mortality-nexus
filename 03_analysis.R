# 03_analysis.R — Correlations & Complete-Case
# ---------------------------------------------------------------
# Awaits: Object `dat` from 02_clean.R.
# Outputs:
#   - ready_to_import/data_manipulated/analysis_correlations.csv
#   - ready_to_import/data_manipulated/analysis_complete_cases.csv
source(here::here("ready_to_import", "00_library_loader.R"))


# ---- Helper ----
map_iso3 <- function(x) {
  suppressWarnings(countrycode(
    x, "country.name", "iso3c",
    custom_match = c("Kosovo" = "XKX", "Micronesia (country)" = "FSM", "Virgin Islands" = "VIR", "Saint Martin" = "MAF")
  ))
}

pull_opt <- function(df, candidates) {
  for (nm in candidates) if (nm %in% names(df)) {
    return(df[[nm]])
  }
  return(rep(NA, nrow(df)))
}

std_cols <- function(df) {
  if (!"iso3c" %in% names(df)) {
    ent_col <- intersect(c("Entity", "entity", "country", "Country"), names(df))[1]
    if (!is.na(ent_col)) df$iso3c <- map_iso3(df[[ent_col]])
  }
  if (!"iso3c" %in% names(df)) stop("iso3c fehlt und konnte nicht abgeleitet werden.")

  tibble::tibble(
    iso3c       = df$iso3c,
    median_age  = pull_opt(df, "median_age"),
    gdp         = pull_opt(df, c("gdp", "GDP per capita, PPP (constant 2017 international $)")),
    uhc         = pull_opt(df, c("uhc", "UHC service coverage index")),
    vacc        = suppressWarnings(as.numeric(pull_opt(df, c("vacc", "vacc_per_100", "COVID-19 doses (cumulative, per hundred)")))),
    excess_mort = suppressWarnings(as.numeric(pull_opt(df, c("excess_mort", "cum_excess_per_million_proj_all_ages")))),
    vax_day     = suppressWarnings(as.Date(pull_opt(df, c("vax_day", "Day", "Day_near", "Day_max"))))
  ) %>% dplyr::distinct(iso3c, .keep_all = TRUE)
}

dat_std <- std_cols(dat)

calc_cor_and_lost <- function(df, xvar, yvar) {
  total_count <- nrow(df)
  df_sub <- df[, c(xvar, yvar)]
  df_cc <- df_sub[stats::complete.cases(df_sub), ]
  n_used <- nrow(df_cc)

  if (n_used < 2) {
    return(data.frame(
      xvar = xvar, yvar = yvar, n_total = total_count,
      lost_count_na = total_count - n_used, n_used = n_used,
      pearson = NA_real_, spearman = NA_real_, message = "N<2",
      stringsAsFactors = FALSE
    ))
  }

  data.frame(
    xvar = xvar, yvar = yvar, n_total = total_count,
    lost_count_na = total_count - n_used, n_used = n_used,
    pearson = round(cor(df_cc[[xvar]], df_cc[[yvar]], method = "pearson"), 3),
    spearman = round(cor(df_cc[[xvar]], df_cc[[yvar]], method = "spearman"), 3),
    message = "OK",
    stringsAsFactors = FALSE
  )
}

# ---- Correlations ----
pairs <- list(
  c("gdp", "median_age"),
  c("gdp", "vacc"),
  c("gdp", "uhc"),
  c("median_age", "excess_mort"),
  c("vacc", "excess_mort"),
  c("uhc", "excess_mort")
)

res_list <- lapply(pairs, function(p) calc_cor_and_lost(dat_std, p[1], p[2]))
results_df <- do.call(rbind, res_list)

# ---- Complete-case ----
df_complete_all <- dat_std %>%
  dplyr::filter(!is.na(gdp), !is.na(median_age), !is.na(vacc), !is.na(uhc), !is.na(excess_mort)) %>%
  dplyr::mutate(continent = countrycode(iso3c, "iso3c", "continent"))

# ---- Outputs ----
out_dir <- here("ready_to_import", "data_manipulated")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
readr::write_csv(results_df, file.path(out_dir, "analysis_correlations.csv"))
readr::write_csv(df_complete_all, file.path(out_dir, "analysis_complete_cases.csv"))
