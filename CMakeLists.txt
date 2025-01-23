cmake_minimum_required(VERSION 3.10)

set(PROJ_NAME "opengl_bug")

project(${PROJ_NAME})

set(CMAKE_CXX_STANDARD 17)

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

        main.cpp
        ext/glad-3.3-core/src/glad.c
)
