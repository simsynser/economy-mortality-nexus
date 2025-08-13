# Excess mortality: Cumulative deaths from all causes compared to projection based on previous years, per million people - Data package

This data package contains the data that powers the chart ["Excess mortality: Cumulative deaths from all causes compared to projection based on previous years, per million people"](https://ourworldindata.org/grapher/cumulative-excess-deaths-per-million-covid?v=1&csvType=full&useColumnShortNames=false) on the Our World in Data website. It was downloaded on April 06, 2025.

### Active Filters

A filtered subset of the full data was downloaded. The following filters were applied:

## CSV Structure

The high level structure of the CSV file is that each row is an observation for an entity (usually a country or region) and a timepoint (usually a year).

The first two columns in the CSV file are "Entity" and "Code". "Entity" is the name of the entity (e.g. "United States"). "Code" is the OWID internal entity code that we use if the entity is a country or region. For normal countries, this is the same as the [iso alpha-3](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) code of the entity (e.g. "USA") - for non-standard countries like historical countries these are custom codes.

The third column is either "Year" or "Day". If the data is annual, this is "Year" and contains only the year as an integer. If the column is "Day", the column contains a date string in the form "YYYY-MM-DD".

The final column is the data column, which is the time series that powers the chart. If the CSV data is downloaded using the "full data" option, then the column corresponds to the time series below. If the CSV data is downloaded using the "only selected data visible in the chart" option then the data column is transformed depending on the chart type and thus the association with the time series might not be as straightforward.

## Metadata.json structure

The .metadata.json file contains metadata about the data package. The "charts" key contains information to recreate the chart, like the title, subtitle etc.. The "columns" key contains information about each of the columns in the csv, like the unit, timespan covered, citation for the data etc..

## About the data

Our World in Data is almost never the original producer of the data - almost all of the data we use has been compiled by others. If you want to re-use data, it is your responsibility to ensure that you adhere to the sources' license and to credit them correctly. Please note that a single time series may have more than one source - e.g. when we stich together data from different time periods by different producers or when we calculate per capita metrics using population data from a second source.

## Detailed information about the data


## cum_excess_per_million_proj_all_ages
The cumulative number of excess deaths per million people in the population; cumulated starting 1 January 2020.
Last updated: August 20, 2024  
Unit: deaths per million people  


### How to cite this data

#### In-line citation
If you have limited space (e.g. in data visualizations), you can use this abbreviated in-line citation:  
Human Mortality Database (2024); World Mortality Dataset (2024); Karlinsky and Kobak (2021) and other sources – processed by Our World in Data

#### Full citation
Human Mortality Database (2024); World Mortality Dataset (2024); Karlinsky and Kobak (2021); Human Mortality Database (2024); World Mortality Database (2024); Karlinsky & Kobak (2024) – processed by Our World in Data. “cum_excess_per_million_proj_all_ages” [dataset]. Human Mortality Database, “Human Mortality Database”; World Mortality Database, “World Mortality Database”; Karlinsky & Kobak, “Excess mortality during the COVID-19 pandemic” [original data].
Source: Human Mortality Database (2024), World Mortality Database (2024), Karlinsky & Kobak (2024) – processed by Our World In Data

### What you should know about this data
* Excess deaths is estimated as _Excess deaths = Number of reported deaths - Number of expected deaths_. Excess mortality goes beyond confirmed COVID-19 fatalities by capturing all deaths above a projected baseline, including indirect deaths from pandemic-related disruptions.
* All-cause mortality data is from the Human Mortality Database (HMD) Short-term Mortality Fluctuations project and the World Mortality Dataset (WMD). Both sources are updated weekly.
* We use the baseline estimates by [Ariel Karlinsky and Dmitry Kobak (2021)](https://elifesciences.org/articles/69336) as part of their World Mortality Dataset (WMD).
* We do not use the data from some countries in WMD because they fail to meet the following data quality criteria: 1) at least three years of historical data; and 2) data published either weekly or monthly. The full list of excluded countries and reasons for exclusion can be found in [this spreadsheet](https://docs.google.com/spreadsheets/d/1JPMtzsx-smO3_K4ReK_HMeuVLEzVZ71qHghSuAfG788/edit?usp=sharing).

### Additional information about this data
All-cause mortality data is from the Human Mortality Database (HMD) Short-term Mortality Fluctuations project and the World Mortality Dataset (WMD). Both sources are updated weekly.

We do not use the data from some countries in WMD because they fail to meet the following data quality criteria: 1) at least three years of historical data; and 2) data published either weekly or monthly. The full list of excluded countries and reasons for exclusion can be found in this spreadsheet: https://docs.google.com/spreadsheets/d/1JPMtzsx-smO3_K4ReK_HMeuVLEzVZ71qHghSuAfG788/edit?usp=sharing.

For a full list of source information (i.e., HMD or WMD) country by country, see: https://ourworldindata.org/excess-mortality-covid#source-information-country-by-country.

We calculate P-scores using the reported deaths data from HMD and WMD and the projected deaths since 2020 from WMD (which we use for all countries and regions, including for deaths broken down by age group). The P-score is the percentage difference between the reported number of weekly or monthly deaths since 2020 and the projected number of deaths for the same period based on previous years (years available from 2015 until 2019).

We calculate the number of weekly deaths for the United Kingdom by summing the weekly deaths from England & Wales, Scotland, and Northern Ireland.

For important issues and caveats to understand when interpreting excess mortality data, see our excess mortality page at https://ourworldindata.org/excess-mortality-covid.

For a more detailed description_short of the HMD data, including week date definitions, the coverage (of individuals, locations, and time), whether dates are for death occurrence or registration, the original national source information, and important caveats, see the HMD metadata file at https://www.mortality.org/Public/STMF_DOC/STMFmetadata.pdf.

For a more detailed description_short of the WMD data, including original source information, see their GitHub page at https://github.com/akarlinsky/world_mortality.
In response to the COVID-19 pandemic, the HMD team decided to establish a new data resource: Short-term Mortality Fluctuations (STMF) data series. Objective and internationally comparable data are crucial to determine the effectiveness of different strategies used to address epidemics. Weekly death counts provide the most objective and comparable way of assessing the scale of short-term mortality elevations across countries and time. More details about this data project can be found in the recently published paper (https://www.nature.com/articles/s41597-021-01019-1).

Before using the data, please consult the STMF Methodological Note (https://www.mortality.org/File/GetDocument/Public/STMF_DOC/STMFNote.pdf), which provides a more comprehensive description of this data project, including important aspects related to data collection and data processing. We also recommend that you read the STMF Metadata (https://www.mortality.org/File/GetDocument/Public/STMF_DOC/STMFmetadata.pdf). This document includes country-specific information about data availability, completeness, data sources, as well as specific features of included data.

Data will be frequently updated and new countries will be added. Data are published under CC BY 4.0 license.

For citing STMF data, please follow the HMD data citation guidelines (https://www.mortality.org/Research/CitationGuidelines).

HMD provides an online STMF visualization toolkit (https://mpidr.shinyapps.io/stmortality).
World Mortality Dataset: international data on all-cause mortality.

This dataset contains country-level data on all-cause mortality in 2015–2024 collected from various sources. They are currently providing data for 122 countries and territories.

For a complete and up-to-date list of notes on the dataset, please refer to their GitHub page at https://github.com/akarlinsky/world_mortality/.

For the list of sources that they use, please go to https://github.com/akarlinsky/world_mortality/#sou rces.

Published paper available at https://elifesciences.org/articles/69336.
The data are sourced from the World Mortality Dataset (https://github.com/akarlinsky/world_mortality). Excess mortality is computed relative to the baseline obtained using linear extrapolation of the 2015–19 trend (different baselines for 2020, 2021, and 2022). In each subplot in the figure below, gray lines are 2015–19, black line is baseline for 2020, red line is 2020, blue line is 2021, orange line is 2022. Countries are sorted by the total excess mortality as % of the 2020 baseline.

For more details, refer to https://github.com/dkobak/excess-mortality#excess-mortality-during-the-covid-19-pandemic.

### Sources

#### Human Mortality Database
Retrieved on: 2024-08-20  
Retrieved from: https://www.mortality.org  

#### World Mortality Database
Retrieved on: 2024-08-20  
Retrieved from: https://github.com/akarlinsky/world_mortality  

#### Karlinsky & Kobak – Excess mortality during the COVID-19 pandemic
Retrieved on: 2024-08-20  
Retrieved from: https://github.com/dkobak/excess-mortality  


    