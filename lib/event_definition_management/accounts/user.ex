defmodule EventDefinitionManagement.Accounts.User do
  use Ash.Resource,
    otp_app: :event_definition_management,
    domain: EventDefinitionManagement.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  authentication do
    strategies do
      password :password do
        identity_field :email
        hash_provider AshAuthentication.BcryptProvider
        
        resettable do
          sender EventDefinitionManagement.Accounts.User.Senders.SendPasswordResetEmail
          password_reset_action_name :reset_password_with_token
          request_password_reset_action_name :request_password_reset_token
        end
      end
    end

    tokens do
      enabled? true
      token_resource EventDefinitionManagement.Accounts.Token
      signing_secret EventDefinitionManagement.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end
  end

  postgres do
    table "users"
    repo EventDefinitionManagement.Repo
  end

  actions do
    defaults [:read]

    create :register_with_password do
      argument :email, :ci_string, allow_nil?: false
      argument :password, :string, allow_nil?: false, sensitive?: true
      argument :password_confirmation, :string, allow_nil?: false, sensitive?: true
      argument :role, :atom, allow_nil?: false
      argument :organization_id, :uuid, allow_nil?: false

      # 1. Validation : Vérifie que les deux mots de passe sont identiques
      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation

      # 2. Changements : Assigne les valeurs aux attributs
      change set_attribute(:email, arg(:email))
      change set_attribute(:role, arg(:role))
      change set_attribute(:organization_id, arg(:organization_id))
      
      # 3. Hachage du mot de passe
      change AshAuthentication.Strategy.Password.HashPasswordChange
      
      # 4. Génération du token de session
      change AshAuthentication.GenerateTokenChange
    end
  end
  policies do
    # Autorise les interactions internes d'AshAuthentication
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    # Autorise la création (pour le seed)
    policy action(:register_with_password) do
      authorize_if always()
    end

    # L'utilisateur peut lire ses propres données
    policy action_type(:read) do
      authorize_if relates_to_actor_via(:id)
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false, public?: true 
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    
    attribute :role, :atom do
      constraints [one_of: [:super_admin, :client_admin, :operator]]
      default :operator
      allow_nil? false
      public? true
    end

    attribute :organization_id, :uuid, public?: true
  end

  relationships do
    belongs_to :organization, EventDefinitionManagement.Accounts.Organization do
      public? true
    end
  end

  identities do
    identity :unique_email, [:email]
  end
end