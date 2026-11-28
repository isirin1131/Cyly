module examples.ast;

// 结构身份包含 kind 字段的字面量类型，Add 与 Multiply 不会合并。
typedef Integer = { kind: "integer", value: i64 };
typedef Add = { kind: "add", left: *Expr, right: *Expr };
typedef Multiply = { kind: "multiply", left: *Expr, right: *Expr };
typedef Expr = Integer | Add | Multiply;

func evaluate(*Expr expression) -> i64 {
    if (typeof(expression.*) == Integer) {
        return expression.*.as(Integer).value;
    }
    if (typeof(expression.*) == Add) {
        Add node = expression.*.as(Add);
        return evaluate(node.left) + evaluate(node.right);
    }
    if (typeof(expression.*) == Multiply) {
        Multiply node = expression.*.as(Multiply);
        return evaluate(node.left) * evaluate(node.right);
    }
    // 语言不做联合穷尽检查；显式提供剩余路径的返回值。
    return 0;
}

func main() -> void {
    Integer two = { kind: "integer", value: 2 };
    Integer three = { kind: "integer", value: 3 };
    Integer four = { kind: "integer", value: 4 };
    Expr left = two;
    Expr middle = three;
    Expr right = four;
    Multiply product = { kind: "multiply", left: &middle, right: &right };
    Expr nested = product;
    Add sum = { kind: "add", left: &left, right: &nested };
    Expr root = sum;
    print evaluate(&root); // 14：2 + 3 * 4
    // 所有节点都在当前栈帧中存活；实际前端可由库提供 Arena。
}
