module examples.invalid.incomplete_number;

func main() -> void {
    i32 bad = 0b102; // 预期编译错误 D31：二进制中出现不允许的数字
}
