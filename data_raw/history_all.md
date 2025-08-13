file,commit,date,author,path_at_commit,blob_sha,sha256,bytes
TRUE LAST CHECK DATE: data/Age/age2022.csv,6c5843333df792d72601609e277fd925bcee78a5,2025-03-20 14:57:20 +0100,Neuwirth Christian,data/Age/age2022.csv,dc64d65951a46ad8efb4757cb552a213a24b63a2,69ee19307210f137b5f9d358977091d7d8f8cd35a56f43af040ced5eedbd1bf1,6860
TRUE LAST CHECK DATE: data/gdp/gdp-per-capita-worldbank.csv,e06598afeb423485243ba199bcf312e85dd29d5d,2024-12-09 15:07:57 +0100,Neuwirth Christian,data/gdp/gdp-per-capita-worldbank.csv,db50e140d02c9f2cdac18da040e02e660ab6f1df,45f08de26c8a93dd87d1715ca89169ec33dc815572b67a3e75c7e0580068a5c2,190896
TRUE LAST CHECK DATE: data/health/healthcare-access-quality-un.csv,493446855a8ab49642f4a4f8f903c9d7018dc596,2024-12-09 14:46:37 +0100,Neuwirth Christian,data/health/healthcare-access-quality-un.csv,cfc5c8c29183cbae3f164772793038efd66e9964,f40d5eea13d74669b94dc2ff3ab5c3eec5baf013f2e4f38785c6058e19f93677,31753
TRUE LAST CHECK DATE: data/mortality/withoutEstimates/cumulative-excess-deaths-per-million-covid.csv,3753c660ab2ec0dd7dfb92bee4c9e09910c8decb,2025-04-06 21:23:35 +0200,Neuwirth Christian,data/mortality/withoutEstimates/cumulative-excess-deaths-per-million-covid.csv,fdc1fff90b4435143af9c99fed6742876f2f06b4,73ddb48633bfbde529b0cec061e4c49b6fe2afa05f0b15004eae62e7f0034dd5,461373
TRUE LAST CHECK DATE: data/vaccination/covid-19-vaccine-doses-administered-per-100-people(1).csv,84dcbbbb73ac4639be33d708fab7880cec05fb1e,2025-03-21 13:40:26 +0100,Neuwirth Christian,data/covid-19-vaccine-doses-administered-per-100-people(1).csv,f32d394c29708dbf61be29716ea605a3ad6204f1,954c09d9cb5fdbc7b8268345648c3408fe4bb311041a2f63e4b94207df87edc2,2578413

We used the versions of each dataset as synchronized in our repository on:
median age (UN WPP via OWID): 2025-03-20;
GDP per capita (World Bank): 2024-12-09;
UHC service coverage index (WHO via World Bank): 2024-12-09;
excess mortality (WHO/OWID): 2025-04-06;
vaccination doses (OWID): 2025-03-21.



| Dataset                          | Source                          | License         | Retrieval Date |
|----------------------------------|----------------------------------|------------------|----------------|
| Median age (2022)                | UN WPP via Our World in Data     | UN (CC BY 3.0 IGO); OWID (CC BY 4.0) | 2025-03-20 |
| GDP per capita (2022)            | World Bank                       | CC BY 4.0        | 2024-12-09     |
| UHC Service Coverage Index (2021)| WHO via World Bank               | CC BY 3.0 IGO    | 2024-12-09     |
| Excess mortality (until 05-05-23)| Our World in Data                | CC BY 4.0        | 2025-04-06     |
| Vaccination doses per 100 (2023) | Our World in Data                | CC BY 4.0        | 2025-03-21     |


Double-check licensing on each data provider’s website for the specific dataset.

If redistributing the raw CSV files in your repo, add a LICENSES-THIRD-PARTY/ directory with small text files, e.g.:


**licenses/un_median_age_wpp2024.txt**

Median Age – World Population Prospects 2024 (Online Edition)
Source: United Nations, Department of Economic and Social Affairs, Population Division
License: Creative Commons Attribution 3.0 IGO (CC BY 3.0 IGO)
Suggested citation: United Nations, Department of Economic and Social Affairs, Population Division (2024). World Population Prospects 2024, Online Edition.
URL: https://population.un.org/wpp/
Retrieved for this repository: 2025-03-20
Disclaimer: The data and materials do not imply the expression of any opinion by the United Nations regarding the legal status of any country, territory, city, or area, or of its authorities, or concerning the delimitation of its frontiers or boundaries.


**licenses/gdp_per_capita_worldbank.txt**

GDP per capita (current US$) – Indicator ID NY.GDP.PCAP.CD
Source: World Bank – World Development Indicators
Original data from: Country official statistics, National Statistical Organizations and/or Central Banks; National Accounts data files, OECD; Staff estimates, World Bank.
License: Creative Commons Attribution 4.0 International (CC BY 4.0)
URL: https://data.worldbank.org/indicator/NY.GDP.PCAP.CD
Retrieved for this repository: 2024-12-09


**licenses/uhc_service_coverage_index_who.txt**

UHC Service Coverage Index – World Health Organization
Source: WHO Member States; WHO Global Health Observatory
License: Creative Commons Attribution 4.0 International (CC BY 4.0) + WHO Additional Terms
Mandatory conditions:
 - Dispute settlement via UNCITRAL Arbitration Rules
 - No de-anonymisation or falsification/misrepresentation of data
 - No implication of WHO endorsement
URL: https://data.who.int/indicators/i/3805B1E/9A706FD
Retrieved for this repository: 2024-12-09


**licenses/owid_vaccine_doses_per100.txt**

Vaccine Doses (per 100 people) – COVID-19
Source: Official data collated by Our World in Data (2024); World Health Organization (2025); Population based on various sources (2024)
Dataset description: Total number of COVID-19 vaccination doses administered per 100 people in the total population. Includes primary series and boosters. Per-capita estimates use 2022 population values.
License: CC BY 4.0 (Our World in Data & WHO, with WHO additional terms: no endorsement, no de-anonymization, arbitration clause).
URL: https://ourworldindata.org/covid-vaccinations
Retrieved for this repository: 2025-03-21
Notes: Vaccination coverage can exceed 100% if population estimates differ from actual population sizes.
Disclaimer: WHO does not endorse the user, use of data, or any resulting analyses. OWID data processing includes standardizing country names, converting units, and calculating derived indicators.


**licenses/excess_mortality_hmd_wmd.txt**

Excess Mortality – Cumulative deaths per million (COVID-19)
Source: Human Mortality Database (STMF); World Mortality Dataset (Karlinsky & Kobak) – processed by Our World in Data
Dataset file in this repo: cumulative-excess-deaths-per-million-covid.csv
License: CC BY 4.0 (see HMD STMF Note & WMD repo; OWID redistributes under CC BY 4.0)
Retrieved for this repository: 2025-04-06
