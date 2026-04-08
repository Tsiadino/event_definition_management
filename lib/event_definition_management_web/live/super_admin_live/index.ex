defmodule EventDefinitionManagementWeb.SuperAdminLive.Index do
  use EventDefinitionManagementWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(25_000, self(), :tick_simulation)
    end

    {:ok,
     socket
     |> assign(:page_title, "TAG-IP Super Administrateur")
     |> assign(:current_view, "monitoring")
     |> load_data()}
  end

  defp load_data(socket) do
    events = Ash.read!(EventDefinitionManagement.Events.GlobalEventDefinition)
    alerts = Ash.read!(EventDefinitionManagement.Events.Alert)

    stats = %{
      latence: "42ms",
      dispo: "99.99%",
      alerts_today: length(alerts),
      total_events: length(events),
      pending_validation: Enum.filter(events, fn e -> e.status == :en_attente end) |> length
    }

    assign(socket,
      events: events,
      alerts: alerts,
      stats: stats,
      history_logs: [
        "Création du catalogue 'Excès de vitesse'",
        "Validation de 'Sortie de zone'",
        "Rejet de 'Test événement'"
      ]
    )
  end

  @impl true
  def handle_event("switch_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :current_view, view)}
  end

  @impl true
  def handle_event("create_event", %{"event" => event_params}, socket) do
    case Ash.create(EventDefinitionManagement.Events.GlobalEventDefinition, %{
           name: event_params["name"],
           description: event_params["description"],
           event_type: event_params["event_type"],
           default_parameters: %{},
           version: 1,
           active_globally: false,
           status: :en_attente
         }) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Événement créé avec succès") |> load_data()}

      {:error, changeset} ->
        {:noreply, socket |> put_flash(:error, "Erreur: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("validate_event", %{"id" => id}, socket) do
    event = Ash.get!(EventDefinitionManagement.Events.GlobalEventDefinition, id)
    Ash.update!(event, %{status: :approuve, active_globally: true})
    {:noreply, socket |> put_flash(:info, "Événement validé et activé") |> load_data()}
  end

  @impl true
  def handle_event("reject_event", %{"id" => id}, socket) do
    event = Ash.get!(EventDefinitionManagement.Events.GlobalEventDefinition, id)
    Ash.update!(event, %{status: :rejete})
    {:noreply, socket |> put_flash(:info, "Événement rejeté") |> load_data()}
  end

  @impl true
  def handle_event("delete_event", %{"id" => id}, socket) do
    event = Ash.get!(EventDefinitionManagement.Events.GlobalEventDefinition, id)
    Ash.destroy!(event)
    {:noreply, socket |> put_flash(:info, "Événement supprimé") |> load_data()}
  end

  @impl true
  def handle_event("toggle_active", %{"id" => id}, socket) do
    event = Ash.get!(EventDefinitionManagement.Events.GlobalEventDefinition, id)
    Ash.update!(event, %{active_globally: !event.active_globally})
    {:noreply, socket |> load_data()}
  end

  @impl true
  def handle_info(:tick_simulation, socket) do
    alerts = Ash.read!(EventDefinitionManagement.Events.Alert)
    stats = %{socket.assigns.stats | alerts_today: length(alerts)}

    socket =
      if length(alerts) > socket.assigns.stats.alerts_today do
        socket
        |> put_flash(:info, "🔧 Simulation: Nouvel alerte déclenchée")
        |> assign(stats: stats)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-[#F8F9FC]">
      <aside class="w-72 bg-[#0F172A] text-white flex flex-col sticky top-0 h-screen shadow-2xl">
        <div class="p-8 mb-4">
          <div class="bg-white p-3 rounded-2xl shadow-lg shadow-indigo-500/10">
            <img src={~p"/images/logo.png"} alt="TAG-IP" class="h-10 w-auto mx-auto object-contain" />
          </div>
          <p class="text-[10px] text-center text-slate-500 uppercase tracking-[0.2em] mt-4 font-bold tracking-widest">
            Super Administrateur
          </p>
        </div>

        <nav class="flex-1 px-4 space-y-1">
          <%= for {id, label, icon} <- [
            {"monitoring", "Monitoring", "hero-chart-bar"},
            {"catalogue", "Catalogue Global", "hero-book-open"},
            {"validation", "Validation", "hero-check-badge"},
            {"alertes", "Alertes", "hero-bell"},
            {"historique", "Historique", "hero-clock"}
          ] do %>
            <button
              phx-click="switch_view"
              phx-value-view={id}
              class={[
                "w-full flex items-center gap-4 px-4 py-3.5 rounded-xl transition-all font-medium group",
                if(@current_view == id,
                  do: "bg-indigo-600 text-white shadow-lg shadow-indigo-500/20",
                  else: "text-slate-400 hover:bg-white/5 hover:text-white"
                )
              ]}
            >
              <.icon
                name={icon}
                class={"w-5 h-5 #{if @current_view == id, do: "text-white", else: "text-slate-500 group-hover:text-indigo-400"}"}
              />
              <span class="text-sm">{label}</span>
              <%= if id == "alertes" && @stats.alerts_today > 0 do %>
                <span class="ml-auto bg-red-500 text-[10px] px-2 py-0.5 rounded-full animate-pulse font-black text-white">
                  {@stats.alerts_today}
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
                    "monitoring" -> "hero-chart-bar"
                    "catalogue" -> "hero-book-open"
                    "validation" -> "hero-check-badge"
                    "alertes" -> "hero-bell"
                    "historique" -> "hero-clock"
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
                TAG-IP Contrôle Central
              </p>
            </div>
          </div>
        </div>

        <%= case @current_view do %>
          <% "monitoring" -> %>
            <div class="grid grid-cols-1 md:grid-cols-4 gap-8 mb-10">
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
              <div class="bg-white p-8 rounded-[32px] shadow-xl border border-slate-50 text-center">
                <.icon name="hero-document-check" class="w-10 h-10 text-amber-500 mb-4 mx-auto" />
                <p class="text-slate-400 font-bold text-xs uppercase mb-1">En attente</p>
                <h4 class="text-3xl font-black text-slate-800">{@stats.pending_validation}</h4>
              </div>
            </div>
          <% "catalogue" -> %>
            <div class="bg-white rounded-[32px] shadow-xl border border-slate-50 overflow-hidden">
              <div class="p-6 border-b border-slate-100 flex justify-between items-center">
                <h3 class="text-lg font-bold text-slate-800">Événements du catalogue</h3>
                <button
                  phx-click="show_create_modal"
                  class="bg-indigo-600 text-white px-6 py-3 rounded-xl font-bold hover:bg-indigo-700 transition-colors"
                >
                  + Nouvel événement
                </button>
              </div>
              <table class="w-full text-left">
                <thead class="bg-slate-50/50 border-b border-slate-100 text-slate-400 text-[10px] font-black uppercase">
                  <tr>
                    <th class="p-8">Nom</th>
                    <th class="p-8">Type</th>
                    <th class="p-8">Statut</th>
                    <th class="p-8">Activation</th>
                    <th class="p-8 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-50">
                  <%= for event <- @events do %>
                    <tr class="hover:bg-slate-50/50">
                      <td class="p-8 font-bold text-slate-700">{event.name}</td>
                      <td class="p-8 text-slate-500 text-sm font-medium">{event.event_type}</td>
                      <td class="p-8">
                        <span class={[
                          "px-5 py-1.5 rounded-full text-[10px] font-black",
                          cond do
                            event.status == :approuve -> "bg-emerald-100 text-emerald-600"
                            event.status == :en_attente -> "bg-amber-100 text-amber-600"
                            true -> "bg-red-100 text-red-600"
                          end
                        ]}>
                          {event.status}
                        </span>
                      </td>
                      <td class="p-8">
                        <button
                          phx-click="toggle_active"
                          phx-value-id={event.id}
                          class={"px-5 py-1.5 rounded-full text-[10px] font-black #{if event.active_globally, do: "bg-emerald-100 text-emerald-600", else: "bg-slate-100 text-slate-400"}"}
                        >
                          {if event.active_globally, do: "ACTIF", else: "INACTIF"}
                        </button>
                      </td>
                      <td class="p-8 text-right space-x-2">
                        <button
                          phx-click="delete_event"
                          phx-value-id={event.id}
                          class="p-2 text-slate-300 hover:text-red-500 transition-colors"
                        >
                          <.icon name="hero-trash" class="w-5 h-5" />
                        </button>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% "validation" -> %>
            <div class="bg-white rounded-[32px] shadow-xl border border-slate-50 overflow-hidden">
              <div class="p-6 border-b border-slate-100">
                <h3 class="text-lg font-bold text-slate-800">Événements en attente de validation</h3>
              </div>
              <table class="w-full text-left">
                <thead class="bg-slate-50/50 border-b border-slate-100 text-slate-400 text-[10px] font-black uppercase">
                  <tr>
                    <th class="p-8">Nom</th>
                    <th class="p-8">Type</th>
                    <th class="p-8">Description</th>
                    <th class="p-8 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-50">
                  <%= for event <- Enum.filter(@events, fn e -> e.status == :en_attente end) do %>
                    <tr class="hover:bg-slate-50/50">
                      <td class="p-8 font-bold text-slate-700">{event.name}</td>
                      <td class="p-8 text-slate-500 text-sm font-medium">{event.event_type}</td>
                      <td class="p-8 text-slate-500">{event.description}</td>
                      <td class="p-8 text-right space-x-2">
                        <button
                          phx-click="validate_event"
                          phx-value-id={event.id}
                          class="px-4 py-2 bg-emerald-500 text-white rounded-lg text-xs font-bold hover:bg-emerald-600 transition-colors"
                        >
                          Valider
                        </button>
                        <button
                          phx-click="reject_event"
                          phx-value-id={event.id}
                          class="px-4 py-2 bg-red-500 text-white rounded-lg text-xs font-bold hover:bg-red-600 transition-colors"
                        >
                          Rejeter
                        </button>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
              <%= if Enum.filter(@events, fn e -> e.status == :en_attente end) == [] do %>
                <div class="p-12 text-center text-slate-400">
                  <.icon name="hero-check-circle" class="w-12 h-12 mx-auto mb-4 opacity-50" />
                  <p>Aucun événement en attente de validation</p>
                </div>
              <% end %>
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
                        {alert.vehicle_immat} • {alert.message}
                      </p>
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
            <div class="bg-white p-8 rounded-[32px] shadow-xl border border-slate-50">
              <h3 class="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2">
                <.icon name="hero-clock" class="w-6 h-6 text-indigo-500" /> Traçabilité des actions
              </h3>
              <ul class="space-y-4">
                <%= for log <- @history_logs do %>
                  <li class="flex items-center gap-4 p-4 hover:bg-slate-50 rounded-2xl transition-all border border-transparent hover:border-slate-100">
                    <div class="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center text-indigo-500">
                      <.icon name="hero-check-circle" class="w-5 h-5" />
                    </div>
                    <span class="text-slate-600 font-medium">{log}</span>
                  </li>
                <% end %>
              </ul>
            </div>
        <% end %>
      </main>

      <div class="fixed bottom-8 right-8 flex flex-col gap-3 z-50">
        <%= if info = Phoenix.Flash.get(@flash, :info) do %>
          <div class="bg-slate-900 text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-3 animate-slide-in-right">
            <.icon name="hero-information-circle" class="w-5 h-5 text-indigo-400" />
            <span class="text-sm font-bold">{info}</span>
          </div>
        <% end %>
        <%= if error = Phoenix.Flash.get(@flash, :error) do %>
          <div class="bg-red-500 text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-3">
            <.icon name="hero-exclamation-circle" class="w-5 h-5" />
            <span class="text-sm font-bold">{error}</span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
