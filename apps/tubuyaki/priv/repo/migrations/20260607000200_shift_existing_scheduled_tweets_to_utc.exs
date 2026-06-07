defmodule Testsite.Repo.Migrations.ShiftExistingScheduledTweetsToUtc do
  use Ecto.Migration

  def up do
    execute """
    UPDATE tweets
    SET scheduled_at = scheduled_at - interval '9 hours'
    WHERE scheduled_at IS NOT NULL
    """
  end

  def down do
    execute """
    UPDATE tweets
    SET scheduled_at = scheduled_at + interval '9 hours'
    WHERE scheduled_at IS NOT NULL
    """
  end
end
