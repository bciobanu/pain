defmodule Dashboard.Predictor.Workers do
  def num_workers() do
    3
  end

  def add_alexnet(image_path) do
    map(fn pid -> GenServer.call(pid, {:add_alexnet, image_path}, :infinity) end)
  end

  def predict(image_path) do
    :poolboy.transaction(
      :predictor,
      fn pid -> GenServer.call(pid, {:predict, image_path}, :infinity) end,
      :infinity
    )
  end

  def reload() do
    map(fn pid -> GenServer.call(pid, :reload, :infinity) end)
  end

  def train() do
    :poolboy.transaction(
      :predictor,
      fn pid -> GenServer.call(pid, :train, :infinity) end,
      :infinity
    )

    reload()
  end

  def map(func) do
    take_ownership = fn _index ->
      pid = :poolboy.checkout(:predictor, true, :infinity)
      {func.(pid), pid}
    end

    stream =
      Task.async_stream(
        1..num_workers(),
        take_ownership,
        timeout: :infinity
      )

    release_ownership = fn {:ok, {result, pid}} ->
      :poolboy.checkin(:predictor, pid)
      result
    end

    Enum.map(stream, release_ownership)
  end
end
