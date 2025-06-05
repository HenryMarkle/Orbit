#pragma once

#include <memory>
#include <string>
#include <cstring>
#include <iostream>

#include <xsimd/xsimd.hpp>

namespace Orbit::Lua {

struct alignas(xsimd::default_arch::alignment()) Vector {
	float _data[4];

	inline float &x() { return _data[0]; }
	inline float &y() { return _data[1]; }
	inline float &z() { return _data[2]; }
	inline float &w() { return _data[3]; }
	
	float distance(Vector const &) const;
	Vector mix(Vector const &, float) const;
	void normalize();
	std::string tostring() const;
	
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
