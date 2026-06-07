defmodule Testsite.Repo.Migrations.AddLaravelReplacementFeatures do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :receives_notification_mail, :boolean, null: false, default: true
      add :deletion_requested_at, :utc_datetime
    end

    create index(:users, [:deletion_requested_at])

    alter table(:tweets) do
      add :is_secret, :boolean, null: false, default: false
      add :is_protected, :boolean, null: false, default: false
      add :scheduled_at, :utc_datetime
    end

    create index(:tweets, [:scheduled_at])
    create index(:tweets, [:is_secret])
  end
end
