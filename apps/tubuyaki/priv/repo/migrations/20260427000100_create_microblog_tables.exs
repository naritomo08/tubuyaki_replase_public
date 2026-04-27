defmodule Testsite.Repo.Migrations.CreateMicroblogTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :is_admin, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:name])
    create unique_index(:users, [:email])

    create unique_index(:users, ["(CASE WHEN is_admin THEN 1 ELSE NULL END)"],
             name: :unique_admin
           )

    create table(:tweets) do
      add :content, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tweets, [:user_id])
    create index(:tweets, [:inserted_at, :id])

    create table(:likes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :tweet_id, references(:tweets, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:likes, [:tweet_id])
    create unique_index(:likes, [:user_id, :tweet_id])
  end
end
