module example_shapes;

// 按操作组织同模块不同类的方法；可访问未导出的字段。
export impl Rect.area(Rect self) -> i32 {
    return self.width * self.height;
}

export impl Square.area(Square self) -> i32 {
    return self.side * self.side;
}
