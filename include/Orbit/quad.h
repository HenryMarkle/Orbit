#pragma once

#include <math.h>

#include <Orbit/point.h>

namespace Orbit::Lua {

struct Quad {

	Point topleft, topright, bottomright, bottomleft;

	bool operator==(const Quad &q) const;	
	bool operator!=(const Quad &q) const;
	Quad operator+(const Quad &q) const;
	Quad operator-(const Quad &q) const;
	Quad operator+(const Point &p) const;
	Quad operator-(const Point &p) const;
	Quad operator*(const int i) const;
	Quad operator/(const int i) const;
	Quad operator*(const float i) const;
	Quad operator/(const float i) const;
	Point center() const;
	Quad rotate(float degrees, const Point &center) const; 	
	Quad operator>>(float degrees) const;

	std::string tostring() const;

	inline Quad() : topleft(Point()), topright(Point()), bottomright(Point()), bottomleft(Point()) {}
	inline Quad(Point tl, Point tr, Point br, Point bl) : topleft(tl), topright(tr), bottomright(br), bottomleft(bl) {}
};

};
