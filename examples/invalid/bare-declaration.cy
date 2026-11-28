module examples.invalid.bare_declaration;

func main() -> void {
    if (true) i32 value = 1; // 预期编译错误 D12：声明不能直接充当主体
}
