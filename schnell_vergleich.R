# ready_to_import/scripts/schnell_vergleich.R
source(here::here("ready_to_import", "00_library_loader.R"))

max_path <- here("ready_to_import", "data_manipulated", "vaccination", "vaccination_max.csv")
near_path <- here("ready_to_import", "data_manipulated", "vaccination", "vaccination_nearest.csv")
out_dir <- here("ready_to_import", "data_manipulated", "vaccination")
out_file <- file.path(out_dir, "vaccination_compare_short.csv")

stopifnot(file.exists(max_path), file.exists(near_path))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Helper
std_vax <- function(df, suffix = c("max", "near")) {
  suffix <- match.arg(suffix)
  # First Day_ suffix, then Day
  day_col <- intersect(c(paste0("Day_", suffix), "Day"), names(df))[1]
  if (is.na(day_col)) stop("Keine Datums-Spalte gefunden (erwartet Day_", suffix, " oder Day).")

  # Wert-Spalte: try vacc_per_100_<suffix>, then vacc_per_100, then generic name
  val_col <- intersect(
    c(
      paste0("vacc_per_100_", suffix),
      "vacc_per_100",
      "COVID-19 doses (cumulative, per hundred)"
    ),
    names(df)
  )[1]
  if (is.na(val_col)) stop("Keine Impf-Wertspalte gefunden.")

  df %>%
    transmute(
      iso3c,
      Entity,
      !!paste0("Day_", suffix) := as.Date(.data[[day_col]]),
      !!paste0("vacc_per_100_", suffix) := .data[[val_col]]
    )
}

# simple load
v_max_raw <- read_csv(max_path, show_col_types = FALSE)
v_near_raw <- read_csv(near_path, show_col_types = FALSE)

v_max <- std_vax(v_max_raw, "max")
v_near <- std_vax(v_near_raw, "near")

# compare
cmp <- full_join(v_max, v_near, by = c("iso3c", "Entity")) %>%
  mutate(
    same_day    = Day_near == Day_max,
    delta_value = vacc_per_100_near - vacc_per_100_max,
    delta_abs   = abs(delta_value),
    day_diff    = as.integer(Day_near - Day_max)
  ) %>%
  select(
    iso3c, Entity, Day_max, vacc_per_100_max, Day_near, vacc_per_100_near,
    same_day, delta_value, delta_abs, day_diff
  ) %>%
  arrange(desc(delta_abs))

write_csv(cmp, out_file)

cat("[schnell_vergleich] gespeichert ->", out_file, "\n")
cat(
  "Entities:", nrow(cmp),
  "| geändert (delta_abs>0):", sum(cmp$delta_abs > 0, na.rm = TRUE),
  "| gleicher Tag:", sum(cmp$same_day, na.rm = TRUE), "\n"
)
