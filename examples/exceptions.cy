module examples.exceptions;

typedef Problem = i32 | bool;

func require_positive(i32 value) -> i32 {
    if (value <= 0) throw 7.to(i32);
    return value;
}

func throw_union() -> void {
    Problem problem = 9.to(i32);
    throw problem; // 抛出静态类型为 Problem 的整个联合
}

func main() -> void {
    // 实现的固定异常槽须能容纳 i32 和 Problem。
    try {
        print require_positive(0);
    } catch (Problem problem) {
        // 抛出 i32，以包含 i32 的联合捕获，构造联合标签。
        if (typeof(problem) == i32) print problem.as(i32); // 7
    }

    try {
        throw_union();
    } catch (bool | i32 problem) {
        // 与抛出联合类型精确匹配，成员顺序不影响身份。
        print typeof(problem) == i32; // true
        print problem.as(i32); // 9
    }

    try {
        try {
            throw 11.to(i32);
        } catch (bool unrelated) {
            print "unreachable"; // 静态异常类型不匹配，继续向外传播
        }
    } catch (i32 code) {
        print code; // 11
    }
    print "recovered";
}
