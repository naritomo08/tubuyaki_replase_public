defmodule TestsiteWeb.AccountController do
  use TestsiteWeb, :controller

  alias Testsite.{Accounts, Microblog}
  alias Testsite.Microblog.User
  alias TestsiteWeb.UserAuth

  def index(conn, _params) do
    user = conn.assigns.current_user

    render(conn, :index,
      profile_form: Phoenix.Component.to_form(User.profile_changeset(user, %{})),
      password_form: Phoenix.Component.to_form(%{}, as: :password_update),
      stats: Microblog.user_stats(user),
      scheduled_tweets: Microblog.list_scheduled_tweets(user)
    )
  end

  def admin_status(conn, _params) do
    user = conn.assigns.current_user

    json(conn, %{
      is_admin: user.is_admin,
      has_two_factor_enabled: false,
      deletion_requested: Accounts.pending_deletion?(user)
    })
  end

  def stats(conn, _params) do
    stats = Microblog.user_stats(conn.assigns.current_user)

    json(conn, %{
      label: "あなた",
      tweet_count: stats.tweet_count,
      like_count: stats.like_count
    })
  end

  def scheduled_tweets(conn, _params) do
    json(conn, %{
      scheduled_tweets:
        conn.assigns.current_user
        |> Microblog.list_scheduled_tweets()
        |> Enum.map(&scheduled_tweet_json/1)
    })
  end

  def update_profile(conn, %{"user" => params}) do
    user = conn.assigns.current_user

    case Accounts.update_profile(user, params) do
      {:ok, user} ->
        conn
        |> assign(:current_user, user)
        |> put_flash(:info, "プロフィールを更新しました。")
        |> redirect(to: ~p"/account")

      {:error, changeset} ->
        render(conn, :index,
          profile_form: Phoenix.Component.to_form(%{changeset | action: :update}),
          password_form: Phoenix.Component.to_form(%{}, as: :password_update),
          stats: Microblog.user_stats(user),
          scheduled_tweets: Microblog.list_scheduled_tweets(user)
        )
    end
  end

  def update_password(conn, %{"password_update" => params}) do
    user = conn.assigns.current_user

    case Accounts.update_password(user, params["current_password"], %{
           "password" => params["password"]
         }) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "パスワードを更新しました。")
        |> redirect(to: ~p"/account")

      {:error, changeset} ->
        render(conn, :index,
          profile_form: Phoenix.Component.to_form(User.profile_changeset(user, %{})),
          password_form:
            Phoenix.Component.to_form(%{changeset | action: :update}, as: :password_update),
          stats: Microblog.user_stats(user),
          scheduled_tweets: Microblog.list_scheduled_tweets(user)
        )
    end
  end

  def update_mail_settings(conn, %{"user" => params}) do
    update_mail_settings(conn, params)
  end

  def update_mail_settings(conn, params) do
    case Accounts.update_mail_settings(conn.assigns.current_user, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "メール通知設定を更新しました。")
        |> redirect(to: ~p"/account")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "メール通知設定を更新できませんでした。")
        |> redirect(to: ~p"/account")
    end
  end

  def disconnect_google(conn, _params) do
    case Accounts.disconnect_google(conn.assigns.current_user) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Google連携を解除しました。")
        |> redirect(to: ~p"/account")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Google連携を解除できませんでした。")
        |> redirect(to: ~p"/account")
    end
  end

  def delete(conn, %{"user" => %{"current_password" => password}}) do
    user = conn.assigns.current_user

    cond do
      user.is_admin ->
        put_flash(conn, :error, "管理者アカウントは削除できません。") |> redirect(to: ~p"/account")

      not Accounts.verify_password(password, user.password_hash) ->
        put_flash(conn, :error, "パスワードが違います。") |> redirect(to: ~p"/account")

      true ->
        Accounts.mark_user_for_deletion(user)

        conn
        |> UserAuth.log_out_user()
        |> put_flash(:info, "アカウントを削除しました。")
        |> redirect(to: ~p"/tweet")
    end
  end

  defp scheduled_tweet_json(tweet) do
    %{
      id: tweet.id,
      content: tweet.content,
      scheduled_at: format_iso8601(tweet.scheduled_at),
      edit_url: ~p"/tweet/#{tweet.id}/edit"
    }
  end

  defp format_iso8601(nil), do: nil
  defp format_iso8601(datetime), do: Testsite.DateTime.iso8601_jst(datetime)
end
