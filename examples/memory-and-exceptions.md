# 显式内存管理与异常

Cyly 不内建 GC、ARC、RAII、`new` 或 `delete`。声明、赋值、传参、返回和联合读取本身都不会隐式分配或释放堆内存；需要动态资源时，由普通库类型与函数显式完成。

下面的 `Arena`、`arena_init`、`arena_alloc_node`、`arena_alloc_i32` 和 `arena_deinit` 都是基础库接口示例，不是语言关键字或内建函数。

## 区域分配与显式清理

```cy
struct Node {
    i32 id;
}

func main() -> void {
    Arena arena = arena_init(4096);
    *Node node = arena_alloc_node(&arena, 42);

    print node.*.id;

    // Release the whole region at a deliberately chosen point. / 在明确选定的位置释放整个区域。
    arena_deinit(&arena);
}
```

`node` 只是裸指针，不携带生命周期元数据。`arena_deinit` 返回后，继续解引用 `node` 所产生的指针有效性问题由作者负责；语言不会自动追踪或延长区域寿命。按需使用的引用计数容器同样属于库，而不是隐式语言行为。

## 异常按值传递，资源仍由作者清理

```cy
func require_positive(i32 value) -> i32 {
    if (value <= 0) throw value;
    return value;
}

func run(i32 input) -> void {
    Arena arena = arena_init(4096);

    try {
        *i32 result = arena_alloc_i32(&arena);
        result.* = require_positive(input);
        print result.*;
    } catch (i32 error) {
        print error;
    }

    // Normal completion and a handled throw both reach this explicit cleanup. / 正常结束与已处理的异常都会到达这次显式清理。
    arena_deinit(&arena);
}

func main() -> void {
    run(-1);
}
```

`throw` 将异常值复制到运行时预留的固定异常存储槽，不进行隐式堆分配；`catch` 再按值接收。栈展开只恢复控制流与栈帧，不调用局部变量的隐式析构函数，也不自动释放内存。

示例把 `arena_deinit` 放在 `try / catch` 之后，使正常路径和已处理的异常路径都执行同一次显式清理。如果异常继续向 `run` 外传播，清理责任必须转由外层 Arena 或调用方承担。异常值中的指针与 `string` 视图也不会延长其所指数据的寿命。
