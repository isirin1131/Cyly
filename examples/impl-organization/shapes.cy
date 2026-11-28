module example_shapes;

export class Rect {
    i32 width;
    i32 height;

    export func init(i32 width, i32 height = 1) -> Rect {
        return { width: width, height: height };
    }
}

export class Square {
    i32 side;

    export func init(i32 side) -> Square {
        return { side: side };
    }
}
