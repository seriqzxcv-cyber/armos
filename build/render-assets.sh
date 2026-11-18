#!/usr/bin/env bash
# Render SVG branding assets to PNG. Run on the host or inside the builder.
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ASSETS="$PROJECT_ROOT/assets"
OUT="$ASSETS/generated"
mkdir -p "$OUT"

render() {
  local src=$1 out=$2 w=$3 h=$4
  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$w" -h "$h" "$src" -o "$out"
  elif command -v inkscape >/dev/null 2>&1; then
    inkscape "$src" --export-type=png --export-filename="$out" -w "$w" -h "$h" >/dev/null 2>&1
  elif command -v convert >/dev/null 2>&1; then
    convert -background none "$src" -resize "${w}x${h}" "$out"
  else
    echo "No SVG renderer found (install librsvg, inkscape or ImageMagick)" >&2
    return 1
  fi
  echo "rendered $out"
}

render "$ASSETS/logo/armos-logo.svg" "$OUT/armos-logo-512.png" 512 512
render "$ASSETS/logo/armos-logo.svg" "$OUT/armos-logo-256.png" 256 256
render "$ASSETS/logo/armos-logo.svg" "$OUT/armos-logo-128.png" 128 128
render "$ASSETS/logo/armos-wordmark.svg" "$OUT/armos-wordmark.png" 1200 320
render "$ASSETS/wallpapers/armos-dark.svg" "$OUT/armos-dark-4k.png" 3840 2160
render "$ASSETS/wallpapers/armos-dark.svg" "$OUT/armos-dark-1080p.png" 1920 1080
