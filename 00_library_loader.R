required_pkgs <- c(
  "readr", "dplyr", "tidyr", "stringr", "rvest", "ppcor", "ggplot2", "ggcorrplot", "sf", "rnaturalearth", "rnaturalearthdata", "rnaturalearthhires",
  "countrycode", "httr", "mgcv"
)

install_if_missing <- function(pkgs, repos = "https://cloud.r-project.org") {
  to_install <- setdiff(pkgs, rownames(installed.packages()))
  if (length(to_install)) {
    message("Installing: ", paste(to_install, collapse = ", "))
    install.packages(to_install, repos = repos, dependencies = TRUE, type = "binary")
  }
}

install_if_missing(required_pkgs)

if (!requireNamespace("rnaturalearthdata", quietly = TRUE)) {
  message("Trying GitHub for rnaturalearthdata …")
  if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
  devtools::install_github("ropensci/rnaturalearthdata")
}

invisible(lapply(required_pkgs, require, character.only = TRUE, quietly = TRUE))
