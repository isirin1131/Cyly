module examples.invalid.continue_block;

func main() -> void {
    done: {
        continue done; // 预期编译错误 D15：continue 的目标必须是循环
    }
}
