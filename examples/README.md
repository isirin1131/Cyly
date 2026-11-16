# Cyly 示例

这些示例按[已定语言设计](../DESIGN_DECISIONS.md)组织，优先展示目标语言而非当前实现进度。当前 `make run` 仅用于词法读取；部分新语法尚未进入词法器，示例不能全部视为当前可执行程序。

- [hello.cy](hello.cy)：`main`、显式类型、内建 `print`、中文注释与单语句 `if`。
- [arrays-and-pointers.cy](arrays-and-pointers.cy)：定长数组的纯值语义、重复填充、数组指针、首元素指针、后缀解引用与无运行期检查的下标。
- [unions.cy](unions.cy)：指针类型与联合类型的优先级、`.as()` 联合读取、跨类型比特重解释及 `typeof` 查询。
- [strings.cy](strings.cy)：只读字节视图、内嵌 NUL、按内容比较与字节下标。
- [control-flow.cy](control-flow.cy)：C 式 `for`、具名循环的 `continue` 与具名 `if` 的 `break`。
- [module-layout.cy](module-layout.cy)：单文件模块、编译期常量初始化的模块变量及显式、不可传递的导入关系。
- [用 impl 按类型或按操作组织代码](impl-organization.md)：同一组结构体与方法的两种组织方式、同文件外部 `impl`、继承与静态分派。
- [memory-and-exceptions.md](memory-and-exceptions.md)：显式 Arena 生命周期、固定异常存储槽、按值异常与栈展开后的资源清理责任。
