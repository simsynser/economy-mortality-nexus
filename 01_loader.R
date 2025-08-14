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

# --- config: which vaccination timepoint to use by default? ---
# options: "nearest" (preferred, as per paper) or "max" (old pipeline)
VAX_SELECTION <- Sys.getenv("VAX_SELECTION", unset = "nearest")

# optional: write intermediate CSVs for inspection?
WRITE_INTERMEDIATE <- FALSE

# --- helper: pick the row nearest to a target date within a group ---
nearest_on <- function(df, date_col = Day, target = as.Date("2023-05-05")) {
  date_sym <- rlang::ensym(date_col)
  df %>%
    dplyr::mutate(.dist = abs(!!date_sym - target)) %>%
    dplyr::slice_min(.dist, with_ties = FALSE) %>%
    dplyr::select(-.dist)
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
VAX_SELECTION <- "max" # choose: "max" or "nearest"
WRITE_INTERMEDIATE <- TRUE # write CSVs?

vax_path <- here::here(
  "ready_to_import", "data_raw", "vaccination",
  "covid-19-vaccine-doses-administered-per-100-people.csv"
)

vax_raw <- load_csv("vaccination", vax_path) %>%
  dplyr::mutate(
    Day = as.Date(Day),
    iso3c = map_iso3(Entity)
  ) %>%
  dplyr::filter(!is.na(iso3c))

vax_col <- "COVID-19 doses (cumulative, per hundred)"

vaccination_max <- vax_raw %>%
  dplyr::group_by(Entity, iso3c) %>%
  dplyr::slice_max(Day, with_ties = FALSE) %>%
  dplyr::ungroup() %>%
  dplyr::rename(Day_max = Day) %>%
  dplyr::mutate(vacc_per_100_max = .data[[vax_col]])

vaccination_nearest <- vax_raw %>%
  dplyr::group_by(Entity, iso3c) %>%
  dplyr::group_modify(~ nearest_on(.x, Day, as.Date("2023-05-05"))) %>%
  dplyr::ungroup() %>%
  dplyr::rename(Day_near = Day) %>%
  dplyr::mutate(vacc_per_100_near = .data[[vax_col]])

# quick compare
vax_compare <- dplyr::full_join(vaccination_max, vaccination_nearest, by = c("Entity", "iso3c")) %>%
  dplyr::mutate(
    delta_value = vacc_per_100_near - vacc_per_100_max,
    same_day = Day_near == Day_max
  )

message(
  "[Vaccination] Entities=", nrow(vax_compare),
  " | changed_value=", sum(!is.na(vax_compare$delta_value) & vax_compare$delta_value != 0),
  " | same_day=", sum(vax_compare$same_day, na.rm = TRUE)
)

# pick final set
vaccination_selected <- if (VAX_SELECTION == "max") {
  vaccination_max %>%
    dplyr::transmute(Entity, iso3c, Day = Day_max, vacc_per_100 = vacc_per_100_max)
} else {
  vaccination_nearest %>%
    dplyr::transmute(Entity, iso3c, Day = Day_near, vacc_per_100 = vacc_per_100_near)
}

if (WRITE_INTERMEDIATE) {
  out_dir <- here::here("ready_to_import", "data_manipulated", "vaccination")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(vaccination_max, file.path(out_dir, "vaccination_max.csv"))
  readr::write_csv(vaccination_nearest, file.path(out_dir, "vaccination_nearest.csv"))
}


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
