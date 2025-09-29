#!/usr/bin/env bash
set -e
IN=${1:-data/sample.jpg}
OUT=${2:-results/output.png}
LOG=${3:-results/log.csv}
mkdir -p "$(dirname "$OUT")"
mkdir -p "$(dirname "$LOG")"

# default block size 16
./build/sobel_gpu --input "$IN" --output "$OUT" --block 16 --log "$LOG"
echo "Output: $OUT"
echo "Log: $LOG"
