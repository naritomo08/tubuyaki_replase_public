defmodule TestsiteWeb.PageController do
  use TestsiteWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/tweet")
  end
end
