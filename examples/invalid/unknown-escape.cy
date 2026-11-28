module examples.invalid.unknown_escape;

func main() -> void {
    string bad = "\q"; // 预期编译错误 D02：未知字符串转义
}
