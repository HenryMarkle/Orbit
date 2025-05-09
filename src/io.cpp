#include <string>
#include <iostream>
#include <filesystem>

#include <Orbit/io.h>

#ifdef _WIN32

#include <windows.h>

namespace Orbit {


std::filesystem::path get_executable_dir() {
    char buffer[MAX_PATH]; // MAX_PATH is 260
    DWORD length = GetModuleFileNameA(nullptr, buffer, MAX_PATH);

    if (length == 0 || length == MAX_PATH) {
        throw std::runtime_error("Failed to get executable path");
    }

    return std::filesystem::absolute(buffer).parent_path();
}

size_t get_path_max_len() {
    return MAX_PATH;
}

};

#else

#include <cstdint>
#include <memory>
#include <stdexcept>
#include <vector>
#include <limits.h>
#include <unistd.h>

namespace Orbit {

std::filesystem::path get_executable_dir() {
    char result[PATH_MAX];
    ssize_t count = readlink("/proc/self/exe", result, PATH_MAX);

    if (count == -1)
      throw "could not retrieve executable's path";
    result[count] = '\0';
    return std::filesystem::absolute(result).parent_path();
}

size_t get_path_max_len() {
    return PATH_MAX;
}

};

#endif