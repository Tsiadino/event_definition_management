defmodule EventDefinitionManagement.Events.OrganizationConfig do # <-- Vérifie bien ce nom
  use Ash.Resource,
    otp_app: :event_definition_management,
    domain: EventDefinitionManagement.Events, # <-- Doit être le domaine complet
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organization_configs"
    repo EventDefinitionManagement.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:custom_name, :enabled, :settings, :organization_id, :global_event_id]
    end

    update :update do
      accept [:custom_name, :enabled, :settings]
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :custom_name, :string, public?: true
    attribute :enabled, :boolean, default: true, public?: true
    attribute :settings, :map, default: %{}, public?: true
  end

  relationships do
    # Le lien vers l'organisation (corrigé)
    belongs_to :organization, EventDefinitionManagement.Accounts.Organization do
      allow_nil? false
      public? true
    end

    # Le lien vers l'événement du catalogue (vérifie bien le nom du module GlobalEvent)
    # Si GlobalEvent est aussi dans le domaine Events, assure-toi que le nom est complet
    belongs_to :global_event, EventDefinitionManagement.Events.GlobalEvent do
      allow_nil? false
      public? true
    end
  end
end