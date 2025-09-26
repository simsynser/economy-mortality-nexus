# 03_analysis.R — Correlation Analysis & Complete Cases Assessment
# -------------------------------------------------------------------------
# Purpose: Analyze pairwise correlations between key COVID-19 related variables
# and identify countries with complete data for downstream analysis
#
# Inputs:  analysis_table.csv (from 02_clean.R)
# Outputs: analysis_correlations.csv, analysis_complete_cases.csv, df_complete_all_analysis.csv
# -------------------------------------------------------------------------

# ---- Setup & Data Loading ------------------------------------------------
source(here::here("00_library_loader.R"))

in_file <- here::here("data_manipulated", "analysis_table.csv")
out_dir <- here::here("data_manipulated")

stopifnot(file.exists(in_file))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

dat <- readr::read_csv(in_file, show_col_types = FALSE)

# Validate required columns are present
required_cols <- c("iso3c", "median_age", "gdp", "uhc", "vacc", "excess_mort")
missing_cols <- setdiff(required_cols, names(dat))
if (length(missing_cols)) {
  stop("analysis_table.csv misses: ", paste(missing_cols, collapse = ", "))
}

# ---- Helper: Pairwise Correlation with Missing Data Transparency ---------
# This function computes correlations while explicitly tracking data loss due to NAs
# Returns both Pearson (assumes normality) and Spearman (rank-based)
calc_cor_and_lost <- function(df, xvar, yvar) {
  total_count <- nrow(df)

  # Extract only the two variables of interest
  df_sub <- df[, c(xvar, yvar)]

  # Pairwise complete case deletion (standard for correlation analysis)
  df_sub_complete <- df_sub[complete.cases(df_sub), ]
  complete_count <- nrow(df_sub_complete)
  lost_count_na <- total_count - complete_count

  # Correlation requires at least 2 complete observations
  if (complete_count < 2) {
    return(list(
      xvar = xvar,
      yvar = yvar,
      n_total = total_count,
      lost_count_na = lost_count_na,
      n_used = complete_count,
      pearson = NA,
      spearman = NA,
      message = "Not enough points for correlation!"
    ))
  }

  # Compute both parametric and non-parametric correlations
  pearson <- cor(df_sub_complete[[xvar]], df_sub_complete[[yvar]], method = "pearson")
  spearman <- cor(df_sub_complete[[xvar]], df_sub_complete[[yvar]], method = "spearman")

  list(
    xvar = xvar,
    yvar = yvar,
    n_total = total_count,
    lost_count_na = lost_count_na,
    n_used = complete_count,
    pearson = round(pearson, 3),
    spearman = round(spearman, 3),
    message = "OK"
  )
}

# ---- Define Variable Pairs for Analysis -----------------------------------
# Focus on theoretically meaningful relationships:
# - Development indicators (GDP) vs. health infrastructure (UHC) & demographics (age)
# - Pandemic response capacity (vaccination) vs. development
# - Health outcomes (excess mortality) vs. protective factors (age, vaccination, UHC)
pairs <- list(
  c("gdp", "median_age"), # Development-demographics relationship
  c("gdp", "vacc"), # Economic capacity-vaccination rollout
  c("gdp", "uhc"), # Economic development-health system strength
  c("median_age", "excess_mort"), # Demographic vulnerability-mortality outcomes
  c("vacc", "excess_mort"), # Vaccination coverage-mortality protection
  c("uhc", "excess_mort") # Health system strength-mortality outcomes
)

# ---- Execute Pairwise Correlation Analysis --------------------------------
results_list <- lapply(pairs, function(vars) {
  xvar <- vars[1]
  yvar <- vars[2]

  res <- calc_cor_and_lost(dat, xvar, yvar)
  res
})

# Convert list to data frame for export and further analysis
results_df <- do.call(
  rbind,
  lapply(results_list, function(x) {
    data.frame(
      xvar = x$xvar,
      yvar = x$yvar,
      n_total = x$n_total,
      lost_count_na = x$lost_count_na,
      n_used = x$n_used,
      pearson = x$pearson,
      spearman = x$spearman,
      message = x$message,
      stringsAsFactors = FALSE
    )
  })
)

print(results_df)
readr::write_csv(results_df, file.path(out_dir, "analysis_correlations.csv"))

# ---- Complete Cases Analysis ---------------------------------------------
# Identify countries with complete data across all key variables
# These form the analytical sample for multivariate analysis
df_complete_all <- dat %>%
  filter(
    !is.na(gdp),
    !is.na(median_age),
    !is.na(vacc),
    !is.na(uhc),
    !is.na(excess_mort)
  ) %>%
  mutate(continent = countrycode(iso3c, origin = "iso3c", destination = "continent"))

# ---- Export Complete Cases Information -----------------------------------
# Export country list for mapping/visualization purposes
readr::write_csv(
  df_complete_all %>% dplyr::select(iso3c, continent),
  file.path(out_dir, "analysis_complete_cases.csv")
)

# ---- Missing Data Summary ------------------------------------------------
# Quick diagnostic of missing data patterns
missing_counts <- c(
  excess_mort = sum(is.na(dat$excess_mort)),
  gdp = sum(is.na(dat$gdp)),
  median_age = sum(is.na(dat$median_age)),
  uhc = sum(is.na(dat$uhc)),
  vacc = sum(is.na(dat$vacc))
)

# Export full complete cases dataset for downstream analysis
readr::write_csv(df_complete_all, file.path(out_dir, "df_complete_all_analysis.csv"))