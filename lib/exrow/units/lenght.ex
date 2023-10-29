defmodule Exrow.Length do
  import NimbleParsec

  @units %{
    femtometer: {"femtometer", Float.pow(10.0, -15)},
    picometer: {"picometer", Float.pow(10.0, -12)},
    nanometre: {"nanometre", Float.pow(10.0, -9)},
    micrometre: {"micrometre", Float.pow(10.0, -6)},
    millimeter: {"millimeter", Float.pow(10.0, -3)},
    centimeter: {"centimeter", Float.pow(10.0, -2)},
    decimeter: {"decimeter", Float.pow(10.0, -1)},
    # Base
    meter: {"meter", Integer.pow(10, 0)},
    dekameter: {"dekameter", Integer.pow(10, 1)},
    hectometer: {"hectometer", Integer.pow(10, 2)},
    kilometer: {"kilometer", Integer.pow(10, 3)},
    # Variants
    mil: {"mil", 1},
    points: {"points", 0.0003527778},
    lines: {"lines", 1},
    inch: {"inch", 0.03},
    hand: {"hand", 1},
    foot: {"foot", 0.3},
    yard: {"yard", 0.91},
    rod: {"rod", 1},
    chain: {"chain", 20.12},
    furlong: {"furlong", 201.17},
    mile: {"mile", 1609.34},
    cable: {"cable", 185.32},
    nmi: {"nmi", 1853.18},
    league: {"league", 4828.03},
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
