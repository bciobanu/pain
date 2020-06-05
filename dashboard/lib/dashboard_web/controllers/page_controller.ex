defmodule DashboardWeb.PageController do
  use DashboardWeb, :controller
  import Ecto.Query
  alias Dashboard.Repo

  plug DashboardWeb.Plugs.EnsureAuthenticated when action in [:index]

  def index(conn, _params) do
    current_user = conn.assigns.current_user

    paintings =
      case current_user do
        %{id: id} -> Repo.all(from p in Dashboard.Painting, where: p.user_id == ^id)
        _ -> nil
      end

    render(conn, "index.html", paintings: paintings)
  end
end
