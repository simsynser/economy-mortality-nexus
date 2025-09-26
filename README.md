# COVID-19 Wealth-Mortality Nexus Analysis Pipeline

## Overview

Modular R pipeline analyzing relationships between economic development, healthcare systems, demographics, and COVID-19 mortality outcomes. Implements GAM-based temporal standardization for robust cross-country comparisons.

## Pipeline Structure

```
ready_to_import/
├── README.md
├── 00_library_loader.R       # Package management & helper functions
├── 01_loader.R               # Raw data loading & ISO standardization  
├── 02_clean.R                # GAM mortality estimation & integration
├── 03_analysis.R             # Correlation analysis & complete cases
├── 04a_plots_correlations.R  # Figure 3: Correlation heatmap
├── 04b_plots_maps.R          # Figure 2: Coverage map
├── 04c_tables.R              # Tables 1 & 2: Subgroup analysis
├── 04d_partial_correlations.R # Section 3.2: Suppression effects
├── DATA_SOURCES.md
├── data_raw/                 # Original datasets
├── data_manipulated/         # Processed data
└── outputs/                  # Final figures, tables, results
```

## Data Sources

See **[DATA_SOURCES.md](DATA_SOURCES.md)** for complete licensing information and snapshot dates.

**Datasets include:**
- Median age (UN WPP via OWID)
- GDP per capita (World Bank WDI)  
- UHC service coverage (WHO via World Bank)
- Excess mortality (HMD/WMD via OWID)
- Vaccination doses (OWID/WHO)

## Key Methodological Improvements

**Vaccination Data:**
- Uses `nearest_date()` approach: closest observation to 2023-05-05 (WHO/OWID standard)
- Ensures temporal consistency across countries
- Alternative: `vaccination_max` (latest available per country)

**GAM Mortality Estimation:**
- Robust error handling with `try()` prevents pipeline crashes
- Dynamic `k` parameter prevents mgcv errors on short time series
- Index-free date prediction eliminates off-by-one errors
- Fallback for dates outside observation range

**ISO3 Standardization:**
- Systematic `map_iso3()` function with manual overrides
- Handles Kosovo, Micronesia, Virgin Islands, Saint Martin
- Prevents country loss due to name matching failures

## Quick Start

```r
# Run complete pipeline via:
source("ready_to_import/01_loader.R")
source("ready_to_import/02_clean.R") 
source("ready_to_import/03_analysis.R")
source("ready_to_import/04a_plots_correlations.R")
source("ready_to_import/04b_plots_maps.R")
source("ready_to_import/04c_tables.R")
source("ready_to_import/04d_partial_correlations.R")
```

## Requirements

```r
required_pkgs <- c(
  "tidyverse", "here", "countrycode", "mgcv", "ppcor",
  "corrplot", "ggplot2", "rnaturalearth", "sf"
)
```

## License

Code: [license here]  
Data: See individual dataset licenses in **[DATA_SOURCES.md](DATA_SOURCES.md)**

