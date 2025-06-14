#pragma once

#include <filesystem>
#include <optional>

#include <Orbit/Lua/rect.h>
#include <Orbit/Lua/quad.h>
#include <Orbit/shaders.h>

#include <raylib.h>

namespace Orbit::RlExt {

enum class CopyImageInk {
	None					=  0,
	TransparentBackground	= 32,
	Darkest					= 39
};

struct CopyImageParams {

	float blend;
	std::optional<Color> color;
	CopyImageInk ink;
	Image *mask;

	CopyImageParams();
	CopyImageParams(float, std::optional<Color>, CopyImageInk, Image *);

};

void CopyImage_CPU(
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Rect *to, 
	const CopyImageParams &params
);

void CopyImage_CPU(
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Quad *to, 
	const CopyImageParams &params
);


void CopyImage_GPU(
	const Orbit::CopyPixelsShader *shader, 
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Rect *to, 
	const CopyImageParams &params
);

void CopyImage_GPU(
	const Orbit::InvbCopyPixelsShader *shader, 
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Quad *to, 
	const CopyImageParams &params
);

};
