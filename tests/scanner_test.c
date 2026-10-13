// scanner / source 的跨平台行为测试。
// 测试输入全部在代码里用转义构造，不依赖磁盘上的样例文件，
// 因此不会被 Git 的 autocrlf 或编辑器悄悄改掉换行符和 BOM。

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "scanner.h"
#include "source.h"

static int failures = 0;

#define CHECK(cond)                                                   \
  do {                                                                \
    if (!(cond)) {                                                    \
      fprintf(stderr, "%s:%d: CHECK failed: %s\n", __FILE__, __LINE__, \
              #cond);                                                 \
      failures++;                                                     \
    }                                                                 \
  } while (0)

#define MAX_TOKENS 64

static int scanAll(const char* source, Token* tokens) {
  initScanner(source);
  int n = 0;
  for (;;) {
    Token t = scanToken();
    tokens[n++] = t;
    if (t.type == TOKEN_EOF || n == MAX_TOKENS) break;
  }
  return n;
}

static int hasError(const Token* tokens, int n, int* line) {
  for (int i = 0; i < n; i++) {
    if (tokens[i].type == TOKEN_ERROR) {
      if (line) *line = tokens[i].line;
      return 1;
    }
  }
  return 0;
}

// LF / CRLF / BOM / 末尾无换行：token 序列、词素、行号必须完全一致。
static void testLineEndingsAndBom(void) {
  const char* variants[] = {
      "var a = 1;\n// note\nprint \"hi\";\n",
      "var a = 1;\r\n// note\r\nprint \"hi\";\r\n",
      "\xEF\xBB\xBFvar a = 1;\n// note\nprint \"hi\";\n",
      "\xEF\xBB\xBFvar a = 1;\r\n// note\r\nprint \"hi\";\r\n",
      "var a = 1;\n// note\nprint \"hi\";",
  };
  Token expected[MAX_TOKENS];
  int expectedCount = scanAll(variants[0], expected);
  CHECK(expectedCount == 9);
  CHECK(!hasError(expected, expectedCount, NULL));
  CHECK(expected[5].type == TOKEN_PRINT && expected[5].line == 3);

  for (size_t v = 1; v < sizeof(variants) / sizeof(variants[0]); v++) {
    Token actual[MAX_TOKENS];
    int count = scanAll(variants[v], actual);
    CHECK(count == expectedCount);
    for (int i = 0; i < count && i < expectedCount; i++) {
      CHECK(actual[i].type == expected[i].type);
      // 末尾无换行时 EOF 本来就在上一行，只比较非 EOF token 的行号
      if (actual[i].type != TOKEN_EOF) CHECK(actual[i].line == expected[i].line);
      CHECK(actual[i].length == expected[i].length);
      CHECK(memcmp(actual[i].start, expected[i].start,
                   (size_t)actual[i].length) == 0);
    }
  }
}

// 用户写的 "\r" 转义：词素保持原文，解码后才是 CR 字节。
static void testEscapeIsPreserved(void) {
  Token t[MAX_TOKENS];
  int n = scanAll("\"a\\rb\"", t);
  CHECK(n == 2 && t[0].type == TOKEN_STRING);
  CHECK(t[0].length == 6 && memcmp(t[0].start, "\"a\\rb\"", 6) == 0);

  char out[16];
  int len = 0;
  CHECK(decodeStringLiteral(&t[0], out, &len) == NULL);
  CHECK(len == 3 && memcmp(out, "a\rb", 3) == 0);

  n = scanAll("\"q\\\"x\\\\\"", t); // "q\"x\\"
  CHECK(n == 2 && t[0].type == TOKEN_STRING);
  CHECK(decodeStringLiteral(&t[0], out, &len) == NULL);
  CHECK(len == 4 && memcmp(out, "q\"x\\", 4) == 0);

  n = scanAll("\"\\q\"", t);
  CHECK(t[0].type == TOKEN_STRING);
  CHECK(decodeStringLiteral(&t[0], out, &len) != NULL); // 未知转义
}

static void testRawLineBreakInStringIsError(void) {
  Token t[MAX_TOKENS];
  int line = 0;
  CHECK(hasError(t, scanAll("\"a\nb\"", t), &line) && line == 1);
  CHECK(hasError(t, scanAll("\"a\r\nb\"", t), &line) && line == 1);
  CHECK(hasError(t, scanAll("\"a\\\nb\"", t), &line) && line == 1);
  CHECK(hasError(t, scanAll("\"abc", t), NULL)); // 缺少结束引号
}

static void testLoneCrIsError(void) {
  Token t[MAX_TOKENS];
  CHECK(hasError(t, scanAll("var a = 1;\rprint a;", t), NULL));
}

static void testNonAscii(void) {
  Token t[MAX_TOKENS];
  // 字符串和注释里允许任意 UTF-8
  CHECK(!hasError(t, scanAll("print \"你好\"; // 注释\n", t), NULL));

  // 代码中的全角分号：整个字符算一个错误
  int n = scanAll("print 1\xEF\xBC\x9B", t); // print 1；
  int errors = 0;
  for (int i = 0; i < n; i++) errors += t[i].type == TOKEN_ERROR;
  CHECK(errors == 1);

  // 文件中间的 BOM 是错误
  CHECK(hasError(t, scanAll("var a;\n\xEF\xBB\xBFvar b;", t), NULL));
}

static void writeFile(const char* path, const char* data, size_t len) {
  FILE* f = fopen(path, "wb");
  CHECK(f != NULL);
  if (f == NULL) return;
  fwrite(data, 1, len, f);
  fclose(f);
}

static void testReadSource(void) {
  const char* path = "scanner_test_tmp.cy";
  char* buf = NULL;
  size_t len = 0;

  // CRLF + BOM 文件必须逐字节原样读入
  const char crlf[] = "\xEF\xBB\xBFvar a;\r\nprint a;\r\n";
  writeFile(path, crlf, sizeof(crlf) - 1);
  CHECK(readSource(path, &buf, &len) == SOURCE_OK);
  CHECK(len == sizeof(crlf) - 1 && memcmp(buf, crlf, len) == 0);
  free(buf);

  // UTF-16LE（如 PowerShell 5.1 的 `echo ... > a.cy`）
  const char utf16[] = {'\xFF', '\xFE', 'v', 0, 'a', 0, 'r', 0};
  writeFile(path, utf16, sizeof(utf16));
  CHECK(readSource(path, &buf, &len) == SOURCE_HAS_NUL);

  remove(path);
  CHECK(readSource(path, &buf, &len) == SOURCE_IO_ERROR);
}

int main(void) {
  testLineEndingsAndBom();
  testEscapeIsPreserved();
  testRawLineBreakInStringIsError();
  testLoneCrIsError();
  testNonAscii();
  testReadSource();

  if (failures > 0) {
    fprintf(stderr, "%d check(s) failed\n", failures);
    return 1;
  }
  printf("all scanner tests passed\n");
  return 0;
}
