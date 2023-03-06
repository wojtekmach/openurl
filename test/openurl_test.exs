defmodule OpenURLTest do
  use ExUnit.Case, async: true
  doctest OpenURL
  import OpenURL

  test "erts:processes" do
    read("erts:processes")
    |> Enum.take(5)
    |> dbg()
  end

  test "erts:processes/:pid" do
    read("erts:processes/0.0.0")
    |> dbg()
  end

  test "elixir:runtime_info" do
    read("elixir:runtime_info")
    |> dbg()
  end

  test "elixir:eval" do
    assert write("elixir:eval", "a = 1 + 2") == {3, [a: 3]}
  end

  test "erlang:eval" do
    assert write("erlang:eval", "A = 1 + 2.") == {3, %{A: 3}}
  end

  @tag :tmp_dir
  test "zip", %{tmp_dir: tmp_dir} do
    write("zip:#{tmp_dir}/foo.zip", [{"foo.txt", "bar"}])
    assert read("zip:#{tmp_dir}/foo.zip") == [{"foo.txt", "bar"}]
  end

  @tag :tmp_dir
  test "tar", %{tmp_dir: tmp_dir} do
    write("tar:#{tmp_dir}/foo.tar", [{"foo.txt", "bar"}])
    assert read("tar:#{tmp_dir}/foo.tar") == [{"foo.txt", "bar"}]
  end

  @tag :tmp_dir
  test "tgz", %{tmp_dir: tmp_dir} do
    write("tgz:#{tmp_dir}/foo.tgz", [{"foo.txt", "bar"}])
    assert read("tgz:#{tmp_dir}/foo.tgz") == [{"foo.txt", "bar"}]
  end

  test "postgres" do
    write("postgres:", "SELECT NOW()")
    |> dbg()
  end

  @tag :skip
  test "mysql" do
    write("mysql:", "SELECT NOW()")
    |> dbg()
  end
end
