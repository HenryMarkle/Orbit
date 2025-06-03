#include <cstring>
#include <filesystem>

#include <Orbit/lua.h>
#include <Orbit/vector.h>
#include <Orbit/point.h>
#include <Orbit/rect.h>
#include <Orbit/quad.h>

#include <raylib.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

using Orbit::Lua::Vector;
using Orbit::Lua::Point;
using Orbit::Lua::Rect;
using Orbit::Lua::Quad;

std::string base_path;

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
    
	
	if (argcount == 0) {
		Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
		*p = Color();
	}
	else if (argcount == 1) {
		Color *arg = nullptr;
	
		if ((arg = static_cast<Color *>(luaL_testudata(L, 1, "color")))) {
			Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
			*p = Color(*arg);
		}
		else {
			Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
			uint32_t packed = static_cast<uint32_t>(luaL_checkinteger(L, 1));
			
			p->r = static_cast<uint8_t>(packed & 0xFF);
			p->g = static_cast<uint8_t>((packed >>  8) & 0xFF);
			p->b = static_cast<uint8_t>((packed >> 16) & 0xFF);
			p->a = static_cast<uint8_t>((packed >> 24) & 0xFF);
		}
	}
	else if (argcount == 3) {
		Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
		
		p->r = lua_tonumber(L, 1);
		p->g = lua_tonumber(L, 2);
		p->b = lua_tonumber(L, 3);
		p->a = 255;
	}
	else {
		Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
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


int rotate_point(lua_State *L, const Point *p, float degrees, const Point *center) {
	Point c = (center == nullptr) ? Point(0, 0) : *center;

	Point *res = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));
	*res = p->rotate(degrees, c);

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);
	
	return 1;
}

int rotate_quad(lua_State *L, const Quad *q, float degrees, const Point *center) {
	Quad *nq = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));
	*nq = q->rotate(degrees, (center == nullptr) ? q->center() : *center);

	luaL_getmetatable(L, "quad");
	lua_setmetatable(L, -2);

	return 1;
}

int rotate_rect(lua_State *L, const Rect *r, float degrees, const Point *center) {
	Quad q = Quad(
				Point(r->left(), r->top()), 
				Point(r->right(), r->top()), 
				Point(r->right(), r->bottom()), 
				Point(r->left(), r->bottom())
			);

	Quad *nq = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));
	*nq = q.rotate(degrees, (center == nullptr) ? q.center() : *center);

	luaL_getmetatable(L, "quad");
	lua_setmetatable(L, -2);

	return 1;
}

int rotate(lua_State *L) {
	void *p1 = nullptr;

	float degrees = luaL_checknumber(L, 2);
	Point *center = static_cast<Point *>(luaL_testudata(L, 3, "point"));

	if (
			(p1 = luaL_testudata(L, 1, "point")) != nullptr
		) 
		{
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
		return rotate_rect(L, static_cast<Rect *>(p1), degrees, center);
	}
	else {
		return luaL_error(L, "invalid parameters");
	}
}

int make_quad(lua_State *L) {
	int count = lua_gettop(L);

	switch (count) {
	
		case 1: {
			void *p = nullptr;
	
			if ((p = luaL_checkudata(L, 1, "quad")) != nullptr) {
				Quad *q = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));
				*q = *static_cast<Quad *>(p);
			
				luaL_getmetatable(L, "quad");
				lua_setmetatable(L, -2);
			}
			else if ((p = luaL_checkudata(L, 1, "rectangle")) != nullptr) {
				Quad *q = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));
				Rect *r = static_cast<Rect *>(p);
				*q = Quad(Point(r->left(), r->top()), Point(r->right(), r->top()), Point(r->right(), r->bottom()), Point(r->left(), r->bottom()));
				
				luaL_getmetatable(L, "quad");
				lua_setmetatable(L, -2);
			}
		} break;

		case 4: {
			Point *tl = static_cast<Point *>(luaL_checkudata(L, 1, "point"));
			Point *tr = static_cast<Point *>(luaL_checkudata(L, 2, "point"));
			Point *br = static_cast<Point *>(luaL_checkudata(L, 3, "point"));
			Point *bl = static_cast<Point *>(luaL_checkudata(L, 4, "point"));
				
			
			Quad *q = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));
			*q = Quad(*tl, *tr, *br, *bl);	
			
			luaL_getmetatable(L, "quad");
			lua_setmetatable(L, -2);
		} break;
	
		default: return luaL_error(L, "invalid number of arguments to quad");
	}
	return 1;
}

int enclose(lua_State *L) {
	int count = lua_gettop(L);

	if (count <= 0) return luaL_error(L, "insuffient arguments to function enclose");

	Rect rect = Rect(0, 0, 0, 0);

	for (int c = 1; c <= count; c++) {
		void *arg1 = nullptr;

		if ((arg1 = luaL_testudata(L, c, "rectangle")) != nullptr) {
			Rect *r = *static_cast<Rect **>(arg1);

			if (c == 0) {
				std::memcpy(rect.data, r->data, sizeof(float) * 4);
				continue;
			}

			if (r->left() < rect.left()) rect.left() = r->left();
			if (r->left() > rect.right()) rect.right() = r->left();

			if (r->top() < rect.top()) rect.top() = r->top();
			if (r->top() > rect.bottom()) rect.bottom() = r->top();

			if (r->right() > rect.right()) rect.right() = r->right();
			if (r->right() < rect.left()) rect.left() = r->right();
			
			if (r->bottom() > rect.bottom()) rect.bottom() = r->bottom();
			if (r->bottom() < rect.top()) rect.top() = r->bottom();
		}
		else if ((arg1 = luaL_testudata(L, c, "quad")) != nullptr) {
			Quad *quad = static_cast<Quad *>(arg1);

			float minx = std::min(std::min(quad->topleft.x, quad->topright.x), std::min(quad->bottomleft.x, quad->bottomright.x));
			float miny = std::min(std::min(quad->topleft.y, quad->topright.y), std::min(quad->bottomleft.y, quad->bottomright.y));
		
			float maxx = std::max(std::max(quad->topleft.x, quad->topright.x), std::max(quad->bottomleft.x, quad->bottomright.x));
			float maxy = std::max(std::max(quad->topleft.y, quad->topright.y), std::max(quad->bottomleft.y, quad->bottomright.y));
		
			if (minx < rect.left()) rect.left() = minx;
			if (miny < rect.top()) rect.top() = miny;
			if (maxx > rect.right()) rect.right() = maxx;
			if (maxy > rect.bottom()) rect.bottom() = maxy;
		}
		else if ((arg1 = luaL_testudata(L, c, "point")) != nullptr) {
			Point *p = static_cast<Point *>(arg1);

			if (p->x < rect.left()) rect.left() = p->x;
			if (p->x > rect.right()) rect.right() = p->x;
			if (p->y < rect.top()) rect.top() = p->y;
			if (p->y > rect.bottom()) rect.bottom() = p->y;
		}
		else {
			return luaL_error(L, "invalid enclose argument %d", c);
		}	
	}

	Rect **res = static_cast<Rect **>(lua_newuserdata(L, sizeof(Rect *)));
	**res = rect;

	luaL_getmetatable(L, "rectangle");
	lua_setmetatable(L, -2);

	return 1;
}

int center(lua_State *L) {
	void *arg = nullptr;

	Point *res = static_cast<Point *>(lua_newuserdata(L, sizeof(Point)));

	if ((arg = luaL_testudata(L, 1, "point")) != nullptr) {
		Point *p = static_cast<Point *>(arg);

		*res = *p;
	}
	else if ((arg = luaL_testudata(L, 1, "rectangle"))) {
		Rect *r = *static_cast<Rect **>(arg);

		*res = Point((r->left() + r->right()) / 2.0f, (r->top() + r->bottom()) / 2.0f);
	}
	else if ((arg = luaL_testudata(L, 1, "vector"))) {
		Vector *v = *static_cast<Vector **>(arg);

		*res = Point((v->x() + v->y()) / 2.0f, (v->z() + v->w()) / 2.0f);
	}
	else if ((arg = luaL_testudata(L, 1, "quad"))) {
		Quad *q = static_cast<Quad *>(arg);

		*res = q->center();
	}
	else {
		return luaL_error(L, "invalid argument for function center");
	}

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);

	return 1;
}

int make_image(lua_State *L) {
		int count = lua_gettop(L);

		switch (count) {
			case 1: {
				if (lua_isstring(L, 1)) {
					const char *path = luaL_checkstring(L, 1);
			
					std::filesystem::path full = std::filesystem::weakly_canonical(base_path + path);

					if (full.string().rfind(base_path, 0) != 0) {
						return luaL_error(L, "access denied");
					}

					Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
					*img = LoadImage(full.string().c_str());
				} else {
					Image *img = static_cast<Image *>(luaL_checkudata(L, 1, "image"));

					Image *copy = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));

					*copy = ImageCopy(*img);
				}			
			}
			break;
				
			case 2: {
				int width = luaL_checkinteger(L, 1);
				int height = luaL_checkinteger(L, 2);
		
				Image nimg = GenImageColor(width, height, { 255, 255, 255, 255 });
				Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
				*img = nimg;
			}
			break;

			case 3: {
				int width = luaL_checkinteger(L, 1);
				int height = luaL_checkinteger(L, 2);
				Color *color = static_cast<Color *>(luaL_checkudata(L, 3, "color"));

				Image nimg = GenImageColor(width, height, { color->r, color->g, color->b, color->a });
				Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
				*img = nimg;
			}
			break;
		}

		luaL_getmetatable(L, "image");
		lua_setmetatable(L, -2);

		return 1;
};

int random_seed(lua_State *L) {
	int seed = lua_tointeger(L, 1);

	return 0;
}

int random_gen(lua_State *L) {
	lua_pushinteger(L, 0);
	return 1;
}

namespace Orbit::Lua {

void LuaRuntime::_register_utils() {
	base_path = _paths->data().string();

	lua_pushcfunction(L, distance);
	lua_setglobal(L, "distance");

	lua_pushcfunction(L, mix);
	lua_setglobal(L, "mix");

	lua_pushcfunction(L, rotate);
	lua_setglobal(L, "rotate");

	lua_pushcfunction(L, enclose);
	lua_setglobal(L, "enclose");

	lua_pushcfunction(L, center);
	lua_setglobal(L, "center");

	lua_pushcfunction(L, make_vector);
	lua_setglobal(L, "vector");

 	lua_pushcfunction(L, make_point);
	lua_setglobal(L, "point");

	lua_pushcfunction(L, make_rect);
	lua_setglobal(L, "rect");

	lua_pushcfunction(L, make_color);
	lua_setglobal(L, "color");

	lua_pushcfunction(L, make_quad);
	lua_setglobal(L, "quad");

	lua_pushcfunction(L, make_image);
	lua_setglobal(L, "image");

	lua_pushcfunction(L, random_seed);
	lua_setglobal(L, "seed");

	lua_pushcfunction(L, random_gen);
	lua_setglobal(L, "random");
}

};
