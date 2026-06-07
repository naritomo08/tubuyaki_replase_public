defmodule TestsiteWeb.AdminUserController do
  use TestsiteWeb, :controller

  alias Testsite.{Accounts, Microblog}

  def index(conn, _params) do
    render(conn, :index,
      users: Accounts.list_users_with_stats(),
      total_tweets: Microblog.count_tweets(),
      total_likes: Microblog.total_like_count(),
      scheduled_tweets: Microblog.list_scheduled_tweets(:all)
    )
  end

  def update_email(conn, %{"id" => id, "user" => params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user_email(user, params) do
      {:ok, _user} ->
        put_flash(conn, :info, "メールアドレスを更新しました。") |> redirect(to: ~p"/admin/users")

      {:error, _changeset} ->
        put_flash(conn, :error, "メールアドレスを更新できませんでした。") |> redirect(to: ~p"/admin/users")
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    case Accounts.delete_user(user) do
      {:ok, _user} ->
        put_flash(conn, :info, "ユーザーを削除しました。") |> redirect(to: ~p"/admin/users")

      {:error, :admin_user} ->
        put_flash(conn, :error, "管理者は削除できません。") |> redirect(to: ~p"/admin/users")
    end
  end
end
