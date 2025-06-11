#pragma once

#include <optional>

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

struct SilhouetteShader {

    Shader shader;
    int texture_loc;
    int invert_loc;
    int fault_tolerance_loc;
    int vflip_loc;

    inline Shader operator=(const SilhouetteShader &s) const { return s.shader; }
    inline void prepare(
        const Texture &t, 
        bool invert = false,
        bool vflip = false,
        float tolerance = 0.001f
    ) const { 
        SetShaderValueTexture(shader, texture_loc, t);

        SetShaderValue(shader, invert_loc, &invert, SHADER_UNIFORM_INT);
        SetShaderValue(shader, vflip_loc, &vflip, SHADER_UNIFORM_INT);
        SetShaderValue(shader, fault_tolerance_loc, &tolerance, SHADER_UNIFORM_FLOAT);
    }

    inline SilhouetteShader &operator=(const SilhouetteShader &) = delete;
    inline SilhouetteShader &operator=(SilhouetteShader &&other) noexcept {
        if (this == &other) return *this;

        shader = other.shader;
        texture_loc = other.texture_loc;
        invert_loc = other.invert_loc;
        fault_tolerance_loc = other.fault_tolerance_loc;
        vflip_loc = other.vflip_loc;

        other.shader = Shader{0};
        other.texture_loc = 0;
        other.invert_loc = 0;
        other.fault_tolerance_loc = 0;
        other.vflip_loc = 0;

        return *this;
    }

    SilhouetteShader(const SilhouetteShader &) = delete;
    inline SilhouetteShader(SilhouetteShader &&other) noexcept {
        shader = other.shader;
        texture_loc = other.texture_loc;
        invert_loc = other.invert_loc;
        fault_tolerance_loc = other.fault_tolerance_loc;
        vflip_loc = other.vflip_loc;

        other.shader = Shader{0};
        other.texture_loc = 0;
        other.invert_loc = 0;
        other.fault_tolerance_loc = 0;
        other.vflip_loc = 0;
    }
    SilhouetteShader();

    inline ~SilhouetteShader() { UnloadShader(shader); }

};

struct CopyPixelsShader {

    Shader shader;
    int texture1_loc, texture2_loc, mask_loc;
    int texture1_size_loc, texture2_size_loc, mask_size_loc;
    int use_mask_loc;
    int use_color_loc;
    int vflip_loc;
    int ink_loc;
    int blend_loc;

    inline Shader operator=(const CopyPixelsShader &s) const { return s.shader; }
    inline void prepare(
        const Texture2D &t1, 
        const Texture2D &t2,
        bool color = false,
        int ink = 0,
        float blend = 1.0f,
        bool vflip = false,
        const Texture2D *mask = nullptr 
    ) const { 
        SetShaderValueTexture(shader, texture1_loc, t1);
        SetShaderValueTexture(shader, texture2_loc, t2);
        if (mask != nullptr) SetShaderValueTexture(shader, mask_loc, *mask);

        int use_mask = mask != nullptr;
        int use_color = (int)color;
        Vector2 t1s = Vector2{(float)t1.width, (float)t1.height};
        Vector2 t2s = Vector2{(float)t2.width, (float)t2.height};
        Vector2 ms = mask ? Vector2{(float)mask->width, (float)mask->height} : Vector2{0, 0};

        SetShaderValueV(shader, texture1_size_loc, &t1s, SHADER_UNIFORM_VEC2, 1);
        SetShaderValueV(shader, texture2_size_loc, &t2s, SHADER_UNIFORM_VEC2, 1);
        SetShaderValueV(shader, mask_size_loc, &ms, SHADER_UNIFORM_VEC2, 1);

        SetShaderValue(shader, vflip_loc, &vflip, SHADER_UNIFORM_INT);
        SetShaderValue(shader, use_color_loc, &use_color, SHADER_UNIFORM_INT);
        SetShaderValue(shader, ink_loc, &ink, SHADER_UNIFORM_INT);
        SetShaderValue(shader, use_mask_loc, &use_mask, SHADER_UNIFORM_INT);
        SetShaderValue(shader, blend_loc, &blend, SHADER_UNIFORM_FLOAT);
    }

    inline CopyPixelsShader &operator=(const CopyPixelsShader &) = delete;

    CopyPixelsShader(const CopyPixelsShader &) = delete;
    
    CopyPixelsShader();

    inline ~CopyPixelsShader() { UnloadShader(shader); }

};

struct InvbCopyPixelsShader {

    Shader shader;
    int texture1_loc, texture2_loc, mask_loc;
    int texture1_size_loc, texture2_size_loc, mask_size_loc;
    int use_mask_loc;
    int use_color_loc;
    int vflip_loc;
    int ink_loc;
    int blend_loc;
    int vertices_loc;
    int src_coords_loc;

    inline Shader operator=(const InvbCopyPixelsShader &s) const { return s.shader; }
    inline void prepare(
        const Texture2D &t1, 
        const Texture2D &t2,
        const Rectangle &src, 
        const Vector2 q[4],
        bool color = false,
        int ink = 0,
        float blend = 1.0f,
        bool vflip = false,
        const Texture2D *mask = nullptr 
    ) const { 
        SetShaderValueTexture(shader, texture1_loc, t1);
        SetShaderValueTexture(shader, texture2_loc, t2);
        
        float src_coords[4] = { src.x / t1.width, src.y / t1.height, (src.x + src.width) / t1.width, (src.y + src.height) / t1.height };
        SetShaderValueV(shader, src_coords_loc, src_coords, SHADER_UNIFORM_FLOAT, 4);
        SetShaderValueV(shader, vertices_loc, q, SHADER_UNIFORM_VEC2, 4);

        if (mask != nullptr) SetShaderValueTexture(shader, mask_loc, *mask);

        int use_mask = mask != nullptr;
        int use_color = (int)color;
        Vector2 t1s = Vector2{(float)t1.width, (float)t1.height};
        Vector2 t2s = Vector2{(float)t2.width, (float)t2.height};
        Vector2 ms = mask ? Vector2{(float)mask->width, (float)mask->height} : Vector2{0, 0};

        SetShaderValueV(shader, texture1_size_loc, &t1s, SHADER_UNIFORM_VEC2, 1);
        SetShaderValueV(shader, texture2_size_loc, &t2s, SHADER_UNIFORM_VEC2, 1);
        SetShaderValueV(shader, mask_size_loc, &ms, SHADER_UNIFORM_VEC2, 1);

        SetShaderValue(shader, vflip_loc, &vflip, SHADER_UNIFORM_INT);
        SetShaderValue(shader, use_color_loc, &use_color, SHADER_UNIFORM_INT);
        SetShaderValue(shader, ink_loc, &ink, SHADER_UNIFORM_INT);
        SetShaderValue(shader, use_mask_loc, &use_mask, SHADER_UNIFORM_INT);
        SetShaderValue(shader, blend_loc, &blend, SHADER_UNIFORM_FLOAT);
    }

    inline InvbCopyPixelsShader &operator=(const InvbCopyPixelsShader &) = delete;

    InvbCopyPixelsShader(const InvbCopyPixelsShader &) = delete;
    
    InvbCopyPixelsShader();

    inline ~InvbCopyPixelsShader() { UnloadShader(shader); }

};

struct Shaders {

    FlipShader flipper;
    InvbShader invb;
    SilhouetteShader silhouette;
    CopyPixelsShader copy_pixels;
    InvbCopyPixelsShader invb_copy_pixels;

};

};