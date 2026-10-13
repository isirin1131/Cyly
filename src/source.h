#ifndef Cyly_source_h
#define Cyly_source_h

#include <stddef.h>

typedef enum {
  SOURCE_OK,
  SOURCE_IO_ERROR, // 无法打开或读取文件
  SOURCE_HAS_NUL,  // 文件含 NUL 字节，几乎一定是 UTF-16 编码
} SourceStatus;

#ifdef __cplusplus
extern "C" {
#endif

// 以二进制模式原样读取整个文件，并在末尾补 '\0'。不会改写任何字节。
// 成功时 *outBuffer 由调用者 free()。
SourceStatus readSource(const char* path, char** outBuffer, size_t* outLength);

const char* sourceStatusMessage(SourceStatus status);

#ifdef __cplusplus
}
#endif

#endif
