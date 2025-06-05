#pragma once

#include <raylib.h>

namespace Orbit {

struct FlipShader {

    Shader shader;
    int texture_loc;

    inline Shader operator=(const FlipShader &s) const { return s.shader; }
    inline void prepare(const Texture &t) const { SetShaderValueTexture(shader, texture_loc, t); }

    inline FlipShader &operator=(const FlipShader &) = delete;
    inline FlipShader &operator=(FlipShader &&other) noexcept {
        if (this == &other) return *this;

        shader = other.shader;
        texture_loc = other.texture_loc;

        other.shader = Shader{0};
        other.texture_loc = 0;

        return *this;
    }

    FlipShader(const FlipShader &) = delete;
    inline FlipShader(FlipShader &&other) noexcept {
        shader = other.shader;
        texture_loc = other.texture_loc;

        other.shader = Shader{0};
        other.texture_loc = 0;
    }
    FlipShader();

    inline ~FlipShader() { UnloadShader(shader); }

};

struct Shaders {

    FlipShader flipper;

};

};