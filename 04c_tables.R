# 04c_tables.R — Tables 1 & 2 (Subgroup & GDP Threshold Analysis)
# ============================================================================
# Purpose: Replicate Table 1 (subgroup correlations) and Table 2 (GDP thresholds)
#
# Dependencies: df_complete_all_analysis.csv (from 03_analysis.R)
# Outputs: table1_subgroup_correlations.csv, table2_gdp_thresholds.csv
#
# Paper Reference: Table 1 & Table 2
# ============================================================================

source(here::here("ready_to_import", "00_library_loader.R"))

# ---- Data Loading & Validation ----
complete_cases_file <- here::here("ready_to_import", "data_manipulated", "df_complete_all_analysis.csv")
out_dir <- here::here("ready_to_import", "plots")

stopifnot(file.exists(complete_cases_file))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load complete cases dataset
df_complete_all <- readr::read_csv(complete_cases_file, show_col_types = FALSE)

message("Data loaded: ", nrow(df_complete_all), " complete cases for table analysis")

# ---- Calculate Reference Medians ----
median_age_cutoff <- median(df_complete_all$median_age)
median_uhc_cutoff <- median(df_complete_all$uhc)
median_gdp_cutoff <- median(df_complete_all$gdp)

message(
  "Reference medians - Age: ", round(median_age_cutoff, 1),
  ", UHC: ", round(median_uhc_cutoff, 1),
  ", GDP: $", scales::comma(median_gdp_cutoff)
)

# ---- Helper Functions ----
# Calculate correlation with both Pearson and Spearman, plus sample size and significance
calc_subgroup_correlation <- function(data, var1, var2) {
  # Remove countries with missing data in either variable
  clean_data <- data %>% filter(!is.na(.data[[var1]]), !is.na(.data[[var2]]))
  n <- nrow(clean_data)

  # Safety check: Need at least 3 observations for meaningful correlation
  if (n < 3) {
    return(list(pearson = NA, spearman = NA, n = n, p_pear = NA, p_spear = NA))
  }

  # Calculate both correlation types with significance tests
  pear_test <- cor.test(clean_data[[var1]], clean_data[[var2]], method = "pearson")
  spear_test <- cor.test(clean_data[[var1]], clean_data[[var2]], method = "spearman")

  # Return organized results
  list(
    pearson = round(pear_test$estimate, 3), # Correlation coefficient
    spearman = round(spear_test$estimate, 3), # Non-parametric version
    n = n, # Sample size
    p_pear = pear_test$p.value, # Significance levels
    p_spear = spear_test$p.value
  )
}

# Calculate GDP threshold correlations with significance testing
calc_gdp_threshold_correlation <- function(data, threshold, direction = "<=") {
  # Split data based on GDP threshold (<= or >)
  if (direction == "<=") {
    subset_data <- data %>% filter(gdp <= threshold)
  } else {
    subset_data <- data %>% filter(gdp > threshold)
  }

  # Remove missing values for GDP and mortality
  clean_data <- subset_data %>% filter(!is.na(gdp), !is.na(excess_mort))
  n <- nrow(clean_data)

  # Safety check: Need at least 3 observations for meaningful correlation
  if (n < 3) {
    return(list(correlation = NA, n = n, p_value = NA))
  }

  # Calculate GDP-mortality correlation for this threshold group
  cor_test <- cor.test(clean_data$gdp, clean_data$excess_mort, method = "pearson")

  list(
    correlation = round(cor_test$estimate, 3), # round to 3 decimal places
    n = n,
    p_value = cor_test$p.value
  )
}
# Format correlation with significance indicators
format_correlation_with_significance <- function(cor_val, p_val) {
  if (is.na(cor_val) || is.na(p_val)) { # Not enough data to compute
    return("NA")
  }

  stars <- ifelse(p_val <= 0.01, "*", "") # Paper uses * for p <= .01
  paste0(cor_val, stars)
}

# ---- Generate Table 1: Subgroup Correlation Analysis ----
message("\n=== Creating Table 1: Subgroup Correlations ===")

# UHC ≤ 79 vs UHC > 79: Age on Mortality
age_mort_low_uhc <- calc_subgroup_correlation(
  df_complete_all %>% filter(uhc <= median_uhc_cutoff), # 79 is median UHC in dataset
  "median_age", "excess_mort"
)

age_mort_high_uhc <- calc_subgroup_correlation(
  df_complete_all %>% filter(uhc > median_uhc_cutoff),
  "median_age", "excess_mort"
)

# Age ≤ 38 vs Age > 38: UHC on Mortality
uhc_mort_young <- calc_subgroup_correlation(
  df_complete_all %>% filter(median_age <= median_age_cutoff), # 37.7 is median age in expanded dataset
  "uhc", "excess_mort"
)

uhc_mort_old <- calc_subgroup_correlation(
  df_complete_all %>% filter(median_age > median_age_cutoff),
  "uhc", "excess_mort"
)

# Age ≤ 38 vs Age > 38: Vaccination on Mortality
vacc_mort_young <- calc_subgroup_correlation(
  df_complete_all %>% filter(median_age <= median_age_cutoff),
  "vacc", "excess_mort"
)

vacc_mort_old <- calc_subgroup_correlation(
  df_complete_all %>% filter(median_age > median_age_cutoff),
  "vacc", "excess_mort"
)

# Create Table 1 in exact paper format
table1 <- data.frame(
  Analysis_Group = c(
    paste0("UHC<=", round(median_uhc_cutoff), " (n=", age_mort_low_uhc$n, ")"),
    paste0("UHC>", round(median_uhc_cutoff), " (n=", age_mort_high_uhc$n, ")"),
    paste0("Age<=", round(median_age_cutoff), " (n=", uhc_mort_young$n, ")"),
    paste0("Age>", round(median_age_cutoff), " (n=", uhc_mort_old$n, ")"),
    paste0("Age<=", round(median_age_cutoff), " (n=", vacc_mort_young$n, ")"),
    paste0("Age>", round(median_age_cutoff), " (n=", vacc_mort_old$n, ")")
  ),
  Age_on_Mortality = c(
    paste0(
      format_correlation_with_significance(age_mort_low_uhc$pearson, age_mort_low_uhc$p_pear),
      "/", format_correlation_with_significance(age_mort_low_uhc$spearman, age_mort_low_uhc$p_spear)
    ),
    paste0(
      format_correlation_with_significance(age_mort_high_uhc$pearson, age_mort_high_uhc$p_pear),
      "/", format_correlation_with_significance(age_mort_high_uhc$spearman, age_mort_high_uhc$p_spear)
    ),
    "", "", "", ""
  ),
  UHC_on_Mortality = c(
    "", "",
    paste0(
      format_correlation_with_significance(uhc_mort_young$pearson, uhc_mort_young$p_pear),
      "/", format_correlation_with_significance(uhc_mort_young$spearman, uhc_mort_young$p_spear)
    ),
    paste0(
      format_correlation_with_significance(uhc_mort_old$pearson, uhc_mort_old$p_pear),
      "/", format_correlation_with_significance(uhc_mort_old$spearman, uhc_mort_old$p_spear)
    ),
    "", ""
  ),
  Vacc_on_Mortality = c(
    "", "", "", "",
    paste0(
      format_correlation_with_significance(vacc_mort_young$pearson, vacc_mort_young$p_pear),
      "/", format_correlation_with_significance(vacc_mort_young$spearman, vacc_mort_young$p_spear)
    ),
    paste0(
      format_correlation_with_significance(vacc_mort_old$pearson, vacc_mort_old$p_pear),
      "/", format_correlation_with_significance(vacc_mort_old$spearman, vacc_mort_old$p_spear)
    )
  ),
  stringsAsFactors = FALSE
)

# ---- Generate Table 2: GDP Threshold Analysis ----
message("\n=== Creating Table 2: GDP Threshold Analysis ===")

gdp_thresholds <- c(20000, 25000, 30000, 33000)
table2_results <- list()

for (threshold in gdp_thresholds) {
  # Countries below threshold
  below <- calc_gdp_threshold_correlation(df_complete_all, threshold, "<=")

  # Countries above threshold
  above <- calc_gdp_threshold_correlation(df_complete_all, threshold, ">")

  table2_results[[paste0("threshold_", threshold)]] <- list(
    threshold = threshold,
    below_cor = below$correlation,
    below_n = below$n,
    below_p = below$p_value,
    above_cor = above$correlation,
    above_n = above$n,
    above_p = above$p_value
  )
}

# Create Table 2
table2 <- data.frame(
  GDP_per_capita_USD = paste0(scales::comma(gdp_thresholds / 1000), ",000"),
  Below_Threshold = sapply(gdp_thresholds, function(t) {
    res <- table2_results[[paste0("threshold_", t)]]

    # Format significance: * for p≤.05, ** for p≤.01 (matching paper)
    stars <- ""
    if (!is.na(res$below_p)) {
      if (res$below_p <= 0.01) {
        stars <- "**"
      } else if (res$below_p <= 0.05) stars <- "*"
    }

    paste0(res$below_cor, stars, "/", res$below_n)
  }),
  Above_Threshold = sapply(gdp_thresholds, function(t) {
    res <- table2_results[[paste0("threshold_", t)]]

    # Format significance: * for p≤.05, ** for p≤.01 (matching paper)
    stars <- ""
    if (!is.na(res$above_p)) {
      if (res$above_p <= 0.01) {
        stars <- "**"
      } else if (res$above_p <= 0.05) stars <- "*"
    }

    paste0(res$above_cor, stars, "/", res$above_n)
  }),
  stringsAsFactors = FALSE
)

# Rename columns to match paper exactly
colnames(table2) <- c("GDP per capita [US$]", "≤", ">")

# ---- Export Tables ----
readr::write_csv(table1, file.path(out_dir, "table1_subgroup_correlations.csv"))
readr::write_csv(table2, file.path(out_dir, "table2_gdp_thresholds.csv"))

# ---- Export Supporting Data ----
# Export detailed correlation results for verification
detailed_results <- data.frame(
  analysis = c(
    "Age_on_Mort_LowUHC", "Age_on_Mort_HighUHC",
    "UHC_on_Mort_Young", "UHC_on_Mort_Old",
    "Vacc_on_Mort_Young", "Vacc_on_Mort_Old"
  ),
  n = c(
    age_mort_low_uhc$n, age_mort_high_uhc$n,
    uhc_mort_young$n, uhc_mort_old$n,
    vacc_mort_young$n, vacc_mort_old$n
  ),
  pearson_r = c(
    age_mort_low_uhc$pearson, age_mort_high_uhc$pearson,
    uhc_mort_young$pearson, uhc_mort_old$pearson,
    vacc_mort_young$pearson, vacc_mort_old$pearson
  ),
  pearson_p = c(
    age_mort_low_uhc$p_pear, age_mort_high_uhc$p_pear,
    uhc_mort_young$p_pear, uhc_mort_old$p_pear,
    vacc_mort_young$p_pear, vacc_mort_old$p_pear
  ),
  spearman_rho = c(
    age_mort_low_uhc$spearman, age_mort_high_uhc$spearman,
    uhc_mort_young$spearman, uhc_mort_old$spearman,
    vacc_mort_young$spearman, vacc_mort_old$spearman
  ),
  spearman_p = c(
    age_mort_low_uhc$p_spear, age_mort_high_uhc$p_spear,
    uhc_mort_young$p_spear, uhc_mort_old$p_spear,
    vacc_mort_young$p_spear, vacc_mort_old$p_spear
  )
)

readr::write_csv(detailed_results, file.path(out_dir, "table1_detailed_results.csv"))

# Export GDP threshold detailed results
gdp_detailed <- do.call(rbind, lapply(names(table2_results), function(name) {
  res <- table2_results[[name]]
  data.frame(
    threshold = res$threshold,
    direction = c("below", "above"),
    correlation = c(res$below_cor, res$above_cor),
    n = c(res$below_n, res$above_n),
    p_value = c(res$below_p, res$above_p),
    stringsAsFactors = FALSE
  )
}))

readr::write_csv(gdp_detailed, file.path(out_dir, "table2_detailed_results.csv"))

# ---- Console Output ----
message("Tables saved:")
message(" - Table 1: ", file.path(out_dir, "table1_subgroup_correlations.csv"))
message(" - Table 2: ", file.path(out_dir, "table2_gdp_thresholds.csv"))
message("GAM-only methodology with n=", nrow(df_complete_all), " countries")

cat("\n=== TABLE 1: Subgroup Correlation Analysis ===\n")
cat("Format: Pearson r/Spearman rho (* indicates p ≤ .01)\n\n")
print(table1)

cat("\n=== TABLE 2: GDP Threshold Analysis ===\n")
cat("Format: correlation/sample size (* p≤.05, ** p≤.01)\n\n")
print(table2)

# ---- Table Verification ----
cat("\n=== Table Verification ===\n")
cat("Table 1 rows:", nrow(table1), "\n")
cat("Table 2 rows:", nrow(table2), "\n")
cat("Complete cases used:", nrow(df_complete_all), "\n")
cat(
  "Median cutoffs verified - Age:", round(median_age_cutoff, 1),
  ", UHC:", round(median_uhc_cutoff, 1), "\n"
)

# Verifying subgroup sample sizes add up correctly
total_young <- sum(df_complete_all$median_age <= median_age_cutoff)
total_old <- sum(df_complete_all$median_age > median_age_cutoff)
total_low_uhc <- sum(df_complete_all$uhc <= median_uhc_cutoff)
total_high_uhc <- sum(df_complete_all$uhc > median_uhc_cutoff)

cat("Subgroup verification:\n")
cat("  Young countries (<=", round(median_age_cutoff, 1), "):", total_young, "\n")
cat("  Old countries (>", round(median_age_cutoff, 1), "):", total_old, "\n")
cat("  Low UHC countries (<=", round(median_uhc_cutoff, 1), "):", total_low_uhc, "\n")
cat("  High UHC countries (>", round(median_uhc_cutoff, 1), "):", total_high_uhc, "\n")

message("Table analysis complete!")
