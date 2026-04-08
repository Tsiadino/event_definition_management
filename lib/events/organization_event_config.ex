defmodule EventDefinitionManagement.Events.OrganizationEventConfig do
  use Ash.Resource,
    otp_app: :event_definition_management,
    domain: EventDefinitionManagement.Events,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organization_event_configs"
    repo EventDefinitionManagement.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [
        :custom_name,
        :active,
        :parameters,
        :actions,
        :organization_id,
        :global_event_definition_id
      ]
    end

    update :update do
      accept [:custom_name, :active, :parameters, :actions]
    end

    destroy :destroy
  end

  attributes do
    uuid_primary_key :id

    attribute :custom_name, :string do
      public? true
    end

    attribute :active, :boolean do
      public? true
      default true
    end

    attribute :parameters, :map do
      public? true
      default %{}
    end

    attribute :actions, :map do
      public? true
      default %{}
    end
  end

  relationships do
    belongs_to :organization, EventDefinitionManagement.Accounts.Organization do
      public? true
      allow_nil? false
    end

    belongs_to :global_event_definition, EventDefinitionManagement.Events.GlobalEventDefinition do
      public? true
      allow_nil? false
    end
  end
end
