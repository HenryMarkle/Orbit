#include <optional>
#include <sstream>
#include <cstring>
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
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

#define META "image"

// Image MakeSilhouette(const Image *src) {
// 	if (src->format != PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 && 
//         src->format != PIXELFORMAT_UNCOMPRESSED_R8G8B8) {
//         throw std::runtime_error("unsupported image format");
//     }
    
//     Image silhouette = ImageCopy(*src);
//     const int length = silhouette.width * silhouette.height;
    
//     if (src->format == PIXELFORMAT_UNCOMPRESSED_R8G8B8A8) {
//         using batch_type = xsimd::batch<uint32_t>;
//         constexpr size_t batch_size = batch_type::size;
//         const uint32_t white_pixel = 0xFFFFFFFF;
//         auto white_batch = xsimd::broadcast<uint32_t>(white_pixel);
//         const uint32_t black_pixel = 0xFF000000;
//         auto black_batch = xsimd::broadcast<uint32_t>(black_pixel);
//         uint32_t *pixel_data = reinterpret_cast<uint32_t *>(silhouette.data);
        
//         size_t i = 0;
//         for (; i + batch_size <= static_cast<size_t>(length); i += batch_size) {
//             auto pixel_batch = xsimd::load_unaligned(&pixel_data[i]);
//             auto is_white_mask = xsimd::eq(pixel_batch, white_batch);
//             auto res_batch = xsimd::select(is_white_mask, white_batch, black_batch);
//             xsimd::store_unaligned(&pixel_data[i], res_batch);
//         }
//         for (; i < static_cast<size_t>(length); ++i) {
//             if (pixel_data[i] != white_pixel) pixel_data[i] = black_pixel;
//         }
//     } else {
//         using batch_type = xsimd::batch<uint8_t>;
//         constexpr size_t batch_size = batch_type::size;
//         const uint8_t white_component = 255;
//         const uint8_t black_component = 0;
//         auto white_batch = xsimd::broadcast<uint8_t>(white_component);
//         auto black_batch = xsimd::broadcast<uint8_t>(black_component);
//         uint8_t *pixel_data = reinterpret_cast<uint8_t *>(silhouette.data);
        
//         size_t total_bytes = length * 3;
//         size_t i = 0;
        
//         for (; i + batch_size <= total_bytes; i += batch_size) {
//             auto pixel_batch = xsimd::load_unaligned(&pixel_data[i]);
//             auto is_white_mask = xsimd::eq(pixel_batch, white_batch);
//             auto res_batch = xsimd::select(is_white_mask, white_batch, black_batch);
//             xsimd::store_unaligned(&pixel_data[i], res_batch);
//         }
        
//         size_t remaining_pixels_start = (i / 3) * 3;
//         for (size_t pixel_idx = remaining_pixels_start / 3; pixel_idx < static_cast<size_t>(length); ++pixel_idx) {
//             size_t base_idx = pixel_idx * 3;
//             uint8_t r = pixel_data[base_idx];
//             uint8_t g = pixel_data[base_idx + 1];
//             uint8_t b = pixel_data[base_idx + 2];
            
//             if (r == 255 && g == 255 && b == 255) {
//                 // Keep white pixel as is
//                 pixel_data[base_idx] = 255;
//                 pixel_data[base_idx + 1] = 255;
//                 pixel_data[base_idx + 2] = 255;
//             } else {
//                 // Convert to black
//                 pixel_data[base_idx] = 0;
//                 pixel_data[base_idx + 1] = 0;
//                 pixel_data[base_idx + 2] = 0;
//             }
//         }
//     }
    
//     return silhouette;
// }

int image_fill(lua_State *L) {
	Image *img  = static_cast<Image *>(luaL_checkudata(L, 1, "image"));
	Color *c = static_cast<Color *>(luaL_testudata(L, 2, "color"));

	ImageClearBackground(img, c ? *c : WHITE);

	return 0;
}

int image_tostring(lua_State *L) {
	Image *img = static_cast<Image *>(luaL_checkudata(L, 1, META));

	std::stringstream ss;

	ss << META << '('
		<< img->width <<
		", " << img->height << ')';

	auto str = ss.str();

	lua_pushstring(L, str.c_str());

	return 1;
}


int image_make_silhouette(lua_State *L){ 
	Image *img = static_cast<Image *>(luaL_checkudata(L, 1, "image"));
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

	luaL_getmetatable(L, "image");
	lua_setmetatable(L, -2);

	return 1; 
}

Orbit::RlExt::CopyImageParams parse_copy_params(lua_State *L, int index) {
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
		Color *c = static_cast<Color *>(luaL_checkudata(L, -1, "color"));
		if (c) params.color = *c;
	}
	lua_pop(L, 1);
	
	lua_getfield(L, index, "mask");
	if (!lua_isnil(L, -1)) {
		Image *i = static_cast<Image *>(luaL_checkudata(L, -1, "image"));
		params.mask = i;
	}
	lua_pop(L, 1);

	return params;
}

int image_copy_pixels(lua_State *L) {
	int count = lua_gettop(L);

	Image *src = static_cast<Image *>(luaL_checkudata(L, 1, "image"));
	Image *dst = static_cast<Image *>(luaL_checkudata(L, 2, "image"));

	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

	switch (count) {
		case 2: {
            auto srcT = LoadTextureFromImage(*src);
            auto dstT = LoadTextureFromImage(*dst);
            Texture2D *mask = nullptr;
            auto canvas = LoadRenderTexture(dstT.width, dstT.height);

			BeginTextureMode(canvas);
			DrawTexture(dstT, 0, 0, WHITE);
			DrawTexture(srcT, 0, 0, WHITE);
			EndTextureMode();

            UnloadImage(*dst);
            *dst = LoadImageFromTexture(canvas.texture);
            ImageFlipVertical(dst);

            UnloadTexture(srcT);
            UnloadTexture(dstT);
            if (mask) UnloadTexture(*mask);
            UnloadRenderTexture(canvas);
		} 
		break;

		case 3: {
			if (lua_istable(L, 3)) {
				// copy(src, dst, {opt})
		
				Orbit::RlExt::CopyImageParams params;
				if (lua_istable(L, 3)) params = parse_copy_params(L, 3);
		
                Orbit::Lua::Rect rect = {0, 0, (float)src->width, (float)src->height};

                Orbit::RlExt::CopyImage_GPU(
                    &runtime->shaders->copy_pixels,
                    src,
                    dst,
                    &rect,
                    &rect,
                    params
                );
		
				return 0;
			}
		}
		break;

		default: {
			if (luaL_testudata(L, 3, "rect")) {
				auto *srcR = *static_cast<Orbit::Lua::Rect **>(luaL_checkudata(L, 3, "rect"));
				void *dstPtr = nullptr;
			
				if ((dstPtr = luaL_testudata(L, 4, "rect")) != nullptr) {
					auto *dstR = *static_cast<Orbit::Lua::Rect **>(luaL_checkudata(L, 4, "rect"));

					Orbit::RlExt::CopyImageParams params;
					if (lua_istable(L, 5)) params = parse_copy_params(L, 5);

					Orbit::RlExt::CopyImage_GPU(
                        &runtime->shaders->copy_pixels,
                        src,
                        dst,
                        srcR,
                        dstR,
                        params
                    );
			
				} else if ((dstPtr = luaL_testudata(L, 4, "quad")) != nullptr) {
					auto *dstR = *static_cast<Orbit::Lua::Quad **>(luaL_checkudata(L, 4, "quad"));

					Orbit::RlExt::CopyImageParams params;
					if (lua_istable(L, 5)) params = parse_copy_params(L, 5);

					Orbit::RlExt::CopyImage_GPU(
                        &runtime->shaders->invb_copy_pixels,
                        src,
                        dst,
                        srcR,
                        dstR,
                        params
                    );
					
				} else if (lua_istable(L, 4)) {
					// copy(src, dst, rect/quad, {opt})
					
					Orbit::RlExt::CopyImageParams params;
					params = parse_copy_params(L, 4);

					if ((dstPtr = luaL_testudata(L, 4, "rect")) != nullptr) {
						auto *dstR = *static_cast<Orbit::Lua::Rect **>(luaL_checkudata(L, 4, "rect"));
						auto srcRect = Orbit::Lua::Rect{0, 0, (float)src->width, (float)src->height};
						
						Orbit::RlExt::CopyImage_GPU(
							&runtime->shaders->copy_pixels,
							src,
							dst,
							&srcRect,
							dstR,
							params
						);
					}
					else if ((dstPtr = luaL_testudata(L, 4, "quad")) != nullptr) {
						auto *dstR = *static_cast<Orbit::Lua::Quad **>(luaL_checkudata(L, 4, "quad"));
						auto srcRect = Orbit::Lua::Rect{0, 0, (float)src->width, (float)src->height};
						
						Orbit::RlExt::CopyImage_GPU(
							&runtime->shaders->invb_copy_pixels,
							src,
							dst,
							&srcRect,
							dstR,
							params
						);
					}
			
				}
			}
		}
		break;
	}

	return 0;
}


int image_index(lua_State *L) {
	Image *img = static_cast<Image *>(luaL_checkudata(L, 1, META));
	const char *field = luaL_checkstring(L, 2);

	
	if (std::strcmp(field, "width") == 0) lua_pushnumber(L, img->width);
	else if (std::strcmp(field, "height") == 0) lua_pushnumber(L, img->height);
	else if (std::strcmp(field, "fill") == 0) lua_pushcfunction(L, image_fill);
	else if (!std::strcmp(field, "copy") || !std::strcmp(field, "copyPixels")) lua_pushcfunction(L, image_copy_pixels);
	else if (std::strcmp(field, "silhouette") == 0) lua_pushcfunction(L, image_make_silhouette);
	else lua_pushnil(L);

	return 1;
}

int image_eq(lua_State *L) {
	Image *a = static_cast<Image *>(luaL_checkudata(L, 1, META));
	Image *b = static_cast<Image *>(luaL_checkudata(L, 2, META));

	lua_pushboolean(L, a == b);

	return 1;
}

int image_gc(lua_State *L) {
	Image *img = static_cast<Image *>(luaL_checkudata(L, 1, META));
	UnloadImage(*img);
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
    Image *mask
) : 
    blend(blend), 
    color(color), 
    ink(ink), 
    mask(mask) {}


void CopyImage_GPU(
	const Orbit::CopyPixelsShader *shader, 
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Rect *to, 
	const CopyImageParams &params
) {
    auto srcT = LoadTextureFromImage(*src);
	auto dstT = LoadTextureFromImage(*dst);
	Texture2D *mask = nullptr;
	auto canvas = LoadRenderTexture(dstT.width, dstT.height);

    if (params.mask) *mask = LoadTextureFromImage(*params.mask);
		
    BeginTextureMode(canvas);
    DrawTexture(dstT, 0, 0, WHITE);
    
    BeginShaderMode(shader->shader);
    shader->prepare(
        srcT, 
        dstT, 
        params.color != std::nullopt, 
        static_cast<int>(params.ink), 
        params.blend,
        false,
        mask
    );
    DrawTexturePro(
        srcT, 
        Rectangle{from->_left, from->_top, from->width(), from->height()}, 
        Rectangle{to->_left, to->_top, to->width(), to->height()},
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
}

void CopyImage_GPU(
	const Orbit::InvbCopyPixelsShader *shader, 
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Quad *to, 
	const CopyImageParams &params
) {
	auto srcT = LoadTextureFromImage(*src);
	auto dstT = LoadTextureFromImage(*dst);
	Texture2D *mask = nullptr;
	auto canvas = LoadRenderTexture(dstT.width, dstT.height);
	auto srcRect = Rectangle{from->_left, from->_top, from->width(), from->height()};

    if (params.mask) *mask = LoadTextureFromImage(*params.mask);
		
    BeginTextureMode(canvas);
    DrawTexture(dstT, 0, 0, WHITE);
    
    BeginShaderMode(shader->shader);
    shader->prepare(
        srcT, 
        dstT,
		srcRect,
		to->vertices,
        params.color != std::nullopt, 
        static_cast<int>(params.ink), 
        params.blend,
        false,
        mask
    );
	Orbit::RlExt::DrawTexture(&srcT, &srcRect, to->vertices, params.color.value_or(WHITE));
    EndShaderMode();
    EndTextureMode();

    UnloadImage(*dst);
	*dst = LoadImageFromTexture(canvas.texture);
	ImageFlipVertical(dst);

	UnloadTexture(srcT);
	UnloadTexture(dstT);
	if (mask) UnloadTexture(*mask);
	UnloadRenderTexture(canvas);
}

};

namespace Orbit::Lua {

void LuaRuntime::_register_image() {

	luaL_newmetatable(L, META);

	lua_pushcfunction(L, image_tostring);
	lua_setfield(L, -2, "__tostring");

	lua_pushcfunction(L, image_index);
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
	lua_setglobal(L, "copy");

	lua_pop(L, 1);

}

};
