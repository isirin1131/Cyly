module examples.unions;

typedef Number = i32 | f32;
typedef SameNumber = f32 | i32 | i32;
typedef Status = 200 | 404;
typedef User = { kind: "user", id: i32 };
typedef Order = { kind: "order", id: i32 };
typedef Item = User | Order;

func main() -> void {
    Number number = 3.to(i32); // 联合中的基础数值成员须显式定型
    SameNumber same = number; // 联合展平、去重，成员顺序不影响身份
    print typeof(number) == typeof(same); // true
    if (typeof(number) == i32) {
        print number.as(i32); // 3：测试不收窄静态类型，仍须显式读取
    }
    number = 1.5.to(f32);
    print number.as(f32) == 1.5; // true

    Status status = 0xC8; // 数学值 200，匹配字面量类型 200
    print typeof(status) == 200; // true
    "ok" | string message = "ok";
    print typeof(message) == "ok"; // true
    string text = "ok";
    message = text;
    print typeof(message) == string; // true：按静态类型选成员

    // 两种结构通过不同字面量字段保持不同身份。
    User user = { kind: "user", id: 7 };
    Item item = user;
    if (typeof(item) == User) print item.as(User).id; // 7

    i32 value = 9;
    *i32 pointer = &value;
    *i32 | null optional = pointer;
    print typeof(optional) == typeof(pointer); // true
    optional.as(*i32).* = 10;
    print value; // 10
    optional = null;
    print typeof(optional) == null; // true
}
