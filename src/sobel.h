#ifndef SOBEL_H_
#define SOBEL_H_

#include <cstdint>

void sobel_process_image(const uint8_t* input_rgba,
                         uint8_t* output_rgba,
                         int width,
                         int height,
                         int input_stride,  // bytes per row (RGBA => width*4)
                         int output_stride,
                         int block_size,
                         float* gpu_elapsed_ms);

#endif  // SOBEL_H_
