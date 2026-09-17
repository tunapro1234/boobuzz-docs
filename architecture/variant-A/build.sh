#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DOC_ROOT="$ROOT" DOC_IMAGE_WIDTH="60%" exec "$ROOT/../build.sh"
