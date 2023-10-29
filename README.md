<div align="center">
  <p>
    <a align="center" href="" target="_blank">
      <img width="100%" src="https://github.com/spawnfest/exrow/blob/main/priv/logo.png?raw=true">
    </a>
  </p>
</div>

An elixir library/livebook plugin/app that combines the simplicity of note-taking with the robust power of computer language and spreadsheet concepts. Exrow allows users to write math equations and expressions using a markdown-like syntax, providing an intuitive and expressive way to work with mathematical concepts.

*Obs:* This project doesn't want to be a complete [CAS] but a calculator with steroids.

## Status

This project is in the early stages, so there's little to see. For now, you can download the source and run the tests:

```bash
$ mix deps.get
$ mix test
```

A basic version of the parse and runtime are ready, so a calculation can be done by calling it from the `iex`:

```elixir
$ iex -S mix
iex(1)> Exrow.Runtime.calculate("var = 1234 * (10 pow -3)\nvar + 2")
[1.234, 3.234]
```

## Packages

This project has three parts:

- `exrow-core`: parser and runtime library
- `exrow-livebook`: a plugin to use exrow as livebook's block
- `exrow-app`: A desktop app for multiple OS, package with [burrito] and [tauri]

## Implementation details

- This project uses [NimbleParsec] to implement a math language parse.
- This project will use [Phoenix LiveView] and [monaco-editor] to create a interactive experience for users, providing a text editor with syntax highlighting and autocompletion.

## Usage

The basis of `☴ Exrow` is: write one math expression by line, for every valid math expression, a result will show up on the right side of the editor:

```
## An example
price_hour = $100                                                      = $ 100
hours_worked = 72                                                      = 72
price_hour * hours_worked                                              = $ 7200
_ in EUR                                                               = € 7200
```

Invalid lines will be ignored, so you can use them as notes or comments.

### Numbers

You can express numbers in decimal `10` or `12.34`, binary `0b00`, octal `0o23478` or hexadecimal `0xFF`. Long numbers can be written with `_` in the middle to make it more transparent, like `1_000_000_000` (the character `_` will be ignored).

*Nerd info:* exrow is strongly inspired by [Elixir](https://elixir-lang.org/getting-started/basic-types.html#basic-arithmetic) arithmetic, so numbers are represented similarly.

### Units

All the values can be expressed in units. We can use many units: Angular, Area, CSS, Currency, Data, Date and Time, Length, Scales, Temperature, Volume and Weight. You'll see details about each in the following sections, but before that, you need to know you can use the operators `in` (or the variants `into, as, to`) to convert between units.

```
0b101010 in hex
10 meters in centimetres
2h * 2 to minutes
```

### Arithmetic operations

Arithmetic operations can be made with sign or word operators. Expressions can be separated by parentheses or stacked together; parentheses after another will be interpreted as a multiple expression:

```
10 + 1
10 times 10
(10 + 2) * 10
(10 + 3)(10 * 3) # same as (10 + 3) * (10 * 3)
```

|Operation|Sign|Sample|
|---|---|---|
|Addition|+|plus, and, with|
|Subtraction|-|minus, subtract, without|
|Multiplication|\*|times, multiplied by, mul|
|Division|/|divide, divide by|
|Exponent|^|pow|
|Modulo||rem, mod|

### Bitwise operations

A set of operators that perform calculations on bits.

|Operation|Sign|
|---|---|
|Bitwise And|&
|Bitwise Or|\|
|Bitwise Xor|xor|
|Left Shift|<<|
|Right Shift|>>|

## TODO

- [ ] Define the language and implement the parse
  - [x] Numbers
    - [x] Negative numbers
  - [x] Operations
  - [x] Bitwise
  - [x] Parentheses
  - [x] Variables
  - [ ] Labels
  - [ ] Units
    - [ ] Angular
    - [ ] Area
    - [x] CSS
    - [ ] Currency
    - [ ] Data
    - [ ] Date and Time
    - [x] Length: meter, mil, points, lines, inch, hand, foot, yard, rod, chain, furlong, mile, cable, nautical mile, league
    - [ ] Scales
    - [ ] Velocity: km, knot
    - [ ] Temperature
    - [ ] Volume
    - [ ] Weight
  - [ ] Function call `sum(10, 2) | (sum 10, 2) + 3`
  - [ ] Percentage
  - [ ] Formula support
    - [ ] Starting with =?
  - [ ] Lambda support
  - [ ] Array, rages and matrix
    - [ ] Matrix operations
- [ ] Implement a runtime
  - [ ] Arithmetic
    - [x] Basic operations
    - [ ] All operations
  - [x] Variables
  - [ ] Units
    - [ ] Adjust precision
    - [ ] Length
    - [-] Css
  - [ ] Currency
  - [ ] Lambda

- [ ] Livebook plugin
  - [ ] Split the project into package
  - [ ] Understand how to implement a livebook plugin

- [ ] UI
  - [ ] Basic Editor
  - [ ] Result panel
  - [ ] File manager
  - [ ] Syntax highlighting
  - [ ] Autocomplete

- [ ] Documentation
  - [ ] Improve the readme
  - [ ] Document language usage
  - [ ] Apply logo and colours

[burrito]: https://github.com/burrito-elixir/burrito
[tauri]: https://github.com/filipecabaco/ex_tauri
[NimbleParsec]: https://hexdocs.pm/nimble_parsec/NimbleParsec.html
[mono-editor]: https://microsoft.github.io/monaco-editor/
[Phoenix LiveView]: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
[CAS]: https://en.wikipedia.org/wiki/Computer_algebra_system
