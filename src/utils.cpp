#include <cstring>

#include <Orbit/lua.h>
#include <Orbit/vector.h>
#include <Orbit/point.h>
#include <Orbit/color.h>
#include <Orbit/rect.h>
#include <Orbit/quad.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

using Orbit::Lua::Vector;
using Orbit::Lua::Point;
using Orbit::Lua::Color;
using Orbit::Lua::Rectangle;
using Orbit::Lua::Quad;

int distance_vector(lua_State *L, const Vector *v1, const Vector *v2) {

	auto res = v1->distance(*v2);

	lua_pushnumber(L, res);
	return 1;
}

int distance_point(lua_State *L, const Point *p1, const Point *p2) {

	auto res = p1->distance(*p2);

	lua_pushnumber(L, res);
	return 1;
}

int distance(lua_State *L) {
	void *p1 = nullptr;
	void *p2 = nullptr;

	if (
			(p1 = luaL_testudata(L, 1, "vector")) != nullptr &&
			(p2 = luaL_testudata(L, 2, "vector")) != nullptr
		) {
		return distance_vector(L, *static_cast<Vector **>(p1), *static_cast<Vector **>(p2));
	}
	else if (
			(p1 = luaL_testudata(L, 1, "point")) != nullptr &&
			(p2 = luaL_testudata(L, 2, "point")) != nullptr
	) {
		return distance_point(L, static_cast<Point *>(p1), static_cast<Point *>(p2));
	}
	else {
		return luaL_error(L, "invalid parameters");
	}
}

//

int mix_vector(lua_State *L, const Vector *v1, const Vector *v2, float t) {
	auto res = v1->mix(*v2, t);

#ifdef __WIN32
		Vector *res_vec = static_cast<Vector *>(_aligned_malloc(16, sizeof(Vector)));
#else
		Vector *res_vec = static_cast<Vector *>(aligned_alloc(16, sizeof(Vector)));
#endif

		*res_vec = res;

		Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
		*udata = res_vec;

		luaL_getmetatable(L, "vector");
		lua_setmetatable(L, -2);

	return 1;
}

int mix_point(lua_State *L, const Point *p1, const Point *p2, float t) {
	auto res = p1->mix(*p2, t);

	Point *p = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
	*p = res;

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);

	return 1;
}

int mix(lua_State *L) {

	void *p1 = nullptr;
	void *p2 = nullptr;

	float t = luaL_checknumber(L, 3);

	if (
			(p1 = luaL_testudata(L, 1, "vector")) != nullptr &&
			(p2 = luaL_testudata(L, 2, "vector")) != nullptr
		) {
		return mix_vector(L, *static_cast<Vector **>(p1), *static_cast<Vector **>(p2), t);
	}
	else if (
			(p1 = luaL_testudata(L, 1, "point")) != nullptr &&
			(p2 = luaL_testudata(L, 2, "point")) != nullptr
	) {
		return mix_point(L, static_cast<Point *>(p1), static_cast<Point *>(p2), t);
	}
	else {
		return luaL_error(L, "invalid parameters");
	}
}

//


int make_vector(lua_State *L) {
	Vector **v = nullptr;

	Point *p1 = nullptr;
	Point *p2 = nullptr;

#ifdef __WIN32
	Vector *p = static_cast<Vector *>(_aligned_malloc(16, sizeof(Vector)));
#else
	Vector *p = static_cast<Vector *>(aligned_alloc(16, sizeof(Vector)));
#endif

	if ((v = static_cast<Vector **>(luaL_testudata(L, 1, "vector"))) != nullptr) {
		memcpy(p->data, (*v)->data, sizeof(float) * 4);
	} else if (
			(p1 = static_cast<Point *>(luaL_testudata(L, 1, "point"))) != nullptr &&
			(p2 = static_cast<Point *>(luaL_testudata(L, 2, "point"))) != nullptr
		) {
		
		p->data[0] = p1->x;
		p->data[1] = p1->y;
		p->data[2] = p2->x;
		p->data[3] = p2->y;
	} else {
		p->data[0] = lua_tonumber(L, 1);
		p->data[1] = lua_tonumber(L, 2);
		p->data[2] = lua_tonumber(L, 3);
		p->data[3] = lua_tonumber(L, 4);
	}

	Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
	*udata = p;

	luaL_getmetatable(L, "vector");
	lua_setmetatable(L, -2);
	
	return 1;
}
int make_point(lua_State *L) {
	Point *arg = nullptr;

	Point *p = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
	
	if ((arg = static_cast<Point *>(luaL_testudata(L, 1, "point")))) {
		p->x = arg->x;
		p->y = arg->y;
	} else {
		p->x = lua_tonumber(L, 1);
		p->y = lua_tonumber(L, 2);
	}

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);
	
	return 1;

}
int make_rect(lua_State *L) {
	Vector **v = nullptr;

	Point *p1 = nullptr;
	Point *p2 = nullptr;

#ifdef __WIN32
	Vector *p = static_cast<Vector *>(_aligned_malloc(16, sizeof(Vector)));
#else
	Vector *p = static_cast<Vector *>(aligned_alloc(16, sizeof(Vector)));
#endif

	if ((v = static_cast<Vector **>(luaL_testudata(L, 1, "rect"))) != nullptr) {
		memcpy(p->data, (*v)->data, sizeof(float) * 4);
	} else if ((v = static_cast<Vector **>(luaL_testudata(L, 1, "vector"))) != nullptr) {
		memcpy(p->data, (*v)->data, sizeof(float) * 4);
	} else if (
			(p1 = static_cast<Point *>(luaL_testudata(L, 1, "point"))) != nullptr &&
			(p2 = static_cast<Point *>(luaL_testudata(L, 2, "point"))) != nullptr
		) {
		
		p->data[0] = p1->x;
		p->data[1] = p1->y;
		p->data[2] = p2->x;
		p->data[3] = p2->y;
	} else {
		p->data[0] = lua_tonumber(L, 1);
		p->data[1] = lua_tonumber(L, 2);
		p->data[2] = lua_tonumber(L, 3);
		p->data[3] = lua_tonumber(L, 4);
	}

	Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
	*udata = p;

	luaL_getmetatable(L, "rect");
	lua_setmetatable(L, -2);
	
	return 1;
}
int make_color(lua_State *L) {
	int argcount = lua_gettop(L);
    
	Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
	
	if (argcount == 0) {
		*p = Color();
	}
	else if (argcount == 1) {
		Color *arg = nullptr;

	
		if ((arg = static_cast<Color *>(luaL_testudata(L, 1, "color")))) {
			*p = Color(*arg);
		}
		else {
			p->r = lua_tonumber(L, 1);
			p->g = 255;
			p->b = 255;
			p->a = 255;
		}
	}
	else {
		*p = Color();
		
		if (lua_isnumber(L, 1)) p->r = lua_tonumber(L, 1);
		if (lua_isnumber(L, 2)) p->g = lua_tonumber(L, 2);
		if (lua_isnumber(L, 3)) p->b = lua_tonumber(L, 3);
		if (lua_isnumber(L, 4)) p->a = lua_tonumber(L, 4);
	}
	
	luaL_getmetatable(L, "color");
	lua_setmetatable(L, -2);
	
	return 1;
}

void define_constant_colors(lua_State *L) {
	lua_getglobal(L, "_G");

	lua_newtable(L);

	lua_pushstring(L, "__newindex");
	lua_pushcfunction(L, [](lua_State *L) {
		const char *key = lua_tostring(L, 2);
		if (
				!std::strcmp(key, "WHITE") || !std::strcmp(key, "BLACK") ||
				!std::strcmp(key, "RED") || !std::strcmp(key, "GREEN") ||
				!std::strcmp(key, "BLUE") || !std::strcmp(key, "PURPLE")
		) {
			return luaL_error(L, "attempt to modify color constant");
		}
		lua_rawset(L, 1);
		return 0;
	});
	lua_settable(L, -3);

	lua_setmetatable(L, -2);
	lua_pop(L, 1);

	// define constant colors here
}


int rotate_point(lua_State *L, const Point *p, float degrees, const Point *center);
int rotate_quad(lua_State *L, const Quad *q, float degrees, const Point *center);
int rotate_rect(lua_State *L, const Rectangle *r, float degrees, const Point *center);

int rotate(lua_State *L) {
	void *p1 = nullptr;

	float degrees = luaL_checknumber(L, 2);
	Point *center = static_cast<Point *>(luaL_testudata(L, 3, "point"));

	if (
			(p1 = luaL_testudata(L, 1, "point")) != nullptr
		) {
		return rotate_point(L, static_cast<Point *>(p1), degrees, center);
	}
	else if (
			(p1 = luaL_testudata(L, 1, "quad")) != nullptr
	) {
		return rotate_quad(L, static_cast<Quad *>(p1), degrees, center);
	}
	else if (
			(p1 = luaL_testudata(L, 1, "rect")) != nullptr
	) {
		return rotate_rect(L, static_cast<Rectangle *>(p1), degrees, center);
	}
	else {
		return luaL_error(L, "invalid parameters");
	}


}

namespace Orbit::Lua {

void LuaRuntime::_register_utils() {

	lua_pushcfunction(L, distance);
	lua_setglobal(L, "distance");

	lua_pushcfunction(L, mix);
	lua_setglobal(L, "mix");

	lua_pushcfunction(L, rotate);
	lua_setglobal(L, "rotate");

 	lua_pushcfunction(L, make_vector);
	lua_setglobal(L, "vector");

 	lua_pushcfunction(L, make_point);
	lua_setglobal(L, "point");

	lua_pushcfunction(L, make_rect);
	lua_setglobal(L, "rect");

	lua_pushcfunction(L, make_color);
	lua_setglobal(L, "color");
}

};
