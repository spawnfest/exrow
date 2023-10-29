defmodule Exrow.LengthTest do
  use ExUnit.Case

  alias Exrow.Runtime
  alias Exrow.Length

  describe "length units" do
    test "length units" do
      assert [{{Length, :meter}, 1}] = Runtime.calculate("1 meter")
      assert [{{Length, :centimeter}, 1}] = Runtime.calculate("1 centimeter")
      assert [{{Length, :meter}, 2.0}] = Runtime.calculate("1 meter + 1 meter")
      assert [{{Length, :meter}, 2.0}] = Runtime.calculate("1 meter + 1")
      assert [{{Length, :meter}, 2.0}] = Runtime.calculate("1 + 1 meter")
      assert [{{Length, :centimeter}, 101.0}] = Runtime.calculate("1 meter + 1 centimeter")
      assert [{{Length, :centimeter}, 202.0}] = Runtime.calculate("2 * (1 meter + 1 centimeter)")
    end
  end
end
