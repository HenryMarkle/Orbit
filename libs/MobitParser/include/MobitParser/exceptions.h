#include <exception>
#include <string>

#pragma once

namespace mp {
    class double_decimal_point : public std::exception {
    private:
        std::string msg_;

    public:
        const char *what() const noexcept override;
        explicit double_decimal_point(const std::string&);
    };

    class parse_failure : public std::exception {
    private:
        std::string msg_;

    public:
        const char *what() const noexcept override;
        explicit parse_failure(const std::string&);
    };
};
