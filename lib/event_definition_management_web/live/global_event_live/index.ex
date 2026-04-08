defmodule EventDefinitionManagementWeb.GlobalEventLive.Index do
  use EventDefinitionManagementWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(25000, self(), :tick_simulation)

    {:ok,
     socket
     |> assign(:page_title, "Super Admin TAG-IP")
     |> assign(:current_view, "monitoring") # Vue par défaut
     |> assign(:notifications_count, 1)
     |> assign(:stats, %{latence: "42ms", dispo: "99.99%", alerts_today: 12})
     |> assign(:events, list_mock_events())
     |> assign(:pending_events, list_pending_events())
     |> assign(:vehicles, list_mock_vehicles())
     |> assign(:history_logs, ["Super Admin a créé 'Incident réseau'", "Validation de 'Maintenance serveur'"])}

    events = 
      EventDefinitionManagement.Catalogue.GlobalEventDefinition
      |> Ash.Query.for_read(:read)
      |> Ash.read!()

  {:ok, assign(socket, :events, events)}
  end

  # --- NAVIGATION ---
  @impl true
  def handle_event("switch_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :current_view, view)}
  end

  # --- ACTIONS ---
  @impl true
  def handle_event("delete_event", %{"id" => id}, socket) do
    updated = Enum.reject(socket.assigns.events, &(&1.id == String.to_integer(id)))
    {:noreply, socket |> assign(:events, updated) |> put_flash(:error, "Événement supprimé")}
  end

  @impl true
  def handle_info(:tick_simulation, socket) do
    vitesse = Enum.random(60..140)
    socket = if vitesse > 110 do
      socket 
      |> put_flash(:info, "🤖 Simulation : Vitesse excessive détectée (#{vitesse} km/h)")
      |> assign(:notifications_count, socket.assigns.notifications_count + 1)
    else
      socket
    end
    {:noreply, socket}
  end

  # --- DATA MOCK ---
  defp list_mock_events, do: [%{id: 1, name: "Excès de vitesse", type: "Vitesse", active_globally: true}, %{id: 2, name: "Sortie de zone", type: "Géofencing", active_globally: false}]
  defp list_pending_events, do: [%{id: 101, name: "Niveau carburant bas", user: "Client_Logistique"}]
  defp list_mock_vehicles, do: [%{immat: "AB-123-CD", org: "Orange", status: "actif"}, %{immat: "XY-789-ZT", org: "SFR", status: "maintenance"}]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-[#F8F9FC]">
      
      <%!-- SIDEBAR OPÉRATIONNELLE --%>
      <aside class="w-72 bg-[#0F172A] text-white flex flex-col sticky top-0 h-screen shadow-2xl">
        <div class="p-8 mb-4">
          <div class="bg-white p-3 rounded-2xl shadow-lg shadow-indigo-500/10">
            <img src={~p"/images/logo.png"} alt="TAG-IP" class="h-10 w-auto mx-auto object-contain" />
          </div>
          <p class="text-[10px] text-center text-slate-500 uppercase tracking-[0.2em] mt-4 font-bold tracking-widest">Super Admin</p>
        </div>

        <nav class="flex-1 px-4 space-y-1">
          <%= for {id, label, icon} <- [
            {"monitoring", "Monitoring", "hero-chart-bar"},
            {"catalogue", "Catalogue Global", "hero-book-open"},
            {"validation", "Validation", "hero-check-badge"},
            {"alertes", "Alertes", "hero-bell"},
            {"vehicules", "Véhicules", "hero-truck"},
            {"historique", "Historique", "hero-clock"}
          ] do %>
            <button phx-click="switch_view" phx-value-view={id} 
              class={["w-full flex items-center gap-4 px-4 py-3.5 rounded-xl transition-all font-medium group", 
              if(@current_view == id, do: "bg-indigo-600 text-white shadow-lg shadow-indigo-500/20", else: "text-slate-400 hover:bg-white/5 hover:text-white")]}>
              <.icon name={icon} class={"w-5 h-5 #{if @current_view == id, do: "text-white", else: "text-slate-500 group-hover:text-indigo-400"}"} />
              <span class="text-sm">{label}</span>
              <%= if id == "alertes" && @notifications_count > 0 do %>
                <span class="ml-auto bg-red-500 text-[10px] px-2 py-0.5 rounded-full animate-pulse font-black text-white">{@notifications_count}</span>
              <% end %>
            </button>
          <% end %>
        </nav>
      </aside>

      <main class="flex-1 p-10 overflow-y-auto">
        <%!-- HEADER DYNAMIQUE --%>
        <div class="flex justify-between items-center mb-10 bg-white p-8 rounded-[32px] shadow-sm border border-slate-100">
          <div class="flex items-center gap-4">
            <div class="p-3 bg-indigo-50 rounded-2xl text-indigo-600">
              <.icon name={
                case @current_view do
                  "monitoring" -> "hero-chart-bar"
                  "catalogue" -> "hero-book-open"
                  "validation" -> "hero-check-badge"
                  "alertes" -> "hero-bell"
                  "vehicules" -> "hero-truck"
                  "historique" -> "hero-clock"
                  _ -> "hero-squares-2x2"
                end
              } class="w-8 h-8" />
            </div>
            <div>
              <h2 class="text-2xl font-black text-slate-800 uppercase tracking-tight">{@current_view}</h2>
              <p class="text-xs text-slate-400 font-bold uppercase tracking-widest leading-relaxed">TAG-IP Cross-Orga Control</p>
            </div>
          </div>
        </div>

        <%!-- CONTENU DYNAMIQUE --%>
        <%= case @current_view do %>
          <% "monitoring" -> %>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div class="bg-white p-8 rounded-[32px] shadow-xl border border-slate-50 text-center">
                <.icon name="hero-bolt" class="w-10 h-10 text-indigo-500 mb-4 mx-auto" />
                <p class="text-slate-400 font-bold text-xs uppercase mb-1">Latence</p>
                <h4 class="text-3xl font-black text-slate-800">{@stats.latence}</h4>
              </div>
              <div class="bg-white p-8 rounded-[32px] shadow-xl border border-slate-50 text-center">
                <.icon name="hero-arrow-trending-up" class="w-10 h-10 text-emerald-500 mb-4 mx-auto" />
                <p class="text-slate-400 font-bold text-xs uppercase mb-1">Disponibilité</p>
                <h4 class="text-3xl font-black text-slate-800">{@stats.dispo}</h4>
              </div>
              <div class="bg-white p-8 rounded-[32px] shadow-xl border border-slate-50 text-center">
                <.icon name="hero-exclamation-triangle" class="w-10 h-10 text-red-500 mb-4 mx-auto" />
                <p class="text-slate-400 font-bold text-xs uppercase mb-1">Alertes (24h)</p>
                <h4 class="text-3xl font-black text-slate-800">{@stats.alerts_today}</h4>
              </div>
            </div>

          <% "catalogue" -> %>
            <div class="bg-white rounded-[32px] shadow-xl border border-slate-50 overflow-hidden">
              <table class="w-full text-left">
                <thead class="bg-slate-50/50 border-b border-slate-100 text-slate-400 text-[10px] font-black uppercase">
                  <tr><th class="p-8">Nom</th><th class="p-8">Type</th><th class="p-8 text-center">Status</th><th class="p-8 text-right">Actions</th></tr>
                </thead>
                <tbody class="divide-y divide-slate-50">
                  <%= for event <- @events do %>
                    <tr class="hover:bg-slate-50/50"><td class="p-8 font-bold text-slate-700">{event.name}</td><td class="p-8 text-slate-500 text-sm font-medium">{event.type}</td>
                      <td class="p-8 text-center"><button class={"px-5 py-1.5 rounded-full text-[10px] font-black #{if event.active_globally, do: "bg-emerald-100 text-emerald-600", else: "bg-slate-100 text-slate-400"}"}>{if event.active_globally, do: "ACTIF", else: "INACTIF"}</button></td>
                      <td class="p-8 text-right space-x-2"><button phx-click="delete_event" phx-value-id={event.id} class="p-2 text-slate-300 hover:text-red-500"><.icon name="hero-trash" class="w-5 h-5" /></button></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

          <% "vehicules" -> %>
            <div class="bg-white rounded-[32px] shadow-xl border border-slate-50 overflow-hidden p-8">
              <h3 class="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2"><.icon name="hero-truck" class="w-6 h-6 text-indigo-500" /> Parc véhicules (toutes organisations)</h3>
              <table class="w-full text-left">
                <thead class="text-slate-400 text-[10px] font-black uppercase border-b border-slate-100">
                  <tr><th class="pb-4">Immatriculation</th><th class="pb-4">Organisation</th><th class="pb-4">Statut</th></tr>
                </thead>
                <tbody class="divide-y divide-slate-50">
                  <%= for v <- @vehicles do %>
                    <tr class="hover:bg-slate-50/30 transition-all"><td class="py-4 font-bold text-slate-700">{v.immat}</td><td class="py-4 text-slate-500">{v.org}</td><td class="py-4"><span class="text-xs font-medium px-3 py-1 bg-slate-100 rounded-lg">{v.status}</span></td></tr>
                  <% end %>
                </tbody>
              </table>
            </div>

          <% "historique" -> %>
            <div class="bg-white p-8 rounded-[32px] shadow-xl border border-slate-50">
              <h3 class="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2"><.icon name="hero-clock" class="w-6 h-6 text-indigo-500" /> Traçabilité des actions</h3>
              <ul class="space-y-4">
                <%= for log <- @history_logs do %>
                  <li class="flex items-center gap-4 p-4 hover:bg-slate-50 rounded-2xl transition-all border border-transparent hover:border-slate-100">
                    <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center text-indigo-500"><.icon name="hero-check-circle" class="w-5 h-5" /></div>
                    <span class="text-slate-600 font-medium">{log}</span>
                  </li>
                <% end %>
              </ul>
            </div>

          <% _ -> %>
            <div class="bg-white p-20 rounded-[32px] text-center border-4 border-dashed border-slate-100 text-slate-400">
              <.icon name="hero-command-line" class="w-12 h-12 mb-4 mx-auto opacity-20" />
              <p class="text-xl font-medium uppercase tracking-widest">Module {@current_view} en cours d'initialisation...</p>
            </div>
        <% end %>
      </main>

      <%!-- FEEDBACK TOASTS --%>
      <div class="fixed bottom-8 right-8 flex flex-col gap-3 z-50">
        <%= if info = Phoenix.Flash.get(@flash, :info) do %>
          <div class="bg-slate-900 text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-3 animate-slide-in-right">
            <.icon name="hero-information-circle" class="w-5 h-5 text-indigo-400" /> <span class="text-sm font-bold">{info}</span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end