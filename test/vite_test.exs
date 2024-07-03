defmodule ViteTest do
  use ExUnit.Case
  doctest Vite

  test "greets the world" do
    assert Vite.hello() == :world
  end
end
