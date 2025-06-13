#pragma once

#include <Orbit/rect.h>
#include <Orbit/quad.h>

#include <raylib.h>

namespace Orbit::RlExt {

void DrawTexture(
  const Texture2D *texture, 
  const Rectangle *src, 
  const Orbit::Lua::Quad *quad, 
  Color color
);

};