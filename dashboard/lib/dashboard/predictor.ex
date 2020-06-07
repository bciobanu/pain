defmodule Dashboard.Predictor do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  def init(_state) do
    {:ok, pid} = :python.start()
    state = %{pid: pid}
    {:ok, state}
  end

  def handle_call(:test, _from, state) do
    {:reply, :python.call(state.pid, :operator, :add, [1, 1]), state}
  end

  def terminate(_reason, state) do
    :python.stop(state.pid)
  end
end
