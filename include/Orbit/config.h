#pragma once

#include <string>
#include <filesystem>

namespace Orbit {

struct Config {

    std::filesystem::path file;

    int width, height, fps;
    std::string entry_file, entry_func;

    bool splashscreen, invb;

    bool initial_disclamer;

    /// @brief Saves the current state into a designated file.
    void Export(const std::filesystem::path &file) const noexcept;
    
    /// @brief Saves the current state into the original file it was imported from.
    inline void Export() const noexcept { Export(file); }

    Config();
    Config(const std::filesystem::path &file);

};

};