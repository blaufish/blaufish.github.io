---
layout: post
title:  "dirverify: concurrent sha256 verifier written in Rust"
date:   2025-12-18 16:31:00 +0100
categories: development
---

In a follow up to
  [Copying large data and learning Rust!]({% post_url 2025-04-22-rust-dircopy %})
  ([dircopy](https://github.com/blaufish/dircopy)):
I've worked on a companion tool
  [dirverify](https://github.com/blaufish/dircopy/blob/master/dirverify.md):
  that verifies directories against `dircopy` `shasum.*.txt` files.

By default it will attempt to use concurrency to achieve performance;

* File reading is running in parallel with `SHA256` calculations.
* Multiple directories can be verified in parallel by specifying
  `dirverify dir1 dir2 dir3`.
  So you can for example verify source and destination drives in
  parallel without needing progress to wait on a slower drive.

Table of Contents:
* [Usage](#usage)
* [Restructuring source directory for multiple binaries](#restructuring-source-directory-for-multiple-binaries)
* [Cross-platform path name processing](#cross-platform-path-name-processing)
* [Inspect directory and obtain hash files](#inspect-directory-and-obtain-hash-files)
* [Parallel directory verification](#parallel-directory-verification)
* [Parallel file read and hashing](#parallel-file-read-and-hashing)

## Usage

Manual: [dirverify.md](https://github.com/blaufish/dircopy/blob/master/dirverify.md)

`dirverify -h`

``` plain
A directory verifier. Searches for shasum.*.txt files in directories

Usage: dirverify [OPTIONS] [DIR]...

Arguments:
  [DIR]...  Directories with files to be verified

Options:
      --hash-file <HASH_FILE>    Specify sha256-file, and disable automatic search for shasum*.txt files
      --silent                   Inhibit all stdout print outs
      --no-convert-paths         Keep paths exactly as is. Do not try to workaround unix, dos mismatches
      --no-summary               Do not print a summary
      --no-threaded-sha          Disable threaded sha read/hash behavior
      --no-parallell             Do not check multiple directories at the same time
      --queue-size <QUEUE_SIZE>  Size of queue between reader and hasher thread. Tuning parameter [default: 2]
      --block-size <BLOCK_SIZE>  Size of blocks between reader and hasher thread. Tuning parameter [default: 128K]
      --verbose                  Print informative messages helpful for understanding processing
  -h, --help                     Print help
  -V, --version                  Print version
```

## Restructuring source directory for multiple binaries

With two binary deliveries out from one `cargo` repository,
  having all code in `src/main.rs` doesn't work any more.

The new directory structure was as follows:
* [src/bin/dircopy.rs](https://github.com/blaufish/dircopy/blob/master/src/bin/dircopy.rs)
  `dircopy` binary source code.
* [src/bin/dirverify.rs](https://github.com/blaufish/dircopy/blob/master/src/bin/dirverify.rs)
  `dirverify` binary source code.
* [src/bin/texttools/mod.rs](https://github.com/blaufish/dircopy/blob/master/src/bin/texttools/mod.rs)
  shared module `texttools` with some basic string features.

## Cross-platform path name processing

Path, directory and file names are annoying as the path separator differs
   between Windows/DOS and Linux/WSL.

To help cross platform users,
  `dirverify` is converting between `\` and `/`
  automatically in `shasum.*.txt` files.


So `dirverify` can use `shasum.*.txt` files generated on Windows in Linux, or vise versa.

``` rust
let filename_corrected;

if self.convert_paths {
    if !filename.contains(MAIN_SEPARATOR_STR) {
        match MAIN_SEPARATOR_STR {
            "\\" => filename_corrected = filename.replace("/", "\\"),
            "/" => filename_corrected = filename.replace("\\", "/"),
            &_ => filename_corrected = filename.to_string(),
        }
    } else {
        filename_corrected = filename.to_string();
    }
} else {
    filename_corrected = filename.to_string();
}
```

## Inspect directory and obtain hash files

When executing `dirverify dir`, the tool needs to perform a few checks on directory `dir`;
* is it a directory?
* is the directory accessible?
* find any `shasum.*.txt` files in the directory,
  and return them to verifier.
  Return error if no such file.
* Optionally skip the `shasum.*.txt` check,
  if the hash-file has been specified elsewhere via command line options.

``` rust
fn inspect_dir(dir: &std::path::PathBuf, detect_sha_files: bool) -> Result<Vec<String>, String> {
    if !dir.is_dir() {
        return Err(format!("Not a directory {}", dir.display()));
    }
    let read_dir_maybe = fs::read_dir(&dir);
    let read_dir;
    match read_dir_maybe {
        Ok(rd) => read_dir = rd,
        Err(e) => {
            return Err(format!("{}: {}", dir.display(), e));
        }
    }
    if !detect_sha_files {
        return Ok(Vec::new());
    }
    let mut names: Vec<String> = Vec::new();
    for entry in read_dir {
        let name;
        match entry {
            Ok(file_entry) => {
                match file_entry.file_name().into_string() {
                    Ok(n) => name = n,
                    Err(e) => {
                        return Err(format!("Error reading file name: {}", e.display()));
                    }
                }
                match file_entry.file_type() {
                    Ok(file_type) => {
                        if !file_type.is_file() {
                            continue;
                        }
                    }
                    Err(e) => {
                        return Err(format!("Error determining file type; {} {}", name, e));
                    }
                }
            }
            Err(e) => {
                return Err(format!("Unexpected: {}", e));
            }
        }
        if !name.starts_with("shasum.") {
            continue;
        }
        if !name.ends_with(".txt") {
            continue;
        }
        names.push(name);
    }
    Ok(names)
}
```


## Parallel directory verification

The `main` function checks if should be run in parallel or not;

``` rust
// ------ run the verifier ------
if args.no_parallell {
    stats = run_sequential(dirverify, args.hash_file, sha_files);
} else {
    stats = run_parallell(dirverify, args.hash_file, sha_files);
}
```

`run_sequential` just loops over the directories,
  and verifies all files,
  except the `shasum.*.txt` files themselves:

``` rust
fn run_sequential(
    dirverify: DirVerify,
    hash_file: Option<std::path::PathBuf>,
    sha_files: Vec<(std::path::PathBuf, Vec<String>)>,
) -> Statistics {
    let mut stats = Statistics::new();
    for (dir, names) in &sha_files {
        let hash_names = match hash_file {
            Some(_) => None,
            None => Some(names.clone()),
        };
        dirverify.verify_all_lists(&mut stats, &dir, &hash_names, &hash_file);
    }
    stats
}
```

The `run_parallell` version basically just spawns a thread per
  directory, and then awaits all threads to terminate.
For all other purposes, it is the same for-loop.

``` rust
fn run_parallell(
    dirverify: DirVerify,
    hash_file: Option<std::path::PathBuf>,
    sha_files: Vec<(std::path::PathBuf, Vec<String>)>,
) -> Statistics {
    let mut stats = Statistics::new();
    let mut threads = Vec::new();
    for (dir, names) in &sha_files {
        let hash_file = hash_file.clone();
        let dir_thread = dir.clone();
        let names_thread = names.clone();
        let dirverify_thread = dirverify.clone();
        let thread = thread::spawn(move || -> Statistics {
            let mut thread_stats = Statistics::new();
            let hash_names = match hash_file {
                Some(_) => None,
                None => Some(names_thread.clone()),
            };
            dirverify_thread.verify_all_lists(
                &mut thread_stats,
                &dir_thread,
                &hash_names,
                &hash_file,
            );
            thread_stats
        });
        threads.push(thread);
    }
    for thread in threads {
        match thread.join() {
            Ok(x) => stats.add(&x),
            Err(err) => {
                stats.errors += 1;
                eprintln!("{}", format!("Join error: {:?}", err));
            }
        }
    }
    stats
}
```

## Parallel file read and hashing

The tool can run file read and SHA-hash in parallel.

While your mileage may vary,
  on my tests with modern processor and fast SSDs,
  the parallel version is a few percent faster.
So it saves some wall time clock, but the gains aren't enormous.

``` rust
fn sha_file(&self, stats: &mut Statistics, file: &mut File) -> Result<String, String> {
    if self.threaded_sha_reader {
        self.sha_file_multithread(stats, file)
    } else {
        self.sha_file_single_thread(stats, file)
    }
}
```

The single thread version is as you would expect just a read, update loop.

``` rust
fn sha_file_single_thread(
    &self,
    stats: &mut Statistics,
    file: &mut File,
) -> Result<String, String> {
    let block_size = self.block_size;
    let mut h1 = Sha256::new();

    let mut heap_buf: Vec<u8> = Vec::with_capacity(block_size);
    heap_buf.resize(block_size, 0x00);

    loop {
        match file.read(&mut heap_buf[0..block_size]) {
            Ok(0) => break,
            Ok(n) => {
                h1.update(&heap_buf[0..n]);
                stats.read_bytes += n;
            }
            Err(e) => {
                return Err(e.to_string());
            }
        }
    }
    let digest = h1.finalize();
    let strdigest = format!("{:x}", digest);
    Ok(strdigest)
}
```

The multithreaded version is basically the same thing,
  but with an thread spawn for the `SHA256` hasher,
  a `sync_channel` queue between threads,
  and a thread `join` to obtain the `SHA256` result.

``` rust
fn sha_file_multithread(
    &self,
    stats: &mut Statistics,
    file: &mut File,
) -> Result<String, String> {
    let block_size = self.block_size;
    let queue_size = self.queue_size;

    let (read_tx, sha_rx) = sync_channel::<Message>(queue_size);

    let sha_thread = thread::spawn(move || -> Result<String, String> {
        let mut h1 = Sha256::new();
        loop {
            match sha_rx.recv() {
                Ok(Message::Block(block)) => {
                    h1.update(&block);
                }
                Ok(Message::Error) => {
                    return Err(String::from("T-Read: sent error"));
                }
                Ok(Message::Done) => {
                    break;
                }
                Err(e) => {
                    return Err(format!("T-SHA: {}", e));
                }
            }
        }
        let digest = h1.finalize();
        let strdigest = format!("{:x}", digest);
        return Ok(strdigest);
    });

    let mut heap_buf: Vec<u8> = Vec::with_capacity(block_size);
    heap_buf.resize(block_size, 0x00);

    loop {
        match file.read(&mut heap_buf[0..block_size]) {
            Ok(0) => {
                if let Err(e) = read_tx.send(Message::Done) {
                    return Err(format!("Error: {}", e));
                }
                break;
            }
            Ok(n) => {
                stats.read_bytes += n;
                if let Err(e) = read_tx.send(Message::Block(heap_buf[0..n].to_vec())) {
                    return Err(format!("Error: {}", e));
                }
            }
            Err(e) => {
                _ = read_tx.send(Message::Error);
                return Err(e.to_string());
            }
        }
    }
    match sha_thread.join() {
        Ok(x) => x,
        Err(err) => Err(format!("Join error: {:?}", err)),
    }
}
```
