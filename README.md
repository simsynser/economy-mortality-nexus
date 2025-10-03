# COVID-19 Economy-Mortality Nexus Analysis Pipeline

## Overview

Modular R pipeline analyzing relationships between economic development, healthcare systems, demographics, and COVID-19 mortality outcomes. Implements GAM-based temporal standardization for robust cross-country comparisons.

## Pipeline Structure

```
├── README.md
├── 00_library_loader.R          # Package management & helper functions
├── 01_loader.R                  # Raw data loading & ISO standardization  
├── 02_clean.R                   # GAM mortality estimation & integration
├── 03_analysis.R                # Correlation analysis & complete cases
├── 04a_plots_correlations.R     # Figure 3: Correlation heatmap
├── 04b_plots_maps.R             # Figure 2: Coverage map
├── 04c_tables.R                 # Tables 1-4: Subgroups, interactions, GDP thresholds
├── 04d_partial_correlations.R   # Section 3.2: Suppression effects
├── 04e_plots_maps_quartile.R    # Quartile distribution maps for all variables
├── DATA_SOURCES.md
├── data_raw/                    # Original datasets
├── data_manipulated/            # Processed data
└── outputs/                     # Final figures, tables, results
```

## Data Sources

See **[DATA_SOURCES.md](DATA_SOURCES.md)** for complete licensing information and snapshot dates.

**Datasets include:**
- Median age (UN WPP 2024 via OWID)
- Population ages 65+ (World Bank WDI via UN WPP)
- GDP per capita, PPP (World Bank WDI, 2017 base year)
- UHC service coverage (WHO via World Bank)
- Cumulative excess mortality (HMD/WMD via OWID)
- Cumulative COVID-19 vaccination doses (OWID/WHO)

## Key Methodological Improvements

**Dual Age Indicators:**
- **Median age** (years): General population age structure
- **Population 65+** (%): Direct measure of high-risk demographic
- Enables robustness checks across different age operationalizations
- Both based on 2022 data (median age: UN WPP; 65+: World Bank WDI)

**Vaccination Data:**
- Uses `nearest_date()` approach: closest observation to 2023-05-05 (WHO/OWID standard)
- Ensures temporal consistency across countries
- Cumulative doses per 100 people

**GAM Mortality Estimation:**
- Robust error handling with `try()` prevents pipeline crashes
- Dynamic `k` parameter prevents mgcv errors on short time series
- Index-free date prediction eliminates off-by-one errors
- Fallback for dates outside observation range

**ISO3 Standardization:**
- Systematic `map_iso3()` function with manual overrides
- Handles Kosovo, Micronesia, Virgin Islands, Saint Martin
- Prevents country loss due to name matching failures

## Analysis Outputs

**Tables:**
- Table 1: Subgroup correlations (median age splits)
- Table 2: Subgroup correlations (age 65+ splits)
- Table 3: OLS interaction models (age × UHC, age × vaccination)
- Table 4: GDP threshold analysis

**Figures:**
- Correlation heatmaps (Pearson & Spearman)
- Coverage maps showing data availability
- Quartile distribution maps for all 6 variables

## Quick Start

```r
# Run complete pipeline:
source("01_loader.R")
source("02_clean.R") 
source("03_analysis.R")
source("04a_plots_correlations.R")
source("04b_plots_maps.R")
source("04c_tables.R")
source("04d_partial_correlations.R")
source("04e_plots_maps_quartile.R")s
```