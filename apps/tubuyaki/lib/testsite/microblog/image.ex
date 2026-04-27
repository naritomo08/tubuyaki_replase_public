defmodule Testsite.Microblog.Image do
  use Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :name, :string

    many_to_many :tweets, Testsite.Microblog.Tweet, join_through: "tweet_images"

    timestamps(type: :utc_datetime)
  end

  def changeset(image, attrs) do
    image
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
