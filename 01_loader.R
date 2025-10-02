# 01_loader.R — Data Loader for COVID-19 Analysis Pipeline
# ============================================================================
# Purpose: Load and standardize datasets for correlation analysis between
#          pandemic outcomes, health systems, demographics, and economic factors
#
# Key Design Decisions:
# - Vaccination data: Uses closest observation to 2023-05-05 for temporal standardization
# - ISO standardization: Robust country code mapping with manual overrides
# - Modular structure: Each dataset can be loaded independently
#
# Exposes: age_median, age_65plus, essential_health_data_clean, gdp_data_clean,
#          vaccination_data_clean, excess_dat
# ============================================================================

# ---- libraries ----
source(here::here("00_library_loader.R"))

# ---- folders ----
dir.create(here::here("data_raw"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("data_manipulated"), recursive = TRUE, showWarnings = FALSE)

# ---- helper functions ----
# load_csv(): Wrapper with informative error messages and progress feedback
load_csv <- function(label, path) {
  if (!file.exists(path)) {
    stop(sprintf("[ERROR] %s not found at: %s", label, fs::path_rel(path, here::here())))
  }
  message(sprintf("[OK] %-28s -> %s", label, fs::path_rel(path, here::here())))
  readr::read_csv(path, show_col_types = FALSE)
}

# map_iso3(): Standardize country names to ISO3 codes with fallback handling
# Includes manual overrides for common problematic cases in OWID data
map_iso3 <- function(x) {
  suppressWarnings(
    countrycode::countrycode(
      x,
      origin = "country.name", destination = "iso3c",
      custom_match = c(
        "Kosovo" = "XKX", # Not in standard ISO (uses XKX per ISO 3166)
        "Micronesia (country)" = "FSM", # OWID disambiguation vs. region name
        "Virgin Islands" = "VIR", # US Virgin Islands
        "Saint Martin" = "MAF" # French part (vs. Dutch Sint Maarten)
      )
    )
  )
}

# nearest_date(): Select observation closest to target date for vaccination temporal alignment
nearest_date <- function(df, target_date = as.Date("2023-05-05")) {
  df %>%
    dplyr::mutate(.dist = abs(Day - target_date)) %>%
    dplyr::slice_min(.dist, with_ties = FALSE) %>%
    dplyr::select(-.dist)
}

# ---- configuration ----
VAX_TARGET_DATE <- as.Date("2023-05-05") # WHO/OWID recommended reference point

# =========================
# 1a) DEMOGRAPHIC DATA: Median Age (UN WPP via OWID)
# =========================
age_median <- load_csv(
  "age_median",
  here::here("data_raw", "age", "age2022.csv")
) %>%
  dplyr::rename(median_age = `Median age - Sex: all - Age: all - Variant: estimates`) %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::select(iso3c, median_age)

# =========================
# 1b) DEMOGRAPHIC DATA: Population Ages 65+ (World Bank WDI via UN WPP)
# =========================
age_65plus <- load_csv(
  "age_65plus",
  here::here("data_raw", "age_alt", "greater_equal65_worldBank.csv")
) %>%
  dplyr::rename(
    iso3c = `Country Code`,
    age_65plus = `2022`
  ) %>%
  dplyr::select(iso3c, age_65plus) %>%
  dplyr::filter(!is.na(age_65plus))

# =========================
# 2) HEALTH SYSTEMS: Universal Health Coverage Index (WHO via World Bank)
# =========================
# Year 2021: Most recent pre-pandemic baseline for health system capacity
essential_health_data_clean <- load_csv(
  "uhc",
  here::here("data_raw", "health", "healthcare-access-quality-un.csv")
) %>%
  dplyr::filter(Year == 2021) %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c)) # Remove regional aggregates and unmatched entities

# =========================
# 3) ECONOMIC INDICATORS: GDP per capita PPP (World Bank)
# =========================
# Year 2022: Latest complete economic data (pre-analysis period)
gdp_data_clean <- load_csv(
  "gdp",
  here::here("data_raw", "gdp", "gdp-per-capita-worldbank.csv")
) %>%
  dplyr::filter(Year == 2022) %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c))

# =========================
# 4) VACCINATION DATA: COVID-19 Doses Administered (OWID)
# =========================
# Uses observations closest to 2023-05-05 for temporal standardization
vaccination_data_clean <- load_csv(
  "vaccination",
  here::here("data_raw", "vaccination", "covid-19-vaccine-doses-administered-per-100-people.csv")
) %>%
  dplyr::mutate(
    Day = as.Date(Day),
    iso3c = map_iso3(Entity)
  ) %>%
  dplyr::filter(!is.na(iso3c)) %>% # Exclude OWID aggregates (OWID_*, regional groups)
  dplyr::group_by(Entity, iso3c) %>%
  dplyr::group_modify(~ nearest_date(.x, VAX_TARGET_DATE)) %>%
  dplyr::ungroup() %>%
  dplyr::transmute(
    Entity, iso3c, Day,
    vacc_per_100 = `COVID-19 doses (cumulative, per hundred)`
  )

# =========================
# 5) MORTALITY OUTCOMES: Excess Deaths (Human Mortality Database via OWID)
# =========================
# Raw time series data - processing (GAM smoothing) handled in 02_clean.R
# Cumulative excess deaths per million, all ages, projected estimates
excess_dat <- load_csv(
  "excess_mort",
  here::here("data_raw", "mortality", "cumulative-excess-deaths-per-million-covid.csv")
)