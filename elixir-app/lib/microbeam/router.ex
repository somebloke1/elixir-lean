defmodule Microbeam.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    info = %{
      system: "MicroBEAM",
      version: "0.1.0",
      beam_pid: System.pid(),
      uptime: Microbeam.SystemMonitor.uptime(),
      memory: Microbeam.SystemMonitor.memory_info(),
      cpu_count: System.schedulers_online(),
      otp_release: :erlang.system_info(:otp_release) |> to_string()
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(info))
  end

  get "/health" do
    send_resp(conn, 200, "ok")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end