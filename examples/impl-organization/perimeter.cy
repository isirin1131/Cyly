module example_shapes;

export impl Rect.perimeter(Rect self) -> i32 {
    return 2 * (self.width + self.height);
}

export impl Square.perimeter(Square self) -> i32 {
    return 4 * self.side;
}
