defmodule EventDefinitionManagementWeb.LiveUserAuth do
  import Phoenix.LiveView

  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/sign-in")}
    end
  end

  def on_mount(:live_user_home, _params, _session, socket) do
    if socket.assigns[:current_user] do
      path =
        case socket.assigns.current_user.role do
          :super_admin -> "/admin"
          :client_admin -> "/client"
          :operator -> "/operator"
          _ -> "/"
        end

      {:halt, redirect(socket, to: path)}
    else
      {:cont, socket}
    end
  end

  def on_mount(:default, _params, _session, socket) do
    {:cont, socket}
  end
end
