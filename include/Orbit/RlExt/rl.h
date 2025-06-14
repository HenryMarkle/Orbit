#pragma once

#include <raylib.h>

namespace Orbit::RlExt {

void DrawTexture(
  const Texture2D *texture, 
  const Rectangle *src, 
  const Vector2 quad[4], 
  Color color
);

};