#include <Orbit/shaders.h>

#include <raylib.h>

namespace Orbit {

FlipShader::FlipShader() {
    shader = LoadShaderFromMemory(
        nullptr, 
        R"(#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;

out vec4 finalColor;

void main()
{
    if (fragTexCoord.x < 0.0 || fragTexCoord.x > 1.0 || fragTexCoord.y < 0.0 || fragTexCoord.y > 1.0) {
        finalColor = vec4(1.0, 1.0, 1.0, 1.0);
    } else {

        //vec4 texelColor = texture(texture0, fragTexCoord);

        finalColor = texture(texture0, vec2(fragTexCoord.x, 1.0 - fragTexCoord.y));
    }
})"
);

    texture_loc = GetShaderLocation(shader, "texture0");
}

InvbShader::InvbShader() {
    shader = LoadShaderFromMemory(R"(#version 330

// Input vertex attributes
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;

uniform mat4 mvp;

out vec2 fragTexCoord;
out vec4 fragColor;

uniform vec2 vertex_pos[4];

void main()
{
    fragTexCoord = vertexPosition.xy;
    
    fragColor = vertexColor;

    gl_Position = mvp*vec4(vertexPosition, 1.0);
})",

R"(#version 330

uniform sampler2D textureSampler;

in vec2 fragTexCoord;
in vec4 fragColor;

uniform vec2 vertex_pos[4];
uniform float tex_coord_pos[4];

out vec4 FragColor;

float cross2d(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

vec2 invbilinear( vec2 p, vec2 a, vec2 b, vec2 c, vec2 d )
{
    vec2 res = vec2(-1.0);

    vec2 e = b-a;
    vec2 f = d-a;
    vec2 g = a-b+c-d;
    vec2 h = p-a;
        
    float k2 = cross2d( g, f );
    float k1 = cross2d( e, f ) + cross2d( h, g );
    float k0 = cross2d( h, e );
    
    // if edges are parallel, this is a linear equation
    if( abs(k2)<0.001 )
    {
        res = vec2( (h.x*k1+f.x*k0)/(e.x*k1-g.x*k0), -k0/k1 );
    }
    // otherwise, it's a quadratic
    else
    {
        float w = k1*k1 - 4.0*k0*k2;
        if( w<0.0 ) return vec2(-1.0);
        w = sqrt( w );

        float ik2 = 0.5/k2;
        float v = (-k1 - w)*ik2;
        float u = (h.x - f.x*v)/(e.x + g.x*v);
        
        if( u<0.0 || u>1.0 || v<0.0 || v>1.0 )
        {
           v = (-k1 + w)*ik2;
           u = (h.x - f.x*v)/(e.x + g.x*v);
        }
        res = vec2( u, v );
    }
    
    return res;
}

void main() {

    vec4 white = vec4(1, 1, 1, 1);
    
	vec2 b = vertex_pos[1]; // top right
    vec2 a = vertex_pos[0]; // top left
	vec2 d = vertex_pos[3]; // bottom left
	vec2 c = vertex_pos[2]; // bottom right

	vec2 uv = invbilinear(fragTexCoord, a, b, c, d);

    uv.x = tex_coord_pos[0] + uv.x*(tex_coord_pos[2] - tex_coord_pos[0]);
    uv.y = tex_coord_pos[1] + uv.y*(tex_coord_pos[3] - tex_coord_pos[1]);

    if (uv.x > 1 || uv.x < 0 || uv.y > 1 || uv.y < 0) {
        FragColor = white;
    } else {
        vec4 newColor = texture(textureSampler, uv) * fragColor;

        if (newColor.r == 1 && newColor.g == 1 && newColor.b == 1 && newColor.a == 1) {
            FragColor = white;
        } else {
            FragColor = newColor;
        }
    }
})"
);

    texture_loc = GetShaderLocation(shader, "textureSampler");
    vertices_loc = GetShaderLocation(shader, "vertex_pos");
    src_coords_loc = GetShaderLocation(shader, "tex_coord_pos");
}

SilhouetteShader::SilhouetteShader() {
    shader = LoadShaderFromMemory(
        nullptr, 
        R"(#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform int invert;
uniform float tolerance;
uniform int vflip;

out vec4 finalColor;

void main()
{
    vec4 white = vec4(1, 1, 1, 1);
    vec4 black = vec4(0, 0, 0, 1);

    if (fragTexCoord.x < 0.0 || fragTexCoord.x > 1.0 || fragTexCoord.y < 0.0 || fragTexCoord.y > 1.0) {
        finalColor = vec4(1.0, 1.0, 1.0, 1.0);
    } else {
        vec4 c;

        if (bool(vflip)) {
            c = texture(texture0, vec2(fragTexCoord.x, 1.0 - fragTexCoord.y));
        } else {
            c = texture(texture0, fragTexCoord);
        }

        if (c == white) { // background
            if (bool(invert)) {
                finalColor = black;
            } else {
                finalColor = white;
            }
        } else { // foreground
            if (bool(invert)) {
                finalColor = white;
            } else {
                finalColor = black;
            }
        }
    }
})"
);

    texture_loc = GetShaderLocation(shader, "texture0");
    invert_loc = GetShaderLocation(shader, "invert");
    vflip_loc = GetShaderLocation(shader, "vflip");
    fault_tolerance_loc = GetShaderLocation(shader, "tolerance");
}

CopyPixelsShader::CopyPixelsShader() {
    shader = LoadShaderFromMemory(
        nullptr, 
        R"(#version 330
                                        
        in vec2 fragTexCoord;
        in vec4 fragColor;

        uniform sampler2D texture0;
        uniform sampler2D texture1;
        uniform sampler2D mask;

        uniform vec2 texture0_size;
        uniform vec2 texture1_size;
        uniform vec2 mask_size;
        
        uniform int use_mask;
        uniform int use_color;
        
        uniform float blend;
        uniform int ink;
        uniform int vflip;

        out vec4 finalColor;

        void main()
        {
            vec4 white = vec4(1, 1, 1, 1);
            vec4 black = vec4(0, 0, 0, 1);

            vec2 uv = fragTexCoord;
            if (bool(vflip)) {
                uv.y = 1.0 - uv.y;
            }

            vec4 c;

            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                c = white;
            } else {
                if (bool(use_mask) && texture(mask, ((uv * texture0_size) / mask_size)) != white) discard;

                c = texture(texture0, uv);
            }

            if (ink == 39) { // darkest
                if (bool(use_color)) {
                    c = fragColor;
                }
            
                finalColor = c;

                vec4 c2 = texture(texture1, ((uv * texture0_size) / texture1_size));

                finalColor.r = min(c.r, c2.r);
                finalColor.g = min(c.g, c2.g);
                finalColor.b = min(c.b, c2.b);
                finalColor.a = min(c.a, c2.a);
                // finalColor.a = min(c.a, blend);

            } else if (ink == 36) { // transparent background
                if (c == white) discard;

                if (bool(use_color)) {
                    c = fragColor;
                }

                if (blend < 0.987) {
                    vec4 c2 = texture(texture1, ((uv * texture0_size) / texture1_size));
                    // finalColor = mix(c2, c, blend);
                    finalColor = vec4(c.rgb, blend);
                } else {
                    finalColor = c; 
                }
            } else if (ink == 0) { // default
                if (bool(use_color)) {
                    c = fragColor;
                }

                if (blend < 0.987) {
                    vec4 c2 = texture(texture1, ((uv * texture0_size) / texture1_size));
                    // finalColor = mix(c2, c, blend);
                    finalColor = vec4(c.rgb, blend);
                } else {
                    finalColor = c; 
                }
            }
        })" 
    );

    texture1_loc = GetShaderLocation(shader, "texture0");
    texture2_loc = GetShaderLocation(shader, "texture1");
    mask_loc = GetShaderLocation(shader, "mask");
    texture1_size_loc = GetShaderLocation(shader, "texture0_size");
    texture2_size_loc = GetShaderLocation(shader, "texture1_size");
    mask_size_loc = GetShaderLocation(shader, "mask_size");
    use_mask_loc = GetShaderLocation(shader, "use_mask");
    use_color_loc = GetShaderLocation(shader, "use_color");
    blend_loc = GetShaderLocation(shader, "blend");
    ink_loc = GetShaderLocation(shader, "ink");
}

InvbCopyPixelsShader::InvbCopyPixelsShader() {
    shader = LoadShaderFromMemory(
        R"(#version 330

        // Input vertex attributes
        in vec3 vertexPosition;
        in vec2 vertexTexCoord;
        in vec3 vertexNormal;
        in vec4 vertexColor;

        uniform mat4 mvp;

        out vec2 fragTexCoord;
        out vec4 fragColor;

        uniform vec2 vertex_pos[4];

        void main()
        {
            fragTexCoord = vertexPosition.xy;
            
            fragColor = vertexColor;

            gl_Position = mvp*vec4(vertexPosition, 1.0);
        })",

        R"(#version 330
                                        
        in vec2 fragTexCoord;
        in vec4 fragColor;

        uniform vec2 vertex_pos[4];
        uniform float tex_coord_pos[4];

        uniform sampler2D texture0;
        uniform sampler2D texture1;
        uniform sampler2D mask;

        uniform vec2 texture0_size;
        uniform vec2 texture1_size;
        uniform vec2 mask_size;
        
        uniform int use_mask;
        uniform int use_color;
        
        uniform float blend;
        uniform int ink;
        uniform int vflip;

        out vec4 finalColor;

        float cross2d(vec2 a, vec2 b) {
            return a.x * b.y - a.y * b.x;
        }

        bool is_rectangle(vec2 a, vec2 b, vec2 c, vec2 d) {
            vec2 ab = b - a;
            vec2 bc = c - b;
            vec2 cd = d - c;
            vec2 da = a - d;
            
            // Check if opposite sides are parallel and equal
            const float EPSILON = 1e-5;
            
            // Check if AB || DC and AD || BC
            bool parallel1 = abs(cross2d(normalize(ab), normalize(-cd))) < EPSILON;
            bool parallel2 = abs(cross2d(normalize(da), normalize(-bc))) < EPSILON;
            
            // Check if adjacent sides are perpendicular
            bool perpendicular = abs(dot(normalize(ab), normalize(bc))) < EPSILON;
            
            return parallel1 && parallel2 && perpendicular;
        }

        vec2 invbilinear_rectangle(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
            // For a rectangle, we can use a more direct approach
            // Transform to local coordinate system where rectangle is axis-aligned
            
            vec2 ab = b - a;  // First side vector
            vec2 ad = d - a;  // Adjacent side vector
            vec2 ap = p - a;  // Vector from corner to point
            
            // Project point onto the rectangle's local axes
            float ab_length_sq = dot(ab, ab);
            float ad_length_sq = dot(ad, ad);
            
            // Avoid division by zero
            if (ab_length_sq < 1e-10 || ad_length_sq < 1e-10) {
                return vec2(-1.0);
            }
            
            float u = dot(ap, ab) / ab_length_sq;
            float v = dot(ap, ad) / ad_length_sq;
            
            return vec2(u, v);
        }

        vec2 invbilinear_enhanced(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
            // First check if it's a rectangle for optimized path
            if (is_rectangle(a, b, c, d)) {
                return invbilinear_rectangle(p, a, b, c, d);
            }
            
            // Fall back to general bilinear inversion with stability improvements
            vec2 e = b - a;
            vec2 f = d - a;
            vec2 g = a - b + c - d;
            vec2 h = p - a;
            
            float k2 = cross2d(g, f);
            float k1 = cross2d(e, f) + cross2d(h, g);
            float k0 = cross2d(h, e);
            
            const float EPSILON = 1e-6;
            
            // Linear case (parallel edges)
            if (abs(k2) < EPSILON) {
                if (abs(k1) < EPSILON) {
                    return vec2(-1.0);
                }
                
                float v = -k0 / k1;
                float u;
                
                // Choose more stable coordinate
                if (abs(e.x + g.x * v) > abs(e.y + g.y * v)) {
                    u = (h.x - f.x * v) / (e.x + g.x * v);
                } else {
                    u = (h.y - f.y * v) / (e.y + g.y * v);
                }
                
                return vec2(u, v);
            }
            
            // Quadratic case
            float discriminant = k1 * k1 - 4.0 * k0 * k2;
            if (discriminant < 0.0) {
                return vec2(-1.0);
            }
            
            float sqrt_disc = sqrt(discriminant);
            float ik2 = 0.5 / k2;
            
            // Try both solutions
            float v1 = (-k1 - sqrt_disc) * ik2;
            float v2 = (-k1 + sqrt_disc) * ik2;
            
            for (int i = 0; i < 2; i++) {
                float v = (i == 0) ? v1 : v2;
                
                float denom_x = e.x + g.x * v;
                float denom_y = e.y + g.y * v;
                
                float u;
                if (abs(denom_x) > abs(denom_y)) {
                    u = (h.x - f.x * v) / denom_x;
                } else if (abs(denom_y) > EPSILON) {
                    u = (h.y - f.y * v) / denom_y;
                } else {
                    continue;
                }
                
                // Allow small tolerance outside [0,1]
                if (u >= -EPSILON && u <= 1.0 + EPSILON && v >= -EPSILON && v <= 1.0 + EPSILON) {
                    return vec2(clamp(u, 0.0, 1.0), clamp(v, 0.0, 1.0));
                }
            }
            
            return vec2(-1.0);
        }

        // Alternative: Matrix-based approach for any quadrilateral
        vec2 invbilinear_matrix(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
            // Use iterative method that's more robust for all cases
            vec2 uv = vec2(0.5, 0.5);
            
            const int MAX_ITERATIONS = 6;
            const float TOLERANCE = 1e-6;
            
            for (int i = 0; i < MAX_ITERATIONS; i++) {
                // Current position using bilinear interpolation
                vec2 p00 = a, p10 = b, p11 = c, p01 = d;
                vec2 current = mix(mix(p00, p10, uv.x), mix(p01, p11, uv.x), uv.y);
                
                vec2 error = current - p;
                if (length(error) < TOLERANCE) break;
                
                // Compute derivatives
                vec2 dpdu = mix(p10 - p00, p11 - p01, uv.y);
                vec2 dpdv = mix(p01 - p00, p11 - p10, uv.x);
                
                // Solve 2x2 system
                float det = dpdu.x * dpdv.y - dpdu.y * dpdv.x;
                if (abs(det) < 1e-10) break;
                
                vec2 delta = vec2(
                    (error.x * dpdv.y - error.y * dpdv.x) / det,
                    (error.y * dpdu.x - error.x * dpdu.y) / det
                );
                
                uv -= delta;
                uv = clamp(uv, vec2(0.0), vec2(1.0));
            }
            
            return uv;
        }

        vec2 invbilinear( vec2 p, vec2 a, vec2 b, vec2 c, vec2 d )
        {
            vec2 res = vec2(-1.0);

            vec2 e = b-a;
            vec2 f = d-a;
            vec2 g = a-b+c-d;
            vec2 h = p-a;
                
            float k2 = cross2d( g, f );
            float k1 = cross2d( e, f ) + cross2d( h, g );
            float k0 = cross2d( h, e );
            
            // if edges are parallel, this is a linear equation
            if( abs(k2)<0.03 )
            {
                res = vec2( (h.x*k1+f.x*k0)/(e.x*k1-g.x*k0), -k0/k1 );
            }
            // otherwise, it's a quadratic
            else
            {
                float w = k1*k1 - 4.0*k0*k2;
                if( w<0.0 ) return vec2(-1.0);
                w = sqrt( w );

                float ik2 = 0.5/k2;
                float v = (-k1 - w)*ik2;
                float u = (h.x - f.x*v)/(e.x + g.x*v);
                
                if( u<0.0 || u>1.0 || v<0.0 || v>1.0 )
                {
                v = (-k1 + w)*ik2;
                u = (h.x - f.x*v)/(e.x + g.x*v);
                }
                res = vec2( u, v );
            }
            
            return res;
        }

        // Improved inverse bilinear interpolation with better numerical stability
        vec2 invbilinear_stable(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
            vec2 e = b - a;
            vec2 f = d - a;
            vec2 g = a - b + c - d;
            vec2 h = p - a;
            
            float k2 = cross2d(g, f);
            float k1 = cross2d(e, f) + cross2d(h, g);
            float k0 = cross2d(h, e);
            
            // Increased threshold for numerical stability
            const float EPSILON = 1e-4;
            
            // If nearly parallel (approaching rectangle), use linear interpolation
            if (abs(k2) < EPSILON) {
                // Linear case - solve k1*v + k0 = 0
                if (abs(k1) < EPSILON) {
                    return vec2(-1.0); // Degenerate case
                }
                
                float v = -k0 / k1;
                float u;
                
                // Choose the coordinate with larger denominator for stability
                if (abs(e.x + g.x * v) > abs(e.y + g.y * v)) {
                    u = (h.x - f.x * v) / (e.x + g.x * v);
                } else {
                    u = (h.y - f.y * v) / (e.y + g.y * v);
                }
                
                return vec2(u, v);
            }
            
            // Quadratic case
            float discriminant = k1 * k1 - 4.0 * k0 * k2;
            if (discriminant < 0.0) {
                return vec2(-1.0); // No real solution
            }
            
            float sqrt_disc = sqrt(discriminant);
            float ik2 = 0.5 / k2;
            
            // Try both solutions
            float v1 = (-k1 - sqrt_disc) * ik2;
            float v2 = (-k1 + sqrt_disc) * ik2;
            
            for (int i = 0; i < 2; i++) {
                float v = (i == 0) ? v1 : v2;
                
                // Choose coordinate with better numerical stability
                float denom_x = e.x + g.x * v;
                float denom_y = e.y + g.y * v;
                
                float u;
                if (abs(denom_x) > abs(denom_y)) {
                    u = (h.x - f.x * v) / denom_x;
                } else if (abs(denom_y) > EPSILON) {
                    u = (h.y - f.y * v) / denom_y;
                } else {
                    continue; // Try other solution
                }
                
                // Check if solution is valid
                if (u >= -EPSILON && u <= 1.0 + EPSILON && v >= -EPSILON && v <= 1.0 + EPSILON) {
                    return vec2(clamp(u, 0.0, 1.0), clamp(v, 0.0, 1.0));
                }
            }
            
            return vec2(-1.0); // No valid solution found
        }

        vec2 invbilinear_iterative(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
            // Start with center point
            vec2 uv = vec2(0.5, 0.5);
            
            const int MAX_ITERATIONS = 8;
            const float TOLERANCE = 1e-6;
            
            for (int i = 0; i < MAX_ITERATIONS; i++) {
                // Bilinear interpolation: P(u,v) = a + u*e + v*f + u*v*g
                vec2 e = b - a;
                vec2 f = d - a;  
                vec2 g = a - b + c - d;
                
                vec2 current = a + uv.x * e + uv.y * f + uv.x * uv.y * g;
                vec2 error = current - p;
                
                if (length(error) < TOLERANCE) break;
                
                // Jacobian matrix
                vec2 du = e + uv.y * g;  // ∂P/∂u
                vec2 dv = f + uv.x * g;  // ∂P/∂v
                
                // Solve 2x2 system: J * delta = -error
                float det = du.x * dv.y - du.y * dv.x;
                if (abs(det) < 1e-8) break;
                
                vec2 delta = vec2(
                    (-error.x * dv.y + error.y * dv.x) / det,
                    (error.x * du.y - error.y * du.x) / det
                );
                
                uv -= delta;
                uv = clamp(uv, vec2(0.0), vec2(1.0));
            }
            
            return uv;
        }

        void main()
        {
            vec4 white = vec4(1, 1, 1, 1);
            vec4 black = vec4(0, 0, 0, 1);

            
            vec2 va = vertex_pos[0]; // top left
            vec2 vb = vertex_pos[1]; // top right
            vec2 vc = vertex_pos[2]; // bottom right
            vec2 vd = vertex_pos[3]; // bottom left

            // vec2 uv = invbilinear(fragTexCoord, va, vb, vc, vd);
            vec2 uv = invbilinear_enhanced(fragTexCoord, va, vb, vc, vd);
            // vec2 uv = invbilinear_iterative(fragTexCoord, va, vb, vc, vd);

            if (uv.x < 0.0) {
                uv = invbilinear_matrix(fragTexCoord, va, vb, vc, vd);
            }

            uv.x = tex_coord_pos[0] + uv.x*(tex_coord_pos[2] - tex_coord_pos[0]);
            uv.y = tex_coord_pos[1] + uv.y*(tex_coord_pos[3] - tex_coord_pos[1]);

            if (bool(vflip)) {
                uv.y = 1.0 - uv.y;
            }

            vec4 c;

            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                c = white;
            } else {
                if (bool(use_mask) && texture(mask, ((uv * texture0_size) / mask_size)) != white) discard;

                c = texture(texture0, uv);
            }

            if (ink == 39) { // darkest
                if (bool(use_color)) {
                    c = fragColor;
                }

                finalColor = c;

                vec4 c2 = texture(texture1, ((uv * texture0_size) / texture1_size));

                finalColor.r = min(c.r, c2.r);
                finalColor.g = min(c.g, c2.g);
                finalColor.b = min(c.b, c2.b);
                finalColor.a = min(c.a, c2.a);

            } else if (ink == 36) { // transparent background
                if (c == white || c.a <= 0.0001) discard;

                if (bool(use_color)) {
                    c = fragColor;
                }

                if (blend < 0.987) {
                    // vec4 c2 = texture(texture1, ((uv * texture0_size) / texture1_size));
                    // finalColor = mix(c2, c, blend);
                    finalColor = vec4(c.rgb, blend);
                } else {
                    finalColor = c; 
                }
            } else if (ink == 0) { // default
                if (bool(use_color)) {
                    c = fragColor;
                }

                if (blend < 0.987) {
                    // vec4 c2 = texture(texture1, ((uv * texture0_size) / texture1_size));
                    // finalColor = mix(c2, c, blend);
                    finalColor = vec4(c.rgb, blend);
                } else {
                    finalColor = c; 
                }
            }
        })" 
    );

    texture1_loc = GetShaderLocation(shader, "texture0");
    texture2_loc = GetShaderLocation(shader, "texture1");
    mask_loc = GetShaderLocation(shader, "mask");
    texture1_size_loc = GetShaderLocation(shader, "texture0_size");
    texture2_size_loc = GetShaderLocation(shader, "texture1_size");
    mask_size_loc = GetShaderLocation(shader, "mask_size");
    use_mask_loc = GetShaderLocation(shader, "use_mask");
    use_color_loc = GetShaderLocation(shader, "use_color");
    blend_loc = GetShaderLocation(shader, "blend");
    ink_loc = GetShaderLocation(shader, "ink");
    vertices_loc = GetShaderLocation(shader, "vertex_pos");
    src_coords_loc = GetShaderLocation(shader, "tex_coord_pos");
    vflip_loc = GetShaderLocation(shader, "vflip");
}

InvbBevelShader::InvbBevelShader() {
    shader = LoadShaderFromMemory(R"(#version 330

        // Input vertex attributes
        in vec3 vertexPosition;
        in vec2 vertexTexCoord;
        in vec3 vertexNormal;
        in vec4 vertexColor;

        uniform mat4 mvp;

        out vec2 fragTexCoord;
        out vec4 fragColor;

        uniform vec2 vertex_pos[4];

        void main()
        {
            fragTexCoord = vertexPosition.xy;
            
            fragColor = vertexColor;

            gl_Position = mvp*vec4(vertexPosition, 1.0);
        })", R"(#version 330
                                        
        in vec2 fragTexCoord;
        in vec4 fragColor;

        uniform vec2 vertex_pos[4];
        uniform float tex_coord_pos[4];

        uniform sampler2D texture0;
        uniform vec2 texture0_size;
        uniform int vflip;
        uniform int thickness;

        out vec4 finalColor;

        float cross2d(vec2 a, vec2 b) {
            return a.x * b.y - a.y * b.x;
        }

        bool is_rectangle(vec2 a, vec2 b, vec2 c, vec2 d) {
            vec2 ab = b - a;
            vec2 bc = c - b;
            vec2 cd = d - c;
            vec2 da = a - d;
            
            // Check if opposite sides are parallel and equal
            const float EPSILON = 1e-5;
            
            // Check if AB || DC and AD || BC
            bool parallel1 = abs(cross2d(normalize(ab), normalize(-cd))) < EPSILON;
            bool parallel2 = abs(cross2d(normalize(da), normalize(-bc))) < EPSILON;
            
            // Check if adjacent sides are perpendicular
            bool perpendicular = abs(dot(normalize(ab), normalize(bc))) < EPSILON;
            
            return parallel1 && parallel2 && perpendicular;
        }

        vec2 invbilinear_rectangle(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
            // For a rectangle, we can use a more direct approach
            // Transform to local coordinate system where rectangle is axis-aligned
            
            vec2 ab = b - a;  // First side vector
            vec2 ad = d - a;  // Adjacent side vector
            vec2 ap = p - a;  // Vector from corner to point
            
            // Project point onto the rectangle's local axes
            float ab_length_sq = dot(ab, ab);
            float ad_length_sq = dot(ad, ad);
            
            // Avoid division by zero
            if (ab_length_sq < 1e-10 || ad_length_sq < 1e-10) {
                return vec2(-1.0);
            }
            
            float u = dot(ap, ab) / ab_length_sq;
            float v = dot(ap, ad) / ad_length_sq;
            
            return vec2(u, v);
        }

        vec2 invbilinear_enhanced(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
            // First check if it's a rectangle for optimized path
            if (is_rectangle(a, b, c, d)) {
                return invbilinear_rectangle(p, a, b, c, d);
            }
            
            // Fall back to general bilinear inversion with stability improvements
            vec2 e = b - a;
            vec2 f = d - a;
            vec2 g = a - b + c - d;
            vec2 h = p - a;
            
            float k2 = cross2d(g, f);
            float k1 = cross2d(e, f) + cross2d(h, g);
            float k0 = cross2d(h, e);
            
            const float EPSILON = 1e-6;
            
            // Linear case (parallel edges)
            if (abs(k2) < EPSILON) {
                if (abs(k1) < EPSILON) {
                    return vec2(-1.0);
                }
                
                float v = -k0 / k1;
                float u;
                
                // Choose more stable coordinate
                if (abs(e.x + g.x * v) > abs(e.y + g.y * v)) {
                    u = (h.x - f.x * v) / (e.x + g.x * v);
                } else {
                    u = (h.y - f.y * v) / (e.y + g.y * v);
                }
                
                return vec2(u, v);
            }
            
            // Quadratic case
            float discriminant = k1 * k1 - 4.0 * k0 * k2;
            if (discriminant < 0.0) {
                return vec2(-1.0);
            }
            
            float sqrt_disc = sqrt(discriminant);
            float ik2 = 0.5 / k2;
            
            // Try both solutions
            float v1 = (-k1 - sqrt_disc) * ik2;
            float v2 = (-k1 + sqrt_disc) * ik2;
            
            for (int i = 0; i < 2; i++) {
                float v = (i == 0) ? v1 : v2;
                
                float denom_x = e.x + g.x * v;
                float denom_y = e.y + g.y * v;
                
                float u;
                if (abs(denom_x) > abs(denom_y)) {
                    u = (h.x - f.x * v) / denom_x;
                } else if (abs(denom_y) > EPSILON) {
                    u = (h.y - f.y * v) / denom_y;
                } else {
                    continue;
                }
                
                // Allow small tolerance outside [0,1]
                if (u >= -EPSILON && u <= 1.0 + EPSILON && v >= -EPSILON && v <= 1.0 + EPSILON) {
                    return vec2(clamp(u, 0.0, 1.0), clamp(v, 0.0, 1.0));
                }
            }
            
            return vec2(-1.0);
        }

        // Alternative: Matrix-based approach for any quadrilateral
        vec2 invbilinear_matrix(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
            // Use iterative method that's more robust for all cases
            vec2 uv = vec2(0.5, 0.5);
            
            const int MAX_ITERATIONS = 6;
            const float TOLERANCE = 1e-6;
            
            for (int i = 0; i < MAX_ITERATIONS; i++) {
                // Current position using bilinear interpolation
                vec2 p00 = a, p10 = b, p11 = c, p01 = d;
                vec2 current = mix(mix(p00, p10, uv.x), mix(p01, p11, uv.x), uv.y);
                
                vec2 error = current - p;
                if (length(error) < TOLERANCE) break;
                
                // Compute derivatives
                vec2 dpdu = mix(p10 - p00, p11 - p01, uv.y);
                vec2 dpdv = mix(p01 - p00, p11 - p10, uv.x);
                
                // Solve 2x2 system
                float det = dpdu.x * dpdv.y - dpdu.y * dpdv.x;
                if (abs(det) < 1e-10) break;
                
                vec2 delta = vec2(
                    (error.x * dpdv.y - error.y * dpdv.x) / det,
                    (error.y * dpdu.x - error.x * dpdu.y) / det
                );
                
                uv -= delta;
                uv = clamp(uv, vec2(0.0), vec2(1.0));
            }
            
            return uv;
        }

        void main()
        {
            vec4 white = vec4(1, 1, 1, 1);
            vec4 red = vec4(1, 0, 0, 1);
            vec4 blue = vec4(0, 0, 1, 1);
            
            vec2 va = vertex_pos[0]; // top left
            vec2 vb = vertex_pos[1]; // top right
            vec2 vc = vertex_pos[2]; // bottom right
            vec2 vd = vertex_pos[3]; // bottom left

            vec2 uv = invbilinear_enhanced(fragTexCoord, va, vb, vc, vd);

            // if (uv.x < 0.0) {
            //     uv = invbilinear_matrix(fragTexCoord, va, vb, vc, vd);
            // }

            uv.x = tex_coord_pos[0] + uv.x*(tex_coord_pos[2] - tex_coord_pos[0]);
            uv.y = tex_coord_pos[1] + uv.y*(tex_coord_pos[3] - tex_coord_pos[1]);

            if (bool(vflip)) {
                uv.y = 1.0 - uv.y;
            }

            vec4 c;

            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                c = white;
            } else {
                c = texture(texture0, uv);
            }

            if (c == white) discard;

            vec2 pixel = vec2(1, 1) / texture0_size;

            int dirmod = 1;
            if (bool(vflip)) { dirmod = -1; }

            bool is_edge_red = false;
            bool is_edge_blue = false;

            for (int i = -int(thickness); i <= int(thickness); ++i) {
                for (int j = -int(thickness); j <= int(thickness); ++j) {
                    if (i == 0 && j == 0) continue;

                    vec2 offset = vec2(float(i), float(j)) * pixel;
                    vec2 sampleUV = uv + offset;

                    // Skip out-of-bounds samples
                    if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0) continue;

                    vec4 neighbor = texture(texture0, sampleUV);
                    if (neighbor == white) {
                        if (i >= 0 || j >= 0) {
                            is_edge_red = true;
                            break;
                        } else if (i <= 0 || j <= 0) {
                            is_edge_blue = true;
                            break;
                        }
                    }
                }
                if (is_edge_blue || is_edge_red) break;
            }

            if (is_edge_blue) {
                finalColor = blue;
                return;
            } else if (is_edge_red) {
                finalColor = red;
                return;
            }

            finalColor = vec4(0, 1, 0, 1);
        })");

    texture1_loc = GetShaderLocation(shader, "texture0");
    texture1_size_loc = GetShaderLocation(shader, "texture0_size");
    vflip_loc = GetShaderLocation(shader, "vflip");
    vertices_loc = GetShaderLocation(shader, "vertex_pos");
    src_coords_loc = GetShaderLocation(shader, "tex_coord_pos");
    thickness_loc = GetShaderLocation(shader, "thickness");
}

SoftPropShader::SoftPropShader() {
    shader = LoadShaderFromMemory(nullptr, R"(
        #version 330

        in vec2 fragTexCoord;
        in vec4 fragColor;

        uniform sampler2D texture0;

        uniform vec2 texture_size;
        uniform int vflip; // 0, 1
        uniform int effect_color; // 0, 1, 2
        uniform int self_shade; // 0, 1
        uniform int smooth_shading;
        uniform int depth_affecthilites;
        uniform int highlight_border;
        uniform int shadow_border;
        uniform int contour_exp;
        uniform float depth; // 0 - 1

        out vec4 finalColor;

        float get_depth(vec2 pos) {
            return texture(texture0, pos).g;
        }

        void main()
        {
            vec2 uv = fragTexCoord;
            vec2 one = vec2(1, 1) / texture_size;
            vec4 white = vec4(1, 1, 1, 1);
            vec4 black = vec4(0, 0, 0, 1);

            // if (bool(vflip)) { uv.y = 1.0 - uv.y; }

            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                discard;
            }

            vec4 pixel = texture(texture0, uv);

            if (depth > pixel.g) { discard; }

            if (pixel == white || pixel == black) { discard; }
            
            float pixel_depth = pixel.g;

            vec3 pal_color = vec3(0, 1, 0);

            float dirmod = 1;
            if (bool(vflip)) dirmod = -1;

            if (effect_color == 1) {
                pal_color = vec3(1, 0, 1);
            } else if (effect_color == 2) {
                pal_color = vec3(0, 1, 1); 
            }

            if (self_shade == 0) {
                if (effect_color == 1) {
                    if (pixel.b > 1.0/3.0*2) {
                        pal_color = vec3(1, 150/255.0, 1);
                    } else if (pixel.b < 1.0/3.0) {
                        pal_color = vec3(150/255.0, 0, 150/255.0);
                    }
                } else if (effect_color == 2) {
                    if (pixel.b > 1.0/3.0*2) {
                        pal_color = vec3(150/255.0, 1, 1);
                    } else if (pixel.b < 1.0/3.0) {
                        pal_color = vec3(0,150/255.0,150/255.0);
                    }
                } else {
                    if (pixel.b > 1.0/3.0*2) {
                        pal_color = vec3(0, 0 ,1);
                    } else if (pixel.b < 1.0/3.0) {
                        pal_color = vec3(1, 0, 0);
                    }
                }
            }

            float ang = 0;

            for (int a = 1; a <= smooth_shading; a++) {
                // iteration 1
                vec2 point = vec2(1, 0) * one;

                ang += (pixel_depth - get_depth(uv - point*a) + (get_depth(uv + point*a) - depth));

                // iteration 2
                point = vec2(1, 1) * one;

                ang += (pixel_depth - get_depth(uv - point*a) + (get_depth(uv + point*a) - depth));

                // iteration 3
                point = vec2(0, 1) * one;

                ang += (pixel_depth - get_depth(uv - point*a) + (get_depth(uv + point*a) - depth));
            }

            ang /= smooth_shading * 3;

            ang *= 1 - pixel.r;

            if (ang * 10 * pow(pixel_depth, depth_affecthilites) > highlight_border) {
                if (effect_color == 1) {
                    pal_color = vec3(1, 150/255.0, 1);
                } else if (effect_color == 2) {
                    pal_color = vec3(150/255.0, 1, 1);
                } else {
                    pal_color = vec3(0, 0, 1);
                }
            } else if (-ang*10.0 > shadow_border) {
                if (effect_color == 1) {
                    pal_color = vec3(150/255.0, 0, 150/255.0);
                } else if (effect_color == 2) {
                    pal_color = vec3(0, 150/255.0, 150/255.0);
                } else {
                    pal_color = vec3(1, 0, 0);
                }
            }

            finalColor = vec4(pal_color, 1);
        }
    )");

    depth_loc = GetShaderLocation(shader, "depth");
    texture_loc = GetShaderLocation(shader, "texture0");
    texture_size_loc = GetShaderLocation(shader, "texture_size");
    vflip_loc = GetShaderLocation(shader, "vflip");
    effect_color_loc = GetShaderLocation(shader, "effect_color");
    self_shade_loc = GetShaderLocation(shader, "self_shade");
    smooth_shading_loc = GetShaderLocation(shader, "smooth_shading");
    depth_affecthilites_loc = GetShaderLocation(shader, "depth_affecthilites");
    highlight_border_loc = GetShaderLocation(shader, "highlight_border");
    shadow_border_loc = GetShaderLocation(shader, "shadow_border");
    contour_exp_loc = GetShaderLocation(shader, "contour_exp");
}

BevelShader::BevelShader() {
    shader = LoadShaderFromMemory(nullptr, R"(
        version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 FragColor;

uniform sampler2D texture0;
uniform int vflip;
uniform vec2 texture_size;
uniform int thickness;
// uniform vec3 highlight;
// uniform vec3 shadow;

void main() {
    vec4 white = vec4(1, 1, 1, 1);
    vec4 red = vec4(1, 0, 0, 1);
    vec4 blue = vec4(0, 0, 1, 1);

    vec4 sample;

    vec2 uv;

    if (bool(vflip)) {
        uv = vec2(fragTexCoord.x, 1.0 - fragTexCoord.y);
    } else {
        uv = fragTexCoord;
    }

    sample = texture(texture0, uv);

    if (sample == white) {
        discard;
    }

    vec2 pixel = vec2(1, 1) / texture_size;

    vec4 left = texture(texture0, vec2(uv.x - pixel.x, uv.y));
    vec4 top = texture(texture0, vec2(uv.x, uv.y - pixel.y));
    vec4 right = texture(texture0, vec2(uv.x + pixel.x, uv.y));
    vec4 bottom = texture(texture0, vec2(uv.x, uv.y + pixel.y));

    vec4 topleft = texture(texture0, uv - pixel);
    vec4 topright = texture(texture0, vec2(uv.x + pixel.x, uv.y - pixel.y));
    vec4 bottomright = texture(texture0, uv + pixel);
    vec4 bottomleft = texture(texture0, vec2(uv.x - pixel.x, uv.y + pixel.y));

    // Right and bottom edges = red
    if (right == white || bottom == white) {
        FragColor = red;
        return;
    }
    // Left and top edges = blue  
    if (left == white || top == white) {
        FragColor = blue;
        return;
    }

    // Diagonal edges - choose based on your preference
    if (bottomright == white || topright == white) {
        FragColor = red;
        return;
    }
    if (topleft == white || bottomleft == white) {
        FragColor = blue;
        return;
    }
    
    FragColor = sample;
})");
}

};