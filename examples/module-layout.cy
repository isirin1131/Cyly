// This file is one module; top-level items are declarations, not statements. / 本文件即一个模块；顶层只放置声明，不执行语句。
i32 default_limit = 4;

struct Counter {
    i32 value;
}

// Other modules must import declarations explicitly; imports are not re-exported. / 其他模块必须显式导入声明；导入的名字不会继续转发给第三方。
func main() -> void {
    print default_limit;
}
