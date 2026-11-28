module examples.invalid.missing_return;

func choose(bool ready) -> i32 {
    if (ready) return 1;
} // 预期编译错误 D18：可能正常落到非 void 函数末尾

func main() -> void {}
