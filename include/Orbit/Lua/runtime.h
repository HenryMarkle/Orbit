#pragma once

#include <memory>
#include <string>
#include <filesystem>

#include <Orbit/paths.h>
#include <Orbit/shaders.h>

#include <spdlog/spdlog.h>
#include <raylib.h>

#ifndef MAIN_FILE

extern "C" {
    #include <lua.h>
}

#endif

namespace Orbit::Lua {


class LuaRuntime {

private:

	int _width, _height;
	bool _redraw;
	std::string _entry, _init;
    
	lua_State *L;

	void _register_point();
	void _register_vector();
	void _register_color();
	void _register_rectangle();
	void _register_quad();
	void _register_image();
	void _register_member();

	void _register_utils();
	void _register_lib();

	
public:

	std::shared_ptr<Orbit::Paths> paths;
	std::shared_ptr<spdlog::logger> logger;
	std::shared_ptr<Orbit::Shaders> shaders;
	
	inline int width() const { return _width; }
	inline int height() const { return _height; }
	inline void _set_redraw() { _redraw = true; }

	inline void set_entry(const std::string &name) { _entry = name; }

	RenderTexture2D viewport;

    void load_file(std::filesystem::path const &);
	void load_directory(std::filesystem::path const &);

	void load_scripts();

	void init();
	void process_frame();
	void draw_frame();

    LuaRuntime &operator=(LuaRuntime const&) = delete;

    LuaRuntime(LuaRuntime const&) = delete;
    LuaRuntime(int, int, std::shared_ptr<Orbit::Paths>, std::shared_ptr<spdlog::logger>, std::shared_ptr<Orbit::Shaders>);
    ~LuaRuntime();

};

};
