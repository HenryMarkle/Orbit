#include <Orbit/castlib.h>

#include <sstream>
#include <memory>
#include <regex>

namespace Orbit::Lua {

void CastMember::load() {
    if (_loaded) return;
}
void CastMember::unload() {
    if (!_loaded) return;
}

CastMember &CastMember::operator=(CastMember &&other) noexcept {
    if (this == &other) return *this;

    _name = std::move(other._name);
    _path = std::move(other._path);
    
    _id = other._id;
    _loaded = other._loaded;
    
    other._id = 0;
    other._loaded = false;

    return *this;
}

CastMember::CastMember(CastMember &&other) noexcept {
    _name = std::move(other._name);
    _path = std::move(other._path);
    
    _id = other._id;
    _loaded = other._loaded;
    
    other._id = 0;
    other._loaded = false;
}
CastMember::CastMember(const std::filesystem::path &path) : _path(path), _loaded(false), _image(Image{0}) {
    // i.e. Drought_1233436_rock.png

    static std::regex pattern(R"(^[a-zA-Z]+_\d+(_[a-zA-Z ]+)?\.png$)");

    if (!std::regex_match(path.string(), pattern)) {
        throw std::invalid_argument(std::string("invalid cast member")+path.string());
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
CastMember::CastMember(int, const std::string &, const std::filesystem::path &, Image) {}

CastMember::~CastMember() {}

};