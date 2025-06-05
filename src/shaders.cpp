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
}

};