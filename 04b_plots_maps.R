# 04b_plots_maps.R — Coverage Map (Figure 2 from Paper)
# ============================================================================
# Purpose: Figure 2 - Map showing countries with complete records
#          for COVID-19 analysis with GAM-only methodology (n=79)
#
# Dependencies: df_complete_all_analysis.csv (from 03_analysis.R)
# Outputs: coverage_map_clean.png, coverage_map_detailed.png, coverage_summary.csv
#
# Paper Reference: Figure 2. Countries with complete GAM-estimated mortality data
# ============================================================================

source(here::here("ready_to_import", "00_library_loader.R"))

# ---- Data Loading & Validation ----
complete_cases_file <- here::here("ready_to_import", "data_manipulated", "df_complete_all_analysis.csv")
out_dir <- here::here("ready_to_import", "outputs")

stopifnot(file.exists(complete_cases_file))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load complete cases dataset
df_complete_all <- readr::read_csv(complete_cases_file, show_col_types = FALSE)

# ---- Load World Map Data ----
world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

# Fix France & Norway ISO codes (which is a common issue with rnaturalearth)
world <- world %>%
  mutate(iso_a3 = case_when(
    iso_a2_eh == "FR" ~ "FRA",
    iso_a2_eh == "NO" ~ "NOR",
    TRUE ~ iso_a3
  ))

# ---- Create Coverage Map Data ----
# Join world map with complete cases data
map_data <- world %>%
  left_join(df_complete_all, by = c("iso_a3" = "iso3c")) %>%
  filter(region_un != "Antarctica") %>%
  mutate(
    has_complete_data = !is.na(vacc),
    coverage_status = ifelse(has_complete_data, "Complete Data", "Incomplete/No Data")
  )

# ---- Generate Clean Coverage Map ----
coverage_map_clean <- ggplot(data = map_data) +
  geom_sf(aes(fill = coverage_status), color = "white", size = 0.1) +
  scale_fill_manual(
    values = c(
      "Complete Data" = "#104E64",
      "Incomplete/No Data" = "#EFF6FF"
    ),
    na.value = "#F5F5F5"
  ) +
  theme_void() +
  theme(
    legend.position = "none",
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

# ---- Generate Detailed Coverage Map (with context) ----
coverage_map_detailed <- ggplot(data = map_data) +
  geom_sf(aes(fill = coverage_status), color = "#DADADA", size = 0.1) +
  scale_fill_manual(
    name = "Data Availability",
    values = c(
      "Complete Data" = "#104E64",
      "Incomplete/No Data" = "#EFF6FF"
    ),
    na.value = "#F5F5F5"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.line = element_blank(),
    panel.grid = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    plot.caption = element_text(size = 8, color = "gray50", hjust = 0.5)
  ) +
  labs(
    title = paste0("Countries with Complete COVID-19 Data Records (n=", nrow(df_complete_all), ")"),
    subtitle = "Complete records for GDP, population age, vaccination, UHC coverage, and GAM-estimated mortality",
    caption = "Data sources: World Bank, UN, WHO, OWID | GAM-only methodology for temporal standardization"
  )

# ---- Export Both Map Versions ----
ggsave(
  filename = file.path(out_dir, "coverage_map_clean.png"),
  plot = coverage_map_clean,
  width = 10, height = 6, dpi = 300, bg = "white"
)
ggsave(
  filename = file.path(out_dir, "coverage_map_detailed.png"),
  plot = coverage_map_detailed,
  width = 12, height = 7, dpi = 300, bg = "white"
)

# ---- Generate Coverage Summary Statistics ----
# Continental breakdown
continent_summary <- df_complete_all %>%
  count(continent, sort = TRUE, name = "countries") %>%
  mutate(
    percentage = round(100 * countries / sum(countries), 1)
  ) %>%
  arrange(desc(countries))

# Calculate missing countries that couldn't be matched
unmatched_countries <- setdiff(df_complete_all$iso3c, world$iso_a3)
if (length(unmatched_countries) > 0) {
  message(
    "Warning: Could not match these countries to world map: ",
    paste(unmatched_countries, collapse = ", ")
  )
}

# ---- Export Summary Data ----
readr::write_csv(continent_summary, file.path(out_dir, "coverage_by_continent.csv"))

# Export list of all complete case countries
country_list <- df_complete_all %>%
  dplyr::select(iso3c, continent) %>%
  arrange(continent, iso3c)

readr::write_csv(country_list, file.path(out_dir, "complete_cases_country_list.csv"))