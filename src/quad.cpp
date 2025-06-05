#include <cstring>
#include <math.h>
#include <sstream>
#include <iostream>
#include <iomanip>

#include <Orbit/lua.h>
#include <Orbit/quad.h>

#include <xsimd/xsimd.hpp>
#include <raylib.h>
#include <raymath.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

inline Vector2 rotate_vector(Vector2 v, float degrees, Vector2 p) {
	float rad = degrees * PI / 180.0f;

	float sinr = (float)sin(rad);
	float cosr = (float)cos(rad);

	float dx = v.x - p.x;
	float dy = v.y - p.y;

	return Vector2{
		p.x + dx * cosr - dy * sinr,
		p.y + dx * sinr + dy * cosr
	};
}

inline std::ostream &operator<<(std::ostream &out, Vector2 v) {
	return out << "point(" 
		<< std::setprecision(4) << v.x << ", "
		<< std::setprecision(4) << v.y
		<< ')';
}

namespace Orbit::Lua {
bool Quad::operator==(const Quad &q) const {
	return 
		topleft == q.topleft && 			
		topright == q.topright && 
		bottomright == q.bottomright && 
		bottomleft == q.bottomleft;
}

bool Quad::operator!=(const Quad &q) const {
		return 
			topleft != q.topleft || 
			topright != q.topright || 
			bottomright != q.bottomright || 
			bottomleft != q.bottomleft;
}

Quad Quad::operator+(const Quad &q) const {
	using batch_type = xsimd::batch<float>;
        
	auto a = batch_type::load_aligned(data);
	auto b = batch_type::load_aligned(q.data);
	auto result = a + b;
	
	Quad output;
	result.store_aligned(output.data);
	return output;
}
	
Quad Quad::operator-(const Quad &q) const {
	using batch_type = xsimd::batch<float>;
        
	auto a = batch_type::load_aligned(data);
	auto b = batch_type::load_aligned(q.data);
	auto result = a - b;
	
	Quad output;
	result.store_aligned(output.data);
	return output;
}

Quad Quad::operator+(const Vector2 &p) const {
		return Quad(
			topleft + p,
			topright + p,
			bottomright + p,
			bottomleft + p
		);
}
	
Quad Quad::operator-(const Vector2 &p) const {
		return Quad(
			topleft - p,
			topright - p,
			bottomright - p,
			bottomleft - p
		);
}

Quad Quad::operator*(const int i) const {
	using batch_type = xsimd::batch<float>;
	
	auto a = batch_type::load_aligned(data);
	auto s = xsimd::broadcast(static_cast<float>(i));
	auto result = a * s;
	
	Quad output;
	result.store_aligned(output.data);
	return output;
}

Quad Quad::operator/(const int i) const {
	using batch_type = xsimd::batch<float>;
	
	auto a = batch_type::load_aligned(data);
	auto s = xsimd::broadcast(static_cast<float>(i));
	auto result = a / s;
	
	Quad output;
	result.store_aligned(output.data);
	return output;
}

Quad Quad::operator*(const float i) const {
	using batch_type = xsimd::batch<float>;
	
	auto a = batch_type::load_aligned(data);
	auto s = xsimd::broadcast(i);
	auto result = a * s;
	
	Quad output;
	result.store_aligned(output.data);
	return output;
}

Quad Quad::operator/(const float i) const {
	using batch_type = xsimd::batch<float>;
	
	auto a = batch_type::load_aligned(data);
	auto s = xsimd::broadcast(i);
	auto result = a / s;
	
	Quad output;
	result.store_aligned(output.data);
	return output;
}

Vector2 Quad::center() const { return (topleft + topright + bottomright + bottomleft) / 4; }
Quad Quad::rotate(float degrees, const Vector2 &center) const {
	#ifdef SIMD
	float radians = degrees * (PI / 180.0f);
	float cos_angle = std::cos(radians);
	float sin_angle = std::sin(radians);
	
	using batch_type = xsimd::batch<float>;
	
	// Load all coordinates
	auto coords = batch_type::load_aligned(data);
	
	// Create center offsets: [cx, cy, cx, cy, cx, cy, cx, cy]
	alignas(32) float center_data[8] = {
		center.x, center.y, center.x, center.y,
		center.x, center.y, center.x, center.y
	};

	auto centers = batch_type::load_aligned(center_data);
	
	// Translate to origin (subtract center)
	auto translated = coords - centers;
	
	// Separate x and y coordinates for rotation
	// We need to shuffle: [x1,y1,x2,y2,x3,y3,x4,y4] -> [x1,x2,x3,x4] and [y1,y2,y3,y4]
	alignas(32) float temp_data[8];
	translated.store_aligned(temp_data);
	
	// Manual extraction of x and y coordinates
	alignas(32) float x_coords[8] = {
		temp_data[0], temp_data[2], temp_data[4], temp_data[6],
		0, 0, 0, 0  // padding for SIMD
	};
	alignas(32) float y_coords[8] = {
		temp_data[1], temp_data[3], temp_data[5], temp_data[7],
		0, 0, 0, 0  // padding for SIMD
	};
	
	auto x_batch = batch_type::load_aligned(x_coords);
	auto y_batch = batch_type::load_aligned(y_coords);
	
	// Create rotation coefficient batches
	auto cos_batch = xsimd::broadcast(cos_angle);
	auto sin_batch = xsimd::broadcast(sin_angle);
	
	// Apply rotation: new_x = x*cos - y*sin, new_y = x*sin + y*cos
	auto new_x = x_batch * cos_batch - y_batch * sin_batch;
	auto new_y = x_batch * sin_batch + y_batch * cos_batch;
	
	// Store back to temp arrays
	new_x.store_aligned(x_coords);
	new_y.store_aligned(y_coords);
	
	// Recombine x,y pairs and translate back
	alignas(32) float rotated_data[8] = {
		x_coords[0] + center.x, y_coords[0] + center.y,  // topleft
		x_coords[1] + center.x, y_coords[1] + center.y,  // topright
		x_coords[2] + center.x, y_coords[2] + center.y,  // bottomright
		x_coords[3] + center.x, y_coords[3] + center.y   // bottomleft
	};
	
	Quad result;
	auto final_batch = batch_type::load_aligned(rotated_data);
	final_batch.store_aligned(result.data);
	
	return result;

	#else
	
	return Quad(
			rotate_vector(topleft, degrees, center),
			rotate_vector(topright, degrees, center),
			rotate_vector(bottomright, degrees, center),
			rotate_vector(bottomleft, degrees, center)
	);

	#endif
}
Quad Quad::operator>>(float degrees) const { return rotate(degrees, center()); }

std::string Quad::tostring() const {
		std::stringstream ss;

		ss 
			<< "quad(" 
			<< topleft << ", " 
			<< topright << ", "
			<< bottomright << ", "
			<< bottomleft << ")";
	
		return ss.str();
}


void LuaRuntime::_register_quad() {
	const auto make = [](lua_State *L) {
		float x = luaL_checknumber(L, 1);
		float y = luaL_checknumber(L, 2);
	
		Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

		p->x = x;
		p->y = y;

		luaL_getmetatable(L, "point");
		lua_setmetatable(L, -2);
	
		return 1;
	};

	const auto read = [](lua_State *L) {
		Quad *q = static_cast<Quad *>(luaL_checkudata(L, 1, "quad"));
		const char *field = luaL_checkstring(L, 2);

		if (std::strcmp(field, "topleft") == 0) {
			Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
			*p = q->topleft;
			luaL_getmetatable(L, "point");
			lua_setmetatable(L, -2);
		}
		else if (std::strcmp(field, "topright") == 0) {
			Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
			*p = q->topright;
			luaL_getmetatable(L, "point");
			lua_setmetatable(L, -2);
		}
		else if (std::strcmp(field, "bottomright") == 0) {
			Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
			*p = q->bottomright;
			luaL_getmetatable(L, "point");
			lua_setmetatable(L, -2);
		}
		else if (std::strcmp(field, "bottomleft") == 0) {
			Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
			*p = q->bottomleft;
			luaL_getmetatable(L, "point");
			lua_setmetatable(L, -2);
		}
		else lua_pushnil(L);

		return 1;
	};

	const auto write = [](lua_State *L) {
		Quad *q = static_cast<Quad *>(luaL_checkudata(L, 1, "quad"));

		const char *field = luaL_checkstring(L, 2);
		Vector2 *value = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

		
		if (std::strcmp(field, "topleft") == 0) {
			q->topleft = *value;
		}
		else if (std::strcmp(field, "topright") == 0) {
			q->topright = *value;
		}
		else if (std::strcmp(field, "bottomright") == 0) {
			q->bottomright = *value;	
		}
		else if (std::strcmp(field, "bottomleft") == 0) {
			q->bottomleft = *value;	
		}
		else return luaL_error(L, "invalid field '%s' on quad", field);		

		return 0;
	};

	const auto add = [](lua_State *L) {
		Quad a = *static_cast<Quad *>(luaL_checkudata(L, 1, "quad"));
		Quad b = *static_cast<Quad *>(luaL_checkudata(L, 2, "quad"));
		

		Quad *res = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));

		*res = a + b;

		luaL_getmetatable(L, "quad");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto subtract = [](lua_State *L) {
		Quad a = *static_cast<Quad *>(luaL_checkudata(L, 1, "quad"));
		Quad b = *static_cast<Quad *>(luaL_checkudata(L, 2, "quad"));
		
		Quad *res = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));
		*res = a - b;

		luaL_getmetatable(L, "quad");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto multiply = [](lua_State *L) {
		Quad a = *static_cast<Quad *>(luaL_checkudata(L, 1, "quad"));
		float b = static_cast<float>(luaL_checknumber(L, 2));
		
		Quad *res = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));
		*res = a * b;

		luaL_getmetatable(L, "quad");
		lua_setmetatable(L, -2);

		return 1;
	};
	
	const auto divide = [](lua_State *L) {
		Quad a = *static_cast<Quad *>(luaL_checkudata(L, 1, "quad"));
		float b = static_cast<float>(luaL_checknumber(L, 2));
		
		Quad *res = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));
		*res = a / b;

		luaL_getmetatable(L, "quad");
		lua_setmetatable(L, -2);

		return 1;
	};

	const auto equals = [](lua_State *L) {
		Quad a = *static_cast<Quad *>(luaL_checkudata(L, 1, "quad"));
		Quad b = *static_cast<Quad *>(luaL_checkudata(L, 2, "quad"));
		
		bool res = a == b;

		lua_pushboolean(L, res);

		return 1;
	};

	const auto tostring = [](lua_State *L) {
		Quad *a = static_cast<Quad *>(luaL_checkudata(L, 1, "quad"));
		auto str = a->tostring();
		lua_pushstring(L, str.c_str());
		return 1;
	};

	luaL_newmetatable(L, "quad");

	lua_pushcfunction(L, tostring);
	lua_setfield(L, -2, "__tostring");

	lua_pushcfunction(L, read);
	lua_setfield(L, -2, "__index");

	lua_pushcfunction(L, write);
	lua_setfield(L, -2, "__newindex");

	lua_pushcfunction(L, add);
	lua_setfield(L, -2, "__add");

	lua_pushcfunction(L, subtract);
	lua_setfield(L, -2, "__sub");

	lua_pushcfunction(L, multiply);
	lua_setfield(L, -2, "__mul");

	lua_pushcfunction(L, divide);
	lua_setfield(L, -2, "__div");

	lua_pushcfunction(L, equals);
	lua_setfield(L, -2, "__eq");

	lua_pop(L, 1);
}

};
