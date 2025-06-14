#include <cstring>
#include <cstdint>
#include <sstream>

#include <Orbit/Lua/lua.h>

#include <raylib.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

inline uint32_t pack(const Color *c) {
	return static_cast<uint32_t>(c->a << 24) | 
			static_cast<uint32_t>(c->b << 16) | 
			static_cast<uint32_t>(c->g << 8) | 
			static_cast<uint32_t>(c->r);
}

int color_pack(lua_State *L) {
	Color *c = static_cast<Color *>(luaL_checkudata(L, 1, "color"));
		
	uint32_t packed = pack(c);
	
	lua_pushinteger(L, packed);
	return 1;
}

void LuaRuntime::_register_color() {
	const auto read = [](lua_State *L) {
		Color *p = static_cast<Color *>(luaL_checkudata(L, 1, "color"));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "r") == 0) lua_pushnumber(L, p->r);
		else if (std::strcmp(field, "g") == 0) lua_pushnumber(L, p->g);
		else if (std::strcmp(field, "b") == 0) lua_pushnumber(L, p->b);
		else if (std::strcmp(field, "a") == 0) lua_pushnumber(L, p->a);
		else if (std::strcmp(field, "pack") == 0) lua_pushcfunction(L, color_pack);
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Color *p = static_cast<Color *>(luaL_checkudata(L, 1, "color"));

		const char *field = luaL_checkstring(L, 2);
		int value = luaL_checknumber(L, 3);

		if (std::strcmp(field, "r") == 0) p->r = (uint8_t)value;
		else if (std::strcmp(field, "g") == 0) p->g = (uint8_t)value;
		else if (std::strcmp(field, "b") == 0) p->b = (uint8_t)value;
		else if (std::strcmp(field, "a") == 0) p->a = (uint8_t)value;
		else luaL_error(L, "invalid field '%s' in color", field);

		return 0;
	};

	const auto add = [](lua_State *L) {
		Color a = *static_cast<Color *>(luaL_checkudata(L, 1, "color"));
		Color b = *static_cast<Color *>(luaL_checkudata(L, 2, "color"));
		

		Color *res = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));

		*res = Color {
			static_cast<uint8_t>(a.r + b.r),
			static_cast<uint8_t>(a.g + b.g),
			static_cast<uint8_t>(a.b + b.b),
			static_cast<uint8_t>(a.a + b.a),
		};

		luaL_getmetatable(L, "color");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Color a = *static_cast<Color *>(luaL_checkudata(L, 1, "color"));
		Color b = *static_cast<Color *>(luaL_checkudata(L, 2, "color"));
		
		Color *res = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
		*res = Color {
			static_cast<uint8_t>(a.r - b.r),
			static_cast<uint8_t>(a.g - b.g),
			static_cast<uint8_t>(a.b - b.b),
			static_cast<uint8_t>(a.a - b.a),
		};
;

		luaL_getmetatable(L, "color");
		lua_setmetatable(L, -2);

		return 1;
	};
	
	const auto equals = [](lua_State *L) {
		Color a = *static_cast<Color *>(luaL_checkudata(L, 1, "color"));
		Color b = *static_cast<Color *>(luaL_checkudata(L, 2, "color"));
		
		bool res = (
			a.r == b.r &&
			a.g == b.g &&
			a.b == b.b &&
			a.a == b.a
		);

		lua_pushboolean(L, res);

		return 1;
	};

	const auto tostring = [](lua_State *L) {
		Color *a = static_cast<Color *>(luaL_checkudata(L, 1, "color"));
			
		std::stringstream ss;

		ss << "color(" <<
			static_cast<unsigned short>(a->r) << ", " <<
			static_cast<unsigned short>(a->g) << ", " <<
			static_cast<unsigned short>(a->b) << ", " <<
			static_cast<unsigned short>(a->a) << ')';

		auto str = ss.str();
		lua_pushstring(L, str.c_str());
		return 1;
	};

	luaL_newmetatable(L, "color");

	lua_pushcfunction(L, tostring);
	lua_setfield(L, -2, "__tostring");

	lua_pushcfunction(L, read);
	lua_setfield(L, -2, "__index");

	lua_pushcfunction(L, write);
	lua_setfield(L, -2, "__newindex");

	lua_pushcfunction(L, add);
	lua_setfield(L, -2, "__add");

	lua_pushcfunction(L, subtract);
	lua_setfield(L, -2, "__sub");

	lua_pushcfunction(L, equals);
	lua_setfield(L, -2, "__eq");

	lua_pop(L, 1);
}

};
