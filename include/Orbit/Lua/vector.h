#pragma once

#include <memory>
#include <string>
#include <cstring>
#include <iostream>

#include <xsimd/xsimd.hpp>

namespace Orbit::Lua {

//xsimd::default_arch::alignment()

struct alignas(16) Vector {
	union {
		struct {
			float _x, _y, _z, _w;
		};

		float _data[4];
	};
	
	float DistanceFrom(Vector const &) const;
	Vector LerpTo(Vector const &, float) const;
	void Normalize();
	std::string ToString() const;
	
	inline bool operator==(Vector const &v) const {
		return 
			this->_data[0] == v._data[0] &&
			this->_data[1] == v._data[1] &&
			this->_data[2] == v._data[2] &&
			this->_data[3] == v._data[3];
	}
	inline bool operator!=(Vector const &v) const {
		return 
			this->_data[0] != v._data[0] ||
			this->_data[1] != v._data[1] ||
			this->_data[2] != v._data[2] ||
			this->_data[3] != v._data[3];
	}

	Vector operator+(Vector const &) const;
	Vector operator-(Vector const &) const;

	Vector operator*(float) const;
	Vector operator/(float) const;

	Vector &operator=(Vector const &);
	Vector &operator=(Vector &&) noexcept;
	
	Vector(Vector const &);
	Vector(Vector &&) noexcept;
	Vector();
	Vector(float x, float y, float z, float w);
};

std::ostream &operator<<(std::ostream &, const Vector &);

};
