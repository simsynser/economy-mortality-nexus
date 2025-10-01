
# ============================================================================
# We replaced variable median population age with variable percentage age 65 and above
# and again calculated pearson correlation matrix, partial correlations and median split correlations
# 
# Purpose: Percent age 65 and above is a common vulnerability indicator in economy and COVID impact assessment.
#          We want to show how this alternative indicator modifies our original results and conclusions.
#       
# The new variable slightly improves coefficients of median split correlations, 
# but it does not affect the overall conclusions of the study.
# 
# This is not included in the manuscript.
# ============================================================================


# =========================
# 1) Load percent population >=65 in 2022 as an alternative variable to median age
# =========================
pop_65 <- load_csv(
  "age_alt",
  here::here("data_raw", "age_alt", "greater_equal65_worldBank.csv")
)


# =========================
# 2) join variable population >=65 to existing variables
# =========================
df_complete_all_alt <- dplyr::left_join(df_complete_all,
                   pop_65,
                   by = c("iso3c" = "Country Code")) %>%
                   dplyr::rename(age65greater = `2022`)

typeof(df_complete_all_alt[1])

# =========================
# 3) calculate correlation matrix
# =========================

res <- df_complete_all_alt %>%
  dplyr::select(2,4,5,6,7,9) %>%
  cor()

round(res, 2)


# =========================
# 4) calculate partial correlations (we use age65greater instead of median_age)
# =========================

#control for age in correlation of vacc on mortality
vacc_mort_part <- pcor.test(df_complete_all_alt$vacc, df_complete_all_alt$excess_mort, df_complete_all_alt$age65greater)
vacc_mort_part
#control for age in correlation of uhc on mortality
uhc_mort_part <- pcor.test(df_complete_all_alt$uhc, df_complete_all_alt$excess_mort, df_complete_all_alt$age65greater)
uhc_mort_part
#control for vacc in correlation of age on mortality
age_mort_part_1 <- pcor.test(df_complete_all_alt$age65greater, df_complete_all_alt$excess_mort, df_complete_all_alt$vacc)
age_mort_part_1
#control for uhc in correlation of age on mortality
age_mort_part_2 <- pcor.test(df_complete_all_alt$age65greater, df_complete_all_alt$excess_mort, df_complete_all_alt$uhc)
age_mort_part_2

# =========================
# 5) calculate median split correlations (we use age65greater instead of median_age)
# =========================

# ---- Calculate Reference Medians ----
median_age_cutoff_alt <- median(df_complete_all_alt$age65greater)
median_uhc_cutoff_alt <- median(df_complete_all_alt$uhc)
median_gdp_cutoff_alt <- median(df_complete_all_alt$gdp)

#age on mortality, uhc below average
df_complete_all_alt %>%
  dplyr::filter(uhc <= median_uhc_cutoff_alt) %>%
  {cor.test(.$age65greater, .$excess_mort, method = "spearman")}

df_complete_all_alt %>%
  dplyr::filter(uhc <= median_uhc_cutoff_alt) %>%
  {cor.test(.$age65greater, .$excess_mort, method = "pearson")}

#age on mortality, uhc above average
df_complete_all_alt %>%
  dplyr::filter(uhc > median_uhc_cutoff_alt) %>%
  {cor.test(.$age65greater, .$excess_mort, method = "spearman")}

df_complete_all_alt %>%
  dplyr::filter(uhc > median_uhc_cutoff_alt) %>%
  {cor.test(.$age65greater, .$excess_mort, method = "pearson")}

#uhc on mortality, age below average
df_complete_all_alt %>%
  dplyr::filter(age65greater <= median_age_cutoff_alt) %>%
  {cor.test(.$uhc, .$excess_mort, method = "spearman")}

df_complete_all_alt %>%
  dplyr::filter(age65greater <= median_age_cutoff_alt) %>%
  {cor.test(.$uhc, .$excess_mort, method = "pearson")}

#uhc on mortality, age above average
df_complete_all_alt %>%
  dplyr::filter(age65greater > median_age_cutoff_alt) %>%
  {cor.test(.$uhc, .$excess_mort, method = "spearman")}

df_complete_all_alt %>%
  dplyr::filter(age65greater > median_age_cutoff_alt) %>%
  {cor.test(.$uhc, .$excess_mort, method = "pearson")}


#vacc on mortality, age below average
df_complete_all_alt %>%
  dplyr::filter(age65greater <= median_age_cutoff_alt) %>%
  {cor.test(.$vacc, .$excess_mort, method = "spearman")}

df_complete_all_alt %>%
  dplyr::filter(age65greater <= median_age_cutoff_alt) %>%
  {cor.test(.$vacc, .$excess_mort, method = "pearson")}

#vacc on mortality, age above average
df_complete_all_alt %>%
  dplyr::filter(age65greater > median_age_cutoff_alt) %>%
  {cor.test(.$vacc, .$excess_mort, method = "spearman")}

df_complete_all_alt %>%
  dplyr::filter(age65greater > median_age_cutoff_alt) %>%
  {cor.test(.$vacc, .$excess_mort, method = "pearson")}



# ============================================================================
###wealth data 1: https://databank.worldbank.org/source/wealth-accounts/Type/TABLE/preview/on#
###wealth data 2: https://worldpopulationreview.com/country-rankings/wealth-per-adult-by-country
#
#
#
#
#
#
# ============================================================================


# =========================
# 1) Load wealth in 2022 as an alternative variable to economic wealth
# =========================
wealth <- load_csv(
  "wealth",
  here::here("data_raw", "wealth", "wealthIndex.csv")
) %>%
  #dplyr::mutate(iso3c = countrycode::countrycode(country, origin = "country.name", destination = "iso3c")) %>%
  #drop_na() %>%
  dplyr::select(`Country Code`, `2020 [YR2020]`)

# =========================
# 2) join variable wealth to existing variables
# =========================
df_complete_all_alt_alt <- dplyr::left_join(df_complete_all_alt,
                                        wealth,
                                        by = c("iso3c" = "Country Code")) 
