defmodule Exrow.ParserTest do
  use ExUnit.Case

  alias ExRow.Number
  alias Exrow.Parser

  describe "#{Parser}" do
    test "integer numbers" do
      assert {:ok, [%Number{mantissa: 1_000_000, base: :decimal, exponent: 0}], _, _, _, _} =
               Parser.decode("1_000_000")

      assert {:ok, [%Number{mantissa: 10, base: :decimal, exponent: 0}], _, _, _, _} =
               Parser.decode("10")

      assert {:ok, [%Number{mantissa: 10, base: :decimal, exponent: 0}], _, _, _, _} =
               Parser.decode("10 ")

      assert {:ok, [%Number{mantissa: 0b10_10, base: :binary, exponent: 0}], _, _, _, _} =
               Parser.decode("0b10_10")

      assert {:ok, [%Number{mantissa: 0b1010, base: :binary, exponent: 0}], _, _, _, _} =
               Parser.decode("0b1010")

      assert {:ok, [%Number{mantissa: 0o777, base: :octal, exponent: 0}], _, _, _, _} =
               Parser.decode("0o777")

      assert {:ok, [%Number{mantissa: 0x1F, base: :hex, exponent: 0}], _, _, _, _} =
               Parser.decode("0x1f")

      assert {:ok, [%Number{mantissa: 0xFFFFFF, base: :hex, exponent: 0}], _, _, _, _} =
                Parser.decode("0xFF_FF_FF")
    end

    test "float numbers" do
      assert {:ok, [%Number{mantissa: 109, base: :decimal, exponent: -2}], _, _, _, _} =
        Parser.decode("1.09")

      assert {:ok, [%Number{mantissa: 1_000_456, base: :decimal, exponent: -3}], _, _, _, _} =
          Parser.decode("1_000.45_6")
    end

    # test "dimension_filter" do
    #   assert {:ok, [%Exrow.TimeUnit{value: 10, unit: :nanosecond}], _, _, _, _} =
    #            Parser.decode("10 nanosecond ")

    #   assert {:ok, [%Exrow.TimeUnit{unit: :nanosecond}], _, _, _, _} =
    #            Parser.decode("100 nanoseconds")

    #   assert {:ok, [%Exrow.TimeUnit{unit: :year}], _, _, _, _} =
    #             Parser.decode("1 years")
    # end
  end
end
