module examples.numbers;

func main() -> void {
    i8 minimum = -128;
    i64 wide = 1 + 2; // 两个未定型字面量均按期望 i64 定型
    i64 large = 3000000000.to(i64);
    u8 low = 300.to(u8); // 显式转换截取低位，不同于 u8 low = 300
    i8 signed_byte = 255.to(i8);
    u16 extended = signed_byte.to(u16);
    u8 byte = 255;
    i16 unsigned_extended = byte.to(i16);

    print minimum;           // -128
    print wide;              // 3
    print large;             // 3000000000
    print low;               // 44
    print signed_byte;       // -1
    print extended;          // 65535：先按源类型符号扩展
    print unsigned_extended; // 255：无符号源类型补零扩展

    u64 bits = 1;
    u8 shift = 3;
    print bits << shift; // 8：移位量可以使用不同整数类型
    print (0b1100 & 0b1010) | 1; // 9
    print 0b1100 ^ 0b1010;      // 6
    print ~0.to(u8);            // 255

    // 普通运行期整数运算回绕；编译期常量算术溢出则是错误。
    byte = byte + 1;
    print byte; // 0
    print 7 / 2; // 3
    print 7 % 2; // 1
    print 3.9.to(i32);       // 3
    print (-3.9).to(i32);    // -3
    print (-5.5 % 2.0) == -1.5; // true

    f64 zero = 0.0;
    f64 infinity = 1.0 / zero;
    f64 nan = zero / zero;
    print infinity > 1.0; // true
    print nan != nan;     // true
}
