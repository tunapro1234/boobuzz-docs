#!/usr/bin/env bash
set -euo pipefail

# Build architecture.md without adding a project-wide Node/npm dependency.
# Mermaid is rendered only when an already-installed mmdc + browser works;
# otherwise its source is retained as a labelled verbatim block.

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

# mmdc accepts Markdown and rewrites Mermaid fences to image references.  A
# successful command is the renderer capability check; missing Chromium (or a
# malformed diagram) deliberately takes the source-preserving fallback below.
if command -v mmdc >/dev/null 2>&1 && mmdc -i "$INPUT" -o "$TMP/mermaid.md" -q >/dev/null 2>&1; then
  MARKDOWN="$TMP/mermaid.md"
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

echo "pandoc=$PANDOC mermaid_renderer=$MERMAID_RENDERED"

# Prefer a real TeX engine.  Some minimal TeX installations ship the binary
# but not its format file; in that case Pandoc exits non-zero and we continue
# to the portable groff fallback instead of leaving a half-built PDF behind.
PDF_METHOD=""
for engine in tectonic xelatex pdflatex; do
  if command -v "$engine" >/dev/null 2>&1; then
    echo "trying pdf engine: $engine"
    if "$PANDOC" \
      --from=gfm \
      --standalone \
      --pdf-engine="$engine" \
      --resource-path="$TMP:$ROOT" \
      --variable=geometry:margin=1in \
      --output="$OUTPUT" \
      "$MARKDOWN"; then
      PDF_METHOD="pandoc+$engine"
      break
    fi
    rm -f -- "$OUTPUT"
  fi
done

# groff is present on the development image even when TeX format files are not.
# Pandoc's man output is intentionally a conservative text rendering, but it
# keeps the complete source and produces a useful, dependency-free PDF.
if [[ -z "$PDF_METHOD" ]] && command -v groff >/dev/null 2>&1; then
  echo "trying PDF fallback: pandoc+groff"
  "$PANDOC" --from=gfm --to=man --output="$TMP/architecture.man" "$MARKDOWN"
  groff -k -K utf8 -t -T pdf -man "$TMP/architecture.man" > "$OUTPUT"
  PDF_METHOD="pandoc+groff"
fi

if [[ -z "$PDF_METHOD" || ! -s "$OUTPUT" ]]; then
  echo "no working PDF path (checked tectonic, xelatex, pdflatex, groff)" >&2
  exit 1
fi

echo "pdf_method=$PDF_METHOD"
echo "wrote $OUTPUT"
