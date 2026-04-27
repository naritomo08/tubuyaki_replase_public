defmodule Testsite.Accounts do
  import Ecto.Query

  alias Testsite.Microblog.User
  alias Testsite.Repo

  @hash_iterations 120_000
  @salt_bytes 16

  def list_users_with_stats do
    like_counts =
      from l in Testsite.Microblog.Like,
        join: t in assoc(l, :tweet),
        group_by: t.user_id,
        select: {t.user_id, count(l.id)}

    tweet_counts =
      from t in Testsite.Microblog.Tweet,
        group_by: t.user_id,
        select: {t.user_id, count(t.id)}

    users = from(u in User, order_by: [desc: u.is_admin, asc: u.name]) |> Repo.all()
    likes = like_counts |> Repo.all() |> Map.new()
    tweets = tweet_counts |> Repo.all() |> Map.new()

    Enum.map(users, fn user ->
      %{
        user
        | tweets_count: Map.get(tweets, user.id, 0),
          received_likes_count: Map.get(likes, user.id, 0)
      }
    end)
  end

  def count_users, do: Repo.aggregate(User, :count)

  def get_user(id), do: Repo.get(User, id)
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email),
    do: Repo.get_by(User, email: String.downcase(String.trim(email || "")))

  def register_user(attrs) do
    attrs =
      attrs
      |> normalize_email()
      |> maybe_mark_first_user_admin()

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    cond do
      user && verify_password(password, user.password_hash) -> {:ok, user}
      true -> {:error, :invalid_credentials}
    end
  end

  def update_profile(%User{} = user, attrs) do
    attrs = normalize_email(attrs)

    user
    |> User.profile_changeset(attrs)
    |> maybe_clear_verification(user, attrs)
    |> Repo.update()
  end

  def update_password(%User{} = user, current_password, attrs) do
    if verify_password(current_password, user.password_hash) do
      user
      |> User.password_changeset(attrs)
      |> Repo.update()
    else
      {:error,
       User.password_changeset(user, attrs)
       |> Ecto.Changeset.add_error(:current_password, "が違います")}
    end
  end

  def update_user_email(%User{} = user, attrs) do
    user
    |> User.profile_changeset(%{"name" => user.name, "email" => normalize_email(attrs)["email"]})
    |> Ecto.Changeset.put_change(:email_verified_at, nil)
    |> Repo.update()
  end

  def verify_email(%User{} = user) do
    user
    |> User.verify_email_changeset()
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    if user.is_admin do
      {:error, :admin_user}
    else
      Repo.delete(user)
    end
  end

  def hash_password(password) do
    salt = :crypto.strong_rand_bytes(@salt_bytes)

    digest =
      :crypto.pbkdf2_hmac(:sha256, password, salt, @hash_iterations, 32)
      |> Base.encode64()

    "pbkdf2_sha256$#{@hash_iterations}$#{Base.encode64(salt)}$#{digest}"
  end

  def verify_password(_password, nil), do: false

  def verify_password(password, encoded) do
    with ["pbkdf2_sha256", iterations, salt, digest] <- String.split(encoded, "$"),
         {iterations, ""} <- Integer.parse(iterations),
         {:ok, salt} <- Base.decode64(salt),
         {:ok, expected} <- Base.decode64(digest) do
      actual = :crypto.pbkdf2_hmac(:sha256, password || "", salt, iterations, byte_size(expected))
      Plug.Crypto.secure_compare(actual, expected)
    else
      _ -> false
    end
  end

  defp normalize_email(attrs) do
    update_in(attrs["email"], fn
      nil -> nil
      email -> email |> String.trim() |> String.downcase()
    end)
  end

  defp maybe_mark_first_user_admin(attrs) do
    admin_exists? = from(u in User, where: u.is_admin == true) |> Repo.exists?()
    if admin_exists?, do: attrs, else: Map.put(attrs, "is_admin", true)
  end

  defp maybe_clear_verification(changeset, user, attrs) do
    if Map.get(attrs, "email") && Map.get(attrs, "email") != user.email do
      Ecto.Changeset.put_change(changeset, :email_verified_at, nil)
    else
      changeset
    end
  end
end
