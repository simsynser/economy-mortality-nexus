# 04b_plots_scatter.R — Scatter Plot Matrix for Key Variable Relationships
# ============================================================================
# Purpose: Create 2x3 grid of scatter plots showing relationships between
#          GDP, demographics, health systems, vaccination, and excess mortality
#
# Dependencies: df_complete_all_analysis.csv (from 03_analysis.R)
# Outputs: scatter_plot_matrix.png, individual plot files (optional)
#
# Plot Structure:
# Row 1: GDP relationships (GDP vs Age, GDP vs Vaccination, GDP vs UHC)
# Row 2: Mortality relationships (Age vs Mortality, Vaccination vs Mortality, UHC vs Mortality)
# ============================================================================

source(here::here("ready_to_import", "00_library_loader.R"))
suppressPackageStartupMessages({
  library(ggplot2)
  library(ggrepel)
  library(cowplot)
  library(scales)
})

# ---- Data Loading & Validation ----
in_file <- here::here("ready_to_import", "data_manipulated", "analysis_table.csv")
complete_cases_file <- here::here("ready_to_import", "data_manipulated", "df_complete_all_analysis.csv")
out_dir <- here::here("ready_to_import", "plots")

stopifnot(file.exists(in_file))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load both datasets
dat <- readr::read_csv(in_file, show_col_types = FALSE)

# Load complete cases if available, otherwise create from main dataset
if (file.exists(complete_cases_file)) {
  df_complete_all <- readr::read_csv(complete_cases_file, show_col_types = FALSE)
} else {
  message("Creating complete cases dataset...")
  df_complete_all <- dat %>%
    dplyr::filter(
      !is.na(gdp), !is.na(median_age), !is.na(vacc),
      !is.na(uhc), !is.na(excess_mort)
    )
}

message("Data loaded: ", nrow(dat), " total countries, ", nrow(df_complete_all), " complete cases")

# ---- Helper Function: Correlation Label ----
# Computes Pearson and Spearman correlations with sample size for plot annotation
calc_cor <- function(df, xvar, yvar) {
  df_sub <- df[, c(xvar, yvar)]
  df_sub <- df_sub[complete.cases(df_sub), ]

  if (nrow(df_sub) < 2) {
    return("N<2")
  }

  pearson <- cor(df_sub[[xvar]], df_sub[[yvar]], method = "pearson")
  spearman <- cor(df_sub[[xvar]], df_sub[[yvar]], method = "spearman")

  paste0("r = ", round(pearson, 3), ", ρ = ", round(spearman, 3), ", n = ", nrow(df_sub))
}

# ---- Common Theme Function ----
# Standardized theme for all plots to ensure consistency
scatter_theme <- function() {
  theme_minimal(base_family = "Arial", base_size = 8) +
    theme(
      axis.title = element_text(size = 8, face = "bold"),
      axis.text = element_text(size = 8),
      axis.line = element_line(size = 0.4, color = "black"),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA, size = 0.5)
    )
}

# ---- Individual Scatter Plots ----

# Plot 1: GDP vs Median Age (Development-Demographics relationship)
plot1 <- {
  corr_label <- calc_cor(df_complete_all, "gdp", "median_age")
  ggplot(dat, aes(x = gdp, y = median_age)) +
    geom_point(size = 1.5, alpha = 0.7) +
    geom_text_repel(
      data = df_complete_all, aes(label = iso3c),
      size = 2, max.overlaps = 15, box.padding = 0.25, point.padding = 0.2
    ) +
    annotate("text",
      x = Inf, y = Inf, label = corr_label,
      hjust = 1.1, vjust = 1.2, size = 3.5, family = "Arial"
    ) +
    scale_x_continuous(labels = comma) +
    xlab("GDP per capita 2022 (international-$)") +
    ylab("Median age (years)") +
    scatter_theme()
}

# Plot 2: GDP vs Vaccination (Economic capacity-vaccination rollout)
plot2 <- {
  corr_label <- calc_cor(df_complete_all, "gdp", "vacc")
  ggplot(dat, aes(x = gdp, y = vacc)) +
    geom_point(size = 1.5, alpha = 0.7) +
    geom_text_repel(
      data = df_complete_all, aes(label = iso3c),
      size = 2, max.overlaps = 15, box.padding = 0.25, point.padding = 0.2
    ) +
    annotate("text",
      x = Inf, y = Inf, label = corr_label,
      hjust = 1.1, vjust = 1.2, size = 3.5, family = "Arial"
    ) +
    scale_x_continuous(
      limits = c(0, 140000),
      breaks = c(0, 20000, 40000, 60000, 80000, 100000, 120000, 140000),
      labels = comma
    ) +
    xlab("GDP per capita 2022 (international-$)") +
    ylab("Cumulative vaccination doses, May 5 2023 (per 100)") +
    scatter_theme()
}

# Plot 3: GDP vs UHC (Economic development-health system strength)
plot3 <- {
  corr_label <- calc_cor(df_complete_all, "gdp", "uhc")
  ggplot(dat, aes(x = gdp, y = uhc)) +
    geom_point(size = 1.5, alpha = 0.7) +
    geom_text_repel(
      data = df_complete_all, aes(label = iso3c),
      size = 2, max.overlaps = 15, box.padding = 0.25, point.padding = 0.2
    ) +
    annotate("text",
      x = Inf, y = Inf, label = corr_label,
      hjust = 1.1, vjust = 1.2, size = 3.5, family = "Arial"
    ) +
    scale_x_continuous(
      limits = c(0, 140000),
      breaks = c(0, 20000, 40000, 60000, 80000, 100000, 120000, 140000),
      labels = comma
    ) +
    xlab("GDP per capita 2022 (international-$)") +
    ylab("Essential health services (UHC Index) 2021") +
    scatter_theme()
}

# Plot 4: Age vs Excess Mortality (Demographic vulnerability-mortality outcomes)
plot4 <- {
  corr_label <- calc_cor(df_complete_all, "median_age", "excess_mort")
  ggplot(dat, aes(x = median_age, y = excess_mort)) +
    geom_point(size = 1.5, alpha = 0.7) +
    geom_text_repel(
      data = df_complete_all, aes(label = iso3c),
      size = 2, max.overlaps = 15, box.padding = 0.25, point.padding = 0.2
    ) +
    annotate("text",
      x = Inf, y = Inf, label = corr_label,
      hjust = 1.1, vjust = 1.2, size = 3.5, family = "Arial"
    ) +
    xlab("Median age (years)") +
    ylab("Cumulative excess mortality, May 5 2023 (per 100k)") +
    scatter_theme()
}

# Plot 5: Vaccination vs Excess Mortality (Vaccination coverage-mortality protection)
plot5 <- {
  corr_label <- calc_cor(df_complete_all, "vacc", "excess_mort")
  ggplot(dat, aes(x = vacc, y = excess_mort)) +
    geom_point(size = 1.5, alpha = 0.7) +
    geom_text_repel(
      data = df_complete_all, aes(label = iso3c),
      size = 2, max.overlaps = 15, box.padding = 0.25, point.padding = 0.2
    ) +
    annotate("text",
      x = Inf, y = Inf, label = corr_label,
      hjust = 1.1, vjust = 1.2, size = 3.5, family = "Arial"
    ) +
    xlab("Cumulative vaccination doses, May 5 2023 (per 100)") +
    ylab("Cumulative excess mortality, May 5 2023 (per 100k)") +
    scatter_theme()
}

# Plot 6: UHC vs Excess Mortality (Health system strength-mortality outcomes)
plot6 <- {
  corr_label <- calc_cor(df_complete_all, "uhc", "excess_mort")
  ggplot(dat, aes(x = uhc, y = excess_mort)) +
    geom_point(size = 1.5, alpha = 0.7) +
    geom_text_repel(
      data = df_complete_all, aes(label = iso3c),
      size = 2, max.overlaps = 15, box.padding = 0.25, point.padding = 0.2
    ) +
    annotate("text",
      x = Inf, y = Inf, label = corr_label,
      hjust = 1.1, vjust = 1.2, size = 3.5, family = "Arial"
    ) +
    xlab("Essential health services (UHC Index) 2021") +
    ylab("Cumulative excess mortality, May 5 2023 (per 100k)") +
    scatter_theme()
}

# ---- Combine Plots into 2x3 Grid ----
plot_matrix <- plot_grid(
  plot1, plot2, plot3,
  plot4, plot5, plot6,
  ncol = 3, nrow = 2,
  labels = c("A", "B", "C", "D", "E", "F"),
  label_size = 10
)

# ---- Export Results ----
# Save combined plot
ggsave(
  filename = file.path(out_dir, "scatter_plot_matrix.png"),
  plot = plot_matrix,
  width = 12, height = 8, dpi = 300, bg = "white"
)

# Optionally save individual plots
if (Sys.getenv("SAVE_INDIVIDUAL_PLOTS", "FALSE") == "TRUE") {
  ggsave(file.path(out_dir, "gdp_vs_age.png"), plot1, width = 4, height = 3, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, "gdp_vs_vaccination.png"), plot2, width = 4, height = 3, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, "gdp_vs_uhc.png"), plot3, width = 4, height = 3, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, "age_vs_mortality.png"), plot4, width = 4, height = 3, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, "vaccination_vs_mortality.png"), plot5, width = 4, height = 3, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, "uhc_vs_mortality.png"), plot6, width = 4, height = 3, dpi = 300, bg = "white")
  message("Individual plots saved to ", out_dir)
}

# ---- Summary Statistics ----
correlations_summary <- data.frame(
  relationship = c("GDP-Age", "GDP-Vaccination", "GDP-UHC", "Age-Mortality", "Vaccination-Mortality", "UHC-Mortality"),
  correlation_label = c(
    calc_cor(df_complete_all, "gdp", "median_age"),
    calc_cor(df_complete_all, "gdp", "vacc"),
    calc_cor(df_complete_all, "gdp", "uhc"),
    calc_cor(df_complete_all, "median_age", "excess_mort"),
    calc_cor(df_complete_all, "vacc", "excess_mort"),
    calc_cor(df_complete_all, "uhc", "excess_mort")
  )
)

# Export summary
readr::write_csv(correlations_summary, file.path(out_dir, "scatter_correlations_summary.csv"))

message("Scatter plot matrix saved to: ", file.path(out_dir, "scatter_plot_matrix.png"))
message("Correlation summary saved to: ", file.path(out_dir, "scatter_correlations_summary.csv"))
message("Complete cases used: ", nrow(df_complete_all), " countries")
