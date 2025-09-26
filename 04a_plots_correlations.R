# 04a_plots_correlations.R — Correlation Matrix Heatmap (Figure 3 from Paper)
# ============================================================================
# Purpose: Replicate Figure 3 - Pearson correlation matrix showing relationships
#          in the wealth-mortality nexus with 79 countries (GAM-only analysis)
#
# Dependencies: df_complete_all_analysis.csv (from 03_analysis.R)
# Outputs: correlation_matrix_heatmap.png, correlation_matrix_data.csv
#
# Paper Reference: Figure 3. Pearson correlation matrix (n=79 countries, GAM estimates)
# ============================================================================

source(here::here("ready_to_import", "00_library_loader.R"))

# ---- Data Loading & Validation ----
complete_cases_file <- here::here("ready_to_import", "data_manipulated", "df_complete_all_analysis.csv")
out_dir <- here::here("ready_to_import", "outputs")

stopifnot(file.exists(complete_cases_file))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load complete cases dataset
df_complete_all <- readr::read_csv(complete_cases_file, show_col_types = FALSE)

message("Data loaded: ", nrow(df_complete_all), " complete cases for correlation matrix")

# ---- Calculate Pearson Correlation Matrix ----
M_r <- df_complete_all %>%
  dplyr::select(gdp, vacc, median_age, uhc, excess_mort) %>%
  cor(method = "pearson")

# Rename to match paper labels
colnames(M_r) <- c("GDP", "Vacc", "Age", "UHC", "Mort.")
rownames(M_r) <- c("GDP", "Vacc", "Age", "UHC", "Mort.")

# ---- Calculate P-values Matrix ----
cor.mtest_pears <- function(mat, ...) {
  mat <- as.matrix(mat)
  n <- ncol(mat)
  p.mat <- matrix(NA, n, n)
  diag(p.mat) <- 0
  for (i in 1:(n - 1)) {
    for (j in (i + 1):n) {
      tmp <- cor.test(mat[, i], mat[, j], method = "pearson", ...)
      p.mat[i, j] <- p.mat[j, i] <- tmp$p.value
    }
  }
  colnames(p.mat) <- rownames(p.mat) <- colnames(mat)
  p.mat
}

M_r_p <- df_complete_all %>%
  dplyr::select(gdp, vacc, median_age, uhc, excess_mort) %>%
  cor.mtest_pears()

# Rename p-values matrix to match correlation matrix
colnames(M_r_p) <- c("GDP", "Vacc", "Age", "UHC", "Mort.")
rownames(M_r_p) <- c("GDP", "Vacc", "Age", "UHC", "Mort.")


# ---- Generate Correlation Heatmap ----
color <- colorRampPalette(c("#BB4444", "#EE9988", "#FFFFFF", "#77AADD", "#4477AA"))

# Create and save the plot
png(file.path(out_dir, "correlation_matrix_heatmap.png"),
  width = 8, height = 6, units = "in", res = 300, bg = "white"
)

corrplot(M_r,
  method = "ellipse",
  col = color(200),
  type = "full",
  tl.col = "black",
  tl.srt = 45,
  number.cex = 0.8,
  p.mat = M_r_p,
  sig.level = 0.05,
  insig = "blank",
  addCoef.col = "black",
  diag = FALSE,
  title = paste0("Pearson correlation matrix (n=", nrow(df_complete_all), " countries)"),
  mar = c(0, 0, 2, 0)
)

dev.off()

# ---- Export Data ----
# Export correlation matrix
cor_matrix_df <- data.frame(
  Variable = rownames(M_r),
  M_r,
  stringsAsFactors = FALSE
)

readr::write_csv(cor_matrix_df, file.path(out_dir, "correlation_matrix_data.csv"))

# Export key correlations with p-values
key_correlations <- data.frame(
  relationship = c(
    "GDP-Age", "GDP-Vacc", "GDP-UHC", "GDP-Mortality",
    "Age-Mortality", "Vacc-Mortality", "UHC-Mortality"
  ),
  pearson_r = c(
    M_r["GDP", "Age"], M_r["GDP", "Vacc"], M_r["GDP", "UHC"], M_r["GDP", "Mort."],
    M_r["Age", "Mort."], M_r["Vacc", "Mort."], M_r["UHC", "Mort."]
  ),
  p_value = c(
    M_r_p["GDP", "Age"], M_r_p["GDP", "Vacc"], M_r_p["GDP", "UHC"], M_r_p["GDP", "Mort."],
    M_r_p["Age", "Mort."], M_r_p["Vacc", "Mort."], M_r_p["UHC", "Mort."]
  ),
  significant = c(
    M_r_p["GDP", "Age"] <= 0.05, M_r_p["GDP", "Vacc"] <= 0.05,
    M_r_p["GDP", "UHC"] <= 0.05, M_r_p["GDP", "Mort."] <= 0.05,
    M_r_p["Age", "Mort."] <= 0.05, M_r_p["Vacc", "Mort."] <= 0.05,
    M_r_p["UHC", "Mort."] <= 0.05
  )
) %>%
  dplyr::mutate(
    pearson_r = round(pearson_r, 3),
    p_value = round(p_value, 4)
  )

readr::write_csv(key_correlations, file.path(out_dir, "key_correlations_summary.csv"))

# ---- Console Summary ----
message("Correlation heatmap saved to: ", file.path(out_dir, "correlation_matrix_heatmap.png"))
message("Sample size n=", nrow(df_complete_all))

cat("\n=== Key Correlations ===\n")
print(key_correlations)

cat("\n=== Correlation Matrix ===\n")
print(round(M_r, 3))
