defmodule TestsiteWeb.ContactController do
  use TestsiteWeb, :controller

  def create(conn, _params) do
    render(conn, :create, form: Phoenix.Component.to_form(%{}, as: :contact))
  end

  def store(conn, %{"contact" => params}) do
    if String.trim(params["message"] || "") == "" do
      conn
      |> put_flash(:error, "お問い合わせ内容を入力してください。")
      |> put_status(:unprocessable_entity)
      |> render(:create, form: Phoenix.Component.to_form(params, as: :contact))
    else
      conn
      |> put_flash(:info, "お問い合わせを受け付けました。")
      |> redirect(to: ~p"/tweet")
    end
  end
end
