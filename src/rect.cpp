#include <string>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <cstring>
#include <stdexcept>
#include <sstream>

#include <Orbit/Lua/runtime.h>
#include <Orbit/Lua/rect.h>

#include <xsimd/xsimd.hpp>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

#define META "rect"

namespace Orbit::Lua {

std::string Rect::tostring() const {
	std::stringstream ss;

		ss 
			<< META << '(' 
			<< std::setprecision(4) << _data[0] << ", "
			<< std::setprecision(4) << _data[1] << ", "
			<< std::setprecision(4) << _data[2] << ", "
			<< std::setprecision(4) << _data[3] << ")";

		return ss.str();
}

Rect Rect::operator+(Rect const &v) const {
	auto ba = xsimd::load_aligned(_data);
	auto bb = xsimd::load_aligned(v._data);

	auto res = ba + bb;

	auto res_rect = Rect();

	res.store_aligned(res_rect._data);

	return res_rect;
}

Rect Rect::operator-(Rect const &v) const {
	auto ba = xsimd::load_aligned(_data);
	auto bb = xsimd::load_aligned(v._data);

	auto res = ba - bb;

	auto res_rect = Rect();

	res.store_aligned(res_rect._data);

	return res_rect;
}

Rect Rect::operator*(float f) const {
	auto ba = xsimd::load_aligned(_data);

	auto res = ba * f;

	auto res_rect = Rect();

	res.store_aligned(res_rect._data);

	return res_rect;
}

Rect Rect::operator/(float f) const {
	auto ba = xsimd::load_aligned(_data);

	auto res = ba / f;

	auto res_rect = Rect();

	res.store_aligned(res_rect._data);

	return res_rect;
}

Rect &Rect::operator=(Rect const &v) {
	std::memcpy(this->_data, v._data, sizeof(float) * 4);
	return *this;
}

Rect::Rect(Rect const &v) {
	std::memcpy(this->_data, v._data, sizeof(float) * 4);
}

Rect::Rect() {
	std::memset(_data, 0, sizeof(float) * 4);
}

void LuaRuntime::_register_rectangle() {

	const auto make = [](lua_State *L) {
		float x = luaL_checknumber(L, 1);
		float y = luaL_checknumber(L, 2);
		float z = luaL_checknumber(L, 3);
		float w = luaL_checknumber(L, 4);

		Rect *p = new Rect();

		p->_data[0] = x;
		p->_data[1] = y;
		p->_data[2] = z;
		p->_data[3] = w;

		Rect **udata = static_cast<Rect **>(lua_newuserdata(L, sizeof(Rect *)));
		*udata = p;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto read = [](lua_State *L) {
		Rect *p = *static_cast<Rect **>(luaL_checkudata(L, 1, META));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "left") == 0) lua_pushnumber(L, p->_data[0]);
		else if (std::strcmp(field, "top") == 0) lua_pushnumber(L, p->_data[1]);
		else if (std::strcmp(field, "right") == 0) lua_pushnumber(L, p->_data[2]);
		else if (std::strcmp(field, "bottom") == 0) lua_pushnumber(L, p->_data[3]);
		else if (std::strcmp(field, "width") == 0) lua_pushnumber(L, p->width());
		else if (std::strcmp(field, "height") == 0) lua_pushnumber(L, p->height());
		else if (std::strcmp(field, "pos") == 0) {
			Vector2 *pos = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

			*pos = *reinterpret_cast<Vector2 *>(p->_data);

			luaL_getmetatable(L, "point");
			lua_setmetatable(L, -2);
		}
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Rect *p = *static_cast<Rect **>(luaL_checkudata(L, 1, META));

		const char *field = luaL_checkstring(L, 2);
		float value = luaL_checknumber(L, 3);

		if (std::strcmp(field, "left") == 0) p->_data[0] = value;
		else if (std::strcmp(field, "top") == 0) p->_data[1] = value;
		else if (std::strcmp(field, "right") == 0) p->_data[2] = value;
		else if (std::strcmp(field, "bottom") == 0) p->_data[3] = value;
		else luaL_error(L, "invalid field '%s' in rectangle", field);

		return 0;
	};

	const auto add = [](lua_State *L) {
		Rect a = **static_cast<Rect **>(luaL_checkudata(L, 1, META));
		Rect b = **static_cast<Rect **>(luaL_checkudata(L, 2, META));
		
		Rect *res = new Rect();
		*res = a + b;

		Rect **udata = static_cast<Rect **>(lua_newuserdata(L, sizeof(Rect *)));
		*udata = res;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Rect a = **static_cast<Rect **>(luaL_checkudata(L, 1, META));
		Rect b = **static_cast<Rect **>(luaL_checkudata(L, 2, META));
		
		Rect *res = new Rect();
		*res = a - b;

		Rect **udata = static_cast<Rect **>(lua_newuserdata(L, sizeof(Rect *)));
		*udata = res;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto multiply = [](lua_State *L) {
		Rect *v = nullptr;
		float n = 0.0f;
		
		if ((v = *static_cast<Rect **>(luaL_testudata(L, 1, META))) != nullptr && lua_isnumber(L, 2)) {
			n = static_cast<float>(lua_tonumber(L, 2));
		}
		else if ((v = *static_cast<Rect **>(luaL_testudata(L, 2, META))) != nullptr && lua_isnumber(L, 1)) {

			n = static_cast<float>(lua_tonumber(L, 1));
		}
		else {
			return luaL_error(L, "invalid operands to rectangle multiplication");
		}

		Rect *res = new Rect();

		auto r = *v * n;
			
		*res = r;

		Rect **udata = static_cast<Rect **>(lua_newuserdata(L, sizeof(Rect *)));
		*udata = res;

		//*res = (*v) * n;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);

		return 1;
	};
	
	const auto divide = [](lua_State *L) {
		Rect *v = nullptr;
		float n = 0.0f;
		
		if ((v = *static_cast<Rect **>(luaL_testudata(L, 1, META))) != nullptr && lua_isnumber(L, 2)) {
			n = static_cast<float>(lua_tonumber(L, 2));
		}
		else if ((v = *static_cast<Rect **>(luaL_testudata(L, 2, META))) != nullptr && lua_isnumber(L, 1)) {

			n = static_cast<float>(lua_tonumber(L, 1));
		}
		else {
			return luaL_error(L, "invalid operands to rectangle multiplication");
		}

		Rect *res = new Rect();

		auto r = *v / n;
			
		*res = r;

		Rect **udata = static_cast<Rect **>(lua_newuserdata(L, sizeof(Rect *)));
		*udata = res;

		//*res = (*v) * n;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);

		return 1;
	};
	const auto equals = [](lua_State *L) {
		Rect a = **static_cast<Rect **>(luaL_checkudata(L, 1, META));
		Rect b = **static_cast<Rect **>(luaL_checkudata(L, 2, META));
		
		bool res = a == b;

		lua_pushboolean(L, res);

		return 1;
	};

	const auto tostring = [](lua_State *L) {
		Rect *v = *static_cast<Rect **>(luaL_checkudata(L, 1, META));
		
		auto str = v->tostring();	

		lua_pushstring(L, str.c_str());
	
		return 1;
	};

	const auto concat = [](lua_State *L) {
		std::string a = luaL_tolstring(L, 1, nullptr);
		std::string b = luaL_tolstring(L, 2, nullptr);

		lua_pushstring(L, (a + b).c_str());
		return 1;
	};

	luaL_newmetatable(L, META);

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

	lua_pushcfunction(L, [](lua_State *L){
		Rect *ptr = *static_cast<Rect **>(lua_touserdata(L, 1));
		delete ptr;
		return 0;
	});
	lua_setfield(L, -2, "__gc");

	lua_pop(L, 1);
}

};
