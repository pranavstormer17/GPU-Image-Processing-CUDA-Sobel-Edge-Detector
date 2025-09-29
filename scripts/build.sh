#!/usr/bin/env bash
set -e
mkdir -p build
cd build
cmake ..
make -j
echo "Build complete. Executable: build/sobel_gpu"
