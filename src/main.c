#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <windows.h>
#endif

#include "scanner.h"
#include "source.h"

// 目前只是把 token 打印出来，方便调试 scanner。
static int dumpTokens(const char* source) {
  int errors = 0;
  int line = -1;
  initScanner(source);
  for (;;) {
    Token token = scanToken();
    if (token.line != line) {
      printf("%4d ", token.line);
      line = token.line;
    } else {
      printf("   | ");
    }
    printf("%2d '%.*s'\n", (int)token.type, token.length, token.start);
    if (token.type == TOKEN_ERROR) errors++;
    if (token.type == TOKEN_EOF) break;
  }
  return errors;
}

int main(int argc, char* argv[]) {
#ifdef _WIN32
  SetConsoleOutputCP(CP_UTF8); // 否则中文信息在 Windows 控制台中是乱码
#endif

  if (argc != 2) {
    fprintf(stderr, "Usage: cyly <path>\n");
    return 64;
  }

  char* source = NULL;
  size_t length = 0;
  SourceStatus status = readSource(argv[1], &source, &length);
  if (status != SOURCE_OK) {
    fprintf(stderr, "%s: %s\n", argv[1], sourceStatusMessage(status));
    return 74;
  }

  int errors = dumpTokens(source);
  free(source);
  return errors > 0 ? 65 : 0;
}
