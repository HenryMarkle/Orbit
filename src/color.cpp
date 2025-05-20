#include <iostream>
#include <cstring>
#include <cstdint>

#include <Orbit/lua.h>
#include <Orbit/color.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

void LuaRuntime::_register_color() {
	const auto read = [](lua_State *L) {
		Color *p = static_cast<Color *>(luaL_checkudata(L, 1, "color"));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "r") == 0) lua_pushnumber(L, p->r);
		else if (std::strcmp(field, "g") == 0) lua_pushnumber(L, p->g);
		else if (std::strcmp(field, "b") == 0) lua_pushnumber(L, p->b);
		else if (std::strcmp(field, "a") == 0) lua_pushnumber(L, p->a);
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

		*res = a + b;

		luaL_getmetatable(L, "color");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Color a = *static_cast<Color *>(luaL_checkudata(L, 1, "color"));
		Color b = *static_cast<Color *>(luaL_checkudata(L, 2, "color"));
		
		Color *res = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
		*res = a - b;

		luaL_getmetatable(L, "color");
		lua_setmetatable(L, -2);

		return 1;
	};
	
	const auto equals = [](lua_State *L) {
		Color a = *static_cast<Color *>(luaL_checkudata(L, 1, "color"));
		Color b = *static_cast<Color *>(luaL_checkudata(L, 2, "color"));
		
		bool res = a == b;

		lua_pushboolean(L, res);

		return 1;
	};

	const auto tostring = [](lua_State *L) {
		Color *a = static_cast<Color *>(luaL_checkudata(L, 1, "color"));
		auto str = a->tostring();
		lua_pushstring(L, str.c_str());
		return 1;
	};

	luaL_newmetatable(L, "color");

	lua_pushcfunction(L, tostring);
	lua_setfield(L, -2, "__tostring");

	lua_newtable(L);

	//lua_pushcfunction(L, read);
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
