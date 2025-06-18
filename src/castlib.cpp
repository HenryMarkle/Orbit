#include <Orbit/Lua/castlib.h>
#include <Orbit/Lua/runtime.h>
#include <Orbit/hash.h>

#include <filesystem>
#include <iostream>
#include <sstream>
#include <fstream>
#include <cstring>
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
using std::string;
using std::move;

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


shared_ptr<CastMember> CastLib::operator[](const string &name) { return _members[name]; }
CastLib &CastLib::operator=(CastLib &&other) noexcept {
    if (this == &other) return *this;

    _name = move(other._name);
    _members = move(other._members);

    _id = other._id;

    other._id = 0;

    return *this;
}
CastLib &CastLib::operator<<(const std::filesystem::path &dir) {
    if (!std::filesystem::is_directory(dir)) {
        throw std::invalid_argument("path is not a direcotry: " + dir.string());
    }

    const char *name = _name.c_str();

    for (auto &entry : std::filesystem::directory_iterator(dir)) {
        const auto &path = entry.path();

        if (!entry.is_regular_file() || path.extension() != ".png") continue;

        const char *ename = path.stem().string().c_str();

        if (std::strncmp(name, ename, std::strlen(name))) continue;

        CastMember member(path);

        if (_members.count(member.name())) continue;

        _members[member.name()] = std::make_shared<CastMember>(std::move(member));
    }

    return *this;
}

CastLib::CastLib(CastLib &&other) noexcept : 
    _id(other._id), 
    _name(move(other._name)),
    _members(move(other._members)) {
    other._id = 0;
}
CastLib::CastLib(int id, const string &name) : _id(id), _name(name), _members({}) {}
CastLib::CastLib(int id, const string &name, unordered_map<string, shared_ptr<CastMember>, CaseInsensitiveHash, CaseInsensitiveEqual> &&members) :
    _name(name), _id(id), _members(move(members)) {}

CastLib::~CastLib() {}

const std::regex CAST_MEMBER_NAME_PATTERN = std::regex(R"(^[a-zA-Z0-9]+_\d+_(.+)?\.(png|txt)$)");


void LuaRuntime::_register_member() {
    lua_pushlightuserdata(L, this);
    lua_pushcclosure(L, [](lua_State *L) {

        CastMember *member = nullptr;

        if (lua_isstring(L, 1)) {
            const char *name = lua_tostring(L, 1);
        }
        else if (lua_isinteger(L, 1)) {
            int id = lua_tointeger(L, 1);
        }

        if (member) {
            lua_newtable(L);

            lua_pushstring(L, "id");
            lua_pushinteger(L, member->id());
            lua_settable(L, -3);

            lua_pushstring(L, "name");
            lua_pushstring(L, member->name().c_str());
            lua_settable(L, -3);
            
            lua_pushstring(L, "path");
            lua_pushstring(L, member->path().string().c_str());
            lua_settable(L, -3);

            if (member->path().extension() == ".png") {
                lua_pushstring(L, "image");
                
                Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
                *img = LoadImage(member->path().string().c_str());
            
                luaL_getmetatable(L, "image");
                lua_setmetatable(L, -2);

                lua_settable(L, -3);
            }
            else if (member->path().extension() == ".txt") {
                std::ifstream file(member->path());
                if (!file) {
                    auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
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
        }
        else lua_pushnil(L);

        return 1;
    }, 1);
    lua_setglobal(L, "member");
}

};