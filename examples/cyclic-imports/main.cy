module examples.cyclic_imports;
import { is_even } from example_even;
import { is_odd } from example_odd;

func main() -> void {
    print is_even(10); // true
    print is_odd(7);   // true
    print is_odd(10);  // false
    // 有界递归；Cyly 不执行尾调用优化。
}
