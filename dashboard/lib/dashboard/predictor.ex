defmodule Dashboard.Predictor do
  use GenServer

  # computed at compile time, so cwd will be `pain/dashboard` expanded as an absolute path
  @model_path (File.cwd!() <> "/../model") |> Path.expand() |> to_charlist

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  def init(_state) do
    {:ok, pid} = :python.start(python_path: @model_path)
    state = %{pid: pid}
    {:ok, state}
  end

  def handle_call(:test, _from, state) do
    {:reply, :python.call(state.pid, :predictor, :main, []), state}
  end

  def terminate(_reason, state) do
    :python.stop(state.pid)
  end
end
