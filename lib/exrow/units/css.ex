defmodule Exrow.Css do
  import NimbleParsec

  @units %{
    # Base
    pixel: {"px", 1},
    point: {"pt", 1.33},
    inch: {"inch", 96},
  }

  def combinators() do
    @units
    |> Enum.map(fn {unit, {form, _}} ->
      string(form)
      |> ignore()
      |> tag({__MODULE__, unit})
    end)
  end

  def to_base(unit, value) do
    value * elem(@units[unit], 1)
  end

  def to_unit(unit, value) do
    {{__MODULE__, unit}, value / elem(@units[unit], 1)}
  end
end
