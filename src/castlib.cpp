#include <Orbit/Lua/castlib.h>
#include <Orbit/Lua/runtime.h>
#include <Orbit/hash.h>

#include <filesystem>
#include <iostream>
#include <sstream>
#include <fstream>
#include <cstring>
#include <algorithm>
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

    name = move(other.name);
    path = move(other.path);
    
    id = other.id;
    // _loaded = other._loaded;
    
    other.id = 0;
    // other._loaded = false;

    return *this;
}

CastMember::CastMember(CastMember &&other) noexcept {
    name = move(other.name);
    path = move(other.path);
    
    id = other.id;
    // _loaded = other._loaded;
    
    other.id = 0;
    // other._loaded = false;
}
CastMember::CastMember(const std::filesystem::path &path) : path(path) {
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

    id = std::stoi(id_ss.str());
    name = name_ss.str();
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
        std::string memname = member.name;

        if (_names.find(memname) != _names.end()) continue;

        auto shared = std::make_shared<CastMember>(std::move(member));

        _members.push_back(shared);
        _names.insert({ memname, shared });
    }

    std::sort(
        _members.begin(), 
        _members.end(), 
        [](const auto &first, const auto &second){
            return first->id < second->id;
    });
}

CastLib::CastLib(CastLib &&other) noexcept : 
    _offset(other._offset), 
    _name(move(other._name)),
    _members(move(other._members)) {
    other._offset = 0;
}
CastLib::CastLib(int offset, const string &name) : 
    _offset(offset), 
    _name(name), 
    _members({}) {}

CastLib::~CastLib() {}

const std::regex CAST_MEMBER_NAME_PATTERN = std::regex(R"(^[a-zA-Z0-9 ]+_\d+_(.+)?\.(png|txt)$)");

};