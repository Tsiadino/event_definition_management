defmodule EventDefinitionManagement.Events.GlobalEventDefinition do
  use Ash.Resource,
    otp_app: :event_definition_management,
    domain: EventDefinitionManagement.Events,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "global_event_definitions"
    repo EventDefinitionManagement.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [
        :name,
        :description,
        :event_type,
        :default_parameters,
        :version,
        :active_globally,
        :status
      ]
    end

    update :update do
      accept [
        :name,
        :description,
        :event_type,
        :default_parameters,
        :version,
        :active_globally,
        :status
      ]
    end

    destroy :destroy
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
    end

    attribute :description, :string do
      public? true
    end

    attribute :event_type, :string do
      public? true
      allow_nil? false
    end

    attribute :default_parameters, :map do
      public? true
      default %{}
    end

    attribute :version, :integer do
      public? true
      default 1
    end

    attribute :active_globally, :boolean do
      public? true
      default false
    end

    attribute :status, :atom do
      public? true
      default :en_attente
    end
  end

  relationships do
    has_many :organization_configs, EventDefinitionManagement.Events.OrganizationEventConfig do
      destination_attribute :global_event_definition_id
    end
  end

  identities do
    identity :unique_name, [:name]
  end
end
