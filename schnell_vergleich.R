# ready_to_import/schnell_vergleich.R
source(here::here("ready_to_import", "00_library_loader.R"))

# ---- config ----
VAX_TARGET_DATE <- as.Date(Sys.getenv("VAX_TARGET_DATE", "2023-05-05"))

max_path <- here::here("ready_to_import", "data_manipulated", "vaccination", "vaccination_max.csv")
near_path <- here::here("ready_to_import", "data_manipulated", "vaccination", "vaccination_nearest.csv")
out_dir <- here::here("ready_to_import", "data_manipulated", "vaccination")

stopifnot(file.exists(max_path), file.exists(near_path))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- load (assumes standard columns) ----
v_max <- readr::read_csv(max_path, show_col_types = FALSE) %>%
  dplyr::select(iso3c, Entity, Day_max, vacc_per_100_max)
v_near <- readr::read_csv(near_path, show_col_types = FALSE) %>%
  dplyr::select(iso3c, Entity, Day_near, vacc_per_100_near)

# ---- compare ----
cmp <- dplyr::full_join(v_max, v_near, by = c("iso3c", "Entity")) %>%
  dplyr::mutate(
    Day_near = as.Date(Day_near),
    Day_max = as.Date(Day_max),
    same_day = Day_near == Day_max,
    delta_value = vacc_per_100_near - vacc_per_100_max,
    delta_abs = abs(delta_value),
    day_diff = as.integer(Day_near - Day_max),
    direction = dplyr::case_when(
      is.na(Day_near) ~ NA_character_,
      Day_near < VAX_TARGET_DATE ~ "before",
      Day_near > VAX_TARGET_DATE ~ "after",
      TRUE ~ "exact"
    ),
    gap_days = as.integer(Day_near - VAX_TARGET_DATE),
    abs_gap_days = abs(gap_days)
  ) %>%
  dplyr::arrange(dplyr::desc(delta_abs))

# ---- write CSVs ----
short_file <- file.path(out_dir, "vaccination_compare_short.csv")
all_file <- file.path(out_dir, "vaccination_compare_all.csv")

readr::write_csv(
  cmp %>% dplyr::select(
    iso3c, Entity, Day_max, vacc_per_100_max, Day_near, vacc_per_100_near,
    same_day, delta_value, delta_abs, day_diff
  ),
  short_file
)
readr::write_csv(cmp, all_file)

# ---- tiny Top-N plot ----
top_n <- 20L
png_file <- file.path(out_dir, sprintf("vaccination_compare_top%d.png", top_n))

if (nrow(cmp) > 0) {
  # robust top_n and safe deltas
  cmp2 <- cmp %>%
    dplyr::mutate(
      delta_value = as.numeric(delta_value),
      delta_abs   = abs(delta_value)
    ) %>%
    dplyr::arrange(dplyr::desc(delta_abs))

  top_n_eff <- min(top_n, nrow(cmp2))
  plt_data <- dplyr::slice_head(cmp2, n = top_n_eff)

  plt <- ggplot2::ggplot(
    plt_data,
    ggplot2::aes(x = reorder(iso3c, delta_abs), y = delta_value, fill = direction)
  ) +
    ggplot2::geom_col() +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.1f", delta_value)),
      hjust = ifelse(plt_data$delta_value >= 0, -0.1, 1.1),
      size = 3
    ) +
    ggplot2::coord_flip(clip = "off") +
    ggplot2::labs(
      title = sprintf("Nearest vs Max — Δ (doses/100), top %d by |Δ|", top_n_eff),
      subtitle = paste0(
        "Target: ", as.character(VAX_TARGET_DATE),
        "  •  n=", nrow(cmp),
        "  •  changed=", sum(plt_data$delta_abs > 0, na.rm = TRUE),
        "  •  exact/before/after = ",
        sum(cmp$direction == "exact", na.rm = TRUE), "/",
        sum(cmp$direction == "before", na.rm = TRUE), "/",
        sum(cmp$direction == "after", na.rm = TRUE)
      ),
      x = "ISO3C (largest |Δ| first)",
      y = "vacc_nearest - vacc_max",
      fill = "Relative to 2023-05-05"
    ) +
    ggplot2::scale_fill_manual(
      values = c(before = "#1f77b4", exact = "#2ca02c", after = "#d62728")
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(plot.margin = ggplot2::margin(5.5, 20, 5.5, 5.5))

  ggplot2::ggsave(png_file, plt, width = 7, height = 6, dpi = 120)
  cat("[schnell_vergleich] plot -> ", png_file)
}
