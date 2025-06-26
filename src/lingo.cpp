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
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

using std::unordered_map;
using std::stringstream;
using std::string;

int concat(lua_State *L) {
	string a = luaL_tolstring(L, 1, nullptr);
	string b = luaL_tolstring(L, 2, nullptr);

	lua_pushstring(L, (a + b).c_str());
	return 1;
}

int member_tostring(lua_State *L) {
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

int member_lookup(lua_State *L) {
    int args = lua_gettop(L);
    
    auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
    Orbit::Lua::CastMember *member = nullptr;

    if (lua_isstring(L, 1)) {
        string name(lua_tostring(L, 1));

        if (args == 1 || lua_isnil(L, 2) != 0) {
            auto foundCaseSensitive = runtime->castmembers().find(name);
            
            if (foundCaseSensitive != runtime->castmembers().end()) {
                member = foundCaseSensitive->second.get();
            }
            else {
                for (const auto &lib : runtime->castlibs()) {
                    const auto &found = lib->names().find(name);
                    if (found == lib->names().end()) continue;
                    member = found->second.get();
                    break;
                }
            }
        }
        else if (lua_isinteger(L, 2)) {
            int libindex = lua_tointeger(L, 2);

            if (libindex > 0 && libindex <= runtime->castlibs().size()) {
                const auto &lib = runtime->castlibs()[libindex - 1];
                
                auto found = lib->names().find(name);
                
                if (found != lib->names().end()) {
                    member = found->second.get();
                }
            }
        }
        else if (lua_isstring(L, 2)) {
            const char *libname = lua_tostring(L, 2);
            auto libfound = runtime->castlib_names().find(libname);
        
            if (libfound != runtime->castlib_names().end()) {
                auto found = libfound->second->names().find(name);
                
                if (found != libfound->second->names().end()) {
                    member = found->second.get();
                }
            }
        }
    }
    else if (lua_isinteger(L, 1)) {
        int index = lua_tointeger(L, 1);

        if (args == 1 || lua_isnil(L, 2)) {
            for (const auto &lib : runtime->castlibs()) {
                const auto &found = lib->find(index);
                member = found.get();
                break;
            }
        }
        else if (lua_isinteger(L, 2)) {
            int libindex = lua_tointeger(L, 2);

            if (libindex > 0 && libindex <= runtime->castlibs().size()) {
                const auto &lib = runtime->castlibs()[libindex - 1];
                auto found = lib->find(index);
                member = found.get();
            }
        }
        else if (lua_isstring(L, 2)) {
            const char *libname = lua_tostring(L, 2);
            auto libfound = runtime->castlib_names().find(libname);
        
            if (libfound != runtime->castlib_names().end()) {
                auto found = libfound->second->find(index);
                member = found.get();
            }
        }
    }

    if (member) {
        auto path = member->path.string();

        lua_newtable(L);

        lua_pushstring(L, "number");
        lua_pushinteger(L, member->id);
        lua_settable(L, -3);

        lua_pushstring(L, "name");
        lua_pushstring(L, member->name.c_str());
        lua_settable(L, -3);
        
        lua_pushstring(L, "path");
        lua_pushstring(L, path.c_str());
        lua_settable(L, -3);

        lua_pushlightuserdata(L, runtime);
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
                auto str = buffer.str();

                lua_pushstring(L2, str.c_str());
                lua_setfield(L2, -3, "text");
            }
            else if (path.extension() == ".png") {
                lua_getfield(L2, -2, "image");
                
                Image *image = static_cast<Image *>(luaL_testudata(L2, -1, "image"));
                if (image) {
                    UnloadImage(*image);
                }
                else {
                    image = static_cast<Image *>(lua_newuserdata(L2, sizeof(Image)));
                }

                *image = LoadImage(path.string().c_str());

                lua_pop(L2, -1);
            }

            return 0;
        }, 1);
        lua_setfield(L, -2, "importFileInto");

        if (member->path.extension() == ".png") {
            lua_pushstring(L, "image");
            
            Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
            *img = LoadImage(member->path.string().c_str());
        
            luaL_getmetatable(L, "image");
            lua_setmetatable(L, -2);

            lua_settable(L, -3);
        }
        else if (member->path.extension() == ".txt") {
            std::ifstream file(member->path);
            if (!file) {
                runtime->logger->error("[runtime] failed to open cast member file {FILE}", member->path.string());
                
                lua_pushnil(L);
                return 1;
            }

            stringstream buffer;
            buffer << file.rdbuf();
            auto text = buffer.str();

            lua_pushstring(L, "text");
            lua_pushstring(L, text.c_str());
            lua_settable(L, -3);
        }

        lua_newtable(L);
        lua_pushcfunction(L, member_tostring);
        lua_setfield(L, -2, "__tostring");

        lua_pushcfunction(L, concat);
        lua_setfield(L, -2, "__concat");
        lua_setmetatable(L, -2);
    }
    else lua_pushnil(L);

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

    lua_pushcfunction(L, [](lua_State *L) {
        lua_getglobal(L, "_G");

        lua_pushnil(L);
        while (lua_next(L, -2)) {
            if (lua_type(L, -2) == LUA_TSTRING) {
                const char* key = lua_tostring(L, -2);

                if (
                    strcmp(key, "_G") == 0 || 
                    strcmp(key, "_VERSION") == 0 ||
                    strcmp(key, "_system") == 0 ||
                    strcmp(key, "_movie") == 0 ||
                    strcmp(key, "_global") == 0 ||
                    strcmp(key, "_mouse") == 0 ||
                    strcmp(key, "_key") == 0
                ) {
                    lua_pop(L, 1);
                    continue;
                }

                int type = lua_type(L, -1);
                lua_pop(L, 1);

                if (type == LUA_TNUMBER) {
                    lua_pushnumber(L, 0);
                } else if (type == LUA_TSTRING) {
                    lua_pushstring(L, "");
                } else if (type == LUA_TBOOLEAN) {
                    lua_pushboolean(L, 0);
                } else if (type == LUA_TTABLE) {
                    lua_newtable(L);
                } else if (type == LUA_TFUNCTION || type == LUA_TTHREAD || type == LUA_TUSERDATA || type == LUA_TLIGHTUSERDATA) {
                    lua_pushnil(L);
                } else {
                    lua_pushnil(L);
                }

                lua_setglobal(L, key);
            } else {
                lua_pop(L, 1);
            }
        }
        lua_pop(L, 1);

        return 0;
    });
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

    std::string moviePath(paths->executable().string());
    lua_pushstring(L, moviePath.c_str());
    lua_setfield(L, -2, "path");

    { // window
        lua_pushstring(L, "window");
        lua_newtable(L);
        
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

            lua_pushstring(L, lib->name().c_str());
            lua_pushstring(L,"name");
            lua_settable(L, -3);
            
            lua_pushinteger(L, lib->offset());
            lua_pushstring(L, "number");
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

                if (mem->path.extension() == ".png") {
                    lua_pushstring(L, "image");

                    Image *nimg = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
                    *nimg = LoadImage(mem->path.string().c_str());

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
                    auto text = buffer.str();

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

            auto found = runtime->castlib_names().find(castLibName);
            
            if (found == runtime->castlib_names().end()) {
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
    lua_setfield(L, -2, "keypressed");

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
    lua_setfield(L, -2, "keyDown");

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

    

    lua_pushlightuserdata(L, this);
    lua_pushcclosure(L, member_lookup, 1);
    lua_setglobal(L, "member");
}

};