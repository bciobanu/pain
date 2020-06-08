defmodule DashboardWeb.PageController do
  use DashboardWeb, :controller
  import Ecto.Query

  plug DashboardWeb.Plugs.EnsureAuthenticated when action in [:index, :new, :create]

  @image_dir File.cwd!() |> Path.join("/priv/static/user_content")

  def index(conn, _params) do
    current_user = conn.assigns.current_user

    paintings =
      case current_user do
        %{id: id} -> Dashboard.Repo.all(from p in Dashboard.Painting, where: p.user_id == ^id)
        _ -> nil
      end

    render(conn, "index.html", paintings: paintings)
  end

  def new(conn, _params) do
    render(conn, "new.html", changeset: conn)
  end

  def absolute_image_path(image_name) do
    Path.join(@image_dir, image_name)
  end

  def upload(upload) do
    image_name = Ecto.UUID.generate() <> Path.extname(upload.filename)
    File.mkdir(@image_dir)
    File.cp!(upload.path, absolute_image_path(image_name))
    image_name
  end

  def create(conn, %{"painting" => painting}) do
    painting = painting |> Map.put_new("user_id", conn.assigns.current_user.id)

    {:ok, parsed_year} = NaiveDateTime.from_iso8601(painting["year_string"] <> ":00")
    painting = painting |> Map.put_new("year", parsed_year)

    painting = painting |> Map.put_new("image_path", upload(painting["image"]))

    inserted =
      %Dashboard.Painting{}
      |> Dashboard.Painting.changeset(painting)
      |> Dashboard.Repo.insert()

    case inserted do
      {:ok, _painting} ->
        # don't block waiting for the workers to add it to the model
        # because it would time out on the redirect
        Task.start(fn ->
          painting["image_path"]
          |> absolute_image_path
          |> Dashboard.Predictor.Workers.add_alexnet()
        end)

        conn
        |> put_flash(:info, "Successfully uploaded!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, changeset} ->
        painting["image_path"]
        |> absolute_image_path
        |> File.rm!()

        conn
        |> put_flash(:error, "There was an error uploading the painting.")
        |> render("new.html", changeset: changeset)
    end
  end
end
