#!/usr/bin/env bash
set -euo pipefail

# Build architecture.md with Pandoc's real TeX PDF path.  Mermaid is rendered
# only with already-installed tools; no package manager or browser download is
# performed by this script.

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

MARKDOWN="$TMP/architecture.md"
MERMAID_RENDERED=0
MERMAID_BROWSER=""

# Puppeteer bundled with mmdc may look for a cached Chrome revision even when a
# system browser exists.  Prefer an explicit executable so an installed Chrome
# can be used without downloading anything.
for candidate in "${PUPPETEER_EXECUTABLE_PATH:-}" chromium chromium-browser \
                 google-chrome google-chrome-stable; do
  [[ -n "$candidate" ]] || continue
  if [[ "$candidate" == /* ]]; then
    [[ -x "$candidate" ]] || continue
    MERMAID_BROWSER="$candidate"
  else
    MERMAID_BROWSER=$(command -v "$candidate" || true)
  fi
  [[ -n "$MERMAID_BROWSER" ]] && break
done

render_mermaid() {
  local rendered_md="$TMP/mermaid.md"
  local converted=1
  local svg pdf count=0

  [[ -n "$MERMAID_BROWSER" ]] || return 1
  PUPPETEER_EXECUTABLE_PATH="$MERMAID_BROWSER" \
    mmdc -i "$INPUT" -o "$rendered_md" -q >/dev/null 2>&1 || return 1

  # Pandoc's LaTeX writer can include PDF graphics portably.  mmdc emits SVG
  # files for a Markdown input; convert each one before rewriting the image
  # references in the temporary Markdown.
  for svg in "$TMP"/mermaid-*.svg; do
    [[ -f "$svg" ]] || continue
    count=$((count + 1))
    pdf="${svg%.svg}.pdf"
    if command -v rsvg-convert >/dev/null 2>&1; then
      rsvg-convert -f pdf -o "$pdf" "$svg" >/dev/null 2>&1 || converted=0
    elif command -v inkscape >/dev/null 2>&1; then
      inkscape "$svg" --export-type=pdf --export-filename="$pdf" \
        >/dev/null 2>&1 || converted=0
    else
      converted=0
    fi
    [[ "$converted" -eq 1 ]] || break
  done
  [[ "$converted" -eq 1 && "$count" -gt 0 ]] || return 1

  sed 's/\.svg)/.pdf)/g' "$rendered_md" > "$TMP/mermaid-pdf.md"
  MARKDOWN="$TMP/mermaid-pdf.md"
  return 0
}

# mmdc accepts Markdown and rewrites Mermaid fences to image references.  A
# successful SVG plus PDF conversion is the renderer capability check;
# missing Chrome/converter (or a malformed diagram) deliberately takes the
# source-preserving fallback below.
if command -v mmdc >/dev/null 2>&1 && render_mermaid; then
  MERMAID_RENDERED=1
else
  awk '
    BEGIN { in_mermaid = 0 }
    /^```mermaid[[:space:]]*$/ {
      print ""
      print "**Diagram source (Mermaid; renderer unavailable).**"
      print ""
      print "```text"
      in_mermaid = 1
      next
    }
    in_mermaid && /^```[[:space:]]*$/ {
      print "```"
      in_mermaid = 0
      next
    }
    { print }
  ' "$INPUT" > "$MARKDOWN"
fi

if [[ "$MERMAID_RENDERED" -eq 1 ]]; then
  echo "pandoc=$PANDOC mermaid_renderer=mmdc+pdf browser=$MERMAID_BROWSER"
else
  echo "pandoc=$PANDOC mermaid_renderer=verbatim (no working mmdc/browser/image converter)"
fi

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
