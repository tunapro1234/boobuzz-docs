#!/usr/bin/env bash
set -euo pipefail

# Render every Mermaid fence to SVG and PDF, then build the diagram-first
# document with Pandoc and a real TeX engine.  No package or browser download
# is performed; the caller supplies already-installed tools.

ROOT=${DOC_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)}
INPUT="$ROOT/architecture.md"
OUTPUT="$ROOT/architecture.pdf"
DIAGRAM_DIR="$ROOT/diagrams"
IMAGE_WIDTH=${DOC_IMAGE_WIDTH:-95%}
TMP=$(mktemp -d "${TMPDIR:-/tmp}/boobuzz-architecture.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

[[ -f "$INPUT" ]] || { echo "architecture source not found: $INPUT" >&2; exit 1; }

PANDOC=$(command -v pandoc || true)
MMDC=$(command -v mmdc || true)
if [[ -z "$PANDOC" || -z "$MMDC" ]]; then
  echo "pandoc and mmdc are required (no Mermaid fallback is needed on this host)" >&2
  exit 1
fi

BROWSER=""
for candidate in "${PUPPETEER_EXECUTABLE_PATH:-}" \
                 /usr/bin/google-chrome-stable /usr/bin/google-chrome \
                 /usr/bin/chromium /usr/bin/chromium-browser \
                 google-chrome-stable google-chrome chromium chromium-browser; do
  [[ -n "$candidate" ]] || continue
  if [[ "$candidate" == /* ]]; then
    [[ -x "$candidate" ]] || continue
    BROWSER="$candidate"
  else
    BROWSER=$(command -v "$candidate" || true)
  fi
  [[ -n "$BROWSER" ]] && break
done
if [[ -z "$BROWSER" ]]; then
  echo "no usable Chrome/Chromium executable found for mmdc" >&2
  exit 1
fi

mkdir -p "$DIAGRAM_DIR"
find "$DIAGRAM_DIR" -maxdepth 1 -type f \
  \( -name 'diagram-*.svg' -o -name 'diagram-*.pdf' -o -name 'diagram-*.mmd' \) -delete

PUPPETEER_CONFIG="$TMP/puppeteer.json"
printf '{"executablePath":"%s","args":["--no-sandbox"]}\n' "$BROWSER" \
  > "$PUPPETEER_CONFIG"

# Extract Mermaid bodies while replacing only those fences in a temporary
# Markdown copy.  The checked-in architecture.md keeps every source fence.
RENDERED_MD="$TMP/architecture-rendered.md"
COUNT_FILE="$TMP/count"
awk -v outdir="$TMP" -v countfile="$COUNT_FILE" -v width="$IMAGE_WIDTH" '
  BEGIN { n = 0; in_mermaid = 0; file = "" }
  /^```mermaid[[:space:]]*$/ {
    n++
    id = sprintf("%03d", n)
    file = outdir "/diagram-" id ".mmd"
    print "![Diagram " n "](diagrams/diagram-" id ".pdf){width=" width "}"
    in_mermaid = 1
    next
  }
  in_mermaid && /^```[[:space:]]*$/ {
    close(file)
    in_mermaid = 0
    next
  }
  in_mermaid { print > file; next }
  { print }
  END {
    if (in_mermaid) exit 2
    print n > countfile
  }
' "$INPUT" > "$RENDERED_MD"
COUNT=$(<"$COUNT_FILE")
[[ "$COUNT" -ge 15 ]] || { echo "expected at least 15 Mermaid blocks, found $COUNT" >&2; exit 1; }

for source in "$TMP"/diagram-*.mmd; do
  id=$(basename "$source" .mmd)
  svg="$DIAGRAM_DIR/$id.svg"
  pdf="$DIAGRAM_DIR/$id.pdf"
  # Keep the SVG source artifact, but use Mermaid's own PDF renderer for the
  # document.  SVG conversion through rsvg/inkscape drops Mermaid's
  # foreignObject labels; mmdc --pdfFit keeps the labels and trims the page.
  "$MMDC" --input "$source" --output "$svg" \
    --puppeteerConfigFile "$PUPPETEER_CONFIG" --quiet
  "$MMDC" --input "$source" --output "$pdf" --pdfFit \
    --puppeteerConfigFile "$PUPPETEER_CONFIG" --quiet
done

echo "pandoc=$PANDOC mermaid_renderer=mmdc browser=$BROWSER"
echo "rendered_diagrams=$COUNT output_dir=$DIAGRAM_DIR"

# Prefer XeLaTeX when its format exists; otherwise use the repaired pdfLaTeX
# format.  The transliteration is only a build artifact for pdfLaTeX's legacy
# input encoding; checked-in Markdown and Mermaid remain UTF-8.
PDF_METHOD=""
for engine in xelatex pdflatex; do
  if ! command -v "$engine" >/dev/null 2>&1; then
    continue
  fi
  if [[ "$engine" == "xelatex" ]] && command -v kpsewhich >/dev/null 2>&1 \
      && ! kpsewhich xetex/xelatex.fmt >/dev/null 2>&1; then
    echo "skipping pdf engine: xelatex (xelatex.fmt is not installed)"
    continue
  fi
  echo "trying pdf engine: $engine"
  TEX_MARKDOWN="$RENDERED_MD"
  if [[ "$engine" == "pdflatex" ]] && command -v iconv >/dev/null 2>&1; then
    sed \
      -e 's/├/|-/g' -e 's/└/`-/g' -e 's/│/|/g' -e 's/─/-/g' \
      -e 's/→/->/g' -e 's/←/<-/g' -e 's/↔/<->/g' \
      -e 's/π/pi/g' -e 's/ω/omega/g' -e 's/×/x/g' -e 's/±/+\/-/g' \
      -e 's/²/^2/g' -e 's/°/ deg/g' -e 's/–/-/g' -e 's/—/--/g' \
      -e 's/“/"/g' -e 's/”/"/g' -e "s/’/'/g" -e 's/…/.../g' \
      "$RENDERED_MD" | iconv -c -t ASCII//TRANSLIT > "$TMP/pdflatex.md"
    TEX_MARKDOWN="$TMP/pdflatex.md"
  fi
  if "$PANDOC" --from='markdown+raw_tex+fenced_code_attributes' --standalone --pdf-engine="$engine" \
      --resource-path="$ROOT:$TMP" --variable=geometry:margin=1in \
      --output="$OUTPUT" "$TEX_MARKDOWN"; then
    PDF_METHOD="pandoc+$engine"
    break
  fi
  rm -f -- "$OUTPUT"
done

if [[ -z "$PDF_METHOD" || ! -s "$OUTPUT" ]]; then
  echo "no working Pandoc TeX PDF path (checked xelatex, pdflatex)" >&2
  exit 1
fi

echo "pdf_method=$PDF_METHOD"
echo "wrote $OUTPUT"
