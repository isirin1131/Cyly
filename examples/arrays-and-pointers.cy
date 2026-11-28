module examples.arrays_and_pointers;

func next_value(*i32 calls) -> i32 {
    calls.* = calls.* + 1;
    return 7;
}

func main() -> void {
    [3]i32 original = [10, 20, 30];
    [3]i32 copy = original;
    copy[0] = 99;
    print original[0]; // 10
    print copy[0];     // 99
    print original.len; // 3，静态类型 i64

    *[3]i32 whole = &original;
    whole.*[1] = 40;
    *i32 first = &original[0]; // 数组不隐式退化为指针
    first[2] = 50;
    print original[1]; // 40
    print original[2]; // 50
    print first == &original[0]; // true

    i32 calls = 0;
    [3]i32 repeated = [next_value(&calls); 3];
    print calls; // 1：填充值只求值一次
    print repeated[2]; // 7

    // 对已知有效对象执行指针转换，并转回原类型。
    *u8 bytes = first.to(*u8);
    *i32 restored = bytes.to(*i32);
    print restored == first; // true
    print restored.*; // 10
    // 指针不拥有数组；这里所有访问都在数组寿命与边界内。
}
