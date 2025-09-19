# 01_loader.R — Modular Data Loader for COVID-19 Analysis Pipeline
# ============================================================================
# Purpose: Load and standardize datasets for correlation analysis between
#          pandemic outcomes, health systems, demographics, and economic factors
#
# Key Design Decisions:
# - Vaccination data: Offers two temporal strategies (max vs nearest to target date)
# - ISO standardization: Robust country code mapping with manual overrides
# - Modular structure: Each dataset can be loaded independently
# - Intermediate outputs: Both vaccination variants saved for comparison studies
#
# Exposes: age, essential_health_data_clean, gdp_data_clean,
#          vaccination_data_clean (selected), excess_dat
# ============================================================================

# ---- libraries ----
source(here::here("ready_to_import", "00_library_loader.R"))

# ---- folders ----
dir.create(here::here("ready_to_import", "data_raw"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("ready_to_import", "data_manipulated"), recursive = TRUE, showWarnings = FALSE)

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

# nearest_on(): Select observation closest to target date (for vaccination temporal alignment)
# Used to standardize vaccination measurements to a common reference point
nearest_on <- function(df, date_col = Day, target = as.Date("2023-05-05")) {
  date_sym <- rlang::ensym(date_col)
  df %>%
    dplyr::mutate(.dist = abs(!!date_sym - target)) %>%
    dplyr::slice_min(.dist, with_ties = FALSE) %>%
    dplyr::select(-.dist)
}

# ---- configuration ----
# Vaccination temporal strategy: Controls which snapshot gets used downstream
# "max" = latest available data per country (historical approach)
# "nearest" = closest to 2023-05-05 (standardized temporal reference)
VAX_SELECTION <- Sys.getenv("VAX_SELECTION", unset = "nearest")
WRITE_INTERMEDIATE <- isTRUE(as.logical(Sys.getenv("WRITE_INTERMEDIATE", "FALSE")))
VAX_TARGET_DATE <- as.Date("2023-05-05") # WHO/OWID recommended reference point

# =========================
# 1) DEMOGRAPHIC DATA: Median Age (UN World Population Prospects via OWID)
# =========================
# Uses 2022 estimates as most recent complete demographic snapshot
age <- load_csv(
  "age",
  here::here("ready_to_import", "data_raw", "age", "age2022.csv")
) %>%
  dplyr::rename(median_age = `Median age - Sex: all - Age: all - Variant: estimates`) %>%
  dplyr::mutate(iso3c = map_iso3(Entity))

# =========================
# 2) HEALTH SYSTEMS: Universal Health Coverage Index (WHO via World Bank)
# =========================
# Year 2021: Most recent pre-pandemic baseline for health system capacity
essential_health_data_clean <- load_csv(
  "uhc",
  here::here("ready_to_import", "data_raw", "health", "healthcare-access-quality-un.csv")
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
  here::here("ready_to_import", "data_raw", "gdp", "gdp-per-capita-worldbank.csv")
) %>%
  dplyr::filter(Year == 2022) %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c))

# =========================================
# 4) VACCINATION DATA: COVID-19 Doses Administered (OWID)
#    Dual-strategy approach for temporal standardization
# =========================================
vax_path <- here::here(
  "ready_to_import", "data_raw", "vaccination",
  "covid-19-vaccine-doses-administered-per-100-people.csv"
)

# Load and standardize vaccination time series
vax_raw <- load_csv("vaccination", vax_path) %>%
  dplyr::mutate(
    Day   = as.Date(Day),
    iso3c = map_iso3(Entity)
  ) %>%
  dplyr::filter(!is.na(iso3c)) # Exclude OWID aggregates (OWID_*, regional groups)

vax_col <- "COVID-19 doses (cumulative, per hundred)"
if (!(vax_col %in% names(vax_raw))) {
  stop("Vaccination column not found: ", vax_col)
}

# Strategy A: Latest available data per country (reproduces historical approach)
vaccination_max <- vax_raw %>%
  dplyr::group_by(Entity, iso3c) %>%
  dplyr::slice_max(Day, with_ties = FALSE) %>%
  dplyr::ungroup() %>%
  dplyr::transmute(
    Entity, iso3c,
    Day_max = Day,
    vacc_per_100_max = .data[[vax_col]]
  )

# Strategy B: Standardized temporal reference (closest to 2023-05-05)
# Provides more comparable cross-country snapshots by eliminating timing differences
vaccination_nearest <- vax_raw %>%
  dplyr::group_by(Entity, iso3c) %>%
  dplyr::group_modify(~ nearest_on(.x, Day, VAX_TARGET_DATE)) %>%
  dplyr::ungroup() %>%
  dplyr::transmute(
    Entity, iso3c,
    Day_near = Day,
    vacc_per_100_near = .data[[vax_col]]
  )

# Quantify differences between temporal strategies
vax_compare <- dplyr::full_join(vaccination_max, vaccination_nearest, by = c("Entity", "iso3c")) %>%
  dplyr::mutate(
    delta_value = vacc_per_100_near - vacc_per_100_max,
    same_day    = Day_near == Day_max
  )

message(
  "[Vaccination] Entities=", nrow(vax_compare),
  " | changed_value=", sum(!is.na(vax_compare$delta_value) & vax_compare$delta_value != 0),
  " | same_day=", sum(vax_compare$same_day, na.rm = TRUE)
)

# Export both vaccination datasets for comparison and sensitivity analysis
vax_out_dir <- here::here("ready_to_import", "data_manipulated", "vaccination")
dir.create(vax_out_dir, recursive = TRUE, showWarnings = FALSE)

readr::write_csv(
  vaccination_max,
  file.path(vax_out_dir, "vaccination_max.csv")
)
readr::write_csv(
  vaccination_nearest,
  file.path(vax_out_dir, "vaccination_nearest.csv")
)

message(
  "[Vaccination] wrote CSVs -> ",
  fs::path_rel(file.path(vax_out_dir, "vaccination_max.csv"), here::here()),
  " | ",
  fs::path_rel(file.path(vax_out_dir, "vaccination_nearest.csv"), here::here())
)

# Select vaccination strategy for downstream processing based on environment variable
vaccination_selected <- switch(VAX_SELECTION,
  "max" = dplyr::transmute(vaccination_max,
    Entity, iso3c,
    Day = Day_max,
    vacc_per_100 = vacc_per_100_max
  ),
  "nearest" = dplyr::transmute(vaccination_nearest,
    Entity, iso3c,
    Day = Day_near,
    vacc_per_100 = vacc_per_100_near
  ),
  stop("Invalid VAX_SELECTION='", VAX_SELECTION, "'. Use 'nearest' or 'max'.")
)

# Attach metadata for downstream traceability
vaccination_data_clean <- vaccination_selected
attr(vaccination_data_clean, "vax_basis") <- VAX_SELECTION
attr(vaccination_data_clean, "target_date") <- as.character(VAX_TARGET_DATE)

# =========================
# 5) MORTALITY OUTCOMES: Excess Deaths (Human Mortality Database via OWID)
# =========================
# Raw time series data - processing (GAM smoothing) handled in 02_clean.R
# Cumulative excess deaths per million, all ages, projected estimates
excess_dat <- load_csv(
  "excess_mort",
  here::here("ready_to_import", "data_raw", "mortality", "cumulative-excess-deaths-per-million-covid.csv")
)

# ---- Loading Summary ----
message(
  "Loaded datasets: ",
  "age=", nrow(age),
  " | UHC=", nrow(essential_health_data_clean),
  " | GDP=", nrow(gdp_data_clean),
  " | Vacc(", attr(vaccination_data_clean, "vax_basis"), ")=", nrow(vaccination_data_clean),
  " | Excess(raw rows)=", nrow(excess_dat)
)

message("Pipeline ready for 02_clean.R processing")
