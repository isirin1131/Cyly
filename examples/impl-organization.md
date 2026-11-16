# 用 impl 按类型或按操作组织代码

Cyly 允许把一个类型的方法集中写在类内，也允许通过外部 `impl` 将同一操作对不同类型的实现放在一起。

下面用圆和矩形的面积、周长展示这种自由：

| 类型（行） | 面积（列） | 周长（列） |
| --- | --- | --- |
| `Circle` | `Circle.area` | `Circle.perimeter` |
| `Rect` | `Rect.area` | `Rect.perimeter` |

两版是替代写法，每一版都完整提供这四个实现，不能将两版重复加入同一个程序。

本文是语言设计示例，采用 `class`、`impl Type.method` 和显式 `self` 写法；当前编译器尚未实现这些能力。示例采用单文件模块：每个类型的定义及其外部 `impl` 均位于同一源文件，不能跨文件为外部类型追加方法。

## 按行：围绕一种类型组织

阅读 `Circle` 时，就能看到圆的数据和两项操作；矩形也一样。

```cy
class Circle {
    f64 radius;

    func area(Circle self) -> f64 {
        return 3.141592653589793 * self.radius * self.radius;
    }

    func perimeter(Circle self) -> f64 {
        return 2.0 * 3.141592653589793 * self.radius;
    }
}

class Rect {
    f64 width;
    f64 height;

    func area(Rect self) -> f64 {
        return self.width * self.height;
    }

    func perimeter(Rect self) -> f64 {
        return 2.0 * (self.width + self.height);
    }
}
```

这种排列方便新增形状：定义新类，并集中写出它支持的操作。已有圆和矩形的代码不用挪动。

## 按列：围绕一种操作组织

先定义数据，再把所有面积实现放在一起，所有周长实现放在一起。

```cy
class Circle {
    f64 radius;
}

class Rect {
    f64 width;
    f64 height;
}

// Area / 面积
impl Circle.area(Circle self) -> f64 {
    return 3.141592653589793 * self.radius * self.radius;
}

impl Rect.area(Rect self) -> f64 {
    return self.width * self.height;
}

// Perimeter / 周长
impl Circle.perimeter(Circle self) -> f64 {
    return 2.0 * 3.141592653589793 * self.radius;
}

impl Rect.perimeter(Rect self) -> f64 {
    return 2.0 * (self.width + self.height);
}
```

这四个方法与上一版具有相同的参数、返回类型和函数体。例如，半径为 3 的圆在两版中都通过 `circle.area()` 求面积；宽 4、高 5 的矩形都通过 `rect.perimeter()` 得到周长 18。

这种排列方便新增操作：例如添加 `describe` 时，可以在同一源文件中把各种形状的描述实现集中写成一组外部 `impl`，无需修改已有类型的定义本身。

## 可以混合组织，也可以只调整 impl 的排列

类型内部可以保留面积方法，把周长方法集中放在同一源文件的外部 `impl` 中。已有方法要移到外部实现时，应移除原方法体，避免重复定义。

外部 `impl` 本身也可以按行排列：先写 `Circle.area`、`Circle.perimeter`，再写 `Rect.area`、`Rect.perimeter`。按行或按列是组织代码的选择，不要求一个项目统一采用其中一种。

## 外部方法同样参与继承

在任意一版后增加：

```cy
class NamedCircle extends Circle {
    string name;
}
```

`NamedCircle` 都会继承 `area` 和 `perimeter`。方法写在父类内部还是通过外部 `impl` 定义，不改变这一点。

如果需要覆写继承的方法，应写在子类定义内；外部 `impl` 只追加尚无实现的方法。因此，这种组织自由适用于新增方法，不能用移动代码的位置绕过覆写限制。

继承与方法覆写统一采用编译期静态分派，调用仅根据接收者表达式的静态类型绑定目标函数；需要运行期多态时，应使用联合类型或显式函数指针。
