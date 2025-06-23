defmodule Microbeam.Application do
  @moduledoc """
  MicroBEAM OTP Application - Ultra-minimal Elixir system
  """
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("MicroBEAM starting - BEAM running as PID 1")
    
    children = [
      {Plug.Cowboy, scheme: :http, plug: Microbeam.Router, options: [port: 4000]},
      Microbeam.SystemMonitor
    ]

    opts = [strategy: :one_for_one, name: Microbeam.Supervisor]
    Supervisor.start_link(children, opts)
  end
end