#include <unordered_map>
#include <string>

#include <Orbit/Lua/runtime.h>

#include <raylib.h>

extern "C" {
    #include <lua.h>
    // #include <lauxlib.h>
    // #include <lualib.h>
}

using std::unordered_map;
using std::string;

namespace Orbit::Lua {

void LuaRuntime::_register_keyboard_events() {
    static unordered_map<string, int> keys = unordered_map<string, int>({
        { "", KEY_NULL },

        { "'", KEY_APOSTROPHE },
        { ",", KEY_COMMA },
        { "-", KEY_MINUS },
        { ".", KEY_PERIOD },
        { "/", KEY_SLASH },
        { ";", KEY_SEMICOLON },
        { "=", KEY_EQUAL },
        { "[", KEY_LEFT_BRACKET },
        { "\\", KEY_BACKSLASH },
        { "]", KEY_RIGHT_BRACKET },
        { "`", KEY_GRAVE },

        { "0", KEY_ZERO },
        { "1", KEY_ONE },
        { "2", KEY_TWO },
        { "3", KEY_THREE },
        { "4", KEY_FOUR },
        { "5", KEY_FIVE },
        { "6", KEY_SIX },
        { "7", KEY_SEVEN },
        { "8", KEY_EIGHT },
        { "9", KEY_NINE },

        { "a", KEY_A },
        { "b", KEY_B },
        { "c", KEY_C },
        { "d", KEY_D },
        { "e", KEY_E },
        { "f", KEY_F },
        { "g", KEY_G },
        { "h", KEY_H },
        { "i", KEY_I },
        { "j", KEY_J },
        { "k", KEY_K },
        { "l", KEY_L },
        { "m", KEY_M },
        { "n", KEY_N },
        { "o", KEY_O },
        { "p", KEY_P },
        { "q", KEY_Q },
        { "r", KEY_R },
        { "s", KEY_S },
        { "t", KEY_T },
        { "u", KEY_U },
        { "v", KEY_V },
        { "w", KEY_W },
        { "x", KEY_X },
        { "y", KEY_Y },
        { "z", KEY_Z },

        { "space", KEY_SPACE },
        { "escape", KEY_ESCAPE },
        { "enter", KEY_ENTER },
        { "tab", KEY_TAB },
        { "backspace", KEY_BACKSPACE },
        { "insert", KEY_INSERT },
        { "delete", KEY_DELETE },
        { "right", KEY_RIGHT },
        { "left", KEY_LEFT },
        { "down", KEY_DOWN },
        { "up", KEY_UP },
        { "page up", KEY_PAGE_UP },
        { "page down", KEY_PAGE_DOWN },
        { "home", KEY_HOME },
        { "end", KEY_END },
        { "caps lock", KEY_CAPS_LOCK },
        { "scroll lock", KEY_SCROLL_LOCK },
        { "num lock", KEY_NUM_LOCK },
        { "print screen", KEY_PRINT_SCREEN },
        { "pause", KEY_PAUSE },
        { "shift", KEY_LEFT_SHIFT },
        { "control", KEY_LEFT_CONTROL },
        { "alt", KEY_LEFT_ALT },
        { "super", KEY_LEFT_SUPER },
    });

    lua_pushcfunction(L, [](lua_State *L) {
        const char *k = lua_tostring(L, 1);
        bool held = lua_toboolean(L, 2);

        lua_pushboolean(
            L, 
            k != nullptr 
                ? (
                    keys.find(k) != keys.end() 
                        ? held ? IsKeyDown(keys[k]) : IsKeyPressed(keys[k]) 
                        : false
                    ) 
                : false
        );
        return 1;
    });
    lua_setglobal(L, "checkKey");
}

};