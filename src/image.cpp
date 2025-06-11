#include <optional>
#include <sstream>
#include <cstring>
#include <string>

#include <xsimd/xsimd.hpp>

#include <Orbit/image.h>
#include <Orbit/rect.h>
#include <Orbit/quad.h>
#include <Orbit/lua.h>

#include <raylib.h>
#include <rlgl.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

#define META "image"

Image MakeSilhouette(const Image *src) {
	if (src->format != PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 && 
        src->format != PIXELFORMAT_UNCOMPRESSED_R8G8B8) {
        throw std::runtime_error("unsupported image format");
    }
    
    Image silhouette = ImageCopy(*src);
    const int length = silhouette.width * silhouette.height;
    
    if (src->format == PIXELFORMAT_UNCOMPRESSED_R8G8B8A8) {
        using batch_type = xsimd::batch<uint32_t>;
        constexpr size_t batch_size = batch_type::size;
        const uint32_t white_pixel = 0xFFFFFFFF;
        auto white_batch = xsimd::broadcast<uint32_t>(white_pixel);
        const uint32_t black_pixel = 0xFF000000;
        auto black_batch = xsimd::broadcast<uint32_t>(black_pixel);
        uint32_t *pixel_data = reinterpret_cast<uint32_t *>(silhouette.data);
        
        size_t i = 0;
        for (; i + batch_size <= static_cast<size_t>(length); i += batch_size) {
            auto pixel_batch = xsimd::load_unaligned(&pixel_data[i]);
            auto is_white_mask = xsimd::eq(pixel_batch, white_batch);
            auto res_batch = xsimd::select(is_white_mask, white_batch, black_batch);
            xsimd::store_unaligned(&pixel_data[i], res_batch);
        }
        for (; i < static_cast<size_t>(length); ++i) {
            if (pixel_data[i] != white_pixel) pixel_data[i] = black_pixel;
        }
    } else {
        using batch_type = xsimd::batch<uint8_t>;
        constexpr size_t batch_size = batch_type::size;
        const uint8_t white_component = 255;
        const uint8_t black_component = 0;
        auto white_batch = xsimd::broadcast<uint8_t>(white_component);
        auto black_batch = xsimd::broadcast<uint8_t>(black_component);
        uint8_t *pixel_data = reinterpret_cast<uint8_t *>(silhouette.data);
        
        size_t total_bytes = length * 3;
        size_t i = 0;
        
        for (; i + batch_size <= total_bytes; i += batch_size) {
            auto pixel_batch = xsimd::load_unaligned(&pixel_data[i]);
            auto is_white_mask = xsimd::eq(pixel_batch, white_batch);
            auto res_batch = xsimd::select(is_white_mask, white_batch, black_batch);
            xsimd::store_unaligned(&pixel_data[i], res_batch);
        }
        
        size_t remaining_pixels_start = (i / 3) * 3;
        for (size_t pixel_idx = remaining_pixels_start / 3; pixel_idx < static_cast<size_t>(length); ++pixel_idx) {
            size_t base_idx = pixel_idx * 3;
            uint8_t r = pixel_data[base_idx];
            uint8_t g = pixel_data[base_idx + 1];
            uint8_t b = pixel_data[base_idx + 2];
            
            if (r == 255 && g == 255 && b == 255) {
                // Keep white pixel as is
                pixel_data[base_idx] = 255;
                pixel_data[base_idx + 1] = 255;
                pixel_data[base_idx + 2] = 255;
            } else {
                // Convert to black
                pixel_data[base_idx] = 0;
                pixel_data[base_idx + 1] = 0;
                pixel_data[base_idx + 2] = 0;
            }
        }
    }
    
    return silhouette;
}

int image_fill(lua_State *L) {
	Image *img  = static_cast<Image *>(luaL_checkudata(L, 1, "image"));
	Color *c = static_cast<Color *>(luaL_checkudata(L, 2, "color"));

	ImageClearBackground(img, *c);

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

int image_index(lua_State *L) {
	Image *img = static_cast<Image *>(luaL_checkudata(L, 1, META));
	const char *field = luaL_checkstring(L, 2);

	
	if (std::strcmp(field, "width") == 0) lua_pushnumber(L, img->width);
	else if (std::strcmp(field, "height") == 0) lua_pushnumber(L, img->height);
	else if (std::strcmp(field, "fill") == 0) lua_pushcfunction(L, image_fill);
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

CopyImageParams::CopyImageParams() : blend(1), color(std::nullopt), ink(CopyImageInk::None), mask(nullptr) {}
CopyImageParams::CopyImageParams(float blend, std::optional<Color> color, CopyImageInk ink, Image *mask) : blend(blend), color(color), ink(ink), mask(mask) {}

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

	lua_pop(L, 1);

}

};
