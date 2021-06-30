defmodule Astrox.Mixfile do
  use Mix.Project

  @description "Elixir library for the Force.com / SalesForce / SFDC REST API"
  @github "https://github.com/ChapterSpot/astrox"

  def project do
    [
      app: :astrox,
      version: get_version(),
      elixir: "~> 1.11",
      name: "Astrox",
      description: @description,
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.post": :test,
        docs: :dev,
        "hex.docs": :dev
      ],
      dialyzer: dialyzer(),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :transitive,
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp get_version, do: File.read!("VERSION") |> String.trim()

  defp files, do: ~w(lib mix.exs README* VERSION)

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [extra_applications: [:logger, :httpoison, :erlsom, :exjsx, :ssl, :html_entities, :poison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.13 or ~> 1.0"},
      {:exjsx, "< 5.0.0"},
      {:poison, "~> 2.0 or ~> 3.1"},
      {:timex, "~> 2.0 or ~> 3.0"},
      {:erlsom, "~> 1.4"},
      {:excoveralls, "~> 0.5", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:earmark, "~> 1.1", only: :dev, override: true},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev, :test], runtime: false},
      {:mox, "~> 0.3", only: :test},
      {:mix_test_watch, "~> 0.5", only: [:dev, :test], runtime: false},
      {:html_entities, "~> 0.4"},
      {:telemetry, "~> 0.4.1"}
    ]
  end

  defp package do
    [
      organization: "chapterspot",
      description: @description,
      maintainers: ["Manuel Zubieta"],
      licenses: ["MIT"],
      files: files(),
      links: %{"Github" => @github},
      source_url: @github,
      homepage_url: "https://chapterspot.hexdocs.pm/astrox"
    ]
  end
end
