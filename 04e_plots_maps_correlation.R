# 04e_plots_maps_quartile.R — Quartile Maps for All Variables
# ============================================================================
# Purpose: Generate world maps showing quartile distributions for each variable
# Dependencies: df_complete_all_analysis.csv (from 03_analysis.R)
# Outputs: map_all_variables_quartiles.png
# ============================================================================

source(here::here("00_library_loader.R"))
complete_cases_file <- here::here("data_manipulated", "df_complete_all_analysis.csv")
out_dir <- here::here("outputs")
stopifnot(file.exists(complete_cases_file))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
df_complete_all <- readr::read_csv(complete_cases_file, show_col_types = FALSE)

df_complete_all <- df_complete_all %>%
  mutate(
    gdp_q = cut(gdp,
      breaks = c(-Inf, 17318, 33150, 48115, Inf),
      labels = c("<17k", "17-33k", "33-48k", ">48k")
    ),
    uhc_q = cut(uhc,
      breaks = c(-Inf, 74, 79, 85, Inf),
      labels = c("<74", "74-79", "79-85", ">85")
    ),
    vacc_q = cut(vacc,
      breaks = c(-Inf, 136, 191, 235, Inf),
      labels = c("<136", "136-191", "191-235", ">235")
    ),
    median_age_q = cut(median_age,
      breaks = c(-Inf, 32, 37.7, 41.8, Inf),
      labels = c("<32", "32-38", "38-42", ">42")
    ),
    age_65plus_q = cut(age_65plus,
      breaks = c(-Inf, 8.5, 15.7, 19.9, Inf),
      labels = c("<8.5", "8.5-15.7", "15.7-20", ">20")
    ),
    excess_mort_q = cut(excess_mort,
      breaks = c(-733, 1481, 2751, 4365, Inf),
      labels = c("<1.5k", "1.5-2.8k", "2.8-4.4k", ">4.4k")
    )
  )

world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
world <- world %>%
  mutate(iso_a3 = case_when(
    iso_a2_eh == "FR" ~ "FRA",
    iso_a2_eh == "NO" ~ "NOR",
    TRUE ~ iso_a3
  ))

var_labels <- c(
  gdp_q = "GDP per Capita (2022)\n[PPP, 2017 Int'l $]",
  uhc_q = "UHC Service Coverage (2021)\n[Index 0-100]",
  vacc_q = "COVID-19 Vaccines\n[doses per 100 people, per May 05 2023]",
  median_age_q = "Population Median Age (2022)",
  median_age_q = "Population Median Age (2022)\n[years]",
  excess_mort_q = "Cumulative Excess Mortality\n[per million, 2020 to May 05 2023]"
)

create_quartile_scale <- function(palette_name, level_labels) {
  scale_fill_brewer(
    palette = palette_name,
    na.value = "gray80",
    direction = 1,
    breaks = level_labels,
    guide = guide_legend(
      title = NULL,
      keyheight = unit(1.2, "cm"),
      keywidth = unit(0.8, "cm"),
      label.theme = element_text(size = 11),
      nrow = 4
    )
  )
}

color_scales <- list(
  gdp_q = create_quartile_scale("Blues", c("<17k", "17-33k", "33-48k", ">48k")),
  uhc_q = create_quartile_scale("Greens", c("<74", "74-79", "79-85", ">85")),
  vacc_q = create_quartile_scale("Oranges", c("<136", "136-191", "191-235", ">235")),
  median_age_q = create_quartile_scale("Purples", c("<32", "32-38", "38-42", ">42")),
  age_65plus_q = create_quartile_scale("RdPu", c("<8.5", "8.5-15.7", "15.7-20", ">20")),
  excess_mort_q = create_quartile_scale("Reds", c("<1.5k", "1.5-2.8k", "2.8-4.4k", ">4.4k"))
)

plots_list <- list()
for (var in names(var_labels)) {
  map_data <- world %>%
    left_join(df_complete_all, by = c("iso_a3" = "iso3c")) %>%
    filter(region_un != "Antarctica")

  p <- ggplot(data = map_data) +
    geom_sf(aes_string(fill = var), color = "white", size = 0.15) +
    color_scales[[var]] +
    theme_void() +
    theme(
      legend.position = "right",
      legend.text = element_text(size = 11),
      plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
      plot.margin = margin(5, 5, 5, 5, "pt")
    ) +
    labs(title = var_labels[[var]])

  plots_list[[var]] <- p
}

combined_plot <- wrap_plots(plots_list, ncol = 2) +
  plot_annotation(
    theme = theme()
  )

ggsave(
  filename = file.path(out_dir, "map_all_variables_quartiles.png"),
  plot = combined_plot,
  width = 16, height = 10, dpi = 300, bg = "white"
)

message("[04e] Quartile maps saved to outputs/map_all_variables_quartiles.png")
