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
    rlSetTexture(texture->id);

    rlBegin(RL_QUADS);

    rlColor4ub(color.r, color.g, color.b, color.a);

    bool flipx = quad[0].x > quad[1].x && quad[3].x > quad[2].x;
    bool flipy = quad[0].y > quad[3].y && quad[1].y > quad[2].y;
    

    int vtrx = flipx ? quad[0].x : quad[1].x;
    int vtry = flipy ? quad[2].y : quad[1].y;

    int vtlx = flipx ? quad[1].x : quad[0].x;
    int vtly = flipy ? quad[3].y : quad[0].y;

    int vblx = flipx ? quad[2].x : quad[3].x;
    int vbly = flipy ? quad[0].y : quad[3].y;

    int vbrx = flipx ? quad[3].x : quad[2].x;
    int vbry = flipy ? quad[1].y : quad[2].y;


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