defmodule Exrow.ParserTest do
  use ExUnit.Case

  alias Exrow.Parser
  alias Exrow.Length

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
      assert {:ok, 1.09} = Parser.parse("1.09")
      assert {:ok, 1_000.45_6} = Parser.parse("1_000.45_6")
    end

    test "signal numbers" do
      assert {:ok, -1_000_000} = Parser.parse("-1_000_000")
      assert {:ok, {:binary, -0b10_10}} = Parser.parse("- 0b10_10")

      assert {:ok, -1.09} = Parser.parse("-1.09")
      assert {:ok, -1_000.456} = Parser.parse("- 1_000.45_6")
    end

    test "algebraic operators with unsigned" do
      assert {:ok, {:+, 1, 1}} = Parser.parse("1 + 1")
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

    test "algebraic operators with signed" do
      assert {:ok, {:+, 1, {:-, 1, 2}}} = Parser.parse("1 + 1 - 2")
      assert {:ok, {:/, 1, -2}} = Parser.parse("1 / -2")
      assert {:ok, {:*, 1, -2}} = Parser.parse("1 * -2")
      assert {:ok, {:*, 1, {:*, -1, 2}}} = Parser.parse("1 * -(2)")
      assert {:ok, {:*, 1, {:*, -1, {:+, 2, 1}}}} = Parser.parse("1 * -(2 + 1)")

      assert {:ok, {:/, 1, 2}} = Parser.parse("1 / +2")
      assert {:ok, {:*, 1, 2}} = Parser.parse("1 * +2")
      assert {:ok, {:*, 1, 2}} = Parser.parse("(1 * +2)")
      assert {:ok, {:*, 1, -2}} = Parser.parse("(1 * -2)")
      assert {:ok, {:*, 1, 2}} = Parser.parse("1 * +(2)")
      assert {:ok, {:+, {:*, 1, 1}, 2}} = Parser.parse("1 * 1 + (2)")
      assert {:ok, {:*, 1, {:+, 2, 1}}} = Parser.parse("1 * +(2 + 1)")
      assert {:ok, {:*, -1, {:+, {:binary, 1}, 1}}} = Parser.parse("- (0b001 + 1)")
      assert {:ok, {:*, 2, {:*, -1, {:+, {:binary, 1}, 1}}}} = Parser.parse("2 * - (0b001 + 1)")

      assert {:ok, {:/, -1, -2}} = Parser.parse("-1 / -2")
      assert {:ok, {:/, 1, -2}} = Parser.parse("+1 / -2")
      assert {:ok, {:*, -1, 2}} = Parser.parse("(-1) * +2")
      assert {:ok, {:*, -1, 2}} = Parser.parse("-1 * +2")
      assert {:ok, {:*, 1, 2}} = Parser.parse("1 * +(2)")
      assert {:ok, {:*, 1, {:+, 2, 1}}} = Parser.parse("1 * +(2 + 1)")
    end

    test "parentheses" do
      assert {:ok, {:*, {:*, 2, 1}, {:+, 3, 1}}} =
               Parser.parse("(2 * 1) (3 + 1)")

      assert {:ok, {:*, {:+, {:*, 2, 1}, 2}, {:+, 3, 1}}} =
               Parser.parse("(2 * 1 + 2)(3 + 1)")

      assert {:ok, {:+, {:+, 1, 2}, {:-, 3, {:/, {:*, 4, 5}, 7}}}} =
               Parser.parse("(1 + 2) + 3 - (4 * 5) / 7")
    end

    test "set variable" do
      assert {:ok, {:=, "result", {:*, {:*, 2, 1}, {:+, 3, 1}}}} =
               Parser.parse("result = (2 * 1) (3 + 1)")

      assert {:ok, {:=, "more_complex_1", {:binary, 2}}} =
               Parser.parse("more_complex_1 = 0b10")
    end

    test "use variables" do
      assert {:ok, {:+, "va1", 10}} = Parser.parse("va1 + 10")
      assert {:ok, {:+, "va1", {:*, "va2", "va3"}}} = Parser.parse("va1 + va2 * va3")
      assert {:ok, {:+, "va1", {:*, "va2", "va3"}}} = Parser.parse("va1 + va2 mul va3")
    end

    test "length units" do
      assert {:ok, {{Length, :meter}, 10}} = Parser.parse("10 meter")
      assert {:ok, {{Length, :mil}, 10}} = Parser.parse("10mil")
      # assert {:ok, {:chain, {:hex, 0xFF}}} = Parser.parse("0xFF chain")
      # assert {:ok, {:inch, 10.05}} = Parser.parse("10.05 inch")

      # assert {:ok, {:+, {:meter, 10}, 2}} = Parser.parse("10 meter + 2")
    end

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
