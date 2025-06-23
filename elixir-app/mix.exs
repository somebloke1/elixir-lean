defmodule Microbeam.MixProject do
  use Mix.Project

  def project do
    [
      app: :microbeam,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      mod: {Microbeam.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"}
    ]
  end

  defp releases do
    [
      microbeam: [
        include_executables_for: [:unix],
        include_erts: true,
        strip_beams: true,
        runtime_config_path: false,
        cookie: "microbeam-secret-cookie"
      ]
    ]
  end
end