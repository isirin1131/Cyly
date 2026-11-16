# Cyly

[简体中文](README.md)

Cyly is a programming language built around the idea of “Yet Another A Better C”, with a focus on static typing, native compilation, explicit memory management, and predictable runtime costs.

Its central principle is that high-level features should cost about as much as hand-written C with equivalent functionality; unused features should add no runtime overhead.

## Core design

- **Explicit value semantics**: Structs, classes, and fixed-size arrays are copied on assignment and when passed by value. Fixed-size arrays never decay into pointers implicitly.
- **Explicit memory and pointers**: No built-in GC, ARC, or RAII, and no implicit heap allocation. Raw pointer operations require no `unsafe` block; lifetimes, bounds, and pointer validity are the author's responsibility.
- **Inline union values**: Unions use a type tag and an inline storage slot without implicit heap boxing. `typeof` queries the active member and `.as()` performs explicit reads, with no implicit type narrowing.
- **Compile-time static dispatch**: Inheritance and method overriding for classes and structs bind through the receiver's static type. Objects contain no implicit vtable pointer or runtime object header.
- **A small language core**: Contiguous memory views, dynamic arrays, and dynamic resource management belong to libraries. The built-in `string` is a separate read-only byte view.
- **Single-file modules and native toolchains**: Each source file is a module, and cross-module references require explicit imports. Compilation lowers through LLVM IR to standard object files and leaves linking to the system toolchain.

## Current status

The initial language design is complete, but a full compiler implementation has not begun. Early frontend code in the repository is exploratory rather than a usable language implementation, and the examples primarily describe the intended design.

## Documentation

- [Design decisions](DESIGN_DECISIONS.md): The authoritative record of the language's syntax, semantics, and runtime rules (in Chinese).
- [Example index](examples/README.md): Design examples organized by language feature (in Chinese, with bilingual code comments).
