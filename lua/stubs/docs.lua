---Gets the number of lines of a string.
---@param str string
---@return integer 
function numberOfLines(str) end

---Gets line from a string at a given index.
---@param str string
---@param line integer
---@return string
function atLine(str, line) end

---Gets character from a string at a given index.
---@param str string
---@param c integer
---@return string
function atChar(str, c) end

---Converts a boolean value into either 0 or 1.
---@param i boolean|number
---@return integer
function toint(i) end

---Converts a number into a boolean value.
---@param number number|boolean?
---@return boolean
function tobool(number) end

---@class ExtendedList
---@field add function

---Creates a list with extra methods.
---@param l table?
---@return ExtendedList
function list(l) end

---@param table table
---@param a any
---@return number
function getPos(table, a) end

---@param table table
---@param a any
function add(table, a) end

-- ---Gets the index of an item if it's in the list; otherwise returns 0.
-- ---@param l table
-- ---@patam item any
-- ---@return integer
-- function getPos(l, item) end

-- ---Deletes one item from a list, if exits.
-- ---@param l table
-- ---@param item any
-- function deleteOne(l, item) end

-- ---Adds an item to a list at a given index and shifts the rest.
-- ---@param l table
-- ---@param index integer
-- ---@param item any
-- function addAt(l, index, item) end

-- ---Gets the index of an item if it's in the map; otherwise returns 0.
-- ---@param m table
-- ---@patam item any
-- ---@return integer
-- function findPos(m, item) end


---Creates a map with extra methods.
---@param m table?
---@return table
function map(m) end

---Creates a point in 2D space.
---@param x number
---@param y number
---@return point
function point(x, y) end

---Creates a rectangle in 2D space.
---@param left number|point
---@param top number|point
---@param right number?
---@param bottom number?
---@return rect
function rect(left, top, right, bottom) end

---Parses a lingo expression into a Lua object.
---@param str string
---@return any
function fromLingo(str) end

---Retreives a cast library by name or index.
---@param nameOrIndex integer|string
---@return CastLib?
function castLib(nameOrIndex) end

---Retreives a cast member by name or index.
---@param nameOrIndex integer|string
---@return CastMember?
function member(nameOrIndex) end

---@class point
---@field x number
---@field y number
---@field locH number
---@field locV number
---@field inside function
---@operator unm:point
local point = {}

---@class rect
---@field left number
---@field top number
---@field right number
---@field bottom number
---@field width number
---@field height number
---@field pos number
local rect = {}

---Creates an RGBA color object.
---@param r integer
---@param g integer
---@param b integer
---@param a integer?
---@return color
function color(r, g, b, a) end

---Creates a new image.
---@param width integer|Image
---@param height integer?
---@return Image
function image(width, height) end

---Creates a new image.
---@param width integer|ImageBuffer|Image
---@param height integer?
---@return ImageBuffer
function imagebuf(width, height) end

---Creates a quad.
---@param tl point|table
---@param tr point?
---@param br point?
---@param bl point?
---@return Quad
function quad(tl, tr, br, bl) end

---Rotates a quad or a rect in a given degree clockwise.
---@param obj Quad|rect
---@param degree number
---@param center point?
---@return Quad
function rotate(obj, degree, center) end

---Creates a rectanlge that encloses all given rects, quads, and points.
---@param ... Quad|rect|point
---@return rect
function enclose(...)end

---Returns the first occurrence of a substring in a string.
---@param str string
---@param sub string
---@return integer
function offset(str, sub) end

---@param img Image
---@param filename string
function exportImage(img, filename) end

---@param img Image
---@param invert boolean?
---@return Image
function silhouette(img, invert) end

---@param any Image|string
---@param x integer
---@param y integer
function draw(any, x, y) end

---@overload fun(point1: point, point2: point, color: color)
function draw(point1, point2, color) end

---@param color color?
function clear(color) end

---@class color
---@field r integer
---@field g integer
---@field b integer
---@field a integer
local Color = {}

---@class Image
---@field width integer
---@field height integer
---@field rect rect
local Image = {}

---@class ImageBuffer
---@field width integer
---@field height integer
---@field rect rect
local ImageBuffer = {}

---@param destImg Image
---@param sourceImg Image
---@param dest rect|Quad
---@param source rect|table
---@param options table?
function Image.copyPixels(destImg, sourceImg, dest, source, options) end

---@param img Image
---@param x integer|point
---@param y integer?
---@return color
function Image.getPixel(img, x, y) end

---@param img Image
---@param x integer
---@param y integer
---@param c color
function Image.setPixel(img, x, y, c) end

---@class Quad
---@field topleft point
---@field topright point
---@field bottomright point
---@field bottomleft point
---@field [1] point
---@field [2] point
---@field [3] point
---@field [4] point
local Quad = {}

---@type string
local dirSeparator = ""

---@type string
local RETURN = "\n"

---@type integer
local TRUE = 1

---@type integer
local FALSE = 0

---@type nil
local VOID = nil

---@type string
local moviePath = ""

---Creates Xtra plugins
---@param name string
---@return table
function xtra(name) return {} end

---Gets the name of the n'th file in a folder, if found; otherwise returns an empty string. The path is relavant to the data/ folder.
---@param folder string
---@param n integer
---@return string
function getNthFileNameInFolder(folder, n) return '' end

---Exclusive or operator for booleans.
---@param b1 boolean
---@param b2 boolean
---@return boolean
function bxor(b1, b2) end

---Exclusive or operator for integers.
---@param int1 integer
---@param int2 integer
---@return integer
function ixor(int1, int2) end

---Deep clones a table.
---@param table table
---@return table
function clone(table) end

---@param s integer
function seed(s) end

---@param limit integer?
---@return integer
function random(limit) end

---@param a Quad|rect|point
---@return point
function center(a) end

---@class CastMember
---@field name string
---@field number integer
---@field text string?
---@field image Image?
---@field importFileInto function
local CastMember = {}

---@class CastLib
---@field name string
---@field number integer
---@field member table
---@field eraseMembers function
local CastLib = {}

---@class _global
local _global = {}

---@class _movie
---@field castLib table
---@field window table
local _movie = {}

---@class _player
---@field quit function
---@field alert function
local _player = {}

---@class _system
local _system = {}

---@class _key
local _key = {}

---@class _mouse
local _mouse = {}
