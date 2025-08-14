# 01_loader.R — modular loader + age tweak
source(here::here("ready_to_import", "00_library_loader.R"))

# Create folder structure if missing
dir.create(here::here("ready_to_import", "data_raw"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("ready_to_import", "data_manipulated"), recursive = TRUE, showWarnings = FALSE)

# Helper for safer loading
load_csv <- function(label, path) {
  if (!file.exists(path)) {
    stop(sprintf("[ERROR] %s not found at: %s", label, fs::path_rel(path, here::here())))
  }
  message(sprintf("[OK] %-28s -> %s", label, fs::path_rel(path, here::here())))
  readr::read_csv(path, show_col_types = FALSE)
}

# Helper to map country names to ISO3 (do so quietly)
map_iso3 <- function(x) {
  suppressWarnings(
    countrycode::countrycode(
      x,
      origin = "country.name", destination = "iso3c",
      custom_match = c(
        "Kosovo" = "XKX",
        "Micronesia (country)" = "FSM",
        "Virgin Islands" = "VIR",
        "Saint Martin" = "MAF"
      )
    )
  )
}


# ---------- AGE (2022 snapshot) ----------
age <- load_csv("age", here::here("ready_to_import", "data_raw", "age", "age2022.csv")) %>%
  dplyr::rename(median_age = `Median age - Sex: all - Age: all - Variant: estimates`) %>%
  dplyr::mutate(iso3c = map_iso3(Entity))


# ---------- UHC (WHO) ----------
essential_health_data_clean <- load_csv(
  "uhc",
  here::here("ready_to_import", "data_raw", "health", "healthcare-access-quality-un.csv")
) %>%
  dplyr::filter(Year == 2021) %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c))

# ---------- GDP (World Bank, 2022) ----------
gdp_data_clean <- load_csv(
  "gdp",
  here::here("ready_to_import", "data_raw", "gdp", "gdp-per-capita-worldbank.csv")
) %>%
  dplyr::filter(Year == 2022) %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c))


# ---------- Vaccination (OWID doses per 100) ----------
vaccination_data_clean <- load_csv(
  "vaccination",
  here::here(
    "ready_to_import", "data_raw", "vaccination",
    "covid-19-vaccine-doses-administered-per-100-people.csv"
  )
) %>%
  dplyr::group_by(Entity) %>%
  dplyr::filter(Day == max(Day), .preserve = TRUE) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c))

stopifnot(nchar(unique(age$iso3c)[1]) == 3) # Check ISO3 length
stopifnot(!any(grepl("^OWID_", vaccination_data_clean$iso3c, useBytes = TRUE))) # Check no OWID prefixes


# ---------- Excess mortality (OWID cumulative per million, raw) ----------
excess_dat <- load_csv(
  "excess_mort",
  here::here("ready_to_import", "data_raw", "mortality", "cumulative-excess-deaths-per-million-covid.csv")
)

# Summary
message(
  "Loaded datasets: age=", nrow(age),
  " | UHC=", nrow(essential_health_data_clean),
  " | GDP=", nrow(gdp_data_clean),
  " | Vacc(latest rows)=", nrow(vaccination_data_clean),
  " | Excess(raw rows)=", nrow(excess_dat)
)
