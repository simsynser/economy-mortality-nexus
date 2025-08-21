# Kurznotiz: Pipeline-Stand

## 1) Daten-Auditing

* Quellen & Lizenzen sind in **`DATA_SOURCES.md`** beschrieben; in **`ready_to_import/data_raw/**`** liegen zusätzlich kurze **LICENSES-Texte** pro Datensatz.
* **“Last synchronized” (per Git-Historie):**

  * Median age (UN WPP via OWID): **2025-03-20**
  * GDP per capita (World Bank): **2024-12-09**
  * UHC service coverage index (WHO via World Bank): **2024-12-09**
  * Excess mortality (HMD/WMD via OWID): **2025-04-06**
  * Vaccination doses (OWID/WHO): **2025-03-21**
    *Hinweis:* Repo-Zeitstempel der verwendeten Kopien, **nicht** die Anbieter-Updatezeiten.

## 2) Library-Loader

* Neues Skript **`ready_to_import/00_library_loader.R`** (Packages, `here()`, Helper).

## 3) `01_loader.R`

* Lädt alle CSVs aus **`ready_to_import/data_raw/`**, vereinheitlicht ISO3 via `map_iso3()`.

* **Impfvarianten (wichtiger Switch):**

  * `vaccination_max` = letzter verfügbarer Tag (altes Verhalten)
  * `vaccination_nearest` = **nächstes Datum zu 2023-05-05** (Paper-konform)
  * Kurzvergleich (aktueller Lauf): **217** Länder; **119** geänderter Wert (*nearest ≠ max*); **97** gleicher Tag.
  * CSVs zur Einsicht:

    * `ready_to_import/data_manipulated/vaccination/vaccination_max.csv`
    * `ready_to_import/data_manipulated/vaccination/vaccination_nearest.csv`
  * Auswahl per **`VAX_SELECTION <- "nearest"`** (empfohlen) oder `"max"`.

## 4) `02_clean.R` (in Arbeit)

* GAM-Schätzung für Excess Mortality wird auf **exakte Vorhersage am 2023-05-05** umgestellt (kein Index-Trick), inkl. **Warnhinweis bei Extrapolation**.


## Kurzfazit: Impf-Definitionen (`max` vs. `nearest` zu 2023-05-05)

* Verglichen: **217** Länder/Gebiete
* **119** (≈55 %) haben einen **anderen Wert** (*nearest* ≠ *max*)
* **97** (≈45 %) haben **denselben Tag** (*nearest == max*)
* Muster: überwiegend `delta_value < 0` → *nearest* < *max*, weil nach dem 05.05.2023 vielerorts weiter geimpft wurde (spätere Dosen zählen nur bei *max*).

**Top-Abweichungen (Dosen/100):** Turkmenistan −51.7, Japan −39.7, Dschibuti −29.1, Spanien −28.1, Tunesien −27.3.

**Repro:**
`scripts/schnell_Vergleich.R` erzeugt
`ready_to_import/data_manipulated/vaccination/vaccination_compare_short.csv`
mit `delta_value`, `delta_abs`, `day_diff`.

**Empfehlung:** Standardmäßig **`nearest`** verwenden; **`max`** als Sensitivitäts-Variante beibehalten.

# Geplant:

## Geplant für: `02_clean.R` / GAM

* **Warum anpassen?** Das alte Skript griff Vorhersagen per Tagesdifferenz-Index ab (fragil bei Lücken/off-by-one).
* **Plannung:** Vorhersage **für den exakten Modell-Prädiktor** am 2023-05-05; keine manuelle Indexierung.
* **Sicherheit:** Wir loggen je Land die Distanz zum Ziel-Datum und warnen/flaggen **Extrapolation** (wenn 05.05.2023 **außerhalb** der Datenreichweite liegt).


# TODO
3. combine variables in df_complete_all (79 countries)  
4. (append fig nexus) image  
5. create fig correlation matrix pearson  
6. calculate partial correlations  
7. calculate median-split conditional correlations
8. map available data