---
title: Rust
date: 2023-05-20 17:39:28
tags:
- Rust
categories:
- Book
---

## 1.2

1. `Even Better TOML`，支持 .toml 文件完整特性
2. `Error Lens`, 更好的获得错误展示
3. `One Dark Pro`, 非常好看的 VSCode 主题
4. `CodeLLDB`, Debugger 程序

## 1.3 Cargo

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

# 2. Rust 基础入门

## 2.1 变量绑定与解构

### 变量绑定与可变性

变量只有初始化之后才能使用。如下会报错。

```rust
fn main() {
    let x: i32; // 未初始化，但被使用
    println!("x is equal to {}", x); 
}
```



### 使用下划线开头忽略未使用的变量

如果你创建了一个变量却不在任何地方使用它，Rust 通常会给你一个警告，因为这可能会是个 BUG。

`let _x = 5; `

### 变量解构

`let (a, mut b): (bool,bool) = (true, false); // a = true,不可变; b = false，可变`

### 解构式赋值

### 常量

- 常量不允许使用 `mut`，**常量不仅仅默认不可变，而且自始至终不可变**。
- 常量使用 `const` 关键字而不是 `let` 关键字来声明，并且值的类型**必须**标注。

Rust 常量的命名约定是全部字母都使用大写，并使用下划线分隔单词，另外对数字字面量可插入下划线以提高可读性。

`const MAX_POINTS: u32 = 100_000;`

### 变量遮蔽

```rust
let x = 5;
let x = x + 1;
```

这和 `mut` 变量的使用是不同的，第二个 `let` 生成了完全不同的新变量，两个变量只是恰好拥有同样的名称，涉及一次内存对象的再分配 ，而 `mut` 声明的变量，可以修改同一个内存地址上的值，并不会发生内存对象的再分配，性能要更好。

## 2.2 基本类型

- 数值类型: 有符号整数 (`i8`, `i16`, `i32`, `i64`, `isize`)、 无符号整数 (`u8`, `u16`, `u32`, `u64`, `usize`) 、浮点数 (`f32`, `f64`)、以及有理数、复数
- 字符串：字符串字面量和字符串切片 `&str`
- 布尔类型： `true`和`false`
- 字符类型: `char`表示单个 Unicode 字符，存储为 4 个字节
- 单元类型: 即 `()` ，其唯一的值也是 `()`

### 2.2.1 数值类型

#### 整数类型

要显式处理可能的溢出，可以使用标准库针对原始数字类型提供的这些方法：

- 使用 `wrapping_*` 方法在所有模式下都按照补码循环溢出规则处理，例如 `wrapping_add`
- 如果使用 `checked_*` 方法时发生溢出，则返回 `None` 值
- 使用 `overflowing_*` 方法返回该值和一个指示是否存在溢出的布尔值
- 使用 `saturating_*` 方法使值达到最小值或最大值

下面是一个演示`wrapping_*`方法的示例：

```rust
fn main() {
    let a : u8 = 255;
    let b = a.wrapping_add(20);
    println!("{}", b);  // 19
}
```

#### 浮点类型

为了避免上面说的两个陷阱，你需要遵守以下准则：

- 避免在浮点数上测试相等性
- 当结果在数学上可能存在未定义时，需要格外的小心

#### NaN

所有跟 `NaN` 交互的操作，都会返回一个 `NaN`

#### 数字运算

只有同样类型，才能运算。

#### 序列

生成连续的数值，例如 `1..5`，生成从 1 到 4 的连续数字，不包含 5 ；`1..=5`，生成从 1 到 5 的连续数字，包含 5。常常用于循环中：

序列只允许用于数字或字符类型。

```rust
fn main() {
for i in 1..=5 {
    println!("{}",i);
}

fn main() {
for i in 'a'..='z' {
    println!("{}",i);
}

```

#### 总结

**类型转换必须是显式的**. Rust 永远也不会偷偷把你的 16bit 整数转换成 32bit 整数。

### 2.2.2 字符、布尔、单元类型

Rust 的字符不仅仅是 `ASCII`，所有的 `Unicode` 值都可以作为 Rust 字符。

字符类型`char`占用 4 个字节。

单元类型就是 `()` 。完全**不占用**任何内存。

### 2.2.3 语句和表达式

**表达式不能包含分号**，表达式如果不返回任何值，会隐式地返回一个 `()`

### 2.2.4 函数

当用 `!` 作函数返回类型的时候，表示该函数永不返回( diverge function )。

```rust
fn dead_end() -> ! {
  panic!("你已经到了穷途末路，崩溃吧！");
}
```

## 2.3 所有权和借用

### 2.3.1 所有权

1. Rust 中每一个值都被一个变量所拥有，该变量被称为值的所有者
2. 一个值同时只能被一个变量所拥有，或者说一个值只能拥有一个所有者
3. 当所有者(变量)离开作用域范围时，这个值将被丢弃(drop)

```rust
// 由于 Rust 禁止你使用无效的引用，错误
fn main() {
let s1 = String::from("hello");
let s2 = s1;

println!("{}, world!", s1);
}


// 不报错，这个例子中，`x` 只是引用了存储在二进制中的字符串 `"hello, world"`，并没有持有所有权。
fn main() {
    let x: &str = "hello, world";
    let y = x;
    println!("{},{}",x,y);
}

// Rust 有一个叫做 Copy 的特征，可以用在类似整型这样在栈中存储的类型。如果一个类型拥有 Copy 特征，一个旧的变量在被赋值给其他变量后仍然可用。
fn main() {
    let x: &str = "hello, world";
    let y = x;
    println!("{},{}",x,y);
}

```

#### 深拷贝

`clone`

```rust
fn main() {
let s1 = String::from("hello");
let s2 = s1.clone();

println!("s1 = {}, s2 = {}", s1, s2);
}
```

**任何基本类型的组合可以 `Copy` ，不需要分配内存或某种形式资源的类型是可以 `Copy` 的**。

- 所有整数类型，比如 `u32`
- 布尔类型，`bool`，它的值是 `true` 和 `false`
- 所有浮点数类型，比如 `f64`
- 字符类型，`char`
- 元组，当且仅当其包含的类型也都是 `Copy` 的时候。比如，`(i32, i32)` 是 `Copy` 的，但 `(i32, String)` 就不是
- 不可变引用 `&T` ，例如转移所有权中的最后一个例子&str，**但是注意: 可变引用 `&mut T` 是不可以 Copy的**