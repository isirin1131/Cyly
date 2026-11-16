class Node {
    i32 id;
}

type IntOrFloat = i32 | f32;

// The pointer constructor binds more tightly than the union operator. / 指针类型构造符的结合优先级高于联合类型运算符。
type NodePointer = *Node | null;

func main() -> void {
    f32 number = 1.0;
    IntOrFloat value = number;

    f32 original = value.as(f32);

    // No member check: reinterpret the f32 storage as i32 bits. / 不进行成员匹配检查：将 f32 存储按 i32 比特重新解释。
    i32 bits = value.as(i32);

    print original;
    print bits;

    NodePointer missing = null;

    // typeof(value) queries the current member without narrowing the static type. / typeof(value) 查询当前成员类型，但不缩窄表达式的静态类型。
}
