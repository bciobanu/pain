defmodule Dashboard.Repo.Migrations.LongerDescriptions do
  use Ecto.Migration

  def change do
    alter table(:painting) do
      modify :description, :text
    end
  end
end
