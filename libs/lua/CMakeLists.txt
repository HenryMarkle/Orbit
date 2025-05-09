cmake_minimum_required(VERSION 3.10)

project(lua)

file(GLOB LUA_SOURCES src/*.c)
list(REMOVE_ITEM LUA_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/src/lua.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/luac.c"
)

add_library(
    lua STATIC
    ${LUA_SOURCES}
)

target_include_directories(lua PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)
