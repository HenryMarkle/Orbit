#include <string>
#include <immintrin.h>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <cstring>
#include <stdexcept>

#include <Orbit/lua.h>

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
	auto v = _mm_load_ps(this->data);
	auto fv = _mm_set1_ps(f);
	
	auto res = _mm_div_ps(v, fv);

	Vector res_vec(0, 0, 0, 0);
	_mm_store_ps(res_vec.data, res);

	return res_vec;
}

Vector::Vector(Vector const &v) {
	std::memcpy(data, v.data, sizeof(float) * 4);
}

Vector::Vector() {
	std::memset(data, 0, sizeof(float) * 4);
}


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


Rectangle Rectangle::operator+(Rectangle const &r) {
	return Rectangle(this->left + r.left, this->top + r.top, this->right + r.right, this->bottom + r.bottom);
}

Rectangle Rectangle::operator-(Rectangle const &r) {
	return Rectangle(this->left - r.left, this->top - r.top, this->right - r.right, this->bottom - r.bottom);
}


std::ostream &operator<<(std::ostream o, const Vector &v) {
	return o << "Vector(" 
		<< std::setprecision(3) << v.data[0] << ',' 
		<< std::setprecision(3) << v.data[1] << ',' 
		<< std::setprecision(3) << v.data[2] << ',' 
		<< std::setprecision(3) << v.data[3] 
		<< ')';
}

std::ostream &operator<<(std::ostream o, const Point &p) {
	return o << "Point(" 
		<< std::setprecision(3) << p.x << ','
		<< std::setprecision(3) << p.y
		<< ')';
}

std::ostream &operator<<(std::ostream o, const Rectangle &r) {
	return o << "Rectangle("
		<< std::setprecision(3) << r.left  << ','
		<< std::setprecision(3) << r.top   << ','
		<< std::setprecision(3) << r.right << ','
		<< std::setprecision(3) << r.bottom
		<< ')';
}

std::ostream &operator<<(std::ostream &o, const Color &c) {
	return o << "Color(" << c.r << ',' << c.g << ',' << c.b << ')';
}


void LuaRuntime::exec_str(const char *str) const {
    luaL_dostring(L, str);
}


void LuaRuntime::_register_point() {
	const auto make = [](lua_State *L) {
		float x = luaL_checknumber(L, 1);
		float y = luaL_checknumber(L, 2);

		Vector *p = static_cast<Vector *>(lua_newuserdata(L, sizeof(Vector)));

		p->data[0] = x;
		p->data[1] = y;
		p->data[2] = 0;
		p->data[3] = 0;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);
	
		return 1;
	};

	const auto read = [](lua_State *L) {
		Vector *p = static_cast<Vector *>(luaL_checkudata(L, 1, "point"));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "x") == 0) lua_pushnumber(L, p->data[0]);
		else if (std::strcmp(field, "y") == 0) lua_pushnumber(L, p->data[1]);
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Vector *p = static_cast<Vector *>(luaL_checkudata(L, 1, "point"));

		const char *field = luaL_checkstring(L, 2);
		float value = luaL_checknumber(L, 3);

		if (std::strcmp(field, "x") == 0) p->data[0] = value;
		else if (std::strcmp(field, "y") == 0) p->data[1] = value;
		else luaL_error(L, "invalid field '%s' in point", field);

		return 0;
	};

	const auto add = [](lua_State *L) {
		Vector a = *static_cast<Vector *>(luaL_checkudata(L, 1, "point"));
		Vector b = *static_cast<Vector *>(luaL_checkudata(L, 2, "point"));
		
		Vector *res = static_cast<Vector *>(lua_newuserdata(L, sizeof(Vector)));
		*res = a + b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Vector a = *static_cast<Vector *>(luaL_checkudata(L, 1, "point"));
		Vector b = *static_cast<Vector *>(luaL_checkudata(L, 2, "point"));
		
		Vector *res = static_cast<Vector *>(lua_newuserdata(L, sizeof(Vector)));
		*res = a - b;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto equals = [](lua_State *L) {
		Vector a = *static_cast<Vector *>(luaL_checkudata(L, 1, "point"));
		Vector b = *static_cast<Vector *>(luaL_checkudata(L, 2, "point"));
		
		bool res = a == b;

		lua_pushboolean(L, res);

		return 1;
	};

	const auto distance = [](lua_State *L) {
		Vector *a = static_cast<Vector *>(luaL_checkudata(L, 1, "point"));
		Vector *b = static_cast<Vector *>(luaL_checkudata(L, 2, "point"));
		
		auto d = a->distance(*b);

		lua_pushnumber(L, d);
		return 1;
	};

	luaL_newmetatable(L, "point");

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

	lua_pushcfunction(L, distance);
	lua_setfield(L, -2, "distance");

	lua_pop(L, 1);

	lua_pushcfunction(L, make);
	lua_setglobal(L, "point");}

void LuaRuntime::_register_vector() {
	const auto make = [](lua_State *L) {
		float x = luaL_checknumber(L, 1);
		float y = luaL_checknumber(L, 2);
		float z = luaL_checknumber(L, 3);
		float w = luaL_checknumber(L, 4);

		Vector *p = static_cast<Vector *>(lua_newuserdata(L, sizeof(Vector)));

		p->data[0] = x;
		p->data[1] = y;
		p->data[2] = z;
		p->data[3] = w;

		luaL_getmetatable(L, "vector");
		lua_setmetatable(L, -2);
	
		return 1;
	};

	const auto read = [](lua_State *L) {
		Vector *p = static_cast<Vector *>(luaL_checkudata(L, 1, "vector"));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "x") == 0) lua_pushnumber(L, p->data[0]);
		else if (std::strcmp(field, "y") == 0) lua_pushnumber(L, p->data[1]);
		else if (std::strcmp(field, "z") == 0) lua_pushnumber(L, p->data[2]);
		else if (std::strcmp(field, "w") == 0) lua_pushnumber(L, p->data[3]);
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Vector *p = static_cast<Vector *>(luaL_checkudata(L, 1, "vector"));

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
		Vector a = *static_cast<Vector *>(luaL_checkudata(L, 1, "vector"));
		Vector b = *static_cast<Vector *>(luaL_checkudata(L, 2, "vector"));
		
		Vector *res = static_cast<Vector *>(lua_newuserdata(L, sizeof(Vector)));
		*res = a + b;

		luaL_getmetatable(L, "vector");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Vector a = *static_cast<Vector *>(luaL_checkudata(L, 1, "vector"));
		Vector b = *static_cast<Vector *>(luaL_checkudata(L, 2, "vector"));
		
		Vector *res = static_cast<Vector *>(lua_newuserdata(L, sizeof(Vector)));
		*res = a - b;

		luaL_getmetatable(L, "vector");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto equals = [](lua_State *L) {
		Vector a = *static_cast<Vector *>(luaL_checkudata(L, 1, "vector"));
		Vector b = *static_cast<Vector *>(luaL_checkudata(L, 2, "vector"));
		
		bool res = a == b;

		lua_pushboolean(L, res);

		return 1;
	};

	const auto distance = [](lua_State *L) {
		Vector *a = static_cast<Vector *>(luaL_checkudata(L, 1, "vector"));
		Vector *b = static_cast<Vector *>(luaL_checkudata(L, 2, "vector"));
		
		auto d = a->distance(*b);

		lua_pushnumber(L, d);
		return 1;
	};

	luaL_newmetatable(L, "vector");

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

	lua_pushcfunction(L, distance);
	lua_setfield(L, -2, "distance");

	lua_pop(L, 1);

	lua_pushcfunction(L, make);
	lua_setglobal(L, "vector");
}

void LuaRuntime::_register_lib() {
	_register_vector();
	_register_point();	
}

void LuaRuntime::load_file(std::filesystem::path const &file) {
	if (!std::filesystem::exists(file)) 
		throw std::invalid_argument("file does not exist");

	if (!std::filesystem::is_regular_file(file) || file.extension() != ".lua")
		throw std::invalid_argument("invalid script file");

	if (luaL_dofile(L, file.string().c_str()) != LUA_OK) {
		const char *err_msg = lua_tostring(L, -1);
		lua_pop(L, 1);

		throw std::runtime_error(std::string("failed to load script file '" + file.stem().string() + "': " + err_msg));
	}
}
void LuaRuntime::load_directory(std::filesystem::path const &dir) {}

LuaRuntime::LuaRuntime() {
    L =  luaL_newstate();
	
	luaopen_base(L);
	luaopen_math(L);
	luaopen_string(L);

	_register_lib();
}

LuaRuntime::~LuaRuntime() {
    lua_close(L);
}

};
