defmodule DashboardWeb.Plugs.Authenticate do
  import Plug.Conn

  alias Dashboard.Repo
  alias Dashboard.Auth.User

  def init(_params) do
  end

  def call(conn, _params) do
    user_id = Plug.Conn.get_session(conn, :current_user_id)
    assign(conn, :current_user,
      if current_user = user_id && Repo.get(User, user_id) do
        current_user
      else
        nil
      end
    )
  end
end
