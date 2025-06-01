#ifdef AVX2
#include <immintrin.h>
#endif

#include <sstream>
#include <cstring>
#include <string>

#include <Orbit/image.h>
#include <Orbit/rect.h>
#include <Orbit/quad.h>

#include <raylib.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

#define META "image"

Image MakeSilhouette(const Image *src) {
	if (src->format != PIXELFORMAT_UNCOMPRESSED_R8G8B8A8) {
		throw std::runtime_error("unsupported image format");
	}

	Image silhouette = ImageCopy(*src);

	Color *pixels = reinterpret_cast<Color *>(silhouette.data);

	const int length = silhouette.width * silhouette.height;

#ifdef AVX2

	const int stride = 8;
	const int iters = length / stride;

	const __m256i white = _mm256_set1_epi32(0xFFFFFFFF);
	const __m256i black = _mm256_set1_epi32(0xFF000000);

	for (int i = 0; i < iters; i++) {
		__m256i pixels_vec = _mm256_loadu_si256(reinterpret_cast<const __m256i *>(&pixels[i * stride]));
		
		__m256i is_white = _mm256_cmpeq_epi32(pixels_vec, white);

		__m256i result = _mm256_blendv_epi8(black, white, is_white);

		_mm256_storeu_si256(reinterpret_cast<__m256i *>(&pixels[i * stride]), result);
	}

	for (int i = iters * stride; i < length; i++) {
		Color *p = pixels + i;

		if (p->r == 255 && p->g == 255 && p->b == 255 && p->a == 255) continue;

		*p = Color{ 0, 0, 0, 255 };
	}

#else

	for (int i = 0; i < length; i++) {
		Color *p = pixels + i;

		if (p->r == 255 && p->g == 255 && p->b == 255 && p->a == 255) continue;

		*p = Color{ 0, 0, 0, 255 };
	}

#endif	

	return silhouette;
}

//

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
	else if (std::strcmp(field, "silhouette") == 0) 
		lua_pushcfunction(L, [](lua_State *L){ 
				Image *img = static_cast<Image *>(luaL_checkudata(L, 1, META));

				Image *nimg = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
				*nimg = MakeSilhouette(img);

				luaL_getmetatable(L, META);
				lua_setmetatable(L, -2);

				return 1; 
		});
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
	free(img);
	return 0;
}

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
