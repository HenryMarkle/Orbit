#include <Orbit/Lua/random.h>

namespace Orbit::Lua {

int RandomGenerator::next(int max) noexcept {
    if (seed == 0) init_rng();

    if ((seed & 1) == 0) seed = static_cast<uint32_t>(seed >> 1);
    else seed = static_cast<uint32_t>(seed >> 1 ^ init);

    auto var1 = derive(static_cast<uint32_t>(seed * 0x47));
    if (max > 1) var1 = static_cast<int>(static_cast<long>(static_cast<uint64_t>(var1 & 0x7FFFFFFF)) % static_cast<long>(max));
    
    return var1;
}

};