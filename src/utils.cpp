#include <cstring>
#include <iostream>
#include <iomanip>
#include <filesystem>

#include <Orbit/lua.h>
#include <Orbit/vector.h>
#include <Orbit/rect.h>
#include <Orbit/quad.h>

#include <spdlog/spdlog.h>
#include <raylib.h>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

using Orbit::Lua::Vector;
using Orbit::Lua::Rect;
using Orbit::Lua::Quad;

inline Vector2 rotate_vector(Vector2 v, float degrees, const Vector2 &p) {
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

inline Vector2 mix(Vector2 v1, Vector2 v2, float t) {
	return Vector2{v1.x * (1 - t) + v2.x * t, v1.y * (1 - t) + v2.y};
}

inline float distance(Vector2 v1, Vector2 v2) {
	return std::sqrt(abs(v1.x - v2.x) + abs(v1.y - v2.y));
}

int distance_vector(lua_State *L, const Vector *v1, const Vector *v2) {

	auto res = v1->distance(*v2);

	lua_pushnumber(L, res);
	return 1;
}

int distance_point(lua_State *L, const Vector2 *p1, const Vector2 *p2) {

	auto res = distance(*p1, *p2);

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
		return distance_point(L, static_cast<Vector2 *>(p1), static_cast<Vector2 *>(p2));
	}
	else {
		return luaL_error(L, "invalid parameters");
	}
}

//

int mix_vector(lua_State *L, const Vector *v1, const Vector *v2, float t) {
	auto res = v1->mix(*v2, t);

	Vector *res_vec = new Vector();
	*res_vec = res;

	Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
	*udata = res_vec;

	luaL_getmetatable(L, "vector");
	lua_setmetatable(L, -2);

	return 1;
}

int mix_point(lua_State *L, const Vector2 *p1, const Vector2 *p2, float t) {
	auto res = mix(*p1, *p2, t);

	Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
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
		return mix_point(L, static_cast<Vector2 *>(p1), static_cast<Vector2 *>(p2), t);
	}
	else {
		return luaL_error(L, "invalid parameters");
	}
}

//


int make_vector(lua_State *L) {
	Vector **v = nullptr;

	Vector2 *p1 = nullptr;
	Vector2 *p2 = nullptr;

	Vector *p = new Vector();

	if ((v = static_cast<Vector **>(luaL_testudata(L, 1, "vector"))) != nullptr) {
		memcpy(p->_data, (*v)->_data, sizeof(float) * 4);
	} else if (
			(p1 = static_cast<Vector2 *>(luaL_testudata(L, 1, "point"))) != nullptr &&
			(p2 = static_cast<Vector2 *>(luaL_testudata(L, 2, "point"))) != nullptr
		) {
		
		p->_data[0] = p1->x;
		p->_data[1] = p1->y;
		p->_data[2] = p2->x;
		p->_data[3] = p2->y;
	} else {
		p->_data[0] = lua_tonumber(L, 1);
		p->_data[1] = lua_tonumber(L, 2);
		p->_data[2] = lua_tonumber(L, 3);
		p->_data[3] = lua_tonumber(L, 4);
	}

	Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector*)));
	*udata = p;

	luaL_getmetatable(L, "vector");
	lua_setmetatable(L, -2);
	
	return 1;
}
int make_point(lua_State *L) {
	Vector2 *arg = nullptr;

	Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
	
	if ((arg = static_cast<Vector2 *>(luaL_testudata(L, 1, "point")))) {
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

	Vector2 *p1 = nullptr;
	Vector2 *p2 = nullptr;

	Color *c = nullptr;

	Rect *p = new Rect();

	if ((v = static_cast<Vector **>(luaL_testudata(L, 1, "rect"))) != nullptr) {
		memcpy(p->_data, (*v)->_data, sizeof(float) * 4);
	} else if ((v = static_cast<Vector **>(luaL_testudata(L, 1, "vector"))) != nullptr) {
		memcpy(p->_data, (*v)->_data, sizeof(float) * 4);
	} else if (
			(p1 = static_cast<Vector2 *>(luaL_testudata(L, 1, "point"))) != nullptr &&
			(p2 = static_cast<Vector2 *>(luaL_testudata(L, 2, "point"))) != nullptr
		) {
		p->_data[0] = p1->x;
		p->_data[1] = p1->y;
		p->_data[2] = p2->x;
		p->_data[3] = p2->y;
	} else if ((c = static_cast<Color *>(luaL_testudata(L, 1, "color"))) != nullptr) {
		p->_data[0] = c->r;
		p->_data[1] = c->g;
		p->_data[2] = c->b;
		p->_data[3] = c->a;
	} else {
		p->_data[0] = lua_tonumber(L, 1);
		p->_data[1] = lua_tonumber(L, 2);
		p->_data[2] = lua_tonumber(L, 3);
		p->_data[3] = lua_tonumber(L, 4);
	}

	Rect **udata = static_cast<Rect **>(lua_newuserdata(L, sizeof(Rect*)));
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


int rotate_point(lua_State *L, const Vector2 *p, float degrees, const Vector2 *center) {
	Vector2 c = (center == nullptr) ? Vector2{0, 0} : *center;

	Vector2 *res = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

	*res = rotate_vector(*p, degrees, *center);

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);
	
	return 1;
}

int rotate_quad(lua_State *L, const Quad *q, float degrees, const Vector2 *center) {
	Quad *nq = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));
	*nq = q->rotate(degrees, (center == nullptr) ? q->center() : *center);

	luaL_getmetatable(L, "quad");
	lua_setmetatable(L, -2);

	return 1;
}

int rotate_rect(lua_State *L, const Rect *r, float degrees, const Vector2 *center) {
	Quad q = Quad(
				Vector2{r->left(), r->top()}, 
				Vector2{r->right(), r->top()}, 
				Vector2{r->right(), r->bottom()}, 
				Vector2{r->left(), r->bottom()}
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
	Vector2 *center = static_cast<Vector2 *>(luaL_testudata(L, 3, "point"));

	if (
			(p1 = luaL_testudata(L, 1, "point")) != nullptr
		) 
		{
		return rotate_point(L, static_cast<Vector2 *>(p1), degrees, center);
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
				*q = Quad(
					Vector2{r->left(), r->top()}, 
					Vector2{r->right(), r->top()}, 
					Vector2{r->right(), r->bottom()}, 
					Vector2{r->left(), r->bottom()}
				);
				
				luaL_getmetatable(L, "quad");
				lua_setmetatable(L, -2);
			}
		} break;

		case 4: {
			Vector2 *tl = static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
			Vector2 *tr = static_cast<Vector2 *>(luaL_checkudata(L, 2, "point"));
			Vector2 *br = static_cast<Vector2 *>(luaL_checkudata(L, 3, "point"));
			Vector2 *bl = static_cast<Vector2 *>(luaL_checkudata(L, 4, "point"));
				
			
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
				std::memcpy(rect._data, r->_data, sizeof(float) * 4);
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
			Vector2 *p = static_cast<Vector2 *>(arg1);

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

	Vector2 *res = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

	if ((arg = luaL_testudata(L, 1, "point")) != nullptr) {
		Vector2 *p = static_cast<Vector2 *>(arg);

		*res = *p;
	}
	else if ((arg = luaL_testudata(L, 1, "rectangle"))) {
		Rect *r = *static_cast<Rect **>(arg);

		*res = Vector2{(r->left() + r->right()) / 2.0f, (r->top() + r->bottom()) / 2.0f};
	}
	else if ((arg = luaL_testudata(L, 1, "vector"))) {
		Vector *v = *static_cast<Vector **>(arg);

		*res = Vector2{(v->x() + v->y()) / 2.0f, (v->z() + v->w()) / 2.0f};
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

					auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));
					
					auto base_path = runtime->paths->data().string();
					
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

int draw(lua_State *L) {
	const char *text = luaL_checkstring(L, 1);
	int x = lua_tonumber(L, 2);
	int y = lua_tonumber(L, 3);
	Color *c = static_cast<Color *>(luaL_testudata(L, 4, "color"));
	int size = lua_tonumber(L, 5);

	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

	BeginTextureMode(runtime->viewport);
	DrawText(text, x, y, size ? 20 : size, *c);
	EndTextureMode();

	runtime->_set_redraw();

	return 0;
}

int clear(lua_State *L) {
	Color *c = nullptr;

	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

	BeginTextureMode(runtime->viewport);

	if ((c = static_cast<Color *>(luaL_testudata(L, 1, "point"))) != nullptr) {
		ClearBackground(*c);
	} else {
		ClearBackground(WHITE);
	}

	EndTextureMode();

	return 0;

}

int log(lua_State *L) {
	const char *text = luaL_checkstring(L, 1);

	auto* runtime = static_cast<Orbit::Lua::LuaRuntime*>(lua_touserdata(L, lua_upvalueindex(1)));

	runtime->logger->info(std::string("[script]: ") + text);

	return 0;
}

int mouse_pos(lua_State *L) {
	Vector2 *mpos = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
	
	*mpos = GetMousePosition();

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);

	return 1;
}

namespace Orbit::Lua {

void LuaRuntime::_register_utils() {
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

	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, draw, 1);
	lua_setglobal(L, "draw");

	lua_pushcfunction(L, log);
	lua_setglobal(L, "log");

	lua_pushcfunction(L, mouse_pos);
	lua_setglobal(L, "mouse_pos");

	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, clear, 1);
	lua_setglobal(L, "clear");
}

};
