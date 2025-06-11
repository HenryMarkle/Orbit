#pragma once

#include <filesystem>
#include <optional>

#include <Orbit/rect.h>
#include <Orbit/quad.h>

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

void CopyImage(const Image *src, Image *dst);
void CopyImage(const Image *src, Image *dst, const CopyImageParams &params);

void CopyImage(const Image *src, Image *dst, const Lua::Rect *from, const Lua::Rect *to);
void CopyImage(const Image *src, Image *dst, const Lua::Rect *from, const Lua::Rect *to, const CopyImageParams &params);

void CopyImage(const Image *src, Image *dst, const Lua::Rect *from, const Lua::Quad *to);
void CopyImage(const Image *src, Image *dst, const Lua::Rect *from, const Lua::Quad *to, const CopyImageParams &params);

};
