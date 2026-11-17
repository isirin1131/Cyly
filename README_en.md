# Cyly

[简体中文](README.md)

Cyly is a statically typed, natively compiled programming language. It preserves C's direct control over memory layout and runtime cost while adding general union types, single-file modules, inheritance, and exceptions—without depending on implicit heap allocation, runtime object headers, or automatic resource management.

Cyly cares more about what a program actually does than about how many details its syntax can hide. When values are copied, who releases memory, which function a method call binds to, and how a union value is read all follow explicit rules. The compiler does as much work as possible at compile time, while the author retains direct control over runtime behavior.

## Core design

- **Value semantics and predictable layout**: Class objects and fixed-size arrays are copied on assignment and when passed by value. Objects contain only fields and alignment padding, and fixed-size arrays never decay into pointers implicitly.
- **Explicit memory and pointers**: No built-in GC, ARC, or RAII, and no implicit heap allocation. Raw pointer operations require no `unsafe` block; lifetimes, bounds, and pointer validity are the author's responsibility.
- **Inline unions and bit reinterpretation**: Unions use a type tag and inline storage without implicit heap boxing. `typeof` queries the active member, `.as()` reads explicitly as a target type, and optimization does not rely on type-based strict aliasing assumptions.
- **Static dispatch and explicit polymorphism**: Inheritance and method overriding bind through the receiver's static type, with no implicit vtable pointer. Runtime polymorphism is expressed through unions or explicit function pointers.
- **A small language core**: Contiguous memory views, dynamic arrays, arenas, and reference-counted containers belong to libraries. The built-in `string` is a separate read-only byte view.
- **Single-file modules and native toolchains**: Cross-module references require explicit, non-transitive imports. Compilation lowers through LLVM IR to standard object files and leaves linking to the system toolchain.

## Example tour

The [`examples/`](examples/README.md) directory explores these decisions by topic, with bilingual Chinese-English code comments. The examples describe the intended language rather than the current implementation status.

- [Arrays and pointers](examples/arrays-and-pointers.cy): Array copies, array pointers versus first-element pointers, and indexing without runtime bounds checks.
- [Unions](examples/unions.cy): How `.as()` reads union storage as a target type, and how pointer constructors bind within union types.
- [Named control flow](examples/control-flow.cy): Cross-level `continue` and `break` from a named `if`.
- [Explicit memory and exceptions](examples/memory-and-exceptions.md): Arena lifetimes, exceptions passed by value, and explicit cleanup on normal and exceptional paths.
- [Method organization and static dispatch](examples/impl-organization.md): Comparing in-type methods with same-file external `impl` blocks, including inheritance and static binding.

See the [example index](examples/README.md) for the complete set, including strings and modules.

## Current status

The initial language design is complete, but a full compiler implementation has not begun. Early frontend code in the repository is exploratory rather than a usable language implementation.

## Design document

[DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) is the authoritative record of the language's syntax, semantics, and runtime rules (in Chinese).

The [language specification draft](docs/language-spec.typ) (in Chinese) expands the same chapter structure into EBNF, static constraints, runtime semantics, diagnostics, and examples. It distinguishes settled rules, proposed additions, and implementation conventions. Run `make docs` with Typst and Chinese fonts installed to render the [PDF](output/pdf/cyly-language-spec.pdf); build notes are included at the end of the specification.
