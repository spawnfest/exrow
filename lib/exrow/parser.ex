defmodule Exrow.Parser do
  import NimbleParsec

  # alias ExRow.Number
  # alias Exrow.Unit

  # space        := ?\s | ?\t
  # identifier   := (?a..?z | ?A..?Z | ?_)[?a..?z, ?A..?Z, ?_, ?0..?9]...
  # term_op      := * | /
  # expr_op      := in | + | - | ^ | rem | & | \| | xor | << | >>

  # float        := 0.1 | 10_00.50 | ...
  # integer      := 0 | 0b01 | 1_000 | ...
  # number       := float | integer

  # length_unit  := kilometer | meter | ...
  # angular_unit := [TODO]
  # unit         := length_unit | angular_unit | [TODO]
  # unit_value   := number unit
  # value        := unit_value | number | identifier

  # factor       := ( expr ) | ( expr ) ( expr ) | value
  # term         := factor term_op term | factor
  # expr         := term expr_op expr | term

  # assign       := identifier = expr

  space = ignore(ascii_string([?\s, ?\t], min: 1))

  identifier =
    ascii_string([?a..?z, ?A..?Z, ?_], max: 1)
    |> optional(ascii_string([?a..?z, ?A..?Z, ?_, ?0..?9], min: 1))
    |> reduce({Enum, :join, [""]})

  expr_op =
    [
      {:in, ["in", "into", "as", "to"]},
      {:+, ["+", "plus", "and", "with"]},
      {:-, ["-", "minus", "subtract", "without"]},
      {:^, ["^", "pow"]},
      {:rem, ["rem", "mod"]},
      {:&, ["&"]},
      {:|, ["|"]},
      {:xor, ["xor"]},
      {:<<<, ["<<"]},
      {:>>>, [">>"]}
    ]
    |> Enum.map(fn {symbol, alternatives} ->
      alternatives
      |> Enum.map(&string(&1))
      |> case do
        [opt] -> opt
        opts -> choice(opts)
      end
      |> replace(symbol)
    end)

  term_op =
    [
      # {:+, ["+"]},
      # {:-, ["-"]},
      {:*, ["*", "times", "multiplied by", "mul"]},
      {:/, ["/", "divide by", "divide"]}
    ]
    |> Enum.map(fn {symbol, alternatives} ->
      alternatives
      |> Enum.map(&string(&1))
      |> case do
        [opt] -> opt
        opts -> choice(opts)
      end
      |> replace(symbol)
    end)

  numbers_separator = ignore(ascii_string([?_], min: 0))

  optional_separator =
    optional(
      numbers_separator
      |> concat(ascii_string([?0..?9], min: 1))
      |> times(min: 1)
      |> reduce({Enum, :join, [""]})
    )

  signal =
    choice([
      ascii_string([?-], max: 1),
      ignore(ascii_string([?+], max: 1))
    ])
    |> optional()

  float =
    signal
    |> optional(space)
    |> ascii_string([?0..?9], min: 1)
    |> concat(optional_separator)
    |> string(".")
    |> concat(optional_separator)
    |> reduce({Enum, :join, [""]})
    |> unwrap_and_tag(:float)
    |> post_traverse(:to_number)

  integer =
    [
      {:binary, ignore(string("0b")), ascii_string([?0..?1], min: 1)},
      {:octal, ignore(string("0o")), ascii_string([?0..?8], min: 1)},
      {:hex, ignore(string("0x")), ascii_string([?0..?9, ?a..?f, ?A..?F], min: 1)},
      {:decimal, empty(), ascii_string([?0..?9], min: 1)}
    ]
    |> Enum.map(fn {system, prefix, numbers} ->
      signal
      |> optional(space)
      |> concat(prefix)
      |> concat(numbers)
      |> optional(
        numbers_separator
        |> concat(numbers)
        |> times(min: 1)
      )
      |> reduce({Enum, :join, [""]})
      |> unwrap_and_tag(system)
      |> post_traverse(:to_number)
    end)
    |> choice()

  length_unit =
    [
      {:femtometer, "femtometer", -15},
      {:picometer, "picometer", -12},
      {:nanometre, "nanometre", -9},
      {:micrometre, "micrometre", -6},
      {:millimeter, "millimeter", -3},
      {:centimeter, "centimeter", -2},
      {:decimeter, "decimeter", -1},
      # Base
      {:meter, "meter", 0},
      {:dekameter, "dekameter", 1},
      {:hectometer, "hectometer", 2},
      {:kilometer, "kilometer", 3},
      # Variants
      {:mil, "mil", 0},
      {:points, "points", 0},
      {:lines, "lines", 0},
      {:inch, "inch", 0},
      {:hand, "hand", 0},
      {:foot, "foot", 0},
      {:yard, "yard", 0},
      {:rod, "rod", 0},
      {:chain, "chain", 0},
      {:furlong, "furlong", 0},
      {:mile, "mile", 0},
      {:cable, "cable", 0},
      {:nmi, "nmi", 0},
      {:nmi, "nautical mile", 0},
      {:league, "league", 0}
    ]
    |> Enum.map(fn {unit, form, _} ->
      string(form)
      |> ignore()
      |> tag(unit)
    end)
    |> choice()

  # signal =
  #   optional(space)
  #   |> ascii_string([?-, ?+], max: 1)
  #   |> optional(space)

  number = choice([float, integer])
  unit = length_unit

  unit_value =
    number
    |> concat(optional(space))
    |> concat(unit)
    |> post_traverse(:to_unit)

  value = choice([unit_value, number, identifier])

  factor =
    empty()
    |> choice(
      [
        optional(space)
        |> concat(ignore(ascii_char([?(])))
        |> concat(parsec(:expr))
        |> ignore(ascii_char([?)]))
        |> times(min: 1)
        |> tag(:factor),
        value
      ],
      gen_weights: [1, 3]
    )
    |> post_traverse(:to_prefixed)

  term =
    empty()
    |> choice(
      [
        factor
        |> concat(optional(space))
        |> concat(choice(term_op))
        |> concat(optional(space))
        |> concat(parsec(:term))
        |> tag(:term),
        factor
      ],
      gen_weights: [1, 3]
    )
    # |> debug()
    |> post_traverse(:to_prefixed)

  expr =
    empty()
    |> choice(
      [
        parsec(:term)
        |> concat(optional(space))
        |> concat(choice(expr_op))
        |> concat(optional(space))
        |> concat(parsec(:expr))
        |> tag(:expr),
        parsec(:term)
      ],
      gen_weights: [1, 3]
    )
    # |> debug()
    |> post_traverse(:to_prefixed)

  defcombinatorp(:term, term)
  defcombinatorp(:expr, expr)

  assign =
    identifier
    |> optional(space)
    |> ignore(string("="))
    |> optional(space)
    |> parsec(:expr)
    |> tag(:assign)
    |> post_traverse(:to_assign)

  defparsec(:mathdown, choice([assign, parsec(:expr)]))

  def parse(value) do
    value
    |> String.trim()
    |> mathdown()
    |> case do
      {:ok, [ast_root], _rest, _context, _line, _offset} ->
        {:ok, ast_root}

      error ->
        error
    end
  end

  defp to_unit(rest, [{unit, _}, value], ctx, _line, _offset) do
    {rest, [{unit, value}], ctx}
  end

  defp to_assign(rest, [{:assign, [identifier, expr]}], ctx, _line, _offset) do
    {rest, [{:=, identifier, expr}], ctx}
  end

  defp to_prefixed(rest, [{:factor, [left, right]}], ctx, _line, _offset) do
    {rest, [{:*, left, right}], ctx}
  end

  defp to_prefixed(rest, [{:factor, expr}], ctx, _line, _offset) do
    {rest, expr, ctx}
  end

  defp to_prefixed(rest, [{:expr, [{op, left, ""}, :-, right]}], ctx, _line, _offset)
       when op in [:*, :/] do
    {rest, [{op, left, {:*, -1, right}}], ctx}
  end

  defp to_prefixed(rest, [{:expr, [{op, left, ""}, :+, right]}], ctx, _line, _offset)
       when op in [:*, :/] do
    {rest, [{op, left, right}], ctx}
  end

  defp to_prefixed(rest, [{:expr, ["", :-, exp]}], ctx, _line, _offset) do
    {rest, [{:*, -1, exp}], ctx}
  end

  defp to_prefixed(rest, [{:expr, ["", :+, exp]}], ctx, _line, _offset) do
    {rest, [exp], ctx}
  end

  defp to_prefixed(rest, [{_, [left, op, right]}], ctx, _line, _offset) do
    {rest, [{op, left, right}], ctx}
  end

  defp to_prefixed(rest, args, ctx, _line, _offset) do
    {rest, args, ctx}
  end

  defp to_number(rest, [{:float, value}], ctx, _line, _offset) do
    {rest, [safe_parse_float(value)], ctx}
  end

  defp to_number(rest, [{:decimal, value}], ctx, _line, _offset) do
    {rest, [safe_parse_int(value)], ctx}
  end

  defp to_number(rest, [{base, value}], ctx, _line, _offset) do
    {rest, [{base, safe_parse_int(value, base)}], ctx}
  end

  defp safe_parse_float(value) do
    case Float.parse(value) do
      {value, _} -> value
      _ -> 0
    end
  end

  defp safe_parse_int(value, base \\ 10)
  defp safe_parse_int(value, :binary), do: safe_parse_int(value, 2)
  defp safe_parse_int(value, :octal), do: safe_parse_int(value, 8)
  defp safe_parse_int(value, :hex), do: safe_parse_int(value, 16)

  defp safe_parse_int(value, base) do
    case Integer.parse(value, base) do
      {value, _} -> value
      _ -> 0
    end
  end

  # tempo_filter =
  #   [
  #     {:nanosecond, :nanoseconds},
  #     {:microsecond, :microseconds},
  #     {:millisecond, :milliseconds},
  #     {:second, :seconds},
  #     {:minute, :minutes},
  #     {:hour, :hours},
  #     {:day, :days},
  #     {:week, :weeks},
  #     {:month, :months},
  #     {:year, :years},
  #     {:century, :centuries},
  #     {:millennium, :millennia}
  #   ]
  #   |> Enum.reduce([], fn {unit, p_unit}, acc ->
  #     s_unit = unit |> Atom.to_string()
  #     p_unit = p_unit |> Atom.to_string()

  #     [
  #       p_unit
  #       |> string()
  #       |> replace(%Exrow.Unit{unit: unit}),
  #       s_unit
  #       |> string()
  #       |> replace(%Exrow.Unit{unit: unit})
  #       | acc
  #     ]
  #   end)
  #   |> choice()
end
