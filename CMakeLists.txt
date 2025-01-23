cmake_minimum_required(VERSION 3.30)

set(PROJ_NAME "opengl_bug")

project(${PROJ_NAME})

set(CMAKE_CXX_STANDARD 20)

if (NOT CMAKE_CUDA_COMPILER)
    set(CMAKE_CUDA_COMPILER "/usr/local/cuda/bin/nvcc")
    # required by CLion
endif ()

enable_language(CUDA)
include_directories("${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}")

message(STATUS "nvcc path: ${CMAKE_CUDA_COMPILER}")
message(STATUS "nvcc version = ${CMAKE_CUDA_COMPILER_VERSION}")

#if (${CMAKE_CUDA_COMPILER_VERSION} VERSION_LESS "11.0.1")
#    message(FATAL_ERROR "NVCC < 11.0.1 was not test")
#endif ()


include_directories("ext/glad-3.3-core/include")

set(GLFW_BUILD_DOCS OFF CACHE BOOL "GLFW lib only")
set(GLFW_INSTALL OFF CACHE BOOL "GLFW lib only")
set(GLFW_BUILD_WAYLAND OFF CACHE BOOL "GLFW lib only")
add_subdirectory(ext/glfw)

include_directories("${GLFW_SOURCE_DIR}/deps")
link_libraries(glfw)

set(OpenGL_GL_PREFERENCE GLVND)
find_package(OpenGL REQUIRED)
link_libraries(${OPENGL_LIBRARIES})

find_package(Threads REQUIRED)
link_libraries(Threads::Threads)

add_executable(
        ${PROJ_NAME}

        main.cu
        ext/glad-3.3-core/src/glad.c
)

set_target_properties(
        ${PROJ_NAME} PROPERTIES
        CUDA_ARCHITECTURES native
        CUDA_SEPARABLE_COMPILATION ON
        CUDA_RESOLVE_DEVICE_SYMBOLS ON
)
# CUDA_SEPARABLE_COMPILATION ON: member function declaration and implementation can be separate
# https://developer.nvidia.com/blog/separate-compilation-linking-cuda-device-code/

# CUDA_ARCHITECTURES native: CUDA_ARCHITECTURES is detected automatically
# https://stackoverflow.com/questions/68223398/how-can-i-get-cmake-to-automatically-detect-the-value-for-cuda-architectures
