source("00_library_loader.R")

dir.create("data_raw", showWarnings = FALSE)

source("00_library_loader.R")
dir.create("data_raw", showWarnings = FALSE)

# GDP & UHC (raw ZIPs) --------------------------------------------------
download.file("https://api.worldbank.org/v2/en/indicator/NY.GDP.PCAP.CD?downloadformat=csv",
  "data_raw/gdp.zip",
  mode = "wb", quiet = TRUE
)
download.file("https://api.worldbank.org/v2/en/indicator/SH.UHC.SRVS.CV.XD?downloadformat=csv",
  "data_raw/uhc.zip",
  mode = "wb", quiet = TRUE
)

# Median-age CSV --------------------------------------------------------
download.file(
  "https://population.un.org/wpp/Download/Files/1_Indicators%20(Standard)/CSV_FILES/WPP2024_POP_F16_1_MEDIAN_AGE_BOTH_SEXES.csv",
  "data_raw/median_age.csv",
  mode = "wb", quiet = TRUE
)

# Vaccination long series ----------------------------------------------
download.file(
  "https://ourworldindata.org/grapher/covid-vaccination-doses-per-capita.csv",
  "data_raw/vacc_per_cap.csv",
  mode = "wb", quiet = TRUE
)

# Excess-mortality long series -----------------------------------------
download.file(
  "https://ourworldindata.org/grapher/cumulative-excess-deaths-per-million-covid.csv",
  "data_raw/excess_mort_long.csv",
  mode = "wb", quiet = TRUE
)
