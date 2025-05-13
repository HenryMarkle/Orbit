#include <string>
#include <immintrin.h>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <cstring>
#include <stdexcept>
#include <sstream>

#include <Orbit/lua.h>
#include <Orbit/point.h>
#include <Orbit/vector.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

Rectangle Rectangle::operator+(Rectangle const &r) {
	return Rectangle(this->left + r.left, this->top + r.top, this->right + r.right, this->bottom + r.bottom);
}

Rectangle Rectangle::operator-(Rectangle const &r) {
	return Rectangle(this->left - r.left, this->top - r.top, this->right - r.right, this->bottom - r.bottom);
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

void LuaRuntime::_register_lib() {
	_register_vector();
	_register_point();	
	_register_utils();
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

void LuaRuntime::load_directory(std::filesystem::path const &dir) {
	if (!std::filesystem::exists(dir))
		throw std::invalid_argument("directory not found");

	if (!std::filesystem::is_directory(dir))
		throw std::invalid_argument("path is not a directory");

	for (auto &entry : std::filesystem::directory_iterator(dir)) {
		if (!std::filesystem::is_regular_file(entry) || entry.path().extension().string() != ".lua") continue;
	
		load_file(entry.path());
	}
}

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
