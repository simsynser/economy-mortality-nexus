# 02_clean.R — Excess Mortality per 2023-05-05 (old GAM form, index-free prediction)
# ----------------------------------------------------------------------------------
# Zweck
# - Für jedes Land den kumulativen Excess-Mortality-Wert am Stichtag 2023-05-05 schätzen.
# - Modellform wie im alten Skript (mgcv::gam(y ~ s(x, bs="cs")) mit GCV-Default),
#   aber OHNE Index-Abgriff: direkte Vorhersage am Ziel-Datum; außerhalb -> Fallback „nearest observed“.
#
# Abhängigkeiten (kommen aus 01_loader.R)
# - Objects: age, gdp_data_clean, essential_health_data_clean,
#            vaccination_data_clean (nearest/max via VAX_SELECTION), excess_dat
#
# Outputs
# - ready_to_import/data_manipulated/mortality_gam_2023-05-05.csv
# - ready_to_import/data_manipulated/analysis_table.csv
#   (Join: iso3c, median_age, gdp, uhc, vacc, vax_day, excess_mort)
#
# Hinweise / mögliche Stolpersteine
# - Sehr kurze/grobe Reihen: Wenn zu wenige eindeutige x-Werte, wird robust auf
#   „nächstbeobachtet“ zurückgegriffen (anstatt wacklige Fits zu erzwingen).
# - GCV-Default: Ohne method="REML" können bei rauschigen Reihen glatte Kurven
#   „wiggly“ werden — wir entnehmen nur den Stichtagswert.
# - Kumulativdaten: Glätten kann leichte Nicht-Monotonien erzeugen; für den
#   Stichtagswert tolerierbar.
#
# Referenzen
# - mgcv (GAM): https://cran.r-project.org/package=mgcv
# - ggplot2 stat_smooth (Default-GAM: y ~ s(x, bs="cs")):
#   https://ggplot2.tidyverse.org/reference/geom_smooth.html

source(here::here("ready_to_import", "00_library_loader.R"))
suppressPackageStartupMessages(library(mgcv))

stopifnot(
  exists("excess_dat"), exists("vaccination_data_clean"),
  exists("age"), exists("gdp_data_clean"), exists("essential_health_data_clean")
)

TARGET_DATE <- as.Date("2023-05-05")

# --- Helper: Länderspezifische Schätzung am Stichtag (indexfrei) -------------
est_excess_oldform_indexfree <- function(df, target = TARGET_DATE) {
  df <- df %>%
    dplyr::filter(!is.na(Day), !is.na(cum_excess_per_million_proj_all_ages)) %>%
    dplyr::mutate(
      Day     = as.Date(Day),
      x       = as.numeric(Day),
      y       = cum_excess_per_million_proj_all_ages
    )

  if (nrow(df) == 0) {
    return(tibble::tibble(value = NA_real_))
  }

  # zu wenige eindeutige x -> robust: nächstliegender beobachteter Wert
  n_uniq <- length(unique(df$x))
  if (n_uniq < 3L) {
    near <- df %>% dplyr::slice_min(abs(Day - target), with_ties = FALSE)
    return(tibble::tibble(value = near$y))
  }

  # Dynamisches k (konservativ), ansonsten alte Modellform (GCV, bs="cs")
  k_val <- max(3L, min(10L, n_uniq - 1L))
  fit <- try(mgcv::gam(y ~ s(x, bs = "cs", k = k_val), data = df), silent = TRUE)

  if (inherits(fit, "try-error")) {
    near <- df %>% dplyr::slice_min(abs(Day - target), with_ties = FALSE)
    return(tibble::tibble(value = near$y))
  }

  # Ziel liegt innerhalb der beobachteten Zeitspanne? -> direkt am Datum vorhersagen
  if (target >= min(df$Day) && target <= max(df$Day)) {
    pred <- mgcv::predict.gam(fit, newdata = data.frame(x = as.numeric(target)))
    return(tibble::tibble(value = as.numeric(pred)))
  } else {
    # außerhalb -> robust: nächstliegender beobachteter Wert
    near <- df %>% dplyr::slice_min(abs(Day - target), with_ties = FALSE)
    return(tibble::tibble(value = near$y))
  }
}

# --- GAM je Land laufen lassen ------------------------------------------------
mortality_data_clean <- excess_dat %>%
  dplyr::mutate(Day = as.Date(Day)) %>%
  dplyr::group_by(Entity) %>%
  dplyr::group_modify(~ est_excess_oldform_indexfree(.x, TARGET_DATE)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(iso3c = map_iso3(Entity)) %>%
  dplyr::filter(!is.na(iso3c), !is.na(value)) %>%
  dplyr::transmute(
    iso3c,
    cum_excess_per_million_proj_all_ages = value
  )

# --- Finaler Join -------------------------------------------------------------
dat <- age %>%
  dplyr::transmute(iso3c, median_age) %>%
  dplyr::full_join(
    vaccination_data_clean %>%
      dplyr::transmute(iso3c, vax_day = Day, vacc = vacc_per_100),
    by = "iso3c"
  ) %>%
  dplyr::full_join(
    mortality_data_clean %>%
      dplyr::transmute(iso3c, excess_mort = cum_excess_per_million_proj_all_ages),
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

# --- Outputs -----------------------------------------------------------------
out_dir <- here::here("ready_to_import", "data_manipulated")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

readr::write_csv(
  mortality_data_clean,
  file = file.path(out_dir, "mortality_gam_2023-05-05.csv")
)
readr::write_csv(
  dat,
  file = file.path(out_dir, "analysis_table.csv")
)

message(
  "[02_clean] rows(dat)=", nrow(dat),
  " | iso3c=", dplyr::n_distinct(dat$iso3c, na.rm = TRUE),
  " | mortality rows=", nrow(mortality_data_clean)
)
