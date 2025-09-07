cmake_minimum_required(VERSION 3.10.0)
project(MobitParser VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD_REQUIRED 17)

file(GLOB LIB_SOURCES src/*.cpp)
include_directories(include)
add_library(MobitParser STATIC ${LIB_SOURCES})
target_include_directories(MobitParser PUBLIC include)

include(CTest)
enable_testing()

set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)
