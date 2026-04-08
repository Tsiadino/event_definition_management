defmodule EventDefinitionManagementWeb.AuthLive do
  use EventDefinitionManagementWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen bg-gradient-to-br from-base-200 to-base-300">
        <div class="card w-full max-w-md bg-base-100 shadow-2xl glass rounded-3xl border border-base-content/10">
            <div class="card-body p-10 gap-6">
            
            <%!-- En-tête avec Logo TAG-IP --%>
            <div class="flex flex-col items-center gap-2 mb-4 text-center">
                <div class="flex items-center justify-center w-20 h-20 rounded-full bg-primary/10 text-primary">
                <span class="text-4xl">🏷️</span>
                </div>
                <h1 class="text-3xl font-bold tracking-tight text-primary">TAG-IP</h1>
                <p class="text-sm text-base-content/70">Gestion des Événements</p>
            </div>

            <div class="space-y-4">
                <h2 class="text-lg font-semibold text-center text-base-content">
                Espace Administration
                </h2>
                
                <style>
                /* Force la largeur et empêche le débordement des inputs générés par Ash */
                #sign-in-container input {
                    width: 100% !important;
                    max-width: 100% !important;
                    box-sizing: border-box !important;
                    padding-right: 45px !important; /* Espace pour l'icône */
                    border-radius: 0.5rem !important;
                }

                #sign-in-container button[type="submit"] {
                    width: 100% !important;
                    max-width: 100% !important;
                    margin-top: 1.5rem !important;
                    border-radius: 0.5rem !important;
                }

                /* Conteneur parent relatif pour l'alignement de l'icône */
                .auth-wrapper {
                    position: relative;
                    width: 100%;
                }

                /* Positionnement précis de l'œil à l'intérieur de l'input */
                .pwd-toggle {
                    position: absolute;
                    right: 12px;
                    /* On cible l'input password pour l'alignement vertical */
                    bottom: 85px; 
                    z-index: 20;
                    cursor: pointer;
                    background: transparent !important;
                    border: none !important;
                }
                </style>

                <div id="sign-in-container" class="form-control w-full p-1">
                <div class="auth-wrapper">
                    <.live_component
                    module={AshAuthentication.Phoenix.Components.SignIn}
                    id="sign-in"
                    otp_app={:event_definition_management}
                    auth_routes_prefix="/auth"
                    />
                    
                    <%!-- Bouton Vue/Pas vue placé stratégiquement --%>
                    <button 
                    type="button" 
                    class="pwd-toggle opacity-50 hover:opacity-100 transition-opacity"
                    onclick="togglePasswordVisibility()"
                    tabindex="-1"
                    >
                    <span id="eye-icon" class="text-xl">👁️</span>
                    </button>
                </div>
                </div>
            </div>
            
            <p class="text-center text-xs text-base-content/60 mt-6 border-t border-base-content/5 pt-4">
                Accès réservé au personnel TAG-IP autorisé.
            </p>

            <%!-- JavaScript corrigé pour détecter l'input généré --%>
            <script>
                function togglePasswordVisibility() {
                // On cherche l'input qui contient 'password' dans son nom ou type
                const pwdInput = document.querySelector('input[type="password"]') || 
                                document.querySelector('input[name*="password"]');
                const eyeIcon = document.getElementById('eye-icon');
                
                if (pwdInput.type === "password") {
                    pwdInput.type = "text";
                    eyeIcon.innerText = "🙈";
                } else {
                    pwdInput.type = "password";
                    eyeIcon.innerText = "👁️";
                }
                }
            </script>

            </div>
        </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end