#pragma once

#include <filesystem>

namespace Orbit {

struct Config {

    int width, height, fps;

    Config();
    Config(const std::filesystem::path &file);

};

};