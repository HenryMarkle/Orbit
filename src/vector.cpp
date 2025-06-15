#include <string>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <cstring>
#include <sstream>

#include <Orbit/Lua/runtime.h>
#include <Orbit/Lua/vector.h>

#include <xsimd/xsimd.hpp>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

#define META "vector"

namespace Orbit::Lua {

float Vector::distance(Vector const &v) const {
	auto a = xsimd::load_aligned(_data);
	auto b = xsimd::load_aligned(v._data);

	auto diff = xsimd::sub(a, b);

	auto squared_diff = xsimd::mul(diff, diff);

	return xsimd::reduce_add(squared_diff);
}

Vector Vector::mix(Vector const &v, float t) const {
	auto a = xsimd::load_aligned(_data);
	auto b = xsimd::load_aligned(v._data);

	auto simd_t = xsimd::broadcast<float>(t);

	auto diff = xsimd::sub(b, a);
	auto scaled = xsimd::mul(simd_t, diff);
	auto res = xsimd::add(a, scaled);

	auto res_vec = Vector();
	xsimd::store_aligned(res_vec._data, res);

	return res_vec;
}

void Vector::normalize() {
	float len_squared = _data[0] * _data[0] + _data[1] * _data[1] + _data[2] + _data[2] + _data[3] * _data[3];

	float len = std::sqrt(len_squared);

	if (len > 0.0f) {
		_data[0] /= len;
		_data[1] /= len;
		_data[2] /= len;
		_data[3] /= len;
	}
}

std::string Vector::tostring() const {
	std::stringstream ss;

		ss 
			<< META << '(' 
			<< std::setprecision(4) << _data[0] << ", "
			<< std::setprecision(4) << _data[1] << ", "
			<< std::setprecision(4) << _data[2] << ", "
			<< std::setprecision(4) << _data[3] << ")";

		return ss.str();
}

Vector Vector::operator+(Vector const &v) const {
	auto ba = xsimd::load_aligned(_data);
	auto bb = xsimd::load_aligned(v._data);

	auto res = ba + bb;

	auto res_vec = Vector();

	res.store_aligned(res_vec._data);

	return res_vec;
}

Vector Vector::operator-(Vector const &v) const {
	auto ba = xsimd::load_aligned(_data);
	auto bb = xsimd::load_aligned(v._data);

	auto res = ba - bb;

	auto res_vec = Vector();

	res.store_aligned(res_vec._data);

	return res_vec;
}

Vector Vector::operator*(float f) const {
	auto ba = xsimd::load_aligned(_data);

	auto res = ba * f;

	auto res_vec = Vector();

	res.store_aligned(res_vec._data);

	return res_vec;
}

Vector Vector::operator/(float f) const {
	auto ba = xsimd::load_aligned(_data);

	auto res = ba / f;

	auto res_vec = Vector();

	res.store_aligned(res_vec._data);

	return res_vec;
}

Vector &Vector::operator=(Vector const &v) {
	if (this == &v) return *this;

	std::memcpy(_data, v._data, sizeof(float) * 4);
	
	return *this;
}

Vector &Vector::operator=(Vector &&v) noexcept {
	if (this == &v) return *this;

	std::memcpy(_data, v._data, sizeof(float) * 4);
	std::memset(v._data, 0, sizeof(float) * 4);
	
	return *this;
}

Vector::Vector(Vector const &v) {
	std::memcpy(_data, v._data, sizeof(float) * 4);
}

Vector::Vector(Vector &&v) noexcept {
	std::memcpy(_data, v._data, sizeof(float) * 4);
	std::memset(v._data, 0, sizeof(float) * 4);
}

Vector::Vector() {
	std::memset(_data, 0, sizeof(float) * 4);
}

Vector::Vector(float x, float y, float z, float w) {
	*_data = x;
	*(_data + 1) = y;
	*(_data + 2) = z;
	*(_data + 3) = w;
}

void LuaRuntime::_register_vector() {
	const auto make = [](lua_State *L) {
		float x = luaL_checknumber(L, 1);
		float y = luaL_checknumber(L, 2);
		float z = luaL_checknumber(L, 3);
		float w = luaL_checknumber(L, 4);

		Vector *p = new Vector(x, y, z, w);

		Vector **u_data = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*u_data = p;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);
	
		return 1;
	};

	const auto read = [](lua_State *L) {
		Vector *p = *static_cast<Vector **>(luaL_checkudata(L, 1, META));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "x") == 0) lua_pushnumber(L, p->_data[0]);
		else if (std::strcmp(field, "y") == 0) lua_pushnumber(L, p->_data[1]);
		else if (std::strcmp(field, "z") == 0) lua_pushnumber(L, p->_data[2]);
		else if (std::strcmp(field, "w") == 0) lua_pushnumber(L, p->_data[3]);
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Vector *p = *static_cast<Vector **>(luaL_checkudata(L, 1, META));

		const char *field = luaL_checkstring(L, 2);
		float value = luaL_checknumber(L, 3);

		if (std::strcmp(field, "x") == 0) p->_data[0] = value;
		else if (std::strcmp(field, "y") == 0) p->_data[1] = value;
		else if (std::strcmp(field, "z") == 0) p->_data[2] = value;
		else if (std::strcmp(field, "w") == 0) p->_data[3] = value;
		else luaL_error(L, "invalid field '%s' in point", field);

		return 0;
	};

	const auto add = [](lua_State *L) {
		Vector a = **static_cast<Vector **>(luaL_checkudata(L, 1, META));
		Vector b = **static_cast<Vector **>(luaL_checkudata(L, 2, META));
		
		Vector *res = new Vector();
		*res = a + b;

		Vector **u_data = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*u_data = res;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Vector a = **static_cast<Vector **>(luaL_checkudata(L, 1, META));
		Vector b = **static_cast<Vector **>(luaL_checkudata(L, 2, META));
			
		Vector *res = new Vector();
		*res = a - b;

		Vector **u_data = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*u_data = res;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto multiply = [](lua_State *L) {
		Vector *v = nullptr;
		float n = 0.0f;
		
		if ((v = *static_cast<Vector **>(luaL_testudata(L, 1, META))) != nullptr && lua_isnumber(L, 2)) {
			n = static_cast<float>(lua_tonumber(L, 2));
		}
		else if ((v = *static_cast<Vector **>(luaL_testudata(L, 2, META))) != nullptr && lua_isnumber(L, 1)) {

			n = static_cast<float>(lua_tonumber(L, 1));
		}
		else {
			return luaL_error(L, "invalid operands to vector multiplication");
		}

		Vector *res = new Vector();

		auto r = *v * n;
			
		*res = r;

		Vector **u_data = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*u_data = res;

		//*res = (*v) * n;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);

		return 1;
	};
	
	const auto divide = [](lua_State *L) {
		Vector *v = nullptr;
		float n = 0.0f;
		
		if ((v = *static_cast<Vector **>(luaL_testudata(L, 1, META))) != nullptr && lua_isnumber(L, 2)) {
			n = static_cast<float>(lua_tonumber(L, 2));
		}
		else if ((v = *static_cast<Vector **>(luaL_testudata(L, 2, META))) != nullptr && lua_isnumber(L, 1)) {

			n = static_cast<float>(lua_tonumber(L, 1));
		}
		else {
			return luaL_error(L, "invalid operands to vector multiplication");
		}

		Vector *res = new Vector();

		auto r = *v / n;
			
		*res = r;

		Vector **u_data = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*u_data = res;

		//*res = (*v) * n;

		luaL_getmetatable(L, META);
		lua_setmetatable(L, -2);

		return 1;
	};
	const auto equals = [](lua_State *L) {
		Vector a = **static_cast<Vector **>(luaL_checkudata(L, 1, META));
		Vector b = **static_cast<Vector **>(luaL_checkudata(L, 2, META));
		
		bool res = a == b;

		lua_pushboolean(L, res);

		return 1;
	};

	const auto tostring = [](lua_State *L) {
		Vector *v = *static_cast<Vector **>(luaL_checkudata(L, 1, META));
		
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
		Vector *ptr = *static_cast<Vector **>(lua_touserdata(L, 1));
		delete ptr;
		return 0;
	});
	lua_setfield(L, -2, "__gc");

	lua_pop(L, 1);

}

std::ostream &operator<<(std::ostream o, const Vector &v) {
	return o << META << '(' 
		<< std::setprecision(4) << v._data[0] << ',' 
		<< std::setprecision(4) << v._data[1] << ',' 
		<< std::setprecision(4) << v._data[2] << ',' 
		<< std::setprecision(4) << v._data[3] 
		<< ')';
}
};
