#pragma once

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

class LuaRuntime {

private:

    lua_State *L;

public:

    void exec_str(const char *str) const;

    LuaRuntime &operator=(LuaRuntime const&) = delete;

    LuaRuntime(LuaRuntime const&) = delete;
    LuaRuntime();
    ~LuaRuntime();

};

};