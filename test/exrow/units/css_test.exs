defmodule Exrow.CssTest do
  use ExUnit.Case

  alias Exrow.Runtime
  alias Exrow.Css

  describe "css units" do
    test "css units" do
      assert [{{Css, :pixel}, 1}] = Runtime.calculate("1 px")
      assert [{{Css, :pixel}, 2.0}] = Runtime.calculate("1 px + 1 px")
      assert [{{Css, :point}, 1}] = Runtime.calculate("1 pt")
      assert [{{Css, :pixel}, 2.33}] = Runtime.calculate("1 pt + 1 px")
      assert [{{Css, :point}, 10.0}] = Runtime.calculate("2 px * 5 pt")
    end
  end
end
