#include <immintrin.h>
#include <optional>
#include <sstream>
#include <cstring>
#include <cstdint>
#include <string>
#include <cmath>

#include <xsimd/xsimd.hpp>
#include <mmintrin.h>

#include <Orbit/RlExt/image.h>
#include <Orbit/Lua/vector.h>
#include <Orbit/Lua/rect.h>
#include <Orbit/Lua/quad.h>
#include <Orbit/Lua/runtime.h>
#include <Orbit/RlExt/rl.h>

#include <raylib.h>
#include <raymath.h>
#include <rlgl.h>

extern "C" {
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

static constexpr const char *META = "imagebuf";

static int image_fill(lua_State *L) {
	Image *img  = static_cast<Image *>(luaL_checkudata(L, 1, META));
	Color *c = static_cast<Color *>(luaL_testudata(L, 2, "color"));

	ImageClearBackground(img, c ? *c : WHITE);

	return 0;
}

static int image_tostring(lua_State *L) {
	Image *img = static_cast<Image *>(luaL_checkudata(L, 1, META));

	std::stringstream ss;

	ss << META << '('
		<< img->width <<
		", " << img->height << ')';

	auto str = ss.str();

	lua_pushstring(L, str.c_str());

	return 1;
}

static int image_concat(lua_State *L) {
	std::string a = lua_tolstring(L, 1, nullptr);
	std::string b = lua_tolstring(L, 2, nullptr);

	lua_pushstring(L, (a + b).c_str());
	return 1;
}

static int image_make_silhouette(lua_State *L){ 
	Image *img = static_cast<Image *>(luaL_checkudata(L, 1, META));
	bool invert = lua_toboolean(L, 2);
	// *nimg = MakeSilhouette(img);

	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
	auto &shadero = runtime->shaders->silhouette;
	auto t = LoadTextureFromImage(*img);
	auto canvas = LoadRenderTexture(img->width, img->height);
	
	BeginTextureMode(canvas);
	
	BeginShaderMode(shadero.shader);
	shadero.prepare(t, invert, true);
	DrawTexture(t, 0, 0, WHITE);
	EndShaderMode();

	EndTextureMode();

	Image *nimg = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
	*nimg = LoadImageFromTexture(canvas.texture);

	UnloadTexture(t);
	UnloadRenderTexture(canvas);

	luaL_getmetatable(L, META);
	lua_setmetatable(L, -2);

	return 1; 
}

static int image_rect (lua_State *L2){
	Image *img = static_cast<Image *>(luaL_checkudata(L2, 1, META));
	
	auto *rect = static_cast<Orbit::Lua::Rect *>(lua_newuserdata(L2, sizeof(Orbit::Lua::Rect)));
	new (rect) Orbit::Lua::Rect(
		0, 0,
		(float)img->width,
		(float)img->height
	);

	luaL_getmetatable(L2, "rect");
	lua_setmetatable(L2, -2);

	return 1;
}

static Orbit::RlExt::CopyImageBufParams parse_copy_params(lua_State *L, int index) {
	luaL_checktype(L, index, LUA_TTABLE);

	auto params = Orbit::RlExt::CopyImageBufParams();	
	
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
		Image *i = static_cast<Image *>(luaL_checkudata(L, -1, META));
		params.mask = i;
	}
	lua_pop(L, 1);

	return params;
}

static void copy_pixels_rect_calc_sample_coords(
	Orbit::Lua::Rect const *src, 
	Orbit::Lua::Rect const *dst,
	float &init_s, float &init_t,
	float &inc_src_s, float &inc_src_t
)
{
	auto srcW = src->GetWidth();
	auto srcH = src->GetHeight();
	auto dstW = dst->GetWidth();
	auto dstH = dst->GetHeight();

	// Horizontal increment for sampling coordinates when the rasterizer iterates.
	inc_src_s = srcW / dstW;
	inc_src_t = srcH / dstH;

	// Half-texel offset so we sample the *center* of the pixels, not the edges.
	init_s = srcW / (dstW * 2) + src->_left;
	init_t = srcH / (dstH * 2) + src->_top;
}

static void copy_pixels_rect_clamp_dst(
	int &dst0,
	int &dst1,
	float &initTex,
	float incSrcTex,
	int dstImg)
{
	if (dst0 < 0)
	{
		initTex += -dst0 * incSrcTex;
		dst0 = 0;
	}

	dst1 = std::min(dst1, dstImg);
}

static int image_copy_pixels(lua_State *L) {
	int count = lua_gettop(L);
	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

	Image *dst = static_cast<Image *>(luaL_checkudata(L, 1, META));
	Image *src = nullptr;

	Image tmp = {0};

	if (src = static_cast<Image *>(luaL_testudata(L, 2, META)); src == nullptr) {
		tmp = LoadImageFromTexture(static_cast<RenderTexture2D *>(luaL_checkudata(L, 2, "image"))->texture);

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

		Orbit::RlExt::CopyImageBufParams params;
		if (lua_istable(L, 5)) params = parse_copy_params(L, 5);

		Orbit::RlExt::CopyImage_CPU(
			src, dst, srcRect, dstRect, params
		);
	}
	else if (
		(arg3Ptr = luaL_testudata(L, 3, "quad")) != nullptr &&
		(arg4Ptr = luaL_testudata(L, 4, "rect")) != nullptr
	) {
		// copy(dst, src, dstQuad, srcRect, {opt})

		auto *dstQuad = static_cast<Orbit::Lua::Quad *>(arg3Ptr);
		auto *srcRect = static_cast<Orbit::Lua::Rect *>(arg4Ptr);

		Orbit::RlExt::CopyImageBufParams params;
		if (lua_istable(L, 5)) params = parse_copy_params(L, 5);

		Orbit::RlExt::CopyImage_CPU(
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

		Orbit::RlExt::CopyImageBufParams params;
		if (lua_istable(L, 5)) params = parse_copy_params(L, 5);

		// Orbit::RlExt::CopyImage_GPU(
		// 	&runtime->shaders->invb_copy_pixels,
		// 	src,
		// 	dst,
		// 	srcRect,
		// 	reinterpret_cast<Orbit::Lua::Quad *>(&dstQuad),
		// 	params
		// );
	} 
	else if (
		(arg3Ptr = luaL_testudata(L, 3, "rect")) != nullptr
	) {
		// copy(dst, src, dstRect, {opt})

		auto *dstRect = static_cast<Orbit::Lua::Rect *>(arg3Ptr);
		auto srcRect = Orbit::Lua::Rect {0, 0, (float)src->width, (float)src->height};

		Orbit::RlExt::CopyImageBufParams params;
		if (lua_istable(L, 4)) params = parse_copy_params(L, 4);

		// Orbit::RlExt::CopyImage_GPU(
		// 	&runtime->shaders->copy_pixels,
		// 	src,
		// 	dst,
		// 	&srcRect,
		// 	dstRect,
		// 	params
		// );
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

		auto srcRect = Orbit::Lua::Rect {0, 0, (float)src->width, (float)src->height};

		Orbit::RlExt::CopyImageBufParams params;
		if (lua_istable(L, 4)) params = parse_copy_params(L, 4);

		// Orbit::RlExt::CopyImage_GPU(
		// 	&runtime->shaders->invb_copy_pixels,
		// 	src,
		// 	dst,
		// 	&srcRect,
		// 	reinterpret_cast<Orbit::Lua::Quad *>(&dstQuad),
		// 	params
		// );
	}
	else if (
		(arg3Ptr = luaL_testudata(L, 3, "quad")) != nullptr
	) {
		// copy(dst, src, dstRect, {opt})

		auto *dstQuad = static_cast<Orbit::Lua::Quad *>(arg3Ptr);
		auto srcRect = Orbit::Lua::Rect {0, 0, (float)src->width, (float)src->height};

		Orbit::RlExt::CopyImageBufParams params;
		if (lua_istable(L, 4)) params = parse_copy_params(L, 4);

		// Orbit::RlExt::CopyImage_GPU(
		// 	&runtime->shaders->invb_copy_pixels,
		// 	src,
		// 	dst,
		// 	&srcRect,
		// 	dstQuad,
		// 	params
		// );
	}
	else {
		// copy(dst, src, {opt})

		auto targetRect = Orbit::Lua::Rect {0, 0, (float)src->width, (float)src->height};

		Orbit::RlExt::CopyImageBufParams params;
		if (lua_istable(L, 3)) params = parse_copy_params(L, 3);

		// Orbit::RlExt::CopyImage_GPU(
		// 	&runtime->shaders->copy_pixels,
		// 	src,
		// 	dst,
		// 	&targetRect,
		// 	&targetRect,
		// 	params
		// );
	}

	if (tmp.data != nullptr) UnloadImage(tmp);

	return 0;
}

static int image_copy_pixels_rect_rect(lua_State *L) {
	int count = lua_gettop(L);
	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

	Image *dst = static_cast<Image *>(luaL_checkudata(L, 1, META));
	Image *src = static_cast<Image *>(luaL_checkudata(L, 2, META));

	auto *dstRect = static_cast<Orbit::Lua::Rect *>(luaL_checkudata(L, 3, "rect"));
	auto *srcRect = static_cast<Orbit::Lua::Rect *>(luaL_checkudata(L, 4, "rect"));

	Orbit::RlExt::CopyImageBufParams params;
	if (lua_istable(L, 5)) params = parse_copy_params(L, 5);

	// Orbit::RlExt::CopyImage_GPU(
	// 	&runtime->shaders->copy_pixels,
	// 	src,
	// 	dst,
	// 	srcRect,
	// 	dstRect,
	// 	params
	// );

	auto srcT = LoadTextureFromImage(*src);
	auto dstT = LoadTextureFromImage(*dst);
	Texture2D *mask = nullptr;
	auto canvas = LoadRenderTexture(dstT.width, dstT.height);

    if (params.mask) *mask = LoadTextureFromImage(*params.mask);
		
    BeginTextureMode(canvas);
    DrawTexture(dstT, 0, 0, WHITE);
    
    BeginShaderMode(runtime->shaders->copy_pixels.shader);
    runtime->shaders->copy_pixels.prepare(
        srcT, 
        dstT, 
        params.color != std::nullopt, 
        static_cast<int>(params.ink), 
        params.blend/255.0f,
        false,
        mask
    );
    DrawTexturePro(
        srcT, 
        Rectangle{srcRect->_left, srcRect->_top, srcRect->GetWidth(), srcRect->GetHeight()}, 
        Rectangle{dstRect->_left, dstRect->_top, dstRect->GetWidth(), dstRect->GetHeight()},
        Vector2{0, 0},
        0, 
        params.color.value_or(WHITE)
    );
    EndShaderMode();
    EndTextureMode();

    UnloadImage(*dst);
	*dst = LoadImageFromTexture(canvas.texture);
	ImageFlipVertical(dst);

	UnloadTexture(srcT);
	UnloadTexture(dstT);
	if (mask) UnloadTexture(*mask);
	UnloadRenderTexture(canvas);

	return 0;
}

static int image_get_pixel(lua_State *L) {
	Image *image = static_cast<Image *>(luaL_checkudata(L, 1, META));

	int x, y;

	if (void *ptr = luaL_testudata(L, 2, "point")) {
		auto *point = static_cast<Vector2 *>(ptr);

		x = static_cast<int>(point->x);
		y = static_cast<int>(point->y);
	} else {
		x = luaL_checkinteger(L, 2);
		y = luaL_checkinteger(L, 3);
	}

    // Validate bounds
    if (x < 0 || x >= image->width || y < 0 || y >= image->height) {
        auto *c = static_cast<Color*>(lua_newuserdata(L, sizeof(Color)));
		
		c->r = 255;
		c->g = 255;
		c->b = 255;
		c->a = 255;

		luaL_getmetatable(L, "color");
		lua_setmetatable(L, -2);

		return 1;
    }

    // Calculate the offset (assuming uncompressed, R8G8B8A8, 4 bytes per pixel)
    int bytesPerPixel = 4;

	switch (image->format) {
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8: bytesPerPixel = 4; break;
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8: bytesPerPixel = 3; break;
		case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE: bytesPerPixel = 1; break;
		default: return luaL_error(L, "Unsupported image format: %d", image->format); break;
	}

    unsigned char *data = (unsigned char *)image->data;
    int index = (y * image->width + x) * bytesPerPixel;

	auto *color = static_cast<Color*>(lua_newuserdata(L, sizeof(Color)));

	switch (image->format) {
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

	luaL_getmetatable(L, "color");
	lua_setmetatable(L, -2);

	return 1;
}

static int image_set_pixel(lua_State *L) {
	Image *image = static_cast<Image *>(luaL_checkudata(L, 1, META));

    int x;
    int y;
	Color *c;

	if (void *ptr = luaL_testudata(L, 2, "point")) {
		auto *point = static_cast<Vector2 *>(ptr);

		x = static_cast<int>(point->x);
		y = static_cast<int>(point->y);

		c = static_cast<Color *>(luaL_checkudata(L, 3, "color"));
	} else {
		x = luaL_checkinteger(L, 2);
		y = luaL_checkinteger(L, 3);

		c = static_cast<Color *>(luaL_checkudata(L, 4, "color"));
	}

    // Validate bounds
    if (x < 0 || x >= image->width || y < 0 || y >= image->height) {
        return 0;
    }

    // Calculate the offset (assuming uncompressed, R8G8B8A8, 4 bytes per pixel)
    int bytesPerPixel = 4;

	switch (image->format) {
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8: bytesPerPixel = 4; break;
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8: bytesPerPixel = 3; break;
		case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE: bytesPerPixel = 1; break;
		default: return luaL_error(L, "Unsupported image format: %d", image->format);
	}

    unsigned char *data = (unsigned char *)image->data;
    int index = (y * image->width + x) * bytesPerPixel;

	auto *color = static_cast<Color*>(lua_newuserdata(L, sizeof(Color)));

	data[index + 0] = c->r;
	data[index + 1] = c->g;
	data[index + 2] = c->b;
	data[index + 3] = c->a;

	return 0;
}

static int image_index(lua_State *L) {
	Image *img = static_cast<Image *>(luaL_checkudata(L, 1, META));
	const char *field = luaL_checkstring(L, 2);

	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
	
	if (std::strcmp(field, "width") == 0) lua_pushnumber(L, img->width);
	else if (std::strcmp(field, "height") == 0) lua_pushnumber(L, img->height);
	else if (std::strcmp(field, "clear") == 0) lua_pushcfunction(L, image_fill);
	else if (std::strcmp(field, "rect") == 0) image_rect(L);
	else if (std::strcmp(field, "copyPixels") == 0) {
		lua_pushlightuserdata(L, runtime);
		lua_pushcclosure(L, image_copy_pixels, 1);
	}
	else if (std::strcmp(field, "getPixel") == 0) lua_pushcfunction(L, image_get_pixel);
	else if (std::strcmp(field, "setPixel") == 0) lua_pushcfunction(L, image_set_pixel);
	else if (std::strcmp(field, "silhouette") == 0) {
		lua_pushlightuserdata(L, runtime);
		lua_pushcclosure(L, image_make_silhouette, 1);
	}
	else lua_pushnil(L);

	return 1;
}

static int image_eq(lua_State *L) {
	Image *a = static_cast<Image *>(luaL_checkudata(L, 1, META));
	Image *b = static_cast<Image *>(luaL_checkudata(L, 2, META));

	lua_pushboolean(L, a == b);

	return 1;
}

static int image_gc(lua_State *L) {
	Image *img = static_cast<Image *>(luaL_checkudata(L, 1, META));
	UnloadImage(*img);
	return 0;
}

inline static float cross2d(Vector2 a, Vector2 b) {
	return a.x * b.y - a.y *b.x;
};

inline static float lerp(float x, float y, float a) { return x + a * (y - x); };

inline static Vector2 invb(Vector2 p, Vector2 a, Vector2 k1, float k2, float k3, Vector2 k4, Vector2 k5) {
	float b = k3 - cross2d(k1, p - a);
	float c = cross2d(p - a, k4);
	float rad = std::sqrt(b * b + k2 * c);
	float v1 = -2.0f * c / (b + rad);
	Vector2 e1 = p - a - k5 * v1;
	float u1 = Vector2DotProduct(e1, e1) / Vector2DotProduct(k4 + k1 * v1, e1);
	float v2 = -2.0f * c / (b - rad);
	Vector2 e2 = p - a - k5 * v2;
	float u2 = Vector2DotProduct(e2, e2) / Vector2DotProduct(k4 + k1 * v2, e2);

	return std::max(std::abs(u1 - 0.5f), std::abs(v1 - 0.5f)) <= 0.5f ? Vector2{u1, v1} : Vector2{u2, v2};
};

#if AVX2
inline static auto dot2d_avx2(
	xsimd::batch<float> ax,
	xsimd::batch<float> ay,
	xsimd::batch<float> bx,
	xsimd::batch<float> by
) {
	return ax * bx + ay * by;
}

inline static auto cross2d_avx2(
	xsimd::batch<float> ax,
	xsimd::batch<float> ay,
	xsimd::batch<float> bx,
	xsimd::batch<float> by
) {
	return ax * by - ay * bx;
}

inline static auto lerp_avx2(
	xsimd::batch<float> x,
	xsimd::batch<float> y,
	xsimd::batch<float> a
) {
	return x + (a * (y - x));
} 

inline static auto single_blend(
	xsimd::batch<uint8_t> src_color,
	xsimd::batch<uint8_t> dst_color,
	xsimd::batch<float> blend,
	xsimd::batch<float> blend_inv
) {
	auto src_float = xsimd::batch_cast<float>(xsimd::batch<int>(src_color));
	auto dst_float = xsimd::batch_cast<float>(xsimd::batch<int>(dst_color));

	auto res_float = (src_float * blend) + (dst_float * blend_inv);

	auto res = xsimd::batch_cast<int>(res_float);

	return xsimd::batch<uint8_t>(res);
}

inline static auto blend_avx2(
	xsimd::batch<uint8_t> src,
	xsimd::batch<uint8_t> dst,
	xsimd::batch<float> blend
) {
	auto res = xsimd::batch<uint8_t>(xsimd::batch<uint32_t>(0xFF000000u));

	auto blend_inv = xsimd::broadcast(1.0f) - blend;

	xsimd::batch<uint8_t> b_mask = {
		0, 255, 255, 255,
		4, 255, 255, 255,
		8, 255, 255, 255,
		12, 255, 255, 255,
		0, 255, 255, 255,
		4, 255, 255, 255,
		8, 255, 255, 255,
		12, 255, 255, 255
	};

	auto src_blue = _mm256_shuffle_epi8(src, b_mask);
	auto dst_blue = _mm256_shuffle_epi8(dst, b_mask);

	auto res_blue = single_blend(src_blue, dst_blue, blend, blend_inv);

	xsimd::batch<uint8_t> b_inv_mask = {
		0, 255, 255, 255,
		4, 255, 255, 255,
		8, 255, 255, 255,
		12, 255, 255, 255,
		0, 255, 255, 255,
		4, 255, 255, 255,
		8, 255, 255, 255,
		12, 255, 255, 255
	};

	res = xsimd::bitwise_or(res, xsimd::batch<uint8_t>(_mm256_shuffle_epi8(res_blue, b_inv_mask)));


	xsimd::batch<uint8_t> g_mask = {
		1, 255, 255, 255,
		5, 255, 255, 255,
		9, 255, 255, 255,
		13, 255, 255, 255,
		1, 255, 255, 255,
		5, 255, 255, 255,
		9, 255, 255, 255,
		13, 255, 255, 255
	};

	auto src_gren = _mm256_shuffle_epi8(src, g_mask);
	auto dst_gren = _mm256_shuffle_epi8(dst, g_mask);

	auto res_green = single_blend(src_gren, dst_gren, blend, blend_inv);

	xsimd::batch<uint8_t> g_inv_mask = {
		255, 0, 255, 255,
		255, 4, 255, 255,
		255, 8, 255, 255,
		255, 12, 255, 255,
		255, 0, 255, 255,
		255, 4, 255, 255,
		255, 8, 255, 255,
		255, 12, 255, 255
	};

	res = xsimd::bitwise_or(res, xsimd::batch<uint8_t>(_mm256_shuffle_epi8(res_green, g_inv_mask)));


	xsimd::batch<uint8_t> r_mask = {
		2, 255, 255, 255,
		6, 255, 255, 255,
		10, 255, 255, 255,
		14, 255, 255, 255,
		2, 255, 255, 255,
		6, 255, 255, 255,
		10, 255, 255, 255,
		14, 255, 255, 255
	};

	auto scr_red = _mm256_shuffle_epi8(src, r_mask);
	auto dst_red = _mm256_shuffle_epi8(dst, r_mask);

	auto res_red = single_blend(scr_red, dst_red, blend, blend_inv);

	xsimd::batch<uint8_t> r_inv_mask = {
		255, 255, 0, 255,
		255, 255, 4, 255,
		255, 255, 8, 255,
		255, 255, 12, 255,
		255, 255, 0, 255,
		255, 255, 4, 255,
		255, 255, 8, 255,
		255, 255, 12, 255
	};

	return xsimd::bitwise_or(res, xsimd::batch<uint8_t>(_mm256_shuffle_epi8(res_red, r_inv_mask)));
}

/// @brief Solves the inverse-biliear equation, returning the UV coordinates.
/// @param px The X screen coordinate.
/// @param py The Y screen coordinate.
/// @param resx The X source image coordinate.
/// @param resy The Y source image coordinate.
inline static auto invb_avx2(
	xsimd::batch<float> px,
	xsimd::batch<float> py,
	Vector2 a,
	Vector2 k1,
	float k2,
	float k3,
	Vector2 k4,
	Vector2 k5,

	xsimd::batch<float> &resx,
	xsimd::batch<float> &resy
) {
	auto ax = xsimd::broadcast(a.x);
	auto ay = xsimd::broadcast(a.y);
	
	auto k1x = xsimd::broadcast(k1.x);
	auto k1y = xsimd::broadcast(k1.y);

	auto k2v = xsimd::broadcast(k2);
	auto k3v = xsimd::broadcast(k3);

	auto k4x = xsimd::broadcast(k4.x);
	auto k4y = xsimd::broadcast(k4.y);

	auto k5x = xsimd::broadcast(k5.x);
	auto k5y = xsimd::broadcast(k5.y);

	auto pmax = px - ax;
	auto pmay = py - ay;

	auto b = k3v - cross2d_avx2(k1x, k1y, pmax, pmay);
	auto c = cross2d_avx2(pmax, pmay, k4x, k4y);
	auto rad = xsimd::sqrt(b * b + k2v * c);

	auto v1 = -2.0f * c / (b + rad);
	auto e1x = pmax - k5x * v1;
	auto e1y = pmay - k5y * v1;
	auto u1 = dot2d_avx2(e1x, e1y, e1x, e1y) / dot2d_avx2(k4x + k1x * v1, k4y + k1y * v1, e1x, e1y);

	auto oob_mask = xsimd::bitwise_or(
		xsimd::bitwise_or(u1 < xsimd::broadcast(0.0f), u1 > xsimd::broadcast(1.0f)),
		xsimd::bitwise_or(v1 < xsimd::broadcast(0.0f), v1 > xsimd::broadcast(1.0f))
	);

	if (xsimd::none(oob_mask)) {
		resx = u1;
		resy = v1;
		return;
	}

	auto v2 = -2.0f * c / (b - rad);
	auto e2x = pmax - k5x * v2;
	auto e2y = pmay - k5y * v2;
	auto u2 = dot2d_avx2(e2x, e2y, e2x, e2y) / dot2d_avx2(k4x + k1x * v2, k4y + k1y * v2, e2x, e2y);

	resx = xsimd::select(oob_mask, u2, u1);
	resy = xsimd::select(oob_mask, v2, v1);
}
#endif

namespace Orbit::RlExt {

CopyImageBufParams::CopyImageBufParams() : 
    blend(1), 
    color(std::nullopt), 
    ink(CopyImageInk::None), 
    mask(nullptr) {}

CopyImageBufParams::CopyImageBufParams(
    float blend, 
    std::optional<Color> color, 
    CopyImageInk ink, 
    Image *mask
) : 
    blend(blend), 
    color(color), 
    ink(ink), 
    mask(mask) {}

bool QuadImageSampler::ScreenToUV(float x, float y, float &u, float &v) const {
	const Vector2 &A = quad.bottomleft;
	const Vector2 B = quad.bottomright - quad.bottomleft;
	const Vector2 C = quad.topleft - quad.bottomleft;
	const Vector2 D = quad.bottomleft - quad.bottomright + quad.topright - quad.topleft;
	
	Vector2 P = {x, y};
	Vector2 PA = P - A;
	
	// Newton-Raphson iteration for solving the bilinear equation
	u = 0.5f; v = 0.5f; // Initial guess
	
	for (int iter = 0; iter < 8; ++iter) {
		Vector2 f = B * u + C * v + D * (u * v) - PA;
		
		// Jacobian matrix
		float fx_u = B.x + D.x * v;
		float fx_v = C.x + D.x * u;
		float fy_u = B.y + D.y * v;
		float fy_v = C.y + D.y * u;
		
		float det = fx_u * fy_v - fx_v * fy_u;
		if (std::abs(det) < 1e-6f) return false;
		
		float du = (fy_v * f.x - fx_v * f.y) / det;
		float dv = (fx_u * f.y - fy_u * f.x) / det;
		
		u -= du;
		v -= dv;
		
		if (std::abs(du) < 1e-6f && std::abs(dv) < 1e-6f) break;
	}
	
	return (u >= 0.0f && u <= 1.0f && v >= 0.0f && v <= 1.0f);
}

void QuadImageSampler::ScreenToUVBatch(
	const float* screen_x, 
	const float* screen_y, 
	int count, 
	float* u_out, 
	float* v_out, 
	bool* valid_out
) const {
	// Precompute bilinear coefficients
	Vector2 A = quad.bottomleft;
	Vector2 B = quad.bottomright - quad.bottomleft;
	Vector2 C = quad.topleft - quad.bottomleft;
	Vector2 D = quad.bottomleft - quad.bottomright + quad.topright - quad.topleft;

	using simd_float = xsimd::simd_type<float>;
    using simd_int = xsimd::simd_type<int>;
    using simd_uint8 = xsimd::simd_type<uint8_t>;
	
	simd_float A_x = simd_float(A.x);
	simd_float A_y = simd_float(A.y);
	simd_float B_x = simd_float(B.x);
	simd_float B_y = simd_float(B.y);
	simd_float C_x = simd_float(C.x);
	simd_float C_y = simd_float(C.y);
	simd_float D_x = simd_float(D.x);
	simd_float D_y = simd_float(D.y);
	
	int simdCount = (count / simd_size) * simd_size;
	
	for (int i = 0; i < simdCount; i += simd_size) {
		simd_float sx = xsimd::load_unaligned(&screen_x[i]);
		simd_float sy = xsimd::load_unaligned(&screen_y[i]);
		
		simd_float PA_x = sx - A_x;
		simd_float PA_y = sy - A_y;
		
		// Initial guess
		simd_float u = simd_float(0.5f);
		simd_float v = simd_float(0.5f);
		
		// Newton-Raphson iterations (vectorized)
		for (int iter = 0; iter < 8; ++iter) {
			// f = B*u + C*v + D*u*v - PA
			simd_float f_x = B_x * u + C_x * v + D_x * u * v - PA_x;
			simd_float f_y = B_y * u + C_y * v + D_y * u * v - PA_y;
			
			// Jacobian elements
			simd_float fx_u = B_x + D_x * v;
			simd_float fx_v = C_x + D_x * u;
			simd_float fy_u = B_y + D_y * v;
			simd_float fy_v = C_y + D_y * u;
			
			simd_float det = fx_u * fy_v - fx_v * fy_u;
			auto valid_det = xsimd::abs(det) >= simd_float(1e-6f);
			
			simd_float du = xsimd::select(valid_det, 
				(fy_v * f_x - fx_v * f_y) / det, simd_float(0.0f));
			simd_float dv = xsimd::select(valid_det,
				(fx_u * f_y - fy_u * f_x) / det, simd_float(0.0f));
			
			u = u - du;
			v = v - dv;
		}
		
		// Check bounds and store results
		auto valid = (u >= simd_float(0.0f)) & (u <= simd_float(1.0f)) & 
					(v >= simd_float(0.0f)) & (v <= simd_float(1.0f));
		
		xsimd::store_unaligned(&u_out[i], u);
		xsimd::store_unaligned(&v_out[i], v);
		
		// Store validity mask
		alignas(32) float valid_vals[simd_size];
		xsimd::store_aligned(valid_vals, xsimd::select(valid, simd_float(1.0f), simd_float(0.0f)));
		for (int j = 0; j < simd_size && (i + j) < count; ++j) {
			valid_out[i + j] = valid_vals[j] > 0.5f;
		}
	}
	
	// Process remaining elements
	for (int i = simdCount; i < count; ++i) {
		valid_out[i] = ScreenToUV(screen_x[i], screen_y[i], u_out[i], v_out[i]);
	}
}

void QuadImageSampler::SamplePixel(float u, float v, Color *pixel) const {
	// Convert UV to image coordinates
	float fx = u * (image.width - 1);
	float fy = v * (image.height - 1);
	
	int x0 = (int)std::floor(fx);
	int y0 = (int)std::floor(fy);
	int x1 = std::min(x0 + 1, image.width - 1);
	int y1 = std::min(y0 + 1, image.height - 1);
	
	float wx = fx - x0;
	float wy = fy - y0;
	
	// Clamp coordinates
	x0 = std::max(0, x0);
	y0 = std::max(0, y0);
	
	// Sample four corners
	const uint8_t* p00 = &reinterpret_cast<uint8_t *>(image.data)[(y0 * image.width + x0) * channels];
	const uint8_t* p10 = &reinterpret_cast<uint8_t *>(image.data)[(y0 * image.width + x1) * channels];
	const uint8_t* p01 = &reinterpret_cast<uint8_t *>(image.data)[(y1 * image.width + x0) * channels];
	const uint8_t* p11 = &reinterpret_cast<uint8_t *>(image.data)[(y1 * image.width + x1) * channels];
	
	// Bilinear interpolation weights
	float w00 = (1.0f - wx) * (1.0f - wy);
	float w10 = wx * (1.0f - wy);
	float w01 = (1.0f - wx) * wy;
	float w11 = wx * wy;
	
	// Interpolate and convert back to uint8 (avoiding float normalization)
	if (channels >= 1) {
		float r = w00 * p00[0] + w10 * p10[0] + w01 * p01[0] + w11 * p11[0];
		pixel->r = (uint8_t)std::round(std::clamp(r, 0.0f, 255.0f));
	} else {
		pixel->r = 0;
	}
	
	if (channels >= 2) {
		float g = w00 * p00[1] + w10 * p10[1] + w01 * p01[1] + w11 * p11[1];
		pixel->g = (uint8_t)std::round(std::clamp(g, 0.0f, 255.0f));
	} else {
		pixel->g = channels >= 1 ? pixel->r : 0;
	}
	
	if (channels >= 3) {
		float b = w00 * p00[2] + w10 * p10[2] + w01 * p01[2] + w11 * p11[2];
		pixel->b = (uint8_t)std::round(std::clamp(b, 0.0f, 255.0f));
	} else {
		pixel->b = channels >= 1 ? pixel->r : 0;
	}
	
	if (channels >= 4) {
		float a = w00 * p00[3] + w10 * p10[3] + w01 * p01[3] + w11 * p11[3];
		pixel->a = (uint8_t)std::round(std::clamp(a, 0.0f, 255.0f));
	} else {
		pixel->a = 255; // Fully opaque by default
	}
}

void QuadImageSampler::SampleBatch(float const *x, float const *y, int count, Color *pixels) const {
	int simdCount = (count / simd_size) * simd_size;
	int remainder = count - simdCount;

	using simd_float = xsimd::simd_type<float>;
    using simd_int = xsimd::simd_type<int>;
    using simd_uint8 = xsimd::simd_type<uint8_t>;
	
	// Process SIMD batches
	for (int i = 0; i < simdCount; i += simd_size) {
		simd_float sx = xsimd::load_unaligned(&x[i]);
		simd_float sy = xsimd::load_unaligned(&y[i]);
		
		// This is a simplified linear approximation for demonstration
		simd_float u = (sx - quad.bottomleft.x) / (quad.bottomright.x - quad.bottomleft.x);
		simd_float v = (sy - quad.bottomleft.y) / (quad.topleft.y - quad.bottomleft.y);
		
		// Clamp UV coordinates
		u = xsimd::clip(u, simd_float(0.0f), simd_float(1.0f));
		v = xsimd::clip(v, simd_float(0.0f), simd_float(1.0f));
		
		// Convert to image coordinates
		simd_float fx = u * simd_float(image.width - 1);
		simd_float fy = v * simd_float(image.height - 1);
		
		// Floor to get integer coordinates
		simd_int x0 = xsimd::to_int(xsimd::floor(fx));
		simd_int y0 = xsimd::to_int(xsimd::floor(fy));
		
		// Calculate interpolation weights
		simd_float wx = fx - xsimd::to_float(x0);
		simd_float wy = fy - xsimd::to_float(y0);
		
		// For each pixel in the batch, perform bilinear sampling
		alignas(32) float u_vals[simd_size], v_vals[simd_size];
		alignas(32) float wx_vals[simd_size], wy_vals[simd_size];
		alignas(32) int x0_vals[simd_size], y0_vals[simd_size];
		
		xsimd::store_aligned(u_vals, u);
		xsimd::store_aligned(v_vals, v);
		xsimd::store_aligned(wx_vals, wx);
		xsimd::store_aligned(wy_vals, wy);
		xsimd::store_aligned(x0_vals, x0);
		xsimd::store_aligned(y0_vals, y0);
		
		for (int j = 0; j < simd_size; ++j) {
			int idx = i + j;
			if (idx >= count) break;
			
			int px0 = std::max(0, std::min(x0_vals[j], image.width - 1));
			int py0 = std::max(0, std::min(y0_vals[j], image.height - 1));
			int px1 = std::min(px0 + 1, image.width - 1);
			int py1 = std::min(py0 + 1, image.height - 1);
			
			float w = wx_vals[j];
			float h = wy_vals[j];
			
			const uint8_t* p00 = &reinterpret_cast<uint8_t *>(image.data)[(py0 * image.width + px0) * channels];
			const uint8_t* p10 = &reinterpret_cast<uint8_t *>(image.data)[(py0 * image.width + px1) * channels];
			const uint8_t* p01 = &reinterpret_cast<uint8_t *>(image.data)[(py1 * image.width + px0) * channels];
			const uint8_t* p11 = &reinterpret_cast<uint8_t *>(image.data)[(py1 * image.width + px1) * channels];
			
			float w00 = (1.0f - w) * (1.0f - h);
			float w10 = w * (1.0f - h);
			float w01 = (1.0f - w) * h;
			float w11 = w * h;

			// Interpolate and convert back to uint8 (avoiding float normalization)
			if (channels >= 1) {
				float r = w00 * p00[0] + w10 * p10[0] + w01 * p01[0] + w11 * p11[0];
				pixels[idx].r = (uint8_t)std::round(std::clamp(r, 0.0f, 255.0f));
			} else {
				pixels[idx].r = 0;
			}
			
			if (channels >= 2) {
				float g = w00 * p00[1] + w10 * p10[1] + w01 * p01[1] + w11 * p11[1];
				pixels[idx].g = (uint8_t)std::round(std::clamp(g, 0.0f, 255.0f));
			} else {
				pixels[idx].g = channels >= 1 ? pixels[idx].r : 0;
			}
			
			if (channels >= 3) {
				float b = w00 * p00[2] + w10 * p10[2] + w01 * p01[2] + w11 * p11[2];
				pixels[idx].b = (uint8_t)std::round(std::clamp(b, 0.0f, 255.0f));
			} else {
				pixels[idx].b = channels >= 1 ? pixels[idx].r : 0;
			}
			
			if (channels >= 4) {
				float a = w00 * p00[3] + w10 * p10[3] + w01 * p01[3] + w11 * p11[3];
				pixels[idx].a = (uint8_t)std::round(std::clamp(a, 0.0f, 255.0f));
			} else {
				pixels[idx].a = 255; // Fully opaque by default
			}
		}
	}

	// Process remaining elements
	for (int i = simdCount; i < count; ++i) {
		float u, v;
		if (ScreenToUV(x[i], y[i], u, v)) {
			SamplePixel(u, v, &pixels[i]);
		} else {
			// Outside quad bounds - fill with transparent/black
			for (int c = 0; c < channels; ++c) {
				pixels[i].r = 0.0f;
				pixels[i].g = 0.0f;
				pixels[i].b = 0.0f;
				pixels[i].a = 0.0f;
			}
		}
	}
}

void CopyImage_CPU(
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Rect *to, 
	const CopyImageBufParams &params
) {
	int dst_l = to->_left, dst_t = to->_top, dst_r = to->_right, dst_b = to->_bottom;

	float init_s, init_t, inc_src_s, inc_src_t;

	copy_pixels_rect_calc_sample_coords(from, to, init_s, init_t, inc_src_s, inc_src_t);

	copy_pixels_rect_clamp_dst(dst_l, dst_r, init_s, inc_src_s, dst->width);
	copy_pixels_rect_clamp_dst(dst_t, dst_b, init_t, inc_src_t, dst->height);

	uint8_t *target = reinterpret_cast<uint8_t *>(dst->data);

	int src_channels = 4, dst_channels = 4;

	switch (src->format) {
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8: src_channels = 3;
	}

	switch (dst->format) {
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8: dst_channels = 3;
	}

	auto t = init_t;
	for (auto y = dst_t; y < dst_b; y++, t += inc_src_t) {
		auto img_row = (int)(t * src->height) * src->width;

		auto s = init_s;

		for (auto x = dst_l; x < dst_r; x++, s += inc_src_s) {
			auto dst_pos = dst->width * y + x;

			if (params.mask != nullptr) {
				auto mask_x = (int)(s * src->width);
				auto mask_y = (int)(t * src->height);

				if (mask_x < 0 || mask_x >= params.mask->width || mask_y < 0 || mask_y >= params.mask->height) continue;

				auto *mask = reinterpret_cast<uint32_t *>(params.mask->data);

				if ((mask[params.mask->width * mask_y + mask_x] & 0xFFFFFF) != 0) continue;
			}

			int src_x = (int)s;
			int src_y = (int)t;

			src_x = std::max(0, std::min(src_x, src->width - 1));
			src_y = std::max(0, std::min(src_y, src->height - 1));

			Color color = Sample(src, src_x + src_y * src->width);

			if (params.ink == CopyImageInk::TransparentBackground && color.r == 255 && color.g == 255 && color.b == 255) {
				continue;
			}
	
			Color fgc = params.color.value_or(Color{ 0, 0, 0, 255 });
	
			uint8_t r = std::min(0XFF, (int)color.r + (int)fgc.r);
			uint8_t g = std::min(0XFF, (int)color.g + (int)fgc.g);
			uint8_t b = std::min(0XFF, (int)color.b + (int)fgc.b);
	
			if (params.blend != 1) {
				Color dc = Sample(dst, dst_pos);
			
				Orbit::Lua::Vector bsrc = { (float)r, (float)g, (float)b, 0 };
				Orbit::Lua::Vector dsrc = { (float)dc.r, (float)dc.g, (float)dc.b, 0 };

				auto final = bsrc * params.blend + dsrc * (1 - params.blend);

				r = (uint8_t)final._x;
				g = (uint8_t)final._y;
				b = (uint8_t)final._z;
			}
			else if (params.ink == CopyImageInk::Darkest) {
				Color dc = Sample(dst, dst_pos);

				r = std::min(r, dc.r);
				g = std::min(g, dc.g);
				b = std::min(b, dc.b);
			}

			target[dst_pos * dst_channels + 0] = r;
			target[dst_pos * dst_channels + 1] = g;
			target[dst_pos * dst_channels + 2] = b;
			if (dst_channels > 3) target[dst_pos * dst_channels + 3] = fgc.a;
		}
	}
}

void CopyImage_CPU(
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Quad *to, 
	const CopyImageBufParams &params
) {
	auto bounds_tl = Vector2Min(to->topleft, Vector2Min(to->topright, Vector2Min(to->bottomleft, to->bottomright)));
	auto bounds_br = Vector2Max(to->topleft, Vector2Max(to->topright, Vector2Max(to->bottomleft, to->bottomright)));

	auto bounds_l = std::clamp((int)bounds_tl.x, 0, dst->width);
	auto bounds_t = std::clamp((int)bounds_tl.y, 0, dst->height);
	auto bounds_r = std::clamp((int)std::ceil(bounds_br.x), 0, dst->width);
	auto bounds_b = std::clamp((int)std::ceil(bounds_br.y), 0, dst->height);

	auto * source = reinterpret_cast<uint8_t *>(src->data);
	auto * target = reinterpret_cast<uint8_t *>(dst->data);

	int src_channels = 4, dst_channels = 4;

	switch (src->format) {
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8: src_channels = 3;
	}

	switch (dst->format) {
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8: dst_channels = 3;
	}

	auto a = to->topleft;
	auto b = to->topright;
	auto c = to->bottomright;
	auto d = to->bottomleft;

	Vector2 k1 = c - d + a - b;
	float k2 = -4.0f * cross2d(k1, d - a);
	float k3 = cross2d(a - d, b - a);
	Vector2 k4 = b - a;
	Vector2 k5 = d - a;

	auto fgc = params.color.value_or(Color{0,0,0,0});

#if AVX2
	auto fg_vec = xsimd::broadcast_as<uint8_t>(* (uint32_t *) (&fgc));

	xsimd::batch<int> pos_mask = { 0, 1, 2, 3, 4, 5, 6, 7 };
	auto width_vec = xsimd::broadcast(bounds_r);

	for (int y = bounds_t; y < bounds_b; y++) {
		auto y_vec = xsimd::broadcast(y + 0.5f);

		for (int x = bounds_l; x < bounds_r; x+=8) {
			auto pos = pos_mask + xsimd::broadcast(x);
			auto write_mask = width_vec > pos;
			// write_mask = xsimd::gt(width_vec, pos);

			auto x_vec = xsimd::batch_cast<float>(pos) + xsimd::broadcast(0.5f);

			xsimd::batch<float> s, t;
			invb_avx2(x_vec, y_vec, a, k1, k2, k3, k4, k5, s, t);

			auto half_vec = xsimd::broadcast(0.5f);
			auto neg_mask = xsimd::broadcast(-0.0f);

			write_mask = xsimd::bitwise_and(
				write_mask,
				xsimd::batch_bool_cast<int>(xsimd::bitwise_and(
					xsimd::bitwise_andnot(neg_mask, s - half_vec) < half_vec,
					xsimd::bitwise_andnot(neg_mask, t - half_vec) < half_vec
				))
			);

			if (xsimd::none(write_mask)) continue;

			s = lerp_avx2(xsimd::broadcast(from->_left/src->width), xsimd::broadcast(from->_right/src->width), s);
			t = lerp_avx2(xsimd::broadcast(from->_top/src->height), xsimd::broadcast(from->_bottom/src->height), t);
		
			auto img_x = xsimd::to_int(s * xsimd::broadcast((float)src->width));
			auto img_y = xsimd::to_int(t * xsimd::broadcast((float)src->height));

			auto valid_x = xsimd::bitwise_and(img_x >= xsimd::broadcast(0), img_x < xsimd::broadcast(src->width));
			auto valid_y = xsimd::bitwise_and(img_y >= xsimd::broadcast(0), img_y < xsimd::broadcast(src->height));
			auto read_mask = xsimd::bitwise_and(xsimd::bitwise_and(valid_x, valid_y), write_mask);

			auto img_pos = (img_y * src->width) + img_x;

			xsimd::batch<int> color;

			// SAMPLING FROM SRC
			{
				alignas(32) Color color_array[8];
	
				alignas(32) int positions[8];
				alignas(32) bool masks[8];
	
				img_pos.store_aligned(positions);
				read_mask.store_aligned(masks);
	
				// Sample pixels directly
				for (int i = 0; i < 8; i++) {
					color_array[i] = masks[i] ? Sample(src, positions[i]) : WHITE;
				}
	
				color = xsimd::load_aligned(reinterpret_cast<int*>(color_array));
			}

			//

			auto dst_pos = x + y * dst->width;

			if (params.blend != 1) {
				auto blend_vec = xsimd::broadcast(params.blend);
				
				auto dst_color = xsimd::batch<int>(_mm256_maskload_epi32(reinterpret_cast<int *>(dst->data) + dst_pos, write_mask));

				auto res = blend_avx2(xsimd::batch<uint8_t>(color), xsimd::batch<uint8_t>(dst_color), blend_vec);

				color = xsimd::batch<int>(res);
			}

			if (dst_channels == 3) {
				// 24-bit RGB - need to write individual pixels to avoid overwriting adjacent pixels
				alignas(32) uint32_t color_array[8];
				alignas(32) bool mask_array[8];
				
				color.store_aligned(reinterpret_cast<int*>(color_array));
				write_mask.store_aligned(mask_array);
				
				for (int i = 0; i < 8; i++) {
					if (mask_array[i] && (x + i) < bounds_r) {
						int pixel_pos = (x + i) + y * dst->width;
						int byte_pos = pixel_pos * 3;
						
						uint32_t pixel_color = color_array[i];
						target[byte_pos + 0] = (pixel_color >> 0) & 0xFF;   // R
						target[byte_pos + 1] = (pixel_color >> 8) & 0xFF;   // G
						target[byte_pos + 2] = (pixel_color >> 16) & 0xFF;  // B
						// Skip alpha channel for RGB format
					}
				}
			} else {
				_mm256_maskstore_epi32(reinterpret_cast<int *>(dst->data) + dst_pos, write_mask, color);
			}
		}
	}
#else
	for (int y = bounds_t; y < bounds_b; y++) {
		for (int x = bounds_l; x < bounds_r; x++) {
			auto p = Vector2{ x + 0.5f, y + 0.5f };
			auto st = invb(p, a, k1, k2, k3, k4, k5);

			if (std::max(std::abs(st.x - 0.5f), std::abs(st.y - 0.5f)) < 0.5f) {
				st.x = lerp(from->_left/src->width, from->_right/src->width, st.x);
				st.y = lerp(from->_top/src->height, from->_bottom/src->height, st.y);

				auto dst_pos = x + y * dst->width;
				auto src_row = (int)(st.y * src->height) * src->width;

				auto color = (st.x < 0 || st.y < 0 || st.x >= 1 || st.y >= 1) 
					? WHITE 
					: Sample(src, (int)(st.x*src->width + src_row));

				if (params.ink == CopyImageInk::TransparentBackground && ((* (uint32_t *) &color) == 0xFFFFFF)) continue;

				

				uint8_t r = std::min(0xFF, color.r + fgc.r);
				uint8_t g = std::min(0xFF, color.g + fgc.g);
				uint8_t b = std::min(0xFF, color.b + fgc.b);

				if (params.blend != 1) {
					auto dst_color = Sample(dst, dst_pos);
						
					Orbit::Lua::Vector blend_src = { (float)r, (float)g, (float)b, 0 };
					Orbit::Lua::Vector blend_dst = { (float)dst_color.r, (float)dst_color.g, (float)dst_color.b, 0 };

					auto blended = blend_src * params.blend + blend_dst * (1 - params.blend);

					r = (int)blended._x;
					g = (int)blended._y;
					b = (int)blended._z;
				} else if (params.ink == CopyImageInk::Darkest) {
					auto dst_color = Sample(dst, dst_pos);

					r = std::min(r, dst_color.r);
					g = std::min(g, dst_color.g);
					b = std::min(b, dst_color.b);
				}

				target[dst_pos * dst_channels + 0] = r;
				target[dst_pos * dst_channels + 1] = g;
				target[dst_pos * dst_channels + 2] = b;
			}
		}
	}
#endif

}

};

namespace Orbit::Lua {

void LuaRuntime::_register_imagebuf() {

	luaL_newmetatable(L, META);

	lua_pushcfunction(L, image_tostring);
	lua_setfield(L, -2, "__tostring");

	lua_pushcfunction(L, image_concat);
	lua_setfield(L, -2, "__concat");

	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, image_index, 1);
	lua_setfield(L, -2, "__index");

	lua_pushcfunction(L, image_eq);
	lua_setfield(L, -2, "__eq");

	lua_pushcfunction(L, image_gc);
	lua_setfield(L, -2, "__gc");

    lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, image_make_silhouette, 1);
	lua_setglobal(L, "silhouette");

	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, image_copy_pixels, 1);
	lua_setglobal(L, "copyPixels");

	lua_pop(L, 1);

}

};
