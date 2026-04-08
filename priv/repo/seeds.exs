alias EventDefinitionManagement.Events.{GlobalEventDefinition, OrganizationEventConfig, Alert}
alias EventDefinitionManagement.Accounts.{Organization, User}
alias EventDefinitionManagement.Repo

IO.puts("🧹 Nettoyage de la base de données...")

Repo.delete_all(Alert)
Repo.delete_all(OrganizationEventConfig)
Repo.delete_all(GlobalEventDefinition)
Repo.delete_all(User)
Repo.delete_all(Organization)

IO.puts("🌱 Création des organisations...")

tag_ip =
  Organization
  |> Ash.Changeset.for_create(:create, %{name: "TAG-IP Administration"})
  |> Ash.create!()

orange =
  Organization
  |> Ash.Changeset.for_create(:create, %{name: "Orange Madagascar"})
  |> Ash.create!()

sfr =
  Organization
  |> Ash.Changeset.for_create(:create, %{name: "SFR Madagascar"})
  |> Ash.create!()

IO.puts("🏢 Organisations créées: TAG-IP, Orange, SFR")

IO.puts("👑 Création du Super Administrateur...")

User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "fannie@tag-ip.com",
  password: "password1234",
  password_confirmation: "password1234",
  role: :super_admin,
  organization_id: tag_ip.id
})
|> Ash.create!()

IO.puts("✅ Super Admin créé: fannie@tag-ip.com")

IO.puts("🏢 Création des administrateurs clients...")

User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "admin@orange.mg",
  password: "password1234",
  password_confirmation: "password1234",
  role: :client_admin,
  organization_id: orange.id
})
|> Ash.create!()

User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "admin@sfr.mg",
  password: "password1234",
  password_confirmation: "password1234",
  role: :client_admin,
  organization_id: sfr.id
})
|> Ash.create!()

IO.puts("✅ Administrateurs créés: admin@orange.mg, admin@sfr.mg")

IO.puts("👁️ Création des opérateurs...")

User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "operateur@orange.mg",
  password: "password1234",
  password_confirmation: "password1234",
  role: :operator,
  organization_id: orange.id
})
|> Ash.create!()

User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "operateur@sfr.mg",
  password: "password1234",
  password_confirmation: "password1234",
  role: :operator,
  organization_id: sfr.id
})
|> Ash.create!()

IO.puts("✅ Opérateurs créés: operateur@orange.mg, operateur@sfr.mg")

IO.puts("📚 Création du catalogue global d'événements...")

events = [
  %{
    name: "Excès de vitesse",
    description: "Alerte cuando la velocidad excede el umbral configurado",
    event_type: "vitesse",
    default_parameters: %{"threshold" => 110}
  },
  %{
    name: "Sortie de zone",
    description: "Alerte cuando el vehículo sale de la zona geofenceada",
    event_type: "geofencing",
    default_parameters: %{}
  },
  %{
    name: "Niveau carburant bas",
    description: "Alerte cuando el nivel de carburante es inferior al umbral",
    event_type: "carburant",
    default_parameters: %{"threshold" => 20}
  },
  %{
    name: "Arrêt prolongé",
    description: "Alerte cuando el vehículo está detenido durante mucho tiempo",
    event_type: "maintenance",
    default_parameters: %{"duration" => 30}
  },
  %{
    name: "Vitesse excessive",
    description: "Alerte cuando la velocidad supera significativamente el límite",
    event_type: "securite",
    default_parameters: %{"threshold" => 130}
  }
]

Enum.each(events, fn event_attrs ->
  GlobalEventDefinition
  |> Ash.Changeset.for_create(:create, Map.put(event_attrs, :status, :approuve))
  |> Ash.create!()
end)

IO.puts("✅ Catalogue créé avec #{length(events)} événements")

IO.puts("🔧 Configuration des événements par organisation...")

global_events = Ash.read!(GlobalEventDefinition)

Enum.each(global_events, fn event ->
  OrganizationEventConfig
  |> Ash.Changeset.for_create(:create, %{
    custom_name: event.name,
    active: true,
    parameters: event.default_parameters,
    actions: %{},
    organization_id: orange.id,
    global_event_definition_id: event.id
  })
  |> Ash.create!()

  OrganizationEventConfig
  |> Ash.Changeset.for_create(:create, %{
    custom_name: event.name,
    active: event.name in ["Excès de vitesse", "Niveau carburant bas"],
    parameters: Map.put(event.default_parameters, "threshold", 120),
    actions: %{},
    organization_id: sfr.id,
    global_event_definition_id: event.id
  })
  |> Ash.create!()
end)

IO.puts("✅ Configurations créées pour Orange et SFR")

IO.puts("🎉 Initialisation terminée!")
IO.puts("")
IO.puts("=== COMPTES DE TEST ===")
IO.puts("Super Admin: fannie@tag-ip.com / password1234")
IO.puts("Admin Orange: admin@orange.mg / password1234")
IO.puts("Admin SFR: admin@sfr.mg / password1234")
IO.puts("Opérateur Orange: operateur@orange.mg / password1234")
IO.puts("Opérateur SFR: operateur@sfr.mg / password1234")
