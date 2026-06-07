defmodule TestsiteWeb.AdminUserHTML do
  use TestsiteWeb, :html

  embed_templates "admin_user_html/*"

  def format_datetime(nil), do: ""

  def format_datetime(datetime) do
    Testsite.DateTime.format_jst(datetime)
  end
end
