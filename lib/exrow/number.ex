defmodule ExRow.Number do
  defstruct mantissa: nil, base: :decimal, exponent: 0

  def new({:float, [mantissa, exponent]}) do
    {mantissa, _} = Integer.parse("#{mantissa}#{exponent}")
    exponent = -String.length(exponent)

    %__MODULE__{mantissa: mantissa, exponent: exponent}
  end

  def new({base, mantissa}) do
    {mantissa, _} =
      Integer.parse(
        mantissa,
        case base do
          :binary -> 2
          :octal -> 8
          :decimal -> 10
          :hex -> 16
        end
      )

    %__MODULE__{mantissa: mantissa, base: base}
  end
end
