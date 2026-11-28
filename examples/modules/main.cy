module examples.modules;
import { double_value as twice, triple_value } from example_math;

func main() -> void {
    print twice(21); // 42
    print triple_value(7); // 21
    // helper 与 factor 未导出，不能从当前模块导入。
}
