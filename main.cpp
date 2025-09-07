#include <iostream>
#include <memory>
#include <vector>
#include <string>

#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/spdlog.h>

#include <raylib.h>
#include <rlgl.h>

#include <Orbit/Lua/runtime.h>
#include <Orbit/shaders.h>
#include <Orbit/config.h>
#include <Orbit/fonts.h>
#include <Orbit/paths.h>

using namespace std;
using namespace Orbit;

static int draw_disclaimer(Fonts *fonts, Config *config);

int main(int argc, char** argv) {
    auto paths = make_shared<Paths>();
    auto config = make_shared<Config>(paths->config());

    shared_ptr<spdlog::logger> logger = nullptr;
	
    // Initializing logging
    try {
        auto console_sink = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
        console_sink->set_pattern("[%T] [%^%l%$] %v");

        auto file_sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(paths->logs() / "output.log", true);
        file_sink->set_pattern("[%Y-%m-%d %T.%e] [%l] %v");

        vector<spdlog::sink_ptr> sinks { console_sink, file_sink };

        logger = make_shared<spdlog::logger>("main", sinks.begin(), sinks.end());

        spdlog::set_default_logger(logger);

        #ifdef DEBUG
        spdlog::set_level(spdlog::level::debug);
        #else
        spdlog::set_level(spdlog::level::info);
        #endif
    } catch (const spdlog::spdlog_ex &ex) {
        cout << "initializing logger has failed" << endl;
        throw std::runtime_error(string("failed to initialize logger: ") + ex.what());
    }

	logger->info("------------------------------------ starting program");

	logger->info(string("Orbit v") + APP_VERSION);

    logger->info(string("Build configuration: ") + BUILD_TYPE);

	logger->info("initializing window");

    SetTargetFPS(config->fps);
    SetTraceLogLevel(LOG_WARNING);
	InitWindow(config->width, config->height, "Orbit Runtime");

    {   // Set icon

        auto icon_image = LoadImage((paths->executable() / "icon.png").string().c_str());
    
        SetWindowIcon(icon_image);
        UnloadImage(icon_image);
    
    }

    shared_ptr<Fonts> fonts = nullptr;

    {   // Load font

        const auto font_path = paths->font().string();

        Font font_32 = LoadFontEx(font_path.c_str(), 32, nullptr, 0);
        Font font_20 = LoadFontEx(font_path.c_str(), 20, nullptr, 0);
        Font font_16 = LoadFontEx(font_path.c_str(), 16, nullptr, 0);

        fonts = make_shared<Fonts>(font_32, font_20, font_16);
    
    }

    // Read from CMD
    //
    // if (argc) {

    // }
    //

    rlDisableBackfaceCulling();

    {   // Draw the splashscreen

        auto splashscreen_path = paths->executable() / "splashscreen.png";
    
        Texture2D splashscreen = LoadTexture(splashscreen_path.string().c_str());
    
        BeginDrawing();
        ClearBackground(BLACK);
        if (config->splashscreen) DrawTextureV(
            splashscreen, 
            Vector2{ (GetScreenWidth() - splashscreen.width)/2.0f, (GetScreenHeight() - splashscreen.height)/2.0f },
            WHITE
        );
    
        DrawText("Loading..", (GetScreenWidth() - MeasureText("Loading..", 30))/2, GetScreenHeight() - 50, 30, WHITE);
        EndDrawing();
    
        UnloadTexture(splashscreen);

    }

    shared_ptr<Shaders> shaders = make_shared<Shaders>();

	logger->info("initializing runtime");


	auto rt = make_unique<Lua::LuaRuntime>(config->width, config->height, paths, logger, shaders, config);

	logger->info("loading cast members");

    logger->debug("registered cast libraries:");
    for (const auto &l : rt->GetCastLibs()) {
        logger->debug("CastLib: {0}", l->name());
    }

	logger->info("loading scripts");

    try {
        rt->LoadScripts();
    } catch (std::exception &e) {
        logger->error(string("failed to load scripts:\n\t") + e.what());
        cerr << "failed to load scripts: " << e.what() << endl;
    }

    logger->info("running initial script");
    
    rt->SelectStartingScript(config->entry_file); // Starting script `.lua` file 
    rt->SelectStartingFunction(config->entry_func); // Starting script function 

    logger->info("begin window loop");

    bool disclaimer = config->initial_disclamer;

	while (!WindowShouldClose() && !rt->GetShouldQuit()) {
        if (disclaimer) {
            if (draw_disclaimer(fonts.get(), config.get())) disclaimer = false;
            continue;
        }

        //

        rt->ProcessFrame();

        BeginDrawing();
        {
            DrawTexture(rt->viewport.texture, 0, 0, WHITE);
        }
        EndDrawing();
	}

	auto _ = rt.release();

	CloseWindow();
	
	logger->info("------------------------------------ program terminated");

    return 0;
}

static int draw_disclaimer(Fonts *fonts, Config *config) {
    int disclaimer = 0;
    
    BeginDrawing();
    ClearBackground(BLACK);

    static const char *text = "The Orbit Runtime is just an environment for executing Lua code.";
    static const char *text2 = "Only you are responsible for verfying any script you copy from the internet.";
    static const char *text3 = "Do not contact me for any damages.";
    
    auto title_measured = MeasureTextEx(fonts->font32, "Disclamer", 32, 0.1);
    DrawTextEx(
        fonts->font32, 
        "Disclamer", 
        Vector2{(GetScreenWidth()-title_measured.x)/2, (GetScreenHeight() - title_measured.y)/2 - 30}, 
        32, 
        0.1, 
        WHITE
    );
    
    auto text1_measured = MeasureTextEx(fonts->font20, text, 20, 0.1);
    auto text2_measured = MeasureTextEx(fonts->font20, text2, 20, 0.1);
    auto text3_measured = MeasureTextEx(fonts->font20, text3, 20, 0.1);
    DrawTextEx(
        fonts->font20, 
        text, 
        Vector2{(GetScreenWidth() - text1_measured.x)/2, (GetScreenHeight() - title_measured.y)/2 + 10}, 
        20, 
        0.1, 
        WHITE
    );
    DrawTextEx(
        fonts->font20, 
        text2, 
        Vector2{(GetScreenWidth() - text2_measured.x)/2, (GetScreenHeight() - title_measured.y)/2 + 10 + text1_measured.y + 5}, 
        20, 
        0.1, 
        WHITE
    );
    DrawTextEx(
        fonts->font20, 
        text3, 
        Vector2{(GetScreenWidth() - text3_measured.x)/2, (GetScreenHeight() - title_measured.y)/2 + 10 + text1_measured.y + 5 + text2_measured.y + 5}, 
        20, 
        0.1, 
        WHITE
    );

    static const char *do_not_show_again_text = "Do not show again";
    static const char *ok_text = "Ok";

    auto box_label_measured = MeasureTextEx(fonts->font20, do_not_show_again_text, 20, 0.1);
    auto ok_measured = MeasureTextEx(fonts->font32, ok_text, 32, 0.1);

    DrawRectangleLinesEx({GetScreenWidth()/2.0f - 100, GetScreenHeight() - 200.0f, 20, 20}, 2, WHITE);
    if (!config->initial_disclamer) DrawRectangleRec({GetScreenWidth()/2.0f - 100 + 5, GetScreenHeight() - 200.0f + 5, 20 - 10, 20 - 10}, WHITE);
    DrawTextEx(fonts->font20, do_not_show_again_text, {GetScreenWidth()/2.0f - 70, GetScreenHeight() - 200.0f}, 20, 0.1, WHITE);

    DrawRectangleRoundedLinesEx({GetScreenWidth()/2.0f - 50, GetScreenHeight() - 100.0f, 100, 40}, 0.1, 1, 2, WHITE);
    DrawTextEx(fonts->font32, ok_text, {(GetScreenWidth() - ok_measured.x)/2.0f, GetScreenHeight() - 95.0f}, 32, 0.1, WHITE);

    if (CheckCollisionPointRec(GetMousePosition(), {GetScreenWidth()/2.0f - 100, GetScreenHeight() - 200.0f, 20 + box_label_measured.x, 20})) {
        DrawRectangleRec({GetScreenWidth()/2.0f - 100, GetScreenHeight() - 200.0f, 40 + box_label_measured.x, 20}, {255, 255, 255, 100});
        
        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
            config->initial_disclamer = !config->initial_disclamer;
        }
    }

    if (CheckCollisionPointRec(GetMousePosition(), {GetScreenWidth()/2.0f - 50, GetScreenHeight() - 100.0f, 100, 40})) {
        DrawRectangleRec({GetScreenWidth()/2.0f - 50, GetScreenHeight() - 100.0f, 100, 40}, {255, 255, 255, 100});

        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
            disclaimer = 1;
        }
    }

    if (!config->initial_disclamer) config->Export();

    EndDrawing();

    return disclaimer;
}

