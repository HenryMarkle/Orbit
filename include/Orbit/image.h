#pragma once

#include <immintrin.h>
#include <cstdint>

#include <Orbit/color.h>
#include <Orbit/rect.h>
#include <Orbit/quad.h>
#include <Orbit/point.h>

namespace Orbit::Lua {

enum class ImageCopyOptions : uint8_t {
	None,
	Blend,
	RemoveBackground,
	Ink,
	Darkest,
};

class Image {
private:
	alignas(16) uint8_t *_data;
	int _width, _height;

	const static int _depth = 8;
	inline static const Color _default_color = Color(255, 255, 255, 255);
	static constexpr uint32_t _packed_default_color = (255 << 24) | (255 << 16) | (255 << 8) | 255;
public:

	inline int size() const { return _width * _height * 4; }
	inline int width() const { return _width; }
	inline int height() const { return _height; }

	void resize(int, int);
	void resize(int, int, Color);

	Color get_pixel(int, int) const;
	void set_pixel(int, int, Color);

	Color get_pixel(const Point &) const;
	void set_pixel(const Point &, Color);
	
	/// Removes white pixles from the margins of the image.
	void trim();
	void fill(Color);

	void copy_to(Image &, const Rectangle &, const Rectangle &, Color, ImageCopyOptions);
	void copy_to(Image &, const Rectangle &, const Quad &, Color, ImageCopyOptions);

	Image &operator=(Image &&) noexcept;
	Image &operator=(const Image &);

	Image(Image &&) noexcept;
	Image(const Image &);
	Image(int width, int height);
	Image(int width, int height, Color color);
	
	~Image();
};

};
