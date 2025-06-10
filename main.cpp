#include <iostream>
#include <memory>
#include <string>

#include <Orbit/lua.h>
#include <Orbit/shaders.h>
#include <Orbit/paths.h>

#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>

#include <raylib.h>

using std::shared_ptr;
using std::make_shared;

using std::unique_ptr;
using std::make_unique;

int main(int, char**) {
    shared_ptr<Orbit::Paths> paths = make_shared<Orbit::Paths>();
	
    std::shared_ptr<spdlog::logger> logger = nullptr;
	
    // Initializing logging
    try {

        #ifdef _WIN32
        logger = spdlog::basic_logger_mt("main logger", (paths->logs() / "logs.txt").string());
        #else
        logger = spdlog::basic_logger_mt("main", (paths->logs() / "logs.txt"));
        #endif

        #ifdef DEBUG
        logger->set_level(spdlog::level::level_enum::debug);
        #endif

    } catch (const spdlog::spdlog_ex &ex) {
        std::cout << "initializing logger has failed" << std::endl;
        throw ex;
    }



	logger->info("------------------------------------ starting program");

	logger->info(std::string("Orbit v") + APP_VERSION);

	
	logger->info("initializing window");

    SetTargetFPS(30);
	InitWindow(1400, 800, "Orbit Runtime");

    shared_ptr<Orbit::Shaders> shaders = make_shared<Orbit::Shaders>();

	logger->info("initializing runtime");

	auto rt = Orbit::Lua::LuaRuntime(1400, 800, paths, logger, shaders);

	logger->info("loading scripts");

	rt.load_scripts();
    
    BeginDrawing();
    ClearBackground(GRAY);
    EndDrawing();
    
    rt.init();

	while (!WindowShouldClose()) {
        rt.process_frame();

		BeginDrawing();
		{
            // rt.draw_frame();

            BeginShaderMode(shaders->flipper.shader);
            shaders->flipper.prepare(rt.viewport.texture);
            DrawTexture(rt.viewport.texture, 0, 0, WHITE);
            EndShaderMode();
        }
		EndDrawing();
	}


	CloseWindow();
	
	logger->info("------------------------------------ program terminated");

    return 0;
}


