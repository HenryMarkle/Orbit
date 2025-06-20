#pragma once

#include <cstdint>

namespace Orbit::Lua {

struct RandomGenerator {

    uint32_t seed, init;

    inline static int derive(uint32_t param) noexcept {
        auto var1 = static_cast<int>((param << 0xd ^ param) - (static_cast<int>(param) >> 0x15));
        auto var2 = static_cast<uint32_t>(((var1 * var1 * 0x3d73 + 0xc0ae5) * var1 + 0xd208dd0d & 0x7fffffff) + var1);
        return static_cast<int>((var2 * 0x2000 ^ var2) - (static_cast<int>(var2) >> 0x15));
    }

    inline void init_rng() noexcept {
        seed = 1;
        init = 0xA3000000;
    }

    int next(int max) noexcept;

    inline RandomGenerator(uint32_t seed = 1) : seed(seed), init(0xA3000000) {}
};

};