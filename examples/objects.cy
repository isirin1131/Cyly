module examples.objects;

typedef Point = { x: i32, y: i32 };
typedef SamePoint = { y: i32, x: i32 };
typedef Node = { value: i64, next: *Node | null };

func sum_nodes(*Node node) -> i64 {
    i64 total = 0;
    while (true) {
        total = total + node.*.value;
        if (typeof(node.*.next) == null) break;
        node = node.*.next.as(*Node);
    }
    return total;
}

func main() -> void {
    Point original = { y: 2, x: 1 };
    SamePoint copy = original; // 透明别名，字段顺序不改变类型身份
    copy.x = 9;
    print original.x; // 1：对象按值复制
    print copy.x;     // 9

    Node tail = { value: 20, next: null };
    Node head = { next: &tail, value: 10 };
    Node shallow = head;
    shallow.value = 100;
    // 指针字段只复制地址；尾节点仍为同一个对象。
    shallow.next.as(*Node).*.value = 30;
    print sum_nodes(&head); // 40
    // 所有节点在 main 返回前都存活，指针不逃逸。
}
