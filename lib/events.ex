defmodule EventDefinitionManagement.Events do
  use Ash.Domain

  resources do
    resource EventDefinitionManagement.Events.GlobalEventDefinition
    resource EventDefinitionManagement.Events.OrganizationEventConfig
    resource EventDefinitionManagement.Events.Alert
    resource EventDefinitionManagement.Events.GlobalEvent
    resource EventDefinitionManagement.Events.OrganizationConfig
  end
end
