defmodule EventDefinitionManagementWeb.ClientAdminLive.Index do
  use EventDefinitionManagementWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(25_000, self(), :tick_simulation)
    end

    {:ok,
     socket
     |> assign(:page_title, "Administration Client")
     |> assign(:current_view, "dashboard")
     |> load_data()}
  end

  defp load_data(socket) do
    org_id = socket.assigns.current_user.organization_id

    configs =
      EventDefinitionManagement.Events.OrganizationEventConfig
      |> Ash.read!()
      |> Enum.filter(fn c -> c.organization_id == org_id end)

    alerts =
      EventDefinitionManagement.Events.Alert
      |> Ash.read!()
      |> Enum.filter(fn a -> a.organization_id == org_id end)

    org = Ash.get!(EventDefinitionManagement.Accounts.Organization, org_id)

    assign(socket,
      org_name: org.name,
      configs: configs,
      alerts: alerts,
      stats: %{
        total_vehicules: 5,
        alertes_actives: Enum.filter(alerts, fn a -> a.status == :en_attente end) |> length,
        configs_actifs: Enum.filter(configs, fn c -> c.active end) |> length
      }
    )
  end

  @impl true
  def handle_event("switch_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :current_view, view)}
  end

  @impl true
  def handle_event("toggle_active", %{"id" => id}, socket) do
    config = Ash.get!(EventDefinitionManagement.Events.OrganizationEventConfig, id)
    Ash.update!(config, %{active: !config.active})
    {:noreply, socket |> put_flash(:info, "Configuration mise à jour") |> load_data()}
  end

  @impl true
  def handle_event("update_threshold", %{"id" => id, "threshold" => threshold}, socket) do
    config = Ash.get!(EventDefinitionManagement.Events.OrganizationEventConfig, id)
    new_params = Map.merge(config.parameters, %{"threshold" => String.to_integer(threshold)})
    Ash.update!(config, %{parameters: new_params})
    {:noreply, socket |> put_flash(:info, "Seuil mis à jour") |> load_data()}
  end

  @impl true
  def handle_info(:tick_simulation, socket) do
    org_id = socket.assigns.current_user.organization_id

    alerts =
      EventDefinitionManagement.Events.Alert
      |> Ash.read!()
      |> Enum.filter(fn a -> a.organization_id == org_id end)

    socket =
      if length(alerts) > length(socket.assigns.alerts) do
        socket
        |> put_flash(:info, "🔧 Nouvelle alerte détectée")
        |> assign(alerts: alerts)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-[#F0F2F5]">
      <aside class="w-72 bg-[#1E293B] text-white flex flex-col sticky top-0 h-screen shadow-2xl">
        <div class="p-8 border-b border-white/10">
          <img src={~p"/images/logo.png"} class="h-10 w-auto bg-white p-1 rounded-lg mb-4" />
          <p class="text-xs font-black text-indigo-400 uppercase tracking-widest">{@org_name}</p>
          <p class="text-[10px] text-slate-500 mt-1">Administrateur</p>
        </div>

        <nav class="flex-1 px-4 py-6 space-y-2">
          <%= for {id, label, icon} <- [
            {"dashboard", "Tableau de bord", "hero-squares-2x2"},
            {"config", "Configuration", "hero-adjustments-horizontal"},
            {"seuils", "Seuils critiques", "hero-variable"},
            {"alertes", "Alertes", "hero-bell"},
            {"historique", "Historique", "hero-document-chart-bar"}
          ] do %>
            <button
              phx-click="switch_view"
              phx-value-view={id}
              class={[
                "w-full flex items-center gap-4 px-4 py-4 rounded-2xl transition-all",
                if(@current_view == id,
                  do: "bg-indigo-600 text-white",
                  else: "text-slate-400 hover:bg-white/5"
                )
              ]}
            >
              <.icon name={icon} class="w-5 h-5" />
              <span class="text-sm font-bold">{label}</span>
              <%= if id == "alertes" && @stats.alertes_actives > 0 do %>
                <span class="ml-auto bg-red-500 text-[10px] px-2 py-0.5 rounded-full">
                  {@stats.alertes_actives}
                </span>
              <% end %>
            </button>
          <% end %>
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
            <div class="p-3 bg-indigo-50 rounded-2xl text-indigo-600">
              <.icon
                name={
                  case @current_view do
                    "dashboard" -> "hero-squares-2x2"
                    "config" -> "hero-adjustments-horizontal"
                    "seuils" -> "hero-variable"
                    "alertes" -> "hero-bell"
                    "historique" -> "hero-document-chart-bar"
                    _ -> "hero-squares-2x2"
                  end
                }
                class="w-8 h-8"
              />
            </div>
            <div>
              <h2 class="text-2xl font-black text-slate-800 uppercase tracking-tight">
                {@current_view}
              </h2>
              <p class="text-xs text-slate-400 font-bold uppercase tracking-widest leading-relaxed">
                {@org_name}
              </p>
            </div>
          </div>
        </div>

        <%= case @current_view do %>
          <% "dashboard" -> %>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-8 mb-10">
              <div class="bg-white p-8 rounded-[32px] shadow-xl border border-slate-50 text-center">
                <.icon name="hero-truck" class="w-10 h-10 text-indigo-500 mb-4 mx-auto" />
                <p class="text-slate-400 font-bold text-xs uppercase mb-1">Véhicules</p>
                <h4 class="text-3xl font-black text-slate-800">{@stats.total_vehicules}</h4>
              </div>
              <div class="bg-white p-8 rounded-[32px] shadow-xl border border-slate-50 text-center">
                <.icon name="hero-bell-alert" class="w-10 h-10 text-red-500 mb-4 mx-auto" />
                <p class="text-slate-400 font-bold text-xs uppercase mb-1">Alertes actives</p>
                <h4 class="text-3xl font-black text-slate-800">{@stats.alertes_actives}</h4>
              </div>
              <div class="bg-white p-8 rounded-[32px] shadow-xl border border-slate-50 text-center">
                <.icon name="hero-check-circle" class="w-10 h-10 text-emerald-500 mb-4 mx-auto" />
                <p class="text-slate-400 font-bold text-xs uppercase mb-1">Configurations actives</p>
                <h4 class="text-3xl font-black text-slate-800">{@stats.configs_actifs}</h4>
              </div>
            </div>

            <div class="bg-white p-8 rounded-[32px] shadow-sm">
              <h3 class="text-lg font-bold text-slate-800 mb-4">
                Bienvenue sur votre tableau de bord
              </h3>
              <p class="text-slate-500">
                Gérez vos événements, configurez les seuils et surveillez votre flotte en temps réel.
              </p>
            </div>
          <% "config" -> %>
            <div class="bg-white rounded-[32px] shadow-xl border border-slate-50 overflow-hidden">
              <div class="p-6 border-b border-slate-100">
                <h3 class="text-lg font-bold text-slate-800">Configuration des événements</h3>
              </div>
              <table class="w-full text-left">
                <thead class="bg-slate-50/50 border-b border-slate-100 text-slate-400 text-[10px] font-black uppercase">
                  <tr>
                    <th class="p-6">Événement</th>
                    <th class="p-6">Statut</th>
                    <th class="p-6 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-50">
                  <%= for config <- @configs do %>
                    <tr class="hover:bg-slate-50/50">
                      <td class="p-6 font-bold">{config.custom_name || "Événement"}</td>
                      <td class="p-6">
                        <button
                          phx-click="toggle_active"
                          phx-value-id={config.id}
                          class={"px-4 py-2 rounded-lg text-xs font-bold #{if config.active, do: "bg-emerald-100 text-emerald-600", else: "bg-slate-100 text-slate-400"}"}
                        >
                          {if config.active, do: "ACTIF", else: "INACTIF"}
                        </button>
                      </td>
                      <td class="p-6 text-right">
                        <button class="px-4 py-2 bg-indigo-500 text-white rounded-lg text-xs font-bold hover:bg-indigo-600 transition-colors">
                          Configurer
                        </button>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
              <%= if @configs == [] do %>
                <div class="p-12 text-center text-slate-400">
                  <.icon name="hero-folder-open" class="w-12 h-12 mx-auto mb-4 opacity-50" />
                  <p>Aucune configuration trouvée</p>
                </div>
              <% end %>
            </div>
          <% "seuils" -> %>
            <div class="bg-white rounded-[32px] shadow-xl border border-slate-50 overflow-hidden">
              <div class="p-6 border-b border-slate-100">
                <h3 class="text-lg font-bold text-slate-800">Configuration des seuils critiques</h3>
              </div>
              <div class="p-6 space-y-6">
                <%= for config <- @configs do %>
                  <div class="border border-slate-100 rounded-2xl p-6">
                    <h4 class="font-bold text-slate-800 mb-4">{config.custom_name || "Événement"}</h4>
                    <div class="flex items-center gap-4">
                      <label class="text-sm font-medium text-slate-600">Seuil:</label>
                      <input
                        type="number"
                        value={get_in(config.parameters, ["threshold"]) || 100}
                        class="px-4 py-2 border border-slate-200 rounded-lg w-32"
                      />
                      <button class="px-4 py-2 bg-indigo-500 text-white rounded-lg text-xs font-bold hover:bg-indigo-600">
                        Appliquer
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% "alertes" -> %>
            <div class="space-y-4">
              <%= for alert <- @alerts do %>
                <div
                  class={"p-6 rounded-2xl border-l-8 bg-white shadow-lg #{if alert.status == :en_attente, do: "border-red-500", else: "border-slate-300"}"}
                  }
                >
                  <div class="flex justify-between items-center">
                    <div>
                      <p class="font-black text-slate-800 uppercase tracking-tight">
                        {alert.event_type}
                      </p>
                      <p class="text-xs text-slate-500 font-bold uppercase tracking-widest">
                        {alert.vehicle_immat}
                      </p>
                      <p class="text-sm text-slate-600 mt-2">{alert.message}</p>
                    </div>
                    <span class={[
                      "px-4 py-2 rounded-xl text-xs font-bold",
                      if(alert.status == :en_attente,
                        do: "bg-red-100 text-red-600",
                        else: "bg-emerald-100 text-emerald-600"
                      )
                    ]}>
                      {alert.status}
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          <% "historique" -> %>
            <div class="bg-white rounded-[32px] shadow-xl border border-slate-50 p-8">
              <h3 class="text-lg font-bold text-slate-800 mb-6">Historique des alertes</h3>
              <div class="text-center text-slate-400 py-12">
                <.icon name="hero-clock" class="w-12 h-12 mx-auto mb-4 opacity-50" />
                <p>Aucun historique disponible</p>
              </div>
            </div>
        <% end %>
      </main>

      <div class="fixed bottom-8 right-8 flex flex-col gap-3 z-50">
        <%= if info = Phoenix.Flash.get(@flash, :info) do %>
          <div class="bg-slate-900 text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-3">
            <.icon name="hero-information-circle" class="w-5 h-5 text-indigo-400" />
            <span class="text-sm font-bold">{info}</span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
