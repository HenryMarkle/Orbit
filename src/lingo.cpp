#include <Orbit/Lua/runtime.h>

#include <unordered_map>
#include <cstring>
#include <iostream>
#include <sstream>
#include <fstream>
#include <string>
#include <chrono>

#include <raylib.h>

extern "C" {
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

using std::unordered_map;
using std::stringstream;
using std::string;

static std::string normalize_line_endings(const std::string& input) {
    std::string output;
    size_t len = input.length();
    for (size_t i = 0; i < len; ++i) {
        if (input[i] == '\r') {
            if (i + 1 < len && input[i + 1] == '\n') {
                // Windows CRLF (\r\n) — keep as is or convert to \n
                ++i;  // Skip \n
            }
            output += '\n'; // Convert \r or \r\n to \n
        } else {
            output += input[i];
        }
    }
    return output;
}

static int concat(lua_State *L) {
	size_t len1, len2;

    const char* a = lua_tolstring(L, 1, &len1);
    const char* b = lua_tolstring(L, 2, &len2);

    std::string result = std::string(a, len1) + std::string(b, len2);

    lua_pop(L, 2);  // Pop the two strings created by luaL_tolstring
    lua_pushstring(L, result.c_str());
    return 1;
}

static int member_tostring(lua_State *L) {
    int tableindex = lua_gettop(L);

    stringstream ss;

    ss << "member(";
        
    lua_getfield(L, tableindex, "name");
    if (!lua_isnil(L, -1)) {
        const char *name = lua_tostring(L, -1);
        ss << '"' << name << '"';
    }
    lua_pop(L, 1);

    ss << ')';
    auto str = ss.str();

    lua_pushstring(L, str.c_str());
    
    return 1;
}

static int member_lookup(lua_State *L) {
    int args = lua_gettop(L);
    
    auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
    Orbit::Lua::CastMember *member = nullptr;

    if (lua_isstring(L, 1)) {
        string name(lua_tostring(L, 1));

        if (args == 1 || lua_isnil(L, 2) != 0) {
            auto foundCaseSensitive = runtime->GetCastMembers().find(name);
            
            if (foundCaseSensitive != runtime->GetCastMembers().end()) {
                member = foundCaseSensitive->second.get();
            }
            else {
                for (const auto &lib : runtime->GetCastLibs()) {
                    const auto &found = lib->names().find(name);
                    if (found == lib->names().end()) continue;
                    member = found->second.get();
                    break;
                }
            }
        }
        else if (lua_type(L, 2) == LUA_TNUMBER) {
            int libindex = lua_tointeger(L, 2);

            if (libindex > 0 && libindex <= runtime->GetCastLibs().size()) {
                const auto &lib = runtime->GetCastLibs()[libindex - 1];
                
                auto found = lib->names().find(name);
                
                if (found != lib->names().end()) {
                    member = found->second.get();
                }
            }
        }
        else if (lua_isstring(L, 2)) {
            const char *libname = lua_tostring(L, 2);
            auto libfound = runtime->GetCastLibNames().find(libname);
        
            if (libfound != runtime->GetCastLibNames().end()) {
                auto found = libfound->second->names().find(name);
                
                if (found != libfound->second->names().end()) {
                    member = found->second.get();
                }
            }
        }
    }
    else if (lua_type(L, 1) == LUA_TNUMBER) {
        int index = lua_tointeger(L, 1);

        if (args == 1 || lua_isnil(L, 2)) {
            for (const auto &lib : runtime->GetCastLibs()) {
                const auto &found = lib->find(index);
                member = found.get();
                break;
            }
        }
        else if (lua_type(L, 2) == LUA_TNUMBER) {
            int libindex = lua_tointeger(L, 2);

            if (libindex > 0 && libindex <= runtime->GetCastLibs().size()) {
                const auto &lib = runtime->GetCastLibs()[libindex - 1];
                auto found = lib->find(index);
                member = found.get();
            }
        }
        else if (lua_isstring(L, 2)) {
            const char *libname = lua_tostring(L, 2);
            auto libfound = runtime->GetCastLibNames().find(libname);
        
            if (libfound != runtime->GetCastLibNames().end()) {
                auto found = libfound->second->find(index);
                member = found.get();
            }
        }
    }

    if (member) {
        
        lua_getglobal(L, "_movie");
        lua_getfield(L, -1, "castLib");
        
        lua_remove(L, -2);
        
        lua_getfield(L, -1, member->library.c_str());
        
        lua_remove(L, -2);
        
        lua_getfield(L, -1, "member");
        
        lua_remove(L, -2);
        
        lua_getfield(L, -1, member->name.c_str());

        return 1;
    }

    
    else lua_pushnil(L);

    return 1;
}

static int castLib_lookup(lua_State *L) {
    auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

    lua_getglobal(L, "_movie");
    lua_getfield(L, -1, "castLib");
    lua_remove(L, -2);

    if (lua_type(L, 1) == LUA_TNUMBER) {

        int index = lua_tointeger(L, 1);

        if (index < 1 || index > runtime->GetCastLibs().size()) {
            lua_pushnil(L);
            return 1;
        }

        const auto &lib = runtime->GetCastLibs()[index-1];

        lua_getfield(L, -1, lib->name().c_str());
        lua_remove(L, -2);

        return 1;
    } else if (lua_isstring(L, 1)) {

        const char *name = lua_tostring(L, 1);

        lua_getfield(L, -1, name);

        lua_remove(L, -2);

        return 1;
    }

    lua_pop(L, 1);

    lua_pushnil(L);
    return 1;
}

static int string_offset(lua_State *L) {
    // Check and get arguments from Lua stack
    const char* s = luaL_checkstring(L, 1);
    const char* sub = luaL_checkstring(L, 2);

    const char* found = strstr(s, sub);
    if (found) {
        // Calculate 1-based index
        int index = static_cast<int>(found - s) + 1;
        lua_pushinteger(L, index);
    } else {
        lua_pushinteger(L, 0);
    }

    return 1;
}

namespace Orbit::Lua {

void LuaRuntime::_register_lingo_api() {
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

    static unordered_map<string, int> buttons = unordered_map<string, int>({
        { "left", MOUSE_BUTTON_LEFT },
        { "middle", MOUSE_BUTTON_MIDDLE },
        { "right", MOUSE_BUTTON_RIGHT },
    });

    lua_newtable(L);

    lua_pushlightuserdata(L, this);
    lua_pushcclosure(L, [](lua_State *L) {
        auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
    
        lua_getglobal(L, "_G");
        
        // Collect keys to remove
        std::vector<std::string> keys_to_remove;
        
        lua_pushnil(L);
        while (lua_next(L, -2)) {
            if (lua_type(L, -2) == LUA_TSTRING) {
                const char* key = lua_tostring(L, -2);
                if (runtime->globals_snapshot.find(key) == runtime->globals_snapshot.end()) {
                    keys_to_remove.push_back(key);
                }
            }
            lua_pop(L, 1);
        }
        
        // Remove the keys
        for (const auto& key : keys_to_remove) {
            lua_pushnil(L);
            lua_setfield(L, -2, key.c_str());
        }
        
        lua_pop(L, 1); // pop _G
        return 0;
    }, 1);
    lua_setfield(L, -2, "clearGlobals");
    
    lua_newtable(L);
    lua_pushcfunction(L, [](lua_State *L){
        lua_pushstring(L, "_global");
        return 1;
    });
    lua_setfield(L, -2, "__tostring");
    
    lua_pushcfunction(L, concat);
    lua_setfield(L, -2, "__concat");

    lua_setmetatable(L, -2);

    lua_setglobal(L, "_global");

    // _movie

    lua_newtable(L);

    std::string moviePath(paths->data().string());
    #ifdef _WIN32
        moviePath += "\\";
    #else
        moviePath += "/";
    #endif
    lua_pushstring(L, moviePath.c_str());
    lua_setfield(L, -2, "path");

    { // window
        lua_pushstring(L, "window");
        lua_newtable(L);

        lua_newtable(L);
        lua_setfield(L, -2, "appearanceOptions");
        
        lua_newtable(L);

        lua_pushcfunction(L, [](lua_State *L) {
            const char *field = luaL_checkstring(L, 2);
        
            if (std::strcmp(field, "sizeState") == 0) {
                if (IsWindowMinimized()) lua_pushstring(L, "minimized");
                else lua_pushstring(L, "");
            } else lua_pushnil(L);

            return 1;
        });
        lua_setfield(L, -2, "__index");
        lua_setmetatable(L, -2);
        
        lua_settable(L, -3);
    }

    { // castLib
        lua_pushstring(L, "castLib");
        lua_newtable(L);

        for (const auto &lib : _castlibs) {
            lua_pushstring(L, lib->name().c_str());
            lua_newtable(L);

            lua_pushstring(L,"name");
            lua_pushstring(L, lib->name().c_str());
            lua_settable(L, -3);
            
            lua_pushstring(L, "number");
            lua_pushinteger(L, lib->offset());
            lua_settable(L, -3);

            lua_pushstring(L, "eraseMembers");
            lua_pushcfunction(L, [](lua_State *LL) {
                lua_getfield(LL, 1, "member");
                if (!lua_istable(LL, -1)) {
                    lua_pop(LL, 1);
                    return 0;
                }

                int memberIndex = lua_gettop(LL);
                lua_pushnil(LL); 
                while (lua_next(LL, memberIndex) != 0) {
                    lua_pop(LL, 1); 
                    lua_pushvalue(LL, -1);  
                    lua_pushnil(LL);
                    lua_settable(LL, memberIndex); 
                }

                lua_pop(LL, 1); 
                return 0;
            });
            lua_settable(L, -3);

            lua_pushstring(L, "member");
            lua_newtable(L);
            for (const auto &mem : lib->members()) {
                lua_pushstring(L, mem->name.c_str());
                lua_newtable(L);
                
                lua_pushstring(L, "name");
                lua_pushstring(L, mem->name.c_str());
                lua_settable(L, -3);
                
                lua_pushstring(L, "number");
                lua_pushinteger(L, mem->id);
                lua_settable(L, -3);

                lua_pushlightuserdata(L, this);
                lua_pushcclosure(L, [](lua_State *L2) {
                    const char *p = lua_tostring(L2, 2);
                    auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L2, lua_upvalueindex(1)));
                    
                    auto path = runtime->paths->data() / p;

                    if (!std::filesystem::exists(path)) return 0;

                    if (path.extension() == ".txt") {
                        std::ifstream file(path);
                        if (!file) {
                            runtime->logger->error("[runtime] failed to open cast member file {FILE}", path.string());
                            return 0;
                        }

                        stringstream buffer;
                        buffer << file.rdbuf();
                        auto str = normalize_line_endings(buffer.str());

                        lua_pushstring(L2, str.c_str());
                        lua_setfield(L2, 1, "text");
                    }
                    else if (path.extension() == ".png") {
                        lua_getfield(L2, -2, "image");
                        
                        RenderTexture2D *image = static_cast<RenderTexture2D *>(luaL_testudata(L2, -1, "image"));
                        if (image) {
                            UnloadRenderTexture(*image);
                            // UnloadTexture(*image);
                        }
                        else {
                            image = static_cast<RenderTexture2D *>(lua_newuserdata(L2, sizeof(RenderTexture2D)));
                        }

                        // *image = LoadImage(path.string().c_str());
                        auto t = LoadTexture(path.string().c_str());

                        *image = LoadRenderTexture(t.width, t.height);
                        
                        BeginTextureMode(*image);
                        ClearBackground(WHITE);
                        DrawTexturePro(
                            t, 
                            { 0, 0, static_cast<float>(t.width), -static_cast<float>(t.height) }, 
                            { 0, 0, static_cast<float>(t.width),  static_cast<float>(t.height) }, 
                            { 0, 0 }, 
                            0, 
                            WHITE
                        );
                        EndTextureMode();

                        UnloadTexture(t);

                        lua_pop(L2, 1);
                    }

                    return 0;
                }, 1);
                lua_setfield(L, -2, "importFileInto");

                if (mem->path.extension() == ".png") {
                    lua_pushstring(L, "image");

                    RenderTexture2D *nimg = static_cast<RenderTexture2D *>(lua_newuserdata(L, sizeof(RenderTexture2D)));
                    auto t = LoadTexture(mem->path.string().c_str());

                    *nimg = LoadRenderTexture(t.width, t.height);
                        
                    BeginTextureMode(*nimg);
                    ClearBackground(WHITE);
                    DrawTexturePro(
                        t, 
                        { 0, 0, static_cast<float>(t.width), -static_cast<float>(t.height) }, 
                        { 0, 0, static_cast<float>(t.width),  static_cast<float>(t.height) }, 
                        { 0, 0 }, 
                        0, 
                        WHITE
                    );
                    EndTextureMode();

                    UnloadTexture(t);

                    luaL_getmetatable(L, "image");
                    lua_setmetatable(L, -2);

                    lua_settable(L, -3);
                }
                else if (mem->path.extension() == ".txt") {
                    std::ifstream file(mem->path);
                    if (!file) {
                        throw std::runtime_error("failed to load member file: " + mem->path.string());
                    }

                    
                    std::stringstream buffer;
                    buffer << file.rdbuf();
                    auto text = normalize_line_endings(buffer.str());

                    // std::replace(text.begin(), text.end(), '\r', '\n');

                    lua_pushstring(L, "text");
                    lua_pushstring(L, text.c_str());
                    lua_settable(L, -3);
                }

                lua_settable(L, -3);
            }
            lua_settable(L, -3);            
            lua_settable(L, -3);            
        }

        lua_newtable(L);
        lua_pushlightuserdata(L, this);
        lua_pushcclosure(L, [](lua_State *L){
            const char *castLibName = luaL_checkstring(L, 2);

            auto* runtime = static_cast<LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));

            auto found = runtime->GetCastLibNames().find(castLibName);
            
            if (found == runtime->GetCastLibNames().end()) {
                lua_pushnil(L);
                return 1;
            }

            auto &lib = found->second;



            return 1;
        }, 1);
        lua_setfield(L, -2, "__index");
        lua_setmetatable(L, -2);

        lua_settable(L, -3);
    }
    
    lua_newtable(L);
    lua_pushcfunction(L, [](lua_State *L){
        lua_pushstring(L, "_movie");
        return 1;
    });
    lua_setfield(L, -2, "__tostring");
    
    lua_pushcfunction(L, concat);
    lua_setfield(L, -2, "__concat");

    lua_pushcfunction(L, [](lua_State *L) {
        const char *field = luaL_checkstring(L, 2);
        
        if (std::strcmp(field, "frame") == 0) {
            lua_pushinteger(L, 0);
        }
        else if (std::strcmp(field, "go") == 0) {
            lua_pushcfunction(L, [](lua_State *L) { return 0; });
        }
        else lua_pushnil(L);
        return 1;
    });
    lua_setfield(L, -2, "__index");

    lua_setmetatable(L, -2);

    lua_setglobal(L, "_movie");

    //

    lua_newtable(L);

    lua_pushstring(L, "appMinimize");
    lua_pushcfunction(L, [](lua_State *) {
        MinimizeWindow();
        return 0;
    });
    lua_settable(L, -3);
    
    lua_pushstring(L, "quit");
    lua_pushlightuserdata(L, this);
    lua_pushcclosure(L, [](lua_State *L) {
        auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
        runtime->Quit();
        return 0;
    }, 1);
    lua_settable(L, -3);
    
    lua_pushstring(L, "alert");
    lua_pushcfunction(L, [](lua_State *) {
        return 0;
    });
    lua_settable(L, -3);
    
    lua_newtable(L);
    lua_pushcfunction(L, [](lua_State *L){
        lua_pushstring(L, "_player");
        return 1;
    });
    lua_setfield(L, -2, "__tostring");
    
    lua_pushcfunction(L, concat);
    lua_setfield(L, -2, "__concat");

    lua_setmetatable(L, -2);

    lua_setglobal(L, "_player");

    //

    lua_newtable(L);

    lua_pushstring(L, "keyPressed");
    lua_pushcfunction(L, [](lua_State *L) {
        if (lua_isstring(L, 1)) {
            const char *k = lua_tostring(L, 1);
    
            lua_pushboolean(
                L, 
                k != nullptr 
                    ? (
                        keys.find(k) != keys.end() 
                            ? IsKeyPressed(keys[k])
                            : false
                        ) 
                    : false
            );
        }
        else {
            int code = lua_tointeger(L, 1);

            lua_pushboolean(L, IsKeyPressed(code));
        }
        return 1;
    });
    lua_settable(L, -3);

    lua_pushstring(L, "keyDown");
    lua_pushcfunction(L, [](lua_State *L) {
        if (lua_isstring(L, 1)) {
            const char *k = lua_tostring(L, 1);
    
            lua_pushboolean(
                L, 
                k != nullptr 
                    ? (
                        keys.find(k) != keys.end() 
                            ? IsKeyDown(keys[k])
                            : false
                        ) 
                    : false
            );
        }
        else {
            int code = lua_tointeger(L, 1);

            lua_pushboolean(L, IsKeyDown(code));
        }
        return 1;
    });
    lua_settable(L, -3);

    lua_newtable(L);
    lua_pushcfunction(L, [](lua_State *L){
        lua_pushstring(L, "_key");
        return 1;
    });
    lua_setfield(L, -2, "__tostring");
    
    lua_pushcfunction(L, concat);
    lua_setfield(L, -2, "__concat");

    lua_setmetatable(L, -2);

    lua_setglobal(L, "_key");

    //

    lua_newtable(L);

    lua_pushcfunction(L, [](lua_State *L) {
        lua_pushboolean(
            L, 
            IsMouseButtonDown(MOUSE_BUTTON_LEFT) || 
            IsMouseButtonDown(MOUSE_BUTTON_RIGHT)
        );
        
        return 1;
    });
    lua_setfield(L, -2, "mouseDown");
    
    lua_pushcfunction(L, [](lua_State *L) {
        lua_pushboolean(
            L, 
            IsMouseButtonDown(MOUSE_BUTTON_RIGHT)
        );
        
        return 1;
    });
    lua_setfield(L, -2, "rightmouseDown");
    
    lua_pushcfunction(L, [](lua_State *L) {
        lua_pushboolean(
            L, 
            IsMouseButtonDown(MOUSE_BUTTON_LEFT)
        );
        
        return 1;
    });
    lua_setfield(L, -2, "leftmouseDown");
    
    lua_newtable(L);
    lua_pushcfunction(L, [](lua_State *L){
        lua_pushstring(L, "_mouse");
        return 1;
    });
    lua_setfield(L, -2, "__tostring");
    
    lua_pushcfunction(L, concat);
    lua_setfield(L, -2, "__concat");

    lua_pushcfunction(L, [](lua_State *L) {
        const char *field = luaL_checkstring(L, 2);
        
        if (std::strcmp(field, "mouseLoc") == 0) {
            auto pos = GetMousePosition();

            Vector2 *ptr = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

            ptr->x = pos.x;
            ptr->y = pos.y;

            luaL_getmetatable(L, "point");
            lua_setmetatable(L, -2);

        }
        else lua_pushnil(L);
        return 1;
    });
    lua_setfield(L, -2, "__index");

    lua_setmetatable(L, -2);

    lua_setglobal(L, "_mouse");
    
    //

    lua_newtable(L);
    lua_pushcfunction(L, [](lua_State *L){
        lua_pushstring(L, "_system");
        return 1;
    });
    lua_setfield(L, -2, "__tostring");
    
    lua_pushcfunction(L, concat);
    lua_setfield(L, -2, "__concat");

    lua_pushcfunction(L, [](lua_State *L) {
        const char *field = luaL_checkstring(L, 2);
        
        if (std::strcmp(field, "milliseconds") == 0) {
            auto now = std::chrono::high_resolution_clock::now();

            lua_pushnumber(L, std::chrono::duration_cast<std::chrono::milliseconds>(
                now.time_since_epoch()
            ).count());
        }
        else if (std::strcmp(field, "deskTopRectList") == 0) {
            Vector2 *ptr = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

            ptr->x = 1024.0f;
            ptr->y = 768.0f;

            luaL_getmetatable(L, "point");
            lua_setmetatable(L, -2);
        }
        else lua_pushnil(L);

        return 1;
    });
    lua_setfield(L, -2, "__index");

    lua_setmetatable(L, -2);

    lua_setglobal(L, "_system");

    //

    lua_pushboolean(L, 0);
    lua_setglobal(L, "FALSE");

    lua_pushboolean(L, 1);
    lua_setglobal(L, "TRUE");

    lua_pushstring(L, "\n");
    lua_setglobal(L, "RETURN");

    lua_pushnil(L);
    lua_setglobal(L, "VOID");

    #ifdef _WIN32
    lua_pushstring(L, "\\");
    #else
    lua_pushstring(L, "/");
    #endif
    lua_setglobal(L, "dirSeparator");

    lua_pushlightuserdata(L, this);
    lua_pushcclosure(L, member_lookup, 1);
    lua_setglobal(L, "member");

    lua_pushlightuserdata(L, this);
    lua_pushcclosure(L, castLib_lookup, 1);
    lua_setglobal(L, "castLib");
\
    lua_pushstring(L, moviePath.c_str());
    lua_setglobal(L, "moviePath");

    lua_pushcfunction(L, string_offset);
    lua_setglobal(L, "offset");

    lua_pushcfunction(L, [](lua_State *L) {
        lua_newtable(L);
        return 1;
    });
    lua_setglobal(L, "sprite");

    lua_pushinteger(L, this->random.seed);
    lua_setglobal(L, "randomSeed");
}

};