#!/usr/bin/env bash
# Download a Creative Commons sample image to data/
set -e
OUTDIR=${1:-data}
mkdir -p "$OUTDIR"
# Example CC0 image from Wikimedia Commons (change URL if desired)
URL="https://upload.wikimedia.org/wikipedia/commons/7/77/Example_image.jpg"
# The above URL might not be valid forever — replace with a working sample.
# We'll try a fallback public domain photo of a dog (example):
if ! command -v curl &>/dev/null; then
  echo "curl not found, trying wget"
  wget -O "$OUTDIR/sample.jpg" "https://upload.wikimedia.org/wikipedia/commons/7/77/Example_image.jpg" || true
else
  curl -L -o "$OUTDIR/sample.jpg" "https://upload.wikimedia.org/wikipedia/commons/7/77/Example_image.jpg" || true
fi

if [ ! -s "$OUTDIR/sample.jpg" ]; then
  echo "Primary URL failed. Trying fallback (dog) image."
  curl -L -o "$OUTDIR/sample.jpg" "https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg" || wget -O "$OUTDIR/sample.jpg" "https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg"
fi

echo "Saved sample image to $OUTDIR/sample.jpg"
