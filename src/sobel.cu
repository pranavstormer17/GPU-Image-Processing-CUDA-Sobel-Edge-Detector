#include "sobel.h"
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <iostream>

static void check_cuda(cudaError_t e, const char* file, int line) {
  if (e != cudaSuccess) {
    std::cerr << "CUDA error " << cudaGetErrorString(e)
              << " at " << file << ":" << line << std::endl;
    std::exit(EXIT_FAILURE);
  }
}
#define CHECK_CUDA(x) check_cuda((x), __FILE__, __LINE__)

// Convert RGBA uchar4 into grayscale float
__device__ inline float rgba_to_gray(const uchar4& px) {
  // Rec. 601 luma
  return 0.299f * px.x + 0.587f * px.y + 0.114f * px.z;
}

// Kernel: convert RGBA to grayscale floats in a tile using shared mem,
// then compute Sobel and write result back as RGBA (edge intensity on all channels).
template<int BLOCK>
__global__ void sobel_kernel(const uchar4* input,
                             uint8_t* output,
                             int width, int height, int pitch_in_pixels) {
  // tile includes halo of 1 pixel for Sobel
  __shared__ float tile[BLOCK + 2][BLOCK + 2];

  int tx = threadIdx.x;
  int ty = threadIdx.y;
  int x = blockIdx.x * BLOCK + tx;
  int y = blockIdx.y * BLOCK + ty;

  // Load into shared memory including halo
  int sx = tx + 1;
  int sy = ty + 1;

  float val = 0.0f;
  if (x < width && y < height) {
    uchar4 px = input[y * pitch_in_pixels + x];
    val = rgba_to_gray(px);
  }
  tile[sy][sx] = val;

  // load halo (left/right/top/bottom)
  if (tx == 0) {
    int lx = x - 1;
    if (lx >= 0 && y < height) {
      uchar4 px = input[y * pitch_in_pixels + lx];
      tile[sy][0] = rgba_to_gray(px);
    } else {
      tile[sy][0] = 0.0f;
    }
  }
  if (tx == BLOCK - 1) {
    int rx = x + 1;
    if (rx < width && y < height) {
      uchar4 px = input[y * pitch_in_pixels + rx];
      tile[sy][BLOCK + 1] = rgba_to_gray(px);
    } else {
      tile[sy][BLOCK + 1] = 0.0f;
    }
  }
  if (ty == 0) {
    int ty_y = y - 1;
    if (ty_y >= 0 && x < width) {
      uchar4 px = input[ty_y * pitch_in_pixels + x];
      tile[0][sx] = rgba_to_gray(px);
    } else {
      tile[0][sx] = 0.0f;
    }
  }
  if (ty == BLOCK - 1) {
    int by = y + 1;
    if (by < height && x < width) {
      uchar4 px = input[by * pitch_in_pixels + x];
      tile[BLOCK + 1][sx] = rgba_to_gray(px);
    } else {
      tile[BLOCK + 1][sx] = 0.0f;
    }
  }

  // corners
  if (tx == 0 && ty == 0) {
    int cx = x - 1;
    int cy = y - 1;
    if (cx >= 0 && cy >= 0) {
      uchar4 px = input[cy * pitch_in_pixels + cx];
      tile[0][0] = rgba_to_gray(px);
    } else {
      tile[0][0] = 0.0f;
    }
  }
  if (tx == BLOCK - 1 && ty == 0) {
    int cx = x + 1;
    int cy = y - 1;
    if (cx < width && cy >= 0) {
      uchar4 px = input[cy * pitch_in_pixels + cx];
      tile[0][BLOCK + 1] = rgba_to_gray(px);
    } else {
      tile[0][BLOCK + 1] = 0.0f;
    }
  }
  if (tx == 0 && ty == BLOCK - 1) {
    int cx = x - 1;
    int cy = y + 1;
    if (cx >= 0 && cy < height) {
      uchar4 px = input[cy * pitch_in_pixels + cx];
      tile[BLOCK + 1][0] = rgba_to_gray(px);
    } else {
      tile[BLOCK + 1][0] = 0.0f;
    }
  }
  if (tx == BLOCK - 1 && ty == BLOCK - 1) {
    int cx = x + 1;
    int cy = y + 1;
    if (cx < width && cy < height) {
      uchar4 px = input[cy * pitch_in_pixels + cx];
      tile[BLOCK + 1][BLOCK + 1] = rgba_to_gray(px);
    } else {
      tile[BLOCK + 1][BLOCK + 1] = 0.0f;
    }
  }

  __syncthreads();

  if (x >= width || y >= height) return;

  // Sobel filters
  float gx = -tile[sy-1][sx-1] - 2.0f * tile[sy][sx-1] - tile[sy+1][sx-1]
             + tile[sy-1][sx+1] + 2.0f * tile[sy][sx+1] + tile[sy+1][sx+1];
  float gy = -tile[sy-1][sx-1] - 2.0f * tile[sy-1][sx] - tile[sy-1][sx+1]
             + tile[sy+1][sx-1] + 2.0f * tile[sy+1][sx] + tile[sy+1][sx+1];

  float mag = sqrtf(gx*gx + gy*gy);
  // normalize to [0,255]
  float outv = fminf(255.0f, mag);

  // write RGBA output (keep alpha = 255)
  int out_idx = (y * width + x) * 4;
  output[out_idx + 0] = static_cast<uint8_t>(outv);
  output[out_idx + 1] = static_cast<uint8_t>(outv);
  output[out_idx + 2] = static_cast<uint8_t>(outv);
  output[out_idx + 3] = 255;
}

void sobel_process_image(const uint8_t* input_rgba,
                         uint8_t* output_rgba,
                         int width,
                         int height,
                         int input_stride,
                         int output_stride,
                         int block_size,
                         float* gpu_elapsed_ms) {
  // input_rgba is host RGBA bytes (4*width*height),
  // pitch in pixels for device pointer we will use equals width.
  size_t num_pixels = static_cast<size_t>(width) * height;
  size_t buffer_bytes = num_pixels * 4;

  uchar4* d_input = nullptr;
  uint8_t* d_output = nullptr;

  CHECK_CUDA(cudaMalloc(&d_input, num_pixels * sizeof(uchar4)));
  CHECK_CUDA(cudaMalloc(&d_output, buffer_bytes));

  // copy host rgba into d_input (uchar4 layout)
  CHECK_CUDA(cudaMemcpy(d_input, input_rgba, buffer_bytes, cudaMemcpyHostToDevice));

  dim3 block(block_size, block_size);
  dim3 grid((width + block.x - 1) / block.x, (height + block.y - 1) / block.y);

  // timing with CUDA events
  cudaEvent_t start, stop;
  CHECK_CUDA(cudaEventCreate(&start));
  CHECK_CUDA(cudaEventCreate(&stop));

  CHECK_CUDA(cudaEventRecord(start));
  // Launch kernel with template block size
  if (block_size == 8) {
    sobel_kernel<8><<<grid, block>>> (d_input, d_output, width, height, width);
  } else if (block_size == 16) {
    sobel_kernel<16><<<grid, block>>> (d_input, d_output, width, height, width);
  } else if (block_size == 32) {
    sobel_kernel<32><<<grid, block>>> (d_input, d_output, width, height, width);
  } else {
    // fallback to 16
    sobel_kernel<16><<<grid, dim3(16,16)>>> (d_input, d_output, width, height, width);
  }
  CHECK_CUDA(cudaGetLastError());
  CHECK_CUDA(cudaEventRecord(stop));
  CHECK_CUDA(cudaEventSynchronize(stop));

  float ms = 0.0f;
  CHECK_CUDA(cudaEventElapsedTime(&ms, start, stop));
  if (gpu_elapsed_ms) *gpu_elapsed_ms = ms;

  // copy back
  CHECK_CUDA(cudaMemcpy(output_rgba, d_output, buffer_bytes, cudaMemcpyDeviceToHost));

  // cleanup
  CHECK_CUDA(cudaEventDestroy(start));
  CHECK_CUDA(cudaEventDestroy(stop));
  CHECK_CUDA(cudaFree(d_input));
  CHECK_CUDA(cudaFree(d_output));
}
