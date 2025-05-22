#include <immintrin.h>
#include <cstring>
#include <math.h>
#include <sstream>

#include <Orbit/lua.h>
#include <Orbit/quad.h>
#include <Orbit/point.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
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
	return Quad(
			topleft + q.topleft,
			topright + q.topright,
			bottomright + q.bottomright,
			bottomleft + q.bottomleft
		);
}
	
Quad Quad::operator-(const Quad &q) const {
		return Quad(
			topleft - q.topleft,
			topright - q.topright,
			bottomright - q.bottomright,
			bottomleft - q.bottomleft
		);
}

Quad Quad::operator+(const Point &p) const {
		return Quad(
			topleft + p,
			topright + p,
			bottomright + p,
			bottomleft + p
		);
}
	
Quad Quad::operator-(const Point &p) const {
		return Quad(
			topleft - p,
			topright - p,
			bottomright - p,
			bottomleft - p
		);
}

Quad Quad::operator*(const int i) const {
		return Quad(
			topleft * i,
			topright * i,
			bottomright * i,
			bottomleft * i
		);
}

Quad Quad::operator/(const int i) const {
		return Quad(
			topleft / i,
			topright / i,
			bottomright / i,
			bottomleft / i
		);
}

Quad Quad::operator*(const float i) const {
		return Quad(
			topleft * i,
			topright * i,
			bottomright * i,
			bottomleft * i
		);
}

Quad Quad::operator/(const float i) const {
		return Quad(
			topleft / i,
			topright / i,
			bottomright / i,
			bottomleft / i
		);
}

Point Quad::center() const { return (topleft + topright + bottomright + bottomleft) / 4; }
Quad Quad::rotate(float degrees, const Point &center) const {
		return Quad(
				topleft.rotate(degrees, center),
				topright.rotate(degrees, center),
				bottomright.rotate(degrees, center),
				bottomleft.rotate(degrees, center)
		);
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
	
		Point *p = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));

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
			Point *p = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
			*p = q->topleft;
			luaL_getmetatable(L, "point");
			lua_setmetatable(L, -2);
		}
		else if (std::strcmp(field, "topright") == 0) {
			Point *p = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
			*p = q->topright;
			luaL_getmetatable(L, "point");
			lua_setmetatable(L, -2);
		}
		else if (std::strcmp(field, "bottomright") == 0) {
			Point *p = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
			*p = q->bottomright;
			luaL_getmetatable(L, "point");
			lua_setmetatable(L, -2);
		}
		else if (std::strcmp(field, "bottomleft") == 0) {
			Point *p = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
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
		Point *value = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));

		
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
