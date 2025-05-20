#include <immintrin.h>
#include <iostream>
#include <iomanip>
#include <cstring>

#include <Orbit/lua.h>
#include <Orbit/point.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

Point Point::operator+(Point const &p) {
	return Point(this->x + p.x, this->y + p.y);
}

Point Point::operator-(Point const &p) {
	return Point(this->x - p.x, this->y - p.y);
}

Point Point::operator*(int i) {
	return Point(this->x + i, this->y + i);
}

Point Point::operator/(int i) {
	return Point(this->x/i, this->y/i);
}

Point Point::operator*(float i) {
	return Point(this->x + i, this->y + i);
}

Point Point::operator/(float i) {
	return Point(this->x/i, this->y/i);
}

std::ostream &operator<<(std::ostream o, const Point &p) {
	return o << "Point(" 
		<< std::setprecision(4) << p.x << ','
		<< std::setprecision(4) << p.y
		<< ')';
}

void LuaRuntime::_register_point() {
	const auto make = [](lua_State *L) {
		float x = luaL_checknumber(L, 1);
		float y = luaL_checknumber(L, 2);
	
		Point *p = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));

		p->x = x;
		p->y = y;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);
	
		return 1;
	};

	const auto read = [](lua_State *L) {
		Point *p = static_cast<Point *>(luaL_checkudata(L, 1, "point"));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "x") == 0) lua_pushnumber(L, p->x);
		else if (std::strcmp(field, "y") == 0) lua_pushnumber(L, p->y);
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Point *p = static_cast<Point *>(luaL_checkudata(L, 1, "point"));

		const char *field = luaL_checkstring(L, 2);
		float value = luaL_checknumber(L, 3);

		if (std::strcmp(field, "x") == 0) p->x = value;
		else if (std::strcmp(field, "y") == 0) p->y = value;
		else luaL_error(L, "invalid field '%s' in point", field);

		return 0;
	};

	const auto add = [](lua_State *L) {
		Point a = *static_cast<Point *>(luaL_checkudata(L, 1, "point"));
		Point b = *static_cast<Point *>(luaL_checkudata(L, 2, "point"));
		

		Point *res = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));

		*res = a + b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Point a = *static_cast<Point *>(luaL_checkudata(L, 1, "point"));
		Point b = *static_cast<Point *>(luaL_checkudata(L, 2, "point"));
		
		Point *res = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
		*res = a - b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto multiply = [](lua_State *L) {
		Point a = *static_cast<Point *>(luaL_checkudata(L, 1, "point"));
		float b = static_cast<float>(luaL_checknumber(L, 2));
		
		Point *res = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
		*res = a * b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};
	
	const auto divide = [](lua_State *L) {
		Point a = *static_cast<Point *>(luaL_checkudata(L, 1, "point"));
		float b = static_cast<float>(luaL_checknumber(L, 2));
		
		Point *res = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
		*res = a / b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto equals = [](lua_State *L) {
		Point a = *static_cast<Point *>(luaL_checkudata(L, 1, "point"));
		Point b = *static_cast<Point *>(luaL_checkudata(L, 2, "point"));
		
		bool res = a == b;

		lua_pushboolean(L, res);

		return 1;
	};

	const auto tostring = [](lua_State *L) {
		Point *a = static_cast<Point *>(luaL_checkudata(L, 1, "point"));
		auto str = a->tostring();
		lua_pushstring(L, str.c_str());
		return 1;
	};

	luaL_newmetatable(L, "point");

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

	lua_pushcfunction(L, multiply);
	lua_setfield(L, -2, "__mul");

	lua_pushcfunction(L, divide);
	lua_setfield(L, -2, "__div");

	lua_pushcfunction(L, equals);
	lua_setfield(L, -2, "__eq");

	lua_pop(L, 1);
}

};
