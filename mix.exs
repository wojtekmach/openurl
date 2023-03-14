defmodule OpenURL.MixProject do
  use Mix.Project

  def project do
    [
      app: :openurl,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {OpenURL.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix_client, "~> 0.3"},
      {:req_easyhtml, ">= 0.0.0"},
      {:jason, "~> 1.0"},
      {:postgrex, ">= 0.0.0"},
      {:myxql, ">= 0.0.0"},
      {:easyhtml, ">= 0.0.0"},
      {:easyrss, ">= 0.0.0", github: "wojtekmach/easyrss"},
      {:earmark_parser, ">= 0.0.0"}
    ]
  end
end
