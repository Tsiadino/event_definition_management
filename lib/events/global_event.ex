defmodule EventDefinitionManagement.Events.GlobalEvent do # <-- NOM COMPLET ICI
  use Ash.Resource,
    otp_app: :event_definition_management,
    domain: EventDefinitionManagement.Events, # <-- DOMAINE COMPLET ICI
    data_layer: AshPostgres.DataLayer

  postgres do
    table "global_events"
    repo EventDefinitionManagement.Repo
  end

  attributes do

    uuid_primary_key :id
    attribute :name, :string do
      public? true
      allow_nil? false
    end

    attribute :code, :string do
      public? true
      allow_nil? false
    end

    attribute :description, :string do
      public? true
    end
  end

  identities do
    identity :unique_code, [:code]
  end

  
  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :code, :description]
    end

    update :update do
      accept [:name, :code, :description]
    end
  end

end
