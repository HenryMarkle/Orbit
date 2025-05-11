#pragma once

#include <iostream>
#include <immintrin.h>
#include <filesystem>
#include <string>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

namespace Orbit::Lua {

struct Vector {
	alignas(16) float data[4];

	inline float &x() { return data[0]; }
	inline float &y() { return data[1]; }
	inline float &z() { return data[2]; }
	inline float &w() { return data[3]; }
	
	float distance(Vector const &) const;
	void normalize();

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

	Vector(Vector const &);
	Vector();
	inline Vector(float x = 0.0f, float y = 0.0f, float z = 0.0f, float w = 0.0f) {
		data[0] = x;
		data[1] = y;
		data[2] = z;
		data[3] = w;
	}
};

struct Point { 
	float x, y;

	Point operator+(Point const &);
	Point operator-(Point const &);
	
	Point operator*(int);
	Point operator/(int);
	
	Point operator*(float);
	Point operator/(float);

	inline Point() : x(0), y(0) {}
	inline Point(float x, float y) : x(x), y(y) {}
};

struct Color {
	short r, g, b;

	inline Color() : r(0), g(0), b(0) {}
	inline Color(short r, short g, short b) : r(r), g(g), b(b) {}
};

struct Rectangle {
	float left, top, right, bottom;

	Rectangle operator+(Rectangle const &);
	Rectangle operator-(Rectangle const &);

	inline Rectangle() : left(0), top(0), right(0), bottom(0) {}
	inline Rectangle(float left, float top, float right, float bottom) : left(left), top(top), right(right), bottom(bottom) {}
};

std::ostream &operator<<(std::ostream &, const Vector &);
std::ostream &operator<<(std::ostream &, const Point &);
std::ostream &operator<<(std::ostream &, const Color &);
std::ostream &operator<<(std::ostream &, const Rectangle &);

class LuaRuntime {

private:
    
	lua_State *L;
	
	void _register_point();
	void _register_vector();
	void _register_color();
	void _register_rectangle();
	void _register_image();
	void _register_member();

	void _register_lib();

public:

    void load_file(std::filesystem::path const &);
	void load_directory(std::filesystem::path const &);

    LuaRuntime &operator=(LuaRuntime const&) = delete;

    LuaRuntime(LuaRuntime const&) = delete;
    LuaRuntime();
    ~LuaRuntime();

};

};
