defmodule Dashboard.Predictor.Workers do
  require Logger

  def num_workers() do
    3
  end

  def add_alexnet(image_path) do
    map(fn pid ->
      Logger.info("[#{inspect(pid)}] started adding #{image_path} to AlexNet.")
      GenServer.call(pid, {:add_alexnet, image_path}, :infinity)
      Logger.info("[#{inspect(pid)}] finished adding #{image_path} to AlexNet.")
    end)
  end

  def predict(image_path) do
    :poolboy.transaction(
      :predictor,
      fn pid ->
        Logger.info("[#{inspect(pid)}] started predicting.")
        result = GenServer.call(pid, {:predict, image_path}, :infinity)
        Logger.info("[#{inspect(pid)}] finished predicting.")
        result
      end,
      :infinity
    )
  end

  def reload() do
    map(fn pid ->
      Logger.info("[#{inspect(pid)}] started reloading.")
      GenServer.call(pid, :reload, :infinity)
      Logger.info("[#{inspect(pid)}] finished reloading.")
    end)
  end

  def train() do
    :poolboy.transaction(
      :predictor,
      fn pid ->
        Logger.info("[#{inspect(pid)}] started training.")
        GenServer.call(pid, :train, :infinity)
        Logger.info("[#{inspect(pid)}] finished training.")
      end,
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
