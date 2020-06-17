defmodule Dashboard.Predictor.Workers do
  require Logger

  @telemetry_module [:dashboard, :predictor]

  def num_workers() do
    3
  end

  def add_alexnet(image_path) do
    {:ok} =
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
    {:ok} =
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

  def get_all_workers() do
    GenServer.call(:predictor, :get_all_workers)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  def map(_func, _remaining, _workers_applied, 0) do
    Logger.error("Failed to run map")
    {:error}
  end

  def map(_func, [], _workers_applied, _attempts) do
    {:ok}
  end

  def map(func, [worker | remaining], workers_applied, attempts) do
    try do
      if worker not in workers_applied do
        func.(worker)
        map(func, remaining, [worker | workers_applied], attempts)
      else
        map(func, remaining, workers_applied, attempts)
      end
    catch
      _ ->
        Logger.error("#{attempts} - Retrying map")
        Process.sleep(1000)
        map(func, get_all_workers(), workers_applied, attempts - 1)
    end
  end

  def map(func) do
    map(func, get_all_workers(), [], 2 * num_workers() + 1)
  end
end
