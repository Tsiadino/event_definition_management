defmodule EventDefinitionManagement.Accounts do
  use Ash.Domain, otp_app: :event_definition_management, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource EventDefinitionManagement.Accounts.Token
    resource EventDefinitionManagement.Accounts.User
  end
end
