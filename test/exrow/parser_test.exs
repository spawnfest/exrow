defmodule Exrow.ParserTest do
  use ExUnit.Case

  alias ExRow.Number
  alias Exrow.Parser

  describe "#{Parser}" do
    test "integer numbers" do
      assert {:ok, %Number{mantissa: 1_000_000, base: :decimal, exponent: 0}} =
               Parser.parse("1_000_000")

      assert {:ok, %Number{mantissa: 10, base: :decimal, exponent: 0}} =
               Parser.parse("10")

      assert {:ok, %Number{mantissa: 10, base: :decimal, exponent: 0}} =
               Parser.parse("10 ")

      assert {:ok, %Number{mantissa: 0b10_10, base: :binary, exponent: 0}} =
               Parser.parse("0b10_10")

      assert {:ok, %Number{mantissa: 0b1010, base: :binary, exponent: 0}} =
               Parser.parse("0b1010")

      assert {:ok, %Number{mantissa: 0o777, base: :octal, exponent: 0}} =
               Parser.parse("0o777")

      assert {:ok, %Number{mantissa: 0x1F, base: :hex, exponent: 0}} =
               Parser.parse("0x1f")

      assert {:ok, %Number{mantissa: 0xFFFFFF, base: :hex, exponent: 0}} =
               Parser.parse("0xFF_FF_FF")
    end

    test "float numbers" do
      assert {:ok, %Number{mantissa: 109, base: :decimal, exponent: -2}} =
               Parser.parse("1.09")

      assert {:ok, %Number{mantissa: 1_000_456, base: :decimal, exponent: -3}} =
               Parser.parse("1_000.45_6")
    end

    test "algebraic operators" do
      assert {:ok, {:+, [%Number{mantissa: 1}, %Number{mantissa: 1}]}} =
               Parser.parse("1 + 1")

      # assert {:ok, {:+, {:+, [%Number{mantissa: 1}, %Number{mantissa: 1}]}, %Number{mantissa: 2}}} =
      #          Parser.parse("1 + 1 + 2")

      assert {:ok, {:+, [%Number{mantissa: 1, base: :hex}, %Number{mantissa: 1, base: :hex}]}} =
               Parser.parse("0x1 + 0x1")

      assert {:ok, {:+, [%Number{mantissa: 1}, %Number{mantissa: 1}]}} =
               Parser.parse("1 plus 1")

      assert {:ok, {:+, [%Number{mantissa: 1}, %Number{mantissa: 1}]}} =
               Parser.parse("1and1")

      assert {:ok, %Number{mantissa: 0x1AA, base: :hex}} =
               Parser.parse("0x1aand0x1")

      assert {:ok, {:+, [%Number{mantissa: 1}, %Number{mantissa: 1}]}} =
               Parser.parse("1 with 1")

      assert {:ok, {:-, [%Number{mantissa: 1}, %Number{mantissa: 1}]}} =
               Parser.parse("1 - 1")

      assert {:ok, {:-, [%Number{mantissa: 1}, %Number{mantissa: 1}]}} =
               Parser.parse("1 minus 1")

      # TODO Add options for the another operators
    end

    # test "parentheses" do
    #   assert {:ok, {:+, [%Number{mantissa: 1}, %Number{mantissa: 1}]}} =
    #            Parser.parse("(1 + 1)")
    # end

    # test "dimension_filter" do
    #   assert {:ok, [%Exrow.TimeUnit{value: 10, unit: :nanosecond}], _, _, _, _} =
    #            Parser.parse("10 nanosecond ")

    #   assert {:ok, [%Exrow.TimeUnit{unit: :nanosecond}], _, _, _, _} =
    #            Parser.parse("100 nanoseconds")

    #   assert {:ok, [%Exrow.TimeUnit{unit: :year}], _, _, _, _} =
    #             Parser.parse("1 years")
    # end
  end
end
