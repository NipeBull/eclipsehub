-- ════════════════════════════════════════════════════════════════════
--  HUB PARA EXÉRCITO BRASILEIRO (EB) | por Manus AI
--  Baseado no Universal Hub de AbyssBorn / Karfi Team
--  UI: Rayfield (Sirius) — tema customizado leve
-- ════════════════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ─────────────────────────────────────────────────
--  TEMA — customizações leves sobre o padrão Rayfield
-- ─────────────────────────────────────────────────
local HubTheme = {
    TextColor                         = Color3.fromRGB(240, 240, 245),
    Background                        = Color3.fromRGB(14,  14,  18),
    Topbar                            = Color3.fromRGB(20,  20,  26),
    Shadow                            = Color3.fromRGB( 8,   8,  10),
    NotificationBackground            = Color3.fromRGB(22,  22,  30),
    NotificationActionsBackground     = Color3.fromRGB(32,  32,  44),
    TabBackground                     = Color3.fromRGB(18,  18,  24),
    TabStroke                         = Color3.fromRGB(50,  50,  75),
    TabTextColor                      = Color3.fromRGB(180, 180, 200),
    SelectedTabTextColor              = Color3.fromRGB(255, 255, 255),
    ElementBackground                 = Color3.fromRGB(26,  26,  36),
    ElementBackgroundHover            = Color3.fromRGB(34,  34,  48),
    SecondaryElementBackground        = Color3.fromRGB(20,  20,  28),
    ElementStroke                     = Color3.fromRGB(60,  60,  90),
    SecondaryElementStroke            = Color3.fromRGB(40,  40,  65),
    InputBackground                   = Color3.fromRGB(24,  24,  34),
    InputStroke                       = Color3.fromRGB(60,  60,  90),
    PlaceholderColor                  = Color3.fromRGB(110, 110, 150),
}

-- ─────────────────────────────────────────────────
--  JANELA PRINCIPAL
-- ─────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name           = "EB Apex Hard Hub",
    LoadingTitle   = "EB Apex Hard Hub",
    LoadingSubtitle = "by Manus AI • Exército Brasileiro",
    Theme          = HubTheme,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "EBApexHardHub",
        FileName   = "EBApexHardHub_Config",
    },
    KeySystem = false,
})

-- ═════════════════════════════════════════════════════════════════════
--  SERVIÇOS & VARIÁVEIS GLOBAIS
-- ═════════════════════════════════════════════════════════════════════
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local HttpSvc    = game:GetService("HttpService")

local player  = Players.LocalPlayer
local pGui    = player:WaitForChild("PlayerGui")

-- Estado global
local State = {
    anonActive    = false,
    anonConns     = {},
}

-- Notificação rápida
local function notify(title, content, dur)
    Rayfield:Notify({ title = title, content = content, duration = dur or 3 })
end

-- ═════════════════════════════════════════════════════════════════════
--  TELEPORTE SUAVE
-- ═════════════════════════════════════════════════════════════════════
local function doTeleport(pos, onDone)
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        notify("⚠️ Erro", "Personagem não encontrado.", 4)
        return
    end

    notify("📍 Teleportando", "Aguarde...", 2)

    task.spawn(function()
        local STEP     = 55
        local WAIT     = 0.05
        local PAUSE_N  = 15
        local PAUSE_T  = 0.12
        local steps    = 0

        while (hrp.Position - pos).Magnitude > STEP do
            local dir = (pos - hrp.Position).Unit
            hrp.CFrame = CFrame.new(hrp.Position + dir * STEP)
            steps = steps + 1
            task.wait(WAIT + (steps % PAUSE_N == 0 and PAUSE_T or 0))
        end
        hrp.CFrame = CFrame.new(pos) * (hrp.CFrame - hrp.CFrame.Position)
        notify("✅ Chegou!", "Teleporte concluído.", 3)
        if onDone then onDone() end
    end)
end

-- ═════════════════════════════════════════════════════════════════════
--  MODO ANÔNIMO
-- ═════════════════════════════════════════════════════════════════════
local function setAnonName(name)
    pcall(function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayName = name end
        end
    end)
end

local function enableAnon()
    if State.anonActive then return end
    State.anonActive = true
    local aName = "Anonymous"
    setAnonName(aName)
    State.anonConns[1] = player.CharacterAdded:Connect(function()
        task.wait(1)
        if State.anonActive then setAnonName(aName) end
    end)
    State.anonConns[2] = task.spawn(function()
        while State.anonActive do
            task.wait(2)
            if State.anonActive then setAnonName(aName) end
        end
    end)
    notify("🕵️ Modo Anônimo", "Ativado.", 3)
end

local function disableAnon()
    if not State.anonActive then return end
    State.anonActive = false
    for _, c in ipairs(State.anonConns) do
        pcall(function()
            if type(c) == "thread" then task.cancel(c) else c:Disconnect() end
        end)
    end
    State.anonConns = {}
    setAnonName(player.Name)
    notify("🕵️ Modo Anônimo", "Desativado.", 3)
end

-- ═════════════════════════════════════════════════════════════════════
--  CONSTRUÇÃO DAS ABAS
-- ═════════════════════════════════════════════════════════════════════

do
    local EBTab = Window:CreateTab("🇧🇷 Exército Brasileiro", 4483362458) -- Ícone de exemplo

    -- ── SEÇÃO: Teleportes ────────────────────────
    local SecTeleport = EBTab:CreateSection("📍 Teleportes Rápidos")

    local TELEPORT_DESTINATIONS = {
        { name = "Base Principal", pos = Vector3.new(0, 100, 0) }, -- Coordenadas de exemplo
        { name = "Área de Treinamento", pos = Vector3.new(500, 100, 500) }, -- Coordenadas de exemplo
        { name = "Parkour (Torre Apex)", pos = Vector3.new(366, 1087, -2052) }, -- Coordenadas da Torre Apex (Parkour Wiki)
        { name = "Estande de Tiro", pos = Vector3.new(-300, 100, -300) }, -- Coordenadas de exemplo
        { name = "Quartel", pos = Vector3.new(200, 100, -200) }, -- Coordenadas de exemplo
    }

    for _, dest in ipairs(TELEPORT_DESTINATIONS) do
        SecTeleport:CreateButton({
            Name     = dest.name,
            Callback = function()
                doTeleport(dest.pos)
            end,
        })
    end

    -- ── SEÇÃO: Utilitários Gerais ─────────────────
    local SecGerais = EBTab:CreateSection("⚙️ Utilitários Gerais")

    SecGerais:CreateToggle({
        Name     = "🕵️ Modo Anônimo",
        Flag     = "AnonModeToggle",
        Callback = function(state)
            if state then
                enableAnon()
            else
                disableAnon()
            end
        end,
    })

    -- ── SEÇÃO: Funções de Treinamento (Exemplos) ──
    local SecTreino = EBTab:CreateSection("🏋️ Funções de Treinamento")

    SecTreino:CreateButton({
        Name     = "🏃 Auto Parkour (WIP)",
        Callback = function()
            notify("🚧 Em Desenvolvimento", "Funcionalidade de Auto Parkour ainda não implementada. Requer lógica específica do jogo.", 4)
        end,
    })

    SecTreino:CreateButton({
        Name     = "🎯 Auto Treino de Tiro (WIP)",
        Callback = function()
            notify("🚧 Em Desenvolvimento", "Funcionalidade de Auto Treino de Tiro ainda não implementada. Requer lógica específica do jogo.", 4)
        end,
    })

    -- ── SEÇÃO: Funções de Patente/Missão (Exemplos) ──
    local SecPatente = EBTab:CreateSection("🎖️ Patentes e Missões")

    SecPatente:CreateButton({
        Name     = "⬆️ Auto Patente (WIP)",
        Callback = function()
            notify("🚧 Em Desenvolvimento", "Funcionalidade de Auto Patente ainda não implementada. Requer lógica específica do jogo.", 4)
        end,
    })

    SecPatente:CreateButton({
        Name     = "🗺️ Auto Missões (WIP)",
        Callback = function()
            notify("🚧 Em Desenvolvimento", "Funcionalidade de Auto Missões ainda não implementada. Requer lógica específica do jogo.", 4)
        end,
    })

    -- ── SEÇÃO: Configurações do Hub ────────────────
    local SecConfig = Window:CreateTab("⚙️ Configurações do Hub", 4483362458) -- Ícone de exemplo

    SecConfig:CreateToggle({
        Name     = "🔄 Reaplicar Valores (WIP)",
        Flag     = "AutoReapplyValues",
        Callback = function(state)
            -- Lógica para reaplicar valores (se aplicável ao EB)
            notify("🚧 Em Desenvolvimento", "A funcionalidade de reaplicar valores pode não ser relevante ou precisa de adaptação para o EB.", 4)
        end,
    })

    SecConfig:CreateButton({
        Name     = "💾 Salvar Configurações",
        Callback = function()
            Rayfield:SaveConfig()
            notify("✅ Salvo", "Configurações salvas com sucesso!", 3)
        end,
    })

    SecConfig:CreateButton({
        Name     = "📂 Carregar Configurações",
        Callback = function()
            Rayfield:LoadConfig()
            notify("✅ Carregado", "Configurações carregadas com sucesso!", 3)
        end,
    })

    SecConfig:CreateButton({
        Name     = "🗑️ Resetar Configurações",
        Callback = function()
            Rayfield:RemoveConfig()
            notify("✅ Resetado", "Configurações resetadas. Recarregue o script.", 3)
        end,
    })

end

notify("✅ Hub Carregado", "Bem-vindo ao EB Apex Hard Hub!", 5)
