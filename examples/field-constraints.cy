module examples.field_constraints;

class Entity {
    string kind;
    i32 | null value;

    func init() -> Entity {
        return { kind: "entity", value: null };
    }
}

class User extends Entity {
    kind as "user";
    value as i32;

    func init(i32 value) -> User {
        // 当前类约束过的继承字段必须显式覆盖父类的初值。
        return super.init() { kind: "user", value: value };
    }
}

func main() -> void {
    User user = User.init(7);
    print user.kind; // user，读取仍为 string
    print user.value.as(i32); // 7：仍需显式读取联合成员
    i32 | null copy = user.value; // 保持原始宽联合静态类型
    print typeof(copy) == i32; // true
    user.value = 8.to(i32);

    // 普通字段指针不携带子类访问约束。
    *(i32 | null) slot = &user.value;
    slot.* = null;
    print typeof(user.value) == null; // true：读取真实标签
    // 重新写入 i32 后再按该成员读取。
    slot.* = 9.to(i32);
    print user.value.as(i32); // 9
}
