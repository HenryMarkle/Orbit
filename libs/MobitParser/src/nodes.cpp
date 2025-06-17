#include <algorithm>
#include <cctype>
#include <iostream>
#include <memory>
#include <numeric>
#include <string>
#include <unordered_map>
#include <vector>

#ifdef __linux__
#include <string.h>
#endif

#include <MobitParser/exceptions.h>
#include <MobitParser/nodes.h>
#include <MobitParser/tokens.h>

namespace mp {
Int::Int(int number) : number(number) {}
Float::Float(float number) : number(number) {}
String::String(std::string &&str_) : str(std::move(str_)) {}
String::String(std::string str_) : str(str_) {}
Symbol::Symbol(std::string &&str_) : str(std::move(str_)) {}
Symbol::Symbol(std::string str_) : str(str_) {}
Iden::Iden(std::string &&iden) : identifier(std::move(iden)) {}
BinOp::BinOp(binary_operation op_, std::unique_ptr<Node> &&left_,
             std::unique_ptr<Node> &&right_)
    : op(op_), left(std::move(left_)), right(std::move(right_)) {}
UnOp::UnOp(unary_operation op_, std::unique_ptr<Node> &&operand_)
    : op(op_), operand(std::move(operand_)) {}
List::List() {}
List::List(std::vector<std::unique_ptr<Node>> &&elements_)
    : elements(std::move(elements_)) {}
Props::Props() {}
Props::Props(std::unordered_map<std::string, std::unique_ptr<Node>> &&map_)
    : map(std::move(map_)) {}
GCall::GCall(std::string &&name_, std::vector<std::unique_ptr<Node>> &&args_)
    : name(std::move(name_)), args(std::move(args_)) {}

std::ostream &operator<<(std::ostream &stream, const Node *node) {
  if (const auto *integer = dynamic_cast<const Int *>(node)) {
    stream << integer->number;
  } else if (const auto *floating = dynamic_cast<const Float *>(node)) {
    stream << floating->number;
  } else if (const auto *string = dynamic_cast<const String *>(node)) {
    stream << '"' << string->str << '"';
  } else if (const auto *symbol = dynamic_cast<const Symbol *>(node)) {
    stream << '#' << symbol->str;
  } else if (const auto *iden = dynamic_cast<const Iden *>(node)) {
    stream << iden->identifier;
  } else if (const auto *bin_op = dynamic_cast<const BinOp *>(node)) {
    stream << bin_op->left.get() << ' ' << bin_op->op << ' '
           << bin_op->right.get();
  } else if (const auto *un_op = dynamic_cast<const UnOp *>(node)) {
    stream << un_op->op << un_op->operand.get();
  } else if (const auto *list = dynamic_cast<const List *>(node)) {
    stream << '[';

    for (int i = 0; i < list->elements.size(); i++) {
      stream << list->elements[i].get();

      if (i != list->elements.size() - 1)
        stream << ", ";
    }

    stream << ']';
  } else if (const auto *props = dynamic_cast<const Props *>(node)) {
    stream << '[';

    for (auto i = props->map.begin(); i != props->map.end(); i++) {
      stream << '#' << i->first << ": " << i->second.get();
      stream << ",";
    }

    stream << ']';
  } else if (const auto *gcall = dynamic_cast<const GCall *>(node)) {
    stream << gcall->name << '(';

    for (int i = 0; i < gcall->args.size(); i++) {
      stream << gcall->args[i].get();

      if (i != gcall->args.size() - 1)
        stream << ", ";
    }

    stream << ')';
  }

  return stream;
}

enum class operators {
  addition,
  subtraction,
  multiplication,
  division,
  mod,

  math_negation,
  math_affirmation,
  logic_negation,
  or_,
  and_,

  concatenation,
  space_concatenation,

  member_access,
  member_call,

  equality,
  inequality,
  greater,
  smaller,
  greater_or_eq,
  smaller_or_eq
};

constexpr int operator_precedence(operators op) {
  switch (op) {
  case operators::equality:
  case operators::inequality:
    return 0;

  case operators::greater:
  case operators::greater_or_eq:
  case operators::smaller:
  case operators::smaller_or_eq:
    return 1;

  case operators::concatenation:
  case operators::space_concatenation:
    return 2;

  case operators::addition:
  case operators::subtraction:
    return 3;

  case operators::multiplication:
  case operators::division:
  case operators::mod:
    return 4;

  case operators::or_:
    return 4;
  case operators::and_:
    return 5;

  case operators::logic_negation:
  case operators::math_negation:
  case operators::math_affirmation:
    return 6;

  case operators::member_access:
  case operators::member_call:
    return 7;
  }

  return 0;
}

bool is_iden_const(const std::string &name) {
  if (name == "RETURN") return true;
  if (name == "ENTER") return true;
  if (name == "SPACE") return true;
  if (name == "QUOTE") return true;
  if (name == "TRUE") return true;
  if (name == "FALSE") return true;

  return false;
}

const char *eval_const_iden(const std::string &name) {
  if (name == "RETURN") return "\n";
  if (name == "ENTER") return "\n";
  if (name == "SPACE") return " ";
  if (name == "QUOTE") return "\"";
  if (name == "TRUE") return "true";
  if (name == "FALSE") return "false";
  return "";
}

std::unique_ptr<Node> parse_helper(std::vector<token>::const_iterator &cursor,
                                   std::vector<token>::const_iterator end,
                                   int precedence, bool flat_tree) {
  std::unique_ptr<Node> expr = nullptr;

  switch (cursor->type) {
    // Unary operators

  case token_type::add: {
    auto op = unary_operation::mathema_affirmation;

    if (++cursor == end)
      throw parse_failure("expected an expression");

    int req_precedence = operator_precedence(operators::math_affirmation);

    auto operand_expr =
        parse_helper(cursor, end, req_precedence + 1, flat_tree);

    if (flat_tree) {

      if (auto *integer = dynamic_cast<Int *>(operand_expr.get())) {
        expr = std::make_unique<Int>(integer->number);
      } else if (auto *floating = dynamic_cast<Float *>(operand_expr.get())) {
        expr = std::make_unique<Float>(floating->number);
      }

    } else {
      expr = std::make_unique<UnOp>(op, std::move(operand_expr));
    }

  } break;

  case token_type::subtract: {
    auto op = unary_operation::mathema_negation;

    if (++cursor == end)
      throw parse_failure("expected an expression");

    int req_precedence = operator_precedence(operators::math_negation);

    auto operand_expr =
        parse_helper(cursor, end, req_precedence + 1, flat_tree);

    // pre-evaluate the unary operation for negative numbers
    if (flat_tree) {

      if (auto *integer = dynamic_cast<Int *>(operand_expr.get())) {
        expr = std::make_unique<Int>(-1 * integer->number);
      } else if (auto *floating = dynamic_cast<Float *>(operand_expr.get())) {
        expr = std::make_unique<Float>(-1 * floating->number);
      }

    } else {
      expr = std::make_unique<UnOp>(op, std::move(operand_expr));
    }

  } break;

  case token_type::negate: {
    auto op = unary_operation::logical_negation;

    if (++cursor == end)
      throw parse_failure("expected an expression");

    int req_precedence = operator_precedence(operators::logic_negation);

    auto operand_expr =
        parse_helper(cursor, end, req_precedence + 1, flat_tree);

    expr = std::make_unique<UnOp>(op, std::move(operand_expr));
  };

  case token_type::integer: {
    int integer = std::stoi(cursor->value);

    expr = std::make_unique<Int>(integer);
  } break;

  case token_type::floating: {
    float floating = std::stof(cursor->value);

    expr = std::make_unique<Float>(floating);
  } break;

  case token_type::string: {
    expr = std::make_unique<String>(cursor->value);
  } break;

  case token_type::symbol: {
    expr = std::make_unique<Symbol>(cursor->value);
  } break;

  case token_type::identifier: {

    std::string iden = cursor->value;

    // pre-evaluate global calls
    if (flat_tree) {

      auto peek = cursor + 1;
      if (peek != end && peek->type == token_type::open_paren) {
        std::vector<std::unique_ptr<Node>> args;

        while (peek != end) {
          peek++;

          auto arg_expr = parse_helper(peek, end, precedence, flat_tree);

          args.push_back(std::move(arg_expr));

          if (++peek == end)
            throw parse_failure("global call expression ended prematurely "
                                "(expected a comma or a closing parentheses)");

          if (peek->type == token_type::close_paren)
            break;
          if (peek->type != token_type::comma)
            throw parse_failure(
                "global call expression ended prematurely (expected a comma)");
        }

        cursor = peek;

        expr = std::make_unique<GCall>(std::move(iden), std::move(args));
      } else {
        expr = std::make_unique<Iden>(std::move(iden));
      }
    }
  } break;

  case token_type::open_bracket: {
    // check for empty expression

    auto peek = cursor + 1;

    if (peek == end)
      throw parse_failure("collection expression ended prematurely");

    // empty linear list
    if (peek->type == token_type::close_bracket) {
      cursor++;

      expr = std::make_unique<List>();
    }
    // empty property list
    else if (peek->type == token_type::colon) {
      if (++peek == end)
        throw parse_failure("empty property list expression ended prematurely");

      if (peek->type != token_type::close_bracket)
        throw parse_failure(
            "invalid empty property list expression (expected ']')");

      cursor += 2;

      expr = std::make_unique<Props>();
    } else {
      std::vector<std::unique_ptr<Node>> list;
      std::unordered_map<std::string, std::unique_ptr<Node>> map;

      bool is_props = peek->type == token_type::symbol;

      bool needs_comma = false;

      while (peek != end) {
        if (is_props) {
          std::string key = peek->value;

          std::transform(key.begin(), key.end(), key.begin(), ::tolower);

          if (++peek == end)
            throw parse_failure("property list expression ended prematurely "
                                "(expected a colon)");

          if (peek->type != token_type::colon)
            throw parse_failure(
                "invalid property list expression (expected a colon)");

          if (++peek == end)
            throw parse_failure("property list expression ended prematurely "
                                "(expected an expression)");

          auto value_expr = parse_helper(peek, end, precedence, flat_tree);

          map.insert_or_assign(std::move(key), std::move(value_expr));

          if (++peek == end)
            throw parse_failure(
                "property list expression ended prematurely "
                "(expected a comma or a closing square bracket)");

          if (peek->type == token_type::close_bracket)
            break;
          if (peek->type != token_type::comma)
            throw parse_failure(
                "invalid property list expression (expected a comma)");
        } else {

          auto element_expr = parse_helper(peek, end, precedence, flat_tree);

          list.push_back(std::move(element_expr));

          if (++peek == end)
            throw parse_failure(
                "linear list expression ended prematurely (expected a comma)");

          if (peek->type == token_type::close_bracket)
            break;

          if (peek->type != token_type::comma)
            throw parse_failure(
                "invalid linear list expression (expected a comma)");
        }

        peek++;
      }

      if (is_props) {
        expr = std::make_unique<Props>(std::move(map));
      } else {
        expr = std::make_unique<List>(std::move(list));
      }

      cursor = peek;
    }

  } break;
  }

  if (expr != nullptr && flat_tree) {
    String *str = dynamic_cast<String*>(expr.get());
    Iden *iden = dynamic_cast<Iden*>(expr.get());

    if (str != nullptr || iden != nullptr) {
      std::string ss(str != nullptr ? str->str : eval_const_iden(iden->identifier));

      while ((cursor+1) != end) {
        auto peek = cursor + 1;

        if (peek->type != token_type::concat && peek->type != token_type::space_concat) break;

        auto rhs = peek + 1;
        if (rhs == end) throw parse_failure("expected an expression after '&' or '&&'");

        if (rhs->type == token_type::identifier && is_iden_const(rhs->value)) {
          const char *const_val = eval_const_iden(rhs->value);

          if (peek->type != token_type::space_concat) ss.append(" ");
          ss.append(const_val);

          cursor = rhs;
        } else if (rhs->type == token_type::string) {
          if (peek->type != token_type::space_concat) ss.append(" ");
          ss.append(rhs->value);
          cursor = rhs;
        }
        else break;
      }

      expr = std::make_unique<String>(ss);
    }
  }


  return expr;
}

std::unique_ptr<Node> parse(const std::string &str, bool flat_tree) {
  if (str.empty())
    return nullptr;

  const auto tokens = tokenize(str);

  if (tokens.empty())
    return nullptr;

  auto cursor = tokens.begin();
  auto end = tokens.end();

  auto expr = parse_helper(cursor, tokens.end(), 0, flat_tree);

  return expr;
}
std::unique_ptr<Node> parse(const std::vector<token> &tokens, bool flat_tree) {
  if (tokens.empty())
    return nullptr;

  auto cursor = tokens.begin();
  auto end = tokens.end();

  auto expr = parse_helper(cursor, tokens.end(), 0, flat_tree);

  return expr;
}
}; // namespace mp
