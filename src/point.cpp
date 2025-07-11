#include <iostream>
#include <sstream>
#include <iomanip>
#include <cstring>
#include <math.h>

#include <Orbit/Lua/runtime.h>

#include <raylib.h>
#include <raymath.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

void LuaRuntime::_register_point() {
	const auto make = [](lua_State *L) {
		float x = luaL_checknumber(L, 1);
		float y = luaL_checknumber(L, 2);
	
		Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

		p->x = x;
		p->y = y;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);
	
		return 1;
	};

	const auto read = [](lua_State *L) {
		Vector2 *p = static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "x") == 0) lua_pushnumber(L, p->x);
		else if (std::strcmp(field, "y") == 0) lua_pushnumber(L, p->y);
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Vector2 *p = static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));

		const char *field = luaL_checkstring(L, 2);
		float value = luaL_checknumber(L, 3);

		if (std::strcmp(field, "x") == 0) p->x = value;
		else if (std::strcmp(field, "y") == 0) p->y = value;
		else luaL_error(L, "invalid field '%s' in point", field);

		return 0;
	};

	const auto add = [](lua_State *L) {
		Vector2 a = *static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
		Vector2 b = *static_cast<Vector2 *>(luaL_checkudata(L, 2, "point"));
		

		Vector2 *res = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

		*res = a + b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Vector2 a = *static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
		Vector2 b = *static_cast<Vector2 *>(luaL_checkudata(L, 2, "point"));
		
		Vector2 *res = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
		*res = a - b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto multiply = [](lua_State *L) {
		Vector2 a = *static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
		float b = static_cast<float>(luaL_checknumber(L, 2));
		
		Vector2 *res = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
		*res = a * b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};
	
	const auto divide = [](lua_State *L) {
		Vector2 a = *static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
		float b = static_cast<float>(luaL_checknumber(L, 2));
		
		Vector2 *res = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
		*res = a / b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto equals = [](lua_State *L) {
		Vector2 a = *static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
		Vector2 b = *static_cast<Vector2 *>(luaL_checkudata(L, 2, "point"));
		
		bool res = a == b; 

		lua_pushboolean(L, res);

		return 1;
	};

	const auto tostring = [](lua_State *L) {
		Vector2 *a = static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));

		std::stringstream ss;

		ss 
			<< "point("
			<< std::setprecision(3) << a->x << ", "
			<< std::setprecision(3) << a->y << ')';

		auto str = ss.str(); 

		lua_pushstring(L, str.c_str());
		return 1;
	};

	const auto concat = [](lua_State *L) {
		std::string a = luaL_tolstring(L, 1, nullptr);
		std::string b = luaL_tolstring(L, 2, nullptr);

		lua_pushstring(L, (a + b).c_str());
		return 1;
	};

	luaL_newmetatable(L, "point");

	lua_pushcfunction(L, tostring);
	lua_setfield(L, -2, "__tostring");
	
	lua_pushcfunction(L, concat);
	lua_setfield(L, -2, "__concat");

	lua_pushcfunction(L, read);
	lua_setfield(L, -2, "__index");

	lua_pushcfunction(L, write);
	lua_setfield(L, -2, "__newindex");

	lua_pushcfunction(L, add);
	lua_setfield(L, -2, "__add");

	lua_pushcfunction(L, subtract);
	lua_setfield(L, -2, "__sub");

	lua_pushcfunction(L, multiply);
	lua_setfield(L, -2, "__mul");

	lua_pushcfunction(L, divide);
	lua_setfield(L, -2, "__div");

	lua_pushcfunction(L, equals);
	lua_setfield(L, -2, "__eq");

	lua_pop(L, 1);
}

};
