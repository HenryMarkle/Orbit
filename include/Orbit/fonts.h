#pragma once

#include <raylib.h>

namespace Orbit {

struct Fonts {

    Font font32, font20, font16;

    inline explicit Fonts(Font font32, Font font20, Font font16) : font32(font32), font20(font20), font16(font16) {}
};

};