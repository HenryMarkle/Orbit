#pragma once

#include <string>
#include <iostream>

namespace Orbit::Lua {

struct Rect {
	#ifdef AVX2
	alignas(16) float data[4];
	#else
	float data[4];
	#endif

	inline float &left() { return data[0]; }
	inline float &top() { return data[1]; }
	inline float &right() { return data[2]; }
	inline float &bottom() { return data[3]; }
	
	inline float left() const { return data[0]; }
	inline float top() const { return data[1]; }
	inline float right() const { return data[2]; }
	inline float bottom() const { return data[3]; }

	inline float width() const { return data[2] - data[0]; }
	inline float height() const { return data[3] - data[1]; }

	std::string tostring() const;
	
	inline bool operator==(Rect const &v) const {
		return 
			this->data[0] == v.data[0] &&
			this->data[1] == v.data[1] &&
			this->data[2] == v.data[2] &&
			this->data[3] == v.data[3];
	}
	inline bool operator!=(Rect const &v) const {
		return 
			this->data[0] != v.data[0] ||
			this->data[1] != v.data[1] ||
			this->data[2] != v.data[2] ||
			this->data[3] != v.data[3];
	}

	Rect operator+(Rect const &) const;
	Rect operator-(Rect const &) const;

	Rect operator*(float) const;
	Rect operator/(float) const;

	Rect &operator=(Rect const &);

	Rect(Rect const &);
	Rect();
	inline Rect(float x = 0.0f, float y = 0.0f, float z = 0.0f, float w = 0.0f) {
		data[0] = x;
		data[1] = y;
		data[2] = z;
		data[3] = w;
	}
};

std::ostream &operator<<(std::ostream &, const Rect &);

};
