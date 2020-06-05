defmodule DashboardWeb.PageController do
  require Logger
  use DashboardWeb, :controller
  import Ecto.Query
  alias Dashboard.Repo

  plug DashboardWeb.Plugs.EnsureAuthenticated when action in [:index, :new, :create]

  def index(conn, _params) do
    current_user = conn.assigns.current_user

    paintings =
      case current_user do
        %{id: id} -> Repo.all(from p in Dashboard.Painting, where: p.user_id == ^id)
        _ -> nil
      end

    render(conn, "index.html", paintings: paintings)
  end

  def new(conn, _params) do
    render(conn, "new.html", changeset: conn)
  end

  def upload(upload) do
    image_path = Ecto.UUID.generate() <> Path.extname(upload.filename)
    File.cp(upload.path, "priv/static/user_content/" <> image_path)
    image_path
  end

  def create(conn, %{"painting" => painting}) do
    painting = painting |> Map.put_new("user_id", conn.assigns.current_user.id)

    {:ok, parsed_year} = NaiveDateTime.from_iso8601(painting["year_string"] <> ":00")
    painting = painting |> Map.put_new("year", parsed_year)

    painting = painting |> Map.put_new("image_path", upload(painting["image"]))

    inserted =
      %Dashboard.Painting{}
      |> Dashboard.Painting.changeset(painting)
      |> Repo.insert()

    case inserted do
      {:ok, _painting} ->
        conn
        |> put_flash(:info, "Successfully uploaded!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an error uploading the painting.")
        |> render("new.html", changeset: changeset)
    end
  end
end
