#pragma once

#include <unordered_map>
#include <filesystem>
#include <memory>
#include <string>

#include <raylib.h>

namespace Orbit::Lua {

class CastMember {

	int _id;
	std::string _name;
	std::filesystem::path _path;
	Image _image;
	bool _loaded;

public:
	
	inline int id() const { return _id; }
	inline const std::string &name() const { return _name; }
	inline const std::filesystem::path &path() const { return _path; }
	inline Image image() { return _image; }
	inline bool loaded() const { return _loaded; }

	void load();
	void unload();
	void reload();

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
	std::unordered_map<std::string, std::shared_ptr<CastMember>> _members;

public:

	inline int id() const { return _id; }
	inline const std::string &name() const { return _name; }
	inline std::unordered_map<std::string, std::shared_ptr<CastMember>> &members() { return _members; }

	std::shared_ptr<CastMember> operator[](const std::string &);
	CastLib &operator=(CastLib &&) noexcept;
	CastLib &operator=(const CastLib &) = delete;

	CastLib(CastLib &&) noexcept;
	CastLib(const CastLib &) = delete;
	CastLib(int, const std::string &);
	CastLib(int, const std::string &, std::unordered_map<std::string, std::shared_ptr<CastMember>> &&);

	~CastLib();
};

};
