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

std::ostream &operator<<(std::ostream &, const Color &);

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
