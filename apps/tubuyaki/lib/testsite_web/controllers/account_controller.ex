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
end
