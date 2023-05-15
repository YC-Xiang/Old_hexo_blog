# Rust 语言基础学习

## 1.2

1. `Even Better TOML`，支持 .toml 文件完整特性
2. `Error Lens`, 更好的获得错误展示
3. `One Dark Pro`, 非常好看的 VSCode 主题
4. `CodeLLDB`, Debugger 程序

## 1.3

`cargo new hello_world`

`tree`

`cargo run` is equal to `cargo build` + `./target/debug/world_hello` 默认的是debug模式，编译器不会做任何的优化，编译速度快，运行慢。



高性能模式，生产发布模式：

`cargo run --release`

`cargo build --release`

`cargo check` 检查编译能否通过



`cargo.toml` **项目数据描述文件**

`cargo.lock` **项目依赖详细清单**



在cargo.toml中定义依赖的三种方式：

```rust
[dependencies]
rand = "0.3"
hammer = { version = "0.5.0"}
color = { git = "https://github.com/bjz/color-rs" }
geometry = { path = "crates/geometry" }

```

