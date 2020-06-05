defmodule DashboardWeb.RegisterController do
  use DashboardWeb, :controller

  plug DashboardWeb.Plugs.EnsureUnauthenticated

  def new(conn, _params) do
    render(conn, "new.html", changeset: conn)
  end

  def create(conn, %{"register" => register_params}) do
    case Dashboard.Auth.register(register_params) do
      {:ok, user} ->
        conn
        |> put_session(:current_user_id, user.id)
        |> put_flash(:info, "You have successfully signed up!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
