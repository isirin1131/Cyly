module examples.empty_classes;

class Ready {
    func init() -> Ready {
        return {}; // 无字段类仍须显式构造
    }
}

class Closed {
    func init() -> Closed {
        return {};
    }
}

class Marker {} // 空类体合法，不自动生成 init

// 外部 impl 属于 Marker 自身方法，允许构造当前类。
impl Marker.copy(Marker self) -> Marker {
    return {};
}

class Marked extends Marker {
    func init() -> Marked {
        return {}; // 包括继承字段在内都没有字段
    }
}

func main() -> void {
    Ready ready = Ready.init();
    Closed closed = Closed.init();
    *Ready | *Closed state = &ready;
    print typeof(state) == *Ready; // true
    state = &closed;
    print typeof(state) == *Closed; // true：不同类声明不会结构合并

    Marked marked = Marked.init();
    Marker marker = marked.to(Marker); // 显式复制父类子对象
    Marker copy = marker.copy();
    // 无字段类实例不直接 print，也不依赖其地址是否相同。
}
