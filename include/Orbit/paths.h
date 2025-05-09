#pragma once

#include <filesystem>

namespace Orbit {

class Paths {

private:

    std::filesystem::path _executable, _logs;

public:

    inline const auto &executable() const { return _executable; }
    inline const auto &logs() const { return _logs; }

    Paths();

};

};