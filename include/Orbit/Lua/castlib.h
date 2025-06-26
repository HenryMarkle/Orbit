#pragma once

#include <Orbit/hash.h>

#include <unordered_map>
#include <filesystem>
#include <algorithm>
#include <memory>
#include <vector>
#include <string>
#include <regex>

#include <raylib.h>

namespace Orbit::Lua {

extern const std::regex CAST_MEMBER_NAME_PATTERN;

class CastMember {

	// bool _loaded;
	
public:
	
	int id;
	std::string name;
	std::filesystem::path path;
	// Image image;
	// std::string text;

	// void load();
	// void unload();
	// inline void reload() { unload(); load(); }

	CastMember &operator=(CastMember &&) noexcept;
	CastMember &operator=(const CastMember &) = delete;

	CastMember(CastMember &&) noexcept;
	CastMember(const CastMember &) = delete;
	CastMember(const std::filesystem::path &);
	CastMember(int, const std::string &, const std::filesystem::path &, Image);

	~CastMember();
};

class CastLib {
	
	int _offset;
	std::string _name;
	std::vector<std::shared_ptr<CastMember>> _members;
	std::unordered_map<std::string, std::shared_ptr<CastMember>, CaseInsensitiveHash, CaseInsensitiveEqual> _names;
	
public:

	static const int OFFSET = 65536;

	inline int offset() const { return _offset; }
	inline const std::string &name() const { return _name; }
	inline const auto &members() const { return _members; }
	inline const auto &names() const { return _names; }

	std::shared_ptr<CastMember> find(const std::string &);
	std::shared_ptr<CastMember> find(int);

	std::shared_ptr<CastMember> operator[](const std::string &);
	std::shared_ptr<CastMember> operator[](int);
	
	CastLib &operator=(CastLib &&) noexcept;
	CastLib &operator=(const CastLib &) = delete;

	// Load all members from a given directory.
	void load_members(const std::filesystem::path &);
	CastLib &operator<<(const std::filesystem::path &);

	CastLib(CastLib &&) noexcept;
	CastLib(const CastLib &) = delete;
	CastLib(int, const std::string &);

	~CastLib();
};

};
