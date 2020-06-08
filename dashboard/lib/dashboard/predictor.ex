defmodule Dashboard.Predictor do
  use GenServer

  # computed at compile time, so cwd will be `pain/dashboard` expanded as an absolute path
  @model_path (File.cwd!() <> "/../model") |> Path.expand()

  @image_path File.cwd!() <> "/priv/static/user_content"

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  def init(_state) do
    {:ok, pid} = :python.start(python_path: @model_path |> to_charlist)
    state = %{pid: pid}
    :python.call(state.pid, :handler, :load, [])
    {:ok, state}
  end

  def handle_call({:predict, image_path}, _from, state) do
    {:reply, :python.call(state.pid, :handler, :predict, [image_path]), state}
  end

  def handle_call({:add_alexnet, image_path}, _from, state) do
    :python.call(state.pid, :handler, :add_alexnet_image, [image_path])
    {:reply, :ok, state}
  end

  def handle_call(:train, _from, state) do
    :python.call(state.pid, :handler, :train, [@image_path])
    {:reply, :ok, state}
  end

  def terminate(_reason, state) do
    :python.stop(state.pid)
  end
end
