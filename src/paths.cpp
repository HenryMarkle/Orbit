#include <Orbit/paths.h>
#include <Orbit/io.h>

#include <filesystem>

using std::filesystem::exists;
using std::filesystem::create_directory;

namespace Orbit {

Paths::Paths() {
    _executable = get_executable_dir();
    
	_data = _executable / "data";
	_logs = _executable / "logs";
	_scripts = _executable / "scripts";
	_config = _executable / "config.toml";

	if (!exists(_logs)) create_directory(_logs);
}

};
