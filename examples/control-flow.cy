func main() -> void {
    i32 total = 0;

    outer: for (i32 i = 0; i < 3; i = i + 1) {
        for (i32 j = 0; j < 3; j = j + 1) {
            if (j == 1) continue outer;
            total = total + 1;
        }
    }

    // Breaking a named if exits the whole if / else chain. / 对具名 if 执行 break 会退出整条 if / else 分支链。
    report: if (total > 0) {
        if (total == 3) break report;
        print 0;
    } else {
        print 0;
    }

    // The break above skips both branch prints, so this prints 3. / 上面的 break 跳过两个分支中的打印，因此这里打印 3。
    print total;
}
