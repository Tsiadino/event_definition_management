defmodule EventDefinitionManagement.Accounts.Organization do
  use Ash.Resource,
    domain: EventDefinitionManagement.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organizations"
    repo EventDefinitionManagement.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name]
    end

    update :update do
      accept [:name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
    end
  end

  relationships do
    has_many :users, EventDefinitionManagement.Accounts.User

    has_many :configs, EventDefinitionManagement.Events.OrganizationEventConfig do
      destination_attribute :organization_id
    end

    has_many :alerts, EventDefinitionManagement.Events.Alert do
      destination_attribute :organization_id
    end
  end
end
