# Pipeline-Stand (Kurznotiz)

## 1) Daten-Auditing

* Quellen & Lizenzen dokumentiert in **`DATA_SOURCES.md`**.
* In **`ready_to_import/data_raw/**`** liegen zusätzlich **LICENSES**-Texte pro Datensatz.
* **“Last synchronized”** (Repo-Zeitstempel, siehe Git-Historie; nicht die Updatezeiten der Anbieter):

  * Median age (UN WPP via OWID): **2025-03-20**
  * GDP per capita (World Bank): **2024-12-09**
  * UHC service coverage index (WHO via WB): **2024-12-09**
  * Excess mortality (HMD/WMD via OWID): **2025-04-06**
  * Vaccination doses (OWID/WHO): **2025-03-21**

## 2) Library-Loader

* **`ready_to_import/00_library_loader.R`**
  Lädt benötigte R-Pakete, setzt `here()`, und stellt Helper-Funktionen (`map_iso3()`, `nearest_on()`) bereit.

## 3) `01_loader.R`

* Lädt alle Roh-CSV-Dateien aus **`ready_to_import/data_raw/`**.
* Vereinheitlicht ISO3-Codes via `map_iso3()` (inkl. manueller Sonderfälle).

**Impfvarianten (zentraler Switch):**

* `vaccination_max` = letzter verfügbarer Tag (historisches Verhalten).
* `vaccination_nearest` = Datum am nächsten zu **2023-05-05** (Paper-konform nach WHO/OWID-Empfehlung).

**Vergleichsergebnisse (aktueller Lauf):**

* **217** Länder, davon **119** mit geänderten Werten (*nearest ≠ max*), **97** unverändert.
* Größte Abweichungen (Dosen/100): Turkmenistan −51.7, Japan −39.7, Dschibuti −29.1, Spanien −28.1, Tunesien −27.3.

**Artefakte:**

* `data_manipulated/vaccination/vaccination_max.csv`
* `data_manipulated/vaccination/vaccination_nearest.csv`
* Vergleich: `scripts/schnell_vergleich.R` → `vaccination_compare_short.csv`.

**Hinweis zu Stabilität:**
*Mit `nearest` können Länder mit wenigen Beobachtungspunkten früher im Zeitverlauf auftreten > GAM-Fits (in `02_clean.R`) können dort `k`-Warnungen oder Fehler auslösen. Bei `max` tritt das i. d. R. nicht auf, da mehr Datenpunkte bis zum letzten Beobachtungstag vorhanden sind.*

**Downstream-Auswahl im Environment:**
Per **`VAX_SELECTION <- "nearest"`** (empfohlen) oder `"max"`.

## 4) `02_clean.R`

* Ziel: **Excess Mortality** am **2023-05-05** pro Land mittels GAM schätzen.
* VORSICHT! Modell entspricht der ursprünglichen Form (`mgcv::gam(y ~ s(x, bs="cs"))`, GCV-Default) – aber **indexfreie Vorhersage** (direkt am Datum).
* Fallback: Wenn das Ziel-Datum außerhalb des Beobachtungszeitraums liegt, wird der nächstliegende beobachtete Wert genommen.

**Outputs:**

* `data_manipulated/mortality_gam_2023-05-05.csv`
* `data_manipulated/analysis_table.csv` (Join: `iso3c, median_age, gdp, uhc, vacc, vax_day, excess_mort`).

**Dokumentierte Stolpersteine:**

* **Extrapolation:** Falls 05-05-2023 nicht im Beobachtungszeitraum → Fallback auf nächstliegendes Datum (statt NA).
* **Indexierung (alt):** Ursprünglich wurde `(Zieldatum − min(Day))` als Index genutzt > *Off-by-one*-Risiko bei fehlenden Tagen/Zeitzonen.
* Siehe: [https://en.wikipedia.org/wiki/Off-by-one_error](https://en.wikipedia.org/wiki/Off-by-one_error) > Muss man wissen.

* **mgcv::gam() Default:** Ohne `method="REML"` wird Generalized Cross Validation (GCV) genutzt > bei kurzen/rauschigen Reihen können wiggly Fits entstehen ([mgcv Doku](https://cran.r-project.org/package=mgcv)).
* **Kumulativdaten:** Glättung kann lokal zu leichten Nicht-Monotonien führen; da nur ein Stichtagswert extrahiert wird, tolerierbar.

## 5) `03_analysis.R`

* ToDo: Zusammenführung, Korrelations-Tabellen, Teilergebnisse. Sollte nicht vom Original abweichen.

## Offene Punkte / Nächste Schritte

1. **`03_analysis.R`** fertigstellen (Bivariate + Partial Correlations, Tabellen).
2. **Korrelations-Matrix (Fig):** Heatmap mit Pearson-Koeffizienten und *n*.
3. **“Fig Nexus”**: kleines Panel-Bild in README oder eigenes `04_plots.R`.
4. **Map “available data”**: Choropleth der Complete-Cases (\~79 Länder) + Coverage pro Variable.
5. **`run_all.sh`**: Shell-Skript zum Reproduzieren der Pipeline (01 → 02 → 03 …).
