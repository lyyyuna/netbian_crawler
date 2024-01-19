defmodule NetbianCrawler.MixProject do
  use Mix.Project

  def project do
    [
      app: :netbian_crawler,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {NetbianCrawler.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.35.0"},
      {:finch, "~> 0.17"},
      {:poolboy, "~> 1.5.2"}
    ]
  end
end
