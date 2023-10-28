defmodule Exrow.Parser do
  import NimbleParsec

  # alias ExRow.Number
  # alias Exrow.Unit

  # term_op  := * | /
  # expr_op    := in | + | - | ^ | rem | & | \| | xor | << | >>
  # float      := 0.1 | 10_00.50 | ...
  # integer    := 0 | 0b01 | 1_000 | ...
  # number     := float | integer
  # factor     := ( expr ) | ( expr ) ( expr ) | number
  # term       := factor term_op term | factor
  # expr       := term expr_op expr | term

  # identifier := not(operator) & not(number)
  # var        := identifier = expr

  space = ignore(ascii_string([?\s, ?\t], min: 1))

  expr_op =
    [
      {:in, ["in", "into", "as", "to"]},
      {:+, ["+", "plus", "and", "with"]},
      {:-, ["-", "minus", "subtract", "without"]},
      {:^, ["^", "pow"]},
      {:rem, ["rem", "mod"]},
      {:and, ["&"]},
      {:or, ["|"]},
      {:xor, ["xor"]},
      {:<<<, ["<<"]},
      {:>>>, [">>"]}
    ]
    |> Enum.map(fn {symbol, alternatives} ->
      ["#{symbol}" | alternatives]
      |> Enum.map(&string(&1))
      |> choice()
      |> replace(symbol)
    end)

  term_op =
    [
      {:*, ["*", "times", "multiplied by", "mul"]},
      {:/, ["/", "divide", "divide by"]}
    ]
    |> Enum.map(fn {symbol, alternatives} ->
      ["#{symbol}" | alternatives]
      |> Enum.map(&string(&1))
      |> choice()
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

  float =
    ascii_string([?0..?9], min: 1)
    |> concat(optional_separator)
    |> reduce({Enum, :join, [""]})
    |> ignore(string("."))
    |> concat(optional_separator)
    |> tag(:float)
    |> post_traverse(:to_number)

  integer =
    [
      {:binary, ignore(string("0b")), ascii_string([?0..?1], min: 1)},
      {:octal, ignore(string("0o")), ascii_string([?0..?8], min: 1)},
      {:hex, ignore(string("0x")), ascii_string([?0..?9, ?a..?f, ?A..?F], min: 1)},
      {:decimal, empty(), ascii_string([?0..?9], min: 1)}
    ]
    |> Enum.map(fn {system, prefix, numbers} ->
      prefix
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

  number = choice([float, integer])

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
        number
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
  defparsec(:mathdown, parsec(:expr))

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

  defp to_prefixed(rest, [{:factor, [left, right]}], ctx, _line, _offset) do
    {rest, [{:*, left, right}], ctx}
  end

  defp to_prefixed(rest, [{:factor, expr}], ctx, _line, _offset) do
    {rest, expr, ctx}
  end

  defp to_prefixed(rest, [{_, [left, op, right]}], ctx, _line, _offset) do
    {rest, [{op, left, right}], ctx}
  end

  defp to_prefixed(rest, args, ctx, _line, _offset) do
    {rest, args, ctx}
  end

  defp to_number(rest, [{:float, [mantissa, exponent]}], ctx, _line, _offset) do
    mantissa = safe_parse_int("#{mantissa}#{exponent}")
    exponent = -String.length(exponent)
    {rest, [{:float, mantissa, exponent}], ctx}
  end

  defp to_number(rest, [{:decimal, value}], ctx, _line, _offset) do
    {rest, [safe_parse_int(value)], ctx}
  end

  defp to_number(rest, [{base, value}], ctx, _line, _offset) do
    {rest, [{base, safe_parse_int(value, base)}], ctx}
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
