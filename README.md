# Pipeline-Stand (Kurznotiz)

## 1) Daten-Auditing
* Quellen & Lizenzen dokumentiert in **`DATA_SOURCES.md`**.
* In **`ready_to_import/data_raw/**`** liegen zusätzlich **LICENSES**-Texte pro Datensatz.
* **"Last synchronized"** (Repo-Zeitstempel, siehe Git-Historie; nicht die Updatezeiten der Anbieter):
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

**Impfvarianten (zentraler "Switch""):**
* `vaccination_max` = letzter verfügbarer Tag (history).
* *`vaccination_nearest`* = Datum am nächsten zu **2023-05-05** (Paper-konform nach WHO/OWID-Empfehlung).

**Vergleichsergebnisse (aktueller Lauf):**
* **217** Länder, davon **119** mit geänderten Werten (*nearest ≠ max*), **97** unverändert.
* Größte Abweichungen (Dosen/100): Turkmenistan −51.7, Japan −39.7, Dschibuti −29.1, Spanien −28.1, Tunesien −27.3.

**Artefakte:**
* `data_manipulated/vaccination/vaccination_max.csv`
* `data_manipulated/vaccination/vaccination_nearest.csv`
* Vergleich: `scripts/schnell_vergleich.R` → `vaccination_compare_short.csv`.

**Hinweis zu Stabilität:**
Mit *`nearest`* können Länder mit wenigen Beobachtungspunkten früher im Zeitverlauf auftreten > GAM-Fits (in *`02_clean.R`*) können  *`k`*-Warnungen oder Fehler auslösen. 
Bei *`max`* tritt das i.d.R. nicht auf, da mehr Datenpunkte bis zum letzten Beobachtungstag vorhanden sind.

**Downstream-Auswahl im Environment:**
Per **`VAX_SELECTION <- "nearest"`** oder `"max"` zur Kontrolle hinzugefügt.

## 4) `02_clean.R`
* Ziel: **Excess Mortality** am **2023-05-05** pro Land mittels GAM schätzen.
* VORSICHT! Modell entspricht der ursprünglichen Form (`mgcv::gam(y ~ s(x, bs="cs"))`, GCV-Default) – aber **indexfreie Vorhersage** (direkt am Datum).
* Fallback: Wenn das Ziel-Datum außerhalb des Beobachtungszeitraums liegt, wird der nächstliegende beobachtete Wert genommen.

**Outputs:**
* `data_manipulated/mortality_gam_2023-05-05.csv`
* `data_manipulated/analysis_table.csv` (Join: `iso3c, median_age, gdp, uhc, vacc, vax_day, excess_mort`).

**Dokumentierte Stolpersteine:**
* **Extrapolation:** Falls 05-05-2023 nicht im Beobachtungszeitraum > Fallback auf nächstliegendes Datum (statt NA).
* **Indexierung (alt):** Ursprünglich wurde `(Zieldatum − min(Day))` als Index genutzt > *Off-by-one*-Risiko bei fehlenden Tagen/Zeitzonen (!!!)
* Siehe: [https://en.wikipedia.org/wiki/Off-by-one_error](https://en.wikipedia.org/wiki/Off-by-one_error) > Muss man wissen.
* **mgcv::gam() Default:** Ohne `method="REML"` wird Generalized Cross Validation (GCV) genutzt > bei kurzen/rauschigen Reihen können wiggly Fits entstehen ([mgcv Doku](https://cran.r-project.org/package=mgcv)).
* **Kumulativdaten:** Glättung kann lokal zu leichten Nicht-Monotonien führen; da nur ein Stichtagswert extrahiert wird, ist aber tolerierbar.

**Wesentliche Verbesserungen gegenüber Original-Code:**
* **Robuste Fehlerbehandlung:** GAM-Fits mit `try()` + Fallbacks verhindern Pipeline-Crashes.
* **Erhöhte Länderabdeckung:** **zusätzliche Länder** erfolgreich prozessiert (126).
* **Dynamic `k`:** Verhindert mgcv-Fehler bei kurzen Zeitreihen durch `k_val <- max(3L, min(10L, n_uniq - 1L))`.
* **Konsistente ISO-Zuordnung:** `map_iso3()` mit manuellen Overrides (Kosovo, Mikronesien, etc.) statt scattered Fixes im Code

**Warum mehr Daten als im Original:**
**Verbesserte ISO3c-Zuordnung:** `map_iso3()` mit systematischen custom matches erfasst Länder, die im Original durch `countrycode()`- Failures verloren gingen.
**Robuste GAM-Behandlung:** Fallbacks für kurze Zeitreihen (<3 Punkte) und numerische GAM-Probleme, wo das Original NA produzierte oder Länder ausschloss.
**Index-freie Datumsvorhersage:** Eliminiert Berechnungsfehler bei `fit[as.Date("2023-05-05") - min(Day)]`, besonders bei Ländern mit unregelmäßigen Zeitabständen.

## 5) `03_analysis.R`
* **Status:** Fertiggestellt. Bivariate Korrelationen (Pearson + Spearman) mit transparenter NA-Behandlung.
* **Datenbasis:** **229 Länder** total, **101 Complete Cases** (44%) für alle 5 Variablen.
* **Key Findings:** Starke Korrelationen Development-Cluster (GDP ↔ UHC: ρ=0.898, GDP ↔ Age: ρ=0.855). Vaccination zeigt immernoch protektiven Effekt (vacc ↔ excess_mort: r=-0.331).

## Offene Punkte / Nächste Schritte
1. **Korrelations-Matrix (Fig):** Heatmap mit Pearson-Koeffizienten und *n*.
2. **"Fig Nexus"**: kleines Panel-Bild in README oder eigenes `04_plots.R`.
3. **Map "available data"**: Choropleth der Complete-Cases (**101 Länder**) + Coverage pro Variable.
4. **`run_all.sh`**: Shell-Skript zum Reproduzieren der Pipeline (01 → 02 → 03 …).
5. **Methodenvergleich:** Optional könnte man original vs. neue GAM-Schätzungen für überlappende Länder direkt vergleichen (aber niedrige Priorität).

Next:

1. Basic Scatter Plot Matrix (04b_plots_scatter.R)

The 6 individual plots (plot1-plot6) and their 2x3 grid
This is the cleanest, most self-contained piece
Uses the calc_cor() helper function

2. Correlation Heatmap (04a_plots_correlations.R)

The corrplot() at the bottom with Pearson correlations
The correlation matrix calculation (M_r, M_r_p)

More Complex (tackle later):
3. Coverage Map (04c_plots_maps.R)

The final map showing complete cases (101 countries)
Should be much simpler than the complex subgroup mapping

4. Subgroup Analysis (04d_plots_subgroup.R)

The complex generate_plot_row() functions with maps + correlations
All the age/UHC splitting logic