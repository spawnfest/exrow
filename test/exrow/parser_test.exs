defmodule Exrow.ParserTest do
  use ExUnit.Case

  alias Exrow.Parser

  describe "#{Parser}" do
    test "dimension_filter" do
      assert {:ok, [%Exrow.TimeUnit{value: 10, unit: :nanosecond}], _, _, _, _} =
               Parser.decode("10 nanosecond ")

      assert {:ok, [%Exrow.TimeUnit{unit: :nanosecond}], _, _, _, _} =
               Parser.decode("100 nanoseconds")

      assert {:ok, [%Exrow.TimeUnit{unit: :year}], _, _, _, _} =
                Parser.decode("1 years")
    end
  end
end
