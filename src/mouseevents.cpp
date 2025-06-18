#include <unordered_map>
#include <string>

#include <Orbit/Lua/runtime.h>

#include <raylib.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    // #include <lualib.h>
}

using std::unordered_map;
using std::string;

namespace Orbit::Lua {

void LuaRuntime::_register_mouse_events() {
    static unordered_map<string, int> keys = unordered_map<string, int>({
        { "left", MOUSE_BUTTON_LEFT },
        { "middle", MOUSE_BUTTON_MIDDLE },
        { "right", MOUSE_BUTTON_RIGHT },
    });

    lua_pushcfunction(L, [](lua_State *L) {
        const char *key = lua_tostring(L, 1);
        bool held = lua_toboolean(L, 2);
        
        lua_pushboolean(
            L,
            key != nullptr
                ? (
                    keys.find(key) != keys.end()
                     ?  held ? IsMouseButtonDown(keys[key]) : IsMouseButtonPressed(keys[key])
                     : false
                )
                : false
        );
        
        return 1;
    });
    lua_setglobal(L, "checkMouse");


    lua_pushcfunction(L, [](lua_State *L) {
        auto wheel = GetMouseWheelMove();
        lua_pushinteger(L, wheel);
        return 1;
    });
    lua_setglobal(L, "mouseWheel");


    lua_pushcfunction(L, [](lua_State *L) {
        auto *v = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
        *v = GetMousePosition();;

        luaL_getmetatable(L, "point");
        lua_setmetatable(L, -2);
        return 1;
    });
	lua_setglobal(L, "mousePos");


    lua_pushcfunction(L, [](lua_State *L) {
        auto *v = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
        *v = GetMouseDelta();;

        luaL_getmetatable(L, "point");
        lua_setmetatable(L, -2);
        return 1;
    });
    lua_setglobal(L, "mouseDelta");
}

};