#include <fstream>
#include <string>
#include <vector>

#include <MobitParser/exceptions.h>
#include <MobitParser/tokens.h>

namespace mp {
std::ostream &operator<<(std::ostream &stream, const token &token) {
  switch (token.type) {
  case token_type::open_bracket:
    stream << '[';
    break;
  case token_type::close_bracket:
    stream << ']';
    break;
  case token_type::open_paren:
    stream << '(';
    break;
  case token_type::close_paren:
    stream << ')';
    break;
  case token_type::colon:
    stream << ':';
    break;
  case token_type::comma:
    stream << ',';
    break;

  case token_type::integer:
    stream << "Int(" << token.value << ')';
    break;
  case token_type::floating:
    stream << "Float(" << token.value << ')';
    break;
  case token_type::string:
    stream << "Str(" << token.value << ')';
    break;
  case token_type::symbol:
    stream << "Sym(" << token.value << ')';
    break;
  case token_type::identifier:
    stream << "Iden(" << token.value << ')';
    break;

  case token_type::add:
    stream << '+';
    break;
  case token_type::subtract:
    stream << '-';
    break;
  case token_type::multiply:
    stream << '*';
    break;
  case token_type::divide:
    stream << '/';
    break;
  case token_type::mod:
    stream << '%';
    break;
  case token_type::negate:
    stream << "not";
    break;

  case token_type::equal:
    stream << '=';
    break;
  case token_type::inequal:
    stream << "<>";
    break;
  case token_type::greater:
    stream << '>';
    break;
  case token_type::greater_or_eq:
    stream << ">=";
    break;
  case token_type::smaller_or_eq:
    stream << "<=";
    break;
  case token_type::concat:
    stream << '&';
    break;
  case token_type::space_concat:
    stream << "&&";
    break;

  case token_type::void_val:
    stream << "void";
    break;

  default:
    stream << token.value;
  }

  return stream;
}

token::token(token_type type, const std::string &&value)
    : type(type), value(value) {}

std::vector<token> tokenize(std::ifstream &file) {
  std::vector<token> tokens;

  char c;
  auto pos = file.tellg();

  while (file.get(c)) {
    switch (c) {
    case ' ':
    case '\t': {
    } break;

    case '[':
      tokens.push_back(token(token_type::open_bracket, "["));
      break;
    case ']':
      tokens.push_back(token(token_type::close_bracket, "]"));
      break;

    case '(':
      tokens.push_back(token(token_type::open_paren, "("));
      break;
    case ')':
      tokens.push_back(token(token_type::close_paren, ")"));
      break;

    case ',':
      tokens.push_back(token(token_type::comma, ","));
      break;
    case ':':
      tokens.push_back(token(token_type::colon, ":"));
      break;

    case '#': {
      std::string symbol;

      while (file.peek() != EOF && isalnum(file.peek())) {
        symbol.push_back(file.get());
      }

      tokens.push_back(token(token_type::symbol, std::move(symbol)));
    } break;

    case '"': {
      std::string _str;

      char peeked;
      while (file.get(peeked) && peeked != '"') {
        _str.push_back(peeked);
      }

      tokens.push_back(token(token_type::string, std::move(_str)));
    } break;

    case '>': {
      if (char peeked = file.peek()) {
        if (peeked == '=') {
          tokens.push_back(token(token_type::greater_or_eq, ">="));
          file.get();
        } else {
          tokens.push_back(token(token_type::greater, ">"));
        }
      } else {
          tokens.push_back(token(token_type::greater, ">"));
      }
    } break;

    case '<': {
      if (char peeked = file.peek()) {
        if (peeked == '=') {
          tokens.push_back(token(token_type::smaller_or_eq, "<="));
          file.get();
        } else if (peeked == '>') {
          tokens.push_back(token(token_type::inequal, "<>"));
          file.get();
        } else {
          tokens.push_back(token(token_type::greater, "<"));
        }
      } else {
          tokens.push_back(token(token_type::greater, "<"));
      }
    } break;

    case '=': {
      tokens.push_back(token(token_type::equal, "="));

    } break;

    case '&': {
      auto saved_pos = file.tellg();
      char peeked;
      if (file.get(peeked)) {
        if (peeked == '&') {

          tokens.push_back(token(token_type::space_concat, "&&"));
        } else {
          file.seekg(saved_pos);
          tokens.push_back(token(token_type::concat, "&"));
        }
      } else {
        file.seekg(saved_pos);
        tokens.push_back(token(token_type::concat, "&"));
      }
    } break;

    case '-':
      tokens.push_back(token(token_type::subtract, "-"));
      break;
    case '+':
      tokens.push_back(token(token_type::add, "+"));
      break;
    case '*':
      tokens.push_back(token(token_type::multiply, "*"));
      break;
    case '/':
      tokens.push_back(token(token_type::divide, "/"));
      break;

    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9': {
      std::string number;

      number.push_back(c);

      bool floating = false;

      while ((isdigit(file.peek()) || file.peek() == '.')) {
        char peeked = file.get();
        
        if (peeked == '.') {
          if (floating)
            throw double_decimal_point(
                "floating number cannot have more than one decimal point");

          floating = true;
          number.push_back(peeked);
        } else {
          number.push_back(peeked);
        }
      }

      if (floating) {
        tokens.push_back(token(token_type::floating, std::move(number)));
      } else {
        tokens.push_back(token(token_type::integer, std::move(number)));
      }
    } break;

    case 'n': {
      char peeked;

      if ((file.get(peeked) && peeked == 'o' && file.get(peeked) &&
           peeked == 't')) {

        tokens.push_back(token(token_type::negate, "not"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'a': {
      char peeked;

      if ((file.get(peeked) && peeked == 'n' && file.get(peeked) &&
           peeked == 'd')) {

        tokens.push_back(token(token_type::and_, "and"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'o': {
      char peeked;

      if ((file.get(peeked) && peeked == 'r')) {
        tokens.push_back(token(token_type::or_, "or"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'm': {
      char peeked;

      if ((file.get(peeked) && peeked == 'o' && file.get(peeked) &&
           peeked == 'd')) {

        tokens.push_back(token(token_type::mod, "mod"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'v': {
      char peeked;

      if ((file.get(peeked) && peeked == 'o' && file.get(peeked) &&
           peeked == 'i' && file.get(peeked) && peeked == 'd')) {

        tokens.push_back(token(token_type::void_val, "void"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    // identifier
    default: {
      std::string iden;
      iden.push_back(c);

      auto saved_pos = file.tellg();
      char peeked;

      while (file.get(peeked) && isalnum(peeked)) {
        iden.push_back(peeked);
        saved_pos = file.tellg();
      }

      tokens.push_back(token(token_type::identifier, std::move(iden)));
      file.seekg(saved_pos);
    } break;
    }

    pos = file.tellg();
  }
  return tokens;
}

std::vector<token> tokenize_line(std::ifstream &file) {
  std::vector<token> tokens;

  char c;
  auto pos = file.tellg();

  while (file.get(c)) {
    if (c == '\r') 
      return tokens;
    if (c == '\n')
      return tokens;

    switch (c) {
    case ' ':
    case '\r':
    case '\n':
    case '\t': {
    } break;

    case '[':
      tokens.push_back(token(token_type::open_bracket, "["));
      break;
    case ']':
      tokens.push_back(token(token_type::close_bracket, "]"));
      break;

    case '(':
      tokens.push_back(token(token_type::open_paren, "("));
      break;
    case ')':
      tokens.push_back(token(token_type::close_paren, ")"));
      break;

    case ',':
      tokens.push_back(token(token_type::comma, ","));
      break;
    case ':':
      tokens.push_back(token(token_type::colon, ":"));
      break;

    case '#': {
      std::string symbol;

      auto saved_pos = file.tellg();

      while (file.peek() != EOF && isalnum(file.peek())) {
        symbol.push_back(file.get());
      }

      tokens.push_back(token(token_type::symbol, std::move(symbol)));
    } break;

    case '"': {
      std::string _str;

      char peeked;
      while (file.get(peeked) && peeked != '"') {
        _str.push_back(peeked);
      }

      tokens.push_back(token(token_type::string, std::move(_str)));
    } break;

    case '>': {
      if (char peeked = file.peek()) {
        if (peeked == '=') {
          tokens.push_back(token(token_type::greater_or_eq, ">="));
          file.get();
        } else {
          tokens.push_back(token(token_type::greater, ">"));
        }
      } else {
          tokens.push_back(token(token_type::greater, ">"));
      }
    } break;

    case '<': {
      if (char peeked = file.peek()) {
        if (peeked == '=') {
          tokens.push_back(token(token_type::smaller_or_eq, "<="));
          file.get();
        } else if (peeked == '>') {
          tokens.push_back(token(token_type::inequal, "<>"));
          file.get();
        } else {
          tokens.push_back(token(token_type::greater, "<"));
        }
      } else {
          tokens.push_back(token(token_type::greater, "<"));
      }
    } break;

    case '=': {
      tokens.push_back(token(token_type::equal, "="));

    } break;

    case '&': {
      auto saved_pos = file.tellg();
      char peeked;
      if (file.get(peeked)) {
        if (peeked == '&') {

          tokens.push_back(token(token_type::space_concat, "&&"));
        } else {
          file.seekg(saved_pos);
          tokens.push_back(token(token_type::concat, "&"));
        }
      } else {
        file.seekg(saved_pos);
        tokens.push_back(token(token_type::concat, "&"));
      }
    } break;

    case '-':
      tokens.push_back(token(token_type::subtract, "-"));
      break;
    case '+':
      tokens.push_back(token(token_type::add, "+"));
      break;
    case '*':
      tokens.push_back(token(token_type::multiply, "*"));
      break;
    case '/':
      tokens.push_back(token(token_type::divide, "/"));
      break;

    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9': {
      std::string number;

      number.push_back(c);

      bool floating = false;

      while ((isdigit(file.peek()) || file.peek() == '.')) {
        char peeked = file.get();

        if (peeked == '.') {
          if (floating)
            throw double_decimal_point(
                "floating number cannot have more than one decimal point");

          floating = true;
          number.push_back(peeked);
        } else {
          number.push_back(peeked);
        }
      }

      if (floating) {
        tokens.push_back(token(token_type::floating, std::move(number)));
      } else {
        tokens.push_back(token(token_type::integer, std::move(number)));
      }
    } break;

    case 'n': {
      char peeked;

      if ((file.get(peeked) && peeked == 'o' && file.get(peeked) &&
           peeked == 't')) {

        tokens.push_back(token(token_type::negate, "not"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'a': {
      char peeked;

      if ((file.get(peeked) && peeked == 'n' && file.get(peeked) &&
           peeked == 'd')) {

        tokens.push_back(token(token_type::and_, "and"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'o': {
      char peeked;

      if ((file.get(peeked) && peeked == 'r')) {
        tokens.push_back(token(token_type::or_, "or"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'm': {
      char peeked;

      if ((file.get(peeked) && peeked == 'o' && file.get(peeked) &&
           peeked == 'd')) {

        tokens.push_back(token(token_type::mod, "mod"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'v': {
      char peeked;

      if ((file.get(peeked) && peeked == 'o' && file.get(peeked) &&
           peeked == 'i' && file.get(peeked) && peeked == 'd')) {

        tokens.push_back(token(token_type::void_val, "void"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    // identifier
    default: {
      std::string iden;
      iden.push_back(c);

      while (file.peek() != EOF && isalnum(file.peek())) {
        iden.push_back(file.get());
      }

      tokens.push_back(token(token_type::identifier, std::move(iden)));
    } break;
    }

    pos = file.tellg();
  }
  return tokens;
}

bool tokenize_line(std::ifstream &file, std::vector<token> &tokens) {
  tokens.clear();
  bool result = true;

  char c;
  auto pos = file.tellg();

  while (file.get(c)) {
    if (c == '\r') 
      return !tokens.empty();
    if (c == '\n')
      return !tokens.empty();

    switch (c) {
    case ' ':
    case '\t': {
    } break;

    case '[':
      tokens.push_back(token(token_type::open_bracket, "["));
      break;
    case ']':
      tokens.push_back(token(token_type::close_bracket, "]"));
      break;

    case '(':
      tokens.push_back(token(token_type::open_paren, "("));
      break;
    case ')':
      tokens.push_back(token(token_type::close_paren, ")"));
      break;

    case ',':
      tokens.push_back(token(token_type::comma, ","));
      break;
    case ':':
      tokens.push_back(token(token_type::colon, ":"));
      break;

    case '#': {
      std::string symbol;

      auto saved_pos = file.tellg();

      while (file.peek() != EOF && isalnum(file.peek())) {
        symbol.push_back(file.get());
      }

      tokens.push_back(token(token_type::symbol, std::move(symbol)));
    } break;

    case '"': {
      std::string _str;

      char peeked;
      while (file.get(peeked) && peeked != '"') {
        _str.push_back(peeked);
      }

      tokens.push_back(token(token_type::string, std::move(_str)));
    } break;

    case '>': {
      if (char peeked = file.peek()) {
        if (peeked == '=') {
          tokens.push_back(token(token_type::greater_or_eq, ">="));
          file.get();
        } else {
          tokens.push_back(token(token_type::greater, ">"));
        }
      } else {
          tokens.push_back(token(token_type::greater, ">"));
      }
    } break;

    case '<': {
      if (char peeked = file.peek()) {
        if (peeked == '=') {
          tokens.push_back(token(token_type::smaller_or_eq, "<="));
          file.get();
        } else if (peeked == '>') {
          tokens.push_back(token(token_type::inequal, "<>"));
          file.get();
        } else {
          tokens.push_back(token(token_type::greater, "<"));
        }
      } else {
          tokens.push_back(token(token_type::greater, "<"));
      }
    } break;

    case '=': {
      tokens.push_back(token(token_type::equal, "="));

    } break;

    case '&': {
      if (file.peek() == '&') {
        file.get();
        tokens.push_back(token(token_type::space_concat, "&&"));
      } else {
        tokens.push_back(token(token_type::concat, "&"));
      }
    } break;

    case '-':
      tokens.push_back(token(token_type::subtract, "-"));
      break;
    case '+':
      tokens.push_back(token(token_type::add, "+"));
      break;
    case '*':
      tokens.push_back(token(token_type::multiply, "*"));
      break;
    case '/':
      tokens.push_back(token(token_type::divide, "/"));
      break;

    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9': {
      std::string number;

      number.push_back(c);

      bool floating = false;

      while ((isdigit(file.peek()) || file.peek() == '.')) {
        char peeked = file.get();
        if (peeked == '.') {
          if (floating)
            throw double_decimal_point(
                "floating number cannot have more than one decimal point");

          floating = true;
          number.push_back(peeked);
        } else {
          number.push_back(peeked);
        }
      }

      if (floating) {
        tokens.push_back(token(token_type::floating, std::move(number)));
      } else {
        tokens.push_back(token(token_type::integer, std::move(number)));
      }
    } break;

    case 'n': {
      char peeked;

      if ((file.get(peeked) && peeked == 'o' && file.get(peeked) &&
           peeked == 't')) {

        tokens.push_back(token(token_type::negate, "not"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'a': {
      char peeked;

      if ((file.get(peeked) && peeked == 'n' && file.get(peeked) &&
           peeked == 'd')) {

        tokens.push_back(token(token_type::and_, "and"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'o': {
      char peeked;

      if ((file.get(peeked) && peeked == 'r')) {
        tokens.push_back(token(token_type::or_, "or"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'm': {
      char peeked;

      if ((file.get(peeked) && peeked == 'o' && file.get(peeked) &&
           peeked == 'd')) {

        tokens.push_back(token(token_type::mod, "mod"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    case 'v': {
      char peeked;

      if ((file.get(peeked) && peeked == 'o' && file.get(peeked) &&
           peeked == 'i' && file.get(peeked) && peeked == 'd')) {

        tokens.push_back(token(token_type::void_val, "void"));
        break;
      } else {
        file.seekg(pos);
      }

      break;
    }

    // identifier
    default: {
      std::string iden;
      iden.push_back(c);

      while (file.peek() != EOF && isalnum(file.peek())) {
        iden.push_back(file.get());
      }

      tokens.push_back(token(token_type::identifier, std::move(iden)));
    } break;
    }

    pos = file.tellg();
  }
  return !tokens.empty();
}

std::vector<token> tokenize(const std::string &str) {
  if (str.size() == 0)
    return {};

  std::vector<token> tokens;

  auto cursor = str.begin();

  do {

    switch (*cursor) {
    case ' ':
    case '\r':
    case '\n':
    case '\t': {
    } break;

    case '[':
      tokens.push_back(token(token_type::open_bracket, "["));
      break;
    case ']':
      tokens.push_back(token(token_type::close_bracket, "]"));
      break;

    case '(':
      tokens.push_back(token(token_type::open_paren, "("));
      break;
    case ')':
      tokens.push_back(token(token_type::close_paren, ")"));
      break;

    case ',':
      tokens.push_back(token(token_type::comma, ","));
      break;
    case ':':
      tokens.push_back(token(token_type::colon, ":"));
      break;

    case '#': {
      std::string symbol;

      auto peek = cursor + 1;

      while (peek != str.end() && isalnum(*peek)) {
        symbol.push_back(*peek);
        peek++;
      }

      tokens.push_back(token(token_type::symbol, std::move(symbol)));
      cursor = peek - 1;
    } break;

    case '"': {
      std::string _str;

      auto peek = cursor + 1;

      while (peek != str.end() && *peek != '"') {
        _str.push_back(*peek);
        ++peek;
      }

      tokens.push_back(token(token_type::string, std::move(_str)));
      cursor = peek;
    } break;

    case '>': {
      auto peek = cursor + 1;

      if (peek != str.end() && *peek == '=') {
        cursor++;

        tokens.push_back(token(token_type::greater_or_eq, ">="));
      } else {
        tokens.push_back(token(token_type::greater, ">"));
      }
    } break;

    case '<': {
      auto peek = cursor + 1;

      if (peek != str.end()) {
        if (*peek == '=') {
          cursor++;
          tokens.push_back(token(token_type::smaller_or_eq, "<="));
        } else if (*peek == '>') {
          cursor++;
          tokens.push_back(token(token_type::inequal, "<>"));
        }

      } else {
        tokens.push_back(token(token_type::smaller, "<"));
      }
    } break;

    case '=': {
      tokens.push_back(token(token_type::equal, "="));

    } break;

    case '&': {
      auto peek = cursor + 1;

      if (peek != str.end() && *peek == '&') {
        cursor++;

        tokens.push_back(token(token_type::space_concat, "&&"));
      } else {
        tokens.push_back(token(token_type::concat, "&"));
      }
    } break;

    case '-':
      tokens.push_back(token(token_type::subtract, "-"));
      break;
    case '+':
      tokens.push_back(token(token_type::add, "+"));
      break;
    case '*':
      tokens.push_back(token(token_type::multiply, "*"));
      break;
    case '/':
      tokens.push_back(token(token_type::divide, "/"));
      break;

    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9': {
      std::string number;

      number.push_back(*cursor);

      auto peek = cursor + 1;
      bool floating = false;

      while (peek != str.end() && (isdigit(*peek) || *peek == '.')) {
        if (*peek == '.') {
          if (floating)
            throw double_decimal_point(
                "floating number cannot have more than one decimal point");

          floating = true;
          number.push_back(*peek);
        } else {
          number.push_back(*peek);
        }

        peek++;
      }

      cursor = peek - 1;

      if (floating) {
        tokens.push_back(token(token_type::floating, std::move(number)));
      } else {
        tokens.push_back(token(token_type::integer, std::move(number)));
      }
    } break;

    case 'n': {
      auto peek = cursor;

      if (!(++peek == str.end() || *peek != 'o' || ++peek == str.end() ||
            *peek != 't')) {

        tokens.push_back(token(token_type::negate, "not"));
        cursor = peek;
        break;
      }
    }

    case 'a': {
      auto peek = cursor;

      if (!(++peek == str.end() || *peek != 'n' || ++peek == str.end() ||
            *peek != 'd')) {

        tokens.push_back(token(token_type::and_, "and"));
        cursor = peek;
        break;
      }
    }

    case 'o': {
      auto peek = cursor;

      if (!(++peek == str.end() || *peek != 'r')) {
        tokens.push_back(token(token_type::or_, "or"));
        cursor = peek;
        break;
      }
    }

    case 'm': {
      auto peek = cursor;

      if (!(++peek == str.end() || *peek != 'o' || ++peek == str.end() ||
            *peek != 'd')) {

        tokens.push_back(token(token_type::mod, "mod"));
        cursor = peek;
        break;
      }
    }

    case 'v': {
      auto peek = cursor;

      if (!(++peek == str.end() || *peek != 'o' || ++peek == str.end() ||
            *peek != 'i' || ++peek == str.end() || *peek != 'd')) {

        tokens.push_back(token(token_type::void_val, "void"));
        cursor = peek;
        break;
      }
    }

    // identifier
    default: {
      std::string iden;
      iden.push_back(*cursor);

      auto peek = cursor + 1;

      while (peek != str.end() && isalnum(*peek)) {
        iden.push_back(*peek);
        ++peek;
      }

      tokens.push_back(token(token_type::identifier, std::move(iden)));
      cursor = peek - 1;
    } break;
    }

    cursor++;

  } while (cursor != str.end());

  return tokens;
};
}; // namespace mp
