defmodule EventDefinitionManagementWeb.OperatorLive.Index do
  use EventDefinitionManagementWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(10_000, self(), :refresh_alerts)
    end

    {:ok, load_data(socket)}
  end

  defp load_data(socket) do
    org_id = socket.assigns.current_user.organization_id

    alerts =
      EventDefinitionManagement.Events.Alert
      |> Ash.read!()
      |> Enum.filter(fn a -> a.organization_id == org_id end)

    org = Ash.get!(EventDefinitionManagement.Accounts.Organization, org_id)

    filtered_alerts = alerts
    pending_count = Enum.filter(alerts, fn a -> a.status == :en_attente end) |> length

    assign(socket,
      org_name: org.name,
      alerts: alerts,
      filtered_alerts: filtered_alerts,
      filter_status: "all",
      pending_count: pending_count
    )
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    filtered_alerts =
      case status do
        "all" -> socket.assigns.alerts
        "pending" -> Enum.filter(socket.assigns.alerts, fn a -> a.status == :en_attente end)
        "acknowledged" -> Enum.filter(socket.assigns.alerts, fn a -> a.status == :acquitte end)
        "resolved" -> Enum.filter(socket.assigns.alerts, fn a -> a.status == :resolu end)
      end

    {:noreply, assign(socket, filter_status: status, filtered_alerts: filtered_alerts)}
  end

  @impl true
  def handle_event("acknowledge_alert", %{"id" => id}, socket) do
    alert = Ash.get!(EventDefinitionManagement.Events.Alert, id)

    Ash.update!(alert, %{
      status: :acquitte,
      acknowledged_at: DateTime.utc_now(),
      acknowledged_by: socket.assigns.current_user.id
    })

    {:noreply, socket |> put_flash(:info, "Alerte acquittée") |> load_data()}
  end

  @impl true
  def handle_info(:refresh_alerts, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-[#F0F2F5]">
      <aside class="w-72 bg-[#1E293B] text-white flex flex-col sticky top-0 h-screen shadow-2xl">
        <div class="p-8 border-b border-white/10">
          <img src={~p"/images/logo.png"} class="h-10 w-auto bg-white p-1 rounded-lg mb-4" />
          <p class="text-xs font-black text-indigo-400 uppercase tracking-widest">{@org_name}</p>
          <p class="text-[10px] text-slate-500 mt-1">Opérateur</p>
        </div>

        <nav class="flex-1 px-4 py-6 space-y-2">
          <button class="w-full flex items-center gap-4 px-4 py-4 rounded-2xl transition-all bg-indigo-600 text-white">
            <.icon name="hero-bell-alert" class="w-5 h-5" />
            <span class="text-sm font-bold">Alertes en temps réel</span>
            <%= if @pending_count > 0 do %>
              <span class="ml-auto bg-red-500 text-[10px] px-2 py-0.5 rounded-full animate-pulse">
                {@pending_count}
              </span>
            <% end %>
          </button>
        </nav>

        <div class="p-4 border-t border-white/10">
          <a
            href="/auth/user/password/sign_out"
            class="flex items-center gap-3 px-4 py-3 rounded-xl text-slate-400 hover:bg-red-500/10 hover:text-red-400 transition-all"
          >
            <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5" />
            <span class="text-sm font-medium">Déconnexion</span>
          </a>
        </div>
      </aside>

      <main class="flex-1 p-10 overflow-y-auto">
        <div class="flex justify-between items-center mb-10 bg-white p-8 rounded-[32px] shadow-sm border border-slate-100">
          <div class="flex items-center gap-4">
            <div class="p-3 bg-red-50 rounded-2xl text-red-600">
              <.icon name="hero-bell-alert" class="w-8 h-8" />
            </div>
            <div>
              <h2 class="text-2xl font-black text-slate-800 uppercase tracking-tight">Alertes</h2>
              <p class="text-xs text-slate-400 font-bold uppercase tracking-widest leading-relaxed">
                {@org_name}
              </p>
            </div>
          </div>
          <div class="flex gap-2">
            <%= for {status, label} <- [
              {"all", "Toutes"},
              {"pending", "En attente"},
              {"acknowledged", "Acquittées"},
              {"resolved", "Résolues"}
            ] do %>
              <button
                phx-click="filter_status"
                phx-value-status={status}
                class={"px-4 py-2 rounded-lg text-xs font-bold transition-all #{if @filter_status == status, do: "bg-indigo-600 text-white", else: "bg-slate-100 text-slate-600 hover:bg-slate-200"}"}
              >
                {label}
              </button>
            <% end %>
          </div>
        </div>

        <div class="space-y-4">
          <%= for alert <- @filtered_alerts do %>
            <div class={"p-6 rounded-2xl border-l-8 bg-white shadow-lg transition-all #{if alert.status == :en_attente, do: "border-red-500 hover:shadow-xl", else: "border-slate-300"}"}>
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2">
                    <p class="font-black text-slate-800 uppercase tracking-tight text-lg">
                      {alert.event_type}
                    </p>
                    <span class={[
                      "px-3 py-1 rounded-full text-[10px] font-black",
                      cond do
                        alert.status == :en_attente -> "bg-red-100 text-red-600"
                        alert.status == :acquitte -> "bg-amber-100 text-amber-600"
                        true -> "bg-emerald-100 text-emerald-600"
                      end
                    ]}>
                      {alert.status}
                    </span>
                  </div>
                  <p class="text-sm font-bold text-slate-600 mb-1">
                    <.icon name="hero-truck" class="w-4 h-4 inline" /> {alert.vehicle_immat}
                  </p>
                  <p class="text-sm text-slate-500">{alert.message}</p>
                  <div class="mt-3 flex gap-4 text-xs text-slate-400">
                    <span>
                      <.icon name="hero-speedometer" class="w-4 h-4 inline" /> {alert.speed} km/h
                    </span>
                    <span>
                      <.icon name="hero-beaker" class="w-4 h-4 inline" /> {alert.fuel_level}%
                    </span>
                  </div>
                </div>
                <%= if alert.status == :en_attente do %>
                  <button
                    phx-click="acknowledge_alert"
                    phx-value-id={alert.id}
                    class="bg-red-500 text-white px-6 py-3 rounded-xl text-sm font-bold hover:bg-red-600 transition-colors shadow-lg hover:shadow-red-500/30"
                  >
                    ACCUSER RÉCEPTION
                  </button>
                <% else %>
                  <div class="text-right">
                    <p class="text-xs text-slate-400">Acquitté</p>
                    <p class="text-xs text-slate-500">
                      {alert.acknowledged_at && Calendar.strftime(alert.acknowledged_at, "%H:%M:%S")}
                    </p>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>

        <%= if @filtered_alerts == [] do %>
          <div class="bg-white p-12 rounded-[32px] text-center border-4 border-dashed border-slate-100 text-slate-400">
            <.icon name="hero-bell-slash" class="w-16 h-16 mx-auto mb-4 opacity-30" />
            <p class="text-xl font-medium uppercase tracking-widest">Aucune alerte</p>
          </div>
        <% end %>
      </main>

      <div class="fixed bottom-8 right-8 flex flex-col gap-3 z-50">
        <%= if info = Phoenix.Flash.get(@flash, :info) do %>
          <div class="bg-slate-900 text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-3">
            <.icon name="hero-check-circle" class="w-5 h-5 text-emerald-400" />
            <span class="text-sm font-bold">{info}</span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
