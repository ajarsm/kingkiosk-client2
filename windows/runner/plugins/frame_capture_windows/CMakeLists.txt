cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "frame_capture_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "frame_capture_plugin")

add_library(${PLUGIN_NAME} STATIC
  "frame_capture_plugin.cpp"
  "frame_capture_plugin.h"
)

apply_standard_settings(${PLUGIN_NAME})
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin d3d11)

# List of absolute paths to libraries that should be bundled with the plugin
set(frame_capture_windows_bundled_libraries
  ""
  PARENT_SCOPE
)
