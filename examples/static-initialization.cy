module examples.static_initialization;

typedef Config = { limit: i32, enabled: bool };

// 编译期初值可以引用后面的模块级声明，但依赖不得成环。
i32 limit = base + 2;
i32 base = 2;
[limit]i32 defaults = [7; limit];
Config settings = { enabled: true, limit: limit };

func main() -> void {
    print limit; // 4
    print defaults.len; // 4
    base = 9;
    print base; // 9：模块级变量在运行期仍可变
    print limit; // 4：不会重新计算初值
    print settings.limit; // 4

    // 数组长度要求 ConstExpr，此处取得 base 声明时的初值 2。
    [base]i32 local = [0; base];
    print local.len; // 2
    print base;      // 9：普通运行期读取仍使用当前值
}
