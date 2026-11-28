module examples.explicit_memory;

// 一个仅分配 i32 槽位的具体类型池；存储由调用方提供。
// 这不是语言内建 Arena，也不需要尚未定义的堆分配 API。
typedef Pool = { data: *i32, used: i64, capacity: i64 };

func allocate(*Pool pool, i32 value) -> *i32 {
    if (pool.*.used >= pool.*.capacity) throw 1.to(i32);
    i64 index = pool.*.used;
    pool.*.data[index] = value;
    pool.*.used = index + 1;
    return &pool.*.data[index];
}

func reset(*Pool pool) -> void {
    pool.*.used = 0;
}

func main() -> void {
    // 固定异常槽只需容纳本例抛出的 i32。
    [2]i32 storage = [0; 2];
    Pool pool = { data: &storage[0], used: 0, capacity: storage.len };
    try {
        *i32 first = allocate(&pool, 10);
        *i32 second = allocate(&pool, 20);
        print first.* + second.*; // 30
        allocate(&pool, 30); // 容量检查在访问前抛出异常
    } catch (i32 code) {
        print code; // 1
    }
    print pool.used; // 2：栈展开不自动回滚池状态
    reset(&pool);   // 正常路径与已捕获异常路径汇合后显式回收槽位
    print pool.used; // 0
    *i32 reused = allocate(&pool, 40);
    print reused.*; // 40
    // reset 后不再使用此前取得的指针，storage 始终在 main 内存活。
    // 未匹配异常、catch 再次抛出或提前 return 均可能跳过这里的清理。
    reset(&pool);
}
