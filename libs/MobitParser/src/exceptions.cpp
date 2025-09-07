#include <string>

#include <MobitParser/exceptions.h>

namespace mp {
double_decimal_point::double_decimal_point(const std::string &msg)
    : msg_(msg) {}
const char *double_decimal_point::what() const noexcept { return msg_.c_str(); }

parse_failure::parse_failure(const std::string &msg) : msg_(msg) {}
const char *parse_failure::what() const noexcept { return msg_.c_str(); }
}; // namespace mp
