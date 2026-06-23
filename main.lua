-- ════════════════════════════════════════════════════════════════════
--  ATLAS HUB LOADER | por Manus AI
--  Carrega scripts de jogos dinamicamente via GitHub Raw.
--  UI: Rayfield (Sirius) — tema customizado leve
-- ════════════════════════════════════════════════════════════════════

-- Carrega a biblioteca Rayfield UI
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
    Name           = "Atlas Hub",
    LoadingTitle   = "Atlas Hub",
    LoadingSubtitle = "by Manus AI • Multi-Game",
    Theme          = HubTheme,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "AtlasHub",
        FileName   = "AtlasHub_Config",
    },
    KeySystem = false,
})

-- ═════════════════════════════════════════════════════════════════════
--  SERVIÇOS & VARIÁVEIS GLOBAIS (Compartilhadas com os scripts de jogos)
-- ═════════════════════════════════════════════════════════════════════
_G.Rayfield = Rayfield -- Torna Rayfield acessível globalmente
_G.player = game:GetService("Players").LocalPlayer
_G.notify = function(title, content, dur)
    Rayfield:Notify({ title = title, content = content, duration = dur or 3 })
end

_G.State = {
    anonActive    = false,
    anonConns     = {},
}

_G.doTeleport = function(pos, onDone)
    local char = _G.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        _G.notify("⚠️ Erro", "Personagem não encontrado.", 4)
        return
    end

    _G.notify("📍 Teleportando", "Aguarde...", 2)

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
        _G.notify("✅ Chegou!", "Teleporte concluído.", 3)
        if onDone then onDone() end
    end)
end

_G.setAnonName = function(name)
    pcall(function()
        local char = _G.player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayName = name end
        end
    end)
end

_G.enableAnon = function()
    if _G.State.anonActive then return end
    _G.State.anonActive = true
    local aName = "Anonymous"
    _G.setAnonName(aName)
    _G.State.anonConns[1] = _G.player.CharacterAdded:Connect(function()
        task.wait(1)
        if _G.State.anonActive then _G.setAnonName(aName) end
    end)
    _G.State.anonConns[2] = task.spawn(function()
        while _G.State.anonActive do
            task.wait(2)
            if _G.State.anonActive then _G.setAnonName(aName) end
        end
    end)
    _G.notify("🕵️ Modo Anônimo", "Ativado.", 3)
end

_G.disableAnon = function()
    if not _G.State.anonActive then return end
    _G.State.anonActive = false
    for _, c in ipairs(_G.State.anonConns) do
        pcall(function()
            if type(c) == "thread" then task.cancel(c) else c:Disconnect() end
        end)
    end
    _G.State.anonConns = {}
    _G.setAnonName(_G.player.Name)
    _G.notify("🕵️ Modo Anônimo", "Desativado.", 3)
end

-- ═════════════════════════════════════════════════════════════════════
--  CONFIGURAÇÃO DE JOGOS E URLS DO GITHUB RAW
--  Você deve fazer upload dos scripts eb_game_script.lua e turbo_grid_game_script.lua
--  para o seu próprio repositório GitHub e substituir as URLs abaixo.
-- ═════════════════════════════════════════════════════════════════════
local GAME_SCRIPTS = {
    -- Exemplo para o Exército Brasileiro (EB)
    "https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/eb_game_script.lua",

    -- Exemplo para o Turbo Grid
    "https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/turbo_grid_game_script.lua",

    -- Adicione mais URLs de scripts de jogos aqui conforme necessário
    -- Exemplo:
    "https://raw.githubusercontent.com/NipeBull/eclipsehub/refs/heads/main/karfihub.lua",
}

-- ═════════════════════════════════════════════════════════════════════
--  CARREGADOR DE SCRIPTS
-- ═════════════════════════════════════════════════════════════════════
local HttpService = game:GetService("HttpService")

for _, scriptUrl in ipairs(GAME_SCRIPTS) do
    local success, scriptContent = pcall(function()
        return HttpService:GetAsync(scriptUrl)
    end)

    if success and scriptContent then
        local loadSuccess, errorMessage = pcall(function()
            loadstring(scriptContent)()
        end)
        if not loadSuccess then
            _G.notify("⚠️ Erro ao Carregar Script", "Falha ao executar script de: " .. scriptUrl .. "\nErro: " .. errorMessage, 8)
        else
            _G.notify("✅ Script Carregado", "Script carregado com sucesso de: " .. scriptUrl, 3)
        end
    else
        _G.notify("⚠️ Erro ao Baixar Script", "Falha ao baixar script de: " .. scriptUrl, 8)
    end
end

-- ═════════════════════════════════════════════════════════════════════
--  ABA DE CONFIGURAÇÕES GLOBAIS DO HUB
-- ═════════════════════════════════════════════════════════════════════
local SecConfig = Window:CreateTab("⚙️ Configurações do Hub", 4483362458) -- Ícone de exemplo

SecConfig:CreateButton({
    Name     = "💾 Salvar Configurações",
    Callback = function()
        Rayfield:SaveConfig()
        _G.notify("✅ Salvo", "Configurações salvas com sucesso!", 3)
    end,
})

SecConfig:CreateButton({
    Name     = "📂 Carregar Configurações",
    Callback = function()
        Rayfield:LoadConfig()
        _G.notify("✅ Carregado", "Configurações carregadas com sucesso!", 3)
    end,
})

SecConfig:CreateButton({
    Name     = "🗑️ Resetar Configurações",
    Callback = function()
        Rayfield:RemoveConfig()
        _G.notify("✅ Resetado", "Configurações resetadas. Recarregue o script.", 3)
    end,
})

_G.notify("✅ Atlas Hub Carregado", "Bem-vindo ao Atlas Hub!", 5)
