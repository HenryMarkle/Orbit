#include <Orbit/config.h>

#include <iostream>
#include <filesystem>

#include <toml++/toml.hpp>

namespace Orbit {

Config::Config() : width(1400), height(800), fps(15) {}

Config::Config(const std::filesystem::path &file) : Config() {
    try {
        const auto &parsed = toml::parse_file(file.string());
    
        width = parsed["width"].value_or(width);
        height = parsed["height"].value_or(height);
        fps = parsed["fps"].value_or(fps);
    } catch (std::exception &e) {
        std::cout << "failed to load config file: " << file << std::endl;
    }
}

};