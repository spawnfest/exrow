# ☴ Exrow

Exrow is an app that combines the simplicity of note-taking with the robust power of computer language and spreadsheets. Exrow allows users to write math equations and expressions using a markdown-like syntax, providing an intuitive and expressive way to work with mathematical concepts.

## Usage

### Numbers

You can express numbers in decimal `10` or `12.34`, binary `0b00`, octal `0o23478` or hexadecimal `0xFF`. Long numbers can be written with `_` in the middle to make it clearer, like `1_000_000_000` (the character `_` will be ignored).

### Units

All the values can be expressed in units. We can use many kinds of units: Angular, Area, CSS, Currency, Data, Date and Time, Length, Scales, Temperature, Volume and Weight. You'll see details about each in the following sections, but before that, you need to know you can use the operators `in` (or the variants `into, as, to`) to convert between units.

```
0b101010 in hex
10 meters in centimetres
2h * 2 to minutes
```

### Algebraic operations

Algebraic operations can be made with sign or word operators. Expressions can be separated by parentheses or stacked together, parentheses after another will be interpreted as a multiple expression:

```
10 + 1
10 times 10
(10 + 2) * 10
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

- [ ] Language and parse
  - [ ] Define the basic language
    - [x] Numbers
    - [x] Operations
    - [x] Bitwise
    - [x] Parentheses
    - [ ] Variables
    - [ ] Units
    - [ ] Percentage
  - [ ] Implement the parse for the basic language
  - [ ] Implement a runtime
  - [ ] Document the language

- [ ] UI
  - [ ] Basic editor
  - [ ] Result panel
  - [ ] File manager
  - [ ] Syntax highlighting
  - [ ] Autocomplete

- [ ] Documentation
  - [ ] Improve the readme
  - [ ] Apply logo and colours
