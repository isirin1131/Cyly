module examples.invalid.implicit_conversion;

func main() -> void {
    i32 small = 1;
    i64 wide = small; // 预期编译错误 D10：已定型数值不隐式转换
}
