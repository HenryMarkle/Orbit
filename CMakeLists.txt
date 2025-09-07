cmake_minimum_required(VERSION 3.15.0)
project(Orbit VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

if(MSVC)
  add_compile_options(/utf-8)
endif()

# LuaJit

set(LUAJIT_ROOT "${CMAKE_SOURCE_DIR}/libs/luajit")
set(LUAJIT_INCLUDE_DIR "${LUAJIT_ROOT}/include")
set(LUAJIT_LIBRARY_DIR "${LUAJIT_ROOT}/lib")

if (WIN32)
  set(LUAJIT_LIBRARY "${LUAJIT_LIBRARY_DIR}/lua51.lib")
  # set(LUAJIT_DLL "${LUAJIT_LIBRARY_DIR}/lua51.dll")
else()
  set(LUAJIT_LIBRARY "${LUAJIT_LIBRARY_DIR}/libluajit.a")
endif()

add_library(luajit STATIC IMPORTED)
set_target_properties(luajit PROPERTIES
  IMPORTED_LOCATION "${LUAJIT_LIBRARY}"
  INTERFACE_INCLUDE_DIRECTORIES "${LUAJIT_INCLUDE_DIR}"
)

if(WIN32)
  # Windows system libraries required for LuaJIT
  set_property(
    TARGET luajit PROPERTY 
    INTERFACE_LINK_LIBRARIES 
      kernel32 user32 gdi32 winspool comdlg32 advapi32 shell32 
      ole32 oleaut32 uuid odbc32 odbccp32
  )
elseif(UNIX AND NOT APPLE)
  set_property(TARGET luajit PROPERTY INTERFACE_LINK_LIBRARIES dl m)
elseif(APPLE)
  set_property(TARGET luajit PROPERTY INTERFACE_LINK_LIBRARIES m)
endif()

add_dependencies(luajit luajit_build)

add_subdirectory(${CMAKE_SOURCE_DIR}/libs/spdlog)
add_subdirectory(${CMAKE_SOURCE_DIR}/libs/raylib)
add_subdirectory(${CMAKE_SOURCE_DIR}/libs/xsimd)
add_subdirectory(${CMAKE_SOURCE_DIR}/libs/MobitParser)

file(GLOB MAIN_SOURCES ${CMAKE_SOURCE_DIR}/src/*.cpp)
# list(REMOVE_ITEM MAIN_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/image.cpp")

add_executable(
  Orbit 
  main.cpp
  ${MAIN_SOURCES}
)

target_include_directories(
  Orbit 
  PRIVATE include 
  ${CMAKE_SOURCE_DIR}/libs/tomlplusplus/include
)

target_link_libraries(Orbit PRIVATE luajit raylib spdlog xsimd MobitParser)

target_include_directories(
  Orbit 
  PRIVATE include 
  PRIVATE ${CMAKE_SOURCE_DIR}/libs/luajit/include
)

# Check for AVX2 support
#
include(CheckCXXCompilerFlag)

if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    check_cxx_compiler_flag("/arch:AVX2" COMPILER_SUPPORTS_AVX2)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    check_cxx_compiler_flag("-mavx2" COMPILER_SUPPORTS_AVX2)
endif()

if(COMPILER_SUPPORTS_AVX2)
  target_compile_definitions(Orbit PUBLIC AVX2=1)
  
  if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
      # Visual Studio
      target_compile_options(Orbit PRIVATE /arch:AVX2)
  elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
      # GCC or Clang
      target_compile_options(Orbit PRIVATE -mavx2 -mfma)
  endif()
else()
  target_compile_definitions(Orbit PUBLIC AVX2=0)
endif()
#
#

target_compile_definitions(
  Orbit
  PRIVATE
  BUILD_TYPE="${CMAKE_BUILD_TYPE}"
)

if(MSVC)
  # Copy the config file
  file(
    COPY
    ${CMAKE_SOURCE_DIR}/config.toml
    DESTINATION
    ${PROJECT_ARTIFACT_DIRECTORY}/
  )

  # Copy the splash screen image
  file(
    COPY
    ${CMAKE_SOURCE_DIR}/splashscreen.png
    DESTINATION
    ${PROJECT_ARTIFACT_DIRECTORY}/
  )

  # Copy the icon image
  file(
    COPY
    ${CMAKE_SOURCE_DIR}/icon.png
    DESTINATION
    ${PROJECT_ARTIFACT_DIRECTORY}/
  )

  # Copy the font file
  add_custom_target(copy_config ALL
    COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_SOURCE_DIR}/FiraCode-Regular.ttf
            ${PROJECT_ARTIFACT_DIRECTORY}/font.ttf
  )
else()
  # Copy the config file
  file(
    COPY
    ${CMAKE_SOURCE_DIR}/config.toml
    DESTINATION
    ${PROJECT_ARTIFACT_DIRECTORY}/
  )

  # Copy the splash screen image
  file(
    COPY
    ${CMAKE_SOURCE_DIR}/splashscreen.png
    DESTINATION
    ${PROJECT_ARTIFACT_DIRECTORY}/
  )

  # Copy the icon image
  file(
    COPY
    ${CMAKE_SOURCE_DIR}/icon.png
    DESTINATION
    ${PROJECT_ARTIFACT_DIRECTORY}/
  )

  # Copy the font file
  add_custom_target(copy_config ALL
    COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_SOURCE_DIR}/FiraCode-Regular.ttf
            ${PROJECT_ARTIFACT_DIRECTORY}/font.ttf
  )
endif()


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

target_compile_definitions(Orbit PRIVATE BUILD_TYPE="${CMAKE_BUILD_TYPE}")
#


set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)
