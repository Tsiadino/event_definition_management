defmodule EventDefinitionManagementWeb.PageController do
  use EventDefinitionManagementWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
