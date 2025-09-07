#include <Orbit/config.h>

#include <string>
#include <fstream>
#include <iostream>
#include <filesystem>

#include <toml++/toml.hpp>

#include <Orbit/io.h>

namespace Orbit {

Config::Config() : 
    file(get_executable_dir() / "config.toml"),
    width(1400), height(800), fps(15), 
    entry_file(std::string("entryPoint")), 
    entry_func(std::string("exitFrame")), 
    splashscreen(true), invb(true),
    initial_disclamer(true) {}

Config::Config(const std::filesystem::path &file) : Config() {
    this->file = file;

    try {
        const auto &parsed = toml::parse_file(file.string());
    
        width = parsed["width"].value_or(width);
        height = parsed["height"].value_or(height);
        fps = parsed["fps"].value_or(fps);
        entry_file = parsed["entry_file"].value_or(entry_file);
        entry_func = parsed["entry_func"].value_or(entry_func);
        splashscreen = parsed["splashscreen"].value_or(true);
        invb = parsed["inverse_biliear_interpolation"].value_or(true);
        initial_disclamer = parsed["initial_disclamer"].value_or(true);

    } catch (std::exception &e) {
        std::cerr << "Failed to load config file: " << file << std::endl;
    }
}

void Config::Export(const std::filesystem::path &file) const noexcept {
    toml::table tb{
        { "width", width },
        { "height", height },
        { "fps", fps },
        { "splashscreen", splashscreen },
        { "entry_file", entry_file.c_str() },
        { "entry_func", entry_func.c_str() },
        { "verbose_deugging", true },
        { "initial_disclamer", initial_disclamer }
    };

    std::ofstream f(file);

    if (!f) return;

    f << tb;
}

};