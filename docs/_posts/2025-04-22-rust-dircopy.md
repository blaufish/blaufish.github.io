---
layout: post
title:  "Copying large data and learning Rust!"
date:   2025-04-22 16:30:00 +0200
categories: development
---

[dircopy - Directory Copy with SHA256](https://github.com/blaufish/dircopy)
is my first useful Rust project.
This is a partially a rewrite and simplification of
[secure-copy](https://github.com/blaufish/secure-copy),
a Java version that I wrote in 2015.

Goals for the program;
* Copy large media files.
  Copying a few terabytes of videos from e.g. security conferences
  is my own use-case.
* Create `sha256sum` files while copying.
* Copy as fast as possible,
  Avoid unnecessary copy pipeline stalls using queues.
  Temporary slowdowns and delays in
  `read`,
  `write` or
  `sha256` should not unnecessarily delay overall performance.

Performance should be close to optimal compared to well performing
copy programs.

And if you wanted to `sha256sum` files like I do, you will save hours
by only passing over the data once.

I have tested the tool with large file file transfers;
copying `2.4 TiB` to a `271 MBps` destination disk
in `2 hrs 44 min`, reaching `266.553 MB/s`
(`98.4%` of maximal theoretical utilization).

**Table of Contents**
* [Usage](#usage)
* [Multithreaded with queues between threads](#multithreaded-with-queues-between-threads)
* [Windows Subsystem for Linux](#windows-subsystem-for-linux)
* [Performance when copying to an HDD](#performance-when-copying-to-an-hdd)
* [Internal performance](#internal-performance)
* [Benchmarking is hard](#benchmarking-is-hard)
* [Application reasons to select Rust](#application-reasons-to-select-rust)
* [Learning Rust](#learning-rust)

## Usage

Usage:

`./dircopy/target/release/dircopy -h`

``` plain
Usage: dircopy [OPTIONS] --input <INPUT> --output <OUTPUT>

Options:
  -i, --input <INPUT>
  -o, --output <OUTPUT>
      --queue-size <QUEUE_SIZE>              [default: 10]
      --block-size <BLOCK_SIZE>              [default: 128K]
      --overwrite-policy <OVERWRITE_POLICY>  [default: default]
  -h, --help                                 Print help
  -V, --version                              Print version
```

## Multithreaded with queues between threads

To achieve these goals, it is multithreaded with no unnecessary wait states.
* Read files in its own thread.
* SHA256SUM files in its own thread.
* Write files in its own thread.
* Synchronized queues between threads.

Tool is also user configurable;
allow end-user to configure queue size and block size.

Block size `128K` and queue size `10` appears great when testing on
my machine.

Setting up queues is done as follows:

``` rust
    let block_size: usize = cfg.block_size;
    let queue_size: usize = cfg.queue_size;

//...

    let (read_tx, read_rx) = sync_channel::<Message>(queue_size);
    let (sha_tx, sha_rx) = sync_channel::<Message>(queue_size);
    let (file_write_tx, file_write_rx) = sync_channel::<Message>(queue_size);
    let (status_tx, status_rx) = sync_channel::<StatusMessage>(queue_size);
```

### File read thread

The reader thread is as follows:

``` rust
    let read_thread = thread::spawn(move || {
        let mut failed = true;
        let mut heap_buf: Vec<u8> = Vec::with_capacity(block_size);
        heap_buf.resize(block_size, 0x00);
        loop {
            match fi.read(&mut heap_buf[0..block_size]) {
                Ok(0) => {
                    failed = false;
                    break;
                }
                Ok(n) => {
                    if let Err(e) = read_tx.send(Message::Block(heap_buf[0..n].to_vec())) {
                        eprintln!("Error: {}", e);
                        break;
                    }
                }
                Err(e) => {
                    eprintln!("Error: {}", e);
                    break;
                }
            }
        }
        if failed {
            if let Err(e) = read_tx.send(Message::Error) {
                eprintln!("Error: {}", e);
            }
            return;
        }
        if let Err(e) = read_tx.send(Message::Done) {
            eprintln!("Error: {}", e);
        }
    });
```

Or in simplified plain English:
* read `Vec<u8>` `heap_buf[0..block_size]` until done.
* send `Message::Block(...)` for each read block.
* send `Message::Done` when done.

### SHA256 thread

The SHA-thread is as follows:

``` rust
    let sha_thread = thread::spawn(move || -> Result<String, ()> {
        let mut h1 = Sha256::new();
        let mut incomplete = true;
        loop {
            match sha_rx.recv() {
                Ok(Message::Block(block)) => {
                    h1.update(&block);
                }
                Ok(Message::Error) => {
                    break;
                }
                Ok(Message::Done) => {
                    incomplete = false;
                    break;
                }
                Err(e) => {
                    eprintln!("Error T-SHA: {}", e);
                    break;
                }
            }
        }
        if incomplete {
            return Err(());
        }
        let digest = h1.finalize();
        let strdigest = format!("{:x}", digest);
        return Ok(strdigest);
    });
```

Or in simplified plain English:
* read blocks from queue until done.
* hash blocks.
* return digest as thread result.

### File write thread

``` rust
    let file_write_thread = thread::spawn(move || loop {
        match file_write_rx.recv() {
            Ok(Message::Block(block)) => {
                if let Err(e) = fo.write_all(&block) {
                    eprintln!("Error T-FW: {}", e);
                    break;
                }
            }
            Ok(Message::Error) => {
                break;
            }
            Ok(Message::Done) => {
                break;
            }
            Err(e) => {
                eprintln!("Error T-FW: {}", e);
                break;
            }
        }
    });
```

Or in simplified plain English:
* read blocks from queue until done.
* write blocks to file.

## Windows Subsystem for Linux

On my machine WSL seems to slow down the tool a lot **3 - 4X**
compared to native Windows.
So apparently WSL can impact performance more than I would have
expected.

Therefor I recommended to cross compile to target environment;
[Dockerfile](https://github.com/blaufish/dircopy/blob/175698f16520247a82c3ca2745972ee2fe168bad/Dockerfile)

``` bash
apt install -y \
   binutils-mingw-w64-x86-64 \
   build-essential \
   llvm \
   mingw-w64 \
   rustup

rustup target add x86_64-pc-windows-gnu

argo build --release --target x86_64-pc-windows-gnu
```

## Performance when copying to an HDD

When copying files to an HDD, I observed a few things:

**USB interface matters**.
I could improve from **70%** to **72%** of theoretical max by just
switching to a newer USB-interface.

**Source matters.**
Even if the source drive is faster than the destination drive, the
program can still bottleneck a bit unnecessarily.
With an internal SATA SSD, I achieved **72%** of theoretical max.
But if I instead copy from a NAS RAID
(6 SSD's over 10 Gigabit Ethernet)
I achieve **98.4%** of theoretical max.

| Source               | Destination                              | Performance          |
| -------------------- | ---------------------------------------- | :------------------- |
| 10GbE SSD RAID NAS   | Toshiba MG10AFA22TE over IB-377-C31      | 266.553 MB/s (98.4%) |
| Samsung EVO 870 SATA | Toshiba MG10AFA22TE over IB-377-C31      | 195.027 MB/s (72%)   |
| Samsung EVO 870 SATA | Toshiba MG10AFA22TE over old USB adapter | 189.559 MB/s (70%)   |

## Internal performance


I guess hardware and Operating System behaviors are interfering with
benchmarks.

With a NVME drive, first time I copy a directory
I achieve 927.385 MB/s on first time copy.
If I immediately repeat copying the file,
I achieve 1.844 GB/s... half the time.
Something makes the the second run super fast :-)
_Maybe Windows utilized all my RAM to cache the entire directory?_

| Drive                             | Performance  |
| --------------------------------- | ------------ |
| Samsung EVO 970 Plus 1TB SSD NVME | 965.849 MB/s |
| Samsung EVO 870 EVO 4TB SSD SATA  | 235.847 MB/s |

## Benchmarking is hard

Copying local files yields some funky results that
honestly is mostly confusing to me.

Extreme speed-ups observed on re-running internal file copy tests,
that simply do not make sense.
This can be explained by RAM caching of files.

Caching is interfering with benchmarks if benchmarking with:
* 64GiB of system RAM,
* 18GiB of test files,
  "impossible" performance is observed.
* 147GiB of test files,
  "impossible" performance is no longer observed.
* i.e. benchmarks can yield impossible results when file sizes are
  small enough for test files to be cached in computer RAM...

Example: SATA-II is a 600 MB/s;
* 235.847 MB/s makes sense for SSD read/write.
  `2 * 235.847 = 471.7` or **79%** of theoretical max.
* _For reference, Windows own file copy dialog average 200 - 220 MB/s
  when copying large files...  which makes sense,_
  `210*2/600 = 70%` _is decent!_
* 482.9 MB/s read and write makes no sense.
  `482.9*2/600 = 161%` ...
  Clearly **161%** performance is impossible,
  RAM caching issue.

But; "Impossible" performance **is not reproducible** when file
sizes are significantly larger than system RAM.
So important caveat, never accept great numbers when tests are
too small, redo tests on huge data sets!

## Application reasons to select Rust

These are some of the reasons why this application benefited from
a Rust rewrite;

### Binary/Executable

I wanted a binary running in native code,
that was easily executed without any additional
dependencies.

No JVM, no wrappers like `.cmd`, `.bat`, `.sh`.

### Fast binary

I wanted a fast binary running in native code.

I wanted to be able to be able investigate performance issues,
I did not want to need to wonder "maybe garbage collection is slow?"

### Cross compile

I wanted to easily be able to support multiple targets;
most importantly WSL/Ubuntu and Windows.

## Learning Rust

A short while back I started my
[rust-playground](https://github.com/blaufish/rust-playground)
where I put various tests, hello world, etc. experiments.

Why do I want to learn Rust?
Personal development mostly!

* Rust is something new and different to me.
  I have learned so many different languages in the past that all are different.
  * **bash** for Linux/WSL programming.
  * **python** for scripting.
  * **C** and **assembly** for systems and low level programming.
  * **Java** for my old backend spring boot, Servlet, EJB.
  * **JavaScript** for my XSS / web penetration testing.
  * **Verilog** and **VHDL** for hardware engineering.
* Rust can replace some of my **bash**, **C**, **Java**.
  With **WebAssembly** (WASM) support, it can even replace some web use-cases.
* Rust is faster than many other languages,
  and compiles to native code;
  _Rust is blazingly fast and memory-efficient:
  with no runtime or garbage collector,
  it can power performance-critical services,
  run on embedded devices,
  and easily integrate with other languages_
  ([Rust](https://www.rust-lang.org/))
* It is easier to design secure and error free code in rust:
  * Errors over Exceptions.
    Rust does **C/Linux** style errors, but with strong `Result<T, E>` typing.
    This move away from _Exceptions_ makes code clearer and makes the
    source code easier to read.
  * No unpredictable **Garbage collection**,
    instead: references, ownership and lifetimes.
  * [Memory Safety](https://doc.rust-lang.org/nomicon/meet-safe-and-unsafe.html).
    Rust's main application interface enforce memory safety.
    This is a huge win for security,
    as memory bugs are a common source of
    exploitable security vulnerabilities.
    (_Rust does allow systems/embedded developers to code unsafe,
    so almost all programming can live inside Rust_)
* [Threads](https://doc.rust-lang.org/book/ch16-01-threads.html)
  and message passing is implemented in a very convenient manner.
* Rust has received a lot of praise by developers, for example in
  [Stack Overflow](https://survey.stackoverflow.co/2024/technology#2-programming-scripting-and-markup-languages)
  survey.
  Of course it makes sense to join the popular train!

Is Learning Rust easy?
**_No, not exactly._**

* Rust loves to **refuse to compile**.
  You will get **so many error messages**.
  Many developers use IDE's and code editors to get integrated help
  to get the code to compile.
  If you compare to traditional languages like **Python** or **C**,
  you should expect a lot more work to get the compiler to accept
  your code.
* Googling on Rust problems often ends up in dead ends...
  This is my anecdotal experience, but I'm used to being able to
  google something and get great results for e.g. Python, Java, C.
  I noticed that I often have a lot less luck on Rust.
  Search results being almost empty or no answers in threads.
  * _Tangent...
    Maybe this is a bit that Rust is partially a post-AI language;
    people are seldom asking for help in forums these days?
    There's been a couple of times where a google searches turn up
    nothing useful but AI/LLMs do?...
    I don't know how I feel about this..._

Learning Rust:
* [YouTube: No Boilerplate](https://www.youtube.com/@NoBoilerplate)
* [YouTube: Let's Get Rusty](https://www.youtube.com/@letsgetrusty)
* [fasterthanli.me: A half-hour to learn Rust](https://fasterthanli.me/articles/a-half-hour-to-learn-rust)

If going to the gym, why not put on some Rusty _No Boilerplate_
videos in your headphones?
* [YouTube/ No Boilerplate: How to Learn Rust](https://www.youtube.com/watch?v=2hXNd6x9sZs) `video`
* [YouTube/ No Boilerplate: Rust makes cents](https://www.youtube.com/watch?v=4dvf6kM70qM) `video`
* [YouTube/ No Boilerplate: Rust for the impatient](https://www.youtube.com/watch?v=br3GIIQeefY) `video`
* [YouTube/ No Boilerplate: Rust Is Boring](https://www.youtube.com/watch?v=oY0XwMOSzq4) `video`
* [YouTube/ No Boilerplate: Rust Is Easy](https://www.youtube.com/watch?v=CJtvnepMVAU) `video`
