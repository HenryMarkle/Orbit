#pragma once

#include <string>
#include <iostream>

namespace Orbit::Lua {

struct Vector {
	alignas(16) float data[4];

	inline float &x() { return data[0]; }
	inline float &y() { return data[1]; }
	inline float &z() { return data[2]; }
	inline float &w() { return data[3]; }
	
	float distance(Vector const &) const;
	Vector mix(Vector const &, float) const;
	void normalize();
	std::string tostring() const;
	
	inline bool operator==(Vector const &v) const {
		return 
			this->data[0] == v.data[0] &&
			this->data[1] == v.data[1] &&
			this->data[2] == v.data[2] &&
			this->data[3] == v.data[3];
	}
	inline bool operator!=(Vector const &v) const {
		return 
			this->data[0] != v.data[0] ||
			this->data[1] != v.data[1] ||
			this->data[2] != v.data[2] ||
			this->data[3] != v.data[3];
	}

	Vector operator+(Vector const &) const;
	Vector operator-(Vector const &) const;

	Vector operator*(float) const;
	Vector operator/(float) const;

	Vector &operator=(Vector const &);

	Vector(Vector const &);
	Vector();
	inline Vector(float x = 0.0f, float y = 0.0f, float z = 0.0f, float w = 0.0f) {
		data[0] = x;
		data[1] = y;
		data[2] = z;
		data[3] = w;
	}
};

std::ostream &operator<<(std::ostream &, const Vector &);

};
