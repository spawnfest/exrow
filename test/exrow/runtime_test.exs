defmodule Exrow.RuntimeTest do
  use ExUnit.Case

  alias Exrow.Runtime

  describe "#{Runtime}" do
    test "ignore some lines" do
      # Invalid lines
      assert [nil] = Runtime.calculate("# Title")
      assert [nil] = Runtime.calculate("(1 * 2")
    end

    test "arithmetic with integers" do
      assert [-1] = Runtime.calculate("-1")
      assert [-2] = Runtime.calculate("- (0b001 + 1)")
      assert [1] = Runtime.calculate("-1 + 2")
      assert [{:binary, -0b01}] = Runtime.calculate("-0b001")
      assert [{:binary, -0b10}] = Runtime.calculate("- (1 + 0b001)")

      assert [-2] = Runtime.calculate("2 * -1")
      assert [2] = Runtime.calculate("2 * +1")

      assert [2, 1] = Runtime.calculate("1 + 1\n2 - 1")
      assert [4, 1.0] = Runtime.calculate("2 * 2\n2 / 2")
      assert [3] = Runtime.calculate("(1 * 2 + 1)")

      assert [{:binary, 1}] = Runtime.calculate("0b001")
      assert [{:binary, 0b10}] = Runtime.calculate("1 + 0b1")

      assert [8] = Runtime.calculate("2 pow 3")
      assert [8] = Runtime.calculate("2 ^ 3")
    end

    test "arithmetics with floats" do
      assert [-1.1] = Runtime.calculate("-1.1")
      assert [3.3] = Runtime.calculate("2. + 1.3")
      assert [2.4000000000000004] = Runtime.calculate("1.1 + 1.3")
      assert [2.4450000000000003] = Runtime.calculate("1.1 + 1.345")
      assert [0.19999999999999996] = Runtime.calculate("-1.1 + 1.3")
      assert [-2.4000000000000004] = Runtime.calculate("-1.1 - 1.3")

      assert [1.234] = Runtime.calculate("1234 * (10 pow -3)")
      assert [1.234] = Runtime.calculate("(10 pow -3) * 1234")
      assert [10.0] = Runtime.calculate("10 ^ 1.0")
    end

    test "using variables" do
      assert [1] = Runtime.calculate("var = 1")
      assert [1] = Runtime.calculate("  var2 = 1")

      assert [1, 2, 3, 0, 3] = Runtime.calculate(~s{
        var1 = 1
        var2 = var1 + 1
        var3 = 1 + var2
        var2 = 0
        var2 + var3
      } |> String.trim())

      assert [1, 2, 3] = Runtime.calculate(~s{
        var1 = 1
        var2 = 2
        var1 + var2
      } |> String.trim())
    end
  end
end
