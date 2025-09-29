/*
 * main.cu
 *
 * Command-line front-end:
 *  --input <path>
 *  --output <path>
 *  --block <n> (16 default)
 *  --log <path> (results/timings.csv default)
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <fstream>
#include <iostream>
#include "sobel.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

static void print_usage(const char* prog) {
  std::printf("Usage: %s --input <infile> --output <outfile> [--block <n>] [--log <log.csv>]\n", prog);
}

int main(int argc, char** argv) {
  if (argc < 5) {
    print_usage(argv[0]);
    return 1;
  }

  std::string input_path, output_path, log_path = "results/timings.csv";
  int block_size = 16;

  for (int i = 1; i < argc; ++i) {
    if (std::strcmp(argv[i], "--input") == 0 && i + 1 < argc) {
      input_path = argv[++i];
    } else if (std::strcmp(argv[i], "--output") == 0 && i + 1 < argc) {
      output_path = argv[++i];
    } else if (std::strcmp(argv[i], "--block") == 0 && i + 1 < argc) {
      block_size = std::atoi(argv[++i]);
    } else if (std::strcmp(argv[i], "--log") == 0 && i + 1 < argc) {
      log_path = argv[++i];
    } else {
      print_usage(argv[0]);
      return 1;
    }
  }

  if (input_path.empty() || output_path.empty()) {
    print_usage(argv[0]);
    return 1;
  }

  int w, h, comp;
  unsigned char* img = stbi_load(input_path.c_str(), &w, &h, &comp, 4);
  if (!img) {
    std::cerr << "Failed to load image: " << input_path << std::endl;
    return 1;
  }
  std::cout << "Loaded " << input_path << " (" << w << " x " << h << "), channels forced to RGBA.\n";

  // output buffer
  size_t out_bytes = static_cast<size_t>(w) * h * 4;
  uint8_t* out_buf = (uint8_t*)malloc(out_bytes);
  if (!out_buf) {
    std::cerr << "Failed to allocate output buffer\n";
    stbi_image_free(img);
    return 1;
  }

  float gpu_ms = 0.0f;
  sobel_process_image(img, out_buf, w, h, w * 4, w * 4, block_size, &gpu_ms);

  // write output image
  // use PNG
  int write_rc = stbi_write_png(output_path.c_str(), w, h, 4, out_buf, w * 4);
  if (!write_rc) {
    std::cerr << "Failed to write output image: " << output_path << std::endl;
    free(out_buf);
    stbi_image_free(img);
    return 1;
  }
  std::cout << "Wrote " << output_path << "\n";
  std::cout << "GPU processing time (ms): " << gpu_ms << "\n";

  // append to CSV log
  std::ofstream csv;
  csv.open(log_path, std::ios::app);
  if (csv.tellp() == 0) {
    csv << "input,output,width,height,block_size,gpu_ms\n";
  }
  csv << input_path << "," << output_path << "," << w << "," << h << "," << block_size << "," << gpu_ms << "\n";
  csv.close();
  std::cout << "Appended timing to " << log_path << "\n";

  free(out_buf);
  stbi_image_free(img);
  return 0;
}
