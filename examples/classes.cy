module examples.classes;

class Counter {
    i32 value;

    func init(i32 value = 0) -> Counter {
        return { value: value };
    }

    func read(Counter self) -> i32 {
        return self.value;
    }
}

// 类外方法属于同一模块，与类内方法共同组成封闭的方法集合。
impl Counter.add(Counter self, i32 amount) -> Counter {
    return { value: self.value + amount };
}

// 修改原对象通过指针表达，避免把按值接收者的副本当作原对象。
func increment(*Counter counter) -> void {
    counter.*.value = counter.*.value + 1;
}

class Callback {
    *func(i32) -> i32 run;

    func init(*func(i32) -> i32 run) -> Callback {
        return { run: run };
    }
}

func twice(i32 value) -> i32 {
    return value * 2;
}

func main() -> void {
    Counter original = Counter.init();
    Counter changed = original.add(4);
    print original.read(); // 0
    print changed.read();  // 4
    increment(&original);
    print original.read(); // 1

    *func(Counter) -> i32 read = &Counter.read;
    print read(changed); // 4：函数指针调用显式传入接收者
    Callback callback = Callback.init(&twice);
    print callback.run(3); // 6：函数指针字段调用不注入接收者
}
