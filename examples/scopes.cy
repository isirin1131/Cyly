module examples.scopes;

typedef Count = i32;

func main() -> void {
    Count count = 4;
    {
        // 初值使用外层 count；新绑定在初始化之后才可见。
        i32 count = count + 1;
        typedef Count = i64;
        Count wide = 3000000000;
        print count; // 5
        print wide;  // 3000000000
    }
    print count; // 4

    for (i32 count = count; count < 6; count = count + 1) {
        print count; // 4、5
    }
    print count; // 4：for 的局部绑定已经离开作用域

    // 标签有独立名字空间，可与变量同名。
    count: {
        print count; // 4
        break count;
    }
}
