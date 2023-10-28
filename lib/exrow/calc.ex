defmodule Exrow.Calc do
  alias Exrow.Parser

  require Logger

  @init_ctx %{
    vars: %{
      "Pi" => {:float, 31_415_926_536, -10},
      "E" => {:float, 27_182_818_285, -10}
    },
    result: []
  }

  def calculate(lines) do
    lines
    |> String.split("\n")
    |> Enum.reduce(@init_ctx, &calc_line/2)
    |> case do
      %{result: result} -> Enum.reverse(result)
    end
  end

  def calc_line(line, %{result: result} = ctx) do
    case Parser.parse(line) do
      {:ok, expr} ->
        %{ctx | result: [calc_expr(expr, ctx) | result]}

      error ->
        Logger.error("Line parse error", inspect(error))
        %{ctx | result: [nil | result]}
    end
  end

  def calc_expr("", _ctx), do: nil
  def calc_expr(value, _ctx) when is_number(value), do: value
  def calc_expr({:binary, _} = value, _ctx), do: value
  def calc_expr({:octal, _} = value, _ctx), do: value
  def calc_expr({:hex, _} = value, _ctx), do: value

  def calc_expr({:-, value}, ctx) do
    case calc_expr(value, ctx) do
      {kind, value} -> {kind, -value}
      value -> -value
    end
  end

  def calc_expr({op, left, right}, ctx) when op in [:^, :+, :-, :*, :/] do
    left = calc_expr(left, ctx) |> to_value()

    case calc_expr(right, ctx) do
      {kind, value} -> {kind, apply_op(op, left, value)}
      value -> apply_op(op, left, value)
    end
  end

  def apply_op(:^, left, right) when is_float(left) or is_float(right), do: Float.pow(left, right)
  def apply_op(:^, left, right) when right < 0, do: Float.pow(left * 1.0, right)
  def apply_op(:^, left, right), do: Integer.pow(left, right)

  def apply_op(op, left, right) when op in [:+, :-, :*, :/] do
    apply(Kernel, op, [left, right])
  end

  def to_value(value) when is_number(value), do: value
  def to_value({:binary, value}), do: value
  def to_value({:octal, value}), do: value
  def to_value({:hex, value}), do: value
end
