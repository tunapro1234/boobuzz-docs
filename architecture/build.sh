#!/usr/bin/env bash
set -euo pipefail

# Build architecture.md with Pandoc's real TeX PDF path.  Mermaid source is
# intentionally kept as a verbatim code listing in the PDF (no browser or
# package-manager work is required).

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INPUT="$ROOT/architecture.md"
OUTPUT="$ROOT/architecture.pdf"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/boobuzz-architecture.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

if [[ ! -f "$INPUT" ]]; then
  echo "architecture source not found: $INPUT" >&2
  exit 1
fi

PANDOC=$(command -v pandoc || true)
if [[ -z "$PANDOC" ]]; then
  echo "pandoc is required to build $OUTPUT (not installed)" >&2
  exit 1
fi

# Passing the source directly to Pandoc preserves each Mermaid fence as a
# listing.  Deliberately do not invoke mmdc, Chrome, or an image converter.
MARKDOWN="$INPUT"
echo "pandoc=$PANDOC mermaid_renderer=verbatim (rendering disabled by docs-cx-07 amendment)"

# Prefer a real TeX engine.  If a binary has no format file, Pandoc exits
# non-zero and the next installed TeX engine is tried.  Repair a user TeX
# installation once with `fmtutil-user --all` before this script; no system
# packages are installed here.
PDF_METHOD=""
for engine in xelatex pdflatex; do
  if command -v "$engine" >/dev/null 2>&1; then
    echo "trying pdf engine: $engine"
    TEX_MARKDOWN="$MARKDOWN"
    if [[ "$engine" == "pdflatex" ]] && command -v iconv >/dev/null 2>&1; then
      # The installed pdfTeX format is healthy but its default input encoding
      # cannot typeset box-drawing/Greek symbols in the source tree.  This is
      # a build-only transliteration; architecture.md itself remains UTF-8.
      sed \
        -e 's/├/|-/g' -e 's/└/`-/g' -e 's/│/|/g' -e 's/─/-/g' \
        -e 's/→/->/g' -e 's/←/<-/g' -e 's/↔/<->/g' \
        -e 's/π/pi/g' -e 's/ω/omega/g' -e 's/×/x/g' -e 's/±/+\/-/g' \
        -e 's/²/^2/g' -e 's/°/ deg/g' -e 's/–/-/g' -e 's/—/--/g' \
        -e 's/“/"/g' -e 's/”/"/g' -e "s/’/'/g" -e 's/…/.../g' \
        "$MARKDOWN" | iconv -c -t ASCII//TRANSLIT > "$TMP/pdflatex.md"
      TEX_MARKDOWN="$TMP/pdflatex.md"
    fi
    if "$PANDOC" \
      --from=gfm \
      --standalone \
      --pdf-engine="$engine" \
      --resource-path="$TMP:$ROOT" \
      --variable=geometry:margin=1in \
      --output="$OUTPUT" \
      "$TEX_MARKDOWN"; then
      PDF_METHOD="pandoc+$engine"
      break
    fi
    rm -f -- "$OUTPUT"
  fi
done

if [[ -z "$PDF_METHOD" || ! -s "$OUTPUT" ]]; then
  echo "no working Pandoc TeX PDF path (checked xelatex, pdflatex)" >&2
  exit 1
fi

echo "pdf_method=$PDF_METHOD"
echo "wrote $OUTPUT"
