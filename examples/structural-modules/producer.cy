module example_producer;

typedef Point = { x: i32, y: i32 };

export func make_point() -> Point {
    return { x: 3, y: 4 };
}
