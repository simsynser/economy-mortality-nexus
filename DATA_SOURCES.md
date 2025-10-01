# Data sources & licensing

This repository bundles snapshot copies of third-party datasets for reproducibility.  
**Code** in this repo is licensed separately from the **data**; see the per-dataset notices in `data_raw/*/licenses/`.

## Snapshot dates (sync points from our Git history)
- **Population ages 65+ (World Bank WDI via UN WPP)**: 2025-09-29
- **GDP per capita (World Bank, WDI)**: 2024-12-09  
- **UHC service coverage index (WHO / GHO)**: 2024-12-09  
- **Excess mortality (HMD STMF + WMD via Our World in Data)**: 2025-04-06  
- **Vaccination doses (OWID; counts from WHO; population = UN WPP 2022)**: 2025-03-21

## Bundled files

| Dataset | In-repo file(s) | Original source | License |
|---|---|---|---|
| Population 65+ (%) | `data_raw/age_alt/greater_equal65_worldBank.csv` | World Bank WDI (UN World Population Prospects) | **CC BY 4.0** |
| GDP per capita (current US$) | `data_raw/gdp/gdp-per-capita-worldbank.csv` | World Bank, World Development Indicators (NY.GDP.PCAP.CD) | **CC BY 4.0** |
| UHC Service Coverage Index (2021) | `data_raw/health/healthcare-access-quality-un.csv` | WHO Global Health Observatory (via World Bank API/OWID) | **CC BY 4.0** + WHO additional terms |
| Excess mortality, cumulative per million (to 2023-05-05) | `data_raw/mortality/cumulative-excess-deaths-per-million-covid.csv` | Human Mortality Database (STMF) & World Mortality Dataset (Karlinsky & Kobak) — **processed by** Our World in Data | **CC BY 4.0** |
| COVID-19 vaccine doses per 100 | `data_raw/vaccination/covid-19-vaccine-doses-administered-per-100-people.csv` | Our World in Data (counts from WHO; per-capita using UN WPP 2022) | **CC BY 4.0** (+ WHO terms when citing WHO directly) |

### Processing notes
- **Population 65+**: Uses 2022 midyear estimates as percentage of total population. Interpolated from five-year cohort data; may not reflect actual single-year age distributions. Regional aggregates removed based on missing ISO3c codes.
- **Vaccination & excess mortality**: Any temporal modeling (e.g., GAM to estimate values at 2023-05-05) happens in analysis scripts; raw CSVs here are unaltered snapshots.
- **All datasets**: Country name standardization to ISO3c codes handled in analysis pipeline with manual overrides for problematic cases (Kosovo, Micronesia, etc.).

## Required notices / disclaimers
- **UN (WPP)**: Data © 2024 United Nations, **CC BY 3.0 IGO**. "The designations employed and the presentation of material do not imply the expression of any opinion by the UN regarding legal status or boundaries." No UN endorsement implied. Applies to age structure data redistributed via World Bank.
- **World Bank (WDI)**: **CC BY 4.0**. Age structure estimates based on UN WPP; interpolations from five-year cohorts may not reflect actual annual distributions.
- **WHO**: **CC BY 4.0** with **additional terms** (no endorsement; no de-anonymization/misrepresentation; disputes via UNCITRAL arbitration).  
- **OWID**: Redistributed indicators are **CC BY 4.0**; OWID performs processing (standardization, derived indicators).
- **HMD STMF / WMD**: Redistributed via OWID under **CC BY 4.0**; see their project notes for caveats.

See full license texts in `data_raw/*/licenses/` directories.