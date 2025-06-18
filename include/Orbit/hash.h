#pragma once

#include <algorithm>
#include <string>

namespace Orbit {

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

};