#include <cstring>
#include <iomanip>
#include <sstream>
#include <iostream>
#include <filesystem>

#include <Orbit/Lua/runtime.h>
#include <Orbit/Lua/random.h>
#include <Orbit/Lua/vector.h>
#include <Orbit/Lua/rect.h>
#include <Orbit/Lua/quad.h>
#include <Orbit/RlExt/image.h>
#include <Orbit/RlExt/rl.h>

#include <MobitParser/tokens.h>
#include <MobitParser/nodes.h>

#include <spdlog/spdlog.h>
#include <raylib.h>
#include <rlgl.h>

extern "C" {
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

using Orbit::Lua::Quad;
using Orbit::Lua::Rect;
using Orbit::Lua::Vector;

static size_t lua_len(lua_State *L, int index)
{
	if (index < 0)
		index = lua_gettop(L) + index + 1;

	lua_pushvalue(L, index);
	if (luaL_callmeta(L, -1, "__len"))
	{
		lua_remove(L, -2);
		return (size_t)lua_tointeger(L, -1);
	}
	else
	{
		lua_pop(L, 1);
		return lua_objlen(L, index);
	}
}

#define LUA_LEN(s, a) lua_len(s, a)
#define LUA_IS_EQUAL(s, a, b) lua_equal(s, a, b)


inline Orbit::RlExt::CopyImageParams parse_params(lua_State *L, int index)
{
	luaL_checktype(L, index, LUA_TTABLE);

	auto params = Orbit::RlExt::CopyImageParams();

	lua_getfield(L, index, "ink");
	if (!lua_isnil(L, -1))
	{
		params.ink = static_cast<Orbit::RlExt::CopyImageInk>(lua_tointeger(L, -1));
	}
	lua_pop(L, 1);

	lua_getfield(L, index, "blend");
	if (!lua_isnil(L, -1))
	{
		params.blend = lua_tonumber(L, -1);
	}
	lua_pop(L, 1);

	lua_getfield(L, index, "color");
	if (!lua_isnil(L, -1))
	{
		Color *c = static_cast<Color *>(luaL_checkudata(L, -1, "color"));
		if (c)
			params.color = *c;
	}
	lua_pop(L, 1);

	lua_getfield(L, index, "mask");
	if (!lua_isnil(L, -1))
	{
		RenderTexture2D *i = static_cast<RenderTexture2D *>(luaL_checkudata(L, -1, "image"));
		params.mask = &i->texture;
	}
	lua_pop(L, 1);

	return params;
}

inline Vector2 rotate_vector(Vector2 v, float degrees, const Vector2 &p)
{
	float rad = fmodf(degrees, 360.0f) * PI / 180.0f;

	float sinr = sinf(rad);
	float cosr = cosf(rad);

	float dx = v.x - p.x;
	float dy = v.y - p.y;

	return Vector2{
		p.x + dx * cosr - dy * sinr,
		p.y + dx * sinr + dy * cosr};
}

inline std::ostream &operator<<(std::ostream &out, Vector2 v)
{
	return out << "point("
			   << std::setprecision(4) << v.x << ", "
			   << std::setprecision(4) << v.y
			   << ')';
}

inline Vector2 mix(Vector2 v1, Vector2 v2, float t)
{
	return Vector2{v1.x * (1 - t) + v2.x * t, v1.y * (1 - t) + v2.y};
}

inline float distance(Vector2 v1, Vector2 v2)
{
	return std::sqrt(abs(v1.x - v2.x) + abs(v1.y - v2.y));
}

static int list_get_pos(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TTABLE);

	lua_pushnil(L);

	while (lua_next(L, 1) != 0)
	{
		if (LUA_IS_EQUAL(L, -1, 2))
		{
			lua_pop(L, 1);
			return 1;
		}

		lua_pop(L, 1);
	}

	lua_pushinteger(L, 0);
	return 1;
}

static int list_delete_one(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TTABLE);

	lua_Integer tableLen = (lua_Integer)LUA_LEN(L, 1);
	lua_pop(L, 1);

	lua_Integer foundIndex = -1;
	for (lua_Integer i = 1; i <= tableLen; ++i)
	{
		lua_rawgeti(L, 1, i);

		if (LUA_IS_EQUAL(L, -1, 2))
		{
			foundIndex = i;
			lua_pop(L, 1);
			break;
		}
		lua_pop(L, 1);
	}

	// If element not found, just return
	if (foundIndex == -1)
	{
		return 0;
	}

	for (lua_Integer i = foundIndex; i < tableLen; ++i)
	{
		lua_rawgeti(L, 1, i + 1); // Get element at position i+1
		lua_rawseti(L, 1, i);
	}

	// Remove the last element (now duplicated)
	lua_pushnil(L);
	lua_rawseti(L, 1, tableLen);

	return 0;
}

static int lua_list_add_at(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TTABLE);
	int index = luaL_checkinteger(L, 2);

	int len = (int)LUA_LEN(L, 1);

	if (index < 1 || index > len + 1)
	{
		return luaL_error(L, "addAt: index out of range");
	}

	for (int i = len; i >= index; --i)
	{
		lua_rawgeti(L, 1, i);
		lua_rawseti(L, 1, i + 1);
	}

	lua_pushvalue(L, 3);
	lua_rawseti(L, 1, index);

	return 0;
}

static int lua_list_delete_at(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TTABLE);
	int index = luaL_checkinteger(L, 2);

	int len = (int)LUA_LEN(L, 1); // Use lua_rawlen for table length

	if (index < 1 || index > len)
	{
		return luaL_error(L, "removeAt: index out of range");
	}

	// Shift elements left
	for (int i = index; i < len; ++i)
	{
		lua_rawgeti(L, 1, i + 1); // get table[i + 1]
		lua_rawseti(L, 1, i);	  // set table[i] = table[i + 1]
	}

	// Set last element to nil
	lua_pushnil(L);
	lua_rawseti(L, 1, len);

	return 0; // no return values
}

static int lua_list_add(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TTABLE);

	int len = (int)LUA_LEN(L, 1);
	lua_pushvalue(L, 2);
	lua_rawseti(L, 1, len + 1); // set at position len+1

	// May be inefficient

	// lua_getglobal(L, "table");
	// lua_getfield(L, -1, "sort");
	// lua_remove(L, -2);

	// lua_pushvalue(L, -2);             // Push the table to sort (assume it's at -2)

	// if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
	// 	const char* err = lua_tostring(L, -1);
	// 	std::cerr << "Error sorting table: " << err << std::endl;
	// 	lua_pop(L, 1);
	// }

	return 0;
}

static void register_list_extensions(lua_State *L)
{
	lua_newtable(L);

	lua_pushcfunction(L, list_get_pos);
	lua_setfield(L, -2, "getPos");

	lua_pushcfunction(L, list_delete_one);
	lua_setfield(L, -2, "deleteOne");

	lua_pushcfunction(L, lua_list_delete_at);
	lua_setfield(L, -2, "deleteAt");

	lua_pushcfunction(L, lua_list_add_at);
	lua_setfield(L, -2, "addAt");

	lua_pushcfunction(L, lua_list_add);
	lua_setfield(L, -2, "add");

	lua_pushcfunction(L, lua_list_add);
	lua_setfield(L, -2, "append");

	lua_newtable(L);
	lua_pushvalue(L, -2);
	lua_setfield(L, -2, "__index");		  // metatable.__index = methods
	lua_setglobal(L, "__list_metatable"); // Store metatable globally

	lua_pop(L, 1);
}

static void attach_list_methods(lua_State *L, int index)
{
	lua_getglobal(L, "__list_metatable");
	lua_setmetatable(L, index < 0 ? index - 1 : index);
}

static int lua_list_constructor(lua_State *L)
{
	if (!lua_gettop(L))
	{
		lua_createtable(L, 0, 0);
		attach_list_methods(L, -1);
		return 1;
	}

	luaL_checktype(L, 1, LUA_TTABLE);

	size_t len = LUA_LEN(L, 1);

	lua_createtable(L, len, 0);

	for (size_t i = 1; i <= len; ++i)
	{
		lua_rawgeti(L, 1, (int)i);
		lua_rawseti(L, -2, (int)i);
	}

	attach_list_methods(L, -1);

	return 1;
}

static int lua_map_find_pos(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TTABLE);

	lua_pushnil(L);

	while (lua_next(L, 1) != 0)
	{
		if (LUA_IS_EQUAL(L, -1, 2))
		{
			lua_pop(L, 1);
			return 1;
		}

		lua_pop(L, 1);
	}

	lua_pushinteger(L, 0);
	return 1;
}

static int lua_map_add_prop(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TTABLE);

	if (!lua_isstring(L, 2))
	{
		return luaL_error(L, "Second argument must be a string key");
	}

	lua_pushvalue(L, 2);
	lua_pushvalue(L, 3);
	lua_settable(L, 1);

	// May be inefficient

	// lua_getglobal(L, "table");
	// lua_getfield(L, -1, "sort");
	// lua_remove(L, -2);

	// lua_pushvalue(L, -2);             // Push the table to sort (assume it's at -2)

	// if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
	// 	const char* err = lua_tostring(L, -1);
	// 	std::cerr << "Error sorting table: " << err << std::endl;
	// 	lua_pop(L, 1);
	// }

	return 0;
}

static int lua_map_delete_prop(lua_State *L)
{
	if (!lua_istable(L, 1))
	{
		return luaL_error(L, "Expected table as first argument");
	}

	lua_pushvalue(L, 2); // key

	lua_pushnil(L);

	lua_settable(L, 1); // pops key and nil

	return 0;
}

static void register_map_extensions(lua_State *L)
{
	lua_newtable(L);

	lua_pushcfunction(L, lua_map_find_pos);
	lua_setfield(L, -2, "findPos");

	lua_pushcfunction(L, lua_map_add_prop);
	lua_setfield(L, -2, "addProp");

	lua_pushcfunction(L, lua_map_delete_prop);
	lua_setfield(L, -2, "deleteProp");

	lua_newtable(L);
	lua_pushvalue(L, -2);
	lua_setfield(L, -2, "__index");
	lua_setglobal(L, "__map_metatable");

	lua_pop(L, 1);
}

static void attach_map_methods(lua_State *L, int index)
{
	lua_getglobal(L, "__map_metatable");
	lua_setmetatable(L, index < 0 ? index - 1 : index);
}

static int lua_map_constructor(lua_State *L)
{
	if (!lua_gettop(L))
	{
		lua_createtable(L, 0, 0);
		attach_map_methods(L, -1);
		return 1;
	}

	luaL_checktype(L, 1, LUA_TTABLE);
	size_t len = LUA_LEN(L, 1);
	lua_createtable(L, 0, len);
	int new_table = lua_gettop(L);

	lua_pushnil(L); // first key
	while (lua_next(L, 1) != 0)
	{
		// Stack: [original_table] [new_table] [key] [value]
		lua_pushvalue(L, -2); // copy key
		lua_pushvalue(L, -2); // copy value
		// Stack: [original_table] [new_table] [key] [value] [key_copy] [value_copy]
		lua_settable(L, new_table); // new_table[key_copy] = value_copy
		// Stack: [original_table] [new_table] [key] [value]
		lua_pop(L, 1); // pop value, keep key for next iteration
		// Stack: [original_table] [new_table] [key]
	}

	attach_map_methods(L, -1);
	return 1;
}

static int distance_vector(lua_State *L, const Vector *v1, const Vector *v2)
{

	auto res = v1->DistanceFrom(*v2);

	lua_pushnumber(L, res);
	return 1;
}

static int distance_point(lua_State *L, const Vector2 *p1, const Vector2 *p2)
{

	auto res = distance(*p1, *p2);

	lua_pushnumber(L, res);
	return 1;
}

static int distance(lua_State *L)
{
	void *p1 = nullptr;
	void *p2 = nullptr;

	if (
		(p1 = luaL_testudata(L, 1, "vector")) != nullptr &&
		(p2 = luaL_testudata(L, 2, "vector")) != nullptr)
	{
		return distance_vector(L, *static_cast<Vector **>(p1), *static_cast<Vector **>(p2));
	}
	else if (
		(p1 = luaL_testudata(L, 1, "point")) != nullptr &&
		(p2 = luaL_testudata(L, 2, "point")) != nullptr)
	{
		return distance_point(L, static_cast<Vector2 *>(p1), static_cast<Vector2 *>(p2));
	}
	else
	{
		return luaL_error(L, "invalid parameters");
	}
}

//

static int mix_vector(lua_State *L, const Vector *v1, const Vector *v2, float t)
{
	auto res = v1->LerpTo(*v2, t);

	Vector *res_vec = new Vector();
	*res_vec = res;

	Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector *)));
	*udata = res_vec;

	luaL_getmetatable(L, "vector");
	lua_setmetatable(L, -2);

	return 1;
}

static int mix_point(lua_State *L, const Vector2 *p1, const Vector2 *p2, float t)
{
	auto res = mix(*p1, *p2, t);

	Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));
	*p = res;

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);

	return 1;
}

static int mix(lua_State *L)
{

	void *p1 = nullptr;
	void *p2 = nullptr;

	float t = luaL_checknumber(L, 3);

	if (
		(p1 = luaL_testudata(L, 1, "vector")) != nullptr &&
		(p2 = luaL_testudata(L, 2, "vector")) != nullptr)
	{
		return mix_vector(L, *static_cast<Vector **>(p1), *static_cast<Vector **>(p2), t);
	}
	else if (
		(p1 = luaL_testudata(L, 1, "point")) != nullptr &&
		(p2 = luaL_testudata(L, 2, "point")) != nullptr)
	{
		return mix_point(L, static_cast<Vector2 *>(p1), static_cast<Vector2 *>(p2), t);
	}
	else
	{
		return luaL_error(L, "invalid parameters");
	}
}

//

static int make_vector(lua_State *L)
{
	Vector **v = nullptr;

	Vector2 *p1 = nullptr;
	Vector2 *p2 = nullptr;

	Vector *p = new Vector();

	if ((v = static_cast<Vector **>(luaL_testudata(L, 1, "vector"))) != nullptr)
	{
		memcpy(p->_data, (*v)->_data, sizeof(float) * 4);
	}
	else if (
		(p1 = static_cast<Vector2 *>(luaL_testudata(L, 1, "point"))) != nullptr &&
		(p2 = static_cast<Vector2 *>(luaL_testudata(L, 2, "point"))) != nullptr)
	{

		p->_data[0] = p1->x;
		p->_data[1] = p1->y;
		p->_data[2] = p2->x;
		p->_data[3] = p2->y;
	}
	else
	{
		p->_data[0] = lua_tonumber(L, 1);
		p->_data[1] = lua_tonumber(L, 2);
		p->_data[2] = lua_tonumber(L, 3);
		p->_data[3] = lua_tonumber(L, 4);
	}

	Vector **udata = static_cast<Vector **>(lua_newuserdata(L, sizeof(Vector *)));
	*udata = p;

	luaL_getmetatable(L, "vector");
	lua_setmetatable(L, -2);

	return 1;
}
static int make_point(lua_State *L)
{
	Vector2 *arg = nullptr;

	Vector2 *p = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

	if ((arg = static_cast<Vector2 *>(luaL_testudata(L, 1, "point"))) != nullptr)
	{
		p->x = arg->x;
		p->y = arg->y;
	}
	else
	{
		p->x = lua_tonumber(L, 1);
		p->y = lua_tonumber(L, 2);
	}

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);

	return 1;
}
static int make_rect(lua_State *L)
{
	Vector **v = nullptr;
	Rect *r = nullptr;

	Vector2 *p1 = nullptr;
	Vector2 *p2 = nullptr;

	Color *c = nullptr;

	Rect p;

	if ((r = static_cast<Rect *>(luaL_testudata(L, 1, "rect"))) != nullptr)
	{
		memcpy(p._data, r->_data, sizeof(float) * 4);
	}
	else if ((v = static_cast<Vector **>(luaL_testudata(L, 1, "vector"))) != nullptr)
	{
		memcpy(p._data, (*v)->_data, sizeof(float) * 4);
	}
	else if (
		(p1 = static_cast<Vector2 *>(luaL_testudata(L, 1, "point"))) != nullptr &&
		(p2 = static_cast<Vector2 *>(luaL_testudata(L, 2, "point"))) != nullptr)
	{
		p._data[0] = p1->x;
		p._data[1] = p1->y;
		p._data[2] = p2->x;
		p._data[3] = p2->y;
	}
	else if ((c = static_cast<Color *>(luaL_testudata(L, 1, "color"))) != nullptr)
	{
		p._data[0] = c->r;
		p._data[1] = c->g;
		p._data[2] = c->b;
		p._data[3] = c->a;
	}
	else
	{
		p._data[0] = lua_tonumber(L, 1);
		p._data[1] = lua_tonumber(L, 2);
		p._data[2] = lua_tonumber(L, 3);
		p._data[3] = lua_tonumber(L, 4);
	}

	Rect *udata = static_cast<Rect *>(lua_newuserdata(L, sizeof(Rect)));
	*new (udata) Rect(p);

	luaL_getmetatable(L, "rect");
	lua_setmetatable(L, -2);

	return 1;
}
static int make_color(lua_State *L)
{
	int argcount = lua_gettop(L);

	if (argcount == 0)
	{
		Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
		*p = Color();
	}
	else if (argcount == 1)
	{
		Color *arg = nullptr;

		if ((arg = static_cast<Color *>(luaL_testudata(L, 1, "color"))))
		{
			Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
			*p = Color(*arg);
		}
		else
		{
			uint32_t packed = static_cast<uint32_t>(luaL_checkinteger(L, 1));
			Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));

			p->r = static_cast<uint8_t>(packed & 0xFF);
			p->g = static_cast<uint8_t>((packed >> 8) & 0xFF);
			p->b = static_cast<uint8_t>((packed >> 16) & 0xFF);
			p->a = static_cast<uint8_t>((packed >> 24) & 0xFF);
		}
	}
	else if (argcount == 3)
	{
		Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));

		p->r = lua_tonumber(L, 1);
		p->g = lua_tonumber(L, 2);
		p->b = lua_tonumber(L, 3);
		p->a = 255;
	}
	else
	{
		Color *p = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));
		*p = Color();

		if (lua_isnumber(L, 1))
			p->r = lua_tonumber(L, 1);
		if (lua_isnumber(L, 2))
			p->g = lua_tonumber(L, 2);
		if (lua_isnumber(L, 3))
			p->b = lua_tonumber(L, 3);
		if (lua_isnumber(L, 4))
			p->a = lua_tonumber(L, 4);
	}

	luaL_getmetatable(L, "color");
	lua_setmetatable(L, -2);

	return 1;
}

static void define_constant_colors(lua_State *L)
{
	lua_getglobal(L, "_G");

	lua_newtable(L);

	lua_pushstring(L, "__newindex");
	lua_pushcfunction(L, [](lua_State *L)
					  {
		const char *key = lua_tostring(L, 2);
		if (
				!std::strcmp(key, "WHITE") || !std::strcmp(key, "BLACK") ||
				!std::strcmp(key, "RED") || !std::strcmp(key, "GREEN") ||
				!std::strcmp(key, "BLUE") || !std::strcmp(key, "PURPLE")
		) {
			return luaL_error(L, "attempt to modify color constant");
		}
		lua_rawset(L, 1);
		return 0; });
	lua_settable(L, -3);

	lua_setmetatable(L, -2);
	lua_pop(L, 1);

	// define constant colors here
}

static int rotate_point(lua_State *L, const Vector2 *p, float degrees, const Vector2 *center)
{
	Vector2 c = (center == nullptr) ? Vector2{0, 0} : *center;

	Vector2 *res = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

	*res = rotate_vector(*p, degrees, *center);

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);

	return 1;
}

static int rotate_quad(lua_State *L, const Quad *q, float degrees, const Vector2 *center)
{
	Quad *nq = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));

	new (nq) Quad(q->rotate(degrees, (center == nullptr) ? q->center() : *center));

	luaL_getmetatable(L, "quad");
	lua_setmetatable(L, -2);

	return 1;
}

static int rotate_rect(lua_State *L, const Rect *r, float degrees, const Vector2 *center)
{
	Quad q = Quad(
		Vector2{r->_left, r->_top},
		Vector2{r->_right, r->_top},
		Vector2{r->_right, r->_bottom},
		Vector2{r->_left, r->_bottom});

	Quad *nq = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));

	new (nq) Quad(q.rotate(degrees, (center == nullptr) ? q.center() : *center));

	luaL_getmetatable(L, "quad");
	lua_setmetatable(L, -2);

	return 1;
}

static int rotate(lua_State *L)
{
	void *p1 = nullptr;

	float degrees = luaL_checknumber(L, 2);
	Vector2 *center = static_cast<Vector2 *>(luaL_testudata(L, 3, "point"));

	if (
		(p1 = luaL_testudata(L, 1, "point")) != nullptr)
	{
		return rotate_point(L, static_cast<Vector2 *>(p1), degrees, center);
	}
	else if (
		(p1 = luaL_testudata(L, 1, "quad")) != nullptr)
	{
		return rotate_quad(L, static_cast<Quad *>(p1), degrees, center);
	}
	else if (
		(p1 = luaL_testudata(L, 1, "rect")) != nullptr)
	{
		return rotate_rect(L, static_cast<Rect *>(p1), degrees, center);
	}
	else
	{
		return luaL_error(L, "invalid parameters");
	}
}

static int make_quad(lua_State *L)
{
	int count = lua_gettop(L);

	switch (count)
	{

	case 1:
	{
		void *p = nullptr;

		if ((p = luaL_testudata(L, 1, "quad")) != nullptr)
		{
			Quad *q = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));

			std::memcpy(q->data, p, sizeof(Vector2) * 4);

			luaL_getmetatable(L, "quad");
			lua_setmetatable(L, -2);
		}
		else if ((p = luaL_testudata(L, 1, "rect")) != nullptr)
		{
			Rect *r = static_cast<Rect *>(p);

			Quad *q = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));

			q->topleft = Vector2{r->_left, r->_top};
			q->topright = Vector2{r->_right, r->_top};
			q->bottomright = Vector2{r->_right, r->_bottom};
			q->bottomleft = Vector2{r->_left, r->_bottom};

			luaL_getmetatable(L, "quad");
			lua_setmetatable(L, -2);
		}
		else if (lua_istable(L, 1))
		{
			lua_rawgeti(L, 1, 1);
			lua_rawgeti(L, 1, 2);
			lua_rawgeti(L, 1, 3);
			lua_rawgeti(L, 1, 4);

			Vector2 *tl = static_cast<Vector2 *>(luaL_checkudata(L, 2, "point"));
			Vector2 *tr = static_cast<Vector2 *>(luaL_checkudata(L, 3, "point"));
			Vector2 *br = static_cast<Vector2 *>(luaL_checkudata(L, 4, "point"));
			Vector2 *bl = static_cast<Vector2 *>(luaL_checkudata(L, 5, "point"));

			Quad *q = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));

			new (q) Quad(*tl, *tr, *br, *bl);

			luaL_getmetatable(L, "quad");
			lua_setmetatable(L, -2);

			lua_remove(L, 2);
			lua_remove(L, 2);
			lua_remove(L, 2);
			lua_remove(L, 2);
		}
	}
	break;

	case 4:
	{
		Vector2 *tl = static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
		Vector2 *tr = static_cast<Vector2 *>(luaL_checkudata(L, 2, "point"));
		Vector2 *br = static_cast<Vector2 *>(luaL_checkudata(L, 3, "point"));
		Vector2 *bl = static_cast<Vector2 *>(luaL_checkudata(L, 4, "point"));

		Quad *q = static_cast<Quad *>(lua_newuserdata(L, sizeof(Quad)));

		new (q) Quad(*tl, *tr, *br, *bl);

		luaL_getmetatable(L, "quad");
		lua_setmetatable(L, -2);
	}
	break;

	default:
		return luaL_error(L, "invalid number of arguments to quad");
	}
	return 1;
}

// int point_inside(lua_State *L) {
// 	Vector2 *p = static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
// 	Rect *e = *static_cast<Rect **>(luaL_checkudata(L, 2, "rectangle"));

// 	lua_pushboolean(L, CheckCollisionPointRec(*p, Rectangle{e->_left, e->_top, e->width(), e->height()}));
// 	return 1;
// }

static int enclose(lua_State *L)
{
	int count = lua_gettop(L);

	if (count <= 0)
		return luaL_error(L, "insuffient arguments to function enclose");

	Rect rect = Rect(0, 0, 0, 0);

	for (int c = 1; c <= count; c++)
	{
		void *arg1 = nullptr;

		if ((arg1 = luaL_testudata(L, c, "rect")) != nullptr)
		{
			Rect *r = static_cast<Rect *>(arg1);

			if (c == 0)
			{
				std::memcpy(rect._data, r->_data, sizeof(float) * 4);
				continue;
			}

			if (r->_left < rect._left)
				rect._left = r->_left;
			if (r->_left > rect._right)
				rect._right = r->_left;

			if (r->_top < rect._top)
				rect._top = r->_top;
			if (r->_top > rect._bottom)
				rect._bottom = r->_top;

			if (r->_right > rect._right)
				rect._right = r->_right;
			if (r->_right < rect._left)
				rect._left = r->_right;

			if (r->_bottom > rect._bottom)
				rect._bottom = r->_bottom;
			if (r->_bottom < rect._top)
				rect._top = r->_bottom;
		}
		else if ((arg1 = luaL_testudata(L, c, "quad")) != nullptr)
		{
			Quad *quad = static_cast<Quad *>(arg1);

			float minx = std::min(std::min(quad->topleft.x, quad->topright.x), std::min(quad->bottomleft.x, quad->bottomright.x));
			float miny = std::min(std::min(quad->topleft.y, quad->topright.y), std::min(quad->bottomleft.y, quad->bottomright.y));

			float maxx = std::max(std::max(quad->topleft.x, quad->topright.x), std::max(quad->bottomleft.x, quad->bottomright.x));
			float maxy = std::max(std::max(quad->topleft.y, quad->topright.y), std::max(quad->bottomleft.y, quad->bottomright.y));

			if (minx < rect._left)
				rect._left = minx;
			if (miny < rect._top)
				rect._top = miny;
			if (maxx > rect._right)
				rect._right = maxx;
			if (maxy > rect._bottom)
				rect._bottom = maxy;
		}
		else if ((arg1 = luaL_testudata(L, c, "point")) != nullptr)
		{
			Vector2 *p = static_cast<Vector2 *>(arg1);

			if (p->x < rect._left)
				rect._left = p->x;
			if (p->x > rect._right)
				rect._right = p->x;
			if (p->y < rect._top)
				rect._top = p->y;
			if (p->y > rect._bottom)
				rect._bottom = p->y;
		}
		else
		{
			return luaL_error(L, "invalid enclose argument %d", c);
		}
	}

	Rect *res = static_cast<Rect *>(lua_newuserdata(L, sizeof(Rect)));
	new (res) Rect(rect);

	luaL_getmetatable(L, "rect");
	lua_setmetatable(L, -2);

	return 1;
}

static int center(lua_State *L)
{
	void *arg = nullptr;

	Vector2 *res = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

	if ((arg = luaL_testudata(L, 1, "point")) != nullptr)
	{
		Vector2 *p = static_cast<Vector2 *>(arg);

		*res = *p;
	}
	else if ((arg = luaL_testudata(L, 1, "rect")))
	{
		Rect *r = static_cast<Rect *>(arg);

		*res = Vector2{(r->_left + r->_right) / 2.0f, (r->_top + r->_bottom) / 2.0f};
	}
	else if ((arg = luaL_testudata(L, 1, "vector")))
	{
		Vector *v = *static_cast<Vector **>(arg);

		*res = Vector2{(v->_x + v->_y) / 2.0f, (v->_z + v->_w) / 2.0f};
	}
	else if ((arg = luaL_testudata(L, 1, "quad")))
	{
		Quad *q = static_cast<Quad *>(arg);

		*res = q->center();
	}
	else
	{
		return luaL_error(L, "invalid argument for function center");
	}

	luaL_getmetatable(L, "point");
	lua_setmetatable(L, -2);

	return 1;
}

// static int make_image(lua_State *L)
// {
// 	int count = lua_gettop(L);

// 	switch (count)
// 	{
// 	case 1:
// 	{
// 		if (lua_isstring(L, 1))
// 		{
// 			const char *path = luaL_checkstring(L, 1);

// 			auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));

// 			auto full = runtime->paths->data() / std::string(path);

// 			Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
// 			*img = LoadImage(full.string().c_str());
// 		}
// 		else
// 		{
// 			Image *img = static_cast<Image *>(luaL_checkudata(L, 1, "image"));

// 			Image *copy = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));

// 			*copy = ImageCopy(*img);
// 		}
// 	}
// 	break;

// 	case 2:
// 	{
// 		int width = luaL_checkinteger(L, 1);
// 		int height = luaL_checkinteger(L, 2);

// 		Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
// 		*img = GenImageColor(width, height, WHITE);
// 	}
// 	break;

// 	case 3:
// 	{
// 		int width = luaL_checkinteger(L, 1);
// 		int height = luaL_checkinteger(L, 2);
// 		Color *color = static_cast<Color *>(luaL_checkudata(L, 3, "color"));

// 		Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
// 		*img = GenImageColor(width, height, *color);
// 		;
// 	}
// 	break;
// 	}

// 	luaL_getmetatable(L, "image");
// 	lua_setmetatable(L, -2);

// 	return 1;
// };

static int make_texture(lua_State *L)
{
	int count = lua_gettop(L);

	switch (count)
	{
	case 1:
	{
		if (lua_isstring(L, 1))
		{
			const char *path = lua_tolstring(L, 1, nullptr);

			auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));

			auto full = (runtime->paths->data() / std::string(path)).string();

			auto t = LoadTexture(full.c_str());

			RenderTexture2D *copy = static_cast<RenderTexture2D *>(lua_newuserdata(L, sizeof(RenderTexture2D)));
			*copy = LoadRenderTexture(t.width, t.height);
			BeginTextureMode(*copy);
			DrawTexturePro(
				t,
				{0, 0, static_cast<float>(t.width), -static_cast<float>(t.height)},
				{0, 0, static_cast<float>(t.width), static_cast<float>(t.height)},
				{0, 0},
				0,
				WHITE);
			EndTextureMode();

			UnloadTexture(t);
		}
		else if (void *ptr = luaL_testudata(L, 1, "imagebuf"); ptr != nullptr) {
			Image *img = static_cast<Image *>(ptr);

			RenderTexture2D *copy = static_cast<RenderTexture2D *>(lua_newuserdata(L, sizeof(RenderTexture2D)));
			*copy = LoadRenderTexture(img->width, img->height);

			auto t = LoadTextureFromImage(*img);

			BeginTextureMode(*copy);
			ClearBackground(WHITE);
			DrawTextureRec(t, { 0, 0, (float)t.width, (float)-t.height }, { 0, (float)copy->texture.height - t.height }, WHITE);
			EndTextureMode();

			UnloadTexture(t);
		}
		else
		{
			RenderTexture2D *img = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));

			RenderTexture2D *copy = static_cast<RenderTexture2D *>(lua_newuserdata(L, sizeof(RenderTexture2D)));

			*copy = LoadRenderTexture(img->texture.width, img->texture.height);
			BeginTextureMode(*copy);
			ClearBackground(WHITE);
			DrawTexturePro(
				img->texture,
				{0, 0, static_cast<float>(img->texture.width), -static_cast<float>(img->texture.height)},
				{0, 0, static_cast<float>(img->texture.width), static_cast<float>(img->texture.height)},
				{0, 0},
				0,
				WHITE);
			EndTextureMode();
		}
	}
	break;

	case 2:
	{
		int width = luaL_checkinteger(L, 1);
		int height = luaL_checkinteger(L, 2);

		RenderTexture2D *img = static_cast<RenderTexture2D *>(lua_newuserdata(L, sizeof(RenderTexture2D)));
		*img = LoadRenderTexture(width, height);

		BeginTextureMode(*img);
		ClearBackground(WHITE);
		EndTextureMode();
	}
	break;

	case 3:
	{
		int width = luaL_checkinteger(L, 1);
		int height = luaL_checkinteger(L, 2);
		Color *color = static_cast<Color *>(luaL_checkudata(L, 3, "color"));

		RenderTexture2D *img = static_cast<RenderTexture2D *>(lua_newuserdata(L, sizeof(RenderTexture2D)));
		*img = LoadRenderTexture(width, height);

		BeginTextureMode(*img);
		ClearBackground(*color);
		EndTextureMode();
	}
	break;
	}

	luaL_getmetatable(L, "image");
	lua_setmetatable(L, -2);

	return 1;
};

static int make_image(lua_State *L)
{
	int count = lua_gettop(L);

	switch (count)
	{
	case 1:
	{
		if (lua_isstring(L, 1))
		{
			const char *path = lua_tolstring(L, 1, nullptr);

			auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));

			auto full = (runtime->paths->data() / std::string(path)).string();

			Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
			*img = LoadImage(full.c_str());
		}
		else if (luaL_testudata(L, 1, "image")) {
			RenderTexture2D *img = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));
			
			Image *copy = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
			*copy = LoadImageFromTexture(img->texture);
		}
		else
		{
			Image *img = static_cast<Image *>(luaL_checkudata(L, 1, "imagebuf"));

			Image *copy = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
			*copy = ImageCopy(*img);
		}
	}
	break;

	case 2:
	{
		int width = luaL_checkinteger(L, 1);
		int height = luaL_checkinteger(L, 2);

		Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
		*img = GenImageColor(width, height, WHITE);
	}
	break;

	case 3:
	{
		int width = luaL_checkinteger(L, 1);
		int height = luaL_checkinteger(L, 2);
		Color *color = static_cast<Color *>(luaL_checkudata(L, 3, "color"));

		Image *img = static_cast<Image *>(lua_newuserdata(L, sizeof(Image)));
		*img = GenImageColor(width, height, *color);
	}
	break;
	}

	luaL_getmetatable(L, "imagebuf");
	lua_setmetatable(L, -2);

	return 1;
};

static int random_seed(lua_State *L)
{
	auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));
	int seed = lua_tointeger(L, 1);

	runtime->random = Orbit::Lua::RandomGenerator(seed);

	return 0;
}

static int random_gen(lua_State *L)
{
	int max = lua_tointeger(L, 1);

	if (lua_isnil(L, 1))
		max = 10000;
	if (max == 0)
		max = 1;

	auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));
	lua_pushinteger(L, runtime->random.next(max));
	return 1;
}

static int draw(lua_State *L)
{
	void *ptr = nullptr;
	const char *text = nullptr;
	RenderTexture2D *img = nullptr;

	auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));

	if ((text = lua_tostring(L, 1)) != nullptr)
	{
		int x = lua_tonumber(L, 2);
		int y = lua_tonumber(L, 3);
		Color *c = static_cast<Color *>(luaL_testudata(L, 4, "color"));
		int size = lua_tonumber(L, 5);

		BeginTextureMode(runtime->viewport);
		DrawText(text, x, y, size ? 20 : size, c ? *c : BLACK);
		EndTextureMode();

		runtime->SetRedraw();
	}
	else if (luaL_testudata(L, 1, "image") != nullptr )
	{
		img = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));

		if (lua_isnumber(L, 2) && lua_isnumber(L, 3))
		{
			// draw(image, x, y, {opt})

			float x = luaL_checknumber(L, 2);
			float y = luaL_checknumber(L, 3);

			// Orbit::RlExt::CopyImageParams params;
			// if (lua_istable(L, 4)) params = parse_params(L, 4);

			BeginTextureMode(runtime->viewport);
			DrawTexturePro(
				img->texture,
				{0, 0, static_cast<float>(img->texture.width), -static_cast<float>(static_cast<float>(img->texture.height))},
				{x, runtime->viewport.texture.height - img->texture.height - y, static_cast<float>(img->texture.width), static_cast<float>(static_cast<float>(img->texture.height))},
				{0, 0},
				0,
				WHITE);
			EndTextureMode();
		}
		else if (luaL_testudata(L, 2, "point"))
		{
			// draw(image, x, y, {opt})

			Vector2 x = *static_cast<Vector2 *>(luaL_checkudata(L, 2, "point"));

			// Orbit::RlExt::CopyImageParams params;
			// if (lua_istable(L, 3)) params = parse_params(L, 3);

			BeginTextureMode(runtime->viewport);
			DrawTextureV(img->texture, x, WHITE);
			EndTextureMode();
		}
		else if (luaL_testudata(L, 2, "rect"))
		{
			Rect *src = static_cast<Rect *>(luaL_checkudata(L, 2, "rect"));

			if (luaL_testudata(L, 3, "rect"))
			{
				// draw(image, src, dest, {opt})

				Rect *dst = static_cast<Rect *>(luaL_checkudata(L, 3, "rect"));

				Orbit::RlExt::CopyImageParams params;
				if (lua_istable(L, 4))
					params = parse_params(L, 4);
			}
			else if (luaL_testudata(L, 3, "quad"))
			{
				// draw(image, src, quad, {opt})

				Quad *dst = *static_cast<Quad **>(luaL_checkudata(L, 3, "quad"));

				Orbit::RlExt::CopyImageParams params;
				if (lua_istable(L, 4))
					params = parse_params(L, 4);
			}
			else
			{
				// draw(image, dest, {opt})

				Orbit::RlExt::CopyImageParams params;
				if (lua_istable(L, 3))
					params = parse_params(L, 3);

				BeginTextureMode(runtime->viewport);
				DrawTexturePro(
					img->texture,
					{0, 0, static_cast<float>(img->texture.width), -static_cast<float>(img->texture.height)},
					{src->_left, src->_top, src->GetWidth(), src->GetHeight()},
					{0, 0},
					0,
					WHITE);
				EndTextureMode();
			}
		}
		else if (luaL_testudata(L, 2, "quad"))
		{
			Quad *dst = static_cast<Quad *>(luaL_checkudata(L, 2, "quad"));

			Orbit::RlExt::CopyImageParams params;
			if (lua_istable(L, 3))
				params = parse_params(L, 3);

			auto &s = runtime->shaders->invb;
			auto srcRect = Rectangle{0, 0, (float)img->texture.width, (float)img->texture.height};

			BeginTextureMode(runtime->viewport);
			BeginShaderMode(s.shader);
			s.prepare(img->texture, srcRect, dst->vertices);
			Orbit::RlExt::DrawTexture(&img->texture, &srcRect, dst->vertices, WHITE);
			EndShaderMode();
			EndTextureMode();
		}
		else
		{
			Orbit::RlExt::CopyImageParams params;
			if (lua_istable(L, 2))
				params = parse_params(L, 2);

			BeginTextureMode(runtime->viewport);
			DrawTexture(img->texture, 0, 0, WHITE);
			EndTextureMode();
		}
	}
	else if (luaL_testudata(L, 1, "imagebuf") != nullptr )
	{
		auto *imgbuf = static_cast<Image *>(luaL_checkudata(L, 1, "imagebuf"));
		auto texture = LoadTextureFromImage(*imgbuf);

		if (lua_isnumber(L, 2) && lua_isnumber(L, 3))
		{
			// draw(image, x, y, {opt})

			float x = luaL_checknumber(L, 2);
			float y = luaL_checknumber(L, 3);

			// Orbit::RlExt::CopyImageParams params;
			// if (lua_istable(L, 4)) params = parse_params(L, 4);

			BeginTextureMode(runtime->viewport);
			DrawTexturePro(
				texture,
				{0, 0, static_cast<float>(texture.width), -static_cast<float>(static_cast<float>(texture.height))},
				{x, runtime->viewport.texture.height - texture.height - y, static_cast<float>(texture.width), static_cast<float>(static_cast<float>(texture.height))},
				{0, 0},
				0,
				WHITE);
			EndTextureMode();
		}
		else if (luaL_testudata(L, 2, "point"))
		{
			// draw(image, x, y, {opt})

			Vector2 x = *static_cast<Vector2 *>(luaL_checkudata(L, 2, "point"));

			// Orbit::RlExt::CopyImageParams params;
			// if (lua_istable(L, 3)) params = parse_params(L, 3);

			BeginTextureMode(runtime->viewport);
			DrawTextureV(texture, x, WHITE);
			EndTextureMode();
		}
		else if (luaL_testudata(L, 2, "rect"))
		{
			Rect *src = static_cast<Rect *>(luaL_checkudata(L, 2, "rect"));

			if (luaL_testudata(L, 3, "rect"))
			{
				// draw(image, src, dest, {opt})

				Rect *dst = static_cast<Rect *>(luaL_checkudata(L, 3, "rect"));

				Orbit::RlExt::CopyImageParams params;
				if (lua_istable(L, 4))
					params = parse_params(L, 4);
			}
			else if (luaL_testudata(L, 3, "quad"))
			{
				// draw(image, src, quad, {opt})

				Quad *dst = *static_cast<Quad **>(luaL_checkudata(L, 3, "quad"));

				Orbit::RlExt::CopyImageParams params;
				if (lua_istable(L, 4))
					params = parse_params(L, 4);
			}
			else
			{
				// draw(image, dest, {opt})

				Orbit::RlExt::CopyImageParams params;
				if (lua_istable(L, 3))
					params = parse_params(L, 3);

				BeginTextureMode(runtime->viewport);
				DrawTexturePro(
					texture,
					{0, 0, static_cast<float>(texture.width), -static_cast<float>(texture.height)},
					{src->_left, src->_top, src->GetWidth(), src->GetHeight()},
					{0, 0},
					0,
					WHITE);
				EndTextureMode();
			}
		}
		else if (luaL_testudata(L, 2, "quad"))
		{
			Quad *dst = static_cast<Quad *>(luaL_checkudata(L, 2, "quad"));

			Orbit::RlExt::CopyImageParams params;
			if (lua_istable(L, 3))
				params = parse_params(L, 3);

			auto &s = runtime->shaders->invb;
			auto srcRect = Rectangle{0, 0, (float)texture.width, (float)texture.height};

			BeginTextureMode(runtime->viewport);
			BeginShaderMode(s.shader);
			s.prepare(texture, srcRect, dst->vertices);
			Orbit::RlExt::DrawTexture(&texture, &srcRect, dst->vertices, WHITE);
			EndShaderMode();
			EndTextureMode();
		}
		else
		{
			Orbit::RlExt::CopyImageParams params;
			if (lua_istable(L, 2))
				params = parse_params(L, 2);

			BeginTextureMode(runtime->viewport);
			DrawTexture(texture, 0, 0, WHITE);
			EndTextureMode();
		}

		UnloadTexture(texture);
	}
	else if (luaL_testudata(L, 1, "point") && luaL_testudata(L, 2, "point"))
	{
		Vector2 *v1 = static_cast<Vector2 *>(luaL_checkudata(L, 1, "point"));
		Vector2 *v2 = static_cast<Vector2 *>(luaL_checkudata(L, 2, "point"));
		Color *c = static_cast<Color *>(luaL_testudata(L, 3, "color"));
		float thickness = lua_tonumber(L, 4);

		BeginTextureMode(runtime->viewport);
		DrawLineEx({v1->x, runtime->viewport.texture.height - v1->y}, {v2->x, runtime->viewport.texture.height - v2->y}, thickness ? thickness : 1, c ? *c : BLACK);
		EndTextureMode();
	}

	return 0;
}

static int clear(lua_State *L)
{
	int count = lua_gettop(L);

	switch (count)
	{
	case 0:
	{
		Color *c = nullptr;

		auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));

		BeginTextureMode(runtime->viewport);

		if ((c = static_cast<Color *>(luaL_testudata(L, 1, "point"))) != nullptr)
		{
			ClearBackground(*c);
		}
		else
		{
			ClearBackground(WHITE);
		}

		EndTextureMode();
	}
	break;

	case 1:
	{
		if (luaL_testudata(L, 1, "color"))
		{
			Color *c = static_cast<Color *>(luaL_checkudata(L, 1, "color"));

			auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));

			BeginTextureMode(runtime->viewport);
			ClearBackground(*c);
			EndTextureMode();
		}
		else if (luaL_testudata(L, 1, "image"))
		{
			RenderTexture2D *i = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));
			BeginTextureMode(*i);
			ClearBackground(WHITE);
			EndTextureMode();
		}
		else if (luaL_testudata(L, 1, "imagebuf")) {
			Image *i = static_cast<Image *>(luaL_checkudata(L, 1, "imagebuf"));
			ImageClearBackground(i, WHITE);
		}
	}
	break;

	case 2:
	{
		if (luaL_testudata(L, 1, "imagebuf")) {
			Image *i = static_cast<Image *>(luaL_checkudata(L, 1, "imagebuf"));
			Color *c = static_cast<Color *>(luaL_checkudata(L, 2, "color"));
			ImageClearBackground(i, *c);
		} else {
			RenderTexture2D *i = static_cast<RenderTexture2D *>(luaL_checkudata(L, 1, "image"));
			Color *c = static_cast<Color *>(luaL_checkudata(L, 2, "color"));
	
			BeginTextureMode(*i);
			ClearBackground(*c);
			EndTextureMode();
		}
	}
	break;
	}

	return 0;
}

static int log(lua_State *L)
{
	const char *text = luaL_checkstring(L, 1);

	auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));

	runtime->logger->info(std::string("[script]: ") + text);

	return 0;
}

static void parse_lingo_expr_tree(lua_State *L, mp::Node *nodes)
{
	if (nodes == nullptr)
	{
		lua_pushnil(L);
		return;
	}

	auto *v = dynamic_cast<mp::Void *>(nodes);
	if (v)
	{
		lua_pushnil(L);
		return;
	}

	auto *integer = dynamic_cast<mp::Int *>(nodes);
	if (integer)
	{
		lua_pushinteger(L, integer->number);
		return;
	}

	auto *floating = dynamic_cast<mp::Float *>(nodes);
	if (floating)
	{
		lua_pushnumber(L, floating->number);
		return;
	}

	auto *str = dynamic_cast<mp::String *>(nodes);
	if (str)
	{
		lua_pushstring(L, str->str.c_str());
		return;
	}

	auto *sym = dynamic_cast<mp::Symbol *>(nodes);
	if (sym)
	{
		lua_pushstring(L, sym->str.c_str());
		return;
	}

	auto *list = dynamic_cast<mp::List *>(nodes);
	if (list)
	{
		lua_newtable(L);
		for (int i = 0; i < list->elements.size(); i++)
		{
			parse_lingo_expr_tree(L, list->elements[i].get());
			lua_rawseti(L, -2, i + 1);
		}
		return;
	}

	auto *props = dynamic_cast<mp::Props *>(nodes);
	if (props)
	{
		lua_newtable(L);
		for (auto &p : props->map)
		{
			lua_pushstring(L, p.first.c_str());
			parse_lingo_expr_tree(L, p.second.get());
			lua_settable(L, -3);
		}
		return;
	}

	//

	auto *gcall = dynamic_cast<mp::GCall *>(nodes);
	if (gcall)
	{
		auto &name = gcall->name;

		if (name == "point")
		{
			auto *argi1 = dynamic_cast<mp::Int *>(gcall->args[0].get());
			auto *argf1 = dynamic_cast<mp::Float *>(gcall->args[0].get());
			auto *argi2 = dynamic_cast<mp::Int *>(gcall->args[1].get());
			auto *argf2 = dynamic_cast<mp::Float *>(gcall->args[1].get());

			Vector2 *v = static_cast<Vector2 *>(lua_newuserdata(L, sizeof(Vector2)));

			v->x = argi1 ? argi1->number : (argf1 ? argf1->number : 0);
			v->y = argi2 ? argi2->number : (argf2 ? argf2->number : 0);

			luaL_getmetatable(L, "point");
			lua_setmetatable(L, -2);
			return;
		}

		if (name == "rect")
		{
			auto *argi1 = dynamic_cast<mp::Int *>(gcall->args[0].get());
			auto *argf1 = dynamic_cast<mp::Float *>(gcall->args[0].get());

			auto *argi2 = dynamic_cast<mp::Int *>(gcall->args[1].get());
			auto *argf2 = dynamic_cast<mp::Float *>(gcall->args[1].get());

			auto *argi3 = dynamic_cast<mp::Int *>(gcall->args[2].get());
			auto *argf3 = dynamic_cast<mp::Float *>(gcall->args[2].get());

			auto *argi4 = dynamic_cast<mp::Int *>(gcall->args[3].get());
			auto *argf4 = dynamic_cast<mp::Float *>(gcall->args[3].get());

			Rect **r = static_cast<Rect **>(lua_newuserdata(L, sizeof(Rect *)));

			auto *newRect = new Rect(
				argi1 ? argi1->number : (argf1 ? argf1->number : 0),
				argi2 ? argi2->number : (argf2 ? argf2->number : 0),
				argi3 ? argi3->number : (argf3 ? argf3->number : 0),
				argi4 ? argi4->number : (argf4 ? argf4->number : 0));

			*r = newRect;

			luaL_getmetatable(L, "rect");
			lua_setmetatable(L, -2);
			return;
		}

		if (name == "color")
		{
			auto *argi1 = dynamic_cast<mp::Int *>(gcall->args[0].get());
			auto *argi2 = dynamic_cast<mp::Int *>(gcall->args[1].get());
			auto *argi3 = dynamic_cast<mp::Int *>(gcall->args[2].get());

			Color *c = static_cast<Color *>(lua_newuserdata(L, sizeof(Color)));

			c->r = argi1 ? argi1->number : 0;
			c->g = argi2 ? argi2->number : 0;
			c->b = argi3 ? argi3->number : 0;
			c->a = 255;

			luaL_getmetatable(L, "color");
			lua_setmetatable(L, -2);
			return;
		}

		lua_pushnil(L);
		return;
	}
}

static int parse_lingo_expr(lua_State *L)
{
	const char *expr_cstr = luaL_checkstring(L, 1);
	const std::string expr_str(expr_cstr);

	auto nodes = mp::parse(expr_str);

	parse_lingo_expr_tree(L, nodes.get());
	return 1;
}

static int string_split(lua_State *L)
{
	if (lua_isnil(L, 1) || lua_isnil(L, 2))
		return luaL_error(L, "invalid 'split()' arguments");

	const char *text = lua_tostring(L, 1);
	const char *sepr = lua_tostring(L, 2);

	std::stringstream ss;

	lua_newtable(L);

	size_t counter = 1, index = 0, prev_index = 0;

	auto text_length = std::strlen(text);
	auto sepr_length = std::strlen(sepr);

	while (index < text_length)
	{
		if (std::strncmp(sepr, text + index, sepr_length) != 0)
		{
			ss.write(text + index, 1);
			index++;
			continue;
		}

		lua_pushstring(L, ss.str().c_str());
		lua_rawseti(L, -2, counter++);

		index += sepr_length;
		prev_index = index;

		ss.clear();
		ss.str("");
	}

	if (index == text_length)
	{
		lua_pushstring(L, ss.str().c_str());
		lua_rawseti(L, -2, counter);
	}
	else if (counter == 1)
	{
		lua_pushstring(L, text);
		lua_rawseti(L, -2, counter);
	}

	return 1;
}

static int string_number_of_lines(lua_State *L)
{
	const char *text = lua_tostring(L, 1);
	size_t count = 0;
	while (*text)
	{
		if (*text == '\r' || *text == '\n')
		{
			count++;
		}
		text++;
	}

	lua_pushinteger(L, count);

	return 1;
}

static int string_at_line(lua_State *L)
{
	const char *text = luaL_checkstring(L, 1);
	int target_line = luaL_checkinteger(L, 2); // 1-based index

	if (target_line < 1)
	{
		lua_pushnil(L);
		return 1;
	}

	int current_line = 1;
	const char *start = text;

	while (*text)
	{
		if (current_line == target_line)
		{
			// Find end of line
			const char *end = text;
			while (*end && *end != '\n' && *end != '\r')
				end++;

			size_t len = end - start;
			lua_pushlstring(L, start, len);
			return 1;
		}

		if (*text == '\n' || *text == '\r')
		{
			current_line++;
			// Handle CRLF or LFCR by skipping both characters
			if ((text[0] == '\r' && text[1] == '\n') ||
				(text[0] == '\n' && text[1] == '\r'))
			{
				text++; // skip the paired character
			}
			start = text + 1;
		}

		text++;
	}

	lua_pushnil(L);
	return 1;
}

static int string_at_char(lua_State *L)
{
	const char *str = luaL_checkstring(L, 1);
	lua_Integer index = luaL_checkinteger(L, 2);

	size_t len = strlen(str);

	// 1-based index check
	if (index < 1 || (size_t)index > len)
	{
		lua_pushnil(L);
		return 1;
	}

	char c = str[index - 1];
	lua_pushlstring(L, &c, 1);
	return 1;
}

static int lua_to_bool(lua_State *L)
{
	int i = 0;

	if (lua_isnil(L, 1))
	{
		lua_pushboolean(L, false);
		return 1;
	}

	if (lua_isnumber(L, 1))
	{
		i = lua_tonumber(L, 1);
		lua_pushboolean(L, i == 0 ? false : true);
	}
	else if (lua_isboolean(L, 1))
	{
		i = static_cast<int>(lua_toboolean(L, 1));
		lua_pushboolean(L, i ? true : false);
	}
	else
		return luaL_error(L, "expected a number or a boolean value");

	return 1;
}

static int lua_conv_to_integer(lua_State *L)
{
	if (lua_isnil(L, 1))
	{
		lua_pushinteger(L, 0);
		return 1;
	}

	if (lua_isnumber(L, 1))
	{
		float i = lua_tonumber(L, 1);

		lua_pushinteger(L, std::round(i));
		return 1;
	}

	int b = lua_toboolean(L, 1);
	lua_pushinteger(L, b);
	return 1;
}

static void lua_deep_clone_recursive(lua_State *L, int index, int seen_index);
static int lua_deep_clone(lua_State *L)
{
	// Create a `seen` table to track circular references
	lua_newtable(L); // stack: ... seen
	int seen_index = lua_gettop(L);

	// Clone the value at stack index 1
	lua_deep_clone_recursive(L, 1, seen_index); // stack: ... seen clone

	// Remove the seen table
	lua_remove(L, seen_index); // stack: ... clone

	return 1; // return the clone
}
static void lua_deep_clone_recursive(lua_State *L, int index, int seen_index)
{
	index = (index > 0 || index <= LUA_REGISTRYINDEX) ? index : lua_gettop(L) + index + 1;
	seen_index = (seen_index > 0 || seen_index <= LUA_REGISTRYINDEX) ? seen_index : lua_gettop(L) + seen_index + 1;

	if (lua_type(L, index) != LUA_TTABLE)
	{
		lua_pushvalue(L, index); // Copy primitive value
		return;
	}

	// Check if table was already seen
	lua_pushvalue(L, index);   // push original table
	lua_rawget(L, seen_index); // seen[orig]
	if (!lua_isnil(L, -1))
	{
		// Already cloned, return reference
		return;
	}
	lua_pop(L, 1); // remove nil

	// Create a new table
	lua_newtable(L); // clone
	int clone_index = lua_gettop(L);

	// Mark as seen
	lua_pushvalue(L, index);	   // original
	lua_pushvalue(L, clone_index); // clone
	lua_rawset(L, seen_index);	   // seen[orig] = clone

	// Clone all keys and values
	lua_pushnil(L); // for iteration
	while (lua_next(L, index) != 0)
	{
		// stack: key, value
		lua_deep_clone_recursive(L, -2, seen_index); // clone key
		lua_deep_clone_recursive(L, -1, seen_index); // clone value
		lua_rawset(L, clone_index);					 // clone[key] = value
	}

	// Copy metatable if any
	if (lua_getmetatable(L, index))
	{
		lua_setmetatable(L, clone_index);
	}
}

static int io_getNthFileNameInFolder(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	int index = lua_tointeger(L, 2);

	if (index < 1)
	{
		lua_pushstring(L, "");
		return 1;
	}

	const auto *runtime = static_cast<Orbit::Lua::LuaRuntime *>(lua_touserdata(L, lua_upvalueindex(1)));

	auto folder = runtime->paths->data() / path;

	if (std::filesystem::is_directory(folder))
	{

		int i = 0;
		for (const auto &entry : std::filesystem::directory_iterator(folder))
		{
			i++;
			if (i == index)
			{
				const auto name = entry.path().stem().string();

				lua_pushstring(L, name.c_str());
				return 1;
			}
		}
	}

	lua_pushstring(L, "");
	return 1;
}

static int export_image(lua_State *L)
{
	if (lua_istable(L, 1))
	{
		lua_gettable(L, 1);

		lua_getfield(L, -1, "image");
		lua_getfield(L, -2, "filename");

		const char *fnm = luaL_checkstring(L, -1);

		if (auto *img = static_cast<RenderTexture2D *>(luaL_testudata(L, -1, "image")); img != nullptr) {
			auto tmp = LoadImageFromTexture(img->texture);
			ExportImage(tmp, fnm);
			UnloadImage(tmp);
			
		} else if (auto *imgbuf = static_cast<Image *>(luaL_checkudata(L, -1, "imagebuf")); imgbuf != nullptr) {
			ExportImage(*imgbuf, fnm);
		}

		return 1;
	}

	const char *fnm = luaL_checkstring(L, 2);

	if (auto *img = static_cast<RenderTexture2D *>(luaL_testudata(L, 1, "image")); img != nullptr) {
		auto tmp = LoadImageFromTexture(img->texture);
		ExportImage(tmp, fnm);
		UnloadImage(tmp);
		
	} else if (auto *imgbuf = static_cast<Image *>(luaL_checkudata(L, 1, "imagebuf")); imgbuf != nullptr) {
		ExportImage(*imgbuf, fnm);
	}
	return 1;
}

namespace Orbit::Lua
{

	void LuaRuntime::_register_utils()
	{
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
		// lua_register(L, "color", make_color);

		lua_pushcfunction(L, make_quad);
		lua_setglobal(L, "quad");

		register_list_extensions(L);
		lua_pushcfunction(L, lua_list_constructor);
		lua_setglobal(L, "list");

		register_map_extensions(L);
		lua_pushcfunction(L, lua_map_constructor);
		lua_setglobal(L, "map");

		lua_pushlightuserdata(L, this);
		lua_pushcclosure(L, make_texture, 1);
		lua_setglobal(L, "image");

		lua_pushlightuserdata(L, this);
		lua_pushcclosure(L, make_image, 1);
		lua_setglobal(L, "imagebuf");

		lua_pushlightuserdata(L, this);
		lua_pushcclosure(L, random_seed, 1);
		lua_setglobal(L, "seed");

		lua_pushlightuserdata(L, this);
		lua_pushcclosure(L, random_gen, 1);
		lua_setglobal(L, "random");

		lua_pushlightuserdata(L, this);
		lua_pushcclosure(L, draw, 1);
		lua_setglobal(L, "draw");

		lua_pushcfunction(L, log);
		lua_setglobal(L, "log");

		lua_pushlightuserdata(L, this);
		lua_pushcclosure(L, clear, 1);
		lua_setglobal(L, "clear");

		lua_pushcfunction(L, parse_lingo_expr);
		lua_setglobal(L, "fromLingo");

		lua_pushcfunction(L, string_split);
		lua_setglobal(L, "split");

		lua_pushcfunction(L, string_number_of_lines);
		lua_setglobal(L, "numberOfLines");

		lua_pushcfunction(L, string_at_line);
		lua_setglobal(L, "atLine");

		lua_pushcfunction(L, string_at_char);
		lua_setglobal(L, "atChar");

		lua_pushcfunction(L, lua_to_bool);
		lua_setglobal(L, "tobool");

		lua_pushcfunction(L, lua_conv_to_integer);
		lua_setglobal(L, "toint");

		lua_pushcfunction(L, lua_deep_clone);
		lua_setglobal(L, "clone");

		lua_pushcfunction(L, [](lua_State *L)
						  {
		lua_pushinteger(L, lua_tointeger(L, 1) ^ lua_tointeger(L, 2));
		return 1; });
		lua_setglobal(L, "ixor");

		lua_pushcfunction(L, [](lua_State *L)
						  {
		lua_pushboolean(L, lua_toboolean(L, 1) ^ lua_toboolean(L, 2));
		return 1; });
		lua_setglobal(L, "bxor");

		lua_pushlightuserdata(L, this);
		lua_pushcclosure(L, io_getNthFileNameInFolder, 1);
		lua_setglobal(L, "getNthFileNameInFolder");

		lua_pushcfunction(L, export_image);
		lua_setglobal(L, "exportImage");

		lua_pushcfunction(L, list_get_pos);
		lua_setglobal(L, "getPos");
	}

};
