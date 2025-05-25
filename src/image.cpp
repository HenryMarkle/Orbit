#include <immintrin.h>
#include <cstdint>
#include <memory>
#include <cstring>
#include <algorithm>
#include <cstddef>

#include <Orbit/image.h>
#include <Orbit/color.h>
#include <Orbit/rect.h>
#include <Orbit/quad.h>
#include <Orbit/point.h>
#include <Orbit/vector.h>

using Orbit::Lua::Image;
using Orbit::Lua::Vector;
using Orbit::Lua::Color;
using Orbit::Lua::Rectangle;

inline Vector normalize(const Rectangle &rect, const Image &image) {
	float l = static_cast<float>(rect.left() / image.width());
	float t = static_cast<float>(rect.top() / image.height());
	float r = static_cast<float>(rect.right() / image.width());
	float b = static_cast<float>(rect.bottom() / image.height());

	return Vector(l, t, r, b);
}

void fill_image(uint8_t *data, int width, int height, uint32_t color) {

	auto total_size = width * height * 4;

	__m256i color_vec = _mm256_set1_epi32(static_cast<int32_t>(color));

	size_t i = 0;
	for (; i + 31 < total_size; i += 32) {
		_mm256_storeu_si256(reinterpret_cast<__m256i *>(data + i), color_vec);
	}

	for (; i < total_size; i += 4) {
		*reinterpret_cast<uint32_t *>(data + i) = color;
	}
}

void imgcpy_darkest(
		const Image &src, 
		Image &dest, 
		
		int srcx, 
		int srcy, 
		int srcw, 
		int srch, 
		
		int destx, 
		int desty, 
		int destw, 
		int desth
		) {
	
}

void imgcpy_ink(
		const Image &src, 
		Image &dest, 

		int srcx, 
		int srcy, 
		int srcw, 
		int srch, 

		int destx, 
		int desty, 
		int destw, 
		int desth, 
		
		Orbit::Lua::Color color
		) {
	
}

void imgcpy_rmbkg(
		const Image &src, 
		Image &dest, 
		
		int srcx, 
		int srcy, 
		int srcw, 
		int srch, 
		
		int destx, 
		int desty, 
		int destw, 
		int desth
		) {
	
}

void imgcpy(
		const Image &src, 
		Image &dest, 
		
		const Rectangle &src_rect, 
		const Rectangle &dest_rect
		) {
	if (
			src_rect.left() > src.width() || 
			src_rect.top() > src.height() || 
			src_rect.right() < 0 || 
			src_rect.bottom() < 0 ||
			
			dest_rect.left() > dest.width() || 
			dest_rect.top() > dest.height() || 
			dest_rect.right() < 0 || 
			dest_rect.bottom() < 0
			) {
		return;
	}

    auto sample_normal = normalize(src_rect, src);


}

namespace Orbit::Lua {

void Image::copy_to(Image &img, const Rectangle &source, const Rectangle &dest, Color color, ImageCopyOptions options) {

	const size_t pixel_bytes = 4;
	const size_t region_row_bytes = static_cast<int>(dest.width()) * pixel_bytes;

	for (size_t row = 0; row < static_cast<int>(dest.height()); ++row) {
		const uint8_t *src_row = _data + ((static_cast<int>(source.top()) + row) * static_cast<int>(source.width()) + static_cast<int>(source.left())) * pixel_bytes;
	
		uint8_t *dest_row = img._data + ((static_cast<int>(dest.top()) + row) * static_cast<int>(dest.width()) + static_cast<int>(dest.left())) * pixel_bytes;
	
		size_t i = 0;
		for (; i + 32 < region_row_bytes; i += 32) {
			__m256i pixels = _mm256_loadu_si256(reinterpret_cast<const __m256i *>(src_row + i));
			_mm256_storeu_si256(reinterpret_cast<__m256i *>(img._data + i), pixels);
		}

		if (i < region_row_bytes) {
			std::memcpy(img._data + i, _data + i, region_row_bytes - i);
		}
	}

}

Image &Image::operator=(Image &&image) noexcept {
	if (this == &image) return *this;

	std::free(_data);
	
	#ifdef __WIN32
	_data = static_cast<uint8_t *>(_aligned_malloc(16, _width * _height * 4));
	#else
	_data = static_cast<uint8_t *>(aligned_alloc(16, _width * _height * 4));
	#endif

	std::memcpy(_data, image._data, image.size());

	_width = image.width();
	_height = image.height();

	std::free(image._data);
	image._width = 0;
	image._height = 0;

	return *this;
}

Image &Image::operator=(const Image &image) {
	if (this == &image) return *this;

	std::free(_data);
	
	#ifdef __WIN32
	_data = static_cast<uint8_t *>(_aligned_malloc(16, _width * _height * 4));
	#else
	_data = static_cast<uint8_t *>(aligned_alloc(16, _width * _height * 4));
	#endif

	std::memcpy(_data, image._data, image.size());

	_width = image.width();
	_height = image.height();

	return *this;
}

Image::Image(Image &&image) noexcept : _width(image.width()), _height(image.height()) {
	#ifdef __WIN32
	_data = static_cast<uint8_t *>(_aligned_malloc(16, _width * _height * 4));
	#else
	_data = static_cast<uint8_t *>(aligned_alloc(16, _width * _height * 4));
	#endif
	
	std::memcpy(_data, image._data, image.size());

	std::free(image._data);
	image._width = 0;
	image._height = 0;
}

Image::Image(const Image &image) : _width(image.width()), _height(image.height()) {
	#ifdef __WIN32
	_data = static_cast<uint8_t *>(_aligned_malloc(16, _width * _height * 4));
	#else
	_data = static_cast<uint8_t *>(aligned_alloc(16, _width * _height * 4));
	#endif

	std::memcpy(_data, image._data, image.size());
}

Image::Image(int width, int height) : _width(width), _height(height) {
	#ifdef __WIN32
	_data = static_cast<uint8_t *>(_aligned_malloc(16, _width * _height * 4));
	#else
	_data = static_cast<uint8_t *>(aligned_alloc(16, width * height * 4));
	#endif
}

Image::Image(int width, int height, Color color) : _width(width), _height(height) {
	#ifdef __WIN32
	_data = static_cast<uint8_t *>(_aligned_malloc(16, width * height * 4));
	#else
	_data = static_cast<uint8_t *>(aligned_alloc(16, width * height * 4));
	#endif

	fill_image(_data, width, height, _packed_default_color);	
}

Image::~Image() {
	std::free(_data);
}

};
