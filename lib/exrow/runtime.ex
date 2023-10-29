defmodule Exrow.Runtime do
  alias Exrow.Parser

  import Exrow.Parser

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

  def calc_line(line, %{vars: vars, results: results} = ctx) do
    case Parser.parse(line) do
      {:ok, {:=, identify, expr}} ->
        case dcalc_expr(expr, ctx) do
          {:error, _} = result ->
            %{ctx | results: [result | results]}

          result ->
            %{ctx | vars: Map.put(vars, identify, result), results: [result | results]}
        end

      {:ok, expr} ->
        %{ctx | results: [dcalc_expr(expr, ctx) | results]}

      error ->
        Logger.error("Line parse error", inspect(error))
        %{ctx | results: [nil | results]}
    end
  end

  def dcalc_expr(expr, ctx) do
    # IO.inspect(expr, label: "Expr")
    calc_expr(expr, ctx)
  end

  # Nothing
  defp calc_expr("", _ctx), do: nil

  # Arithmetic Operators
  @arithmetic_ops [:^, :+, :-, :*, :/, :**]
  defp calc_expr({op, left, right}, _ctx)
       when op in @arithmetic_ops and is_exrow_number(left) and is_exrow_number(right) do
    apply_op(op, left, right)
  end

  defp calc_expr({op, left, right} = current, ctx) when op in @arithmetic_ops do
    {op, dcalc_expr(left, ctx), dcalc_expr(right, ctx)}
    |> case do
      ^current -> {:error, "Bad expression: `#{inspect(left)} ^ #{inspect(right)}`"}
      new -> calc_expr(new, ctx)
    end
  end

  # Variables
  defp calc_expr(identifier, %{vars: vars}) when is_binary(identifier) do
    Map.get(vars, identifier, nil)
  end

  # Anything else
  defp calc_expr(expr, _ctx) do
    # Logger.warn("Unsupported expr: #{expr}")
    expr
  end

  # Simple cases
  defp apply_op(:**, left, right) when right < 0 do
    Float.pow(left * 1.0, right)
  end

  defp apply_op(op, left, right)
       when is_number(left) and is_number(right) and op in [:**, :+, :-, :*, :/] do
    apply(Kernel, op, [left, right])
  end

  # Units parse
  # {op, unit, unit}
  defp apply_op(op, {{module, l_unit}, l_value} = left, {{module, r_unit}, r_value} = right)
       when is_unit(left) and is_unit(right) do
    l_value = apply(module, :to_base, [l_unit, l_value])
    r_value = apply(module, :to_base, [r_unit, r_value])
    apply(module, :to_unit, [r_unit, apply_op(op, l_value, r_value)])
  end

  # {op, unit, number}
  defp apply_op(op, {{module, l_unit}, l_value} = left, r_value)
       when is_number(r_value) and is_unit(left) do
    l_value = apply(module, :to_base, [l_unit, l_value])
    apply(module, :to_unit, [l_unit, apply_op(op, l_value, r_value)])
  end

  # {op, number, unit}
  defp apply_op(op, l_value, {{module, r_unit}, r_value} = right)
       when is_number(l_value) and is_unit(right) do
    r_value = apply(module, :to_base, [r_unit, r_value])
    apply(module, :to_unit, [r_unit, apply_op(op, l_value, r_value)])
  end

  # Unpack left
  defp apply_op(op, {_, left}, right), do: apply_op(op, left, right)

  # Unpack right, but keep the kind
  defp apply_op(op, left, {kind, right}) when is_number(left) do
    {kind, apply_op(op, left, right)}
  end

  defp apply_op(op, left, right) do
    {:error, "Bad arithmetic: `#{left} #{op} #{right}`"}
  end
end
