# Data sources & licensing

This repository bundles snapshot copies of third-party datasets for reproducibility.  
**Code** in this repo is licensed separately from the **data**; see the per-dataset notices in `licenses/`.

## Snapshot dates (sync points from our Git history)

- **Median age (UN WPP via Our World in Data)**: 2025-03-20  
- **GDP per capita (World Bank, WDI)**: 2024-12-09  
- **UHC service coverage index (WHO / GHO)**: 2024-12-09  
- **Excess mortality (HMD STMF + WMD via Our World in Data)**: 2025-04-06  
- **Vaccination doses (OWID; counts from WHO; population = UN WPP 2022)**: 2025-03-21

## Bundled files

| Dataset | In-repo file(s) | Original source | License |
|---|---|---|---|
| Median age (2022) | `data/Age/age2022.csv` (legacy snapshot); `ready_to_import/data_manipulated/age/age2022_manipulated.csv` (reconstructed) | United Nations, World Population Prospects 2024 – **via** Our World in Data | UN **CC BY 3.0 IGO**; OWID content **CC BY 4.0** |
| GDP per capita (current US$) | `data/gdp/gdp-per-capita-worldbank.csv` | World Bank, World Development Indicators (NY.GDP.PCAP.CD) | **CC BY 4.0** |
| UHC Service Coverage Index (2021) | `data/health/healthcare-access-quality-un.csv` | WHO Global Health Observatory (via World Bank API/OWID) | **CC BY 4.0** + WHO additional terms |
| Excess mortality, cumulative per million (to 2023-05-05) | `data/mortality/withoutEstimates/cumulative-excess-deaths-per-million-covid.csv` | Human Mortality Database (STMF) & World Mortality Dataset (Karlinsky & Kobak) — **processed by** Our World in Data | **CC BY 4.0** |
| COVID-19 vaccine doses per 100 | `data/vaccination/covid-19-vaccine-doses-administered-per-100-people(1).csv` | Our World in Data (counts from WHO; per-capita using UN WPP 2022) | **CC BY 4.0** (+ WHO terms when citing WHO directly) |

### Processing notes

- **Median age (manipulated)**: filtered `Year == 2022`, dropped aggregates (`Code` `NA`), added empty column `Median age - Sex: all - Age: all - Variant: medium` and `time = Year`, then sorted by `Entity` to match the paper’s schema.  
- **Vaccination & excess mortality**: any modeling (e.g., GAM to estimate values at 2023-05-05/08) happens in analysis scripts; raw CSVs here are unaltered snapshots.

## Required notices / disclaimers

- **UN (WPP)**: Data © 2024 United Nations, **CC BY 3.0 IGO**. “The designations employed and the presentation of material do not imply the expression of any opinion by the UN regarding legal status or boundaries.” No UN endorsement implied.
- **WHO**: **CC BY 4.0** with **additional terms** (no endorsement; no de-anonymization/misrepresentation; disputes via UNCITRAL arbitration).  
- **OWID**: Redistributed indicators are **CC BY 4.0**; OWID performs processing (standardization, derived indicators).
- **HMD STMF / WMD**: Redistributed via OWID under **CC BY 4.0**; see their project notes for caveats.

See full texts in `licenses/`.
