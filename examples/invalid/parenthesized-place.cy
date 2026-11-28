module examples.invalid.parenthesized_place;

func main() -> void {
    i32 value = 0;
    (value) = 1; // 预期编译错误 D11：括号表达式产生右值
}
