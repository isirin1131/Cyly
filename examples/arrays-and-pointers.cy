func main() -> void {
    [4]i32 values = [1, 2, 3, 4];
    [4]i32 copied = values;
    copied[0] = 99;

    // Array assignment copies the whole value, so this still prints 1. / 数组赋值复制整块数组，因此这里仍打印 1。
    print values[0];

    [4]i32 zeros = [0; 4];
    print zeros.len;

    *[4]i32 array_pointer = &values;
    array_pointer.*[1] = 20;

    // Taking element zero explicitly produces *i32 instead of *[4]i32. / 显式获取首元素地址得到 *i32，而不是 *[4]i32。
    *i32 first = &values[0];
    first.* = 10;
    first[2] = 30;

    i32 index = 3;
    // Runtime indexing is unchecked; the author must guarantee a valid index. / 运行期下标不做越界检查；作者必须保证下标有效。
    print first[index];
}
