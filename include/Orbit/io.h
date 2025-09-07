#pragma once

#include <filesystem>
#include <optional>

namespace Orbit {

std::filesystem::path get_executable_dir();
size_t GetMaxPathLength();

/// Reteives the path using case-insensitive algorithm, if found.
std::optional<std::filesystem::path> GetPathCaseInsensitive(std::filesystem::path const &);

};
