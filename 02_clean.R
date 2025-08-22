# 02_clean.R — Excess Mortality per 2023-05-05 (altes GAM, 1:1 Verhalten)
# -----------------------------------------------------------------------------
# Zweck
# - Für jedes Land den kumulativen Excess-Mortality-Wert am Stichtag 2023-05-05
#   schätzen – mit demselben GAM-Setup wie im ursprünglichen Skript.
#
# Abhängigkeiten (kommen aus 01_loader.R)
# - Objects: age, gdp_data_clean, essential_health_data_clean,
#            vaccination_data_clean (nearest/max via VAX_SELECTION), excess_dat
#
# Output
# - data_manipulated/analysis_table.csv  (Join: median_age, gdp, uhc, vacc, excess_mort, vax_day)
#
# Modell (unverändert zur alten Logik)
# - mgcv::gam(y ~ s(x, bs="cs"), GCV-Default); Vorhersage via täglichem Grid;
#   Abgriff des Zielwerts per Index (as.Date("2023-05-05") - min(Day)).
#
# Wichtige Hinweise / Stolpersteine
# - Extrapolation: Liegt der Stichtag außerhalb der beobachteten Reihe, fällt
#   die Indexposition außerhalb des Vorhersage-Rasters → NA möglich.
# - Off-by-one-Risiko: Der Index ist (Zieldatum - min(Day)) ohne +1, wie im
#   alten Code; kann bei Datenlücken/Zeitzonen um 1 Tag versetzt sein.
# - GCV-Default: Ohne method="REML" kann das Glätten bei kurzen/rauschigen
#   Reihen „wiggly“ werden.
# - Kumulativdaten: Glätten kann kleine Nicht-Monotonien erzeugen; wir entnehmen
#   nur einen Stichtagswert, daher tolerierbar.
#
# Referenzen
# - mgcv (GAM-Grundlagen): https://cran.r-project.org/package=mgcv
# - ggplot2 stat_smooth (Default-GAM: y ~ s(x, bs="cs")):
#   https://ggplot2.tidyverse.org/reference/geom_smooth.html

source(here::here("ready_to_import", "00_library_loader.R"))
suppressPackageStartupMessages(library(mgcv))

stopifnot(
  exists("excess_dat"), exists("vaccination_data_clean"),
  exists("age"), exists("gdp_data_clean"), exists("essential_health_data_clean")
)

TARGET_DATE <- as.Date("2023-05-05")

# --- GAM-Schätzung je Land (alte Logik, aber k dynamisch) -------------------
est_excess_oldmodel <- function(df, target = TARGET_DATE) {
  df <- df %>%
    dplyr::filter(!is.na(Day), !is.na(cum_excess_per_million_proj_all_ages)) %>%
    dplyr::mutate(
      Day     = as.Date(Day),
      Day_num = as.numeric(Day)
    )

  if (nrow(df) == 0) {
    return(tibble::tibble(value = NA_real_))
  }

  x <- df$Day_num
  y <- df$cum_excess_per_million_proj_all_ages
  n_uniq <- length(unique(x))

  # Sehr kurze Reihen: altes Modell kann hier nicht stabil fitten -> nimm den nächsten beobachteten Wert
  if (n_uniq < 3L) {
    near <- df %>% dplyr::slice_min(abs(Day - target), with_ties = FALSE)
    return(tibble::tibble(value = near$cum_excess_per_million_proj_all_ages))
  }

  # Dynamisches k, aber nie > 10 (entspricht mgcv-Default), und mind. 3
  k_val <- max(3L, min(10L, n_uniq - 1L))

  # GCV-Default, cs-Basis – nur k wird gesetzt
  mod <- mgcv::gam(formula = y ~ s(x, bs = "cs", k = k_val))

  # tägliche Sequenz & Vorhersage (wie gehabt)
  grid <- data.frame(x = seq(from = min(df$Day_num), to = max(df$Day_num), by = 1))
  fit <- mgcv::predict.gam(mod, newdata = grid)

  # identischer Indexzugriff wie im alten Code (OHNE +1) – kann Off-by-one erzeugen
  idx <- as.integer(as.Date(target) - min(df$Day))

  # Wenn außerhalb des Rasters -> NA (statt Fehler)
  if (idx < 1L || idx > length(fit)) {
    return(tibble::tibble(value = NA_real_))
  }

  tibble::tibble(value = as.numeric(fit[idx]))
}

mortality_data_clean <- excess_dat %>%
  dplyr::mutate(Day = as.Date(Day)) %>%
  dplyr::group_by(Entity) %>%
  dplyr::group_modify(~ est_excess_oldmodel(.x, TARGET_DATE)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c)) %>%
  dplyr::rename(cum_excess_per_million_proj_all_ages = value)

# --- Final Join ---
dat <- age %>%
  dplyr::transmute(iso3c, median_age) %>%
  dplyr::full_join(
    vaccination_data_clean %>%
      dplyr::transmute(iso3c, vax_day = Day, vacc = vacc_per_100),
    by = "iso3c"
  ) %>%
  dplyr::full_join(
    mortality_data_clean %>%
      dplyr::select(iso3c, excess_mort = cum_excess_per_million_proj_all_ages),
    by = "iso3c"
  ) %>%
  dplyr::full_join(
    essential_health_data_clean %>%
      dplyr::transmute(iso3c, uhc = `UHC service coverage index`),
    by = "iso3c"
  ) %>%
  dplyr::full_join(
    gdp_data_clean %>%
      dplyr::transmute(iso3c, gdp = `GDP per capita, PPP (constant 2017 international $)`),
    by = "iso3c"
  )


# --- Output -------------------------
out_dir <- here::here("ready_to_import", "data_manipulated")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

readr::write_csv(dat, file = file.path(out_dir, "analysis_table.csv"))

message(
  "[02_clean| rows(dat)=", nrow(dat),
  " | iso3c=", dplyr::n_distinct(dat$iso3c, na.rm = TRUE) # ohne NA ! vergleichen
)
