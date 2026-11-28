# Cyly 示例

这些示例依据[语言规范草案 0.5](../docs/language-spec.typ)编写。规范是规则的权威记录；示例中的注释说明预期语义，不新增语言规则。

当前仓库只有早期探索用词法器，尚无完整 Cyly 编译器。这些程序尚未经过完整编译与执行验证，`make run FILE=...` 目前仅打印 token，且未覆盖现行全部词法规则，不能用来运行这些示例。下面列出的是未来编译器的源文件输入组合，不是当前可用的编译命令。

## 使用方式

- 本目录根部每个 `.cy` 都是独立完整程序，包含 `module` 和一个 `main`；每次选择一个文件，不要把它们合并成同一个可执行程序。
- 多文件示例按下方列出的文件集合分别构建；模块名由 `module` 决定，目录与文件名不决定模块身份，文件输入顺序不应改变行为。
- `// 3`、`// true` 等注释描述预期值。除 `print` 追加换行外，整数、浮点、布尔和指针的具体输出格式由实现规定；注释不是逐字节输出快照。
- 正常示例不依赖外部库。异常示例要求目标实现的固定异常槽足以容纳相应抛出及捕获类型；其他 ABI 参数依实现文档。
- [invalid/](invalid/README.md) 单独保存预期编译错误，不应纳入正常示例构建。

## 单文件示例

| 文件 | 内容 | 规范章节 |
| --- | --- | --- |
| [hello.cy](hello.cy) | main、显式类型、print、单语句 if | 0、8、9 |
| [lexical.cy](lexical.cy) | 进制、指数、嵌套注释、转义与中文内容 | 0、2 |
| [numbers.cy](numbers.cy) | 字面量定型、显式转换、位运算、回绕、浮点边界 | 3、7 |
| [scopes.cy](scopes.cy) | 局部 typedef、遮蔽、初始化式绑定、for 作用域 | 3、8 |
| [objects.cy](objects.cy) | 结构同一性、值复制、递归指针与浅复制 | 3、5 |
| [unions.cy](unions.cy) | 归一化、字面量成员、typeof、显式读取、可空指针 | 3、4 |
| [union-storage.cy](union-storage.cy) | 跨成员读取、bool 字节解释、写入清零 | 4 |
| [arrays-and-pointers.cy](arrays-and-pointers.cy) | 数组复制、重复填充、数组指针、指针转换 | 5、7 |
| [strings.cy](strings.cy) | 只读字节视图、NUL、UTF-8 字节长度、内容比较 | 2、6 |
| [expressions.cy](expressions.cy) | 优先级、赋值、求值顺序、短路、括号右值 | 3、7 |
| [control-flow.cy](control-flow.cy) | while、for、具名跳转、else 归属、空语句 | 0、8 |
| [functions.cy](functions.cy) | 递归、函数指针的参数与返回、函数指针联合 | 3、10 |
| [static-initialization.cy](static-initialization.cy) | 前向引用、常量初值、运行期修改与常量上下文 | 3、9 |
| [classes.cy](classes.cy) | 显式 init、默认参数、外部 impl、方法与函数指针字段 | 10、11 |
| [empty-classes.cy](empty-classes.cy) | 空类体、无字段类显式构造、类声明身份 | 3、11 |
| [inheritance.cy](inheritance.cy) | super、方法重写、静态分派、父类值与指针视图 | 7、11 |
| [field-constraints.cy](field-constraints.cy) | 继承字段 as 约束、原始联合类型、指针别名 | 11 |
| [exceptions.cy](exceptions.cy) | 精确匹配、联合捕获、未匹配异常向外传播 | 12 |
| [explicit-memory.cy](explicit-memory.cy) | 调用方提供存储的具体类型池、显式回收、异常路径 | 1、5、12 |
| [ast.cy](ast.cy) | 用递归结构联合表达并求值 2 + 3 * 4 | 3、4、5、10 |

`ast.cy` 只是语言数据建模示例，不是当前编译器的 AST 实现。所有节点由当前栈帧持有；实际前端可使用库提供的 Arena。`explicit-memory.cy` 实现的是固定容量 i32 池，不假设语言存在内建分配、析构或尚未提供的运行时 API。

## 多文件示例

| 目录 | 完整构建输入（相对该目录） | 展示内容 | 预期打印值 |
| --- | --- | --- | --- |
| [modules/](modules/) | [helpers.cy](modules/helpers.cy)、[operations.cy](modules/operations.cy)、[main.cy](modules/main.cy) | 同模块跨文件声明、内部成员、export 与导入别名 | 42、21 |
| [impl-organization/](impl-organization/) | [shapes.cy](impl-organization/shapes.cy)、[area.cy](impl-organization/area.cy)、[perimeter.cy](impl-organization/perimeter.cy)、[main.cy](impl-organization/main.cy) | 按操作跨文件组织外部 impl，导出方法访问内部字段 | 20、18、9、12 |
| [cyclic-imports/](cyclic-imports/) | [even.cy](cyclic-imports/even.cy)、[odd.cy](cyclic-imports/odd.cy)、[main.cy](cyclic-imports/main.cy) | 循环导入与先收集导出签名，有限深度相互递归 | true、true、false |
| [structural-modules/](structural-modules/) | [producer.cy](structural-modules/producer.cy)、[consumer.cy](structural-modules/consumer.cy)、[main.cy](structural-modules/main.cy) | 跨模块结构同一性、声明顺序不同的字段 | 7 |

多文件组织遵守规范第 9 章与第 11 章；结构同一性见 §3.4，独立编译兼容要求见 §13.2。把这些输入拆成独立编译产物时，还需实现模块接口并使用同版本编译器、同目标平台及一致 ABI 选项；本目录不规定尚未实现的命令行或库打包方式。

## 用于前端开发

首个前端里程碑的范围见[文档说明](../docs/README.md#实现范围与约定)。上述文件保留完整语言程序的形式；仅实现语句片段入口时，可以按实现约定选取函数体中的相应片段，不能据此把模块顶层执行语句当成合法完整源文件。

建议先核对词法、表达式树分组、赋值结合性、控制结构及源码定位，再逐步用函数、类型、模块与异常示例验证后续阶段。超出当前实现范围的特性应明确报告，不应悄悄跳过并宣称整个程序编译成功。
