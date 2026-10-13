#ifndef Cyly_scanner_h
#define Cyly_scanner_h

typedef enum {
  // Single-character tokens.
  TOKEN_LEFT_PAREN,  // (
  TOKEN_RIGHT_PAREN, // )
  TOKEN_LEFT_BRACE,  // {
  TOKEN_RIGHT_BRACE, // }
  TOKEN_COMMA,       // ,
  TOKEN_DOT,         // .
  TOKEN_MINUS,       // -
  TOKEN_PLUS,        // +
  TOKEN_SLASH,       // /
  TOKEN_STAR,        // *
  TOKEN_SEMICOLON,   // ;
  // One or two character tokens.
  TOKEN_BANG,          // !
  TOKEN_BANG_EQUAL,    // !=
  TOKEN_EQUAL,         // =
  TOKEN_EQUAL_EQUAL,   // ==
  TOKEN_GREATER,       // >
  TOKEN_GREATER_EQUAL, // >=
  TOKEN_LESS,          // <
  TOKEN_LESS_EQUAL,    // <=
  // Literals.
  TOKEN_IDENTIFIER, // 标识符: [a-zA-Z_][a-zA-Z_0-9]*
  TOKEN_STRING,     // 字符串字面量: "this is a string.\n"
  TOKEN_NUMBER,     // 数字字面量: 123 / 123.45
  // Keywords.
  TOKEN_AND,    // and
  TOKEN_OR,     // or
  TOKEN_FALSE,  // false
  TOKEN_TRUE,   // true
  TOKEN_ELSE,   // else
  TOKEN_FOR,    // for
  TOKEN_WHILE,  // while
  TOKEN_FUNC,    // func
  TOKEN_IF,     // if
  TOKEN_NULL,    // null
  TOKEN_PRINT,  // print
  TOKEN_RETURN, // return
  TOKEN_VAR,    // var

  TOKEN_ERROR, // 词法错误，无对应符号
  TOKEN_EOF    // 文件结束，无对应符号
} TokenType;

typedef struct {
  TokenType type;
  const char* start; // 指向原始源码（未经任何改写）；TOKEN_ERROR 时指向错误信息
  int length;
  int line;
} Token;

#ifdef __cplusplus
extern "C" {
#endif

// source 必须以 '\0' 结尾，且在扫描期间保持有效。
// 只会跳过文件开头的 UTF-8 BOM，不会修改源码。
void initScanner(const char* source);
Token scanToken(void);

// 把 TOKEN_STRING（含两侧引号）的转义序列解码为字符串的值。
// out 至少需要 token->length 字节；成功返回 NULL 并写入 *outLength，
// 失败返回错误信息。支持：\n \r \t \0 \\ \"
const char* decodeStringLiteral(const Token* token, char* out, int* outLength);

#ifdef __cplusplus
}
#endif

#endif

