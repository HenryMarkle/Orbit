#include <Orbit/Lua/castlib.h>

#include <filesystem>
#include <sstream>
#include <cstring>
#include <memory>
#include <regex>

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
        throw std::invalid_argument(string("invalid cast member")+path.filename().string());
    }

    auto stem = path.stem().string();
    std::stringstream id_ss, name_ss;
    int count = 0, index = 0;
    for (auto c : stem) {

        if (c == '_') {
            count++;
            continue;
        }

        if (count == 2) {
            id_ss << c;    
        } else if (count == 3) {
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

const std::regex CAST_MEMBER_NAME_PATTERN(R"(^[a-zA-Z]+_\d+(_[a-zA-Z ]+)?\.(png|txt)$)");

};