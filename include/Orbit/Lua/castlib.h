#pragma once

#include <unordered_map>
#include <filesystem>
#include <algorithm>
#include <memory>
#include <string>

#include <raylib.h>

namespace Orbit::Lua {

// Custom case-insensitive hash function
struct CaseInsensitiveHash {
    inline size_t operator()(const std::string &s) const {
        std::string lower = s;
        std::transform(lower.begin(), lower.end(), lower.begin(), ::tolower);
        return std::hash<std::string>{}(lower);
    }
};

// Custom case-insensitive equality function
struct CaseInsensitiveEqual {
    inline bool operator()(const std::string &a, const std::string &b) const {
        return std::equal(a.begin(), a.end(), b.begin(), b.end(),
                          [](char c1, char c2) { return std::tolower(c1) == std::tolower(c2); });
    }
};

class CastMember {

	int _id;
	std::string _name;
	std::filesystem::path _path;
	Image _image;
	std::string _text;
	bool _loaded;

public:
	
	inline int id() const { return _id; }
	inline const std::string &name() const { return _name; }
	inline const std::filesystem::path &path() const { return _path; }
	inline Image image() const { return _image; }
	inline std::string &text() { return _text; }
	inline bool loaded() const { return _loaded; }

	void load();
	void unload();
	inline void reload() { unload(); load(); }

	CastMember &operator=(CastMember &&) noexcept;
	CastMember &operator=(const CastMember &) = delete;

	CastMember(CastMember &&) noexcept;
	CastMember(const CastMember &) = delete;
	CastMember(const std::filesystem::path &);
	CastMember(int, const std::string &, const std::filesystem::path &, Image);

	~CastMember();
};

class CastLib {

	int _id;
	std::string _name;
	std::unordered_map<std::string, std::shared_ptr<CastMember>, CaseInsensitiveHash, CaseInsensitiveEqual> _members;

public:

	inline int id() const { return _id; }
	inline const std::string &name() const { return _name; }
	inline auto &members() { return _members; }

	std::shared_ptr<CastMember> operator[](const std::string &);
	CastLib &operator=(CastLib &&) noexcept;
	CastLib &operator=(const CastLib &) = delete;

	// Load all members from a given directory.
	CastLib &operator<<(const std::filesystem::path &);

	CastLib(CastLib &&) noexcept;
	CastLib(const CastLib &) = delete;
	CastLib(int, const std::string &);
	CastLib(int, const std::string &, std::unordered_map<std::string, std::shared_ptr<CastMember>, CaseInsensitiveHash, CaseInsensitiveEqual> &&);

	~CastLib();
};

};
