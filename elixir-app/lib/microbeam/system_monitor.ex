defmodule Microbeam.SystemMonitor do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def uptime do
    GenServer.call(__MODULE__, :uptime)
  end

  def memory_info do
    GenServer.call(__MODULE__, :memory_info)
  end

  @impl true
  def init(_) do
    Logger.info("SystemMonitor started")
    start_time = System.monotonic_time(:second)
    
    # Log system info on startup
    log_system_info()
    
    {:ok, %{start_time: start_time}}
  end

  @impl true
  def handle_call(:uptime, _from, %{start_time: start_time} = state) do
    uptime_seconds = System.monotonic_time(:second) - start_time
    {:reply, uptime_seconds, state}
  end

  @impl true
  def handle_call(:memory_info, _from, state) do
    memory = :erlang.memory()
    info = %{
      total: memory[:total],
      processes: memory[:processes],
      system: memory[:system],
      atom: memory[:atom],
      binary: memory[:binary]
    }
    {:reply, info, state}
  end

  defp log_system_info do
    Logger.info("System Information:")
    Logger.info("  OTP: #{:erlang.system_info(:otp_release)}")
    Logger.info("  ERTS: #{:erlang.system_info(:version)}")
    Logger.info("  Schedulers: #{System.schedulers_online()}")
    Logger.info("  Memory: #{div(:erlang.memory(:total), 1024 * 1024)} MB")
    
    # Check if we're PID 1
    case System.cmd("cat", ["/proc/self/stat"]) do
      {output, 0} ->
        [pid | _] = String.split(output)
        Logger.info("  Running as PID: #{pid}")
      _ ->
        :ok
    end
  end
end