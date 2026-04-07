defmodule EventDefinitionManagement.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        EventDefinitionManagement.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:event_definition_management, :token_signing_secret)
  end
end
