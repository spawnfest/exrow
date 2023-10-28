defmodule DimensionFilter do
  defstruct dimensions: nil
end

defmodule Exrow.TimeUnit do
  defstruct value: nil, unit: nil
end

defmodule Exrow.Parser do
  import NimbleParsec

  blankspace =
    ignore(ascii_string([?\s, ?\n, ?\r, ?\t], min: 1))

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
        |> replace(%Exrow.TimeUnit{unit: unit}),
        s_unit
        |> string()
        |> replace(%Exrow.TimeUnit{unit: unit})
        | acc
      ]
    end)
    |> choice()

  defparsec(
    :mathdown_filter,
    integer(min: 1)
    |> concat(blankspace)
    |> concat(tempo_filter)
    |> post_traverse(:build_unit)
    |> eos()
  )

  def decode(value) do
    value
    |> String.trim()
    |> mathdown_filter()
  end

  defp build_unit(
    rest,
    [unit, value],
    ctx,
    _line,
    _offset
  ) do
    {rest, [%Exrow.TimeUnit{unit | value: value}], ctx}
  end
end
