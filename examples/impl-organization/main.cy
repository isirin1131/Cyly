module examples.impl_organization;
import { Rect, Square } from example_shapes;

func main() -> void {
    Rect rect = Rect.init(4, 5);
    Square square = Square.init(3);
    print rect.area();        // 20
    print rect.perimeter();   // 18
    print square.area();      // 9
    print square.perimeter(); // 12
    // 导入类后可使用其导出成员，无需单独导入方法。
    // export class 不自动导出字段；这里不能读取 rect.width。
}
