defmodule EventDefinitionManagementWeb.Router do
  use EventDefinitionManagementWeb, :router

  import AshAuthentication.Phoenix.Router
  import AshAuthentication.Phoenix.LiveSession

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EventDefinitionManagementWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser

    sign_in_route auth_routes_prefix: "/auth"
    reset_route path: "/password-reset", auth_routes_prefix: "/auth"

    confirm_route EventDefinitionManagement.Accounts.User, :password,
      path: "/confirm-new-user",
      auth_routes_prefix: "/auth"

    auth_routes EventDefinitionManagementWeb.AuthController,
                EventDefinitionManagement.Accounts.User,
                path: "/auth",
                otp_app: :event_definition_management

    sign_out_route EventDefinitionManagementWeb.AuthController
  end

  scope "/admin", EventDefinitionManagementWeb do
    pipe_through [:browser]

    ash_authentication_live_session :super_admin_session,
      on_mount: [{EventDefinitionManagementWeb.LiveUserAuth, :live_user_required}] do
      live "/", SuperAdminLive.Index, :index
      live "/dashboard", SuperAdminLive.Index, :index
    end
  end

  scope "/operator", EventDefinitionManagementWeb do
    pipe_through [:browser]

    ash_authentication_live_session :operator_session,
      on_mount: [{EventDefinitionManagementWeb.LiveUserAuth, :live_user_required}] do
      live "/", OperatorLive.Index, :index
      live "/alerts", OperatorLive.Index, :index
    end
  end

  scope "/client", EventDefinitionManagementWeb do
    pipe_through [:browser]

    ash_authentication_live_session :client_session,
      on_mount: [{EventDefinitionManagementWeb.LiveUserAuth, :live_user_required}] do
      live "/", ClientAdminLive.Index, :index
      live "/dashboard", ClientAdminLive.Index, :index
    end
  end

  scope "/", EventDefinitionManagementWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  if Application.compile_env(:event_definition_management, :dev_routes) do
    import Phoenix.LiveDashboard.Router
    import AshAdmin.Router

    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: EventDefinitionManagementWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
      ash_admin "/db"
    end
  end
end
