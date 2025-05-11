#include <iostream>
#include <memory>

#include <Orbit/lua.h>
#include <Orbit/paths.h>

#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>

using std::shared_ptr;
using std::make_shared;

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
        std::cout << "Initializing logger has failed" << std::endl;
        throw ex;
    }

	logger->info("------------------------------------ starting program");
    
	auto rt = Orbit::Lua::LuaRuntime();

    rt.exec_str("print(double(5))");
	
	logger->info("------------------------------------ program terminated");

    return 0;
}
