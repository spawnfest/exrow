defmodule Exrow.ParserTest do
  use ExUnit.Case

  alias Exrow.Parser

  describe "#{Parser}" do
    test "integer numbers" do
      assert {:ok, 1_000_000} = Parser.parse("1_000_000")
      assert {:ok, 10} = Parser.parse("10")
      assert {:ok, 10} = Parser.parse("10 ")
      assert {:ok, {:binary, 0b10_10}} = Parser.parse("0b10_10")
      assert {:ok, {:binary, 0b1010}} = Parser.parse("0b1010")
      assert {:ok, {:octal, 0o777}} = Parser.parse("0o777")
      assert {:ok, {:hex, 0x1F}} = Parser.parse("0x1f")
      assert {:ok, {:hex, 0xFFFFFF}} = Parser.parse("0xFF_FF_FF")
    end

    test "float numbers" do
      assert {:ok, {:float, 109, -2}} = Parser.parse("1.09")
      assert {:ok, {:float, 1_000_456, -3}} = Parser.parse("1_000.45_6")
    end

    test "algebraic operators" do
      assert {:ok, {:+, 1, {:+, 1, 2}}} = Parser.parse("1 + 1 + 2")
      assert {:ok, {:+, {:hex, 1}, {:hex, 1}}} = Parser.parse("0x1 + 0x1")
      assert {:ok, {:+, 1, 1}} = Parser.parse("1 plus 1")
      assert {:ok, {:+, 1, 1}} = Parser.parse("1and1")
      assert {:ok, {:hex, 0x1AA}} = Parser.parse("0x1aand0x1")
      assert {:ok, {:+, 1, 1}} = Parser.parse("1 with 1")
      assert {:ok, {:-, 1, 1}} = Parser.parse("1 - 1")
      assert {:ok, {:-, 1, 1}} = Parser.parse("1 minus 1")

      assert {:ok, {:*, 2, 1}} = Parser.parse("2 * 1")
      assert {:ok, {:+, 2, {:*, 1, 5}}} = Parser.parse("2 + 1 * 5")

      # TODO Add options for the another operators
    end

    test "parentheses" do
      assert {:ok, {:*, {:*, 2, 1}, {:+, 3, 1}}} =
        Parser.parse("(2 * 1) (3 + 1)")

      assert {:ok, {:*, {:+, {:*, 2, 1}, 2}, {:+, 3, 1}}} =
               Parser.parse("(2 * 1 + 2)(3 + 1)")

      assert {:ok, {:+, {:+, 1, 2}, {:-, 3, {:/, {:*, 4, 5}, 7}}}} =
               Parser.parse("(1 + 2) + 3 - (4 * 5) / 7")
    end

    # test "parentheses" do
    #   assert {:ok, {:+, 1},1}]}} =
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
