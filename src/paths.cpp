#include <Orbit/paths.h>
#include <Orbit/io.h>

#include <filesystem>

using std::filesystem::path;

namespace Orbit {

Paths::Paths() {
    _executable = get_executable_dir();
    _logs = _executable / "logs";
}

};