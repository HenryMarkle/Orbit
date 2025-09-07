#include <regex>
#include <vector>
#include <string>
#include <sstream>
#include <iostream>
#include <stdexcept>
#include <filesystem>
#include <unordered_set>
#include <unordered_map>

#include <Orbit/Lua/runtime.h>
#include <Orbit/Lua/castlib.h>
#include <Orbit/Lua/memory.h>
#include <Orbit/config.h>
#include <Orbit/paths.h>

#include <spdlog/spdlog.h>

extern "C" {
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

using std::filesystem::exists;
using std::filesystem::is_directory;
using std::filesystem::directory_iterator;
using std::unordered_map;
using std::unordered_set;
using std::string;
using std::regex;
using std::regex_match;
using std::stringstream;

static int detailed_error_handler(lua_State* L) {
    const char* msg = lua_tostring(L, 1);
    if (msg == NULL) {
        msg = "Unknown error";
    }
    
    lua_Debug ar;
    std::ostringstream trace;
    trace << "Error: " << msg << "\n";
    trace << "Stack traceback:\n";
    
    int level = 1;
    while (lua_getstack(L, level, &ar)) {
        lua_getinfo(L, "Slnt", &ar);
        
        trace << "  [" << level << "] ";
        if (ar.name) {
            trace << ar.name << " ";
        }
        if (ar.namewhat && strlen(ar.namewhat) > 0) {
            trace << "(" << ar.namewhat << ") ";
        }
        
        if (ar.source) {
            trace << "in " << ar.source;
            if (ar.currentline > 0) {
                trace << ":" << ar.currentline;
            }
        }
        trace << "\n";
        
        // Print local variables (optional)
        trace << "    Locals:\n";
        int localIndex = 1;
        const char* localName;
        while ((localName = lua_getlocal(L, &ar, localIndex)) != NULL) {
            if (localName[0] != '(') { // Skip internal variables
                trace << "      " << localName << " = ";
                // Convert value to string
                if (lua_isstring(L, -1)) {
                    trace << "\"" << lua_tostring(L, -1) << "\"";
                } else if (lua_isnumber(L, -1)) {
                    trace << lua_tonumber(L, -1);
                } else if (lua_isboolean(L, -1)) {
                    trace << (lua_toboolean(L, -1) ? "true" : "false");
                } else if (lua_isnil(L, -1)) {
                    trace << "nil";
                } else {
                    trace << lua_typename(L, lua_type(L, -1));
                }
                trace << "\n";
            }
            lua_pop(L, 1); // Remove local variable value
            localIndex++;
        }
        
        level++;
        if (level > 50) break; // Prevent infinite loops
    }
    
    lua_pushstring(L, trace.str().c_str());
    return 1;
}

namespace Orbit::Lua {

void LuaRuntime::_register_lib() {
	_register_vector();
	_register_point();	
	_register_rectangle();
	_register_color();
	_register_quad();
	_register_image();
	_register_imagebuf();
	_register_utils();
	_register_xtra();
	_register_lingo_api();
}

void LuaRuntime::_load_cast_libs() {
	const auto castpath = paths->data() / "Cast";

	if (!exists(castpath) || !is_directory(castpath)) return;

	auto Internal_ptr 		= std::make_shared<CastLib>(CastLib::OFFSET * 0, "Internal");
	auto customMems_ptr 	= std::make_shared<CastLib>(CastLib::OFFSET * 2, "customMems");
	auto soundCast_ptr 		= std::make_shared<CastLib>(CastLib::OFFSET * 3, "soundCast");
	auto levelEditor_ptr 	= std::make_shared<CastLib>(CastLib::OFFSET * 4, "levelEditor");
	auto exportBitmaps_ptr 	= std::make_shared<CastLib>(CastLib::OFFSET * 5, "exportBitmaps");
	auto Drought_ptr 		= std::make_shared<CastLib>(CastLib::OFFSET * 6, "Drought");
	auto Dry_Editor_ptr 	= std::make_shared<CastLib>(CastLib::OFFSET * 7, "Dry Editor");
	auto MSC_ptr 			= std::make_shared<CastLib>(CastLib::OFFSET * 8, "MSC");

	Internal_ptr->load_members(castpath);
	customMems_ptr->load_members(castpath);
	soundCast_ptr->load_members(castpath);
	levelEditor_ptr->load_members(castpath);
	exportBitmaps_ptr->load_members(castpath);
	Drought_ptr->load_members(castpath);
	Dry_Editor_ptr->load_members(castpath);
	MSC_ptr->load_members(castpath);

	// for (auto &m : Dry_Editor_ptr->members()) std::cout << "MEMBER \"" << m->name << "\"" << std::endl;

	for (auto &m : Internal_ptr->members()) _castmembers.insert({ m->name, m });
	for (auto &m : customMems_ptr->members()) _castmembers.insert({ m->name, m });
	for (auto &m : soundCast_ptr->members()) _castmembers.insert({ m->name, m });
	for (auto &m : levelEditor_ptr->members()) _castmembers.insert({ m->name, m });
	for (auto &m : exportBitmaps_ptr->members()) _castmembers.insert({ m->name, m });
	for (auto &m : Drought_ptr->members()) _castmembers.insert({ m->name, m });
	for (auto &m : Dry_Editor_ptr->members()) _castmembers.insert({ m->name, m });
	for (auto &m : MSC_ptr->members()) _castmembers.insert({ m->name, m });

	_castlibs.push_back(Internal_ptr);
	_castlib_names.insert({ Internal_ptr->name(), Internal_ptr });

	_castlibs.push_back(customMems_ptr);
	_castlib_names.insert({ customMems_ptr->name(), customMems_ptr });

	_castlibs.push_back(soundCast_ptr);
	_castlib_names.insert({ soundCast_ptr->name(), soundCast_ptr });

	_castlibs.push_back(levelEditor_ptr);
	_castlib_names.insert({ levelEditor_ptr->name(), levelEditor_ptr });

	_castlibs.push_back(exportBitmaps_ptr);
	_castlib_names.insert({ exportBitmaps_ptr->name(), exportBitmaps_ptr });

	_castlibs.push_back(Drought_ptr);
	_castlib_names.insert({ Drought_ptr->name(), Drought_ptr });

	_castlibs.push_back(Dry_Editor_ptr);
	_castlib_names.insert({ Dry_Editor_ptr->name(), Dry_Editor_ptr });

	_castlibs.push_back(MSC_ptr);
	_castlib_names.insert({ MSC_ptr->name(), MSC_ptr });

	return;

	// Dead code

	unordered_set<string> names;

	for (auto &e : directory_iterator(castpath)) {
		stringstream ss;

		if (!e.is_regular_file()) continue;

		const auto &path = e.path();
		const auto pathstr = path.filename().string();
		
		if (!regex_match(pathstr, CAST_MEMBER_NAME_PATTERN)) continue;

		for (auto c : pathstr) {
			if (c == '_') break;
			ss << c;
		}

		const auto name = ss.str();

		if (names.find(name) != names.end()) continue;

		names.insert(name);

		auto lib = CastLib(0, name);
		lib.load_members(castpath);
		for (auto &m : lib.members()) _castmembers.insert({ m->name, m });

		auto ptr = std::make_shared<CastLib>(std::move(lib));

		_castlibs.push_back(ptr);
		_castlib_names.insert({ std::move(name), ptr });
	}
}

void LuaRuntime::LoadFile(std::filesystem::path const &file) {
	if (!std::filesystem::exists(file)) 
		throw std::invalid_argument("file does not exist");

	if (!std::filesystem::is_regular_file(file) || file.extension() != ".lua")
		throw std::invalid_argument("invalid script file");

	if (luaL_dofile(L, file.string().c_str()) != LUA_OK) {
		const char *err_msg = lua_tostring(L, -1);
		lua_pop(L, 1);

		throw std::runtime_error(std::string("failed to load script file '" + file.stem().string() + "': " + err_msg));
	}

	// if (lua_pcall(L, 0, 1, 0) != LUA_OK) {
	// 	const char *err_msg = lua_tostring(L, -1);
	// 	lua_pop(L, 1);
	// 	throw std::runtime_error("failed to load script file: " + std::string(err_msg));
	// }

	// std::string module_name = file.stem().string();

	// lua_getglobal(L, "package");
	// lua_getfield(L, -1, "loaded");
	// lua_pushvalue(L, -3);
	// lua_setfield(L, -2, module_name.c_str());
	// lua_pop(L, 2);
	// lua_pop(L, 1);
}

void LuaRuntime::LoadDirectory(std::filesystem::path const &dir) {
	if (!std::filesystem::exists(dir))
		throw std::invalid_argument("directory not found");

	if (!std::filesystem::is_directory(dir))
		throw std::invalid_argument("path is not a directory");

	for (auto &entry : std::filesystem::directory_iterator(dir)) {
		if (!std::filesystem::is_regular_file(entry) || entry.path().extension().string() != ".lua") continue;
	
		LoadFile(entry.path());
	}
}

void LuaRuntime::LoadScripts() {
	LoadDirectory(paths->scripts());
}

void LuaRuntime::SelectStartingScript(std::string const &name) { _entry_file = name; }
void LuaRuntime::SelectStartingFunction(std::string const &name) { _entry_func = name; }

void LuaRuntime::ProcessFrame() {
	lua_pushcfunction(L, detailed_error_handler);
	int handler_index = lua_gettop(L);

	const auto requireStr = std::string("local entryModule = require('" + _entry_file + "'); return entryModule");

	int loadRes = luaL_dostring(L, requireStr.c_str());

	if (loadRes != LUA_OK) {
		std::string err = lua_tostring(L, -1);
		std::cout << "Load Err: " << err << std::endl;
		lua_pop(L, 1);
		return;
	}

	// lua_getglobal(L, "renderStart");

	// if (!lua_istable(L, -1)) {
	// 	logger->error("renderStart global is not a table");
	// 	lua_pop(L, 1);
	// 	return;
	// }

	lua_getfield(L, -1, "exitFrame");

	// lua_pushnil(L);

	int res = lua_pcall(L, 0, LUA_MULTRET, handler_index);

	if (res != LUA_OK) {
		std::string err = lua_tostring(L, -1);
		lua_pop(L, 1);
		
		luaL_traceback(L, L, err.c_str(), 1);
		std::string stack_trace(lua_tostring(L, -1));
		
		lua_pop(L, 1);
		
		logger->error(std::string("failed to run entry function '") + _entry_func + "': " + err + "\nStack Trace:\n"+stack_trace);
		throw std::runtime_error(std::string("failed to run exitFrame '") + _entry_func + "'\nStack Trace:\n"+stack_trace);
	}

	lua_pop(L, 1);
}

void LuaRuntime::DrawFrame() {
	if (_redraw) {
		// redraw here
		// ClearBackground(GRAY);
		DrawTexture(viewport.texture, 0, 0, WHITE);
		_redraw = false;
	}
}

LuaRuntime::LuaRuntime(
	int width, 
	int height, 
	std::shared_ptr<Orbit::Paths> paths, 
	std::shared_ptr<spdlog::logger> logger, 
	std::shared_ptr<Orbit::Shaders> shaders,
	std::shared_ptr<Orbit::Config> config
) : 
	_width(width), 
	_height(height),
	paths(paths),
	logger(logger),
	shaders(shaders),
	config(config),
	_redraw(false),
	_should_quit(false),
	_entry_file(""),
	_entry_func("") {

	// L =  luaL_newstate();

	L = lua_newstate(AlignedAllocator, nullptr);

	_load_cast_libs();
	_register_lib();
	
	
	
	
	// #if LUAJIT
	// #else
	// luaopen_base(L);
	// luaopen_math(L);
	// luaopen_string(L);
	// luaopen_table(L);
	// luaopen_debug(L);
	// luaopen_utf8(L);
	// luaopen_os(L);
	// luaL_requiref(L, "table", luaopen_table, 1);
	// lua_pop(L, 1);

	// luaL_requiref(L, "package", luaopen_package, 1);
	// lua_pop(L, 1);
	// #endif

	luaL_openlibs(L);

	lua_getglobal(L, "package");
	if (lua_istable(L, -1)) {
		lua_getfield(L, -1, "path");
		std::string current_path = lua_tostring(L, -1);
		lua_pop(L, 1);
		
		std::string new_path = std::string("./?.lua;") + 
							(paths->scripts() / "?.lua;").string() + 
							current_path;
		
		lua_pushstring(L, new_path.c_str());
		lua_setfield(L, -2, "path");
	}
	lua_pop(L, 1);


	viewport = LoadRenderTexture(1400, 800);

	BeginTextureMode(viewport);
	ClearBackground(WHITE);
	EndTextureMode();

	_castlibs.reserve(8);
	_castlib_names.reserve(12);

	{
		lua_getglobal(L, "_G");

		lua_pushnil(L);
		while (lua_next(L, -2)) {
			if (lua_type(L, -2) == LUA_TSTRING) {
				globals_snapshot.insert(lua_tostring(L, -2));
			}
			lua_pop(L, 1);
		}

		lua_pop(L, 1);
	}
}

LuaRuntime::~LuaRuntime() {
    lua_close(L);
}

};
