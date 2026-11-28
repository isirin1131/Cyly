module examples.invalid.union_literal;

func main() -> void {
    i32 | null value = 1; // 预期编译错误 D33：没有字面量类型 1 成员
    // 合法构造应写 1.to(i32)，不能从联合反推数值类型。
}
