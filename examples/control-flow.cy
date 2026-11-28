module examples.control_flow;

func main() -> void {
    i32 total = 0;
    outer: for (i32 i = 0; i < 3; i = i + 1) {
        for (i32 j = 0; j < 3; j = j + 1) {
            if (j == 1) continue outer; // 先执行外层 for 的步进
            total = total + 1;
        }
    }
    print total; // 3

    i32 count = 0;
    while (count < 4) {
        count = count + 1;
        if (count == 2) continue;
        if (count == 4) break;
        print count; // 1、3
    }

    exit_block: {
        for (;;) {
            break exit_block; // 退出整个具名块
        }
        print "unreachable";
    }

    report: if (total == 3) {
        print "matched";
        break report; // 退出完整 if 链，不进入 else
    } else {
        print "unreachable";
    }

    if (true)
        if (false) print "unreachable";
        else print "inner else"; // else 匹配最近的 if

    for (i32 i = 0; i < 2; i = i + 1); // 空语句主体
}
