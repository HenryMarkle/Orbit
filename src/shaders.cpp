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

        vec4 texelColor = texture(texture0, fragTexCoord);

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

};