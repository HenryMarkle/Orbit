#pragma once

#include <filesystem>

namespace Orbit {

class Dirs {

private:

	std::filesystem::path _exec, _scripts, _data, _assets;
	std::filesystem::path _cast;

public:

	inline const std::filesystem::path &exec() const { return _exec; }
	inline const std::filesystem::path &scripts() const { return _scripts; }
	inline const std::filesystem::path &data() const { _data; }
	inline const std::filesystem::path &assets() const { _assets; }
	
	inline const std::filesystem::path &cast() const { _cast; }

	Dirs();

};

};
