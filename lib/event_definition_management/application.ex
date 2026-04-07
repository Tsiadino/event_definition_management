defmodule EventDefinitionManagement.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EventDefinitionManagementWeb.Telemetry,
      EventDefinitionManagement.Repo,
      {DNSCluster, query: Application.get_env(:event_definition_management, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EventDefinitionManagement.PubSub},
      # Start a worker by calling: EventDefinitionManagement.Worker.start_link(arg)
      # {EventDefinitionManagement.Worker, arg},
      # Start to serve requests, typically the last entry
      EventDefinitionManagementWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EventDefinitionManagement.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EventDefinitionManagementWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
