cmake_minimum_required(VERSION 3.13)

# Frame Capture Plugin for Linux
project(frame_capture_linux)

# Find required packages
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Find OpenGL
find_package(OpenGL REQUIRED)
find_package(X11 REQUIRED)

# Plugin library
add_library(frame_capture_linux SHARED
  frame_capture_plugin.cc
)

# Include directories
target_include_directories(frame_capture_linux PRIVATE
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/linux/runner
)

# Link libraries
target_link_libraries(frame_capture_linux PRIVATE
  PkgConfig::GTK
  ${OPENGL_LIBRARIES}
  ${X11_LIBRARIES}
  GL
  GLX
)

# Compiler settings
set_target_properties(frame_capture_linux PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
  POSITION_INDEPENDENT_CODE ON
)

# Install the plugin library
install(TARGETS frame_capture_linux
  LIBRARY DESTINATION lib
)
