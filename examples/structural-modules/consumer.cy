module example_consumer;

// 名字、字段顺序和声明模块均不影响 typedef 结构对象的身份。
typedef Position = { y: i32, x: i32 };

export func sum_coordinates(Position point) -> i32 {
    return point.x + point.y;
}
