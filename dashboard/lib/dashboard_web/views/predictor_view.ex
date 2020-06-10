defmodule DashboardWeb.PredictorView do
  use DashboardWeb, :view

  def render("predict.json", %{paintings: paintings}) do
    Enum.map(paintings, fn painting ->
      %{
        name: painting.name,
        artist: painting.artist,
        description: painting.description,
        image_path: painting.image_path,
        medium: painting.medium,
        year: painting.year
      }
    end)
  end
end
