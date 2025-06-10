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

struct InvbShader {

    Shader shader;
    int texture_loc;
    int vertices_loc;
    int src_coords_loc;

    inline Shader operator=(const InvbShader &s) const { return s.shader; }
    inline void prepare(const Texture &t, const Rectangle &src, const Vector2 q[4]) const { 
        SetShaderValueTexture(shader, texture_loc, t); 
        float src_coords[4] = { src.x / t.width, src.y / t.height, (src.x + src.width) / t.width, (src.y + src.height) / t.height };
        SetShaderValueV(shader, src_coords_loc, src_coords, SHADER_UNIFORM_FLOAT, 4);
        SetShaderValueV(shader, vertices_loc, q, SHADER_UNIFORM_VEC2, 4);
    }

    inline InvbShader &operator=(const InvbShader &) = delete;
    inline InvbShader &operator=(InvbShader &&other) noexcept {
        if (this == &other) return *this;

        shader = other.shader;
        texture_loc = other.texture_loc;
        vertices_loc = other.vertices_loc;
        src_coords_loc = other.src_coords_loc;

        other.shader = Shader{0};
        other.texture_loc = 0;
        other.vertices_loc = 0;
        other.src_coords_loc = 0;

        return *this;
    }

    InvbShader(const InvbShader &) = delete;
    inline InvbShader(InvbShader &&other) noexcept {
        shader = other.shader;
        texture_loc = other.texture_loc;
        vertices_loc = other.vertices_loc;
        src_coords_loc = other.src_coords_loc;

        other.shader = Shader{0};
        other.texture_loc = 0;
        other.vertices_loc = 0;
        other.src_coords_loc = 0;
    }
    InvbShader();

    inline ~InvbShader() { UnloadShader(shader); }

};

struct Shaders {

    FlipShader flipper;
    InvbShader invb;

};

};