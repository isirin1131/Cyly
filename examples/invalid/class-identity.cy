module examples.invalid.class_identity;

class Ready {
    func init() -> Ready { return {}; }
}

class Closed {
    func init() -> Closed { return {}; }
}

func main() -> void {
    Ready ready = Ready.init();
    Closed closed = ready; // 预期编译错误：不同类声明不因无字段而合并
}
