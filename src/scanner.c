#include "scanner.h"

#include <stdbool.h>
#include <string.h>

// 设计原则：
//   1. 源码原样保留：直接扫描原始缓冲区，Token 指向原文。
//   2. 只识别文件格式层（开头的 BOM、行尾的 CRLF），不改写内容。
//   3. 字符串内容必须显式写出：普通字符串不允许直接换行，\r 等只能通过转义得到。
//   4. 看不懂就报错，不悄悄修正（单独的 CR、非 ASCII 字符出现在代码中）。

typedef struct {
  const char* start;
  const char* current;
  int line;
} Scanner;

static Scanner scanner;

void initScanner(const char* source) {
  // strncmp 遇到 '\0' 会停下，源码不足 3 字节时也安全。
  if (strncmp(source, "\xEF\xBB\xBF", 3) == 0) source += 3;
  scanner.start = source;
  scanner.current = source;
  scanner.line = 1;
}

static bool isAlpha(char c) {
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

static bool isDigit(char c) { return c >= '0' && c <= '9'; }

static bool isAtEnd(void) { return *scanner.current == '\0'; }

static char advance(void) {
  scanner.current++;
  return scanner.current[-1];
}

static char peek(void) { return *scanner.current; }

static char peekNext(void) {
  if (isAtEnd()) return '\0';
  return scanner.current[1];
}

static bool match(char expected) {
  if (isAtEnd() || *scanner.current != expected) return false;
  scanner.current++;
  return true;
}

static Token makeToken(TokenType type) {
  Token token;
  token.type = type;
  token.start = scanner.start;
  token.length = (int)(scanner.current - scanner.start);
  token.line = scanner.line;
  return token;
}

static Token errorToken(const char* message) {
  Token token;
  token.type = TOKEN_ERROR;
  token.start = message;
  token.length = (int)strlen(message);
  token.line = scanner.line;
  return token;
}

static void skipWhitespace(void) {
  for (;;) {
    switch (peek()) {
      case ' ':
      case '\t':
        advance();
        break;
      case '\r':
        if (peekNext() != '\n') return; // 单独的 CR：交给 scanToken 报错
        advance();                      // 跳过 \r，下一轮由 '\n' 负责 line++
        break;
      case '\n':
        scanner.line++;
        advance();
        break;
      case '/':
        if (peekNext() != '/') return;
        // 注释读到 '\n' 为止（CRLF 的 \r 算作注释内容，随注释一起丢弃）。
        while (peek() != '\n' && !isAtEnd()) advance();
        break;
      default:
        return;
    }
  }
}

static TokenType checkKeyword(int start, int length, const char* rest,
                              TokenType type) {
  if (scanner.current - scanner.start == start + length &&
      memcmp(scanner.start + start, rest, (size_t)length) == 0) {
    return type;
  }
  return TOKEN_IDENTIFIER;
}

static TokenType identifierType(void) {
  switch (scanner.start[0]) {
    case 'a': return checkKeyword(1, 2, "nd", TOKEN_AND);
    case 'e': return checkKeyword(1, 3, "lse", TOKEN_ELSE);
    case 'f':
      if (scanner.current - scanner.start > 1) {
        switch (scanner.start[1]) {
          case 'a': return checkKeyword(2, 3, "lse", TOKEN_FALSE);
          case 'o': return checkKeyword(2, 1, "r", TOKEN_FOR);
          case 'u': return checkKeyword(2, 2, "nc", TOKEN_FUNC);
        }
      }
      break;
    case 'i': return checkKeyword(1, 1, "f", TOKEN_IF);
    case 'n': return checkKeyword(1, 3, "ull", TOKEN_NULL);
    case 'o': return checkKeyword(1, 1, "r", TOKEN_OR);
    case 'p': return checkKeyword(1, 4, "rint", TOKEN_PRINT);
    case 'r': return checkKeyword(1, 5, "eturn", TOKEN_RETURN);
    case 't': return checkKeyword(1, 3, "rue", TOKEN_TRUE);
    case 'v': return checkKeyword(1, 2, "ar", TOKEN_VAR);
    case 'w': return checkKeyword(1, 4, "hile", TOKEN_WHILE);
  }
  return TOKEN_IDENTIFIER;
}

static Token identifier(void) {
  while (isAlpha(peek()) || isDigit(peek())) advance();
  return makeToken(identifierType());
}

static Token number(void) {
  while (isDigit(peek())) advance();
  if (peek() == '.' && isDigit(peekNext())) {
    advance(); // 吃掉 '.'
    while (isDigit(peek())) advance();
  }
  return makeToken(TOKEN_NUMBER);
}

static bool isLineBreak(char c) { return c == '\n' || c == '\r'; }

static Token string(void) {
  while (peek() != '"' && !isAtEnd()) {
    if (isLineBreak(peek())) {
      return errorToken("字符串不能直接换行，请使用 \\n");
    }
    // 跳过被转义的字符，避免 \" 提前结束字符串。
    // 反斜杠后紧跟换行时不跳过，让下一轮报"不能直接换行"。
    if (peek() == '\\' && peekNext() != '\0' && !isLineBreak(peekNext())) {
      advance();
    }
    advance();
  }
  if (isAtEnd()) return errorToken("字符串缺少结束引号");
  advance(); // 结束引号
  return makeToken(TOKEN_STRING);
}

Token scanToken(void) {
  skipWhitespace();
  scanner.start = scanner.current;

  if (isAtEnd()) return makeToken(TOKEN_EOF);

  char c = advance();
  if (isAlpha(c)) return identifier();
  if (isDigit(c)) return number();

  switch (c) {
    case '(': return makeToken(TOKEN_LEFT_PAREN);
    case ')': return makeToken(TOKEN_RIGHT_PAREN);
    case '{': return makeToken(TOKEN_LEFT_BRACE);
    case '}': return makeToken(TOKEN_RIGHT_BRACE);
    case ';': return makeToken(TOKEN_SEMICOLON);
    case ',': return makeToken(TOKEN_COMMA);
    case '.': return makeToken(TOKEN_DOT);
    case '-': return makeToken(TOKEN_MINUS);
    case '+': return makeToken(TOKEN_PLUS);
    case '/': return makeToken(TOKEN_SLASH);
    case '*': return makeToken(TOKEN_STAR);
    case '!': return makeToken(match('=') ? TOKEN_BANG_EQUAL : TOKEN_BANG);
    case '=': return makeToken(match('=') ? TOKEN_EQUAL_EQUAL : TOKEN_EQUAL);
    case '<': return makeToken(match('=') ? TOKEN_LESS_EQUAL : TOKEN_LESS);
    case '>': return makeToken(match('=') ? TOKEN_GREATER_EQUAL : TOKEN_GREATER);
    case '"': return string();
    case '\r': return errorToken("不支持单独的 CR 换行，请使用 LF 或 CRLF");
  }

  if ((unsigned char)c >= 0x80) {
    // 把整个 UTF-8 字符当作一个错误，而不是每个字节报一次
    // （也覆盖文件中间的 BOM、全角符号等）。
    while (((unsigned char)peek() & 0xC0) == 0x80) advance();
    return errorToken("代码中出现非 ASCII 字符（只允许出现在字符串和注释中）");
  }
  return errorToken("非法字符");
}

const char* decodeStringLiteral(const Token* token, char* out, int* outLength) {
  // token 包含两侧引号，且 scanner 已保证不含直接换行。
  const char* p = token->start + 1;
  const char* end = token->start + token->length - 1;
  int n = 0;

  while (p < end) {
    char c = *p++;
    if (c != '\\') {
      out[n++] = c;
      continue;
    }
    switch (*p++) {
      case 'n':  out[n++] = '\n'; break;
      case 'r':  out[n++] = '\r'; break;
      case 't':  out[n++] = '\t'; break;
      case '0':  out[n++] = '\0'; break;
      case '\\': out[n++] = '\\'; break;
      case '"':  out[n++] = '"';  break;
      default:   return "未知的转义序列";
    }
  }
  *outLength = n;
  return NULL;
}
