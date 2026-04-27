defmodule TestsiteWeb.AuthController do
  use TestsiteWeb, :controller

  alias Testsite.Accounts
  alias Testsite.Microblog.User
  alias TestsiteWeb.UserAuth

  def new(conn, _params),
    do: render(conn, :login, form: Phoenix.Component.to_form(%{}, as: :user))

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> UserAuth.log_in_user(user)
        |> put_flash(:info, "ログインしました。")
        |> redirect(to: ~p"/tweet")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "メールアドレスまたはパスワードが違います。")
        |> put_status(:unprocessable_entity)
        |> render(:login, form: Phoenix.Component.to_form(%{"email" => email}, as: :user))
    end
  end

  def register(conn, _params) do
    render(conn, :register,
      form: Phoenix.Component.to_form(User.registration_changeset(%User{}, %{}))
    )
  end

  def create_registration(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        Accounts.verify_email(user)

        conn
        |> UserAuth.log_in_user(user)
        |> put_flash(:info, "登録しました。")
        |> redirect(to: ~p"/tweet")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:register, form: Phoenix.Component.to_form(%{changeset | action: :insert}))
    end
  end

  def verify_email(conn, _params) do
    if user = conn.assigns.current_user do
      Accounts.verify_email(user)
      put_flash(conn, :info, "メール認証を完了しました。") |> redirect(to: ~p"/tweet")
    else
      redirect(conn, to: ~p"/login")
    end
  end

  def google_unconfigured(conn, _params) do
    conn
    |> put_flash(:error, "Google連携は OAuth クライアント設定後に有効化できます。")
    |> redirect(to: ~p"/account")
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "ログアウトしました。")
    |> redirect(to: ~p"/tweet")
  end
end
