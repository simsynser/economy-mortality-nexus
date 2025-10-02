# 04c_tables.R — Tables 1, 2, 3 (Subgroup & GDP Threshold Analysis)
# ============================================================================
# Purpose: Replicate Table 1 & 2 (subgroup correlations) and Table 3 (GDP thresholds)
#
# Dependencies: df_complete_all_analysis.csv (from 03_analysis.R)
# Outputs: table1_subgroup_correlations.csv, table2_subgroup_correlations_age65plus.csv,
#          table3_gdp_thresholds.csv#
# Paper Reference: Table 1, Table 2, Table 3
# ============================================================================

source(here::here("00_library_loader.R"))

# ---- Data Loading & Validation ----
complete_cases_file <- here::here("data_manipulated", "df_complete_all_analysis.csv")
out_dir <- here::here("outputs")

stopifnot(file.exists(complete_cases_file))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load complete cases dataset
df_complete_all <- readr::read_csv(complete_cases_file, show_col_types = FALSE)

# ---- Calculate Reference Medians ----
median_age_65plus_cutoff <- median(df_complete_all$age_65plus)
median_age_cutoff <- median(df_complete_all$median_age)
median_uhc_cutoff <- median(df_complete_all$uhc)
median_gdp_cutoff <- median(df_complete_all$gdp)

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
  if (is.na(cor_val) || is.na(p_val)) {
    return("NA")
  }

  # Two-level significance marking
  stars <- ""
  if (p_val <= 0.01) {
    stars <- "**"
  } else if (p_val <= 0.05) {
    stars <- "*"
  }

  paste0(cor_val, stars)
}

# ---- Generate Table 1: Subgroup Correlation Analysis ----
# UHC ≤ 79 vs UHC > 79: Age on Mortality
age_mort_low_uhc <- calc_subgroup_correlation(
  df_complete_all %>% filter(uhc <= median_uhc_cutoff),
  "median_age", "excess_mort"
)

age_mort_high_uhc <- calc_subgroup_correlation(
  df_complete_all %>% filter(uhc > median_uhc_cutoff),
  "median_age", "excess_mort"
)

# Age ≤ 38 vs Age > 38: UHC on Mortality
uhc_mort_young <- calc_subgroup_correlation(
  df_complete_all %>% filter(median_age <= median_age_cutoff),
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

# ---- Generate Table 2: Subgroup Analysis with Age 65+ ----
# UHC ≤ median vs UHC > median: Age 65+ on Mortality
age65_mort_low_uhc <- calc_subgroup_correlation(
  df_complete_all %>% filter(uhc <= median_uhc_cutoff),
  "age_65plus", "excess_mort"
)

age65_mort_high_uhc <- calc_subgroup_correlation(
  df_complete_all %>% filter(uhc > median_uhc_cutoff),
  "age_65plus", "excess_mort"
)

# Age 65+ ≤ median vs Age 65+ > median: UHC on Mortality
uhc_mort_young_age65 <- calc_subgroup_correlation(
  df_complete_all %>% filter(age_65plus <= median_age_65plus_cutoff),
  "uhc", "excess_mort"
)

uhc_mort_old_age65 <- calc_subgroup_correlation(
  df_complete_all %>% filter(age_65plus > median_age_65plus_cutoff),
  "uhc", "excess_mort"
)

# Age 65+ ≤ median vs Age 65+ > median: Vaccination on Mortality
vacc_mort_young_age65 <- calc_subgroup_correlation(
  df_complete_all %>% filter(age_65plus <= median_age_65plus_cutoff),
  "vacc", "excess_mort"
)

vacc_mort_old_age65 <- calc_subgroup_correlation(
  df_complete_all %>% filter(age_65plus > median_age_65plus_cutoff),
  "vacc", "excess_mort"
)

table2 <- data.frame(
  Analysis_Group = c(
    paste0("UHC<=", round(median_uhc_cutoff), " (n=", age65_mort_low_uhc$n, ")"),
    paste0("UHC>", round(median_uhc_cutoff), " (n=", age65_mort_high_uhc$n, ")"),
    paste0("Age65+<=", round(median_age_65plus_cutoff, 1), "% (n=", uhc_mort_young_age65$n, ")"),
    paste0("Age65+>", round(median_age_65plus_cutoff, 1), "% (n=", uhc_mort_old_age65$n, ")"),
    paste0("Age65+<=", round(median_age_65plus_cutoff, 1), "% (n=", vacc_mort_young_age65$n, ")"),
    paste0("Age65+>", round(median_age_65plus_cutoff, 1), "% (n=", vacc_mort_old_age65$n, ")")
  ),
  Age65plus_on_Mortality = c(
    paste0(
      format_correlation_with_significance(age65_mort_low_uhc$pearson, age65_mort_low_uhc$p_pear),
      "/", format_correlation_with_significance(age65_mort_low_uhc$spearman, age65_mort_low_uhc$p_spear)
    ),
    paste0(
      format_correlation_with_significance(age65_mort_high_uhc$pearson, age65_mort_high_uhc$p_pear),
      "/", format_correlation_with_significance(age65_mort_high_uhc$spearman, age65_mort_high_uhc$p_spear)
    ),
    "", "", "", ""
  ),
  UHC_on_Mortality = c(
    "", "",
    paste0(
      format_correlation_with_significance(uhc_mort_young_age65$pearson, uhc_mort_young_age65$p_pear),
      "/", format_correlation_with_significance(uhc_mort_young_age65$spearman, uhc_mort_young_age65$p_spear)
    ),
    paste0(
      format_correlation_with_significance(uhc_mort_old_age65$pearson, uhc_mort_old_age65$p_pear),
      "/", format_correlation_with_significance(uhc_mort_old_age65$spearman, uhc_mort_old_age65$p_spear)
    ),
    "", ""
  ),
  Vacc_on_Mortality = c(
    "", "", "", "",
    paste0(
      format_correlation_with_significance(vacc_mort_young_age65$pearson, vacc_mort_young_age65$p_pear),
      "/", format_correlation_with_significance(vacc_mort_young_age65$spearman, vacc_mort_young_age65$p_spear)
    ),
    paste0(
      format_correlation_with_significance(vacc_mort_old_age65$pearson, vacc_mort_old_age65$p_pear),
      "/", format_correlation_with_significance(vacc_mort_old_age65$spearman, vacc_mort_old_age65$p_spear)
    )
  ),
  stringsAsFactors = FALSE
)

# ---- Generate Table 3: GDP Threshold Analysis ----
gdp_thresholds <- c(20000, 25000, 30000, 33000)
table3_results <- list()

for (threshold in gdp_thresholds) {
  # Countries below / above threshold
  below <- calc_gdp_threshold_correlation(df_complete_all, threshold, "<=")
  above <- calc_gdp_threshold_correlation(df_complete_all, threshold, ">")

  table3_results[[paste0("threshold_", threshold)]] <- list(
    threshold = threshold,
    below_cor = below$correlation,
    below_n = below$n,
    below_p = below$p_value,
    above_cor = above$correlation,
    above_n = above$n,
    above_p = above$p_value
  )
}

table3 <- data.frame(
  GDP_per_capita_USD = paste0(scales::comma(gdp_thresholds / 1000), ",000"),
  Below_Threshold = sapply(gdp_thresholds, function(t) {
    res <- table3_results[[paste0("threshold_", t)]]

    # Format significance: * for p≤.05, ** for p≤.01
    stars <- ""
    if (!is.na(res$below_p)) {
      if (res$below_p <= 0.01) {
        stars <- "**"
      } else if (res$below_p <= 0.05) stars <- "*"
    }

    paste0(res$below_cor, stars, "/", res$below_n)
  }),
  Above_Threshold = sapply(gdp_thresholds, function(t) {
    res <- table3_results[[paste0("threshold_", t)]]

    # Format significance: * for p≤.05, ** for p≤.01
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
colnames(table3) <- c("GDP per capita [US$]", "≤", ">")

# ---- Export Tables ----
readr::write_csv(table2, file.path(out_dir, "table2_subgroup_correlations_age65plus.csv"))
readr::write_csv(table1, file.path(out_dir, "table1_subgroup_correlations.csv"))
readr::write_csv(table3, file.path(out_dir, "table3_gdp_thresholds.csv"))