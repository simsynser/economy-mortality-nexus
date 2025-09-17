# 03_analysis.R — Correlation
# ------------------------------------------------------------
in_file <- here::here("ready_to_import", "data_manipulated", "analysis_table.csv")
out_dir <- here::here("ready_to_import", "data_manipulated")
plot_dir <- out_dir

stopifnot(file.exists(in_file))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(plot_dir, recursive = TRUE, showWarnings = FALSE)

dat <- readr::read_csv(in_file, show_col_types = FALSE)

required_cols <- c("iso3c", "median_age", "gdp", "uhc", "vacc", "excess_mort")
missing_cols <- setdiff(required_cols, names(dat))
if (length(missing_cols)) {
  stop("analysis_table.csv fehlt Spalten: ", paste(missing_cols, collapse = ", "))
}

# ---- Helper: Correlation + NA Count --------------------------------------
calc_cor_and_lost <- function(df, xvar, yvar) {
  total_count <- nrow(df)

  # Subset of those two variables
  df_sub <- df[, c(xvar, yvar)]
  # Pairwise drop NA
  df_sub_complete <- df_sub[complete.cases(df_sub), ]

  complete_count <- nrow(df_sub_complete)
  lost_count_na <- total_count - complete_count

  # When <2 complete points, cor() fails
  if (complete_count < 2) {
    return(list(
      xvar = xvar,
      yvar = yvar,
      n_total = total_count,
      lost_count_na = lost_count_na,
      n_used = complete_count,
      pearson = NA,
      spearman = NA,
      message = "Not enough points for correlation!"
    ))
  }

  # Compute Pearson & Spearman
  pearson <- cor(df_sub_complete[[xvar]], df_sub_complete[[yvar]], method = "pearson")
  spearman <- cor(df_sub_complete[[xvar]], df_sub_complete[[yvar]], method = "spearman")

  list(
    xvar = xvar,
    yvar = yvar,
    n_total = total_count,
    lost_count_na = lost_count_na,
    n_used = complete_count,
    pearson = round(pearson, 3),
    spearman = round(spearman, 3),
    message = "OK"
  )
}


pairs <- list(
  c("gdp", "median_age"),
  c("gdp", "vacc"),
  c("gdp", "uhc"),
  c("median_age", "excess_mort"),
  c("vacc", "excess_mort"),
  c("uhc", "excess_mort")
)

# ---- Calc and Console Output --------------------------------------
results_list <- lapply(pairs, function(vars) {
  xvar <- vars[1]
  yvar <- vars[2]

  res <- calc_cor_and_lost(dat, xvar, yvar)

  cat("\n========================================\n")
  cat("Correlating", res$xvar, "vs.", res$yvar, "\n")
  cat("Total rows in dataset:", res$n_total, "\n")
  cat("Lost rows (NA):", res$lost_count_na, "\n")
  cat("Rows used for correlation:", res$n_used, "\n")
  cat("Pearson’s r:", res$pearson, "\n")
  cat("Spearman’s rho:", res$spearman, "\n")
  cat("Message:", res$message, "\n")

  res
})

results_df <- do.call(
  rbind,
  lapply(results_list, function(x) {
    data.frame(
      xvar = x$xvar,
      yvar = x$yvar,
      n_total = x$n_total,
      lost_count_na = x$lost_count_na,
      n_used = x$n_used,
      pearson = x$pearson,
      spearman = x$spearman,
      message = x$message,
      stringsAsFactors = FALSE
    )
  })
)

print(results_df)
readr::write_csv(results_df, file.path(out_dir, "analysis_correlations.csv"))

# ---- Complete Cases (for descriptive and map) ----------------------------------
df_complete_all <- dat %>%
  filter(
    !is.na(gdp),
    !is.na(median_age),
    !is.na(vacc),
    !is.na(uhc),
    !is.na(excess_mort)
  ) %>%
  mutate(continent = countrycode(iso3c, origin = "iso3c", destination = "continent"))

# ---- Table of complete cases -----------------------------------------------
readr::write_csv(
  df_complete_all %>% select(iso3c, continent),
  file.path(out_dir, "analysis_complete_cases.csv")
)
