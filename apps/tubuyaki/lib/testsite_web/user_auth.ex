defmodule TestsiteWeb.UserAuth do
  import Phoenix.Controller
  import Plug.Conn

  alias Testsite.Accounts

  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    assign(conn, :current_user, user_id && Accounts.get_user(user_id))
  end

  def log_in_user(conn, user) do
    conn
    |> renew_session()
    |> put_session(:user_id, user.id)
  end

  def log_out_user(conn) do
    conn
    |> renew_session()
    |> delete_session(:user_id)
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "ログインしてください。")
      |> redirect(to: "/login")
      |> halt()
    end
  end

  def require_admin_user(conn, _opts) do
    case conn.assigns[:current_user] do
      %{is_admin: true} ->
        conn

      _ ->
        conn
        |> put_flash(:error, "管理者のみ利用できます。")
        |> redirect(to: "/tweet")
        |> halt()
    end
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
