#include <Orbit/lua.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

int l_double(lua_State* L) {
    int n = luaL_checkinteger(L, 1);
    lua_pushinteger(L, n * 2);
    
    return 1;
}

namespace Orbit::Lua {

void LuaRuntime::exec_str(const char *str) const {
    luaL_dostring(L, str);
}

LuaRuntime::LuaRuntime() {
    L =  luaL_newstate();
    luaL_openlibs(L);

    lua_register(L, "double", l_double);
}

LuaRuntime::~LuaRuntime() {
    lua_close(L);
}

};