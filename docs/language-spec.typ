// Build from the repository root: make docs
// No external Typst packages or network access are required.
#let ink = rgb("202c38")
#let accent = rgb("176c70")
#let muted = rgb("65727d")
#let pale = rgb("f2f6f7")
#let cjk-serif = sys.inputs.at("cjk-serif", default: "Songti SC")
#let cjk-sans = sys.inputs.at("cjk-sans", default: "PingFang SC")
#let latin-sans = sys.inputs.at("latin-sans", default: "Avenir Next")
#let mono = sys.inputs.at("mono", default: "Menlo")
#set document(title: "Cyly 语言规范草案", author: "Cyly", description: "Cyly 语言规范草案 0.5", date: datetime(year: 2026, month: 11, day: 24))
#set page(paper: "a4", margin: (top: 22mm, bottom: 21mm, x: 22mm), numbering: "1",
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 8pt, fill: muted)
      grid(columns: (1fr, auto), [CYLY / LANGUAGE SPECIFICATION], [草案 0.5])
      v(3pt)
      line(length: 100%, stroke: 0.4pt + rgb("ccd7db"))
    }
  },
  footer: context {
    if counter(page).get().first() > 1 {
      set text(size: 8pt, fill: muted)
      grid(columns: (1fr, auto), [Cyly 语言规范 · 2026-11-24], counter(page).display("1"))
    }
  })
#set text(font: ("Libertinus Serif", cjk-serif), size: 10.5pt, lang: "zh", fill: ink)
#set par(justify: true, leading: 0.65em, spacing: 0.85em)
#set heading(numbering: "1.1")
#set outline(indent: 1.1em)
#set list(indent: 1.2em, body-indent: 0.6em, spacing: 0.45em)
#set enum(indent: 1.3em, body-indent: 0.6em, spacing: 0.45em)
#show heading: set text(font: (latin-sans, cjk-sans), fill: accent)
#show heading.where(level: 1): set block(above: 1.8em, below: 1em)
#show heading.where(level: 2): set block(above: 1.2em, below: 0.7em)
#show heading.where(level: 3): set block(above: 1.0em, below: 0.55em)
#show outline.entry.where(level: 1): set block(above: 0.65em)
#show outline.entry.where(level: 1): set text(weight: "bold")
#show raw: set text(font: (mono, cjk-sans), size: 8.5pt)
#show raw.where(block: true): it => block(width: 100%, fill: pale, inset: 10pt, radius: 3pt, breakable: false, it)
#show link: set text(fill: accent)
#show ref: it => {
  let el = it.element
  if el != none and el.func() == heading {
    let nums = counter(heading).at(el.location())
    let body = if it.supplement != auto {
      [#it.supplement#numbering("1.1", ..nums)]
    } else if nums.len() == 1 {
      [第 #numbering("1", ..nums) 章]
    } else {
      [§#numbering("1.1", ..nums)]
    }
    link(el.location(), body)
  } else {
    it
  }
}
#let matrix(inset: 7pt, ..cells) = {
  set text(size: 9pt)
  table(columns: (auto, 1fr), inset: inset, stroke: 0.4pt + rgb("d4dfe2"), ..cells)
}

#v(26mm)
#text(font: latin-sans, size: 15pt, tracking: 2pt, fill: accent)[CYLY]
#v(10mm)
#text(font: cjk-sans, size: 32pt, weight: "bold")[语言规范]
#v(3mm)
#text(size: 17pt, fill: muted)[Language Specification · 草案 0.5]
#v(11mm)
#line(length: 33mm, stroke: 2pt + accent)
#v(9mm)
静态类型 · 原生编译 · 显式内存 · 值语义

本规范定义 Cyly 的源文本、语法、名字解析、类型与值、求值规则、程序组织及实现约束。
#v(1fr)
#text(size: 9pt, fill: muted)[
  草案 0.5\
  2026 年 11 月 24 日
]
#pagebreak()

#heading(numbering: none, outlined: false)[范围与记号]

本规范是 Cyly 语言规则的权威定义。正文中的“必须”和“不得”表示实现与程序须满足的强制要求；“编译错误”表示实现必须在编译期（词法、语法、名字解析或类型检查阶段）拒绝相应程序。示例和附录中的诊断索引用于说明和查阅，具体规则以正文为准。

“由实现规定”表示具体实现须选择并在实现文档中记录的事项，其选择必须符合本规范的其他约束。“未定义行为”表示本规范对相应执行不作要求。LLVM `poison` 及未定义行为适用于正文明确列出的运算边界。

语法采用 EBNF：`=` 定义产生式，`|` 表示选择，`[ ... ]` 表示可选项，`{ ... }` 表示零次或多次重复，双引号或单引号包围终结符。引号内的 `"|"`、`"["` 等才是源代码字符。产生式末尾的分号属于 EBNF；源代码分号写成 `";"`。`EOF` 表示输入结束。

文法片段与文字规则共同描述语言；各章列出的产生式不构成脱离正文的独立文法。合法程序除符合语法外，还须通过名字解析、类型检查并满足运行期有效性约束。

代码示例可省略模块声明及无关的外围声明；执行语句片段视为位于合法函数体内。标为“完整示例”的代码包含模块声明与所需的模块级声明。示例中的“错误”注释标明触发编译错误的位置。

#outline(title: [目录], depth: 2)
#pagebreak()

= 设计目标与全局约束 <ch-goals>

Cyly 是静态类型、原生编译的语言，采用值语义、显式内存管理和静态方法分派。语言操作的运行时成本应接近同等功能的 C 实现；未使用的能力不应增加运行时成本。

== 内存与资源约束 <sec-memory-model>

语言不内建 GC、ARC 或隐式析构，不为指针或对象维护隐式生命周期元数据。声明、赋值、传参、返回、联合读取等语言操作不产生隐式堆分配，也不自动释放内存。

手工分配、Arena、引用计数容器由库通过普通类型、函数和方法表达。`init` 是显式初始化入口；与之对应的清理同样必须显式调用普通函数或方法。语言不提供 `new`、`delete` 或 `unsafe` 专用关键字与代码块。

函数调用所需的栈帧、联合值的内联存储和运行时预留的固定异常槽不属于隐式堆装箱。程序可以显式调用分配内存的库函数。

== 可观察行为 <sec-observable>

实现选择的目标机器布局、寄存器分配与代码生成方式必须保留本规范规定的求值顺序、值复制效果、字符串内容比较、联合读取、静态分派、规范化字段布局、父类前缀和继承字段槽位。实现不得采用严格别名假设，也不得执行尾调用优化。具体二进制布局和异常槽参数由实现规定。

== 语言范围 <sec-scope>

本规范不包含参数化多态（泛型）、宏或用于容器复用的代码生成机制；不包含 `readonly` 修饰、可选字段、交叉类型、宽度子类型、控制流类型收窄或联合穷尽检查；也不包含类型位置的 `typeof`、成员键查询、索引访问类型、条件类型、映射类型或模板字面量类型等类型级运算。

连续内存视图（切片）、动态数组、字典和哈希表不作为语言内建类型，均由库通过具体类型及普通函数实现。

= 源文本与词法 <ch-lex>

== 字节、字符与行 <sec-source-bytes>

源码按原始字节读取和保留，不自动纠正或改写内容。文件开头允许 UTF-8 BOM；任何位置的实际 NUL 字节均为编译错误，包括字符串和注释内部。字符串中的两个源字符 `\0` 是合法转义，不是源文件中的实际 NUL 字节。

代码符号限 ASCII；字符串和注释允许 UTF-8。换行接受 LF 或 CRLF，代码空白处的单独 CR 为编译错误。字符串内不得直接出现 LF、CRLF 或单独 CR，也不得通过反斜杠接换行续写字符串。

== 标识符、保留字与数值词法 <sec-lex-tokens>

标识符区分大小写，其形式为 `[a-zA-Z_][a-zA-Z_0-9]*`。类型、类、变量、函数和语句标签均使用此形式；某个单词能否用作声明名还受保留字规则约束。

```ebnf
Identifier = LetterOrUnderscore, { LetterOrUnderscore | Digit };
Digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9";
HexDigit = Digit | "a" | "b" | "c" | "d" | "e" | "f"
                 | "A" | "B" | "C" | "D" | "E" | "F";
BinaryDigit = "0" | "1";
DecimalInteger = Digit, { Digit };
HexInteger = ("0x" | "0X"), HexDigit, { HexDigit };
BinaryInteger = ("0b" | "0B"), BinaryDigit, { BinaryDigit };
IntegerLiteral = DecimalInteger | HexInteger | BinaryInteger;
Exponent = ("e" | "E"), [ "+" | "-" ], DecimalInteger;
DecimalFloat = DecimalInteger, ".", DecimalInteger, [ Exponent ]
             | DecimalInteger, Exponent;
BooleanLiteral = "true" | "false";
NullLiteral = "null";
```

其中 `LetterOrUnderscore` 表示 ASCII 大小写字母（`a`–`z`、`A`–`Z`）或下划线 `_`。

整数支持十进制、十六进制和二进制写法。十六进制与二进制前缀分别为 `0x`／`0X` 和 `0b`／`0B`，前缀后必须至少有一个对应进制的数字；十六进制字母不区分大小写。无进制前缀的整数始终按十进制解释，前导零不表示八进制，例如 `010` 表示十。进制不决定位宽或有符号性：`255`、`0xFF` 和 `0b11111111` 表示同一数学整数值，字面量类型身份见 @sec-type-identity，上下文定型见 @sec-literal-typing，显式转换见 @sec-conversions。

浮点字面量支持十进制小数和十进制科学计数法。指数由 `e` 或 `E` 引入，可带 `+` 或 `-`，其后必须有十进制数字，例如 `1e6`、`1.5e-3`、`2E+4`。含小数点或指数的形式均为浮点字面量，即使其数学值恰为整数：`1e3` 依期望浮点类型定型，无期望类型时默认 `f64`，不按整数字面量 `1000` 处理（@sec-literal-typing）。

负号 `-` 作为一元运算符解析；直接作用于整数字面量（含 `-0x80` 等非十进制写法）时的取值与定型见 @sec-literal-typing。浮点指数内部的正负号属于指数词法的一部分，不作为独立的一元运算符。

十进制数字后的 `.` 仅在其后紧接十进制数字时作为小数点读入小数部分；因此 `300.to(u8)` 解析为整数字面量 `300` 后接后缀转换，`255.9.to(u8)` 解析为浮点字面量 `255.9` 后接后缀转换。非十进制整数与带指数的浮点字面量也可直接接后缀，例如 `0xFF.to(u8)` 和 `1e3.to(i32)`。

进制前缀或指数不完整，或出现对应进制不允许的数字（例如 `0x`、`0b102`、`1e+`），均为编译错误；实现不得通过拆成多个合法 token 接受这些写法。

```cy
u8 mask = 0xFF;
u8 pattern = 0b1010;
f64 scale = 1e6;
f32 step = 1.5e-3;
u8 wrapped = 0x1FF.to(u8); // 显式转换保留低 8 位，结果为 255
```

完整保留字如下。内建基础类型名也属于保留字，禁止同作用域重名声明；保留字不得作为普通标识符使用。

#matrix(
  table.header([*类别*], [*保留字*]),
  [声明与结构], [`typedef`、`class`、`extends`、`impl`、`func`、`module`、`import`、`export`、`from`、`super`],
  [控制流与异常], [`if`、`else`、`while`、`for`、`break`、`continue`、`return`、`try`、`catch`、`throw`],
  [运算与内建操作], [`not`、`and`、`or`、`as`、`to`、`typeof`、`print`],
  [字面量与特殊名], [`true`、`false`、`null`、`void`、`init`],
  [内建基础类型名], [`i8`、`i16`、`i32`、`i64`、`u8`、`u16`、`u32`、`u64`、`f32`、`f64`、`bool`、`string`],
)

逻辑非只使用关键字 `not`，不提供 `!` 运算符。浮点内建类型仅保留 `f32` 与 `f64`，不包含 `f8` 或 `f16`。

== 普通字符串字面量 <sec-lex-string>

普通字符串字面量由一对双引号包围：

```ebnf
StringLiteral = '"', { StringByte | EscapeSeq }, '"';
EscapeSeq = "\n" | "\r" | "\t" | "\0" | "\\" | '\"';
```

其中 `StringByte` 表示除双引号 `"`、反斜杠 `\`、直接换行（LF、CRLF 或单独 CR）和实际 NUL 字节之外的原始字节，按原值保留。允许的转义序列及其解码字节如下；未知转义、缺失结束引号、直接换行和反斜杠续行均为编译错误。

#matrix(
  table.header([*源代码转义*], [*解码后的字节*]),
  [`\n`], [`0A`，换行],
  [`\r`], [`0D`，回车],
  [`\t`], [`09`，水平制表符],
  [`\0`], [`00`，NUL],
  [`\\`], [`5C`，反斜杠],
  [`\"`], [`22`，双引号],
)

```cy
string message = "A\0B";  // 合法：解码后有三个字节
string bad = "\q";        // 错误：未知转义
```

相邻字符串字面量不自动拼接；`"a" "b"` 为编译错误。

== 空白与注释 <sec-lex-comments>

代码空白为 ASCII 空格、水平制表符以及 @sec-source-bytes 规定的 LF 或 CRLF 换行。行注释以 `//` 开始，持续到下一个合法换行或文件结束；文件末尾的行注释不要求以换行结束。块注释使用 `/* ... */`，可以跨行并允许嵌套。

```ebnf
Whitespace = " " | HT | Newline;
Newline = LF | CRLF;
LineComment = "//", { LineCommentByte };
BlockComment = "/*", { BlockComment | BlockCommentByte }, "*/";
```

`HT`、`LF` 和 `CRLF` 分别表示水平制表符、单个 LF 字节和连续的 CR、LF 两字节。`LineCommentByte` 表示既不是合法换行起始位置、也不是实际 NUL 的字节；换行本身不属于行注释。`BlockCommentByte` 表示既不是 `/*` 或 `*/` 起始位置、也不是实际 NUL 的字节。注释中的 UTF-8 内容与实际 NUL 禁令遵守 @sec-source-bytes。

进入块注释后，每遇到 `/*` 增加一层嵌套，每遇到 `*/` 关闭一层；最外层关闭后恢复普通词法分析。到达文件结束仍有未闭合层时为编译错误。块注释内的 `//`、引号和反斜杠均为普通注释内容，不开启行注释、字符串或转义；行注释内的块注释标记同样只是普通内容。

空白和注释分隔 token，不拼接两侧字符；例如 `ab/*说明*/cd` 解析为两个标识符，不是 `abcd`。普通字符串内部的 `//`、`/*` 和 `*/` 均为字符串内容，不开始或结束注释。

```cy
/* 暂时停用这段代码
    /* 原有说明 */
    do_work();
*/
i32 count /* 个数 */ = 1;
string markers = "// /* */"; // 字符串内容原样保留
```

= 类型、声明与值的基础 <ch-types>

== 类型构造与身份 <sec-type-identity>

类型系统支持内建基础类型、字面量类型、`typedef` 结构对象类型、显式指针、函数指针、定长数组和一般联合类型。类型别名声明写作 `typedef Name = TypeExpr;`，声明的名字是透明别名，不创建独立类型身份。`class` 是声明类的唯一关键字，每处类声明具有独立身份，不适用透明别名或结构同一性规则；`typedef` 结构对象与 `class` 对象分别遵守本章和#ref(<ch-classes>)的规则。

```ebnf
TypeDecl = "typedef", Identifier, "=", TypeExpr, ";";
TypeExpr = PrefixType, { "|", PrefixType };
PrefixType = "*", PointeeType
           | "[", ConstExpr, "]", PrefixType
           | TypeAtom;
PointeeType = PrefixType | ClassName;
TypeAtom = TypeName | LiteralType | "(", TypeExpr, ")"
         | ObjectType | FunctionPointerType;
LiteralType = [ "-" ], IntegerLiteral
            | StringLiteral
            | BooleanLiteral
            | NullLiteral;
TypeName = Identifier;
ClassName = Identifier;
DeclType = TypeExpr | ClassName;
```

`TypeName` 指解析为内建基础类型或 `typedef` 别名的标识符，`ClassName` 指解析为 `class` 的标识符。结构对象类型文字 `ObjectType` 见 @sec-struct-objects，可直接写在任意 `TypeExpr` 位置，无需先经 `typedef` 命名；函数指针类型 `FunctionPointerType` 见 @sec-func-decl。

`LiteralType` 表示单值字面量类型，可用于类型别名、结构对象字段和联合成员等任意 `TypeExpr` 位置，分为四类（浮点字面量不构成字面量类型）：

- *整数字面量类型*（`[ "-" ], IntegerLiteral`）：仅包含对应带符号数学整数值，不绑定机器整数位宽。数学值相同的写法对应同一类型，例如 `200` 与 `0xC8` 同一类型，`-0` 与 `0` 同一类型。
- *字符串字面量类型*（`StringLiteral`）：仅包含对应解码后字节序列的字符串值；解码后字节序列完全相同时为同一类型。
- *布尔字面量类型*（`BooleanLiteral`）：`true` 与 `false` 分别仅包含对应布尔值。`true`、`false` 与内建 `bool` 具有不同类型身份；联合归一化不将 `true | false` 改写为 `bool`，也不从 `true | bool` 中消去 `true`。
- *空值字面量类型*（`NullLiteral`）：`null` 仅包含空值 `null`，与无返回值标记 `void` 及各指针类型均具有不同身份。

*类不属于类型系统。*类名不是 `TypeName`，不能作为 `TypeAtom` 出现。`TypeExpr` 中仅两处允许出现类名：

- 指针的被指对象：`*Node` 是合法指针类型，可继续参与复合类型构造（如 `*Node | null`、`[4]*Node`）；
- 函数指针签名的参数与返回位置（如 `*func(Circle) -> f64`），仅描述调用签名而非将类对象纳入 `TypeExpr`。

因此，类对象不能作为联合成员、定长数组元素或 `typedef` 结构对象字段，类名也不能出现在 `typedef` 右侧；`Node | null`、`[4]Node` 均为编译错误。本章的透明别名、结构兼容与联合归一化，以及#ref(<ch-unions>)的 `typeof` 与 `.as()`，均不适用于类对象。类对象按值仅出现在 `DeclType` 允许的位置（变量、参数、返回值及 @sec-conversions 的子类到父类显式转换）；不同类即使字段完全相同或均无字段也不相容，类对象与 `typedef` 结构对象之间不相通、不可转换。

类指针与函数指针的类型身份分别判定如下：

- 两个类指针类型相同，当且仅当两个类名指向同一处 `class` 声明（@sec-module-imports 的跨模块导入保留原声明身份；不同模块各自声明的同名类即使字段相同，其类指针类型仍不同）。
- 两个函数指针类型相同，当且仅当按顺序排列的参数类型与返回类型完全相同；同一签名的函数指针可指向不同函数。

类型前缀 `*` 与 `[N]` 的结合优先级高于 `|`：`*T | null` 表示指针与 `null` 的联合，`[4]i32 | null` 表示整个数组与 `null` 的联合。数组长度 `N` 必须是编译期正整数常量；零、负数或运行期值均为编译错误。类型位置的括号 `(T)` 用于分组而不改变类型身份：`(i32) x = 1;` 等价于 `i32 x = 1;`，`*(i32 | f32)` 表示指向联合的指针；按 @sec-func-decl，`*func(i32) -> i32 | null` 的返回类型为 `i32 | null`，而 `(*func(i32) -> i32) | null` 则是函数指针与 `null` 的联合。

判定类型身份时，先完全展开各层透明别名（含复合类型内部引用的别名）：`typedef` 结构对象按 @sec-struct-objects 的字段集合判定同一性；联合类型将直接成员位置上的嵌套联合逐层展平，再按类型身份合并重复成员，归一化后成员集合相同的两个联合即为同一类型，与成员书写顺序无关。展平仅发生在联合的直接成员位置，例如当 `Number` 为 `i32 | f32` 时，`*Number | null` 的成员是 `*(i32 | f32)` 与 `null`。

```cy
typedef Count = i32;
typedef CountAgain = Count;
typedef Number = Count | CountAgain | f32;
typedef Value = Number | string;
typedef Same = string | f32 | i32;
// CountAgain 展开为 i32；Value 与 Same 是同一类型，仅有一层标签。

typedef Status = 200 | 404;
Status ok = 0xC8; // 0xC8 与 200 为同一整数字面量类型
```

== 基础类型与数值字面量定型 <sec-literal-typing>

内建整数类型为 `i8`、`i16`、`i32`、`i64`、`u8`、`u16`、`u32`、`u64`；内建浮点类型为 `f32`、`f64`。`bool` 与 `string` 是独立内建类型；`void` 仅作为函数无返回值标记，不与 `null` 混同。`bool` 占 1 个字节：写入时 `false` 编码为 `0x00`，`true` 编码为 `0x01`；联合跨成员读取 `bool` 的字节解释见 @sec-union-read。

数值字面量区分为*未定型数值字面量*与*已定型值*。已经定型的数值变量与表达式之间禁止隐式转换；未定型数值字面量的上下文定型不构成已定型值之间的隐式转换：

- *明确期望数值类型上下文：*在变量声明初始化、赋值、函数传参、`return` 以及另一侧已定型的同类型二元运算中，字面量在不超出目标数值类型表示范围时直接定型为该目标整数或浮点类型（浮点字面量仅依期望浮点类型定型，不直接定型为整数类型）；超出表示范围即为编译错误。
- *无期望类型的默认定型：*需要具体数值类型但上下文未提供期望类型时（如 `print 1;`、`print 1e3;`），整数字面量默认定型为 `i32`，浮点字面量默认定型为 `f64`。
- *联合期望类型上下文：*期望类型为联合时，数值字面量既不默认定型为 `i32` 或 `f64`，也不从联合成员反推目标数值类型（即使联合仅含唯一数值成员），而是按 @sec-union-construct 仅匹配字面量自身的类型。
- *同类型二元运算：*若两侧均为未定型数值字面量且外层给出期望数值类型，两侧均按该期望类型定型（如 `i64 y = 1 + 2;` 按 `i64` 运算）；若一侧已定型，另一侧字面量按该已定型操作数的类型定型（如 `x` 为 `i32` 时 `x + 2` 结果为 `i32`，直接赋给 `i64` 为编译错误）。

整数字面量在选定具体机器整数类型前保留其内建字面量类型与精确数学整数值，不受 `i32` 位宽限制；一元负号直接作用于整数字面量时先取带符号数学值，括号包裹亦保留该性质。显式转换 `expr.to(T)` 对已定型操作数按其静态源类型执行 @sec-conversions 的转换，外层期望类型不反推操作数源类型；直接以整数字面量（含带括号或前置一元 `-` 的整数字面量）向内建数值类型执行 `.to(T)` 时，直接对该精确整数值执行目标转换，不先默认定型为 `i32`。例如 `3000000000.to(i64)` 合法且结果为 `3000000000`，`300.to(u8)` 保留低 8 位得到 `44`，而直接声明 `u8 a = 300;` 因字面量定型越界产生编译错误。

字面量定型的范围检查仅在编译期执行。非联合上下文中给出具体数值类型时（如 `i64 n = 200;`），整数字面量定型为该数值类型；联合上下文中（如 `Status ok = 200;`）则保留字面量类型 `200` 直接构造联合。

```cy
i8 small = 127;       // 字面量直接定型为 i8
i8 minimum = -128;    // 合法：-128 是 i8 的最小值
i8 overflow = 128;    // 错误：超出 i8 表示范围
i8 below = -129;      // 错误：低于 i8 的最小值
i16 wide = small;     // 错误：已定型 i8 值不能隐式转换为 i16
f32 ratio = 1.0;      // 字面量直接定型为 f32
print 1;              // 无期望类型：默认 i32
print 1.0;            // 无期望类型：默认 f64
```

== 编译期常量表达式 <sec-constexpr>

```ebnf
ConstExpr = Expr;
```

语法上 `ConstExpr` 采用一般表达式 `Expr` 的形式，但仅允许由字面量、模块级变量的编译期初值、内建算术／位／逻辑／比较运算、显式类型转换（@sec-conversions）以及定长数组的 `.len` 构成。数组字面量的所有元素或 `typedef` 结构对象字面量的所有字段初始化式均为 `ConstExpr` 时，整个复合字面量（递归包含嵌套字面量）属于 `ConstExpr`；重复填充 `[val; N]` 的 `val` 和 `N` 均须为 `ConstExpr`，并满足常规类型、字段和长度约束。

模块级变量均须以 `ConstExpr` 初始化（@sec-module-init），在要求 `ConstExpr` 的位置引用模块级变量时取其声明的编译期初值；模块级变量之间的 `ConstExpr` 初值依赖不得成环。语言不设常量声明关键字，模块级变量在运行期仍可变；普通运行期表达式读取可变变量时始终取得运行期当前值，不得以声明初值替代，也不得据该初值触发编译期常量诊断。

`ConstExpr` 不得包含函数调用、指针解引用、变量赋值或运行期内存读取。定长数组 `.len` 是编译期属性，不读取数组运行期存储。常量求值遵守#ref(<ch-expr>)规定的优先级、结合性、短路求值及常量越界／除零编译错误规则。

== `typedef` 结构对象 <sec-struct-objects>

`typedef` 结构对象类型在完全展开透明别名并归一化联合类型后，当且仅当字段集合（每个字段的名称与对应静态类型）完全相同时具有同一类型身份，与源码中的字段声明顺序、所在文件或所属模块无关。相同结构类型的对象值可直接互相赋值或传参，不进行宽度子类型转换。

```ebnf
ObjectType = "{", ObjectField, { ",", ObjectField }, [ "," ], "}";
ObjectField = Identifier, ":", TypeExpr;
```

`typedef` 结构对象类型必须至少包含一个字段，不支持空结构（此限制不适用于 `class`，无字段类见 @sec-class-decl）。字段以逗号分隔，允许末尾逗号；同一结构内字段不得重名。字段类型使用 `TypeExpr`，可包含嵌套结构、联合、定长数组和指针，不能直接包含类对象。

`typedef` 结构对象可通过字段直接或间接引用自身，前提是每条回到自身的字段路径都经过显式指针（例如 `Node` 的 `next` 字段为 `*Node | null`）。递归结构逐层按字段集合判定结构同一性，别名在每一层保持透明。不经过结构构造的纯 `typedef` 别名环，以及未经过显式指针而按值包含自身的字段环，均为编译错误。

`typedef` 结构对象采用规范化内存布局：字段先按对齐字节数从大到小排列，对齐要求相同的字段再按字段名 ASCII 字典序排列，编译器依此顺序执行目标平台所需的对齐与填充。结构完全相同的 `typedef` 结构对象具有一致的字段偏移、尺寸、对齐和内存布局。此规则不替代 @sec-class-layout 的 `class` 分层布局。

`typedef` 结构对象使用不带类型名前缀的对象字面量初始化或赋值（`class` 实例的对象字面量构造受 @sec-class-init 限制）：

```ebnf
ObjectLiteral = "{", [ FieldInit, { ",", FieldInit }, [ "," ] ], "}";
FieldInit = Identifier, ":", Expr;
```

对象字面量的字段集合必须与目标结构类型完全一致，不得遗漏、多出或重复字段；空字面量 `{}` 仅用于 @sec-class-init 规定的无字段类显式构造，不能构造 `typedef` 结构对象。目标字段类型为对应初始化表达式提供期望类型，适用 @sec-literal-typing 的字面量定型与 @sec-union-construct 的联合构造规则。各字段初始化式严格按字面量中的源码书写顺序从左到右求值，不受规范化内存布局影响。

```cy
typedef Node = { value: i64, next: *Node | null };
Node node = { next: null, value: 1 }; // 字段书写顺序不影响匹配，1 按 i64 定型
typedef Empty = {};                   // 错误：typedef 结构对象至少需要一个字段
```

== 名字、作用域与声明 <sec-names-scopes>

Cyly 区分以下三类独立名字空间：

- *普通声明名字空间：*类型别名（`typedef`）、类（`class`）、变量、普通函数（`func`）以及源文件导入绑定（`import`）共用同一名字空间。保留字（含内建基础类型名）不得用作声明名或导入别名。
- *类成员名字空间：*每个类的字段与方法共用该类的成员名字空间（@sec-class-decl）；关联初始化函数固定使用保留字 `init`。
- *语句标签名字空间：*具名控制结构的标签独立于上述名字空间，仅在 `break` 与 `continue` 后按标签解析（@sec-labeled-stmt）。

普通声明名字空间内，各级作用域与可见范围规定如下：

- *模块级与导入作用域：*同一模块全部源文件的模块级声明共享同一模块级作用域，按全模块统一收集与解析，不受文件划分或源码书写顺序限制；同模块内重复声明为编译错误（@sec-module-imports、@sec-module-init）。`import` 引入的名字仅在当前源文件内可见；同一源文件内的导入绑定之间不得重名，也不得与所属模块的模块级声明重名。
- *参数与 `catch` 作用域：*函数参数（含类方法、外部 `impl` 的显式接收者及 `init` 参数）与对应函数体最外层块共用作用域，从函数体起始处可见；参数之间不得重名，函数体最外层也不得声明与参数同名的变量或 `typedef`。`catch (T id)` 的接收变量与该 `catch` 块最外层共用作用域，从该块起始处可见，不延伸至 `try` 块或 `catch` 之后。函数体或 `catch` 块内显式嵌套的子块可遮蔽外层名字。
- *块级与 `for` 局部作用域：*同一块直接包含的局部声明不得重名，内层块声明可遮蔽外层同名类型、类、变量、函数或导入名，名字按当前位置最近的可见绑定解析。局部声明不提升到块首，不得先用后定义：
  - 局部变量的初始化式按声明前已有的可见绑定解析（若存在同名外层声明则引用该外层绑定，若不存在则为编译错误）；求值完成初始化后，新变量绑定在当前块的剩余部分及其内层块中可见。`for` 初始化中声明的变量按相同规则解析初值，并在该 `for` 的条件、步进和主体中可见（@sec-for）。
  - 块内 `typedef` 从声明处起在当前块的剩余部分及其内层块中可见，离开该块即失效；声明前按外层已有绑定解析。局部 `typedef` 仍是纯编译期透明别名，不创建独立类型身份，不产生运行期代码，也不改变所指类型或值的寿命。

```ebnf
VariableDecl = DeclType, Identifier, "=", Expr, ";";
```

变量采用 C 式显式类型声明，不提供 `var` 关键字，不进行变量类型推断。局部变量和模块级变量均必须在声明处显式给出初始化式；语言不生成默认零值，也不自动调用 `init`。模块级变量的初始化式须为 `ConstExpr`（@sec-module-init）。

```cy
i32 count = 4;
{
    i32 count = count + 1; // 初始化式读取外层 count，内层初值为 5
    print count;           // 5：声明后使用内层变量
}
print count;               // 4：离开内层块后恢复外层变量
i32 absent = absent + 1;   // 错误：没有可见的外层 absent
i32 missing;               // 错误：变量声明缺少初始化式
```

```cy
func example() -> void {
    typedef Number = i32 | f32;
    Number value = 3.to(i32);
    print value.as(i32);
    {
        typedef Number = i64; // 合法：遮蔽外层别名
        Number n = 5;
        print n;
        typedef Count = i32;
        Count count = 1;
    }
    Number another = 4.to(i32); // 使用外层的 i32 | f32 别名
    Count count = 2;            // 错误：Count 在此处不可见
}
```

== 值、存储位置与布局 <sec-places-values>

表达式结果区分为*存储位置*（具有内存存储承载的位置）与*右值*（不传递存储承载的纯值）：

- *存储位置*严格由以下四类表达式产生，且均为*可写存储位置*：
  - 变量标识符 `id`（含模块级变量、局部变量、函数参数与 `catch` 接收变量；普通函数名与类名不是存储位置）；
  - 数据指针或类指针解引用 `expr.*`（无论 `expr` 是否带括号）；
  - 指针下标 `ptr_expr[i]`（无论 `ptr_expr` 是否带括号）；
  - 以存储位置为基底的定长数组下标 `place[i]`，以及 `typedef` 结构对象或 `class` 对象的可访问字段访问 `place.field`。
- *右值*包括字面量、括号表达式 `(expr)`、算术／位／逻辑／比较／赋值表达式的结果、函数与方法调用、类构造表达式、字符串字节读取 `s[i]`、联合读取 `.as(T)`、显式转换 `.to(T)`、长度属性 `.len`，以及以右值为基底的数组下标和字段访问。右值不能作为赋值目标（@sec-assignment）、取地址操作数（@sec-pointers）或 `typeof` 查询参数（@sec-typeof）。

赋值、初始化、按值传参与返回均复制值本身；含指针或 `string` 视图的复合值仅复制指针地址或视图结构，不复制所指数据，也不延长其寿命。`typedef` 结构对象采用 @sec-struct-objects 的规范化字段布局；`class` 对象仅由字段构成，不含隐式 vptr、对象头或生命周期元数据，采用 @sec-class-layout 的分层规范化布局。

= 联合类型与显式类型读取 <ch-unions>

== 类型与布局 <sec-union-layout>

可空类型写作 `T | null`。联合值采用内联布局，由当前成员类型标签与按最大成员对齐的存储槽组成；标签与归一化成员类型的对应关系在编译期确定，存储槽容量足以容纳任一成员，不进行隐式堆装箱。

数据指针、类指针和函数指针均可作为按值存储的联合成员。例如，当 `Handler` 为 `*func(i32) -> i32` 的透明别名时，`*Node | Handler | null` 可存放类指针、匹配签名的函数指针或 `null`，写入指针仅复制地址。类对象与普通函数本身均不能作为联合成员。

控制流不触发类型收窄：经 `typeof` 测试后，原表达式的静态类型仍为原联合类型。展开后字段结构完全相同的两个 `typedef` 结构对象别名具有同一类型身份，不能通过 `typeof` 区分；需区分对象种类时，应使用含不同字面量类型字段的结构（如 `kind: "user"` 与 `kind: "order"`）。

== 当前成员查询 <sec-typeof>

`typeof(place)` 的参数必须是存储位置（@sec-places-values），并按 `place` 的静态类型决定测试所用的类型：

- 静态类型为联合时，读取该存储位置的运行期标签，取得归一化后的当前成员类型；
- 静态类型为指针（含数据指针、类指针、函数指针）时，直接取其编译期静态指针类型，无需解引用指针或检查所指函数，但位置表达式本身仍按 @sec-eval-order 求值。

其他静态类型的存储位置（含类对象）、任何右值及类型名作为 `typeof` 参数均为编译错误。语言不存在一等类型值，`typeof` 仅允许出现在以下两种结果为 `bool` 的相等性测试中：

- `typeof(place) == T` 或 `typeof(place) != T`：右侧 `T` 按 `PrefixType` 解析。`place` 为联合时，`T` 必须是该联合归一化后的成员类型之一；`place` 为指针时，`T` 必须与其静态指针类型相同；否则为编译错误。
- `typeof(a) == typeof(b)` 或 `typeof(a) != typeof(b)`：两侧分别按上述规则取得类型后比较类型身份；允许两侧为不同联合、一侧联合一侧指针，或两侧均为指针。

```cy
typedef Number = i32 | f32;
Number value = 1.to(i32);
if (typeof(value) == i32) {
    print value.as(i32);
}
// p 是 *Node，next 是 *Node | null，f 与 g 是同一签名的函数指针。
if (typeof(next) == null) { }           // 查询联合当前成员是否为 null
if (typeof(next) == typeof(p)) { }      // 等价于 typeof(next) == *Node
if (typeof(f) == typeof(g)) { }         // 为真，即使指向不同函数
typeof(p) == null;           // 错误：p 的静态指针类型是 *Node
typeof(p.*) == *Node;        // 错误：p.* 是类对象
typeof(i32) == i32;          // 错误：i32 是类型名
typeof(1) == i32;            // 错误：参数不是存储位置
typeof(find()) == null;      // 错误：函数调用结果是右值，须先存入变量
i32 current = typeof(value); // 错误：typeof 仅允许出现在成员测试中
```

指针类型在编译期确定，无需附加运行期标签；跨联合比较按各自标签对应的成员类型身份判定。独立编译产物之间传递联合值的标签兼容要求见 @sec-abi。

== 显式读取与写入清零 <sec-union-read>

`expr.as(TypeExpr)` 是后缀运算，其目标类型必须是该联合归一化后的成员类型之一（包括整数、字符串、布尔等字面量类型成员），否则为编译错误；尺寸相同或更宽的非成员类型同样不得作为目标。`.as()` 按目标类型直接解释联合存储字节并产生该目标类型的右值，不执行运行期成员匹配检查，也不作为写入联合存储的左值入口（@sec-field-as 中的继承字段 `field as T;` 复用同一关键字声明编译期访问约束，不改变此处的跨成员读取语义）。

语言允许读取非当前成员类型（含非当前成员的字面量类型），成员不匹配本身不构成未定义行为。`.as()` 不进行数值转换，不改写底层存储字节或当前成员标签，其操作数正常按表达式规则求值。

编译器不得仅凭读取目标的类型或值域假设当前成员与目标匹配，也不得据此删除代码或改写结果；目标为单值字面量类型时，不得仅因该类型只含单一值就将读取直接替换为对应常量。仅当基于已知写入值、数据流及适用的存储表示能够严格证明结果等价时，才允许执行常量折叠，且必须保留操作数求值的可观察行为。

```cy
200 | i32 value = 1.to(i32);
value.as(200); // 合法：200 是联合成员，当前成员为 i32 不影响读取合法性
value.as(404); // 错误：404 不是联合成员
```

每次向联合存储槽写入成员值（含构造与赋值），实现必须写入当前成员字节、更新成员标签，并将存储槽内超出该成员字节尺寸的尾部剩余字节全部清零为 `0x00`。因此，后续以较大成员类型跨成员读取时，原较小成员未覆盖的槽尾字节具有确定零值。

当读取目标为 `bool` 时，`.as(bool)` 读取存储槽起始处的 1 个字节：`0x00` 产生 `false`，任意非零字节产生 `true`，不要求该字节原本为标准布尔编码，也不改写原存储或标签。对应 LLVM 语义必须等价于 `load i8` 后接 `icmp ne i8 ..., 0`，不得以 `load i1` 或截断最低位替代。

```cy
typedef Number = i32 | f32;
f32 original = 1.0;
Number value = original;
f32 same = value.as(f32);
i32 bits = value.as(i32);      // 跨成员解释存储字节，非数值转换
string bad = value.as(string); // 错误：string 不是成员类型
u32 raw = value.as(u32);       // 错误：u32 与 i32 同尺寸，但不是成员类型
```

```cy
u8 | bool value = 2.to(u8);
bool flag = value.as(bool); // true：非零字节判为真
if (flag) { print 123; }    // 执行
print value.as(u8);         // 仍为 2，读取未改写存储
value = flag;               // 写入 bool 成员，编码为 0x01
print value.as(u8);         // 1
```

联合类型不提供共同字段直访：即使所有成员对象均含字段 `id`，也必须先显式读取具体成员，再访问字段（如 `value.as(Node).id`）。

== 联合构造赋值 <sec-union-construct>

将属于联合类型 `U` 归一化成员类型的值直接用于期望类型为 `U` 的位置（声明初始化、赋值、函数传参、`return`、复合字面量元素初始化及 `catch` 联合捕获），属于合法的联合构造，不视为隐式类型转换。构造时复制成员值、写入对应成员标签，并执行 @sec-union-read 的槽尾清零。

联合构造严格按类型身份匹配成员：

- 直接使用整数、字符串或布尔字面量时，仅匹配该字面量自身的字面量类型；若联合不含该字面量类型成员则为编译错误，不会回退定型为 `i32`、`f64`、`string` 或 `bool`。浮点字面量不构成字面量类型，在联合位置也不默认定型为 `f64`。括号包裹以及直接作用于整数字面量的一元负号 `-` 不绕过上述字面量匹配规则。
- 要构造联合中的内建数值、`string` 或 `bool` 成员，数值字面量须按 @sec-literal-typing 显式写出 `.to(T)` 或先存入已定型变量，字符串与布尔字面量须先通过明确的基础类型声明得到已定型值后再传入。
- 已定型的数值、`string` 和 `bool` 值仅按其静态类型匹配成员，不因运行期值或编译期常量值恰与某字面量成员相等而改选字面量成员。

```cy
200 | i32 x = 200;
print typeof(x) == 200; // true
x = 200.to(i32);
print typeof(x) == i32; // true
```

```cy
i32 | i64 a = 1.to(i32);          // 合法：显式转为 i32 后构造联合
i32 | i64 implicit = 1;           // 错误：无字面量类型 1 成员
i64 | null b = 1;                 // 错误：不自动定型为唯一数值成员
i32 | i64 c = 3000000000;         // 错误：无该整数字面量类型成员
i8 | u8 d = 1;                    // 错误：不按数值范围选择成员
i64 | null e = 1.to(i64);         // 合法：显式选择 i64
i32 | i64 f = 3000000000.to(i64); // 合法：按精确整数值直接转换
f64 | null g = 1.0;               // 错误：浮点字面量不默认定型为 f64
f32 | null h = 1.0.to(f32);       // 合法：显式选择 f32
i32 value = 1;
i32 | i64 copy = value;           // 合法：已具有静态类型 i32
```

```cy
"ok" | string result = "ok";
print typeof(result) == "ok";   // true：匹配字符串字面量类型
string text = "ok";
result = text;
print typeof(result) == string; // true：按静态类型 string 匹配
result = "other";               // 错误：无 "other" 字面量成员
string other = "other";
result = other;                 // 合法：传入已定型的 string 值
"ok" | null exact = text;       // 错误：string 不是该联合的成员
```

```cy
true | bool state = true;
print typeof(state) == true; // true：匹配布尔字面量类型
bool flag = true;
state = flag;
print typeof(state) == bool; // true：按静态类型 bool 匹配
state = false;               // 错误：无 false 字面量成员
bool disabled = false;
state = disabled;            // 合法：传入已定型的 bool 值
typedef Result = { ok: true, value: i32 } | { ok: false, error: string };
```

= 指针、定长数组与连续内存 <ch-pointers-arrays>

== 指针与取地址 <sec-pointers>

指针类型写作 `*T`。指针的赋值、传参与返回仅复制地址，不复制所指数据，也不延长其寿命。

一元前缀 `&` 仅允许以下三种形式，其余操作数（如字面量、括号右值 `&(a)`、函数调用结果、字符串字节 `s[i]` 等右值）均为编译错误：

- `&place`：取得存储位置 `place`（@sec-places-values）的内存地址，静态类型为 `*T`（`T` 为该位置的静态类型或类名；对声明了 `as` 约束的继承字段取地址得到指向原始字段类型的指针，见 @sec-field-as）。
- `&func_name`：取得模块级普通函数的函数指针（@sec-func-decl）。
- `&ClassName.method`：取得当前位置可访问的类方法的函数指针（@sec-dispatch-super）。

后缀 `p.*` 对数据指针或类指针解引用；经指针访问成员须写作 `p.*.field`，语言不提供 `->` 成员访问运算符（函数签名中的 `->` 仅作返回类型标点）。`p[i]` 表示按所指元素类型进行地址偏移并访问该元素，不插入运行期边界检查；指向定长数组的指针须先解引用再取下标，即 `p_arr.*[i]`。

静态类型完全相同的两个指针（含数据指针、类指针、函数指针）可用 `==` 和 `!=` 比较地址，结果为 `bool`；静态类型不同的指针直接比较为编译错误，须先按 @sec-conversions 显式转换至同一指针类型。

== 定长数组 <sec-arrays>

`[N]T` 是包含 `N` 个 `T` 元素的定长数组，采用纯值语义：赋值、按值传参与返回均复制整块数组，数组不会隐式退化为指针。`arr.len` 返回元素个数，静态类型为 `i64`；元素通过 `arr[i]` 读写。

```ebnf
ArrayLiteral = "[", Expr, { ",", Expr }, "]"
             | "[", Expr, ";", ConstExpr, "]";
```

枚举形式 `[e1, e2, ...]` 与重复填充形式 `[val; N]` 均为显式数组初始化。枚举元素个数及重复填充的 `N` 必须严格等于目标定长数组的声明长度，不自动补零或截断；每个元素须符合目标元素类型。重复填充中的 `val` 仅求值一次，随后将所得值按值语义复制 `N` 份填入各槽位。`&arr` 的类型为 `*[N]T`；获取首元素指针须显式写作 `&arr[0]`，类型为 `*T`。

```cy
[3]i32 a = [10, 20, 30];
[3]i32 b = a;
b[0] = 99;             // 不改变 a[0]
*[3]i32 whole = &a;
whole.*[1] = 40;
*i32 first = &a[0];
first[2] = 50;
print a.len;
```

== 边界与内存责任 <sec-bounds-memory>

定长数组、字符串和裸指针的下标接受任意内建整数类型（不强制使用与 `.len` 相同的 `i64`），未定型整数字面量按 @sec-literal-typing 定型；浮点、布尔、指针或其他类型作下标均为编译错误。

定长数组和内建字符串的下标若为编译期常量且越界（合法范围 `0 <= i < len`），必须报编译错误；编译期越界判定直接使用下标类型表示的精确整数值，不得先截断窄化而将越界值误判为合法索引。运行期的数组、字符串与裸指针下标均只作地址偏移计算，不插入越界检查。

```cy
[2]i32 a = [1, 2];
print a[2];           // 错误：编译期常量下标越界
i32 index = 1;
print a[index];       // 运行期索引：由程序保证在有效边界内
```

程序须自行保证内存访问所需的对象寿命、索引边界、对齐与指针有效性；语言不提供借用检查、生命周期追踪或 `unsafe` 标记。编译器不得采用基于类型的严格别名假设（Strict Aliasing / TBAA）：允许通过指针转换或联合跨成员读取按不同类型读取同一有效存储。数组切片与动态数组边界见 @sec-scope，`string` 视图规则见#ref(<ch-strings>)。

= 字符串与内建容器边界 <ch-strings>

== 字符串值 <sec-string-value>

`string` 是由地址与字节长度构成的只读字节序列视图；长度不依赖终止符，内容允许包含 `0x00`（NUL）字节并计入长度。通过 `string` 不能写入字节；该只读约束仅限于经此视图的访问，不约束指向同一底层存储的其他可写指针别名，也不赋予视图内存所有权。复制 `string` 值仅复制地址与长度构成的视图，不复制底层字节，也不延长所指数据的寿命。

语言将字符串内容视为原始字节序列，不解释字符编码；UTF-8 校验、解码、码点计数与字素切分均由库负责。`s.len` 返回字节长度，静态类型为 `i64`；`s[i]` 读取第 `i` 个字节并产生 `u8` 右值，其下标类型与常量越界检查遵守 @sec-bounds-memory。

== 比较与字面量存储 <sec-string-compare>

字符串的 `==` 和 `!=` 比较字节长度与逐字节内容，不比较存储地址；实现的字面量驻留或其他优化不得改变比较结果。语言不提供 `<` 等字符串大小比较运算符、拼接运算符、隐式字符串转换或相邻字面量拼接；排序与拼接由普通函数完成。

同一次链接产物（单个可执行文件或单个动态库）内部，解码后字节内容完全相同的字符串字面量必须共用同一存储地址；跨动态库边界不保证地址相同，运行时不维护全局驻留表。

```cy
string left = "A\0B";
string right = "A\0C";
bool same = left == right; // false：NUL 之后的字节同样参与比较
string bad = left + right; // 错误：不提供字符串拼接运算符
```

语言不内建字符串哈希运算，也不内建字典或哈希表类型（@sec-scope）。

= 表达式与运算 <ch-expr>

== 求值顺序与优先级 <sec-eval-order>

表达式各子项严格从左到右求值；赋值表达式先求左侧目标存储位置，再求右侧值并写入。`and` 与 `or` 采用从左到右短路求值：前者左操作数为 `false` 时不求右操作数，后者左操作数为 `true` 时不求右操作数。运算符优先级与结合性仅决定语法树分组，不改变从左到右的求值顺序。

按值传递的函数实参在各自求值时即完成取值：例如在 `f(value, mutate(&value))` 中，第二个实参对 `value` 原存储的修改不会改变第一个实参已取得的值（若该值内部含指针或 `string` 视图，其所指外部数据仍遵循 @sec-places-values 的浅复制规则）。

#block(breakable: false)[#matrix(
  table.header([*从高到低*], [*运算类别*]),
  [1], [后缀：成员 `.`、下标 `[]`、调用 `()`、解引用 `.*`、联合读取 `.as(T)`、类型转换 `.to(T)`；左结合链式组合],
  [2], [一元前缀：`not`、`~`、`+`、`-`、`&`（取地址／取函数指针）],
  [3], [乘、除、取模：`*`、`/`、`%`；左结合],
  [4], [加、减：`+`、`-`；左结合],
  [5], [按位移位：`<<`、`>>`；左结合],
  [6], [大小比较：`<`、`<=`、`>`、`>=`],
  [7], [相等比较：`==`、`!=`；`typeof` 成员测试],
  [8], [按位与：`&`；左结合],
  [9], [按位异或：`^`；左结合],
  [10], [按位或：`|`；左结合],
  [11], [逻辑与：`and`；左结合，短路求值],
  [12], [逻辑或：`or`；左结合，短路求值],
  [13], [赋值：`=`；右结合],
)]

所有后缀运算同属最高优先级并从左到右链式结合：例如 `ptr.as(*Node).*.id` 依次读取指针成员、解引用、访问字段；`value.as(i32).to(i64)` 先读取联合成员再执行数值转换。后缀优先级高于一元前缀，因此转换负值须写 `(-x).to(i64)`，转换取地址结果须写 `(&child).to(*Parent)`。一元 `&` 为取地址／取函数指针，二元 `&` 为按位与；类型表达式中的 `|` 由 @sec-type-identity 的类型文法解释，不受表达式优先级表支配。

== 核心表达式文法 <sec-expr-grammar>

```ebnf
Expr = Assignment;
Assignment = LogicalOr, [ "=", Assignment ];
LogicalOr = LogicalAnd, { "or", LogicalAnd };
LogicalAnd = BitwiseOr, { "and", BitwiseOr };
BitwiseOr = BitwiseXor, { "|", BitwiseXor };
BitwiseXor = BitwiseAnd, { "^", BitwiseAnd };
BitwiseAnd = Equality, { "&", Equality };
Equality = Relational, { ("==" | "!="), Relational }
         | TypeofTest;
TypeofTest = TypeofExpr, ("==" | "!="), (PrefixType | TypeofExpr);
TypeofExpr = "typeof", "(", Expr, ")";
Relational = Shift, { ("<" | "<=" | ">" | ">="), Shift };
Shift = Additive, { ("<<" | ">>"), Additive };
Additive = Multiplicative, { ("+" | "-"), Multiplicative };
Multiplicative = Unary, { ("*" | "/" | "%"), Unary };
Unary = ("not" | "~" | "+" | "-" | "&"), Unary | Postfix;
Postfix = Primary, { Suffix };
Suffix = ".", Identifier | ".*"
       | ".as", "(", TypeExpr, ")"
       | ".to", "(", DeclType, ")"
       | "[", Expr, "]" | "(", [ Arguments ], ")";
Arguments = Expr, { ",", Expr };
Primary = Identifier | Literal | ArrayLiteral | ObjectLiteral
        | ClassInitExpr | SuperCallExpr | SuperInitExpr
        | "(", Expr, ")";
Literal = IntegerLiteral | DecimalFloat | StringLiteral
        | BooleanLiteral | NullLiteral;
```

上述文法编码了 @sec-eval-order 的优先级与结合性。`.as`、`.to` 和 `.*` 描述后缀语法结构，具体 token 切分方式由词法器实现决定。`.to(...)` 括号内按 `DeclType` 解析目标，合法转换范围见 @sec-conversions；`ClassInitExpr`、`SuperCallExpr` 和 `SuperInitExpr` 见#ref(<ch-classes>)。

== 运算与转换约束 <sec-ops>

语言不为自定义类型提供运算符重载，自定义运算统一通过普通函数或方法表达。除结构完全相同的 `typedef` 结构对象兼容（@sec-struct-objects）与联合构造（@sec-union-construct）外，已定型值之间不进行隐式类型转换；子类对象转为父类对象也须显式调用 `.to()`。

下表汇总内建基础运算的类型约束；其中“数值类型”指 8 种内建整数类型及 `f32`、`f64`，同类型要求同时匹配位宽与有符号性。未定型数值字面量先按 @sec-literal-typing 定型，已定型小整数不发生隐式整数提升。后缀解引用、下标、取地址 `&` 与成员调用规则分别见#ref(<ch-pointers-arrays>)、#ref(<ch-functions>)与#ref(<ch-classes>)。

#matrix(
  table.header([*运算*], [*操作数与结果类型*]),
  [二元 `+`、`-`、`*`、`/`、`%`], [两侧为同一数值类型 `T`，结果为 `T`；浮点 `%` 采用 @sec-float-ops 的取余语义。],
  [一元 `+`、`-`], [操作数为数值类型 `T`，结果为 `T`；无符号整数同样适用。],
  [`&`、`|`、`^`；一元 `~`], [二元操作数为同一整数类型 `T`，一元操作数为整数类型 `T`，结果均为 `T`。],
  [`<<`、`>>`], [两侧均为整数类型（允许不同），结果保持左操作数类型（@sec-shifts）。],
  [`<`、`<=`、`>`、`>=`], [两侧为同一数值类型，结果为 `bool`。],
  [`==`、`!=`], [两侧为同一数值类型、`bool`、`string` 或同一静态指针类型，结果为 `bool`；字符串按字节内容比较，指针按地址比较。],
  [`not`；`and`、`or`], [操作数均为 `bool`，结果为 `bool`；`and`、`or` 短路求值。],
)

一元 `+` 保留原数值；已定型整数类型 `T` 的一元 `-` 按 `T` 位宽下的 `0 - x` 计算，运行期二进制补码回绕。直接作用于整数字面量的一元 `-` 先确定带符号数学值再执行 @sec-literal-typing 的定型范围检查；编译期常量算术溢出按 @sec-int-div 报编译错误。

```cy
u8 x = 1;
u8 inverse = -x;    // 运行期无符号取负回绕，结果为 255
u8 invalid = -1;    // 错误：字面量 -1 超出 u8 表示范围
i8 small = 2;
i8 sum = small + 1; // 按 i8 运算，不提升为 i32
```

=== 显式类型转换 <sec-conversions>

显式类型转换仅使用后缀语法 `expr.to(DeclType)`。`to` 是保留字，`.to` 是内建运算，不能由方法或外部 `impl` 定义。操作数只求值一次，转换结果为右值（可继续链式接其他后缀，但不可赋值或取地址）。仅允许以下三类转换，其余目标（如联合构造、联合 `.as()` 读取、字符串转换、无关类转换）均为编译错误：

- *数值转换：*任意内建整数类型与浮点类型之间，以及数值字面量到这些数值类型（如 `x.to(i64)`、`y.to(f32)`、`3000000000.to(i64)`）。
- *指针与地址转换：*任意指针类型之间，或任意指针类型与内建整数类型之间（如 `ptr.to(*i32)`、`(&child).to(*Parent)`）；转换不复制所指数据，也不延长其寿命。
- *子类到父类对象转换：*子类 `Child` 的实例可显式按值转换为父类 `Parent` 的实例，写作 `child.to(Parent)`（这是 `ClassName` 作为 `.to()` 目标的唯一合法情形）。转换直接复制 `child` 起始处前 `sizeof(Parent)` 字节的父类内存前缀；对应指针转换 `(&child).to(*Parent)` 零成本复用原地址（@sec-class-layout）。

```cy
i64 wide = small.to(i64);
f32 ratio = wide.to(f32);
*i32 word = raw.to(*i32);
*Parent parent_ptr = (&child).to(*Parent);
Parent parent_value = child.to(Parent);
```

*整数之间的显式转换：*先依据源类型与目标类型的位宽处理位模式，再按目标类型的有符号性解释结果：

- 目标位宽更小：保留目标位宽的低位并丢弃高位，对应 LLVM `trunc`；
- 目标位宽更大且源类型有符号：按源值符号位扩展，对应 `sext`（与目标类型是否有符号无关）；
- 目标位宽更大且源类型无符号：高位补零扩展，对应 `zext`（与目标类型是否有符号无关）；
- 位宽相同：位模式不变，按目标类型解释（转为自身类型保留原值）。

上述规则统一适用于编译期常量求值与运行期求值，不插入范围检查，源值超出目标类型数值范围不构成编译错误；对应 LLVM 指令默认不附加 `nsw`、`nuw` 或 `nneg`。直接以整数字面量作为转换操作数时（@sec-literal-typing），对位宽为 `N` 的目标整数类型取该精确整数值模 `2^N` 的非负余数作为 `N` 位位模式，再按目标有符号性解释；转为浮点类型时直接对该精确整数值执行下述浮点舍入。

```cy
i64 large = 3000000000.to(i64); // 合法：字面量不先受 i32 范围限制
u8 a = 300.to(u8);              // 保留低 8 位，结果为 44
i8 b = 255.to(i8);              // 低 8 位全 1，按 i8 解释为 -1
i8 negative = -1;
u16 c = negative.to(u16);       // 源类型有符号，符号扩展后为 65535
u8 byte = 255;
i16 d = byte.to(i16);           // 源类型无符号，补零扩展后为 255
```

*浮点相关的显式转换：*采用 LLVM 默认浮点环境，不附加 fast-math 标志，也不插入运行期范围检查：

- `f32` 转 `f64`：生成 `fpext`，有限数值精确扩宽；
- `f64` 转 `f32`：生成 `fptrunc`，按最近可表示值、居中取偶规则舍入，溢出产生对应符号的无穷；
- 整数转浮点：按源整数有符号性生成 `sitofp` 或 `uitofp`，不能精确表示时按最近值、居中取偶舍入；
- 浮点转整数：按目标整数有符号性生成 `fptosi` 或 `fptoui`，向零截断小数部分；截断结果超出目标整数表示范围，或输入为 `NaN`、正负无穷时，结果为 LLVM `poison`（不采用低位截断规则）。

浮点转为自身类型保留原值；浮点间转换按 LLVM 规则保留零的符号、无穷及 `NaN` 传播语义。编译期常量折叠遵循同一转换语义，操作数自身的字面量定型仍须满足 @sec-literal-typing。

```cy
f32 rounded = 16777217.to(f32);      // 整数字面量转 f32，得 16777216.0
f32 narrow = 16777217.0.to(f32);     // f64 转 f32，同样得 16777216.0
f64 wide_float = narrow.to(f64);     // 有限数值精确扩宽
i32 positive = 3.9.to(i32);          // 3
i32 negative_float = (-3.9).to(i32); // -3
u8 byte_float = 255.9.to(u8);        // 向零截断为 255，未越界
u8 invalid = 300.0.to(u8);           // LLVM poison，不保证得到 44
```

*指针与整数之间的显式转换：*指针转整数生成 `ptrtoint`，整数转指针生成 `inttoptr`，指针位宽由目标平台 LLVM 数据布局决定。目标位宽更小时截断保留低位，目标位宽更大时一律高位补零（即使源或目标整数有符号也不作符号扩展），同宽时保持位模式。转换不插入范围检查，不保证所得指针可解引用，窄化丢弃的高位不会在再次扩宽时恢复；解引用仍须满足 @sec-bounds-memory。以下示例假定 64 位指针平台，仅演示地址位模式转换：

```cy
i8 source = -1;
*i32 address = source.to(*i32);
u64 bits = address.to(u64);              // 255：i8 的 8 位全 1 补零扩展至 64 位
*i32 extended = source.to(i64).to(*i32); // 先显式符号扩展至 i64 再转指针
```

=== 整数移位 <sec-shifts>

移位运算的左操作数与移位量可使用不同的内建整数类型，结果类型保持左操作数类型，右移方式由左操作数有符号性决定。左操作数为未定型整数字面量时按外层期望整数类型或默认 `i32` 定型；右操作数独立定型，无期望类型时默认 `i32`。

左移 `<<` 生成同位宽 LLVM `shl`（低位补零、丢弃移出高位）；无符号右移 `>>` 生成 `lshr`（高位补零）；有符号右移 `>>` 生成 `ashr`（高位填充符号位）。默认不附加 `nsw`、`nuw` 或 `exact`；有效移位量下移出非零位或改变符号位不是错误。

移位量按其自身整数位宽的无符号值解释；当移位量大于或等于左操作数位宽（含负数移位量按无符号解释后的越界情形）时，结果为 LLVM `poison`。后端为适配 LLVM 同位宽操作数要求转换移位量时，必须保留该越界语义，不得通过截断或掩码将越界移位量变为有效值；实现不插入运行期检查，也不模拟特定硬件的移位掩码行为。

```cy
u64 bits = 1;
u8 count = 3;
u64 shifted = bits << count; // 合法：结果为 u64，值为 8
```

=== 整数除法、取模与溢出 <sec-int-div>

整数 `/` 或 `%` 的右操作数若为编译期常量 `0`，为编译错误；运行期右操作数为 `0` 时按 LLVM 规则属于未定义行为，不插入除零检查，也不保证触发运行期陷阱（Trap）。有符号整数最小负数 `/ -1` 导致的商溢出必须触发运行期 Trap 并立即终止进程。

有符号 `%` 生成 LLVM `srem`，有符号 `/` 在保障上述商溢出 Trap 的前提下生成 `sdiv`，无符号 `/` 与 `%` 分别生成 `udiv` 与 `urem`。有符号最小负数 `% -1` 按 LLVM 规则属于未定义行为，不作额外保护；编译器可依据 LLVM 规则假设运行期除零与该取余边界不会发生。

运行期普通整数加、减、乘及取负溢出按二进制补码回绕；编译期常量算术运算超出目标类型表示范围时为编译错误（显式 `.to()` 转换除外，见 @sec-conversions）。

=== 浮点边界 <sec-float-ops>

浮点加、减、乘、除和比较遵循 IEEE 754 标准语义，默认不开启 fast-math，不额外插入运行期浮点异常检查。非零有限浮点数除以 `0.0` 产生对应符号的正负无穷（`Inf`），`0.0 / 0.0` 产生 `NaN`；涉及 `NaN` 的大小比较及 `==` 均为 `false`，`NaN != NaN` 为 `true`。

浮点 `%` 两侧须同为 `f32` 或同为 `f64`，结果保持该类型，生成无 fast-math 标志的 LLVM `frem`（`fmod` 式取余，而非 IEEE 754 `remainder`）：对有限被除数和有限非零除数，按精确商向零截断后的整数商确定余数，余数符号与被除数一致且绝对值小于除数绝对值（例如 `5.5 % 2.0` 为 `1.5`，`-5.5 % 2.0` 为 `-1.5`），无需先经一次有舍入的浮点除法。

任一操作数为 `NaN`、被除数为无穷或除数为正负零时，浮点 `%` 产生 `NaN`（整数常量除零编译错误不适用于浮点 `%`）；有限被除数对无穷取余保留被除数，零余数保留被除数符号。编译期常量折叠遵循相同语义；目标平台将 `frem` 降低为数学库调用时的链接要求由实现规定。

== 赋值 <sec-assignment>

赋值 `=` 是右结合表达式，求值结果为写入左侧目标后的值。`a = b = c` 解析为 `a = (b = c)`：先确定 `a` 的存储位置，再求右侧子赋值（先确定 `b` 的存储位置，再求 `c`，写入 `b` 后将所得值写入 `a`）。

赋值左侧必须是 @sec-places-values 定义的可写存储位置（变量标识符 `id`、指针解引用 `expr.*`、指针下标 `ptr_expr[i]`，或以存储位置为基底的数组下标 `place[i]` 与可访问字段 `place.field`）；任何右值作为赋值目标均为编译错误。因此，括号包裹变量或对象后（如 `(a)`）不能赋值，以其为基底的 `(arr)[i]` 和 `(obj).field` 也不可写；但括号指针的解引用 `(p).*` 与下标 `(p)[i]` 仍为合法可写存储位置。字符串字节 `s[i]` 与联合读取 `.as()` 均产生右值，不可赋值。

```cy
i32 a = 0;
i32 b = 0;
*i32 p = &a;
a = b = 3;
print a = 4; // 赋值表达式的结果为写入 a 的 4
(p).* = 5;   // 合法：括号指针表达式解引用仍是可写存储位置
p[0] = 6;    // 合法：指针下标是可写存储位置
(a) = 7;     // 错误：括号表达式产生右值
```

= 语句与控制流 <ch-stmt>

== 语句文法与条件约束 <sec-stmt-grammar>

```ebnf
Block = "{", { BlockItem }, "}";
BlockItem = TypeDecl | VariableDecl | Statement;
Statement = Block | IfStmt | WhileStmt | ForStmt | NamedStmt
          | BreakStmt | ContinueStmt | PrintStmt
          | ReturnStmt | TryStmt | ThrowStmt | ExprStmt | ";";
IfStmt = "if", "(", Expr, ")", Statement,
         [ "else", Statement ];
WhileStmt = "while", "(", Expr, ")", Statement;
ForStmt = "for", "(", [ ForInit ], ";", [ Expr ], ";",
          [ Expr ], ")", Statement;
ForInit = DeclType, Identifier, "=", Expr | Expr;
NamedStmt = Identifier, ":", (Block | IfStmt | WhileStmt | ForStmt);
BreakStmt = "break", [ Identifier ], ";";
ContinueStmt = "continue", [ Identifier ], ";";
PrintStmt = "print", Expr, ";";
ExprStmt = Expr, ";";
```

`ReturnStmt` 见 @sec-func-decl，`TryStmt` 与 `ThrowStmt` 见 @sec-try-catch。

`if` 与循环仅作为语句，不产生值。`if`、`while`、`for` 的条件表达式静态类型必须为 `bool`，禁止将整数、指针或其他类型隐式转为布尔值。

分支和循环主体是一条 `Statement`，花括号 `{ ... }` 将多条项组合为单一块语句，缩进无语法意义；空语句 `;` 可作为主体。`VariableDecl` 与 `TypeDecl` 属于 `BlockItem` 而非 `Statement`，不能直接裸写为分支或循环主体（`for` 初始化位置单独允许变量声明，仍禁止 `typedef`）。`else` 始终与语法上允许匹配的最近一个未配对 `if` 结合。

```cy
if (true)
    if (false) print 1;
    else print 2;          // else 与内层 if 配对

if (true) i32 x = 1;                             // 错误：变量声明不能直接作主体
if (true) { i32 x = 1; }                         // 合法
if (true) typedef Count = i32;                   // 错误：typedef 不能直接作主体
if (true) { typedef Count = i32; Count n = 1; }  // 合法
```

== 具名结构与跳转 <sec-labeled-stmt>

普通块 `{ ... }`、`if` 语句和 `while`／`for` 循环可附加标签命名。标签与目标结构之间允许空白、换行和注释，但不得插入分号使标签悬空；具名 `if` 覆盖完整的 `if / else if / else` 链，是否省略分支花括号不改变标签范围。

- `break name;` 退出同一函数内包围当前位置的具名块、具名 `if`（直接跳过整条分支链，不落入后续 `else`）或具名循环，从该结构之后继续执行。
- `continue name;` 仅允许指向同一函数内包围当前位置的具名循环；指向具名块或具名 `if` 为编译错误。
- 无标签 `break;` 与 `continue;` 仅作用于包围当前位置的最内层循环，不受外围具名块或具名 `if` 影响；位于任何循环之外为编译错误。

禁止跳入兄弟结构、已结束结构或其他函数，语言不提供 `goto`。标签位于独立的语句标签名字空间（@sec-names-scopes）；内外嵌套的结构禁止使用同名标签，互不嵌套的结构可复用同名标签。

```cy
exit_block: {
    while (true) {
        break exit_block; // 退出外层具名块
    }
}
report: if (true) {
    continue report;      // 错误：report 不是循环
}
```

== C 式 `for` 循环 <sec-for>

`for (初始化; 条件; 步进)` 的三个部分均可省略，但两个分号必须保留；省略条件表示条件恒为 `true`。初始化仅在进入循环时执行一次；其中声明的变量按 @sec-names-scopes 解析初始化式，初始化完成后对该 `for` 的条件、步进和主体可见，离开 `for` 后不可见。

单轮迭代按“条件检查 → 主体 → 步进 → 下一次条件检查”顺序执行。主体正常结束或执行以该 `for` 为目标的 `continue` 时，继续执行步进表达式；执行以该 `for` 为目标的 `break` 时直接跳出循环，不执行步进（对 `while` 执行 `continue` 则直接回到条件检查）。

*完整示例：*下列程序最终打印整数 `3`（具体文本格式遵循实现规定）。

```cy
module example;

func main() -> void {
    i32 total = 0;
    outer: for (i32 i = 0; i < 3; i = i + 1) {
        for (i32 j = 0; j < 3; j = j + 1) {
            if (j == 1) continue outer;
            total = total + 1;
        }
    }
    print total;
}
```

== `print` 语句 <sec-print>

`print` 是按操作数静态类型分派的内建语句，仅接受内建整数、内建浮点、`bool`、`string` 和各类指针，输出后自动追加一个换行符 `\n`。

定长数组、联合、`typedef` 结构对象和 `class` 对象等复合值不支持直接 `print`，须逐字段打印或通过普通函数格式化；各允许类型除末尾换行外的具体文本格式由实现规定。

= 模块与程序组织 <ch-modules>

== 模块、导入与导出 <sec-module-imports>

每个完整源文件必须以 `module ModuleName;` 开头声明所属模块；一个模块可由多个源文件组成。`ModuleName` 由点号分隔的标识符构成（如 `graphics.geometry`），它是逻辑模块名而非文件系统路径，点号层级不自动引入父模块声明或产生传递导出。

同一模块的全部源文件共享模块级声明作用域（@sec-names-scopes），重复声明为编译错误。模块的组成源文件由构建输入显式给定并经编译器核对 `module` 声明，文件名与目录位置不决定声明身份；依赖库中的同名模块不自动合并，同一构建中存在冲突模块提供者时为编译错误。

模块顶层的 `typedef`、`class`、`func` 和变量默认仅在所属模块的全部源文件内可见；前置 `export` 后才允许其他模块显式导入，导入未导出声明为编译错误。跨模块引用必须显式书写 `import`，导入保留原声明身份（不创建新类型、新类、新变量或新函数身份）。`as` 可为导入项指定当前源文件内的本地名字；导入绑定仅在当前源文件内生效，不向同模块其他源文件或第三方模块传递（若模块 `A` 导出 `x`、模块 `B` 导入 `x`，模块 `C` 仍须直接从 `A` 导入 `x`）。同一源文件内的导入绑定之间不得重名，也不得与本模块的模块级声明重名。

```ebnf
SourceFile = ModuleDecl, { ImportDecl | TopLevelDecl }, EOF;
ModuleDecl = "module", ModuleName, ";";
ModuleName = Identifier, { ".", Identifier };
ImportDecl = "import", "{", ImportItem, { ",", ImportItem }, "}",
             "from", ModuleName, ";";
ImportItem = Identifier, [ "as", Identifier ];
TopLevelDecl = [ "export" ], (ExportableDecl | ImplDecl);
ExportableDecl = TypeDecl | ClassDecl | FunctionDecl | VariableDecl;
```

`export` 仅允许修饰上述模块级声明以及#ref(<ch-classes>)规定的类字段、类内方法、`init` 和外部 `impl`，用于局部声明或 `import` 为编译错误。`export impl` 导出对应类方法而不产生独立的模块级函数名；`export class` 不自动导出类成员，外部模块导入类后可直接访问其带 `export` 的成员而无需单独导入方法。

```cy
// helpers.cy
module math;

func helper(i32 value) -> i32 {
    return value * 2;
}
```

```cy
// operations.cy
module math;

export func double_value(i32 value) -> i32 {
    return helper(value); // 同模块跨文件直接访问，无需 export 或 import
}
```

```cy
// main.cy
module app;
import { double_value as twice } from math;
// import { helper } from math; // 错误：helper 未导出

func main() -> void {
    print twice(21);
}
```

库仅是打包与链接单位，不引入库级可见性或公开模块清单：无论同一库内还是跨静态库／动态库，跨模块共享均统一通过 `export` 与显式 `import` 控制。`module` 与 `import` 均为静态组织声明，不书写文件系统路径，也不产生运行期顶层操作。

模块之间允许直接或间接循环导入：导入成环本身不是编译错误，成环模块中的函数可合法相互调用。编译器必须在检查函数体前收集各模块的导出签名，不得要求按无环拓扑顺序逐模块完整编译，且沿导入环再次遇到同一模块时必须保持声明身份唯一。由于 @sec-module-init 禁止运行期模块初始化，循环导入不会引发运行期初始化顺序问题。

```cy
// even.cy
module even;
import { is_odd } from odd;

export func is_even(u32 n) -> bool {
    if (n == 0) return true;
    return is_odd(n - 1);
}
```

```cy
// odd.cy
module odd;
import { is_even } from even;

export func is_odd(u32 n) -> bool {
    if (n == 0) return false;
    return is_even(n - 1);
}
```

== 顶层与静态初始化 <sec-module-init>

模块顶层仅允许 `typedef`、`class`、`impl`、`func` 及模块级变量声明，出现可执行语句为编译错误；导入、链接、加载模块或进入 `main` 均不得隐式执行用户代码。

模块级变量必须显式初始化且初始化式必须为 `ConstExpr`（@sec-constexpr），在编译期求值并按静态数据建立初值；模块级变量间的 `ConstExpr` 依赖成环为编译错误。由于 `ClassName.init(...)` 属于函数调用而非 `ConstExpr`，且类不存在常量构造形式，模块级变量不能直接保存类对象；需要共享类实例时，可将模块级变量声明为类指针（如 `*Node | null`），在运行期函数内按#ref(<ch-classes>)显式构造对象后再赋给该指针，其对象寿命与访问次序由程序负责。

```cy
i32 default_limit = 4;       // 合法：ConstExpr 静态初值
*Node | null current = null; // 合法：类指针可作模块级变量
Node shared = Node.init();   // 错误：模块级变量不能保存类对象且初值非 ConstExpr
i32 runtime = compute();     // 错误：模块级初始化式不是 ConstExpr
```

模块是声明解析的最小整体：所属模块全部源文件的模块级声明、类成员、继承关系与外部 `impl` 均先按全模块收集，再统一执行名字解析、类型检查和模块变量常量求值。模块级名字引用不受文件拆分、构建输入次序或源码书写先后影响；引用未声明名字或同级重复声明均为编译错误，不得按处理先后覆盖。

```cy
func main() -> void {
    print double_value(limit); // 合法：全模块收集后解析模块变量与函数
}

i32 limit = 4;
// print limit;                // 错误：模块顶层禁止执行语句

func double_value(i32 value) -> i32 {
    return value + value;
}
```

== 可执行程序入口 <sec-main-entry>

可执行程序必须提供模块级 `main` 函数，合法签名仅限 `func main() -> void` 或 `func main() -> i32`（不接收参数，无需标记 `export`）；其他签名的 `main` 不能作为可执行程序入口。`i32` 返回值到宿主进程退出状态的映射由实现规定；未捕获异常传播出入口 `main` 时按 @sec-catch-match 异常终止进程。

= 函数与调用 <ch-functions>

== 定义与函数指针 <sec-func-decl>

普通函数仅允许模块级具名定义，不支持局部函数、匿名函数、闭包捕获或同名函数重载；参数类型与返回类型均须显式写出（类内方法与外部 `impl` 见#ref(<ch-classes>)）。

```ebnf
FunctionDecl = "func", Identifier, "(", [ Parameters ], ")",
               "->", ReturnType, Block;
Parameters = Parameter, { ",", Parameter };
Parameter = DeclType, Identifier, [ "=", ConstExpr ];
ReturnType = DeclType | "void";
ReturnStmt = "return", [ Expr ], ";";
```

参数的可选默认值 `= ConstExpr` 仅允许用于类内的 `init`（@sec-class-init）；普通函数、类普通方法和外部 `impl` 的参数附加默认值为编译错误。

函数指针可存入变量、作为参数传递和作为返回值返回，其类型采用 `*func` 前缀语法，仅列参数类型而不写参数名：

```ebnf
FunctionPointerType = "*", "func", "(", [ DeclType, { ",", DeclType } ],
                      ")", "->", ReturnType;
```

`->` 右侧按完整 `ReturnType`（即 `DeclType | "void"`）解析；若需将函数指针类型作为外层联合的一个成员，须按 @sec-type-identity 先用括号包裹整个函数指针类型，如 `(*func(i32) -> i32) | null`。

对模块级普通函数 `f`，`f(args)` 直接发起调用，`&f` 取得对应签名的函数指针；以裸函数名 `f` 直接初始化变量、传参或返回而不加 `&` 为编译错误。已取得的函数指针值可直接复制、传递或加 `(args)` 调用，调用签名须与目标函数一致，不携带闭包环境。类方法通过 `&ClassName.method` 取得函数指针，显式接收者对应首参数（@sec-dispatch-super）。

```cy
func increment(i32 x) -> i32 {
    return x + 1;
}

func apply_twice(*func(i32) -> i32 operation, i32 value) -> i32 {
    return operation(operation(value));
}

func main() -> void {
    *func(i32) -> i32 callback = &increment;
    print increment(3);             // 4
    print apply_twice(callback, 3); // 5
}
```

== 返回约束 <sec-return>

返回类型 `void` 表示不产生返回值（不同于返回 `null`）：`void` 函数可执行 `return;` 或自然执行至函数体末尾，写成 `return Expr;` 为编译错误。返回非 `void` 类型的函数必须通过 `return Expr;` 返回符合声明返回类型的值；经编译器的常规保守控制流分析仍不能排除正常执行落到函数体末尾的路径时，必须报编译错误（异常传播或永不终止的路径不要求提供返回值，也不要求编译器推导复杂条件间的逻辑互斥关系）。

```cy
func abs_value(i32 value) -> i32 {
    if (value < 0) return -value;
    return value;
}

func incomplete(bool ready) -> i32 {
    if (ready) return 1;
} // 错误：ready 为 false 时可能正常落到函数末尾而未返回值
```

== 普通调用边界 <sec-tail-call>

实现不得执行尾调用优化（包括不得将尾递归改写为循环）：尾部位置的函数或方法调用必须保留普通调用栈帧语义，无论当前函数是否存在待执行的清理操作。

= 对象、继承与方法 <ch-classes>

== 类声明与成员可见性 <sec-class-decl>

`class` 提供具名类与单继承机制，继承关系不得成环（直接或间接继承自身均为编译错误）。如 @sec-type-identity 规定，类不属于类型系统：类名是 `ClassName` 而非 `TypeName`，`TypeExpr` 中仅指针被指对象与函数指针签名允许出现类名；`typedef` 结构对象的透明别名、结构兼容和字面量构造规则均不适用于 `class`。类声明不自动生成初始化逻辑，类实例必须按 @sec-class-init 显式构造，也不自动生成对象相等比较运算。

类按声明保持独立身份，允许无字段类及空类体 `{}`；判断类是否无字段时须计入全部继承字段。无字段类同样可定义方法、显式 `init` 并参与继承。

```cy
class Ready {}
class Closed {}
// Ready 与 Closed 是不同的类，*Ready 与 *Closed 是不同的指针类型。
```

类字段、方法与 `init` 默认仅在声明所属模块内可见，前置 `export` 后允许跨模块访问；语言不设 `private`、`protected` 或 `public`。类名与成员的导出相互独立：`export class` 不自动导出其成员，成员标记 `export` 也不自动导出所属类。

模块是成员访问控制的唯一边界：同一模块任意源文件中的普通函数、其他类及外部 `impl` 均可访问未导出成员；跨模块进行字段读写、字段取地址、方法调用、方法取函数指针、`init`／`super` 调用或声明继承字段 `as` 约束时，若目标成员未导出则为编译错误。继承但未重写的成员保留原声明所属模块与导出属性，跨模块子类不因继承获得父类未导出成员的访问权。可见性纯属编译期检查，不影响内存布局、尺寸、父类前缀或按值复制。

字段与方法共用类的成员名字空间（与 @sec-names-scopes 普通声明名字空间规则一致）：同一类中字段之间、字段与方法之间（含继承成员及同模块外部 `impl` 方法）均不得重名；子类不得以字段遮蔽继承方法或以方法遮蔽继承字段（合法方法重写见 @sec-method-binding；`field as T;` 仅约束已有继承字段，不声明新成员）。

```ebnf
ClassDecl = "class", Identifier, [ "extends", ClassName ],
            "{", { ClassMember }, "}";
ClassMember = [ "export" ], (FieldDecl | MethodDecl | InitDecl)
            | FieldAccessDecl;
FieldDecl = TypeExpr, Identifier, ";";
FieldAccessDecl = Identifier, "as", TypeExpr, ";";
MethodDecl = FunctionDecl;
InitDecl = "func", "init", "(", [ Parameters ], ")",
           "->", Identifier, Block;
ImplDecl = "impl", ClassName, ".", Identifier,
           "(", [ Parameters ], ")", "->", ReturnType, Block;
```

`InitDecl` 的返回类型标识符必须等于当前类名。`FieldDecl` 使用 `TypeExpr`，因此类字段不能按值直接嵌套类对象，须使用类指针（如 `*Node`）。

```cy
// buffer.cy
module buffers;

export class Buffer {
    *u8 data;
    u64 length;

    export func init(*u8 data, u64 length) -> Buffer {
        return { data: data, length: length };
    }
}
```

```cy
// queries.cy
module buffers;

export impl Buffer.size(Buffer self) -> u64 {
    return self.length; // 同模块的外部 impl 可访问未导出字段
}

func is_empty(Buffer value) -> bool {
    return value.length == 0; // 同模块的普通函数也可访问
}
```

```cy
// use_buffer.cy
module app;
import { Buffer } from buffers;

func inspect(Buffer value) -> void {
    print value.size();
    // print value.length; // 错误：跨模块访问未导出字段
    // value.length = 0;   // 错误：写入同样受可见性约束
}
```

== `class` 分层规范化内存布局 <sec-class-layout>

根类的自身字段先按字段对齐字节数从大到小排列，对齐要求相同的字段再按字段名 ASCII 字典序排列，并执行目标平台所需的对齐与填充，构成固定尺寸的内存块（本规范以记号 `sizeof(Parent)` 指代父类完整块字节数，不新增同名语言运算符）。

子类 `Child extends Parent` 将直接父类 `Parent` 的完整内存块原样固定在起始偏移 `0` 处，`Child` 新增字段按同一规范化排序规则排列在整个 `Parent` 内存块之后；多层继承逐层递推。通过 `field as T;` 声明访问约束的继承字段并非新增字段，仍原地占用父类前缀中的既有槽位。

因此，任意 `Child` 实例的起始内存前缀均为布局完全合法的 `Parent` 实例：按值转换 `child.to(Parent)` 直接截取复制前 `sizeof(Parent)` 字节，指针转换 `(&child).to(*Parent)` 零成本复用原地址。类对象不含隐式 vptr、对象头或生命周期元数据。

== 继承字段的 `as` 访问约束 <sec-field-as>

子类可在自身 `class` 定义块内书写 `field as TypeExpr;`，为当前位置可访问的已有继承字段声明编译期访问约束。约束保留原字段的所属模块与导出属性，不改变该字段的原始静态类型、槽位尺寸、对齐、偏移或联合标签编码，也不产生窄联合类型或子类型转换；禁止用普通 `TypeExpr field;` 重新声明同名继承字段，禁止在同一类中对同一字段重复声明 `as` 约束，禁止在外部 `impl` 中追加或修改约束，也禁止为 `FieldAccessDecl` 附加 `export` 或借此公开未导出字段。

约束类型的值域必须是原字段类型（及祖先已声明约束）值域的子集，后代类只能维持或进一步收紧继承约束，不得扩大允许范围：例如可将 `string`、`i32` 字段分别约束为字面量类型 `"user"`、`200`，将 `T | null` 约束为 `T`，或将联合约束为其成员或成员子集。

```cy
class Entity {
    string kind;
    i32 code;
    i32 | null value;
}

class User extends Entity {
    kind as "user";
    code as 200;
    value as i32;
}
```

访问约束依据字段访问表达式基底的编译期静态类生效：

- *写入与构造：*经子类直接写入字段或在子类中构造实例时，写入值须同时满足原始字段类型与子类访问约束；底层仍按原始表示存储（联合写入维护原始宽联合标签并执行 @sec-union-read 尾部清零），不插入运行期检查。
- *读取与复制：*普通字段读取 `c.field` 与按值复制仍产生原始字段类型的值（字面量约束不将字段读取折叠为字面量常量）；联合字段读取具体成员仍须显式写 `.as(T)`（即使约束仅剩单一成员），且经子类直接调用 `.as(T)` 时 `T` 必须是原始联合成员并落在约束允许范围内（不能把子集联合本身作为 `.as()` 目标）。`typeof` 仍读取真实运行期标签。
- *取地址与别名：*对存储位置上的可访问字段，`&c.field` 取得指向原始字段类型的普通指针，不携带子类访问约束。若经父类视图或原始字段指针向槽位写入了约束之外的其他成员，随后再经子类执行符合约束的 `.as(T)`，仍按 @sec-union-read 直接按字节解释槽位内容，无运行期匹配检查且不构成未定义行为；编译器不得依据访问约束假设槽内不可能存在其他成员。

```cy
class Parent {
    i32 | f32 | string value;
}
class Child extends Parent {
    value as (i32 | f32);
}

// c 是已初始化的 Child 实例。
c.value = 3.to(i32);                // 合法：写入原始宽联合并维护标签
string message = "hello";
c.value = message;                  // 错误：违反 Child 的访问约束
i32 n = c.value.as(i32);            // 合法：显式读取，无运行期匹配检查
c.value.as(string);                 // 错误：超出 Child 允许的读取范围
i32 | f32 small = c.value;          // 错误：原始字段静态类型仍是宽联合
i32 | f32 | string copy = c.value;  // 合法：按原始字段类型复制
*(i32 | f32 | string) p = &c.value; // 取地址得到指向原始宽联合的指针
p.* = message;                      // 合法：普通指针不携带 Child 访问约束
n = c.value.as(i32);                // 仍合法：按 i32 直接解释当前槽内字节
```

== 全模块绑定与方法归属 <sec-method-binding>

同一模块全部源文件中的 `class`、继承关系与外部 `impl` 均按全模块收集后统一绑定和检查，与文件划分及声明先后无关。方法既可定义在 `class` 块内（导出写作 `export func m(...)`），也可定义在所属模块任意源文件的外部 `impl` 中（导出写作 `export impl ClassName.m(...)`）；禁止跨模块为外部类编写 `impl`。类的方法集合在所属模块编译时即完全封闭确定。

方法覆盖遵循唯一优先级规则：子类 `class` 块内定义的方法可覆盖父类方法（无论父类方法定义于父类 `class` 块内还是父类模块的外部 `impl`）。同一类的同级重复定义、用外部 `impl` 覆盖本类已有方法，或用子类外部 `impl` 覆盖继承方法，均为编译错误。

方法不支持同名参数重载或多方法分派；不同类可各自声明同名方法。方法的接收者必须显式声明为首个参数（如 `Circle self`），`circle.area()` 对应按值传入接收者的调用；需要修改外部对象时仍通过显式指针表达。

调用表达式 `obj.f(args)` 先按 `obj` 的静态类解析成员 `f` 并检查可见性：

- 若 `f` 为方法，自动将 `obj` 作为首参数传入，括号内仅填写接收者之后的其余实参；
- 若 `f` 为函数指针类型的字段，则按普通函数指针调用，仅传入括号内显式列出的实参，不自动传入 `obj`。

由于字段与方法禁止同名（@sec-class-decl），上述两种情形互不歧义。

```cy
class Circle {
    f64 radius;
}

impl Circle.area(Circle self) -> f64 {
    return 3.141592653589793 * self.radius * self.radius;
}
```

```cy
class Callback {
    *func(i32) -> i32 run;
}
// callback 是已初始化的 Callback 实例。
i32 result = callback.run(3); // 字段函数指针调用，仅传入 3

class Conflict {
    *func(i32) -> i32 run;
    func run(Conflict self, i32 x) -> i32 { return x; }
} // 错误：字段与方法同名
```

== 继承分派、`super` 与机器码复用 <sec-dispatch-super>

所有方法调用（含继承与重写方法）一律采用编译期静态分派，不维护 vtable：目标函数完全由接收者表达式的编译期静态类决定；需要运行期多态时应使用类指针联合（如 `*Circle | *Rect`）或显式函数指针。普通赋值、传参与返回中的子类实例到父类实例仍须使用 @sec-conversions 的显式转换，下述 `super` 调用自动传递父类接收者属于专门调用规则。父类方法全局只生成一份机器码，未重写该方法的子类直接复用同一函数实现。

子类在具有当前接收者 `self` 的自身方法（含同模块合法外部 `impl` 方法）内部，可通过 `super.method(args)` 静态调用直接父类上可用且在当前位置可访问的方法（跨模块继承时目标父类方法须已 `export`）：

```ebnf
SuperCallExpr = "super", ".", Identifier, "(", [ Arguments ], ")";
```

求值 `super.method(args)` 时，先按 @sec-class-layout 的前缀复制规则从当前接收者提取 `Parent` 子对象作为首参数，再按 @sec-eval-order 从左到右求值括号内的其余实参，静态绑定至直接父类实现（`super.init` 另循 @sec-class-init 规则，不自动传入接收者）。

```cy
class Parent {
    func score(Parent self) -> i32 { return 10; }
}
class Child extends Parent {
    func score(Child self) -> i32 {
        return super.score() + 1; // 自动传入父类前缀，结果为 11
    }
}
```

对可访问的类方法取函数指针统一写作 `&ClassName.method`，所得静态类型为以显式接收者为首参数的普通函数指针 `*func(ClassName, ...) -> ReturnType`（裸写 `ClassName.method` 或对实例方法访问取地址 `&obj.method` 均为编译错误）：

```cy
*func(Circle) -> f64 area_fn = &Circle.area;
```

== 显式 `init` 与类内部构造 <sec-class-init>

`init` 是在 `class` 块内定义的关联初始化函数，签名固定为 `func init(Parameters) -> ClassName`，返回当前类的对象值，不支持同名重载。调用方通过 `ClassName.init(...)` 显式构造实例；跨模块调用 `ClassName.init(...)` 或子类中调用 `super.init(...)` 均要求目标 `init` 已标记 `export`（仅 `export class` 不自动导出 `init`）。

```ebnf
ClassInitExpr = ClassName, ".", "init", "(", [ Arguments ], ")";
```

`init` 参数允许使用编译期常量默认值 `TypeExpr name = ConstExpr`：必填参数必须全部排在带默认值的参数之前；默认值在声明处按参数类型检查并求得编译期常量，不得引用运行期参数。`ClassName.init(...)` 与 `super.init(...)` 均按位置顺序匹配实参，仅允许连续省略末尾具有默认值的参数并由编译器在调用处补齐对应常量；缺少必填参数、实参过多或用空位跳过中间参数均为编译错误。默认参数不改变底层函数签名或调用约定，显式实参仍从左到右求值；省略参数的规则只适用于上述按名调用，不使普通函数指针调用具有默认参数。

```cy
class Client {
    i32 port;
    i32 timeout;
    i32 retries;

    func init(i32 port, i32 timeout = 30, i32 retries = 3) -> Client {
        return { port: port, timeout: timeout, retries: retries };
    }
}
```

```cy
Client a = Client.init(8080);        // timeout 为 30，retries 为 3
Client b = Client.init(8080, 60);    // timeout 为 60，retries 为 3
Client c = Client.init(8080, 60, 5); // 全部显式指定
Client.init();                       // 错误：缺少必填参数 port
Client.init(8080, , 5);              // 错误：不能跳过中间参数
Client.init(8080, 60, 5, 1);         // 错误：实参过多
```

以对象字面量 `{ ... }` 直接构造类实例，仅允许出现在该类自身的方法（含同模块外部 `impl`）与 `init` 内部、且期望类型为当前类的位置（该作用域限制仅针对类实例构造，`typedef` 结构对象字面量遵循 @sec-struct-objects）。若当前类（含全部继承字段）确实没有任何字段，则在上述允许位置可用 `{}` 进行全字段显式构造；无字段类仍不自动生成 `init`，变量声明也不得省略初始化式。

```cy
class Token {
    func init() -> Token {
        return {};
    }
}
func use_token() -> void {
    Token token = Token.init(); // 显式构造无字段类实例
}
```

子类 `Child.init` 构造 `Child` 实例仅允许以下两种形式（根类 `init` 仅使用全字段直接构造，`super.init` 仅允许出现在子类 `init` 内部）：

+ *委托直接父类 `init`：*使用 `super.init(...) { ... }` 构造 `Child` 实例：

  ```ebnf
  SuperInitExpr = "super", ".", "init", "(", [ Arguments ], ")", "{",
                  [ FieldInit, { ",", FieldInit }, [ "," ] ], "}";
  ```

  ```cy
  return super.init(id) { kind: "user", child_field: val };
  ```

  求值时先调用直接父类的 `init` 填充 `Parent` 内存前缀，再按从左到右顺序计算 `{ ... }` 中的字段初始化式以填充或覆写字段。当前子类新增的全部字段，以及在当前子类中通过 `as` 声明访问约束的全部继承字段，均必须在 `{ ... }` 中显式赋值（以覆盖父类可能写入的宽泛值），遗漏任一项均为编译错误；其他在当前位置可访问的继承字段可按需覆写。所有字段值须同时满足原始字段类型与当前子类适用的访问约束；父类未导出的跨模块字段由父类 `init` 负责初始化，不向子类开放。

+ *全字段直接构造：*不调用 `super.init`，直接使用 `{ ... }` 显式给出全部继承字段与子类新增字段的初始值。字面量中列出的每个字段均须在当前位置可访问，字段值须满足原始字段类型与当前子类适用的访问约束，遗漏、多出或重复字段均为编译错误；若存在跨模块不可访问的继承字段，则不能采用全字段直接构造，须改用可访问的父类 `init` 委托构造。

= 异常与资源生命周期 <ch-exceptions>

== 抛出、接收与栈展开 <sec-try-catch>

异常机制由 `try`、`catch`、`throw` 构成：

```ebnf
TryStmt = "try", Block,
          "catch", "(", TypeExpr, Identifier, ")", Block;
ThrowStmt = "throw", Expr, ";";
```

`throw expr;` 将异常值按值复制到运行时预留的固定容量异常存储槽，不触发隐式堆分配；匹配 `catch` 后再按值复制到接收变量。栈展开仅恢复控制流与调用栈帧，不执行局部变量隐式析构，也不自动释放动态内存。

异常值属于类型系统：`throw` 操作数的静态类型与 `catch` 声明的接收类型均须为 `TypeExpr`，类对象不能直接抛出或捕获（需传递类实例时应抛出类指针，如 `*Node`）。异常值若包含指针或 `string` 视图，按值复制仅复制地址或视图；其所指数据的寿命及 `try` 块内动态资源在异常路径上的回收责任，须由外层 Arena 或调用方显式承担（正常路径仍可在 `try` 内主动释放）。

== 固定槽容量与 `catch` 类型匹配 <sec-catch-match>

目标平台的固定异常槽字节容量由实现规定。`throw expr;` 中 `expr` 的静态类型尺寸，以及 `catch (T id)` 中 `T` 的静态类型尺寸，均不得超过该固定容量；任一处超出容量即为编译错误（静态检查，不依赖运行期控制流或实际抛出值）。

异常匹配在展开透明别名并归一化联合类型后，仅按以下两条规则判定（不执行数值隐式转换，也不按类继承关系匹配）：

- *精确匹配：*`T_throw` 与 `T_catch` 为同一类型，直接从异常槽按值复制到 `id`（例如抛出 `i32 | f32` 值时，`catch (f32 | i32 id)` 精确匹配并保留原当前成员标签）。
- *联合捕获匹配：*`T_catch` 为联合类型且 `T_throw` 是其归一化成员类型之一，按 @sec-union-construct 将异常槽中的值连同对应成员标签构造为联合值 `id`，并执行槽尾清零。

异常未被任何匹配的 `catch` 捕获而传播出程序入口 `main` 时，必须异常终止进程（不视为 `main` 正常返回，宿主支持退出状态时必须表示失败），且不执行隐式清理或尚未到达的后续语句；具体退出码、终止机制与是否输出诊断信息由实现规定。

== 显式清理示例 <sec-cleanup-example>

以下示例使用库提供的 `Arena` 接口管理临时内存（设 `require_positive` 抛出的异常静态类型为 `i32`）：

```cy
Arena arena = arena_init(4096);
try {
    *i32 value = arena_alloc_i32(&arena);
    value.* = require_positive(input);
    print value.*;
} catch (i32 error) {
    print error;
}
arena_deinit(&arena);
```

正常完成与被 `catch (i32 error)` 捕获的路径均会汇合执行 `arena_deinit(&arena)`；若抛出未匹配类型的异常、`catch` 块内再次抛出异常或控制流提前返回，则回收责任由更外层区域或调用方承担。

= 编译器、ABI 与外部边界 <ch-abi>

== 前端与诊断 <sec-frontend-diag>

编译流程依次包含词法与语法解析生成 AST、名字解析、类型检查及代码生成。语法解析器采用手写递归下降实现，语法错误恢复仅使用以分号等语法边界同步的 panic mode。

递归下降解析的语法嵌套深度上限默认为 512 层，可通过编译器参数配置；超出上限必须报编译错误，不得因宿主调用栈耗尽而崩溃。深度计数粒度及配置参数名由实现规定。附录 A 中的诊断编号仅供规范查阅，不约束编译器的实际错误码或提示措辞。

== 产物与 ABI <sec-abi>

编译器前端经 LLVM IR 生成目标平台标准目标文件，静态库归档及动态库、可执行文件链接由系统工具链完成。模块间与库间统一适用 `export` 可见性规则：工具链按模块接口和 ABI 生成链接符号与动态导出表，二进制目标中存在符号不赋予 Cyly 源码导入未导出声明的权限。

使用同一版本 Cyly 编译器、同一目标平台及一致 ABI 相关编译选项时，接口类型一致的独立编译产物（目标文件、静态库、动态库）必须能够直接链接互操作；跨编译器版本的内部 ABI 稳定性不在保证之列。

联合值可跨上述独立编译边界按值传参和返回：对同一联合类型，调用方与被调方必须采用一致的标签编码、存储槽布局和调用约定。例如动态库函数按返回类型 `i32 | f32` 返回 `f32` 成员值，调用方以 `f32 | i32` 接收后，`typeof(value) == f32` 必须为 `true` 且 `value.as(f32)` 必须读出原返回值。

语言不提供 FFI 或 `extern` 声明：基础库通过不向用户源码开放的编译器内部运行时原语访问底层内存页、字节流和网络 I/O，用户程序通过进程间通信（IPC）或网络协议与外部软件交互。实现文档必须记录目标平台类型尺寸、对齐、端序、调用约定、联合标签编码与布局、固定异常槽容量与布局、符号命名规则及 ABI 相关编译选项；联合标签的编码、宽度及其与存储槽的布局须满足上述独立编译兼容要求，模块接口中的递归结构类型表示须保留 @sec-struct-objects 的结构同一性。

#pagebreak()
#heading(numbering: none)[附录 A · 诊断索引]

本索引汇总主要编译错误及其正文依据；其他违反正文约束的程序同样必须作为编译错误拒绝。

#matrix(
  table.header([*编号*], [*触发条件与依据*]),
  [D01], [源文件中出现实际 NUL 字节；代码符号含非 ASCII 字节（文件开头 UTF-8 BOM 除外）；代码空白处出现单独 CR。@ch-lex[§]。],
  [D02], [普通字符串直接换行、反斜杠续行、含未知转义或缺失结束引号；将保留字（含内建基础类型名）用作普通标识符。@ch-lex[§]。],
  [D03], [同一作用域内声明重名（含重声明内建基础类型名、参数重名、函数体或 `catch` 最外层与参数／接收变量重名、同一源文件导入绑定重名或与本模块顶层声明重名）；引用未声明名字、先用后定义局部变量或不可见的局部 `typedef`；局部初始化式在无同名外层绑定时引用正在声明的变量；`ClassName` 出现在 `*ClassName` 与函数指针签名之外的 `TypeExpr` 位置（如联合成员、数组元素、`typedef` 右侧或字段类型）。@ch-lex[§]、@ch-types[§]、@ch-modules[§]、@ch-classes[§]。],
  [D04], [变量声明缺少显式类型或缺少初始化式；使用 `var` 声明变量。@sec-names-scopes。],
  [D05], [定长数组长度 `N` 不是编译期正整数常量；数组枚举字面量元素个数或重复填充 `[val; N]` 的 `N` 与目标长度不符。@sec-type-identity、@sec-arrays。],
  [D06], [`.as(T)` 的目标不是联合归一化后的成员类型；直接访问联合对象的共同字段；`typeof` 参数不是联合或指针类型的存储位置；`typeof` 测试右侧类型不属于该联合或与左侧指针静态类型不同；`typeof` 出现在允许的相等性测试之外。@ch-unions[§]。],
  [D07], [数组、字符串或裸指针下标不是内建整数类型；定长数组或字符串的编译期常量下标越界。@sec-bounds-memory、@sec-string-value。],
  [D08], [将定长数组隐式退化为指针；通过 `string` 视图写入字节。@sec-arrays、@sec-string-value。],
  [D09], [对字符串使用大小比较或拼接运算符、隐式字符串转换或相邻字符串字面量拼接。@sec-lex-string、@sec-string-compare。],
  [D10], [不被允许的隐式类型转换（含已定型数值间转换、子类实例到父类实例转换；合法联合构造不在此列）；用 `==` 或 `!=` 直接比较静态类型不同的指针。@sec-literal-typing、@sec-pointers、@sec-ops。],
  [D11], [未定型数值字面量超出目标类型表示范围；赋值目标不是可写存储位置，或一元 `&` 作用于不允许的操作数；`ConstExpr` 含函数调用、解引用、赋值或运行期内存读取；整数 `/` 或 `%` 的右操作数为编译期常量 `0`，或编译期常量算术溢出。@sec-literal-typing、@sec-constexpr、@sec-pointers、@ch-expr[§]。],
  [D12], [`if`、`while`、`for` 条件不是 `bool`；变量声明或 `typedef` 未加块花括号直接作为分支／循环主体；`for` 初始化中使用 `typedef`。@sec-stmt-grammar。],
  [D13], [语句标签未附着于块、`if` 或循环，或标签后紧跟分号悬空；内外嵌套结构使用同名标签。@sec-labeled-stmt。],
  [D14], [无标签 `break` 或 `continue` 位于循环外；具名跳转目标不包围当前位置或不在同一函数内。@sec-labeled-stmt。],
  [D15], [`continue` 指向具名块或具名 `if`；`for` 头部缺少两个必需分号。@sec-labeled-stmt、@sec-for。],
  [D16], [模块顶层出现执行语句；模块级变量缺少初值、初值不是 `ConstExpr`、初值依赖成环或直接声明为类对象类型；`import` 书写文件系统路径。@sec-constexpr、@ch-modules[§]。],
  [D17], [定义局部函数、匿名函数、闭包或同名重载函数，或省略参数／返回类型；可执行程序入口 `main` 签名不符；以裸函数名或裸方法名代替 `&f`／`&ClassName.method` 函数指针。@sec-main-entry、@sec-func-decl、@sec-dispatch-super。],
  [D18], [`void` 函数返回表达式值；非 `void` 函数执行无值 `return;`、返回值类型不符，或经保守控制流检查仍可能正常落到函数末尾。@sec-return。],
  [D19], [跨模块编写外部 `impl`；同一方法同级重复定义；用外部 `impl` 覆盖本类已有方法，或用子类外部 `impl` 覆盖继承方法。@sec-method-binding。],
  [D20], [类继承成环；字段之间或字段与方法重名（含继承成员与外部 `impl`）；同一类同名方法重载；子类重声明继承字段；`as` 约束指向非继承字段、同级重复、超出原字段／祖先约束值域、附加 `export` 或写在类定义块外；经子类直接写入字段或调用 `.as()` 违反访问约束。@ch-classes[§]。],
  [D21], [递归下降解析超出配置的语法嵌套深度上限。@sec-frontend-diag。],
  [D22], [`typedef` 结构对象无字段或字段重名；结构对象字面量遗漏、多出、重复字段或字段类型不匹配；在类自身方法（含同模块外部 `impl`）及 `init` 之外使用 `{ ... }` 构造该类实例；类全字段构造遗漏／多出字段，或 `super.init(...) { ... }` 遗漏子类新增字段／当前子类声明 `as` 约束的继承字段。@sec-struct-objects、@sec-class-init。],
  [D23], [对定长数组、联合、`typedef` 结构对象或 `class` 对象直接执行 `print`。@sec-print。],
  [D24], [`throw` 表达式或 `catch` 接收类型的静态尺寸超过目标平台固定异常槽容量；直接抛出或捕获类对象。@sec-try-catch、@sec-catch-match。],
  [D25], [`.to()` 的目标超出数值、指针或子类到父类的允许转换范围；`super.method(...)` 不在具有当前接收者的子类方法中，或目标方法在直接父类不可用；`super.init(...)` 出现在子类 `init` 之外。@sec-conversions、@sec-dispatch-super、@sec-class-init。],
  [D26], [`init` 返回类型不是当前类或存在同名重载；非 `init` 参数声明默认值，或默认值不是符合参数类型的 `ConstExpr`；默认参数之后出现必填参数；`init` 调用缺少必填参数、实参过多或跳过中间参数。@sec-func-decl、@sec-class-init。],
  [D27], [完整源文件缺少开头 `module` 声明；同一构建中模块存在冲突提供者；跨模块导入未导出声明；将 `export` 用于允许的模块级声明、类字段、方法、`init` 和外部 `impl` 之外。@sec-module-imports、@sec-class-decl。],
  [D28], [跨模块访问未导出的类成员（含字段读写、字段取地址、方法调用、方法取函数指针、`init`／`super` 调用、对未导出继承字段声明 `as` 约束，以及类构造时显式命名不可访问的继承字段）。@ch-classes[§]。],
  [D29], [`typedef` 构成纯别名环，或结构对象通过未经过显式指针的字段路径按值包含自身。@sec-struct-objects。],
  [D30], [内建运算的操作数不符合类型约束（移位两侧为不同内建整数类型本身合法）。@sec-ops。],
  [D31], [数值字面量的进制前缀或指数不完整，或包含对应进制不允许的数字（如 `0x`、`0b102`、`1e+`）。@sec-lex-tokens。],
  [D32], [到达文件结束时块注释（含嵌套块注释）仍未完全闭合。@sec-lex-comments。],
  [D33], [联合构造成员匹配失败：直接使用整数、字符串或布尔字面量时无相同字面量类型成员（禁止回退定型为基础类型），浮点字面量未显式转换，或已定型值无相同静态类型的成员。@sec-union-construct。],
)
