# GPU Image Processing-CUDA Sobel Edge Detector

**Short description:**  
This project demonstrates GPU acceleration for image processing by implementing a grayscale conversion and Sobel edge detection using CUDA. The program accepts command line arguments, measures GPU execution time, and writes the processed image and a CSV timing log. Intended as a final project for a CUDA/GPU course.

**Repository template used:**  
https://github.com/PascaleCourseraCourses/CUDAatScaleForTheEnterpriseCourseProjectTemplate

---

## Features
- Uses CUDA (nvcc) kernels for image grayscale conversion + Sobel filter.
- Uses tiling / shared memory for improved performance.
- Command line interface (input, output, block size, log file).
- Produces output image and CSV timing log.
- Minimal third-party dependencies: `stb_image.h` and `stb_image_write.h` headers are used to load/save PNG/JPEG.

---

## Prerequisites
- Linux (tested Ubuntu 20.04+), or WSL2 with CUDA drivers.
- NVIDIA GPU with CUDA support.
- NVIDIA driver and CUDA toolkit installed (nvcc available).
- CMake 3.18+ and make.
- `git`, `curl` or `wget` (for sample download scripts).

If you do not have `stb` headers, the `include/` directory contains them. (They are public domain / MIT style single-file headers.)

---
