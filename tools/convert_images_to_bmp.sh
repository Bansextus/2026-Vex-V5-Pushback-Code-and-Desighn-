#!/bin/bash
set -euo pipefail

# Convert images in the SD card Images folder to 480x240 BMPs.
# Usage: ./tools/convert_images_to_bmp.sh [images_dir]
# Default images_dir: /Volumes/MICROBONK/Images

IMAGES_DIR="${1:-/Volumes/MICROBONK/Images}"

if [[ ! -d "$IMAGES_DIR" ]]; then
  echo "Images folder not found: $IMAGES_DIR"
  exit 1
fi

shopt -s nullglob
converted=0

for file in "$IMAGES_DIR"/*; do
  if [[ -d "$file" ]]; then
    continue
  fi

  filename="$(basename "$file")"
  # Skip hidden/AppleDouble files (e.g. ._IMG_1234.jpeg)
  if [[ "$filename" == .* ]]; then
    continue
  fi

  ext="${file##*.}"
  lower_ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

  # Skip existing BMPs.
  if [[ "$lower_ext" == "bmp" ]]; then
    continue
  fi

  base="${file%.*}"
  out="${base}.bmp"

  echo "Converting: $file -> $out"
  tmp_out="/tmp/$(basename "$out")"
  if /usr/bin/sips -s format bmp -z 240 480 "$file" --out "$tmp_out" >/dev/null; then
    /bin/cp "$tmp_out" "$out"
    /bin/rm -f "$tmp_out"
    converted=$((converted + 1))
  else
    echo "Failed to convert: $file"
    /bin/rm -f "$tmp_out"
  fi
done

echo "Done. Converted $converted file(s) to BMP."
