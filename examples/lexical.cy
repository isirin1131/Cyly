module examples.lexical;

// 标识符使用 ASCII；字符串和注释可以包含中文。
/* 外层块注释
    /* 内层块注释 */
    引号和 // 在块注释中都只是普通内容。
*/
func main() -> void {
    i32 decimal = 010;       // 十进制 10，不是八进制
    i32 hex = 0xFF;
    i32 binary = 0b1010;
    f64 scale = 1e3;
    f32 fraction = 1.5e-3;
    i32 count /* 注释分隔 token */ = 2;
    string text = "中文 // /* */"; // 字符串内容不开始注释
    string escapes = "\n\r\t\0\\\"";

    print decimal;          // 10
    print hex;              // 255
    print binary;           // 10
    print scale == 1000.0;   // true
    print fraction > 0.0;   // true
    print count;            // 2
    print text;
    print escapes.len;      // 6 个解码后字节
}
