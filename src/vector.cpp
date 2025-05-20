#include <string>
#include <immintrin.h>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <cstring>
#include <stdexcept>
#include <sstream>

#include <Orbit/lua.h>
#include <Orbit/vector.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

float Vector::distance(Vector const &v) const {
	__m128 a = _mm_load_ps(this->data);
	__m128 b = _mm_load_ps(v.data);

	__m128 diff = _mm_sub_ps(a, b);
	__m128 squared = _mm_mul_ps(diff, diff);

	__m128 shuf = _mm_shuffle_ps(squared, squared, _MM_SHUFFLE(2, 3, 0, 1));
	__m128 sums = _mm_add_ps(squared, shuf);

	shuf = _mm_movehl_ps(shuf, sums);
	sums = _mm_add_ss(sums, shuf);

	return std::sqrt(_mm_cvtss_f32(sums));
}

Vector Vector::mix(Vector const &v, float t) const {
 return *this * (1 - t) + v * t;
}

void Vector::normalize() {
	float len_squared = data[0] * data[0] + data[1] * data[1] + data[2] + data[2] + data[3] * data[3];

	float len = std::sqrt(len_squared);

	if (len > 0.0f) {
		data[0] /= len;
		data[1] /= len;
		data[2] /= len;
		data[3] /= len;
	}
}

std::string Vector::tostring() const {
	std::stringstream ss;

		ss 
			<< "vector(" 
			<< std::setprecision(4) << data[0] << ", "
			<< std::setprecision(4) << data[1] << ", "
			<< std::setprecision(4) << data[2] << ", "
			<< std::setprecision(4) << data[3] << ")";

		return ss.str();
}

Vector Vector::operator+(Vector const &v) const {
	auto a = _mm_load_ps(this->data);
	auto b = _mm_load_ps(v.data);

	auto res = _mm_add_ps(a, b);

	Vector res_vec(0, 0, 0, 0);
	_mm_store_ps(res_vec.data, res);
	
	return res_vec;
}

Vector Vector::operator-(Vector const &v) const {
	auto a = _mm_load_ps(this->data);
	auto b = _mm_load_ps(v.data);

	auto res = _mm_sub_ps(a, b);

	Vector res_vec(0, 0, 0, 0);
	_mm_store_ps(res_vec.data, res);
	
	return res_vec;

}

Vector Vector::operator*(float f) const {
	auto v = _mm_load_ps(this->data);
	auto fv = _mm_set1_ps(f);
	
	auto res = _mm_mul_ps(v, fv);

	Vector res_vec(0, 0, 0, 0);
	_mm_store_ps(res_vec.data, res);

	return res_vec;
}

Vector Vector::operator/(float f) const {
	auto v = _mm_loadu_ps(this->data);
	auto fv = _mm_set1_ps(f);
	
	auto res = _mm_div_ps(v, fv);

	Vector res_vec(0, 0, 0, 0);
	_mm_storeu_ps(res_vec.data, res);

	return res_vec;
}

Vector &Vector::operator=(Vector const &v) {
	std::memcpy(this->data, v.data, sizeof(float) * 4);
	return *this;
}

Vector::Vector(Vector const &v) {
	std::memcpy(data, v.data, sizeof(float) * 4);
}

Vector::Vector() {
	std::memset(data, 0, sizeof(float) * 4);
}

void LuaRuntime::_register_vector() {
	const auto make = [](lua_State *L) {
		float x = luaL_checknumber(L, 1);
		float y = luaL_checknumber(L, 2);
		float z = luaL_checknumber(L, 3);
		float w = luaL_checknumber(L, 4);

#ifdef __WIN32
		Vector *p = static_cast<Vector *>(_aligned_malloc(16, sizeof(Vector)));
#else
		Vector *p = static_cast<Vector *>(aligned_alloc(16, sizeof(Vector)));
#endif

		p->data[0] = x;
		p->data[1] = y;
		p->data[2] = z;
		p->data[3] = w;

		Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*udata = p;

		luaL_getmetatable(L, "vector");
		lua_setmetatable(L, -2);
	
		return 1;
	};

	const auto read = [](lua_State *L) {
		Vector *p = *static_cast<Vector **>(luaL_checkudata(L, 1, "vector"));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "x") == 0) lua_pushnumber(L, p->data[0]);
		else if (std::strcmp(field, "y") == 0) lua_pushnumber(L, p->data[1]);
		else if (std::strcmp(field, "z") == 0) lua_pushnumber(L, p->data[2]);
		else if (std::strcmp(field, "w") == 0) lua_pushnumber(L, p->data[3]);
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Vector *p = *static_cast<Vector **>(luaL_checkudata(L, 1, "vector"));

		const char *field = luaL_checkstring(L, 2);
		float value = luaL_checknumber(L, 3);

		if (std::strcmp(field, "x") == 0) p->data[0] = value;
		else if (std::strcmp(field, "y") == 0) p->data[1] = value;
		else if (std::strcmp(field, "z") == 0) p->data[2] = value;
		else if (std::strcmp(field, "w") == 0) p->data[3] = value;
		else luaL_error(L, "invalid field '%s' in point", field);

		return 0;
	};

	const auto add = [](lua_State *L) {
		Vector a = **static_cast<Vector **>(luaL_checkudata(L, 1, "vector"));
		Vector b = **static_cast<Vector **>(luaL_checkudata(L, 2, "vector"));
		
#ifdef __WIN32
		Vector *res = static_cast<Vector *>(_aligned_malloc(16, sizeof(Vector)));
#else
		Vector *res = static_cast<Vector *>(aligned_alloc(16, sizeof(Vector)));
#endif
		*res = a + b;

		Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*udata = res;

		luaL_getmetatable(L, "vector");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Vector a = **static_cast<Vector **>(luaL_checkudata(L, 1, "vector"));
		Vector b = **static_cast<Vector **>(luaL_checkudata(L, 2, "vector"));
		
#ifdef __WIN32
		Vector *res = static_cast<Vector *>(_aligned_malloc(16, sizeof(Vector)));
#else
		Vector *res = static_cast<Vector *>(aligned_alloc(16, sizeof(Vector)));
#endif
		*res = a - b;

		Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*udata = res;

		luaL_getmetatable(L, "vector");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto multiply = [](lua_State *L) {
		Vector *v = nullptr;
		float n = 0.0f;
		
		if ((v = *static_cast<Vector **>(luaL_testudata(L, 1, "vector"))) != nullptr && lua_isnumber(L, 2)) {
			n = static_cast<float>(lua_tonumber(L, 2));
		}
		else if ((v = *static_cast<Vector **>(luaL_testudata(L, 2, "vector"))) != nullptr && lua_isnumber(L, 1)) {

			n = static_cast<float>(lua_tonumber(L, 1));
		}
		else {
			return luaL_error(L, "invalid operands to vector multiplication");
		}

#ifdef __WIN32
		Vector *res = static_cast<Vector *>(_aligned_malloc(16, sizeof(Vector)));
#else
		Vector *res = static_cast<Vector *>(aligned_alloc(16, sizeof(Vector)));
#endif

		auto r = *v * n;
			
		*res = r;

		Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*udata = res;

		//*res = (*v) * n;

		luaL_getmetatable(L, "vector");
		lua_setmetatable(L, -2);

		return 1;
	};
	
	const auto divide = [](lua_State *L) {
		Vector *v = nullptr;
		float n = 0.0f;
		
		if ((v = *static_cast<Vector **>(luaL_testudata(L, 1, "vector"))) != nullptr && lua_isnumber(L, 2)) {
			n = static_cast<float>(lua_tonumber(L, 2));
		}
		else if ((v = *static_cast<Vector **>(luaL_testudata(L, 2, "vector"))) != nullptr && lua_isnumber(L, 1)) {

			n = static_cast<float>(lua_tonumber(L, 1));
		}
		else {
			return luaL_error(L, "invalid operands to vector multiplication");
		}

#ifdef __WIN32
		Vector *res = static_cast<Vector *>(_aligned_malloc(16, sizeof(Vector)));
#else
		Vector *res = static_cast<Vector *>(aligned_alloc(16, sizeof(Vector)));
#endif

		auto r = *v / n;
			
		*res = r;

		Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*udata = res;

		//*res = (*v) * n;

		luaL_getmetatable(L, "vector");
		lua_setmetatable(L, -2);

		return 1;
	};
	const auto equals = [](lua_State *L) {
		Vector a = **static_cast<Vector **>(luaL_checkudata(L, 1, "vector"));
		Vector b = **static_cast<Vector **>(luaL_checkudata(L, 2, "vector"));
		
		bool res = a == b;

		lua_pushboolean(L, res);

		return 1;
	};

	const auto tostring = [](lua_State *L) {
		Vector *v = *static_cast<Vector **>(luaL_checkudata(L, 1, "vector"));
		
		auto str = v->tostring();	

		lua_pushstring(L, str.c_str());
	
		return 1;
	};

	luaL_newmetatable(L, "vector");

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

std::ostream &operator<<(std::ostream o, const Vector &v) {
	return o << "Vector(" 
		<< std::setprecision(4) << v.data[0] << ',' 
		<< std::setprecision(4) << v.data[1] << ',' 
		<< std::setprecision(4) << v.data[2] << ',' 
		<< std::setprecision(4) << v.data[3] 
		<< ')';
}
};
