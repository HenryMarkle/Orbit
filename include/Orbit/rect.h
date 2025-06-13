#pragma once

#include <string>
#include <iostream>

#include <xsimd/xsimd.hpp>

namespace Orbit::Lua {

struct alignas(xsimd::default_arch::alignment()) Rect {
	union
	{
		struct {
			float _left, _top, _right, _bottom;
		};
		
		float _data[4];
	};

	inline float &left() { return _data[0]; }
	inline float &top() { return _data[1]; }
	inline float &right() { return _data[2]; }
	inline float &bottom() { return _data[3]; }
	
	inline float left() const { return _data[0]; }
	inline float top() const { return _data[1]; }
	inline float right() const { return _data[2]; }
	inline float bottom() const { return _data[3]; }

	inline float width() const { return _data[2] - _data[0]; }
	inline float height() const { return _data[3] - _data[1]; }

	std::string tostring() const;
	
	inline bool operator==(Rect const &v) const {
		return 
			this->_data[0] == v._data[0] &&
			this->_data[1] == v._data[1] &&
			this->_data[2] == v._data[2] &&
			this->_data[3] == v._data[3];
	}

	inline bool operator!=(Rect const &v) const {
		return 
			this->_data[0] != v._data[0] ||
			this->_data[1] != v._data[1] ||
			this->_data[2] != v._data[2] ||
			this->_data[3] != v._data[3];
	}

	Rect operator+(Rect const &) const;
	Rect operator-(Rect const &) const;

	Rect operator*(float) const;
	Rect operator/(float) const;

	Rect &operator=(Rect const &);

	Rect(Rect const &);
	Rect();
	inline Rect(float x, float y = 0.0f, float z = 0.0f, float w = 0.0f) {
		_data[0] = x;
		_data[1] = y;
		_data[2] = z;
		_data[3] = w;
	}
};

std::ostream &operator<<(std::ostream &, const Rect &);

};
