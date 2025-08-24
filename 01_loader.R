# 01_loader.R — modular loader (+ age tweaks, vax selection switch)
# Exposes: age, essential_health_data_clean, gdp_data_clean,
#          vaccination_data_clean (selected), excess_dat

# ---- libraries ----
source(here::here("ready_to_import", "00_library_loader.R"))

# ---- folders ----
dir.create(here::here("ready_to_import", "data_raw"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("ready_to_import", "data_manipulated"), recursive = TRUE, showWarnings = FALSE)

# ---- helpers ----
# load_csv(): small wrapper with a friendly OK/error message
load_csv <- function(label, path) {
  if (!file.exists(path)) {
    stop(sprintf("[ERROR] %s not found at: %s", label, fs::path_rel(path, here::here())))
  }
  message(sprintf("[OK] %-28s -> %s", label, fs::path_rel(path, here::here())))
  readr::read_csv(path, show_col_types = FALSE)
}

# map_iso3(): quiet country name -> ISO3 mapper with a few manual matches
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

# nearest_on(): pick the single row whose date is closest to `target`
nearest_on <- function(df, date_col = Day, target = as.Date("2023-05-05")) {
  date_sym <- rlang::ensym(date_col)
  df %>%
    dplyr::mutate(.dist = abs(!!date_sym - target)) %>% # dist = absolute difference to target
    dplyr::slice_min(.dist, with_ties = FALSE) %>%
    dplyr::select(-.dist)
}

# ---- config ----
# Choose which vaccination snapshot to expose downstream
# (both variants are written to disk; this only controls the in-memory selection)
VAX_SELECTION <- Sys.getenv("VAX_SELECTION", unset = "nearest")
WRITE_INTERMEDIATE <- isTRUE(as.logical(Sys.getenv("WRITE_INTERMEDIATE", "FALSE")))
VAX_TARGET_DATE <- as.Date("2023-05-05")

# =========================
# 1) AGE (2022 snapshot)
# =========================
age <- load_csv(
  "age",
  here::here("ready_to_import", "data_raw", "age", "age2022.csv")
) %>%
  dplyr::rename(median_age = `Median age - Sex: all - Age: all - Variant: estimates`) %>%
  dplyr::mutate(iso3c = map_iso3(Entity))

# =========================
# 2) UHC (WHO) — Year 2021
# =========================
essential_health_data_clean <- load_csv(
  "uhc",
  here::here("ready_to_import", "data_raw", "health", "healthcare-access-quality-un.csv")
) %>%
  dplyr::filter(Year == 2021) %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c))

# =========================
# 3) GDP (World Bank) — 2022
# =========================
gdp_data_clean <- load_csv(
  "gdp",
  here::here("ready_to_import", "data_raw", "gdp", "gdp-per-capita-worldbank.csv")
) %>%
  dplyr::filter(Year == 2022) %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c))

# =========================================
# 4) Vaccination (OWID doses per 100 people)
#    Build both: "max" and "nearest to 2023-05-05"
# =========================================
vax_path <- here::here(
  "ready_to_import", "data_raw", "vaccination",
  "covid-19-vaccine-doses-administered-per-100-people.csv"
)

vax_raw <- load_csv("vaccination", vax_path) %>%
  dplyr::mutate(
    Day   = as.Date(Day),
    iso3c = map_iso3(Entity)
  ) %>%
  dplyr::filter(!is.na(iso3c)) # drop OWID_* aggregates, EU, etc.

vax_col <- "COVID-19 doses (cumulative, per hundred)"
if (!(vax_col %in% names(vax_raw))) {
  stop("Vaccination column not found: ", vax_col)
}

# A) latest available day per entity
vaccination_max <- vax_raw %>%
  dplyr::group_by(Entity, iso3c) %>%
  dplyr::slice_max(Day, with_ties = FALSE) %>%
  dplyr::ungroup() %>%
  dplyr::transmute(
    Entity, iso3c,
    Day_max = Day,
    vacc_per_100_max = .data[[vax_col]]
  )

# B) nearest to target date per entity
vaccination_nearest <- vax_raw %>%
  dplyr::group_by(Entity, iso3c) %>%
  dplyr::group_modify(~ nearest_on(.x, Day, VAX_TARGET_DATE)) %>%
  dplyr::ungroup() %>%
  dplyr::transmute(
    Entity, iso3c,
    Day_near = Day,
    vacc_per_100_near = .data[[vax_col]]
  )

# quick comparison log (how different are the two definitions?)
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

# Always write both CSVs so the comparison script can run without extra setup
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

# Choose which vaccination table to expose downstream
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

vaccination_data_clean <- vaccination_selected
attr(vaccination_data_clean, "vax_basis") <- VAX_SELECTION
attr(vaccination_data_clean, "target_date") <- as.character(VAX_TARGET_DATE)

# =========================================
# 5) Excess mortality (OWID cumulative per million) — raw load only
# =========================================
excess_dat <- load_csv(
  "excess_mort",
  here::here("ready_to_import", "data_raw", "mortality", "cumulative-excess-deaths-per-million-covid.csv")
)

# ---- summary ----
message(
  "Loaded datasets: ",
  "age=", nrow(age),
  " | UHC=", nrow(essential_health_data_clean),
  " | GDP=", nrow(gdp_data_clean),
  " | Vacc(", attr(vaccination_data_clean, "vax_basis"), ")=", nrow(vaccination_data_clean),
  " | Excess(raw rows)=", nrow(excess_dat)
)
