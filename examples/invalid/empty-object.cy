module examples.invalid.empty_object;

typedef Empty = {}; // 预期编译错误 D22：结构对象至少一个字段
// class Empty {} 则合法；不能将结构对象限制推广到类。

func main() -> void {}
