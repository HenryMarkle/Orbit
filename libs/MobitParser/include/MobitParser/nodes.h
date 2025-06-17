#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include <MobitParser/tokens.h>

namespace mp {
enum class binary_operation : uint8_t {
  addition,       // +
  subtraction,    // -
  multiplication, // *
  division,       // /

  member_access, // point.x, rect.width, ..

  and_, // and
  or_   // or
};

enum class unary_operation : uint8_t {
  logical_negation,    // not
  mathema_negation,    // -
  mathema_affirmation, // +
  member_call,         // point(..), rect(..), ..
  index                // arr[0]
};

/// TODO: implement this
inline int operator_precedence(token_type) { return 0; }

class Node {
public:
  virtual ~Node() = default;
};

class Void : public Node {};

class Int : public Node {
public:
  const int number;

  Int(int);
};

class Float : public Node {
public:
  const float number;

  Float(float);
};

class String : public Node {
public:
  const std::string str;

  String(std::string);
  String(std::string &&);
};

class Symbol : public Node {
public:
  const std::string str;

  Symbol(std::string);
  Symbol(std::string &&);
};

class Iden : public Node {
public:
  const std::string identifier;

  Iden() = delete;
  Iden(std::string &&);
};

class BinOp : public Node {
public:
  const binary_operation op;
  const std::unique_ptr<Node> left, right;

  BinOp(binary_operation op_, std::unique_ptr<Node> &&left_,
        std::unique_ptr<Node> &&right_);
};

class UnOp : public Node {
public:
  const unary_operation op;
  const std::unique_ptr<Node> operand;

  UnOp(unary_operation op_, std::unique_ptr<Node> &&operand_);
};

class List : public Node {
public:
  const std::vector<std::unique_ptr<Node>> elements;

  List();
  List(std::vector<std::unique_ptr<Node>> &&);
};

class Props : public Node {
public:
  const std::unordered_map<std::string, std::unique_ptr<Node>> map;

  Props();
  Props(std::unordered_map<std::string, std::unique_ptr<Node>> &&);
};

class GCall : public Node {
public:
  const std::string name;
  const std::vector<std::unique_ptr<Node>> args;

  GCall(std::string &&, std::vector<std::unique_ptr<Node>> &&);
};

inline std::ostream &operator<<(std::ostream &stream, unary_operation op) {
  switch (op) {
  case unary_operation::logical_negation:
    stream << "not";
    break;
  case unary_operation::mathema_negation:
    stream << '-';
    break;
  case unary_operation::mathema_affirmation:
    stream << '+';
    break;

  default: {
  } break;
  }

  return stream;
}

inline std::ostream &operator<<(std::ostream &stream, binary_operation op) {
  switch (op) {
  case binary_operation::addition:
    stream << "+";
    break;
  case binary_operation::subtraction:
    stream << "-";
    break;
  case binary_operation::multiplication:
    stream << "*";
    break;
  case binary_operation::division:
    stream << "/";
    break;
  case binary_operation::member_access:
    stream << '.';
    break;
  case binary_operation::and_:
    stream << "and";
    break;
  case binary_operation::or_:
    stream << "or";
    break;
  }

  return stream;
}

std::ostream &operator<<(std::ostream &, const Node *);

/// @brief Constructs an abstract syntax tree from the expression string.
/// @param str The expression string.
/// @param flat_tree pre-evaluates some expression such as unary operations to
/// numbers and global calls.
std::unique_ptr<Node> parse(const std::string &str, bool flat_tree = true);

/// @brief Constructs an abstact syntax tree from a node vector.
std::unique_ptr<Node> parse(const std::vector<token> &tokens,
                            bool flat_tree = true);
}; // namespace mp
