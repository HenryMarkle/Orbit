#pragma once

#include <cstdint>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

namespace mp {
enum class token_type : uint8_t {
  open_bracket,  // [
  close_bracket, // ]

  open_paren,  // (
  close_paren, // )

  comma, // ,
  colon, // :

  symbol,     // #symbol
  identifier, // variableName
  string,     // "Hello World"
  integer,    // 0
  floating,   // 0.0
  void_val,   // void

  concat,       // &
  space_concat, // &&

  add,      // +
  subtract, // -
  multiply, // *
  divide,   // /
  mod,      // mod (%)

  negate, // not
  or_,    // or
  and_,   // and

  equal,         // =
  inequal,       // <>
  greater,       // >
  smaller,       // <
  greater_or_eq, // >=
  smaller_or_eq  // <=
};

enum class math_binary_operator : uint8_t {
  addition,
  subtraction,
  multiplication,
  division,
  mod
};

enum class logic_binary_operator : uint8_t {
  or_,
  and_,
  equal,
  inequal,
  greater,
  smaller,
  greater_or_eq,
  smaller_or_eq
};

enum class math_unary_operator : uint8_t { affirmation, negation };

enum class logic_unary_operator : uint8_t { negation };

struct token {
  const token_type type;
  const std::string value;

  token() = delete;
  token(token_type, const std::string &&);
};

std::ostream &operator<<(std::ostream &, const token &);

std::vector<token> tokenize(std::ifstream &);
std::vector<token> tokenize_line(std::ifstream &);
bool tokenize_line(std::ifstream &, std::vector<token> &);
std::vector<token> tokenize(const std::string &);
}; // namespace mp
