module examples.functions;

typedef Operation = *func(i32) -> i32;

func increment(i32 value) -> i32 {
    return value + 1;
}

func choose_operation() -> Operation {
    return &increment; // 函数不是一等值，通过 & 显式取得函数指针
}

func apply_twice(Operation operation, i32 value) -> i32 {
    return operation(operation(value));
}

func factorial(i32 value) -> i32 {
    if (value <= 1) return 1;
    return value * factorial(value - 1);
}

func main() -> i32 {
    Operation operation = choose_operation();
    print apply_twice(operation, 3); // 5
    print factorial(5); // 120
    // 括号把函数指针整体纳入外层联合；否则 | 属于返回类型。
    (*func(i32) -> i32) | null optional = operation;
    if (typeof(optional) == Operation) {
        print optional.as(Operation)(8); // 9
    }
    return 0; // 到进程退出状态的映射由实现规定
}
