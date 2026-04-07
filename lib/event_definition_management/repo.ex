defmodule EventDefinitionManagement.Repo do
  use Ecto.Repo,
    otp_app: :event_definition_management,
    adapter: Ecto.Adapters.Postgres
end
