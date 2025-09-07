#include <Orbit/RlExt/rl.h>

#include <raylib.h>
#include <rlgl.h>

namespace Orbit::RlExt {

void DrawTexture(
  const Texture2D *texture, 
  const Rectangle *src, 
  const Vector2 quad[4], 
  Color color
) {
  // rlSetCullFace(RL_CULL_FACE_FRONT);
  rlSetTexture(texture->id);

  rlBegin(RL_QUADS);

  rlColor4ub(color.r, color.g, color.b, color.a);

  // top right
  rlTexCoord2f((src->x+texture->width)/texture->width, src->y/texture->height);
  rlVertex2i(quad[1].x, quad[1].y);

  // top left
  rlTexCoord2f(src->x/src->width, src->y/src->height);
  rlVertex2i(quad[0].x, quad[0].y);
  
  // bottom left
  rlTexCoord2f(src->x/texture->width, (src->y+src->height)/texture->height);
  rlVertex2i(quad[3].x, quad[3].y);

  // bottom right
  rlTexCoord2f((src->x+src->width)/texture->width, (src->y+src->height)/texture->height);
  rlVertex2i(quad[2].x, quad[2].y);

  rlEnd();

  rlSetTexture(0);
}

};