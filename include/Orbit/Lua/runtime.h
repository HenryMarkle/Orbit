#pragma once

// #include <chrono>
#include <vector>
#include <memory>
#include <string>
#include <filesystem>
#include <unordered_set>
#include <unordered_map>

#include <Orbit/Lua/castlib.h>
#include <Orbit/Lua/random.h>
#include <Orbit/hash.h>
#include <Orbit/paths.h>
#include <Orbit/config.h>
#include <Orbit/shaders.h>

#include <spdlog/spdlog.h>
#include <raylib.h>

struct lua_State; // Forward declaration. Useful for preventing lua headers from leaking.

namespace Orbit::Lua {

class LuaRuntime {

private:

	int _width, _height;
	bool _redraw;
	std::string _entry_file, _entry_func;
	std::vector<std::shared_ptr<CastLib>> _castlibs;
	std::unordered_map<std::string, std::shared_ptr<CastMember>> _castmembers;
	std::unordered_map<std::string, std::shared_ptr<CastLib>, CaseInsensitiveHash, CaseInsensitiveEqual> _castlib_names;
	bool _should_quit;
    
	lua_State *L;

	void _register_point();
	void _register_vector();
	void _register_color();
	void _register_rectangle();
	void _register_quad();
	void _register_image();
	void _register_imagebuf();
	void _register_utils();
	void _register_lingo_api();
	void _register_xtra();


	void _register_lib();

	void _load_cast_libs();
	
public:

	std::shared_ptr<Orbit::Paths> paths;
	std::shared_ptr<spdlog::logger> logger;
	std::shared_ptr<Orbit::Shaders> shaders;
	std::shared_ptr<Orbit::Config> config;
	std::unordered_set<std::string> globals_snapshot;

	RandomGenerator random;

	// std::chrono::high_resolution_clock::time_point stopwatch;
	
	inline int GetWidth() const { return _width; }
	inline int GetHeight() const { return _height; }
	inline void SetRedraw() { _redraw = true; }
	inline bool GetShouldQuit() const { return _should_quit; }
	inline void Quit() { _should_quit = true; }

	inline const auto &GetCastLibs() const { return _castlibs; }
	inline const auto &GetCastMembers() const { return _castmembers; }
	inline const auto &GetCastLibNames() const { return _castlib_names; }

	RenderTexture2D viewport;

    void LoadFile(std::filesystem::path const &);
	void LoadDirectory(std::filesystem::path const &);

	void LoadScripts();

	void SelectStartingScript(std::string const&);
	void SelectStartingFunction(std::string const&);
	void ProcessFrame();
	void DrawFrame();

    LuaRuntime &operator=(LuaRuntime const&) = delete;

    LuaRuntime(LuaRuntime const&) = delete;
    LuaRuntime(int, int, std::shared_ptr<Orbit::Paths>, std::shared_ptr<spdlog::logger>, std::shared_ptr<Orbit::Shaders>, std::shared_ptr<Orbit::Config>);
    ~LuaRuntime();

};

};
