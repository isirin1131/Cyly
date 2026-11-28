module examples.expressions;

typedef Pair = { a: i32, z: i32 };

func advance(*i32 state) -> i32 {
    state.* = state.* + 1;
    return state.*;
}

func observe(i32 before, i32 after) -> void {
    print before;
    print after;
}

func main() -> void {
    print 1 + 2 * 3; // 7
    i32 a = 0;
    i32 b = 0;
    a = b = 3;
    print a; // 3
    print b; // 3
    print a = 4; // 4：赋值本身也是表达式

    i32 state = 0;
    observe(state, advance(&state)); // 依次打印 0、1；首参数已取值
    // 字段初始化按书写顺序求值，不按规范化后的存储顺序求值。
    Pair pair = { z: advance(&state), a: advance(&state) };
    print pair.z; // 2
    print pair.a; // 3

    bool skipped_and = false and advance(&state) > 0;
    bool skipped_or = true or advance(&state) > 0;
    print not skipped_and and skipped_or; // true
    print state; // 3：短路跳过两个调用

    [2]i32 slots = [0; 2];
    i32 index = 0;
    slots[index] = index = 1; // 先确定左侧 slots[0]，再计算右侧
    print slots[0]; // 1
    print slots[1]; // 0
    *i32 pointer = &a;
    (pointer).* = 8; // 括号指针的解引用仍产生可写位置
    print a; // 8；但 (a) 本身是右值，不能赋值或取地址
}
