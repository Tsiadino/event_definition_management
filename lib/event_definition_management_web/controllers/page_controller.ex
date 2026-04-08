defmodule EventDefinitionManagementWeb.PageController do
  use EventDefinitionManagementWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      case conn.assigns[:current_user].role do
        :super_admin -> redirect(conn, to: ~p"/admin")
        :client_admin -> redirect(conn, to: ~p"/client")
        :operator -> redirect(conn, to: ~p"/operator")
        _ -> redirect(conn, to: ~p"/sign-in")
      end
    else
      redirect(conn, to: ~p"/sign-in")
    end
  end
end
