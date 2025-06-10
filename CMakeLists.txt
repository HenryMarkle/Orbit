cmake_minimum_required(VERSION 3.15.0)
project(Orbit VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

add_subdirectory(libs/lua)
add_subdirectory(libs/spdlog)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/libs/raylib)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/libs/xsimd)

file(GLOB MAIN_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

add_executable(
    Orbit 
    main.cpp
    ${MAIN_SOURCES}
)

target_include_directories(
  Orbit 
  PRIVATE include 
  ${CMAKE_CURRENT_SOURCE_DIR}/libs/lua/src 
  ${CMAKE_CURRENT_SOURCE_DIR}/libs/tomlplusplus/include
)

target_link_libraries(Orbit PRIVATE raylib lua spdlog xsimd)

if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    # Visual Studio
    add_compile_options(/arch:AVX2)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    # GCC or Clang
    add_compile_options(-mavx2 -mfma)
endif()

target_compile_definitions(
  Orbit
  PRIVATE
  BUILD_TYPE="${CMAKE_BUILD_TYPE}"
)

if(FEATURE_SIMD)
  target_compile_definitions(Orbit PRIVATE SIMD=1)
else()
  target_compile_definitions(Orbit PRIVATE SIMD=0)
endif()

# Copy the config file
file(
  COPY
  ${CMAKE_SOURCE_DIR}/config.json
  DESTINATION
  ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/
)

# Embed the changelog file
#
set(CHLG_INPUT_FILE "${CMAKE_SOURCE_DIR}/changelog.txt")
set(CHLG_OUTPUT_FILE "${CMAKE_BINARY_DIR}/embedded_changelog.h")

file(READ "${CHLG_INPUT_FILE}" CHANGELOG_CONTENT)
string(REPLACE "\"" "\\\"" CHANGELOG_CONTENT
  "${CHANGELOG_CONTENT}") # Escape double quotes

string(REPLACE "\n" "\\n\"\n\""
  CHANGELOG_CONTENT "${CHANGELOG_CONTENT}") # Handle newlines

file(WRITE "${CHLG_OUTPUT_FILE}" "#pragma once\n")
file(APPEND "${CHLG_OUTPUT_FILE}"
  "constexpr const char* EMBEDDED_CHANGELOG = R\"(\n")
file(APPEND "${CHLG_OUTPUT_FILE}" "${CHANGELOG_CONTENT}")
file(APPEND "${CHLG_OUTPUT_FILE}" "\n)\";\n")

target_include_directories(Orbit PRIVATE "${CMAKE_BINARY_DIR}")
#

# Compile Constants
#
file(READ "${CMAKE_SOURCE_DIR}/version.txt" VERSION_CONTENT)
string(STRIP "${VERSION_CONTENT}" VERSION_CONTENT)
target_compile_definitions(Orbit PRIVATE APP_VERSION="${VERSION_CONTENT}")

if(CMAKE_BUILD_TYPE STREQUAL "Release")

endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  target_compile_definitions(Orbit PRIVATE PROJECT_SRC_DIR="${CMAKE_SOURCE_DIR}")
  target_compile_definitions(Orbit PRIVATE DEBUG=1)
else()
  target_compile_definitions(Orbit PRIVATE DEBUG=0)
endif()

if(WIN32)
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        set_target_properties(Orbit PROPERTIES WIN32_EXECUTABLE YES)
    endif()
endif()
#


set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)
