# 类型与操作双向扩展：现有先例

检索日期：2026-11-09。用于第 19、20 条议题的讨论；以下是资料与评估，不是已定语言规则。

## 先分清要解决的事情

- 行代表数据种类，列代表操作，格子代表一种具体实现。
- 阅读与书写：是否可以把同一类型、同一操作的实现分别集中展示和编写。
- 扩展：是否可以新增格子而不改已有定义。
- 调用：如何根据输入选择实现，哪些选择在编译时完成。
- 组合：来自不同模块的实现如何汇总，重叠或缺失如何处理。

普通静态重载解决不了所有运行时分发问题；编辑器视图也不会自动产生分发语义。闭合联合可以包含运行时才确定的成员；“编译时已知所有成员”不等于“编译时已知这次具体是哪一成员”。

## 上轮六个设想的先例

| 设想 | 接近的已有机制 | 对应范围与限制 |
| --- | --- | --- |
| 同一代码按行、按列编辑 | JetBrains MPS 的多投影编辑 | 同一模型可以有文本、表格等不同编辑器；MPS 是语言工作台，不是自动适用于任意源码的转置插件。 |
| 独立实现关联类型与操作 | Common Lisp CLOS、Clojure protocols、Rust trait impl、Haskell instance | 都能将实现置于数据定义之外；分发、作用域、实例冲突和静态检查规则各不相同。 |
| 分散定义后显式组装 | Haskell Data Types à la Carte、Zig comptime；Racket units 提供模块连接先例 | 前两者涉及泛型或类型组合；units 说明连接可显式表达，但不能当作 Cyly 编译时闭合类型族的现成实现。 |
| 同一数据使用不同操作表 | 显式传入函数记录、策略对象、Zig 风格函数指针表 | 可以由普通数据结构表达；Rust/Haskell 默认实例通常不能让相同类型与协议拥有任意多个可隐式选择的实现。 |
| 允许矩阵留空 | 独立 trait / type class / protocol，分别规定适用对象 | 不要求所有对象支持所有操作；调用不存在能力的对象仍须报错、限制输入或显式处理。 |
| 自动切换按类型与按操作的组织 | Decomposition Diversity with Symmetric Data and Codata，POPL 2020 | 提供对称研究语言、保持类型与行为的双向转换及 IDE 原型；不意味着任意 C 风格程序可无条件转换。 |

来源：[MPS 多投影](https://www.jetbrains.com/help/mps/editor-cookbook.html)、[Racket units](https://docs.racket-lang.org/guide/Linking_Units.html)、[POPL 2020 论文及原型介绍](https://popl20.sigplan.org/details/POPL-2020-Research-Papers/57/Decomposition-Diversity-with-Symmetric-Data-and-Codata)。其余机制的来源见下文。

## Java

**按行。** 定义接口或基类，各具体类实现固定操作。新增对象种类时，添加一个实现类即可。调用经接口选择具体实现。

**按列。** 经典 Visitor 预留 accept 协议，操作集中在访问者中。另一条直接路线是 sealed 类型层次配合模式 switch：操作位于外部方法中，各分支处理一种对象。Java 21 已正式支持这种 switch，无须为了按列组织而总是引入 Visitor。

**边界。** Visitor 新增对象种类时需要扩充访问协议；sealed 集合新增成员时需要修改相应声明并检查有关 switch。不能仅凭在外部另写一个方法，就让已有类成为一个新接口的实现类。

来源：[接口](https://docs.oracle.com/javase/tutorial/java/IandI/interfaceDef.html)、[模式 switch](https://docs.oracle.com/en/java/javase/21/language/pattern-matching-switch.html)、[Visitor](https://web.mit.edu/6.102/www/sp25/classes/19-little-languages/)。

## C++

**按行。** 抽象基类与虚函数，让新类实现一组固定操作。

**按列。** std::variant 列出具体种类，std::visit 执行外部操作。也能使用经典 Visitor。

**独立填格子。** 普通非成员重载函数可以写在类型之外，例如 area(Circle)、area(Rect)。模板与 concepts 可表达对这些操作的要求；ADL 根据实参类型的关联命名空间寻找函数。

**边界。** 普通重载根据静态类型选择：拿到 Shape& 不会自动选 area(Circle)。运行时异构值需要虚调用、variant 访问或其他显式分发。variant 的成员集合固定；新增候选也受名字查找及模板规则约束，不能视为随处注册的动态方法。Concepts 不会自动生成运行时接口或函数表。

来源：[虚函数](https://eel.is/c++draft/class.virtual)、[variant 访问](https://eel.is/c++draft/variant.visit)、[模板约束](https://eel.is/c++draft/temp.constr)、[ADL](https://eel.is/c++draft/basic.lookup.argdep)。

## Haskell

**按列。** 代数数据类型列出分支，独立函数使用模式匹配。增加操作很直接，新增分支需要检查原有处理函数。

**按行或独立填格子。** type class 声明能力，instance 在数据定义之外提供实现。新增类型后可提供旧能力的实例；新增能力后可为旧类型提供实例。

```haskell
class Area a where
  area :: a -> Double

instance Area Circle where
  area (Circle r) = pi * r * r

instance Area Rect where
  area (Rect w h) = w * h
```

此处 class 是能力约定，不是创建实例对象的类。普通类型类用法中，一个类型对应一个能力的实现需保持一致；需要替代行为时可以使用包装类型或显式函数记录。

**边界。** 能分别处理不同类型，不等于这些值能自动混装进同一种运行时容器。存在类型包装可以隐藏具体类型并保留指定能力，但包装后并不能凭空增加未保留的操作。递归且可扩展的 AST 还需要处理子节点表示。

Data Types à la Carte 把节点种类做成可组合部分；tagless-final 将表达式写成可交给不同解释器的构造过程。两者都支持进一步扩展，但要求特定表示和泛型等机制。

来源：[Haskell 类型与类型类](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html)、[GHC 存在类型](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/existential_quantification.html)、[Data Types à la Carte](https://fstar-lang.org/tutorial/book/part3/part3_alacarte.html)、[tagless-final 作者教程](https://okmij.org/ftp/tagless-final/course/)。

## Zig

**按列。** union(enum) 配合外部函数中的 switch。

**按行。** 编译时可用 anytype / comptime 接受满足所需操作的类型；运行时可以显式组织数据指针和函数指针表。

标准库 Allocator 就包含 ptr: *anyopaque 和 vtable: *const VTable，调用时取出函数指针并传入数据指针。不同分配器提供相同约定的一组实现。

**边界。** comptime 和 anytype 在这里承担泛型与编译期特化功能，不能理解为 Zig 不需要泛型。显式函数表不自动解决生命周期、数据指针与函数表的配对或新增操作的问题；扩展表结构也会影响接口。Zig 也允许结构体内部声明函数。

来源：[Zig 语言参考：tagged union、函数、comptime](https://ziglang.org/documentation/master/)、[Allocator 源码](https://raw.githubusercontent.com/ziglang/zig/master/lib/std/mem/Allocator.zig)。master 为滚动文档；这里只比较这些机制，不依赖具体最新版本号。

## Rust

**按列。** enum 列出数据种类，独立函数使用 match。

**独立填格子。** trait 定义能力，impl Trait for Type 提供实现。实现代码本来就位于 struct 定义之外。

```rust
trait Area { fn area(&self) -> f32; }
trait Draw { fn draw(&self); }

impl Area for Circle { /* ... */ }
impl Draw for Circle { /* ... */ }
impl Area for Rect   { /* ... */ }
impl Draw for Rect   { /* ... */ }
```

这四个实现块可以按类型或按能力集中摆放。trait 可以包含多个操作，此时一个格子更准确地说是一组操作的实现。

**调用。** 泛型调用通常按具体类型生成代码；&dyn Trait 等 trait object 使用数据指针和虚方法表进行动态分发。

**边界。** 简化说，trait 或被实现的类型至少有一方必须属于当前 crate，并且实现不得重叠。不能随意给两个外部库的 trait 和类型建立第三方实现；可用本地包装类型等方式适配。已变成 dyn Area 的值，不会因为底层类型后来实现 Draw，就自动获得任意恢复 Draw 的能力。对象可携带的能力由接口确定。

来源：[实现与孤儿规则](https://doc.rust-lang.org/reference/items/implementations.html)、[trait objects](https://doc.rust-lang.org/reference/types/trait-object.html)、[enum 与 match](https://doc.rust-lang.org/book/ch06-02-match.html)。

## Lisp：Common Lisp 与 Clojure

Lisp 是语言家族，不能用同一套对象系统概括所有方言。

**Common Lisp CLOS。** defclass 定义数据，defgeneric 定义操作，defmethod 在类外增加针对参数类别的实现。

```lisp
(defclass circle ()
  ((radius :initarg :radius :reader radius)))
(defclass rectangle ()
  ((width :initarg :width :reader rect-width)
   (height :initarg :height :reader rect-height)))

(defgeneric area (shape))
(defmethod area ((c circle))
  (* pi (radius c) (radius c)))
(defmethod area ((r rectangle))
  (* (rect-width r) (rect-height r)))
```

新增类型可增加旧操作的方法；新增操作可对旧类型增加方法。方法能根据多个必需参数的类别或特定对象选择。generic function 在这里指包含多个方法的操作，不等同于 Cyly 之前讨论的参数化泛型。

CLOS 的动态开放性和方法组合需要运行时语义；没有适用方法时默认报错。它不要求所有可能的对象与操作组合在编译前补齐。

来源：[generic functions](https://www.lispworks.com/documentation/HyperSpec/Body/07_fa.htm)、[defmethod](https://www.lispworks.com/documentation/HyperSpec/Body/m_defmet.htm)、[无适用方法](https://www.lispworks.com/documentation/HyperSpec/Body/f_no_app.htm)。

**Clojure protocols。** extend-type 集中为一个类型实现多个协议，extend-protocol 集中为一个协议实现多个类型，底层都可以归结到 extend。extend 甚至直接接受“协议方法名 → 普通函数”的映射，与显式关联表很接近。

以下两段展示替代的组织形式，不要求重复定义同一实现：

```clojure
; 按行：一个类型的多种能力
(extend-type Circle
  Area (area [c] ...)
  Draw (draw [c] ...))

; 按列：一种能力的多个类型实现
(extend-protocol Area
  Circle (area [c] ...)
  Rect   (area [r] ...))
```

协议可以包含多个方法；这时“列”是一组操作。上述宏省略了类型与协议声明以及方法正文。协议按首个参数类型分发；multimethod 还可由显式函数计算分发键。独立扩展可能发生冲突，官方建议库代码不要同时扩展不属于自己的类型和协议。

来源：[protocols 与 extend](https://clojure.org/reference/protocols)、[extend-protocol / extend-type](https://clojure.github.io/clojure/clojure.core-api.html#clojure.core/extend-protocol)、[multimethods](https://clojure.org/reference/multimethods)。

## 对 Cyly 最直接的启发

1. Clojure 是“同一机制既能按行写，也能按列写”的直接先例；研究其组织方式不意味着采用其动态运行时。
2. Rust 说明类型外的能力实现可以静态检查，但必须考虑第三方扩展冲突和运行时接口能保留哪些能力。
3. Zig 的显式函数表提供接近 C 的运行时实现参照；生成这些表能减少手写连接代码，却不会消除真实的间接调用或数据寿命要求。
4. POPL 2020 的对称语言与 IDE 比单纯调整文件排列更接近“转置程序”的设想，但适用语言规则需要专门设计。
5. Cyly 的透明别名和结构兼容仍然有效；不能只因外部能力实现方便，就把别名当作独立分发身份。
6. 选择哪个模型、是否新增协议或分发表语法、怎样处理缺失与重复实现，仍需讨论。现有资料不能替代这些决策。
