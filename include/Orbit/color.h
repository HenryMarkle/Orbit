#pragma once

#include <cstdint>
#include <string>
#include <sstream>
#include <iostream>

namespace Orbit::Lua {

struct Color {

	uint8_t r, g, b, a;

	inline std::string tostring() const {

		std::stringstream ss;

		ss 
			<< "color("
			<< static_cast<unsigned short>(r) << ", "
			<< static_cast<unsigned short>(g) << ", "
			<< static_cast<unsigned short>(b) << ", "
			<< static_cast<unsigned short>(a) << ")";

		return ss.str();

	}
	
	inline uint32_t pack() const {
		return (a << 24) | (b << 16) | (g << 8) | r;
	}

	inline Color operator+(Color c) const { return Color(r + c.r, g + c.g, b + c.b, a + c.a); }
	inline Color operator-(Color c) const { return Color(r - c.r, g - c.g, b - c.b, a - c.a); }

	inline bool operator==(Color a) const { return r == a.r && g == a.g && b == a.b && a == a.a ;}
	inline bool operator!=(Color a) const { return r != a.r || g != a.g || b != a.b || a != a.a;}


	inline Color(uint8_t r = 255, uint8_t g = 255, uint8_t b = 255, uint8_t a = 255) : r(r), g(g), b(b), a(a) {}

	inline Color(uint32_t n) : r(n & 0xFF), g((n >> 8) & 0xFF), b((n >> 16) & 0xFF), a((n >> 24) & 0xFF) {}
	
	inline Color(int32_t n) : r(static_cast<uint32_t>(n) & 0xFF), g((static_cast<uint32_t>(n) >> 8) & 0xFF), b((static_cast<uint32_t>(n) >> 16) & 0xFF), a((static_cast<uint32_t>(n) >> 24) & 0xFF) {}
};

inline std::ostream &operator<<(std::ostream &o, const Color &c) {
	return o << c.tostring();
}

};
