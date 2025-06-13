#include <Orbit/rl.h>

#include <Orbit/rect.h>
#include <Orbit/quad.h>

#include <raylib.h>
#include <rlgl.h>

namespace Orbit::RlExt {

void DrawTexture(
  const Texture2D *texture, 
  const Rectangle *src, 
  const Orbit::Lua::Quad *quad, 
  Color color
) {
    rlSetTexture(texture->id);

    rlBegin(RL_QUADS);

    rlColor4ub(color.r, color.g, color.b, color.a);

    bool flipx = quad->topleft.x > quad->topright.x && quad->bottomleft.x > quad->bottomright.x;
    bool flipy = quad->topleft.y > quad->bottomleft.y && quad->topright.y > quad->bottomright.y;
    

    int vtrx = flipx ? quad->topleft.x : quad->topright.x;
    int vtry = flipy ? quad->bottomright.y : quad->topright.y;

    int vtlx = flipx ? quad->topright.x : quad->topleft.x;
    int vtly = flipy ? quad->bottomleft.y : quad->topleft.y;

    int vblx = flipx ? quad->bottomright.x : quad->bottomleft.x;
    int vbly = flipy ? quad->topleft.y : quad->bottomleft.y;

    int vbrx = flipx ? quad->bottomleft.x : quad->bottomright.x;
    int vbry = flipy ? quad->topright.y : quad->bottomright.y;


    float topright_vx = (src->x + src->width) / texture->width;
    float topright_vy = (src->y)             / texture->height;

    float topleft_vx = (src->x) / texture->width;
    float topleft_vy = (src->y) / texture->height;

    float bottomleft_vx = (src->x)              / texture->width;
    float bottomleft_vy = (src->y + src->height) / texture->height;

    float bottomright_vx = (src->x + src->width)  / texture->width;
    float bottomright_vy = (src->y + src->height) / texture->height;


    float ttrx = flipx ? topleft_vx     : topright_vx;
    float ttry = flipy ? bottomright_vy : topright_vy;

    float ttlx = flipx ? topright_vx   : topleft_vx;
    float ttly = flipy ? bottomleft_vy : topleft_vy;

    float tblx = flipx ? bottomright_vx : bottomleft_vx;
    float tbly = flipy ? topleft_vy     : bottomleft_vy;

    float tbrx = flipx ? bottomleft_vx : bottomright_vx;
    float tbry = flipy ? topright_vy   : bottomright_vy;


    // top right
    rlTexCoord2f(ttrx, ttry);
    rlVertex2i(vtrx, vtry);

    // top left
    rlTexCoord2f(ttlx, ttly);
    rlVertex2i(vtlx, vtly);
    
    // bottom left
    rlTexCoord2f(tblx, tbly);
    rlVertex2i(vblx, vbly);

    // bottom right
    rlTexCoord2f(tbrx, tbry);
    rlVertex2i(vbrx, vbry);

    
    // top right
    rlTexCoord2f(ttrx, ttry);
    rlVertex2i(vtrx, vtry);

    rlEnd();

    rlSetTexture(0);
}

};