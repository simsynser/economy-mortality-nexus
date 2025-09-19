required_pkgs <- c(
  "cocor", "corrplot", "countrycode", "cowplot",
  "ggpubr", "ggrepel", "mgcv", "naniar", "ppcor",
  "rnaturalearth", "rnaturalearthdata", "tidyverse", "here", "scales"
)

install_if_missing <- function(pkgs, repos = getOption("repos")[["CRAN"]] %||% "https://cloud.r-project.org") {
  ip <- rownames(installed.packages())
  to_install <- setdiff(pkgs, ip)
  if (length(to_install)) {
    message("Installing: ", paste(to_install, collapse = ", "))
    install.packages(to_install, repos = repos)
  }
}

install_if_missing(required_pkgs)

# Attach them all
failed <- vapply(required_pkgs, function(p) {
  suppressPackageStartupMessages(require(p, character.only = TRUE))
}, logical(1L), USE.NAMES = TRUE)

if (any(!failed)) {
  stop("Failed to load: ", paste(names(failed)[!failed], collapse = ", "))
}
