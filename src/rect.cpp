#ifdef AVX2
#include <immintrin.h>
#endif

#include <string>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <cstring>
#include <stdexcept>
#include <sstream>

#include <Orbit/lua.h>
#include <Orbit/rect.h>

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
			<< std::setprecision(4) << data[0] << ", "
			<< std::setprecision(4) << data[1] << ", "
			<< std::setprecision(4) << data[2] << ", "
			<< std::setprecision(4) << data[3] << ")";

		return ss.str();
}

Rect Rect::operator+(Rect const &v) const {
#ifdef AVX2
	auto a = _mm_load_ps(this->data);
	auto b = _mm_load_ps(v.data);

	auto res = _mm_add_ps(a, b);

	Rect res_vec(0, 0, 0, 0);
	_mm_store_ps(res_vec.data, res);
	
	return res_vec;
#else
	return Rect(
			data[0] + v.data[0],
			data[1] + v.data[1],
			data[2] + v.data[2],
			data[3] + v.data[3]
		);
#endif
}

Rect Rect::operator-(Rect const &v) const {
#ifdef AVX2
	auto a = _mm_load_ps(this->data);
	auto b = _mm_load_ps(v.data);

	auto res = _mm_sub_ps(a, b);

	Rect res_vec(0, 0, 0, 0);
	_mm_store_ps(res_vec.data, res);
	
	return res_vec;
#else
	return Rect(
			data[0] - v.data[0],
			data[1] - v.data[1],
			data[2] - v.data[2],
			data[3] - v.data[3]
		);
#endif
}

Rect Rect::operator*(float f) const {
#ifdef AVX2
	auto v = _mm_load_ps(this->data);
	auto fv = _mm_set1_ps(f);
	
	auto res = _mm_mul_ps(v, fv);

	Rect res_vec(0, 0, 0, 0);
	_mm_store_ps(res_vec.data, res);

	return res_vec;
#else
	return Rect(
			data[0] * f,
			data[1] * f,
			data[2] * f,
			data[3] * f
		);
#endif
}

Rect Rect::operator/(float f) const {
#ifdef AVX2
	auto v = _mm_loadu_ps(this->data);
	auto fv = _mm_set1_ps(f);
	
	auto res = _mm_div_ps(v, fv);

	Rect res_vec(0, 0, 0, 0);
	_mm_storeu_ps(res_vec.data, res);

	return res_vec;
#else
	return Rect(
			data[0] / f,
			data[1] / f,
			data[2] / f,
			data[3] / f
		);
#endif
}

Rect &Rect::operator=(Rect const &v) {
	std::memcpy(this->data, v.data, sizeof(float) * 4);
	return *this;
}

Rect::Rect(Rect const &v) {
	std::memcpy(data, v.data, sizeof(float) * 4);
}

Rect::Rect() {
	std::memset(data, 0, sizeof(float) * 4);
}

void LuaRuntime::_register_rectangle() {
	const auto make = [](lua_State *L) {
		float x = luaL_checknumber(L, 1);
		float y = luaL_checknumber(L, 2);
		float z = luaL_checknumber(L, 3);
		float w = luaL_checknumber(L, 4);

#ifdef _WIN32
		Rect *p = static_cast<Rect *>(_aligned_malloc(16, sizeof(Rect)));
#else
		Rect *p = static_cast<Rect *>(aligned_alloc(16, sizeof(Rect)));
#endif

		p->data[0] = x;
		p->data[1] = y;
		p->data[2] = z;
		p->data[3] = w;

		Rect **udata = static_cast<Rect **>(lua_newuserdata(L, sizeof(Rect *)));
		*udata = p;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);
	
		return 1;
	};

	const auto read = [](lua_State *L) {
		Rect *p = *static_cast<Rect **>(luaL_checkudata(L, 1, META));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "left") == 0) lua_pushnumber(L, p->data[0]);
		else if (std::strcmp(field, "top") == 0) lua_pushnumber(L, p->data[1]);
		else if (std::strcmp(field, "right") == 0) lua_pushnumber(L, p->data[2]);
		else if (std::strcmp(field, "bottom") == 0) lua_pushnumber(L, p->data[3]);
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Rect *p = *static_cast<Rect **>(luaL_checkudata(L, 1, META));

		const char *field = luaL_checkstring(L, 2);
		float value = luaL_checknumber(L, 3);

		if (std::strcmp(field, "left") == 0) p->data[0] = value;
		else if (std::strcmp(field, "top") == 0) p->data[1] = value;
		else if (std::strcmp(field, "right") == 0) p->data[2] = value;
		else if (std::strcmp(field, "bottom") == 0) p->data[3] = value;
		else luaL_error(L, "invalid field '%s' in rectangle", field);

		return 0;
	};

	const auto add = [](lua_State *L) {
		Rect a = **static_cast<Rect **>(luaL_checkudata(L, 1, META));
		Rect b = **static_cast<Rect **>(luaL_checkudata(L, 2, META));
		
#ifdef _WIN32
		Rect *res = static_cast<Rect *>(_aligned_malloc(16, sizeof(Rect)));
#else
		Rect *res = static_cast<Rect *>(aligned_alloc(16, sizeof(Rect)));
#endif
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
		
#ifdef _WIN32
		Rect *res = static_cast<Rect *>(_aligned_malloc(16, sizeof(Rect)));
#else
		Rect *res = static_cast<Rect *>(aligned_alloc(16, sizeof(Rect)));
#endif
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

#ifdef _WIN32
		Rect *res = static_cast<Rect *>(_aligned_malloc(16, sizeof(Rect)));
#else
		Rect *res = static_cast<Rect *>(aligned_alloc(16, sizeof(Rect)));
#endif

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

#ifdef _WIN32
		Rect *res = static_cast<Rect *>(_aligned_malloc(16, sizeof(Rect)));
#else
		Rect *res = static_cast<Rect *>(aligned_alloc(16, sizeof(Rect)));
#endif

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

	luaL_newmetatable(L, META);

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

	lua_pushcfunction(L, multiply);
	lua_setfield(L, -2, "__mul");
	
	lua_pushcfunction(L, divide);
	lua_setfield(L, -2, "__div");
	
	lua_pushcfunction(L, equals);
	lua_setfield(L, -2, "__eq");

	lua_pushcfunction(L, [](lua_State *L){
		void *ptr = *static_cast<void **>(lua_touserdata(L, 1));
		free(ptr);
		return 0;
	});
	lua_setfield(L, -2, "__gc");

	lua_pop(L, 1);
}

};
