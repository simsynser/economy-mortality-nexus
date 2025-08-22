# Kurznotiz: Pipeline-Stand

## 1) Daten-Auditing

* Quellen & Lizenzen in **`DATA_SOURCES.md`**; in **`ready_to_import/data_raw/**`** liegen **LICENSES** pro Datensatz.
* **“Last synchronized” (per Git-Historie):**
  * Median age (UN WPP via OWID): **2025-03-20**
  * GDP per capita (World Bank): **2024-12-09**
  * UHC service coverage index (WHO via WB): **2024-12-09**
  * Excess mortality (HMD/WMD via OWID): **2025-04-06**
  * Vaccination doses (OWID/WHO): **2025-03-21**
    *Hinweis:* Repo-Zeitstempel der Kopien, **nicht** die Updatezeiten der Anbieter.

## 2) Library-Loader

* **`ready_to_import/00_library_loader.R`**: lädt Packages, setzt `here()`, stellt gemeinsame Helper bereit.

## 3) `01_loader.R`

* Lädt alle CSVs aus **`ready_to_import/data_raw/`**, vereinheitlicht ISO3 via `map_iso3()`.
* **Impfvarianten (wichtiger Switch):**
  * `vaccination_max` = letzter verfügbarer Tag (altes Verhalten)
  * `vaccination_nearest` = **Datum am nächsten zu 2023-05-05** (Paper-konform, empfohlen)
* Kurzvergleich (aktueller Lauf): **217** Länder; **119** mit geändertem Wert (*nearest ≠ max*); **97** gleicher Tag.
  **Top-Abweichungen (Dosen/100):** TKM −51.7, JPN −39.7, DJI −29.1, ESP −28.1, TUN −27.3.
* Artefakte abgelegt:
  * `data_manipulated/vaccination/vaccination_max.csv`
  * `data_manipulated/vaccination/vaccination_nearest.csv`
  * Vergleich: `scripts/schnell_vergleich.R` → `data_manipulated/vaccination/vaccination_compare_short.csv` oder Data > `cmp`
* Auswahl per **`VAX_SELECTION <- "nearest"`** (empfohlen) oder `"max"`.

## 4) `02_clean.R`

* **Excess Mortality** am **2023-05-05** via *altem* GAM **1:1** beibehalten.
* Output-Join: `data_manipulated/analysis_table.csv`
  Spalten: `iso3c, median_age, gdp, uhc, vacc, vax_day, excess_mort`.
* **Bekannte Stolpersteine (dokumentiert im Skript-Header):**
  * **Extrapolation** möglich, wenn 05-05-2023 außerhalb der Reihe liegt.
  * **Index-Abgriff** via `(Zieldatum − min(Day))` -> Off-by-one-Risiko bei Lücken/Zeitzonen.
  * **GCV-Default** in `mgcv::gam()` kann bei kurzen/rauschigen Reihen “wiggly” Fits erzeugen.
  * **Kumulativdaten** können durch Glättung leicht nicht-monoton werden; wir entnehmen nur den Stichtagswert.

## 5) `03_analysis.R`

* **Paarweise Korrelationen** (Pearson/Spearman) inkl. NA-Zeilenverlust-Stats.

  * Aktueller Lauf: **n_total = 242**, **Complete cases = 80** Länder.
  * Ergebnisse:
    * `gdp ~ median_age`: *r* = **0.666**, ρ = **0.855** (n = 180)
    * `gdp ~ uhc`: *r* = **0.717**, ρ = **0.898** (n = 177)
    * `vacc ~ excess_mort`: *r* = **−0.443**, ρ = **−0.470** (n = 88)
* Artefakte:
  * `data_manipulated/analysis_correlations.csv`
  * `data_manipulated/analysis_complete_cases.csv` (Complete-Case-Tabelle inkl. Kontinent)

## Offene Punkte / Nächste Schritte

1. **Korrelations-Matrix (Fig):** Heatmap/Viz der Pearson-Koeffizienten mit *n*-Annot.
2. **Partielle Korrelationen:** z. B. `excess_mort ~ vacc | (gdp, median_age, uhc)`; sauber loggen, welche Länder im Modell landen.
3. **Median-Split / konditionierte Korr.:** 
4. **“Fig Nexus” anfügen:** kleines Panel-Bild in README oder `04_plots.R`.
5. **Map “available data”:** Choropleth der Complete-Cases (80/242) plus Coverage pro Variable.
6. **run_all.sh**: Shell-Skript, das alle Schritte in der richtigen Reihenfolge ausführt noch schreiben.

## Reproduzierbarkeit soweit

1. `01_loader.R`
2. `02_clean.R` → schreibt `analysis_table.csv`
3. `03_analysis.R` → schreibt `analysis_correlations.csv` & `analysis_complete_cases.csv`
*(Optional)* `schnell_vergleich.R` für Delta - Vacc vergleich max() vs nearest.
