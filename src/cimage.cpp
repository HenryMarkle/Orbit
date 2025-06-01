#ifdef AVX2
#include <immintrin.h>
#endif

#include <vector>
#include <cstdint>
#include <memory>
#include <cstring>
#include <algorithm>
#include <cstddef>

#include <Orbit/cimage.h>
#include <Orbit/color.h>
#include <Orbit/rect.h>
#include <Orbit/quad.h>
#include <Orbit/point.h>
#include <Orbit/vector.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

using Orbit::Lua::Vector;

#define META "image"

inline Vector normalize(const Orbit::Lua::Rect &rect, const Orbit::Lua::Custom::Image &image) {
	return Vector(
			static_cast<float>(rect.left() / image.width()), 
			static_cast<float>(rect.top() / image.height()), 
			static_cast<float>(rect.right() / image.width()), 
			static_cast<float>(rect.bottom() / image.height())
	);
}

inline bool is_rect_in_image(const Orbit::Lua::Custom::Image &image, const Orbit::Lua::Rect &rect) {
	return rect.left() > image.width() || 
			rect.top() > image.height() || 
			rect.right() < 0 || 
			rect.bottom() < 0;
}

void fill_image(uint8_t *data, int width, int height, uint32_t color) {
#ifdef AVX2
	auto total_size = width * height * 4;

	__m256i color_vec = _mm256_set1_epi32(static_cast<int32_t>(color));

	size_t i = 0;
	for (; i + 31 < total_size; i += 32) {
		_mm256_storeu_si256(reinterpret_cast<__m256i *>(data + i), color_vec);
	}

	for (; i < total_size; i += 4) {
		*reinterpret_cast<uint32_t *>(data + i) = color;
	}
#else
	for (int i = 0; i < width * height * 4; i += 4) {
		*data = color.r;
		*(data + 1) = color.g;
		*(data + 2) = color.b;
		*(data + 3) = color.a;
	}
#endif
}

void imgcpy_darkest(
		const Orbit::Lua::Custom::Image &src, 
		Orbit::Lua::Custom::Image &dest, 
		
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
		const Orbit::Lua::Custom::Image &src, 
		Orbit::Lua::Custom::Image &dest, 

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
		const Orbit::Lua::Custom::Image &src, 
		Orbit::Lua::Custom::Image &dest, 
		
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
		const Orbit::Lua::Custom::Image &src, 
		Orbit::Lua::Custom::Image &dest, 
		
		const Orbit::Lua::Rect &src_rect, 
		const Orbit::Lua::Rect &dest_rect
		) {
	
	if (
			!is_rect_in_image(src, src_rect) ||
			!is_rect_in_image(dest, dest_rect)
	) return;

    auto sample_normal = normalize(src_rect, src);


}

namespace Orbit::Lua::Custom {

Mask::Mask(int width, int height) : width(width), height(height) {
	data = std::vector<uint8_t>(width * height * depth, 0);
}

Mask::Mask(int width, int height, const std::vector<uint8_t> &data) : width(width), height(height), data(data) {}

Mask::Mask(int width, int height, const uint8_t *data) : width(width), height(height) {
	this->data = std::vector<uint8_t>(data, data + width * height * depth);
}

ImageCopyParams::ImageCopyParams() : ink(ImageCopyInk::None), blend(0), color(Color(255, 255, 255, 255)), mask(Mask(0, 0)) {}

ImageCopyParams::ImageCopyParams(ImageCopyInk ink, float blend, Color color, Mask mask) : ink(ink), blend(blend), color(color), mask(mask) {}

//

Image Image::crop(const Orbit::Lua::Rect &rect) const {
	if (!is_rect_in_image(*this, rect)) {
		throw std::runtime_error("out-of-bounds image rect");
	}

	auto nimg = Image(static_cast<int>(rect.width()), static_cast<int>(rect.height()));
	
#ifdef AVX2
	const int src_stride = _width * 4;
	const int dest_stride = nimg.width() * 4;
	
	const uint8_t *starting_pos = _data + static_cast<int>(rect.top())*src_stride + static_cast<int>(rect.left()) * 4;
	uint8_t *dest_pos = nimg._data;

	const int bytes_per_row = static_cast<int>(rect.width()) * 4;

	const int pixels_per_iter = 8;
	const int bytes_per_iter = 32;

	const int full_avx2_iters = bytes_per_row / bytes_per_iter;
	const int remaining_bytes = bytes_per_row % bytes_per_iter;

	for (int row = 0; row < static_cast<int>(rect.height()); row++) {
		const uint8_t *src_row = _data + (row * src_stride);
		uint8_t *dest_row = dest_pos + (row * dest_stride);
		
		int byte_offset = 0;

		for (int i = 0; i < full_avx2_iters; i++) {
			__m256i pixels = _mm256_loadu_si256(
					reinterpret_cast<const __m256i *>(src_row + byte_offset)
					);

			_mm256_storeu_si256(
					reinterpret_cast<__m256i *>(dest_row + byte_offset),
					pixels
					);

			byte_offset += bytes_per_iter;
		}

		if (remaining_bytes > 0) {
			std::memcpy(dest_row + byte_offset, src_row + byte_offset, remaining_bytes);
		}
	}
#else
	for (
			int x = 0; 
			x < static_cast<int>(rect.width()) * 4; 
			x += 4) {

		for (
				int y = 0;
				y < static_cast<int>(rect.height()) * 4;
				y += 4
				) {

			int ix = x + static_cast<int>(rect.left()) * 4;
			int iy = y + static_cast<int>(rect.top()) * 4;

			int dest_index = x + (y * static_cast<int>(rect.width()) * 4);
			int src_index = ix + (iy * static_cast<int>(rect.width()) * 4);
		
			*(nimg._data + dest_index + 0) = *(_data + src_index + 0);
			*(nimg._data + dest_index + 1) = *(_data + src_index + 1);
			*(nimg._data + dest_index + 2) = *(_data + src_index + 2);
			*(nimg._data + dest_index + 3) = *(_data + src_index + 3);
		}
	}
#endif

	return nimg;
}

void Image::copy_to(
		Image &img, 
		const Rect &source, 
		const Rect &dest, 
		const ImageCopyParams &options
		) {

}

void Image::copy_to(
		Image &img, 
		const Rect &source, 
		const Quad &dest, 
		const ImageCopyParams &options
		) {

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
