defmodule Exrow.Calc do
  alias Exrow.Parser

  require Logger

  @init_ctx %{
    vars: %{
      "Pi" => {:float, 31_415_926_536, -10},
      "E" => {:float, 27_182_818_285, -10}
    },
    results: []
  }

  def calculate(lines) do
    lines
    |> String.split("\n")
    |> Enum.reduce(@init_ctx, &calc_line/2)
    |> case do
      %{results: results} -> Enum.reverse(results)
    end
  end

  def calc_line(line, %{results: results} = ctx) do
    case Parser.parse(line) do
      {:ok, expr} ->
        %{ctx | results: [dcalc_expr(expr, ctx) | results]}

      error ->
        Logger.error("Line parse error", inspect(error))
        %{ctx | results: [nil | results]}
    end
  end

  # TODO: implements this guard
  @number_kinds [:binary, :octal, :hex]

  # {kind, value}
  defguardp is_exrow_kind_number(v)
            when is_tuple(v) and tuple_size(v) == 2 and elem(v, 0) in @number_kinds and
                   is_number(elem(v, 1))

  # {kind, value} | value
  defguardp is_exrow_number(v) when is_number(v) or is_exrow_kind_number(v)

  def dcalc_expr(expr, ctx) do
    # IO.inspect(expr, label: "Expr")
    calc_expr(expr, ctx)
  end

  # Arithmetic Operators
  @arithmetic_ops [:^, :+, :-, :*, :/]
  defp calc_expr({op, left, right}, _ctx)
      when op in @arithmetic_ops and is_exrow_number(left) and is_exrow_number(right) do
    apply_op(op, left, right)
  end

  defp calc_expr({op, left, right}, ctx) when op in @arithmetic_ops do
    calc_expr({op, dcalc_expr(left, ctx), dcalc_expr(right, ctx)}, ctx)
  end

  # Anything else
  defp calc_expr("", _ctx), do: nil
  defp calc_expr(expr, _ctx) do
    # Logger.warn("Unsupported expr: #{expr}")
    expr
  end

  # Simple cases
  defp apply_op(op, left, right)
      when is_number(left) and is_number(right) and op in [:+, :-, :*, :/] do
    apply(Kernel, op, [left, right])
  end

  defp apply_op(:^, left, right) when is_float(right) do
    {:error, "Bad arithmetic: `#{left} ^ #{right}`"}
  end

  defp apply_op(:^, left, right) when is_float(left) or right < 0 do
    Float.pow(left * 1.0, right)
  end

  defp apply_op(:^, left, right) when is_integer(right) and is_integer(right) do
    Integer.pow(left, right)
  end

  # Unpack left
  defp apply_op(op, {_, left}, right), do: apply_op(op, left, right)

  # Unpack right, but keep the kind
  defp apply_op(op, left, {kind, right}) when is_number(left) do
    {kind, apply_op(op, left, right)}
  end
end
