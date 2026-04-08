defmodule EventDefinitionManagementWeb.AuthHTML do
  use EventDefinitionManagementWeb, :html

  # Cette ligne est cruciale pour charger les composants Ash
  embed_templates "auth_html/*"
end