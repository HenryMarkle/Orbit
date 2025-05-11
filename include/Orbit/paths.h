#pragma once

#include <filesystem>

namespace Orbit {

class Paths {

private:

    std::filesystem::path _executable, _logs, _scripts;

public:

    inline const auto &executable() const { return _executable; }
    inline const auto &logs() const { return _logs; }
	inline const auto &scripts() const { return _scripts; }

    Paths();

};

};
