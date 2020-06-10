defmodule DashboardWeb.PredictorController do
  use DashboardWeb, :controller
  import Ecto.Query

  def create(conn, %{"payload" => payload}) do
    image_list = Dashboard.Predictor.Workers.predict(payload.path)

    paintings =
      Dashboard.Repo.all(from p in Dashboard.Painting, where: p.image_path in ^image_list)

    render(conn, "predict.json", paintings: paintings)
  end

  def train(conn, _payload) do
    Task.start(fn -> Dashboard.Predictor.Workers.train() end)
    send_resp(conn, :ok, "")
  end
end
