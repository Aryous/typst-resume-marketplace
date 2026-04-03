#!/usr/bin/env bash
# Typst compile wrapper for typst-resume skill
# Usage:
#   compile.sh --preview --data <json> --outdir <dir> --templates-dir <dir>
#   compile.sh --final --template <id> --data <json> --outdir <dir> --templates-dir <dir> --timestamp <yyyymmdd-HHmmss>

set -euo pipefail

MODE=""
DATA=""
OUTDIR=""
TEMPLATES_DIR=""
TEMPLATE=""
TIMESTAMP=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --preview)    MODE="preview"; shift ;;
    --final)      MODE="final"; shift ;;
    --data)       DATA="$2"; shift 2 ;;
    --outdir)     OUTDIR="$2"; shift 2 ;;
    --templates-dir) TEMPLATES_DIR="$2"; shift 2 ;;
    --template)   TEMPLATE="$2"; shift 2 ;;
    --timestamp)  TIMESTAMP="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$MODE" || -z "$DATA" || -z "$OUTDIR" || -z "$TEMPLATES_DIR" ]]; then
  echo "Error: --data, --outdir, and --templates-dir are required" >&2
  exit 1
fi

# Read JSON data
RESUME_DATA=$(cat "$DATA")

mkdir -p "$OUTDIR"

if [[ "$MODE" == "preview" ]]; then
  # Batch compile all templates to SVG
  TEMPLATES=("classic" "modern" "minimal" "twocolumn" "academic")
  for tmpl in "${TEMPLATES[@]}"; do
    TMPL_PATH="$TEMPLATES_DIR/${tmpl}.typ"
    OUT_PATH="$OUTDIR/${tmpl}.svg"
    if [[ -f "$TMPL_PATH" ]]; then
      echo "Compiling preview: ${tmpl}..."
      # SVG outputs one file per page; use {p} placeholder then rename page 1
      typst compile \
        --input "resume-data=${RESUME_DATA}" \
        --format svg \
        "$TMPL_PATH" \
        "$OUTDIR/${tmpl}-{p}.svg"
      # Keep only first page, rename to clean name
      mv "$OUTDIR/${tmpl}-1.svg" "$OUT_PATH"
      rm -f "$OUTDIR/${tmpl}"-[0-9]*.svg
    else
      echo "Warning: template not found: $TMPL_PATH" >&2
    fi
  done
  echo "Preview compilation complete. SVGs in: $OUTDIR"

elif [[ "$MODE" == "final" ]]; then
  if [[ -z "$TEMPLATE" || -z "$TIMESTAMP" ]]; then
    echo "Error: --template and --timestamp are required for final mode" >&2
    exit 1
  fi

  TMPL_PATH="$TEMPLATES_DIR/${TEMPLATE}.typ"
  if [[ ! -f "$TMPL_PATH" ]]; then
    echo "Error: template not found: $TMPL_PATH" >&2
    exit 1
  fi

  BASENAME="resume-${TEMPLATE}-${TIMESTAMP}"

  # Compile PDF
  echo "Compiling final PDF: ${BASENAME}.pdf..."
  typst compile \
    --input "resume-data=${RESUME_DATA}" \
    --format pdf \
    "$TMPL_PATH" \
    "$OUTDIR/${BASENAME}.pdf"

  # Copy .typ source
  cp "$TMPL_PATH" "$OUTDIR/${BASENAME}.typ"

  # Copy JSON data
  cp "$DATA" "$OUTDIR/${BASENAME}.json"

  echo "Final compilation complete:"
  echo "  PDF:  $OUTDIR/${BASENAME}.pdf"
  echo "  TYP:  $OUTDIR/${BASENAME}.typ"
  echo "  JSON: $OUTDIR/${BASENAME}.json"

else
  echo "Error: specify --preview or --final" >&2
  exit 1
fi
