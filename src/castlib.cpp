#include <Orbit/Lua/castlib.h>
#include <Orbit/Lua/runtime.h>
#include <Orbit/hash.h>

#include <filesystem>
#include <iostream>
#include <sstream>
#include <fstream>
#include <cstring>
#include <vector>
#include <memory>
#include <regex>

#include <raylib.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

using std::unordered_map;
using std::shared_ptr;
using std::unique_ptr;
using std::stringstream;
using std::string;
using std::vector;
using std::move;

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

int member_concat(lua_State *L) {
	std::string a = luaL_tolstring(L, 1, nullptr);
	std::string b = luaL_tolstring(L, 2, nullptr);

	lua_pushstring(L, (a + b).c_str());
	return 1;
}

namespace Orbit::Lua {

// void CastMember::load() {
//     if (_loaded) return;
    
//     _image = LoadImage(_path.string().c_str());

//     _loaded = true;
// }

// void CastMember::unload() {
//     if (!_loaded) return;
//     UnloadImage(_image);
//     _loaded = false;
// }

CastMember &CastMember::operator=(CastMember &&other) noexcept {
    if (this == &other) return *this;

    _name = move(other._name);
    _path = move(other._path);
    
    _id = other._id;
    // _loaded = other._loaded;
    
    other._id = 0;
    // other._loaded = false;

    return *this;
}

CastMember::CastMember(CastMember &&other) noexcept {
    _name = move(other._name);
    _path = move(other._path);
    
    _id = other._id;
    // _loaded = other._loaded;
    
    other._id = 0;
    // other._loaded = false;
}
CastMember::CastMember(const std::filesystem::path &path) : _path(path) {
    // i.e. Drought_1233436_rock.png

    if (!std::regex_match(path.filename().string(), CAST_MEMBER_NAME_PATTERN)) {
        throw std::invalid_argument(string("invalid cast member ")+path.filename().string());
    }

    auto stem = path.stem().string();
    std::stringstream id_ss, name_ss;
    int count = 0, index = 0;
    for (auto c : stem) {

        if (c == '_') {
            count++;
            continue;
        }

        if (count == 1) {
            id_ss << c;    
        } else if (count == 2) {
            name_ss << c;
        }

        index++;
    }

    _id = std::stoi(id_ss.str());
    _name = name_ss.str();
}
CastMember::CastMember(int, const string &, const std::filesystem::path &, Image) {}

CastMember::~CastMember() {
    // unload();
}

std::shared_ptr<CastMember> CastLib::find(const std::string &name) { return _names[name]; }
std::shared_ptr<CastMember> CastLib::find(int index) {
    if (index > 0 && index < _members.size()) return _members[index];

    auto offseted = index - _offset;
    if (offseted > 0 && offseted < _members.size()) return _members[offseted];

    return nullptr;
}

shared_ptr<CastMember> CastLib::operator[](const string &name) { return _names[name]; }
shared_ptr<CastMember> CastLib::operator[](int index) {
    if (index > 0 && index < _members.size()) return _members[index];

    auto offseted = index - _offset;
    if (offseted > 0 && offseted < _members.size()) return _members[offseted];

    return nullptr;
}

CastLib &CastLib::operator=(CastLib &&other) noexcept {
    if (this == &other) return *this;

    _name = move(other._name);
    _members = move(other._members);

    _offset = other._offset;

    other._offset = 0;

    return *this;
}
void CastLib::load_members(const std::filesystem::path &dir) {
    if (!std::filesystem::is_directory(dir)) {
        throw std::invalid_argument("path is not a direcotry: " + dir.string());
    }

    _members.reserve(10000);
    _names.reserve(10000 + 500);

    const char *name = _name.c_str();

    for (auto &entry : std::filesystem::directory_iterator(dir)) {
        const auto &path = entry.path();

        if (!entry.is_regular_file()) continue;
        if (path.extension() != ".png" && path.extension() != ".txt") continue;

        const char *ename = path.stem().string().c_str();

        if (std::strncmp(name, ename, std::strlen(name))) continue;

        CastMember member(path);
        std::string memname = member.name();

        if (_names.find(memname) != _names.end()) continue;

        auto shared = std::make_shared<CastMember>(std::move(member));

        _members.push_back(shared);
        _names.insert({ memname, shared });
    }
}

CastLib::CastLib(CastLib &&other) noexcept : 
    _offset(other._offset), 
    _name(move(other._name)),
    _members(move(other._members)) {
    other._offset = 0;
}
CastLib::CastLib(int offset, const string &name) : _offset(offset), _name(name), _members({}) {}

CastLib::~CastLib() {}

const std::regex CAST_MEMBER_NAME_PATTERN = std::regex(R"(^[a-zA-Z0-9 ]+_\d+_(.+)?\.(png|txt)$)");


void LuaRuntime::_register_member() {
    lua_pushlightuserdata(L, this);
    lua_pushcclosure(L, [](lua_State *L) {

        auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
        CastMember *member = nullptr;

        if (lua_isstring(L, 1)) {
            std::string name(lua_tostring(L, 1));

            if (lua_isnil(L, 2)) {
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

            if (lua_isnil(L, 2)) {
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
            auto path = member->path().string();

            lua_newtable(L);

            lua_pushstring(L, "id");
            lua_pushinteger(L, member->id());
            lua_settable(L, -3);

            lua_pushstring(L, "name");
            lua_pushstring(L, member->name().c_str());
            lua_settable(L, -3);
            
            lua_pushstring(L, "path");
            lua_pushstring(L, path.c_str());
            lua_settable(L, -3);

            if (member->path().extension() == ".png") {
                lua_pushstring(L, "image");
                
                Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
                *img = LoadImage(path.c_str());
            
                luaL_getmetatable(L, "image");
                lua_setmetatable(L, -2);

                lua_settable(L, -3);
            }
            else if (member->path().extension() == ".txt") {
                std::ifstream file(member->path());
                if (!file) {
                    runtime->logger->error("[runtime] failed to open cast member file {FILE}", member->path().string());
                    return 1;
                }
                
                std::stringstream buffer;
                buffer << file.rdbuf();
                auto str = buffer.str();

                lua_pushstring(L, "text");
                lua_pushstring(L, str.c_str());
                lua_settable(L, -3);
            }

            lua_newtable(L);
            lua_pushcfunction(L, member_tostring);
            lua_setfield(L, -2, "__tostring");

            lua_pushcfunction(L, member_concat);
            lua_setfield(L, -2, "__concat");
            lua_setmetatable(L, -2);
        }
        else lua_pushnil(L);

        return 1;
    }, 1);
    lua_setglobal(L, "member");
}

};