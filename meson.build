project('Cyly', 'c',
  version: '0.1.0',
  default_options: ['c_std=c11', 'warning_level=3'])

src_inc = include_directories('src')

# 前端核心（不含 main），供 cyly 可执行文件和测试共用
cyly_core = static_library('cyly_core',
  'src/scanner.c',
  'src/source.c',
  include_directories: src_inc)

executable('cyly', 'src/main.c',
  link_with: cyly_core,
  include_directories: src_inc)

test('scanner', executable('scanner_test', 'tests/scanner_test.c',
  link_with: cyly_core,
  include_directories: src_inc))

# reference/ 下是参考资料（LLVM Kaleidoscope 教程），不参与构建。
