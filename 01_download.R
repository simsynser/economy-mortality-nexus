# 01_download.R — automated downloads matching the old pipeline
source(here::here("ready_to_import", "00_library_loader.R"))

# Create raw download folder
dir.create(here::here("ready_to_import", "data_raw"), showWarnings = FALSE, recursive = TRUE)

# Quiet retrying downloader
dl <- function(url, out, tries = 2) {
  for (i in seq_len(tries)) {
    ok <- try(utils::download.file(url, out, mode = "wb", quiet = TRUE), silent = TRUE)
    if (!inherits(ok, "try-error")) {
      return(invisible(TRUE))
    }
    if (i < tries) Sys.sleep(1.5 * i)
  }
  stop("Failed to download: ", url, " -> ", out)
}

# 1) GDP per capita
dl(
  "https://api.worldbank.org/v2/en/indicator/NY.GDP.PCAP.CD?downloadformat=csv",
  here::here("ready_to_import", "data_raw", "gdp.zip")
)

# 2) UHC service coverage index
dl(
  "https://api.worldbank.org/v2/en/indicator/SH.UHC.SRVS.CV.XD?downloadformat=csv",
  here::here("ready_to_import", "data_raw", "uhc.zip")
)

# 3) Median age — build repo-style age2022.csv directly
dl(
  "https://ourworldindata.org/grapher/median-age.csv",
  here::here("ready_to_import", "data_raw", "median_age.csv")
)

dir.create(here::here("ready_to_import", "data_manipulated"), recursive = TRUE, showWarnings = FALSE)

readr::read_csv(here::here("ready_to_import", "data_raw", "median_age.csv"), show_col_types = FALSE) %>%
  dplyr::filter(Year == 2022, !is.na(Code)) %>%
  dplyr::mutate(
    `Median age - Sex: all - Age: all - Variant: medium` = NA_real_,
    time = Year
  ) %>%
  dplyr::select(
    Entity, Code, Year,
    `Median age - Sex: all - Age: all - Variant: estimates`,
    `Median age - Sex: all - Age: all - Variant: medium`,
    time
  ) %>%
  dplyr::arrange(Entity) %>%
  readr::write_csv(
    here::here("ready_to_import", "data_manipulated", "age", "age2022_from_web.csv"),
    na = "NA"
  )

# 4) Vaccination doses per 100 people
dl(
  "https://ourworldindata.org/grapher/covid-vaccination-doses-per-capita.csv",
  here::here("ready_to_import", "data_raw", "vacc_per_cap.csv")
)

# 5) Excess mortality
dl(
  "https://ourworldindata.org/grapher/cumulative-excess-deaths-per-million-covid.csv",
  here::here("ready_to_import", "data_raw", "excess_mort_long.csv")
)

message("Downloads complete -> ", here::here("ready_to_import", "data_raw"))

# now check via sanity if it is indeed the same str() as the old stationary csv files

# one folder before ready_to_import - data folder:
# age <- readr::read_delim("data/Age/age2022.csv") %>%
# gdp <- gdp_data <- readr::read_csv("data/gdp/gdp-per-capita-worldbank.csv") %>%
# excess_dat <- readr::read_csv("data/mortality/withoutEstimates/cumulative-excess-deaths-per-million-covid.csv")
# vacc <- vaccination_data_clean <- readr::read_csv("data/vaccination/covid-19-vaccine-doses-administered-per-100-people(1).csv") %>%
# uhc essential_health_data <- readr::read_csv("data/health/healthcare-access-quality-un.csv") %>%
