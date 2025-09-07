#include <cctype>
#include <filesystem>
#include <algorithm>
#include <string>
#include <optional>

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

size_t GetMaxPathLength() {
    return MAX_PATH;
}

};

#else

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

size_t GetMaxPathLength() {
    return PATH_MAX;
}

};

#endif

std::optional<std::filesystem::path> GetPathCaseInsensitive(std::filesystem::path const &path) {
	auto parent = path.parent_path();

	auto name = path.stem().string();

	std::transform(name.begin(), name.end(), name.begin(), [](auto c) { return std::tolower(c); });

	for (const auto &e : std::filesystem::directory_iterator(parent)) {
		auto test_name = e.path().stem().string();

		std::transform(test_name.begin(), test_name.end(), test_name.begin(), [](auto c) { return std::tolower(c); });

		if (name == test_name) return e.path();
	}

	return std::nullopt;
}
