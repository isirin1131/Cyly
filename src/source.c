#include "source.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

SourceStatus readSource(const char* path, char** outBuffer, size_t* outLength) {
  // 必须用 "rb"：Windows 的文本模式会改写 CRLF，导致 ftell 与 fread 的结果不一致。
  FILE* file = fopen(path, "rb");
  if (file == NULL) return SOURCE_IO_ERROR;

  if (fseek(file, 0, SEEK_END) != 0) {
    fclose(file);
    return SOURCE_IO_ERROR;
  }
  long size = ftell(file);
  if (size < 0) {
    fclose(file);
    return SOURCE_IO_ERROR;
  }
  rewind(file);

  char* buffer = (char*)malloc((size_t)size + 1);
  if (buffer == NULL) {
    fclose(file);
    return SOURCE_IO_ERROR;
  }
  size_t bytesRead = fread(buffer, 1, (size_t)size, file);
  fclose(file);
  if (bytesRead != (size_t)size) {
    free(buffer);
    return SOURCE_IO_ERROR;
  }
  buffer[bytesRead] = '\0';

  // scanner 以 '\0' 判断结束，文件中间的 NUL 会让代码被悄悄截断，必须拒绝。
  if (memchr(buffer, '\0', bytesRead) != NULL) {
    free(buffer);
    return SOURCE_HAS_NUL;
  }

  *outBuffer = buffer;
  *outLength = bytesRead;
  return SOURCE_OK;
}

const char* sourceStatusMessage(SourceStatus status) {
  switch (status) {
    case SOURCE_OK:       return "OK";
    case SOURCE_IO_ERROR: return "无法读取文件";
    case SOURCE_HAS_NUL:  return "文件包含 NUL 字节（可能是 UTF-16 编码），请另存为 UTF-8";
  }
  return "未知错误";
}
