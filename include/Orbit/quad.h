#pragma once

#include <Orbit/point.h>

namespace Orbit::Lua {

struct Quad {

	Point topleft, topright, bottomright, bottomleft;

	inline bool operator==(const Quad &q) const {
		return 
			topleft == q.topleft && 
			topright == q.topright && 
			bottomright == q.bottomright && 
			bottomleft == q.bottomleft;
	}
	
	inline bool operator!=(const Quad &q) const {
		return 
			topleft != q.topleft || 
			topright != q.topright || 
			bottomright != q.bottomright || 
			bottomleft != q.bottomleft;
	}

	inline Quad operator+(const Quad &q) const {
		return Quad(
			topleft + q.topleft,
			topright + q.topright,
			bottomright + q.bottomright,
			bottomleft + q.bottomleft
		);
	}
	
	inline Quad operator-(const Quad &q) const {
		return Quad(
			topleft - q.topleft,
			topright - q.topright,
			bottomright - q.bottomright,
			bottomleft - q.bottomleft
		);
	}

	inline Quad operator+(const Point &p) const {
		return Quad(
			topleft + p,
			topright + p,
			bottomright + p,
			bottomleft + p
		);
	}
	
	inline Quad operator-(const Point &p) const {
		return Quad(
			topleft - p,
			topright - p,
			bottomright - p,
			bottomleft - p
		);
	}

	inline Quad operator*(const int i) const {
		return Quad(
			topleft * i,
			topright * i,
			bottomright * i,
			bottomleft * i
		);
	}

	inline Quad operator/(const int i) const {
		return Quad(
			topleft / i,
			topright / i,
			bottomright / i,
			bottomleft / i
		);
	}

	inline Quad operator*(const float i) const {
		return Quad(
			topleft * i,
			topright * i,
			bottomright * i,
			bottomleft * i
		);
	}

	inline Quad operator/(const float i) const {
		return Quad(
			topleft / i,
			topright / i,
			bottomright / i,
			bottomleft / i
		);
	}

	inline Quad() : topleft(Point()), toright(Point()), bottomright(Point()), bottomleft(Point) {}
	inline Quad(Point tl, Point tr, Point br, Point bl) : topleft(tl), topright(tr), bottomright(br), bottomleft(bl) {}

};

};
