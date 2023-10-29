defmodule Exrow.CalcTest do
  use ExUnit.Case

  alias Exrow.Calc

  describe "#{Calc}" do
    test "ignore some lines" do
      # Invalid lines
      assert [nil] = Calc.calculate("# Title")
      assert [nil] = Calc.calculate("(1 * 2")
    end

    test "arithmetic with integers" do
      # assert [-1] = Calc.calculate("-1")
      assert [-2] = Calc.calculate("- (0b001 + 1)")
      assert [1] = Calc.calculate("-1 + 2")
      assert [{:binary, -0b01}] = Calc.calculate("-0b001")
      assert [{:binary, -0b10}] = Calc.calculate("- (1 + 0b001)")

      assert [-2] = Calc.calculate("2 * -1")
      assert [2] = Calc.calculate("2 * +1")

      assert [2, 1] = Calc.calculate("1 + 1\n2 - 1")
      assert [4, 1.0] = Calc.calculate("2 * 2\n2 / 2")
      assert [3] = Calc.calculate("(1 * 2 + 1)")

      assert [{:binary, 1}] = Calc.calculate("0b001")
      assert [{:binary, 0b10}] = Calc.calculate("1 + 0b1")

      assert [8] = Calc.calculate("2 pow 3")
      assert [8] = Calc.calculate("2 ^ 3")
    end

    test "arithmetics with floats" do
      assert [{:float, -11, -1}] = Calc.calculate("-1.1")
      assert [{:float, 24, -1}] = Calc.calculate("1.1 + 1.3")
      assert [{:float, 2445, -3}] = Calc.calculate("1.1 + 1.345")

      # assert [{:float, 2, -1}] = Calc.calculate("-1.1 + 1.3")
      # assert [{:float, 2, -1}] = Calc.calculate("2. + 1.3")
      # assert [{:float, -24, -1}] = Calc.calculate("-1.1 - 1.3")
      # assert [{:float, 1234, -3}] = Calc.calculate("1234 * (10 pow -3)")
      # assert [{:float, 1234, -3}] = Calc.calculate("(10 pow -3) * 1234")

      # assert [3] = Calc.calculate("label: 1 + 2")

      # NEXT:
        # - calculate with float and units
        # - add more operators
        # - and variable set and expand
    end
  end
end
