#include <string>

#include <Orbit/Lua/runtime.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    // #include <lualib.h>
}

using std::string;

int global_xtra(lua_State *L) {
    const string name(luaL_checkstring(L, 1));

    lua_newtable(L);

    if (name == "fileio") {
        lua_pushcfunction(L, [](lua_State *L2) {
            return 0;
        });
        lua_setfield(L, -2, "openFile");
        lua_settable(L, -3);

        lua_pushcfunction(L, [](lua_State *L2) {
            return 0;
        });
        lua_setfield(L, -2, "writeString");
        lua_settable(L, -3);

        lua_pushcfunction(L, [](lua_State *L2) {
            return 0;
        });
        lua_setfield(L, -2, "closeFile");
        lua_settable(L, -3);
    }
    else if (name == "ImgXtra") {
        lua_pushcfunction(L, [](lua_State *L2) {
            return 0;
        });
        lua_setfield(L, -2, "ix_saveImage");
        lua_settable(L, -3);
    }

    return 1;
}

namespace Orbit::Lua {

void LuaRuntime::_register_xtra() {
    lua_pushcfunction(L, global_xtra);
    lua_setglobal(L, "xtra");
}

};