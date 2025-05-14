#pragma once

#include <string>
#include <iostream>

namespace Orbit::Lua {

struct Rectangle {
	alignas(16) float data[4];

	inline float &left() { return data[0]; }
	inline float &top() { return data[1]; }
	inline float &right() { return data[2]; }
	inline float &bottom() { return data[3]; }
	
	std::string tostring() const;
	
	inline bool operator==(Rectangle const &v) const {
		return 
			this->data[0] == v.data[0] &&
			this->data[1] == v.data[1] &&
			this->data[2] == v.data[2] &&
			this->data[3] == v.data[3];
	}
	inline bool operator!=(Rectangle const &v) const {
		return 
			this->data[0] != v.data[0] ||
			this->data[1] != v.data[1] ||
			this->data[2] != v.data[2] ||
			this->data[3] != v.data[3];
	}

	Rectangle operator+(Rectangle const &) const;
	Rectangle operator-(Rectangle const &) const;

	Rectangle operator*(float) const;
	Rectangle operator/(float) const;

	Rectangle &operator=(Rectangle const &);

	Rectangle(Rectangle const &);
	Rectangle();
	inline Rectangle(float x = 0.0f, float y = 0.0f, float z = 0.0f, float w = 0.0f) {
		data[0] = x;
		data[1] = y;
		data[2] = z;
		data[3] = w;
	}
};

std::ostream &operator<<(std::ostream &, const Rectangle &);

};
