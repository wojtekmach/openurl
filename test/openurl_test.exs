defmodule OpenURLTest do
  use ExUnit.Case, async: true
  doctest OpenURL
  import OpenURL

  @tag :tmp_dir
  test "file", %{tmp_dir: tmp_dir} do
    write("#{tmp_dir}/foo.txt", "bar")
    assert read("#{tmp_dir}/foo.txt") == "bar"

    assert read("file:#{tmp_dir}/foo.txt") == "bar"
    assert read("file://#{tmp_dir}/foo.txt") == "bar"
  end

  @tag :tmp_dir
  test "file zip", %{tmp_dir: tmp_dir} do
    write("#{tmp_dir}/foo.zip", [{"foo.txt", "bar"}])
    assert read("#{tmp_dir}/foo.zip") == [{"foo.txt", "bar"}]
  end

  @tag :tmp_dir
  test "file tar", %{tmp_dir: tmp_dir} do
    write("#{tmp_dir}/foo.tar", [{"foo.txt", "bar"}])
    assert read("#{tmp_dir}/foo.tar") == [{"foo.txt", "bar"}]
  end

  @tag :tmp_dir
  test "file tgz", %{tmp_dir: tmp_dir} do
    write("file:#{tmp_dir}/foo.tgz", [{"foo.txt", "bar"}])
    assert read("file:#{tmp_dir}/foo.tgz") == [{"foo.txt", "bar"}]

    write("#{tmp_dir}/foo.tar.gz", [{"foo.txt", "bar"}])
    assert read("#{tmp_dir}/foo.tar.gz") == [{"foo.txt", "bar"}]
  end

  @tag :tmp_dir
  test "file html", %{tmp_dir: tmp_dir} do
    html = "<p><span>foo</span> <span>bar</span></p>"
    write("#{tmp_dir}/foo.html", html)
    assert read("#{tmp_dir}/foo.html") == EasyHTML.parse!(html)

    write("#{tmp_dir}/foo.html", EasyHTML.parse!(html))
  end

  @tag :tmp_dir
  test "file markdown", %{tmp_dir: tmp_dir} do
    markdown = "_hello_"
    write("#{tmp_dir}/foo.md", markdown)
    assert read("#{tmp_dir}/foo.md") == [{"p", [], [{"em", [], ["hello"], %{}}], %{}}]
  end

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
