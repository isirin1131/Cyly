# 联合查询与显式读取：场景推演

日期：2026-11-09。依据：[已定特性](../DESIGN_DECISIONS.md)。当前不做自动类型收窄，提供运行时 `typeof` 查询联合当前类型、`readas` 按允许类型显式读值两项能力。

本文推演写法；`readas` 不检查当前成员，允许成员不匹配的读取，成员不匹配本身不属于未定义行为。操作的最终语法、具体存储表示、对象复制规则和指针规则未定。例子没有对应的编译器实现，不能作为可运行测试。

## 先记住：别名不提供分支身份

**不同名字不代表不同类型。相同结构在联合中只保留一次，运行时不能查询出原先使用的别名。**

```cy
type UserId = { id: i32 };
type OrderId = { id: i32 };
type AnyId = UserId | OrderId;
```

展开并去重后，`AnyId` 就是 `{ id: i32 }`。`UserId` 和 `OrderId` 是同一类型；查询与读取都不能区分“原本想表示用户还是订单”。

需要区分时，把区别写进类型描述的实际值：

```cy
type UserId = { kind: "user"; id: i32 };
type OrderId = { kind: "order"; id: i32 };
type AnyId = UserId | OrderId;
```

这两个结构因字面量字段不同而可区分，名字本身仍不提供身份隔离。查询所用的判别信息如何存储属于实现布局，不要求按字符串名字反射。

## 示例记号

暂用两个内建操作的占位记号：

- `typeof(v) == T`：查询 `v` 当前所存值的类型，并与 `T` 比较。
- `readas(v, T)`：按 `T` 解释 `v` 的数据存储并读取，表达式的静态类型为 `T`。

这两个名字表示内建操作，不是普通函数；不引入泛型或可供用户操作的完整运行时类型对象。`readas` 按目标类型解释已有存储，不执行整数到浮点数这样的数值转换。

`v` 在条件内外都保留声明类型。读取表达式的类型来自显式写出的 `T`，不依赖前面有没有 `if`，也不要求编译器证明两个操作之间的关系。联合不允许的目标类型编译报错；目标类型允许时，即使实际成员不同也允许读取，不进行成员匹配检查。编译器不得以目标类型必定匹配当前成员为前提进行优化。`typeof` 与 `readas` 之间不形成编译期收窄关系。

为了检验最小能力，下面只用单个成员作为读取目标，不额外假设允许读取一个较小的子联合。类型名按透明别名解释，不成为新的运行时身份；对象示例用不同字面量字段使分支互不重叠。重复结构会在联合归一化时合并。

## 1. 可空值的普通分支

```cy
type MaybeInt = i32 | null;
MaybeInt result = getnumber();

if (typeof(result) == i32) {
    print readas(result, i32) + 1;
} else {
    print "没有结果";
}
```

也可沿用允许的空值比较写 `if (result != null)`，分支内仍显式读取。比较只是产生 bool，不改变 `result` 的类型。

反复使用时，用普通局部变量：

```cy
if (typeof(result) == i32) {
    i32 n = readas(result, i32);
    print n + 1;
    print n * 2;
}
```

## 2. 提前返回与默认值

```cy
func get_or_zero(MaybeInt result) -> i32 {
    if (typeof(result) == null) return 0;
    return readas(result, i32);
}
```

这不要求编译器从提前返回推导剩余类型。返回表达式自己写明了读取类型。`break`、`continue` 后的同类代码采用相同方法。

## 3. 短路条件

```cy
if (typeof(result) == i32 and readas(result, i32) > 0) {
    print "正整数";
}

if (typeof(result) == null or readas(result, i32) <= 0) {
    print "没有正整数";
}
```

靠已经确定的短路求值决定是否执行读取，无需 `and` 或 `or` 传播类型信息。这些例子针对没有中间修改的普通局部值。

## 4. 多种类型分别处理

```cy
type Value = i32 | f64 | bool;
Value v = getvalue();

if (typeof(v) == i32) {
    print readas(v, i32) + 1;
} else if (typeof(v) == f64) {
    print readas(v, f64) * 2.0;
} else {
    print readas(v, bool);
}
```

不需要先增加 `switch`、模式匹配或穷尽检查。如果以后扩充 `Value`，这段最后的 `else` 不会自动成为覆盖完整的保证；这是既有“不做穷尽检查”的边界。

## 5. 对象分支、成功与失败

```cy
type Ok = { kind: "ok"; value: i32 };
type Error = { kind: "error"; message: string };
type Result = Ok | Error;

Result r = calculate();
if (typeof(r) == Ok) {
    print readas(r, Ok).value;
} else {
    print readas(r, Error).message;
}
```

`Ok` 和 `Error` 只是结构的透明别名，不恢复名字隔离；这里能区分它们，是因为 `kind` 的字面量值不同。分支专有字段通过 `readas` 读取，不提供共同字段的特殊访问能力。

## 6. 判断封装成普通函数，或先保存 bool

```cy
func has_int(MaybeInt v) -> bool {
    return typeof(v) == i32;
}

MaybeInt result = getnumber();
bool found = has_int(result);
if (found) {
    i32 n = readas(result, i32);
    print n + 1;
}
```

不需要“返回值为真时，参数就收窄成某类型”的特殊函数签名。条件可以跨函数、保存在 bool 中，也可以参与复杂业务判断；读取的静态类型独立于这些条件。

但 `found` 只记录判断时的结果。若中间修改了 `result`，旧 bool 不保证新值仍为整数。

## 7. 循环读取与筛选

```cy
MaybeInt next = getnumber();
while (typeof(next) == i32) {
    i32 n = readas(next, i32);
    print n;
    next = getnumber();
}
```

每轮显式取出当前值，循环末尾允许替换联合。筛选容器成员时，也可在每轮把元素读入局部联合，再判断、读取、处理；不需要引入“过滤后自动推导容器类型”的能力。

## 8. 嵌套字段与多个联合值

```cy
type Box = { item: MaybeInt };
type MaybeBox = Box | null;

MaybeBox outer = getbox();
if (typeof(outer) == Box) {
    MaybeInt inner = readas(outer, Box).item;
    if (typeof(inner) == i32) {
        print readas(inner, i32);
    }
}
```

多层数据逐层读取，不需要编译器长期维护 `outer.item` 这类访问路径的收窄事实。

两个联合的组合也能用普通短路条件：

```cy
if (typeof(a) == i32 and typeof(b) == i32) {
    print readas(a, i32) + readas(b, i32);
}
```

这里 `a`、`b` 均为已初始化的 `MaybeInt` 局部变量。

## 9. 调用函数与传递结果

```cy
if (typeof(result) == i32) {
    process_int(readas(result, i32));
}
```

`process_int` 接收普通 `i32` 参数，不需要了解联合或调用前的判断。用于返回值或传给已明确函数类型的函数指针也一样，不要求类型信息跨调用传播。

若要把一个大联合中的若干成员传给更小的联合参数，最小能力的重复会变明显：

```cy
type TextOrInt = i32 | string;
type Input = i32 | string | bool;
Input input = getinput();

if (typeof(input) == i32) {
    consume(readas(input, i32));
} else if (typeof(input) == string) {
    consume(readas(input, string));
}
```

此处 `consume` 接收 `TextOrInt`；每个分支取得的值均是它允许的成员。不能只排除 bool，就依靠控制流把整个 `input` 自动当成 `TextOrInt`。如果将来允许 `readas(input, TextOrInt)`，可以缩短代码，但这是“读取目标是否允许子联合”的独立选择。

## 10. 修改之后继续使用

```cy
if (typeof(result) == i32) {
    i32 n = readas(result, i32);
    result = getnumber();
    print n + 1;
}
```

`n` 是已取得的整数；`result` 的替换不影响它。想使用新的联合值，就针对新值再次查询和读取。

成员已改变后，仍可以按原类型读取：

```cy
if (typeof(result) == i32) {
    result = null;
    print readas(result, i32);
}
```

最后一次读取的目标类型属于联合，实际成员已是 `null`。这次读取仍被允许，不因成员不匹配报错或成为未定义行为。具体读到什么取决于后续确定的存储规则，目前不能承诺读到零或先前的整数。

外面的 `if` 不会产生编译期收窄。后端仍可进行保持规定行为的普通优化，但不能因为出现 `readas(result, i32)` 就认定 `result` 必须存着整数，或把这条路径视为不可能执行。

## 11. 更新成员与原地访问

整数更新可以读取后给整个联合赋回：

```cy
if (typeof(result) == i32) {
    result = readas(result, i32) + 1;
}
```

若对象采用独立值语义，也可读出、修改、赋回：

```cy
if (typeof(r) == Ok) {
    Ok value = readas(r, Ok);
    value.value = value.value + 1;
    r = value;
}
```

对象复制规则尚未确定，这里展示的是按值方案。不能据“读取能力”自行认定 `readas(r, Ok).value = 1` 合法，或认定能取得其内部成员的指针。大对象无需复制的原地修改、成员引用的返回和保存，需要另外的存储访问规则；不是查询与读值这两项能力自动附送的性质。

## 12. 哪些写法确实会更啰嗦

| 场景 | 只用两个基础操作的改写 | 主要区别 |
|---|---|---|
| 非空后运算 | 查询或比较 null，显式读成具体类型 | 每次读取注明类型，或多一个局部变量 |
| 提前返回、break、continue | 退出后显式读取 | 不靠控制流推导剩余类型 |
| 短路条件 | 条件右侧显式读取 | 沿用普通 bool 与短路语义 |
| 对象、嵌套字段 | 选择结构并逐层读取 | 路径长时需要中间变量 |
| 判断函数、保存 bool | 普通函数和变量，使用处显式读取 | 无需特殊类型谓词，旧判断仍可能过时 |
| 字面量分支 | 普通值比较；需要其他数据时再读取 | 不需要创造新的名义类型身份 |
| 转交多个剩余成员 | 按成员分别读取、调用 | 未增加子联合读取时存在重复 |
| 更新原联合 | 读值后赋回 | 大对象原地访问不能据此保证 |

这些例子覆盖主要的读取、控制流和调用场景。编译器检查联合是否允许目标类型，`typeof` 按需查询当前成员，`readas` 按目标类型读取存储而不检查成员。字段访问统一放在明确读取之后；这些操作不决定返回值是否与原存储共享数据。

## 13. 使用建议：按需要保存读取结果

同一个联合值需要反复参与计算时，可以用一次 `readas` 取成具体类型的局部变量，减少重复书写并保存这次读取结果：

```cy
i32 n = readas(result, i32);
print n + 1;
print n * 2;
```

`readas` 本身不检查成员，无需为了避免成员检查而把它搬出循环。每轮读取不同值时，可以直接在循环中使用。保存为局部变量主要服务于表达和取值时机；原联合之后被修改时，`n` 仍保存读出时的整数，需要新值就重新读取。实际数据读取或复制仍可能有成本。

## 14. 跨类型读取的存储规则

允许成员不匹配的读取，会使联合的数据表示成为可观察行为。后续需明确布局、字节序、大小不同的成员之间如何读取，以及未被写入覆盖的字节如何处理。`bool`、指针和字面量字段的位表示也需要相应规则；不能仅写“不检查”，再让后端假定目标类型的所有取值约束天然成立。

这些规则尚未确定，不能据当前决策承诺某次跨类型读取的具体结果。已经确定的是：成员不匹配本身不授权未定义行为，也不授权编译器删掉相关执行路径。
