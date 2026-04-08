defmodule EventDefinitionManagement.Accounts do
  use Ash.Domain, otp_app: :event_definition_management, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource EventDefinitionManagement.Accounts.User
    resource EventDefinitionManagement.Accounts.Organization # <-- DOIT ÊTRE ICI
    resource EventDefinitionManagement.Accounts.Token
  end
end
