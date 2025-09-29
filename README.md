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


## Build & Run (command-line)

1. **Clone repository:**
   ```bash
   git clone https://github.com/<your-username>/cuda-sobel-project.git
   cd cuda-sobel-project
   
2. **Build with the included script (or use manual CMake commands):**
   ```bash
   chmod +x scripts/build.sh
   ./scripts/build.sh
This produces the build/sobel_gpu executable.
3. **Download a sample image (optional):**
   ```bash
   chmod +x scripts/download_sample.sh
   ./scripts/download_sample.sh data/
Sample is saved as data/sample.jpg
