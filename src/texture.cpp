#include <optional>
#include <sstream>
#include <cstring>
#include <cstdint>
#include <string>

#include <xsimd/xsimd.hpp>

#include <Orbit/RlExt/image.h>
#include <Orbit/Lua/rect.h>
#include <Orbit/Lua/quad.h>
#include <Orbit/Lua/runtime.h>
#include <Orbit/RlExt/rl.h>

#include <raylib.h>
#include <rlgl.h>

extern "C" {
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

#define META "image"

static int texture_fill(lua_State *L) {
	RenderTexture2D *texture  = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));
	Color *c = static_cast<Color *>(luaL_testudata(L, 2, "color"));

	BeginTextureMode(*texture);
	ClearBackground(c ? *c : WHITE);
	EndTextureMode();
    
	return 0;
}

static int texture_tostring(lua_State *L) {
	std::stringstream ss;

	lua_pushstring(L, META);

	return 1;
}

static int texture_concat(lua_State *L) {
	std::string a = lua_tolstring(L, 1, nullptr);
	std::string b = lua_tolstring(L, 2, nullptr);

	lua_pushstring(L, (a + b).c_str());
	return 1;
}

static int texture_make_silhouette(lua_State *L){ 
	RenderTexture2D *texture = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));
	bool invert = lua_toboolean(L, 2);
	// *nimg = MakeSilhouette(img);

	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
	auto &shadero = runtime->shaders->silhouette;
	// auto t = LoadTextureFromImage(*img);
	auto canvas = LoadRenderTexture(texture->texture.width, texture->texture.height);
	
	BeginTextureMode(canvas);
	
	BeginShaderMode(shadero.shader);
	shadero.prepare(texture->texture, invert, true);
	DrawTexturePro(
		texture->texture, 
		{
			0, 0,
			static_cast<float>(texture->texture.width),
			-static_cast<float>(texture->texture.height)
		},
		{
			0, 0,
			static_cast<float>(texture->texture.width),
			static_cast<float>(texture->texture.height)
		},
		{ 0, 0 },
		0, 
		WHITE
	);
	EndShaderMode();

	EndTextureMode();

	RenderTexture2D *ntexture = static_cast<RenderTexture2D *>(lua_newuserdata(L, sizeof(RenderTexture2D)));

	*ntexture = canvas;

	luaL_getmetatable(L, "image");
	lua_setmetatable(L, -2);

	return 1; 
}

static int texture_rect (lua_State *L2){
	RenderTexture2D *texture = static_cast<RenderTexture2D *>(luaL_checkudata(L2, 1, "image"));
	
	auto *rect = static_cast<Orbit::Lua::Rect *>(lua_newuserdata(L2, sizeof(Orbit::Lua::Rect)));
	new (rect) Orbit::Lua::Rect(
		0, 0,
		(float)texture->texture.width,
		(float)texture->texture.height
	);

	luaL_getmetatable(L2, "rect");
	lua_setmetatable(L2, -2);

	return 1;
}

static Orbit::RlExt::CopyImageParams parse_copy_params(lua_State *L, int index) {
	luaL_checktype(L, index, LUA_TTABLE);

	auto params = Orbit::RlExt::CopyImageParams();	
	
	lua_getfield(L, index, "ink");
	if (!lua_isnil(L, -1)) {
		params.ink = static_cast<Orbit::RlExt::CopyImageInk>(lua_tointeger(L, -1));
	}
	lua_pop(L, 1);

	lua_getfield(L, index, "blend");
	if (!lua_isnil(L, -1)) {
		params.blend = lua_tonumber(L, -1);
	}
	lua_pop(L, 1);

	lua_getfield(L, index, "color");
	if (!lua_isnil(L, -1)) {
		if (Color *c = static_cast<Color *>(luaL_testudata(L, -1, "color")); c != nullptr) {
			if (c) params.color = *c;
		} else if (lua_type(L, 1) == LUA_TNUMBER) {
			uint32_t i = static_cast<uint32_t>(lua_tointeger(L, 1));

			params.color = *(Color *) &i;
		}
	}
	lua_pop(L, 1);
	
	lua_getfield(L, index, "mask");
	if (!lua_isnil(L, -1)) {
		RenderTexture2D *i = static_cast<RenderTexture2D *>(luaL_checkudata(L, -1, "image"));
		params.mask = &i->texture;
	}
	lua_pop(L, 1);

	return params;
}

static int texture_copy_pixels(lua_State *L) {
	int count = lua_gettop(L);
	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

	RenderTexture2D *dst = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));
	RenderTexture2D *src = nullptr;

	RenderTexture2D tmp = {0};

	if (src = static_cast<RenderTexture2D *>(luaL_testudata(L, 2, "image")); src == nullptr) {
		auto *img = static_cast<Image *>(luaL_checkudata(L, 2, "imagebuf"));

		Texture2D t = LoadTextureFromImage(*img);

		tmp = LoadRenderTexture(img->width, img->height);
	
		BeginTextureMode(tmp);
		ClearBackground(WHITE);
		DrawTextureRec(t, { 0, 0, (float)t.width, (float)-t.height }, { 0, 0 }, WHITE);
		EndTextureMode();

		UnloadTexture(t);

		src = &tmp;
	}

	void *arg3Ptr = nullptr;
	void *arg4Ptr = nullptr;

	if (
		(arg3Ptr = luaL_testudata(L, 3, "rect")) != nullptr &&
		(arg4Ptr = luaL_testudata(L, 4, "rect")) != nullptr
	) {
		// copy(dst, src, dstRect, srcRect, {opt})

		auto *dstRect = static_cast<Orbit::Lua::Rect *>(arg3Ptr);
		auto *srcRect = static_cast<Orbit::Lua::Rect *>(arg4Ptr);

		Orbit::RlExt::CopyImageParams params;
		if (lua_istable(L, 5)) params = parse_copy_params(L, 5);

		Orbit::RlExt::CopyImage_GPU(
			&runtime->shaders->copy_pixels,
			src,
			dst,
			srcRect,
			dstRect,
			params
		);
	}
	else if (
		(arg3Ptr = luaL_testudata(L, 3, "quad")) != nullptr &&
		(arg4Ptr = luaL_testudata(L, 4, "rect")) != nullptr
	) {
		// copy(dst, src, dstQuad, srcRect, {opt})

		auto *dstQuad = static_cast<Orbit::Lua::Quad *>(arg3Ptr);
		auto *srcRect = static_cast<Orbit::Lua::Rect *>(arg4Ptr);

		Orbit::RlExt::CopyImageParams params;
		if (lua_istable(L, 5)) params = parse_copy_params(L, 5);

		Orbit::RlExt::CopyImage_GPU(
			&runtime->shaders->invb_copy_pixels,
			src,
			dst,
			srcRect,
			dstQuad,
			params
		);
	} 
	else if (
		lua_istable(L, 3) &&
		(arg4Ptr = luaL_testudata(L, 4, "rect")) != nullptr
	) {
		// copy(dst, src, dstQuad, srcRect, {opt})

		// auto *dstQuad = *static_cast<Orbit::Lua::Quad **>(arg3Ptr);
		lua_rawgeti(L, 3, 1);
		lua_rawgeti(L, 3, 2);
		lua_rawgeti(L, 3, 3);
		lua_rawgeti(L, 3, 4);

		Vector2 dstQuad[4] = {
			*static_cast<Vector2 *>(luaL_checkudata(L, 4, "point")),
			*static_cast<Vector2 *>(luaL_checkudata(L, 5, "point")),
			*static_cast<Vector2 *>(luaL_checkudata(L, 6, "point")),
			*static_cast<Vector2 *>(luaL_checkudata(L, 7, "point"))
		};
		
		lua_remove(L, 4);
		lua_remove(L, 4);
		lua_remove(L, 4);
		lua_remove(L, 4);

		auto *srcRect = static_cast<Orbit::Lua::Rect *>(arg4Ptr);

		Orbit::RlExt::CopyImageParams params;
		if (lua_istable(L, 5)) params = parse_copy_params(L, 5);

		Orbit::RlExt::CopyImage_GPU(
			&runtime->shaders->invb_copy_pixels,
			src,
			dst,
			srcRect,
			reinterpret_cast<Orbit::Lua::Quad *>(&dstQuad),
			params
		);
	} 
	else if (
		(arg3Ptr = luaL_testudata(L, 3, "rect")) != nullptr
	) {
		// copy(dst, src, dstRect, {opt})

		auto *dstRect = static_cast<Orbit::Lua::Rect *>(arg3Ptr);
		auto srcRect = Orbit::Lua::Rect {0, 0, (float)src->texture.width, (float)src->texture.height};

		Orbit::RlExt::CopyImageParams params;
		if (lua_istable(L, 4)) params = parse_copy_params(L, 4);

		Orbit::RlExt::CopyImage_GPU(
			&runtime->shaders->copy_pixels,
			src,
			dst,
			&srcRect,
			dstRect,
			params
		);
	}
	else if (
		lua_istable(L, 3)
	) {
		// copy(dst, src, dstRect, {opt})

		lua_rawgeti(L, 3, 1);
		lua_rawgeti(L, 3, 2);
		lua_rawgeti(L, 3, 3);
		lua_rawgeti(L, 3, 4);

		Vector2 dstQuad[4] = {
			*static_cast<Vector2 *>(luaL_checkudata(L, 4, "point")),
			*static_cast<Vector2 *>(luaL_checkudata(L, 5, "point")),
			*static_cast<Vector2 *>(luaL_checkudata(L, 6, "point")),
			*static_cast<Vector2 *>(luaL_checkudata(L, 7, "point"))
		};
		
		lua_remove(L, 4);
		lua_remove(L, 4);
		lua_remove(L, 4);
		lua_remove(L, 4);

		auto srcRect = Orbit::Lua::Rect {0, 0, (float)src->texture.width, (float)src->texture.height};

		Orbit::RlExt::CopyImageParams params;
		if (lua_istable(L, 4)) params = parse_copy_params(L, 4);

		Orbit::RlExt::CopyImage_GPU(
			&runtime->shaders->invb_copy_pixels,
			src,
			dst,
			&srcRect,
			reinterpret_cast<Orbit::Lua::Quad *>(&dstQuad),
			params
		);
	}
	else if (
		(arg3Ptr = luaL_testudata(L, 3, "quad")) != nullptr
	) {
		// copy(dst, src, dstRect, {opt})

		auto *dstQuad = static_cast<Orbit::Lua::Quad *>(arg3Ptr);
		auto srcRect = Orbit::Lua::Rect {0, 0, (float)src->texture.width, (float)src->texture.height};

		Orbit::RlExt::CopyImageParams params;
		if (lua_istable(L, 4)) params = parse_copy_params(L, 4);

		Orbit::RlExt::CopyImage_GPU(
			&runtime->shaders->invb_copy_pixels,
			src,
			dst,
			&srcRect,
			dstQuad,
			params
		);
	}
	else {
		// copy(dst, src, {opt})

		auto targetRect = Orbit::Lua::Rect {0, 0, (float)src->texture.width, (float)src->texture.height};

		Orbit::RlExt::CopyImageParams params;
		if (lua_istable(L, 3)) params = parse_copy_params(L, 3);

		Orbit::RlExt::CopyImage_GPU(
			&runtime->shaders->copy_pixels,
			src,
			dst,
			&targetRect,
			&targetRect,
			params
		);
	}

	if (tmp.id != 0) UnloadRenderTexture(tmp);
	return 0;
}

static int texture_get_pixel(lua_State *L) {
	RenderTexture2D *texture = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));

	int x, y;

	if (void *ptr = luaL_testudata(L, 2, "point"); ptr != nullptr) {
		Vector2 *p = static_cast<Vector2 *>(ptr);

		x = static_cast<int>(std::round(p->x));
		y = static_cast<int>(std::round(p->y));
	} else {
		x = luaL_checkinteger(L, 2);
		y = luaL_checkinteger(L, 3);
	}


    // Validate bounds
    if (x < 0 || x >= texture->texture.width || y < 0 || y >= texture->texture.height) {
        auto *c = static_cast<Color*>(lua_newuserdata(L, sizeof(Color)));
		
		c->r = 255;
		c->g = 255;
		c->b = 255;
		c->a = 255;

		luaL_getmetatable(L, "color");
		lua_setmetatable(L, -2);

		return 1;
    }

	y = texture->texture.height - y;

    // Calculate the offset (assuming uncompressed, R8G8B8A8, 4 bytes per pixel)
    int bytesPerPixel = 4;

	switch (texture->texture.format) {
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8: bytesPerPixel = 4; break;
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8: bytesPerPixel = 3; break;
		case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE: bytesPerPixel = 1; break;
		default: return luaL_error(L, "Unsupported image format: %d", texture->texture.format); break;
	}

    auto image = LoadImageFromTexture(texture->texture);

    unsigned char *data = (unsigned char *)image.data;
    int index = (y * image.width + x) * bytesPerPixel;

	auto *color = static_cast<Color*>(lua_newuserdata(L, sizeof(Color)));

	switch (image.format) {
        case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8:
            color->r = data[index + 0];
            color->g = data[index + 1];
            color->b = data[index + 2];
            color->a = data[index + 3];
            break;
        case PIXELFORMAT_UNCOMPRESSED_R8G8B8:
            color->r = data[index + 0];
            color->g = data[index + 1];
            color->b = data[index + 2];
            color->a = 255;  // No alpha channel, set to opaque
            break;
        case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE:
            color->r = data[index];
            color->g = data[index];
            color->b = data[index];
            color->a = 255;  // No alpha channel, set to opaque
		break;
    }

    UnloadImage(image);

	luaL_getmetatable(L, "color");
	lua_setmetatable(L, -2);

	return 1;
}

static int texture_set_pixel(lua_State *L) {
	RenderTexture2D *texture = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));

    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
	auto *c = static_cast<Color *>(luaL_checkudata(L, 4, "color"));

    // Validate bounds
    if (x < 0 || x >= texture->texture.width || y < 0 || y >= texture->texture.height) {
        return 0;
    }

	x = texture->texture.width - x;
	y = texture->texture.height - y;

    auto *color = static_cast<Color*>(lua_newuserdata(L, sizeof(Color)));

	BeginTextureMode(*texture);
	DrawRectangle(x, y, 1, 1, *color);
	EndTextureMode();

	return 0;
}

static int texture_index(lua_State *L) {
	RenderTexture2D *texture = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, META));
	const char *field = luaL_checkstring(L, 2);

	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
	
	if (std::strcmp(field, "width") == 0) lua_pushnumber(L, texture->texture.width);
	else if (std::strcmp(field, "height") == 0) lua_pushnumber(L, texture->texture.height);
	else if (std::strcmp(field, "clear") == 0) lua_pushcfunction(L, texture_fill);
	else if (std::strcmp(field, "rect") == 0) texture_rect(L);
	else if (std::strcmp(field, "copyPixels") == 0) {
		lua_pushlightuserdata(L, runtime);
		lua_pushcclosure(L, texture_copy_pixels, 1);
	}
	else if (std::strcmp(field, "getPixel") == 0) lua_pushcfunction(L, texture_get_pixel);
	else if (std::strcmp(field, "setPixel") == 0) lua_pushcfunction(L, texture_set_pixel);
	else if (std::strcmp(field, "silhouette") == 0) {
		lua_pushlightuserdata(L, runtime);
		lua_pushcclosure(L, texture_make_silhouette, 1);
	}
	else lua_pushnil(L);

	return 1;
}

int texture_eq(lua_State *L) {
	RenderTexture2D *a = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, META));
	RenderTexture2D *b = static_cast<RenderTexture2D *>(luaL_checkudata(L, 2, META));

	lua_pushboolean(L, a == b);

	return 1;
}

int texture_gc(lua_State *L) {
	RenderTexture2D *texture = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, META));
	UnloadRenderTexture(*texture);
	return 0;
}


static int texture_copy_pixels_soft_prop(lua_State *L) {
	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

	RenderTexture2D *dst = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));
	RenderTexture2D *src = static_cast<RenderTexture2D *>(luaL_checkudata(L, 2, "image"));
	
	Orbit::Lua::Rect *dstRect = static_cast<Orbit::Lua::Rect *>(luaL_checkudata(L, 3, "rect"));

	float normalized_depth = luaL_checknumber(L, 4);
	int effect_color = lua_tointeger(L, 5);
	int self_shade = lua_tointeger(L, 6);
	int smooth_shading = lua_tointeger(L, 7);
	int depth_highlites = lua_tointeger(L, 8);
	int highlight_border = lua_tointeger(L, 9);
	int shadow_border = lua_tointeger(L, 10);

	auto &sh = runtime->shaders->soft_prop;

	BeginTextureMode(*dst);
	BeginShaderMode(sh.shader);
	sh.prepare(
		src->texture, 
		1.0f - normalized_depth,
		effect_color, 
		self_shade, 
		smooth_shading,
		depth_highlites,
		highlight_border,
		shadow_border
	);
	DrawTexturePro(
		src->texture, 
		{ 0, 0, static_cast<float>(src->texture.width), -static_cast<float>(src->texture.height) },
		{ dstRect->_left, dst->texture.height - dstRect->GetHeight() - dstRect->_top, dstRect->GetWidth(), dstRect->GetHeight() },
		{ 0, 0 },
		0,
		WHITE
	);
	EndShaderMode();
	EndTextureMode();

	return 0;
}

static int texture_copy_pixels_bevel(lua_State *L) {
	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

	RenderTexture2D *dst = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));
	RenderTexture2D *src = static_cast<RenderTexture2D *>(luaL_checkudata(L, 2, "image"));

	Orbit::Lua::Quad *dstQuad = static_cast<Orbit::Lua::Quad *>(luaL_checkudata(L, 3, "quad"));
	Orbit::Lua::Rect *srcRect = static_cast<Orbit::Lua::Rect *>(luaL_checkudata(L, 4, "rect"));

	int thickness = lua_tointeger(L, 5);
	if (thickness == 0) thickness = 1;

	auto &sh = runtime->shaders->invb_bevel;

	auto srcRectangle = Rectangle{srcRect->_left, srcRect->_top, srcRect->GetWidth(), srcRect->GetHeight()};

	Vector2 flipped[4] = {
		{dstQuad->bottomleft.x, dst->texture.height - dstQuad->bottomleft.y},   // was topleft, now bottomleft  
		{dstQuad->bottomright.x, dst->texture.height - dstQuad->bottomright.y}, // was topright, now bottomright
		{dstQuad->topright.x, dst->texture.height - dstQuad->topright.y},       // was bottomright, now topright
		{dstQuad->topleft.x, dst->texture.height - dstQuad->topleft.y}          // was bottomleft, now topleft
	};

	BeginTextureMode(*dst);
	BeginShaderMode(sh.shader);
	sh.prepare(
		src->texture,
		srcRectangle,
		flipped,
		thickness,
		true
	);
	Orbit::RlExt::DrawTexture(&src->texture, &srcRectangle, flipped, WHITE);
	
	EndShaderMode();
	
	EndTextureMode();

	return 0;
}

namespace Orbit::RlExt {

CopyImageParams::CopyImageParams() : 
    blend(1), 
    color(std::nullopt), 
    ink(CopyImageInk::None), 
    mask(nullptr) {}

CopyImageParams::CopyImageParams(
    float blend, 
    std::optional<Color> color, 
    CopyImageInk ink, 
    Texture2D *mask
) : 
    blend(blend), 
    color(color), 
    ink(ink), 
    mask(mask) {}


void CopyImage_GPU(
	const Orbit::CopyPixelsShader *shader, 
	const RenderTexture2D *src, 
	RenderTexture2D *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Rect *to, 
	const CopyImageParams &params
) {
    BeginTextureMode(*dst);
    
    BeginShaderMode(shader->shader);
    shader->prepare(
        src->texture, 
        dst->texture, 
        params.color != std::nullopt, 
        static_cast<int>(params.ink), 
        params.blend,
        false,
        params.mask
    );
    DrawTexturePro(
        src->texture, 
        Rectangle{from->_left, from->_top, from->GetWidth(), -from->GetHeight()}, 
        Rectangle{to->_left, dst->texture.height -to->GetHeight() - to->_top, to->GetWidth(), to->GetHeight()},
        Vector2{0, 0},
        0, 
        params.color.value_or(WHITE)
    );
    EndShaderMode();
    EndTextureMode();
}

void CopyImage_GPU(
	const Orbit::InvbCopyPixelsShader *shader, 
	const RenderTexture2D *src, 
	RenderTexture2D *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Quad *to, 
	const CopyImageParams &params
) {
	auto srcRect = Rectangle{from->_left, from->_top, from->GetWidth(), from->GetHeight()};

	Vector2 flipped[4] = {
		{to->bottomleft.x, dst->texture.height - to->bottomleft.y},   // was topleft, now bottomleft  
		{to->bottomright.x, dst->texture.height - to->bottomright.y}, // was topright, now bottomright
		{to->topright.x, dst->texture.height - to->topright.y},       // was bottomright, now topright
		{to->topleft.x, dst->texture.height - to->topleft.y}          // was bottomleft, now topleft
	};

    BeginTextureMode(*dst);
    
    BeginShaderMode(shader->shader);
    shader->prepare(
        src->texture, 
        dst->texture,
		srcRect,
		flipped,
        params.color != std::nullopt, 
        static_cast<int>(params.ink), 
        params.blend,
        true,
        params.mask
    );
	Orbit::RlExt::DrawTexture(&src->texture, &srcRect, flipped, params.color.value_or(WHITE));
    EndShaderMode();
    EndTextureMode();
}

};

namespace Orbit::Lua {

void LuaRuntime::_register_image() {

	luaL_newmetatable(L, META);

	lua_pushcfunction(L, texture_tostring);
	lua_setfield(L, -2, "__tostring");

	lua_pushcfunction(L, texture_concat);
	lua_setfield(L, -2, "__concat");

	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, texture_index, 1);
	lua_setfield(L, -2, "__index");

	lua_pushcfunction(L, texture_eq);
	lua_setfield(L, -2, "__eq");

	lua_pushcfunction(L, texture_gc);
	lua_setfield(L, -2, "__gc");

    lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, texture_make_silhouette, 1);
	lua_setglobal(L, "silhouette");

	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, texture_copy_pixels, 1);
	lua_setglobal(L, "copyPixels");


	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, texture_copy_pixels_soft_prop, 1);
	lua_setglobal(L, "copyPixelsSoftProp");

	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, texture_copy_pixels_bevel, 1);
	lua_setglobal(L, "copyPixelsBevel");

	lua_pop(L, 1);

}

};
