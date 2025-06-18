#pragma once

#include <filesystem>

namespace Orbit {

class Paths {

private:

    std::filesystem::path _executable, _data, _logs, _scripts;
    std::filesystem::path _config;

public:

    inline const auto &executable() const { return _executable; }
	inline const auto &data() const { return _data; }
    inline const auto &logs() const { return _logs; }
	inline const auto &scripts() const { return _scripts; }
	inline const auto &config() const { return _config; }

    Paths();

};

};
