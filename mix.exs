defmodule Vite.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/mazz-seven/elixir-vite"

  def project do
    [
      app: :vite,
      version: @version,
      elixir: "~> 1.11",
      deps: deps(),
      description: "Mix tasks for invoking vite",
      package: [
        links: %{"GitHub" => @source_url, "vite" => "https://vitejs.dev/"},
        licenses: ["MIT"]
      ],
      docs: [
        source_url: @source_url,
        source_ref: "v#{@version}"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, inets: :optional, ssl: :optional],
      mod: {Vite, []},
      env: [default: []]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
