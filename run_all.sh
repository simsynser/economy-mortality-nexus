#!/usr/bin/env bash
set -euo pipefail

echo "[1/4] Loader..."
Rscript ready_to_import/01_loader.R

echo "[2/4] Clean + merge..."
Rscript ready_to_import/02_clean_merge.R

echo "[3/4] Analysis..."
Rscript ready_to_import/03_analysis.R

echo "[4/4] Plot..."
Rscript ready_to_import/04_plots.R

echo "Done."
