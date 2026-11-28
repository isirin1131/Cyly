module examples.invalid.recursive_value;

typedef Node = { next: Node }; // 预期编译错误 D29：按值递归没有经过指针

func main() -> void {}
