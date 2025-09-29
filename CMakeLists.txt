cmake_minimum_required(VERSION 3.18)
project(cuda_sobel_project LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set nvcc flags (tweak as needed)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_ARCHITECTURES "all")

# Source files
file(GLOB SRC src/*.cu src/*.h)

add_executable(sobel_gpu src/main.cu src/sobel.cu)

target_include_directories(sobel_gpu PRIVATE ${CMAKE_SOURCE_DIR}/include)
# Link libraries - none required for stb
set_target_properties(sobel_gpu PROPERTIES
  CUDA_SEPARABLE_COMPILATION ON
  POSITION_INDEPENDENT_CODE OFF
)
