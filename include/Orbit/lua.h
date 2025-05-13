#pragma once

#include <iostream>
#include <immintrin.h>
#include <filesystem>
#include <string>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

struct Color {
	short r, g, b;

	inline Color() : r(0), g(0), b(0) {}
	inline Color(short r, short g, short b) : r(r), g(g), b(b) {}
};

struct Rectangle {
	float left, top, right, bottom;

	Rectangle operator+(Rectangle const &);
	Rectangle operator-(Rectangle const &);

	inline Rectangle() : left(0), top(0), right(0), bottom(0) {}
	inline Rectangle(float left, float top, float right, float bottom) : left(left), top(top), right(right), bottom(bottom) {}
};

std::ostream &operator<<(std::ostream &, const Color &);
std::ostream &operator<<(std::ostream &, const Rectangle &);

class LuaRuntime {

private:
    
	lua_State *L;
	
	void _register_point();
	void _register_vector();
	void _register_color();
	void _register_rectangle();

	void _register_utils();

	void _register_image();
	void _register_member();

	void _register_lib();

public:

    void load_file(std::filesystem::path const &);
	void load_directory(std::filesystem::path const &);

    LuaRuntime &operator=(LuaRuntime const&) = delete;

    LuaRuntime(LuaRuntime const&) = delete;
    LuaRuntime();
    ~LuaRuntime();

};

};
