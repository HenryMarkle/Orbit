#include <string>
#include <stdexcept>

#include <Orbit/Lua/runtime.h>
#include <Orbit/paths.h>

#include <spdlog/spdlog.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

void LuaRuntime::_register_lib() {
	_register_vector();
	_register_point();	
	_register_rectangle();
	_register_color();
	_register_quad();
	_register_image();
	_register_utils();
}

void LuaRuntime::load_file(std::filesystem::path const &file) {
	if (!std::filesystem::exists(file)) 
		throw std::invalid_argument("file does not exist");

	if (!std::filesystem::is_regular_file(file) || file.extension() != ".lua")
		throw std::invalid_argument("invalid script file");

	if (luaL_dofile(L, file.string().c_str()) != LUA_OK) {
		const char *err_msg = lua_tostring(L, -1);
		lua_pop(L, 1);

		throw std::runtime_error(std::string("failed to load script file '" + file.stem().string() + "': " + err_msg));
	}
}

void LuaRuntime::load_directory(std::filesystem::path const &dir) {
	if (!std::filesystem::exists(dir))
		throw std::invalid_argument("directory not found");

	if (!std::filesystem::is_directory(dir))
		throw std::invalid_argument("path is not a directory");

	for (auto &entry : std::filesystem::directory_iterator(dir)) {
		if (!std::filesystem::is_regular_file(entry) || entry.path().extension().string() != ".lua") continue;
	
		load_file(entry.path());
	}
}

void LuaRuntime::load_scripts() {
	load_directory(paths->scripts());
}

void LuaRuntime::init() {
	lua_getglobal(L, _init.c_str());

	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		return;
	}

	int res = lua_pcall(L, 0, 0, 0);

	if (res != LUA_OK) {
		std::string err = lua_tostring(L, -1);
		logger->error(std::string("failed to run init function '") + _init + "': " + err);
		lua_pop(L, 1);
		throw std::runtime_error(std::string("failed to run init function '") + _init + "': " + err);
	}
}

void LuaRuntime::process_frame() {
	lua_getglobal(L, _entry.c_str());

	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		return;
	}

	int res = lua_pcall(L, 0, 0, 0);

	if (res != LUA_OK) {
		std::string err = lua_tostring(L, -1);
		logger->error(std::string("failed to run entry function '") + _entry + "': " + err);
		lua_pop(L, 1);
		throw std::runtime_error(std::string("failed to run entry function '") + _entry + "': " + err);
	}
}

void LuaRuntime::draw_frame() {
	if (_redraw) {
		// redraw here
		// ClearBackground(GRAY);
		DrawTexture(viewport.texture, 0, 0, WHITE);
		_redraw = false;
	}
}

LuaRuntime::LuaRuntime(int width, int height, std::shared_ptr<Orbit::Paths> paths, std::shared_ptr<spdlog::logger> logger, std::shared_ptr<Orbit::Shaders> shaders) : 
	_width(width), 
	_height(height),
	paths(paths),
	logger(logger),
	shaders(shaders),
	_redraw(false),
	_entry("exitFrame"),
	_init("initFrame") {

	L =  luaL_newstate();
	
	luaopen_base(L);
	luaopen_math(L);
	luaopen_string(L);

	_register_lib();

	viewport = LoadRenderTexture(1400, 800);

	BeginTextureMode(viewport);
	ClearBackground(WHITE);
	EndTextureMode();
}

LuaRuntime::~LuaRuntime() {
    lua_close(L);
}

};
