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

  # {:float, mantissa, exponent}
  defguardp is_exrow_float(v) when is_tuple(v) and tuple_size(v) == 3 and elem(v, 0) == :float

  # {kind, value}
  defguardp is_exrow_kind_number(v)
            when is_tuple(v) and tuple_size(v) == 2 and elem(v, 0) in @number_kinds and
                   is_number(elem(v, 1))

  # {:float, _, _} | {kind, value} | value
  defguardp is_exrow_number(v) when is_number(v) or is_exrow_float(v) or is_exrow_kind_number(v)

  def dcalc_expr(expr, ctx) do
    IO.inspect(expr, label: "Expr")
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
  defp apply_op(:+, {:float, l_mantissa, l_exponent}, {:float, r_mantissa, r_exponent}) do
    {:float, l_mantissa + r_mantissa, min(l_exponent, r_exponent)}
  end

  defp apply_op(:*, left, {:float, r_mantissa, r_exponent}) do
    {:float, left * r_mantissa, r_exponent}
  end

  defp apply_op(:*, left, {:float, r_mantissa, r_exponent}) do
    {:float, left * r_mantissa, r_exponent}
  end

  defp apply_op(op, left, right)
      when is_number(left) and is_number(right) and op in [:+, :-, :*, :/] do
    apply(Kernel, op, [left, right])
  end

  defp apply_op(:^, left, right) when right < 0 do
    Parser.parse("#{Float.pow(left * 1.0, right) |> IO.inspect()}") |> IO.inspect()
    |> case do
      {:ok, float} -> float
      _error -> 0
    end
  end

  defp apply_op(:^, left, right) when is_number(right) and is_number(right) do
    Integer.pow(left, right)
  end

  # Unpack left
  defp apply_op(op, {_, left}, right), do: apply_op(op, left, right)

  # Unpack right, but keep the kind
  defp apply_op(op, left, {kind, right}) when is_number(left) do
    {kind, apply_op(op, left, right)}
  end

  # defp calc_expr({:-, {:float, mantissa, exponent}}, _ctx), do: {:float, -mantissa, exponent}
  # defp calc_expr({:-, expr}, ctx), do: dcalc_expr({:-, dcalc_expr(expr, ctx)}, ctx)

  # defp calc_expr({:^, left, right}, _ctx) when is_float(left) or is_float(right),
  #   do: Float.pow(left, right)

  # defp calc_expr({:^, left, right}, _ctx) when right < 0, do: Float.pow(left * 1.0, right)
  # defp calc_expr({:^, left, right}, _ctx) when is_number(right), do: Integer.pow(left, right)

  # TODO: all the options should be covered to avoid loop
  # defp raw_value(value) when is_exrow_float(value), do: value
  # defp raw_value({_, value} = expr) when number_kind?(expr), do: value
  # defp raw_value(value), do: value

  # Unpack complex types
  # @arithmetic_ops [:^, :+, :-, :*, :/]
  # defp calc_expr({op, left, right}, ctx) when not is_number(left) and op in @arithmetic_ops do
  #   dcalc_expr({op, dcalc_expr(left, ctx) |> raw_value(), right}, ctx)
  # end

  # defp calc_expr({op, left, {:float, _, _} = right}, ctx) when op in @arithmetic_ops do
  #   Parser.parse("#{dcalc_expr({op, left, dcalc_expr(right, ctx) |> raw_value()}, ctx)}")
  #   |> case do
  #     {:ok, float} -> float
  #     _error -> 0
  #   end
  # end

  # defp calc_expr({op, left, {kind, value}}, ctx)
  #     when kind in @number_kinds and op in @arithmetic_ops do
  #   {kind, dcalc_expr({op, left, value}, ctx)}
  # end

  # defp calc_expr({op, left, right}, ctx) when not is_number(right) do
  #   dcalc_expr({op, left, dcalc_expr(right, ctx)}, ctx)
  # end

  # Arithmetic operations
  # defp calc_expr({:-, value}, _ctc) when is_number(value), do: -value

  # defp calc_expr({:-, {kind, value}}, _ctc) when is_atom(kind) and is_number(value),
  #   do: {kind, -value}
end
