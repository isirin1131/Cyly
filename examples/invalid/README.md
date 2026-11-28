# 预期拒绝的示例

这里每个 `.cy` 文件都是独立输入，标出的错误故意保留。不要与正常示例一起编译，也不要因为当前词法器接受其中某些输入，就认为程序符合规范。

| 文件 | 预期拒绝原因 | 规范依据 |
| --- | --- | --- |
| [implicit-conversion.cy](implicit-conversion.cy) | 已定型 i32 不隐式转为 i64 | §3.2、§7.2，D10 |
| [union-literal.cy](union-literal.cy) | 联合没有字面量类型 1，不回退为 i32 | §4.4，D33 |
| [parenthesized-place.cy](parenthesized-place.cy) | 括号表达式不能作赋值目标 | §3.6、§7.3，D11 |
| [recursive-value.cy](recursive-value.cy) | 结构字段按值递归，未经过指针 | §3.4，D29 |
| [class-identity.cy](class-identity.cy) | 两个无字段类仍按声明保持独立身份 | §3.1、§11.1 |
| [empty-object.cy](empty-object.cy) | typedef 结构对象不能为空 | §0.6、§3.4，D22 |
| [bare-declaration.cy](bare-declaration.cy) | 变量声明未包在块内，直接作 if 主体 | §0.8，D12 |
| [continue-block.cy](continue-block.cy) | continue 指向块而非循环 | §8.2，D15 |
| [missing-return.cy](missing-return.cy) | 非 void 函数有正常落到末尾的路径 | §10.2，D18 |
| [unknown-escape.cy](unknown-escape.cy) | 字符串中存在未知转义 | §0.3、§2.3，D02 |
| [incomplete-number.cy](incomplete-number.cy) | 二进制字面量含数字 2，不能拆 token 接受 | §2.2，D31 |

章节号对应[规范草案 0.5](../../docs/language-spec.typ)。D 编号是规范诊断索引，实际编译器无需使用相同错误码或提示措辞。这里展示常见边界，不是完整的语言符合性测试集；部分错误属于名字解析或类型检查，不要求首个仅输出 AST 的前端里程碑完成这些检查。
