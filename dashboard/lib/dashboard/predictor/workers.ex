defmodule Dashboard.Predictor.Workers do
  require Logger

  @telemetry_module [:dashboard, :predictor]

  def num_workers() do
    3
  end

  def add_alexnet(image_path) do
    map(fn pid ->
      Logger.info("[#{inspect(pid)}] started adding #{image_path} to AlexNet.")
      start_time = System.monotonic_time()

      GenServer.call(pid, {:add_alexnet, image_path}, :infinity)

      elapsed = System.monotonic_time() - start_time

      :telemetry.execute(
        @telemetry_module ++ [:add_alexnet],
        %{duration: elapsed},
        %{pid: pid}
      )

      Logger.info("[#{inspect(pid)}] finished adding #{image_path} to AlexNet.")
    end)
  end

  def predict(image_path) do
    :poolboy.transaction(
      :predictor,
      fn pid ->
        Logger.info("[#{inspect(pid)}] started predicting.")
        start_time = System.monotonic_time()

        result = GenServer.call(pid, {:predict, image_path}, :infinity)

        elapsed = System.monotonic_time() - start_time

        :telemetry.execute(
          @telemetry_module ++ [:predict],
          %{duration: elapsed},
          %{pid: pid}
        )

        Logger.info("[#{inspect(pid)}] finished predicting.")
        result
      end,
      :infinity
    )
  end

  def reload() do
    map(fn pid ->
      Logger.info("[#{inspect(pid)}] started reloading.")
      start_time = System.monotonic_time()

      GenServer.call(pid, :reload, :infinity)

      elapsed = System.monotonic_time() - start_time

      :telemetry.execute(
        @telemetry_module ++ [:reload],
        %{duration: elapsed},
        %{pid: pid}
      )

      Logger.info("[#{inspect(pid)}] finished reloading.")
    end)
  end

  def train() do
    :poolboy.transaction(
      :predictor,
      fn pid ->
        Logger.info("[#{inspect(pid)}] started training.")
        start_time = System.monotonic_time()

        GenServer.call(pid, :train, :infinity)

        elapsed = System.monotonic_time() - start_time

        :telemetry.execute(
          @telemetry_module ++ [:train],
          %{duration: elapsed},
          %{pid: pid}
        )

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
