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


class LuaRuntime {

private:
    
	lua_State *L;
	
	void _register_point();
	void _register_vector();
	void _register_color();
	void _register_rectangle();
	void _register_quad();

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
