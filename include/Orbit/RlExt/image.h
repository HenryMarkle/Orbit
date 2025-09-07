#pragma once

#include <cstdint>
#include <filesystem>
#include <optional>

#include <Orbit/Lua/rect.h>
#include <Orbit/Lua/quad.h>
#include <Orbit/shaders.h>

#include <raylib.h>

namespace Orbit::RlExt {

enum class CopyImageInk {
	None					=  0,
	TransparentBackground	= 36,
	Darkest					= 39
};

struct CopyImageParams {

	float blend;
	std::optional<Color> color;
	CopyImageInk ink;
	Texture2D *mask;

	CopyImageParams();
	CopyImageParams(float, std::optional<Color>, CopyImageInk, Texture2D *);

};

struct CopyImageBufParams {

	float blend;
	std::optional<Color> color;
	CopyImageInk ink;
	Image *mask;

	CopyImageBufParams();
	CopyImageBufParams(float, std::optional<Color>, CopyImageInk, Image *);

};

inline Color Sample(const Image *img, int index) {
	int channels = 4;

	switch (img->format) {
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8: channels = 3; break;
		default: channels = 4; break;
	}

	if (index < 0 || index >= img->width * img->height * channels) return WHITE;

	index *= channels;

	Color c = { 0, 0, 0, 0 };

	const auto *data = reinterpret_cast<uint8_t *>(img->data);

	c.r = data[index + 0];
	
	c.g = data[index + 1];
	c.b = data[index + 2];
	if (channels > 3) c.a = data[index + 3];
	else c.a = 255;

	return c;
}

inline Color Sample(const Image *img, int x, int y) {
	int index = x + y * img->width;
	int channels = 4;

	switch (img->format) {
		case PIXELFORMAT_UNCOMPRESSED_R8G8B8: channels = 3; break;
		default: channels = 4; break;
	}

	index *= channels;

	Color c = { 0, 0, 0, 0 };

	const auto *data = reinterpret_cast<uint8_t *>(img->data);

	c.r = data[index];
	
	c.g = data[index + 1];
	c.b = data[index + 2];
	if (channels > 3) c.a = data[index + 3];

	return c;
}

void CopyImage_CPU(
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Rect *to, 
	const CopyImageBufParams &params
);

void CopyImage_CPU(
	const Image *src, 
	Image *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Quad *to, 
	const CopyImageBufParams &params
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

void CopyImage_GPU(
	const Orbit::CopyPixelsShader *shader, 
	const RenderTexture2D *src, 
	RenderTexture2D *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Rect *to, 
	const CopyImageParams &params
);

void CopyImage_GPU(
	const Orbit::InvbCopyPixelsShader *shader, 
	const RenderTexture2D *src, 
	RenderTexture2D *dst, 
	const Orbit::Lua::Rect *from, 
	const Orbit::Lua::Quad *to, 
	const CopyImageParams &params
);

/// @note Does not take ownership of the image.
struct QuadImageSampler {

	Image image;
	Lua::Quad quad;
	size_t channels;
	
	static constexpr size_t simd_size = xsimd::simd_type<float>::size;

	bool ScreenToUV(float x, float y, float &u, float &v) const;
	void ScreenToUVBatch(const float* screen_x, const float* screen_y, int count, float* u_out, float* v_out, bool* valid_out) const;

	void SamplePixel(float u, float v, Color *pixel) const;
	void SampleBatch(const float *x, const float *y, int count, Color *pixels) const;

	void SampleFromUVBatch(const float *u_coords, const float *v_coords, const bool* valid, int count, Color* pixels) const;

	inline QuadImageSampler(Image const&image, Lua::Quad const&quad) : image(image), quad(quad) {
		channels = 4; // TODO: Depends on image pixel format.
	}
};

};
