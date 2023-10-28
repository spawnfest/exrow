defmodule Exrow.Parser do
  import NimbleParsec

  alias ExRow.Number
  alias Exrow.Unit

  blankspace =
    ignore(ascii_string([?\s, ?\n, ?\r, ?\t], min: 1))

  numbers_separator = ignore(ascii_string([?_], min: 0))

  optional_separator =
    optional(
      numbers_separator
      |> concat(ascii_string([?0..?9], min: 1))
      |> times(min: 1)
      |> reduce({Enum, :join, [""]})
    )

  float_combinator =
    ascii_string([?0..?9], min: 1)
    |> concat(optional_separator)
    |> reduce({Enum, :join, [""]})
    |> ignore(string("."))
    |> concat(optional_separator)
    |> tag(:float)
    |> post_traverse(:to_number)

  integer_combinator =
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

  number_combinator = choice([float_combinator, integer_combinator])

  tempo_filter =
    [
      {:nanosecond, :nanoseconds},
      {:microsecond, :microseconds},
      {:millisecond, :milliseconds},
      {:second, :seconds},
      {:minute, :minutes},
      {:hour, :hours},
      {:day, :days},
      {:week, :weeks},
      {:month, :months},
      {:year, :years},
      {:century, :centuries},
      {:millennium, :millennia}
    ]
    |> Enum.reduce([], fn {unit, p_unit}, acc ->
      s_unit = unit |> Atom.to_string()
      p_unit = p_unit |> Atom.to_string()

      [
        p_unit
        |> string()
        |> replace(%Exrow.Unit{unit: unit}),
        s_unit
        |> string()
        |> replace(%Exrow.Unit{unit: unit})
        | acc
      ]
    end)
    |> choice()

  defparsec(
    :mathdown_filter,
    number_combinator
    # integer(min: 1)
    # |> concat(blankspace)
    # |> concat(tempo_filter)
    # |> post_traverse(:build_unit)
    |> eos()
  )

  def decode(value) do
    value
    |> String.trim()
    |> mathdown_filter()
  end

  defp to_number(rest, [arg], ctx, _line, _offset) do
    {rest, [Number.new(arg)], ctx}
  end
end
