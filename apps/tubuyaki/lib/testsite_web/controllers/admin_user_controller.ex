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

  def stats(conn, _params) do
    users = Accounts.list_users_with_stats()

    json(conn, %{
      totals: %{
        label: "全体",
        tweet_count: Microblog.count_tweets(),
        like_count: Microblog.total_like_count()
      },
      users: Enum.map(users, &user_stats_json/1)
    })
  end

  def list_users(conn, _params) do
    json(conn, %{users: Enum.map(Accounts.list_users_with_stats(), &user_json/1)})
  end

  def scheduled_tweets(conn, _params) do
    json(conn, %{
      scheduled_tweets:
        :all
        |> Microblog.list_scheduled_tweets()
        |> Enum.map(&scheduled_tweet_json/1)
    })
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

  defp user_stats_json(user) do
    %{
      id: user.id,
      name: user.name,
      tweet_count: user.tweets_count,
      like_count: user.received_likes_count
    }
  end

  defp user_json(user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      is_admin: user.is_admin,
      email_verified: not is_nil(user.email_verified_at),
      receives_notification_mail: user.receives_notification_mail,
      google_connected: not is_nil(user.google_id),
      deletion_requested: Accounts.pending_deletion?(user),
      tweet_count: user.tweets_count,
      like_count: user.received_likes_count
    }
  end

  defp scheduled_tweet_json(tweet) do
    %{
      id: tweet.id,
      content: tweet.content,
      scheduled_at: format_iso8601(tweet.scheduled_at),
      user: %{id: tweet.user.id, name: tweet.user.name},
      edit_url: ~p"/tweet/#{tweet.id}/edit"
    }
  end

  defp format_iso8601(nil), do: nil
  defp format_iso8601(datetime), do: Testsite.DateTime.iso8601_jst(datetime)
end
