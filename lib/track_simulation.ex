defmodule EventDefinitionManagement.TrackSimulation do
  use GenServer

  @vehicules [
    %{immat: "AB-123-CD", organization_id: "org_orange"},
    %{immat: "XY-789-ZT", organization_id: "org_sfr"},
    %{immat: "EF-456-GH", organization_id: "org_bouygues"},
    %{immat: "IJ-789-KL", organization_id: "org_orange"},
    %{immat: "MN-012-OP", organization_id: "org_sfr"}
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_simulation()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:simulate, state) do
    simulate_telemetry()
    schedule_simulation()
    {:noreply, state}
  end

  defp schedule_simulation do
    Process.send_after(self(), :simulate, 25_000)
  end

  defp simulate_telemetry do
    vehicle = Enum.random(@vehicules)
    speed = Enum.random(40..150)
    lat = 48.8566 + :rand.uniform() * 0.1
    lng = 2.3522 + :rand.uniform() * 0.1
    fuel = Enum.random(10..100)

    IO.puts("🔧 Track: #{vehicle.immat} - Vitesse: #{speed} km/h, Carburant: #{fuel}%")

    try_evaluate_rules(vehicle, speed, lat, lng, fuel)
  end

  defp try_evaluate_rules(vehicle, speed, lat, lng, fuel) do
    case Ash.read(EventDefinitionManagement.Events.OrganizationEventConfig) do
      {:ok, configs} ->
        active_configs =
          Enum.filter(configs, fn c ->
            c.active && c.organization_id == vehicle.organization_id
          end)

        Enum.each(active_configs, fn config ->
          threshold = get_in(config.parameters, ["threshold"])

          cond do
            threshold && speed > threshold ->
              create_alert(vehicle, "Excès de vitesse", speed, lat, lng, fuel, config)

            threshold && fuel < threshold ->
              create_alert(vehicle, "Niveau carburant bas", speed, lat, lng, fuel, config)

            true ->
              nil
          end
        end)

      _ ->
        nil
    end
  rescue
    _ -> nil
  end

  defp create_alert(vehicle, event_type, speed, lat, lng, fuel, config) do
    Alert
    |> Ash.Changeset.for_create(:create, %{
      event_type: event_type,
      message: "#{event_type} détecté - Véhicule #{vehicle.immat}",
      vehicle_id: vehicle.organization_id,
      vehicle_immat: vehicle.immat,
      latitude: lat,
      longitude: lng,
      speed: speed,
      fuel_level: fuel,
      status: :en_attente,
      organization_id: vehicle.organization_id,
      organization_event_config_id: config.id
    })
    |> Ash.create!()

    IO.puts("🚨 ALERTE CRÉÉE: #{event_type} - #{vehicle.immat}")
  end
end
