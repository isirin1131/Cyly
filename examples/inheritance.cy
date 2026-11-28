module examples.inheritance;

class Parent {
    i32 value;

    func init(i32 value = 10) -> Parent {
        return { value: value };
    }

    func score(Parent self) -> i32 {
        return self.value;
    }
}

class Child extends Parent {
    i32 bonus;

    func init(i32 value = 10, i32 bonus = 1) -> Child {
        return super.init(value) { bonus: bonus };
    }

    func score(Child self) -> i32 {
        return super.score() + self.bonus;
    }
}

func main() -> void {
    Child child = Child.init();
    Parent parent = child.to(Parent);
    print child.score();  // 11：静态绑定 Child.score
    print parent.score(); // 10：静态绑定 Parent.score

    *Parent view = (&child).to(*Parent);
    view.*.value = 20; // 父类前缀直接引用原对象
    print child.score();  // 21
    print view.*.score();  // 20：父类指针不会动态分派到子类
    print parent.score(); // 10：按值转换得到的副本未改变
}
