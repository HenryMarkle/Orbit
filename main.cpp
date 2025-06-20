#include <iostream>
#include <memory>
#include <string>

#include <Orbit/Lua/runtime.h>
#include <Orbit/shaders.h>
#include <Orbit/paths.h>
#include <Orbit/config.h>

#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>

#include <raylib.h>

#define MAIN_FILE

using std::shared_ptr;
using std::make_shared;

using std::unique_ptr;
using std::make_unique;

int main(int, char**) {
    shared_ptr<Orbit::Paths> paths = make_shared<Orbit::Paths>();
	
    shared_ptr<Orbit::Config> config = make_shared<Orbit::Config>(paths->config());
    shared_ptr<spdlog::logger> logger = nullptr;
	
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

    SetTargetFPS(config->fps);
	InitWindow(config->width, config->height, "Orbit Runtime");

    shared_ptr<Orbit::Shaders> shaders = make_shared<Orbit::Shaders>();

	logger->info("initializing runtime");

	auto rt = Orbit::Lua::LuaRuntime(config->width, config->height, paths, logger, shaders, config);

	logger->info("loading cast members");

    rt.load_cast_libs();

    logger->debug("registered cast libraries:");
    for (const auto &l : rt.castlibs()) {
        logger->debug("CastLib: {0}", l->name());
    }

	logger->info("loading scripts");

	rt.load_scripts();
    
    BeginDrawing();
    ClearBackground(GRAY);
    EndDrawing();

    logger->info("running initial script");
    
    rt.init();

    logger->info("begin window loop");

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


