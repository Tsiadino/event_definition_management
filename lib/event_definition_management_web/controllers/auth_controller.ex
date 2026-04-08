defmodule EventDefinitionManagementWeb.AuthController do
  use EventDefinitionManagementWeb, :controller
  use AshAuthentication.Phoenix.Controller

  @impl true
  def success(conn, _activity, user, _token) do
    path =
      case user.role do
        :super_admin -> ~p"/admin"
        :client_admin -> ~p"/client"
        :operator -> ~p"/operator"
        _ -> ~p"/"
      end

    conn
    |> store_in_session(user)
    |> put_flash(:info, "Bienvenue #{user.email} !")
    |> redirect(to: path)
  end

  @impl true
  def failure(conn, _activity, _reason) do
    conn
    |> put_flash(:error, "Identifiants incorrects.")
    |> redirect(to: ~p"/sign-in")
  end

  @impl true
  def sign_out(conn, _params) do
    conn
    |> clear_session(:event_definition_management)
    |> put_flash(:info, "Déconnexion réussie.")
    |> redirect(to: ~p"/")
  end
end
