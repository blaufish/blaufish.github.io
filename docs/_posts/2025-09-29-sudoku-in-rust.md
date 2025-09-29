---
layout: post
title:  "Sudoku in Rust"
date:   2025-09-29 15:48:00 +0200
categories: development
---

As part of "Learning Rust!" I started trying to solve Sudoku:

* [github/blaufish/sudoku-solver-rust](https://github.com/blaufish/sudoku-solver-rust)

A sudoku can loosely be defined as a puzzle game with **N by N** cells.
Each cell is part of three sets: a **row**, a **column**, a **grid**.
Each set is **N** cells large.
Each cell have a value between `1` and `N` which is unique in all three sets.

**Table of Contents**
* [Goals](#goals)
* [Performance](#performance)
* [When does performance matter?](#when-does-performance-matter)
* [One Hot Encoding variant](#one-hot-encoding-variant)
* [Dynamic Programming](#dynamic-programming)
* [Solving sudoku](#solving-sudoku)
  * [Recursion and Backtrack](#recursion-and-backtrack)
  * [Recursion, Backtrack and with focus on easiest cell](#recursion-backtrack-and-with-focus-on-easiest-cell)
  * [Solve as many cells as possible before recursion and backtrack](#solve-as-many-cells-as-possible-before-recursion-and-backtrack)
  * [Backtrack with deduction strategies](#backtrack-with-deduction-strategies)
* [Generating a sudoku](#generating-a-sudoku)
  * [Generating one sudoku solution](#generating-one-sudoku-solution)
  * [Generate a sudoku challenge](#generate-a-sudoku-challenge)
* [Future improvements](#future-improvements)
* [References](#references)
  * [General](#general)
  * [Rust Sudoku solvers](#rust-sudoku-solvers)
* [Bonus references](#bonus-references)
  * [Constraint based solving](#constraint-based-solving)
  * [Computer vision](#computer-vision)

## Goals

My goals for my Sudoku solver included:

Arbitrary **character sets**, such as `1-9`, `0-8`, `0-9A-F`.
Or Unicode like `🐡💩🐙`.
Or whatever.

Support **larger sudoku**.
Not be constrained by classical 9x9.
* I wanted to be able to solve 16x16, 25x25, 36x36
  and other sizes.
* I also wanted to support asymmetric grids,
  such as required by 6x6, 12x12, 30x30 Sudoku.
  For example, **6x6 Sudoku**: each grid is 3x2,
  three cells vertically, two cells horizontally.
  The sudoku has two grids on vertical axis and
  three grids on the horizontal axis.

Avoid **string operations** within the sudoku logic.
A Unicode/UTF-8 character can have arbitrary length,
and honestly I sometimes find Rust's different string
types confusing/difficult to deal with.
So my Sudoku has a character set to be able to convert
from and to text, but doesn't use the text values internally.

## Performance

I've tried solving a simple 9x9 sudoku with my two current implementations;

* 375.752µs is required for a basic recursive / backtrack sudoku solve.
* 32.318µs is required for a faster backtrack solve.
  It iteratively solves all trivially solvable squares before executing
  next recursive / backtrack iteration.

So just a slight change in the logic makes the code **11X faster**.
But, for comparison:

* 6.559µs is required for `sudoku` `v0.8.0`
  [https://crates.io/crates/sudoku](https://crates.io/crates/sudoku):

So, a rust developer who is capable of getting the max out of rust,
and implements
[Sudoku strategies](https://www.sudokuwiki.org/Strategy_Families)
is **5X faster** than my best implementation,
and is **57X faster** than my naive implementation.

That's a bit humbling, people who know Rust & Sudoku are orders of magnitude
faster than me.


## When does performance matter?

So, **does performance matter?**
If you are only solving a single 9x9 sudoku on a fast modern CPU, clearly not.

But sudoku performance does matter in some use cases:
* Generating a sudoku with a single unique solution requires solving several
  Sudoku. Speed is nice.
* Working with larger Sudoku, such as 36x36, does tax the CPU.
  Faster is nice.
* Solving Sudoku on very low-end devices.


## One Hot Encoding variant

One implementation decision I made was to use a variant of One Hot Encoding / bit fields.

I defined a cell value as:

* `b00000` (`0x00`) - cell is empty / unsolved
* `b00001` (`0x01`) - the cell has the first character value.
* `b00010` (`0x02`) - the cell has the second character value.
* `b00100` (`0x04`) - the cell has the third character value.
* ... and so on.

So if I want to know all occupied values in a row, I can just `or` all the values together.

Now, notably, I've realized that my code actually only uses this in a very special use case,
(the dynamic table).
So I will probably experiment with a more memory compact representation soon.

## Dynamic Programming

[Dynamic programming](https://en.wikipedia.org/wiki/Dynamic_programming)
is the art of replacing function calls with a table.

And since I am hilarious I decided to name my table `Table`,
not at all confusing.

``` rust
pub struct Table {
    pub rows: [u64; MAX_DIMENSIONS],
    pub cols: [u64; MAX_DIMENSIONS],
    pub grids: [[u64; MAX_GRID_DIMENSIONS]; MAX_GRID_DIMENSIONS],
}

impl Table {
    # ...
    pub fn populate(&mut self, sudoku: &sudoku::Sudoku) {
        for i in 0..sudoku.dimensions {
            self.rows[i] = sudoku.utilized_row(i);
            self.cols[i] = sudoku.utilized_col(i);
        }
        for r in 0..(sudoku.dimensions / sudoku.grid_height) {
            for c in 0..(sudoku.dimensions / sudoku.grid_width) {
                let row = r * sudoku.grid_height;
                let col = c * sudoku.grid_width;
                self.grids[r][c] = sudoku.utilized_grid(row, col);
            }
        }
    }
    # ...
}
```

So to find what possible values exists for a cell, I can ask the table
with just three memory accesses two `or` operations.

``` rust
    pub fn get_utilized_grgc_rc(
        &self,
        grid_row: usize,
        grid_col: usize,
        row: usize,
        col: usize,
    ) -> u64 {
        let utilized_row = self.rows[row];
        let utilized_col = self.cols[col];
        let utilized_grid = self.grids[grid_row][grid_col];
        let utilized = utilized_row | utilized_col | utilized_grid;
        utilized
    }
```

there's a ton of `sudoku.utilized_row(i)`, `sudoku.utilized_col(i)` etc.
calls that never need to be made.

Instead the table is just initialized once,

``` rust
pub fn solve(sudoku: &mut sudoku::Sudoku) -> bool {
    let mut table = Table::new();
    table.populate(sudoku);
    solve_inner(sudoku, &mut table)
}
```

and each `solve_inner(sudoku, &mut table)`
call updates the table appropriately.
Less function calls, less memory that needs to be processed.

## Solving sudoku

### Recursion and Backtrack

The most simple solution to solving Sudoku is to pick the first empty cell.
Calculate all possible values for this cell,
pick a value, and recursively try to solve the sudoku.
Upon failure, backtrack, and try another potential value.
Recursively iterate and backtrack until a solution is found.

### Recursion, Backtrack and with focus on easiest cell

An minor improvement is to always pick the cell with the fewest possible values,
so the backtrack/recursion tree will be as shallow as possible.

Finding the cell with the fewest possible moves:

``` rust
fn next_moves(sudoku: &sudoku::Sudoku, table: &Table) -> Option<(usize, usize, Vec<u64>)> {
    let mut result: Option<(usize, usize, Vec<u64>)> = None;
    for row in 0..sudoku.dimensions {
        let utilized_row = table.rows[row];
        for col in 0..sudoku.dimensions {
            if sudoku.board[row][col] != 0 {
                continue;
            }
            let utilized_col = table.cols[col];
            let grid_row = row / sudoku.grid_height;
            let grid_col = col / sudoku.grid_width;
            let utilized_grid = table.grids[grid_row][grid_col];
            let utilized = utilized_row | utilized_col | utilized_grid;
            let mut moves: Vec<u64> = Vec::new();
            for i in 0..sudoku.dimensions {
                let binary: u64 = 1 << i;
                if binary & utilized != 0 {
                    continue;
                }
                moves.push(binary);
            }
            if moves.len() == 0 {
                //Board is in a bad state, a cell cannot accept any moves
                return None;
            }
            match result {
                None => result = Some((row, col, moves)),
                Some((r, c, old_moves)) => {
                    if moves.len() < old_moves.len() {
                        result = Some((row, col, moves));
                    } else {
                        result = Some((r, c, old_moves));
                    }
                }
            }
        }
    }
    result
}
```

The backtrack implementation:

``` rust
fn solve_inner(sudoku: &mut sudoku::Sudoku, table: &mut Table) -> bool {
    let mut solved = true;

    for r in 0..sudoku.dimensions {
        for c in 0..sudoku.dimensions {
            if sudoku.board[r][c] != 0 {
                continue;
            }
            solved = false;
            break;
        }
    }
    if solved {
        return true;
    }

    let moves = next_moves(&sudoku, &table);
    let row: usize;
    let col: usize;
    let values: Vec<u64>;
    if let Some((r, c, v)) = moves {
        row = r;
        col = c;
        values = v;
    } else {
        //Give up. No move is possible.
        return false;
    }

    let grid_row = row / sudoku.grid_height;
    let grid_col = col / sudoku.grid_width;
    for binary in values {
        sudoku.board[row][col] = binary;
        table.rows[row] ^= binary;
        table.cols[col] ^= binary;
        table.grids[grid_row][grid_col] ^= binary;

        let recursive_solved = solve_inner(sudoku, table);
        if recursive_solved {
            return true;
        }

        sudoku.board[row][col] = 0;
        table.rows[row] ^= binary;
        table.cols[col] ^= binary;
        table.grids[grid_row][grid_col] ^= binary;
    }
    false
```

### Solve as many cells as possible before recursion and backtrack


But anyway, for now, I have `multi.rs` as follows...

Solve several cells per recursion level.
Restore all cells if the recursion fails.

``` rust
fn solve_inner(sudoku: &mut sudoku::Sudoku) -> bool {
    let mut restorepoint: Vec<(usize, usize)> = Vec::new();
    let result = solve_inner_inner(sudoku, &mut restorepoint);
    if !result {
        restore(sudoku, &mut restorepoint);
    }
    result
}
```

The iteration calls a precheck with deductions;

``` rust
fn solve_inner_inner(sudoku: &mut sudoku::Sudoku, restorepoint: &mut Vec<(usize, usize)>) -> bool {
    let check = pre(sudoku, restorepoint);
    match check {
        PreCheckValue::Completed => return true,
        PreCheckValue::NotCompleted => (),
    }

    #
    # cut for brevity:
    # the backtrack algorithm
    #
}
```

The precheck currently only implements the most basic of strategies, `deduce_cell_locked_obvious`...

``` rust
fn pre(sudoku: &mut sudoku::Sudoku, restorepoint: &mut Vec<(usize, usize)>) -> PreCheckValue {
    let mut table = Table::new();
    table.populate(sudoku);
    if deduce_completed(&sudoku) {
        return PreCheckValue::Completed;
    }
    deduce_cell_locked_obvious(sudoku, &mut table, restorepoint);
    if deduce_completed(&sudoku) {
        return PreCheckValue::Completed;
    }
    PreCheckValue::NotCompleted

```

`deduce_cell_locked_obvious` simply fills in all cells that have a single possible value.

``` rust
fn deduce_cell_locked_obvious(
    sudoku: &mut sudoku::Sudoku,
    table: &mut Table,
    restorepoint: &mut Vec<(usize, usize)>,
) {
    loop {
        let mut done = true;
        for grid_row in 0..(sudoku.dimensions / sudoku.grid_height) {
            for grid_col in 0..(sudoku.dimensions / sudoku.grid_width) {
                let row_base = grid_row * sudoku.grid_height;
                let col_base = grid_col * sudoku.grid_width;
                for r in 0..sudoku.grid_height {
                    for c in 0..sudoku.grid_width {
                        let row = row_base + r;
                        let col = col_base + c;
                        if sudoku.board[row][col] != 0 {
                            continue;
                        }

                        let utilized_grid = table.grids[grid_row][grid_col];
                        let utilized_row = table.rows[row];
                        let utilized_col = table.cols[col];
                        let utilized = utilized_row | utilized_col | utilized_grid;
                        let mut binary: u64 = 0;
                        let mut count = 0;
                        for i in 0..sudoku.dimensions {
                            let bin: u64 = 1 << i;
                            if bin & utilized != 0 {
                                continue;
                            }
                            binary = bin;
                            count = count + 1;
                        }

                        if count == 1 {
                            sudoku.board[row][col] = binary;
                            table.rows[row] ^= binary;
                            table.cols[col] ^= binary;
                            table.grids[grid_row][grid_col] ^= binary;
                            restorepoint.push((row, col));
                            done = false;
                        }
                    }
                }
            }
        }
        if done {
            break;
        }
    }
}
```

Performing this instead early instead of always performing a recursive function
  call reduces stack utilization.
It is also significantly faster.

### Backtrack with deduction strategies

Prior to recursion/backtrack, you can solve all cells that can be deduced using a "strategy".

You are much better served by looking at
[sudokuwiki.org](https://www.sudokuwiki.org/)
and
[github/Emerentius/sudoku](https://github.com/Emerentius/sudoku)
that does this much better than me...


Even if you cannot deduce which exact cell has a value,
if you can determine a pair must claim a value,
you can conclude other cells cannot have this value.


## Generating a sudoku

Generating a Sudoku follows basically this algorithm;

1. First generate one sudoku solution.
2. Then generate a sudoku challenge,
   with less and less characters,
   always verifying it has no alternative solution.

### Generating one sudoku solution

I created this generator that works for 9x9 and larger Sudoku.
(for smaller Sudoku I have another implementation).

``` rust
fn generate_golden_large(generator: &Generator) -> Option<sudoku::Sudoku> {
    let mut sudoku = sudoku::Sudoku::new(
        generator.dimensions,
        generator.grid_height,
        generator.grid_width,
        generator.charset.clone(),
    );
    let grid_dim;
    if generator.grid_width > generator.grid_height {
        grid_dim = generator.grid_height;
    } else {
        grid_dim = generator.grid_width;
    }

    let mut cells = get_empty_cells(sudoku.clone());
    let mut rng = rand::rng();
    cells.shuffle(&mut rng);

    for i in 0..grid_dim {
        fill_grid(&mut sudoku, i, i);
    }
    let solved = solve(&mut sudoku, None);
    if !solved {
        return None;
    }
    Some(sudoku)
}
```

### Generate a sudoku challenge

For the sudoku challenge, I created the following algorithm:

1. Create a randomly ordered list of cells using
   `cells.shuffle(&mut rng);`
2. loop:
   * Return success early if spent too much time on the effort.
   * Perform `try_remove(&mut sudoku, row, col);`


``` rust
pub fn generate_challenge(
    generator: &Generator,
    golden: &sudoku::Sudoku,
) -> Option<sudoku::Sudoku> {
    let max_duration = Duration::new(generator.max_prune_seconds, 0);

    let mut sudoku = golden.clone();
    let mut rng = rand::rng();

    let mut ignore: Vec<sudoku::Sudoku> = Vec::new();
    ignore.push(golden.clone());
    let start = Instant::now();

    let mut cells = get_none_empty_cells(sudoku.clone());
    cells.shuffle(&mut rng);
    for cell in cells {
        let duration = start.elapsed();
        if duration > max_duration {
            break;
        }
        let row: usize;
        let col: usize;
        (row, col) = cell;

        try_remove(&mut sudoku, row, col);
    }
    return Some(sudoku);
}
```

`try_remove` checks that no alternative solutions exists if this cell is
  removed:

``` rust
fn try_remove(sudoku: &mut sudoku::Sudoku, row: usize, col: usize) {
    let tmp = sudoku.board[row][col];
    let charset_len = sudoku.character_set.chars().count();
    let mut sudoku2 = sudoku.clone();

    sudoku2.board[row][col] = 0;
    let utilized_grid = sudoku2.utilized_grid(row, col);
    let utilized_row = sudoku2.utilized_row(row);
    let utilized_col = sudoku2.utilized_col(col);
    let utilized = utilized_grid | utilized_row | utilized_col;

    for i in 0..charset_len {
        let binary: u64 = 1 << i;
        if tmp == binary {
            // This is the correct sudoku, no need to validate.
            continue;
        }
        if utilized & binary != 0 {
            //This value cannot be picked, not an option!
            continue;
        }
        sudoku2.board[row][col] = binary;
        let solved = solve(&mut sudoku2, None);
        if solved {
            //An alernative solution was found, this branch is poisoned!
            return;
        }
    }
    //No wrong solutions found, unfill this cell.
    sudoku.board[row][col] = 0;
}

```

## Future improvements

Future improvement may include:

**More Compact memory layout**;
* use generic size, so Sudoku boards are sized as needed, instead of max supported size.
* represent sudoku board with `u8` instead of `u64`.


**Utilize Rust more efficiently**
* Learn what coding styles enables, invites Rust to apply more concurrency, optimizations, `SIMD` etc.

**Utilize Sudoku strategies**
* Apply smarter deductions strategies,
  like [Naked Candidates](https://www.sudokuwiki.org/Naked_Candidates) (Naked Pair, Conjugate Pair).

## References

### General

* [sudokuwiki.org](https://www.sudokuwiki.org/)
  a wiki that explains Sudoku and various ways of solving Sudoku using clever
  strategies.
* [Medium/ Tuksa Emmanuel David: Sudoku Solver Using Rust](https://medium.com/@dt_emmy/sudoku-solver-using-rust-8a4e83d921fd)
  a very good introductory blog post to sudoku solving in Rust.

### Rust Sudoku solvers

* [github.com/blaufish/sudoku-solver-rust/](https://github.com/blaufish/sudoku-solver-rust/)
  my sudoku solver.
* [github.com/Emerentius/sudoku](https://github.com/Emerentius/sudoku)
  a rust library that implements several sudoku strategies.
  Also known as [crates.io/crates/sudoku](https://crates.io/crates/sudoku)
* [github.com/DeTuksa/Sudoku-Solver](https://github.com/DeTuksa/Sudoku-Solver)
  a rust library that solves sudoku using backtracking.

## Bonus references

Additional fun things I stumbled across, that are not relevant to my blog post.

### Constraint based solving

Well, ... constraint based programming lets a constraint solver solve the problem,
instead of manually writing sudoku solving algorithms.
Pure witchcraft.

* [github/wangds/puzzle-solver](https://github.com/wangds/puzzle-solver)
  rust based constraint solver that looks pretty simple,
  and supports Sudoku.
* [Solving Sudoku with Prolog (metalevel.at)](https://www.metalevel.at/sudoku/)
* [Constraint Logic Programming over Integers](https://github.com/triska/clpz)

So not something I've gotten experience in, but in theory this could just do
the entire sudoku solving for you.

### Computer vision

A Python wrapper round Rust [crates/sudoku](https://crates.io/crates/sudoku).
Solves sudoku from images.

* [medium/Prakhar Kaushik: Open-CV Based Sudoku Solver Powered By Rust](https://medium.com/data-science/open-cv-based-sudoku-solver-powered-by-rust-df256653d5b3)
* [github/pr4k/sudoku-solver](https://github.com/pr4k/sudoku-solver)
  Computer vision sudoku solver. Take a photo of an sudoku, and it solves it.

Potentially cool.

