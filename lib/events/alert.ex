defmodule EventDefinitionManagement.Events.Alert do
  use Ash.Resource,
    otp_app: :event_definition_management,
    domain: EventDefinitionManagement.Events,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "alerts"
    repo EventDefinitionManagement.Repo
  end

  actions do
    defaults [:read, :create]

    update :update do
      accept [:status, :acknowledged_at, :acknowledged_by]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :event_type, :string do
      public? true
      allow_nil? false
    end

    attribute :message, :string do
      public? true
    end

    attribute :vehicle_id, :string do
      public? true
    end

    attribute :vehicle_immat, :string do
      public? true
    end

    attribute :latitude, :float do
      public? true
    end

    attribute :longitude, :float do
      public? true
    end

    attribute :speed, :float do
      public? true
    end

    attribute :fuel_level, :float do
      public? true
    end

    attribute :status, :atom do
      public? true
      default :en_attente
    end

    attribute :acknowledged_at, :utc_datetime_usec do
      public? true
    end

    attribute :acknowledged_by, :uuid do
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :organization, EventDefinitionManagement.Accounts.Organization do
      public? true
      allow_nil? false
    end

    belongs_to :organization_event_config,
               EventDefinitionManagement.Events.OrganizationEventConfig do
      public? true
      allow_nil? true
    end

    belongs_to :global_event_definition, EventDefinitionManagement.Events.GlobalEventDefinition do
      public? true
      allow_nil? true
    end
  end
end
