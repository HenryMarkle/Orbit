#pragma once

#include <math.h>

#include <raylib.h>

namespace Orbit::Lua {

struct alignas(32) Quad {

	union {
		struct {
			Vector2 topleft, topright, bottomright, bottomleft;
		};

		Vector2 vertices[4];

		float data[8];
	};


	bool operator==(const Quad &q) const;	
	bool operator!=(const Quad &q) const;
	Quad operator+(const Quad &q) const;
	Quad operator-(const Quad &q) const;
	Quad operator+(const Vector2 &p) const;
	Quad operator-(const Vector2 &p) const;
	Quad operator*(const int i) const;
	Quad operator/(const int i) const;
	Quad operator*(const float i) const;
	Quad operator/(const float i) const;
	Vector2 center() const;
	Quad rotate(float degrees, const Vector2 &center) const; 	
	Quad operator>>(float degrees) const;

	std::string tostring() const;

	Quad &operator=(const Quad &);
	
	Quad(const Quad &);

	inline Quad() : topleft(Vector2{0, 0}), topright(Vector2{0, 0}), bottomright(Vector2{0, 0}), bottomleft(Vector2{0, 0}) {}
	inline Quad(Vector2 tl, Vector2 tr, Vector2 br, Vector2 bl) : topleft(tl), topright(tr), bottomright(br), bottomleft(bl) {}
};

};
