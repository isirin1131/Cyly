module examples.strings;

func main() -> void {
    string left = "A\0B";
    string same = "A\0B";
    string right = "A\0C";
    print left.len; // 3：NUL 计入长度
    print left[1];  // 0，字节读取结果为 u8
    print left == same; // true：比较内容
    print left != right; // true：NUL 不终止比较

    string chinese = "你好";
    print chinese.len; // 6：UTF-8 字节数，不是字符数
    string view = chinese; // 只复制视图，字面量存储在程序内持续存在
    print view;
    print "// 与 /* 在字符串内都不是注释 */";
}
