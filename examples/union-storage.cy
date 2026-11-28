module examples.union_storage;

func main() -> void {
    // .as() 可读取非当前成员，不检查运行期标签。
    u8 | bool value = 2.to(u8);
    bool flag = value.as(bool); // 非零字节均读作 true，不只看最低位
    print flag; // true
    print typeof(value) == u8; // true：读取没有改写标签
    print value.as(u8); // 2：读取没有改写字节
    value = flag;
    print value.as(u8); // 1：写入 bool 使用规范编码

    // 从较大成员改写为较小成员，存储槽尾部清零。
    // 用全零值避免依赖目标端序；此处不假设标签位于何处。
    u64 | u8 storage = 0xFFFFFFFFFFFFFFFF.to(u64);
    storage = 0.to(u8);
    print storage.as(u64); // 0
    print typeof(storage) == u8; // true
}
