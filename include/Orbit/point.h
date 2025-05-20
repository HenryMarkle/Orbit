#pragma once

#include <string>
#include <immintrin.h>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <cmath>

#include <Orbit/lua.h>
#include <Orbit/vector.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

struct Point { 
	float x, y;

	inline std::string tostring() const { 
		std::stringstream ss;

		ss 
			<< "Point("
			<< std::setprecision(3) << x << ", "
			<< std::setprecision(3) << y << ')';

		return ss.str(); 
	}

	inline float distance(const Point &p) const {
		return std::sqrt(abs(x - p.x) + abs(y - p.y));
	}

	inline Point mix(const Point &p, float t) const {
		return Point(x * (1 - t) + p.x * t, y * (1 - t) + p.y);
	}

	Point rotate(float degrees, const Point &point) const;
	inline Point operator>>(float degrees) const { return rotate(degrees, Point(0, 0)); }

	Point operator+(Point const &) const;
	Point operator-(Point const &) const;
	
	Point operator*(int) const;
	Point operator/(int) const;
	
	Point operator*(float) const;
	Point operator/(float) const;

	inline bool operator==(const Point &p) const { return x == p.x && y == p.y; }
	inline bool operator!=(const Point &p) const { return x != p.x || y != p.y; }

	inline Point() : x(0), y(0) {}
	inline Point(float x, float y) : x(x), y(y) {}
};

std::ostream &operator<<(std::ostream &, const Point &);


};


