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

	inline Color operator+(Color c) const { return Color(r + c.r, g + c.g, b + c.b, a + c.a); }
	inline Color operator-(Color c) const { return Color(r - c.r, g - c.g, b - c.b, a - c.a); }

	inline bool operator==(Color a) const { return r == a.r && g == a.g && b == a.b && a == a.a ;}
	inline bool operator!=(Color a) const { return r != a.r || g != a.g || b != a.b || a != a.a;}

	inline Color(uint8_t r = 255, uint8_t g = 255, uint8_t b = 255, uint8_t a = 255) : r(r), g(g), b(b), a(a) {}

};

inline std::ostream &operator<<(std::ostream &o, const Color &c) {
	return o << c.tostring();
}

};
