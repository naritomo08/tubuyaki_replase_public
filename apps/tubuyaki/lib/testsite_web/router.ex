defmodule TestsiteWeb.Router do
  use TestsiteWeb, :router
  import TestsiteWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TestsiteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug :require_authenticated_user
  end

  pipeline :admin do
    plug :require_admin_user
  end

  scope "/", TestsiteWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/terms", LegalDocumentController, :terms
    get "/privacy", LegalDocumentController, :privacy
    get "/health", PageController, :health
    get "/tweet", TweetController, :index
    get "/tweet/latest", TweetController, :latest
    get "/like/status", TweetController, :like_status
    get "/login", AuthController, :new
    post "/login", AuthController, :create
    get "/register", AuthController, :register
    post "/register", AuthController, :create_registration
    delete "/logout", AuthController, :delete
  end

  scope "/", TestsiteWeb do
    pipe_through [:browser, :authenticated]

    post "/tweet", TweetController, :create
    get "/tweet/search", TweetController, :search
    get "/tweet/search/results", TweetController, :search
    get "/tweet/:id/edit", TweetController, :edit
    put "/tweet/:id", TweetController, :update
    delete "/tweet/:id", TweetController, :delete
    post "/tweet/:id/like", TweetController, :like
    get "/verify-email", AuthController, :verify_email
    get "/contact", ContactController, :create
    post "/contact", ContactController, :store
    get "/account", AccountController, :index
    get "/account/admin-status", AccountController, :admin_status
    get "/account/stats", AccountController, :stats
    get "/account/scheduled-tweets", AccountController, :scheduled_tweets
    put "/account/profile", AccountController, :update_profile
    put "/account/mail-settings", AccountController, :update_mail_settings
    put "/account/password", AccountController, :update_password
    delete "/account/google", AccountController, :disconnect_google
    delete "/account", AccountController, :delete
    get "/account/google/connect", AuthController, :google_unconfigured
  end

  scope "/admin", TestsiteWeb do
    pipe_through [:browser, :authenticated, :admin]

    get "/users", AdminUserController, :index
    get "/users/stats", AdminUserController, :stats
    get "/users/list", AdminUserController, :list_users
    get "/users/scheduled-tweets", AdminUserController, :scheduled_tweets
    put "/users/:id/email", AdminUserController, :update_email
    delete "/users/:id", AdminUserController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", TestsiteWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:testsite, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TestsiteWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
