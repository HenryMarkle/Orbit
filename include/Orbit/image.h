#pragma once

#ifdef AVX2
#include <immintrin.h>
#endif

#include <vector>
#include <cstdint>

#include <Orbit/color.h>
#include <Orbit/rect.h>
#include <Orbit/quad.h>
#include <Orbit/point.h>

namespace Orbit::Lua {

enum class ImageCopyInk : uint8_t {
	None,
	RemoveBackground,
	Darkest,
};

struct Mask {
	int width, height;
	std::vector<uint8_t> data;
	const static int depth = 1;

	Mask(int, int);
	Mask(int, int, const std::vector<uint8_t> &);
	Mask(int, int, const uint8_t *);
};

struct ImageCopyParams {
	ImageCopyInk ink;
	float blend;
	Color color;
	Mask mask;
	
	ImageCopyParams();
	ImageCopyParams(ImageCopyInk, float, Color, Mask);
};

class Image {
private:
	#ifdef AVX2
	alignas(16) uint8_t *_data;
	#else
	uint8_t *_data;
	#endif

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

	Mask to_mask() const;

	void fill(Color);
	Image trim() const;
	Image crop(const Rectangle &) const;

	void copy_to(Image &, const Rectangle &, const Rectangle &, const ImageCopyParams &);
	void copy_to(Image &, const Rectangle &, const Quad &, const ImageCopyParams &);

	Image &operator=(Image &&) noexcept;
	Image &operator=(const Image &);

	Image(Image &&) noexcept;
	Image(const Image &);
	Image(int width, int height);
	Image(int width, int height, Color color);
	
	~Image();
};

};
