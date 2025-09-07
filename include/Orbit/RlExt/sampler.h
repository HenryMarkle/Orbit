#pragma once

#include <raylib.h>

namespace Orbit::RlExt {

struct Sampler {

    Image &image;

    void Sample(int x, int y, Color &pixel);

    explicit Sampler(Image &image);

};

};