func bytes_equal(string left, string right) -> bool {
    // The operator compares byte content even when views use different storage. / 即使两个视图使用不同存储，== 仍按字节内容比较。
    return left == right;
}

func main() -> void {
    string first = "A\0B";
    string second = "A\0C";

    // Bytes after NUL participate, so this prints false. / NUL 后的字节也参与比较，因此这里打印 false。
    print bytes_equal(first, second);

    // String views are read-only and indexing yields one byte. / 字符串视图只读，下标读取得到一个字节。
    print first[0];

    i32 index = 2;
    // Runtime string indexing is unchecked; byte index 2 is valid here. / 字符串运行期下标不做越界检查；此处的字节下标 2 有效。
    print first[index];
}
