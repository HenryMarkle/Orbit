#pragma once

#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <xsimd/xsimd.hpp>

// extern "C" {
//     #include <lua.h>
//     #include <lauxlib.h>
//     #include <lualib.h>
// }

#define ALIGN_SIZE 16
#define ALIGN_MASK (ALIGN_SIZE - 1)

#define ALIGN_UP(size) (((size) + ALIGN_MASK) & ~ALIGN_MASK)

namespace Orbit::Lua {

void* AlignedAllocator(void *ud, void *ptr, size_t osize, size_t nsize);

};