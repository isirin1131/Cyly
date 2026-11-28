module example_math;

// 同模块跨文件共享声明，不需要 import，且不受输入次序影响。
export func double_value(i32 value) -> i32 {
    return helper(value);
}

export func triple_value(i32 value) -> i32 {
    return value * factor;
}
