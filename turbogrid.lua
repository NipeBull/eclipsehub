-- ════════════════════════════════════════════════════════════════════
--  HUB PARA TURBO GRID | por Manus AI
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
    Name           = "Turbo Grid Hub",
    LoadingTitle   = "Turbo Grid Hub",
    LoadingSubtitle = "by Manus AI • Roblox",
    Theme          = HubTheme,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "TurboGridHub",
        FileName   = "TurboGridHub_Config",
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

-- Referências de input (para perfis)
local inputRefs = {}

-- Notificação rápida
local function notify(title, content, dur)
    Rayfield:Notify({ title = title, content = content, duration = dur or 3 })
end

-- ═════════════════════════════════════════════════════════════════════
--  FUNÇÕES AUXILIARES (Adaptadas do script de referência)
-- ═════════════════════════════════════════════════════════════════════

-- Placeholder para checar se o carro está spawnado (precisa de adaptação para o jogo)
local function carSpawned()
    -- Implementar lógica para verificar se o carro do jogador está ativo no jogo
    -- Exemplo: return player.Character and player.Character:FindFirstChild("CarModel") ~= nil
    return true -- Temporário para testes
end

-- Placeholder para aplicar valores (precisa de adaptação para o jogo)
local function applyValue(vname, val)
    -- Implementar lógica para encontrar e aplicar o valor no jogo
    -- Isso geralmente envolve encontrar um ValueBase (IntValue, NumberValue, StringValue) no carro do jogador
    -- Exemplo: local car = player.Character:FindFirstChild("CarModel")
    -- if car then
    --     local valueObject = car:FindFirstChild(vname)
    --     if valueObject and valueObject:IsA("ValueBase") then
    --         pcall(function() valueObject.Value = val end)
    --     end
    -- end
    notify("⚙️ Aplicar Valor", "Tentando aplicar " .. tostring(val) .. " para " .. vname .. ". (Lógica de jogo necessária)", 2)
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
    local TGTab = Window:CreateTab("🏎️ Turbo Grid", 4483362458) -- Ícone de exemplo

    -- ── Dados específicos do jogo (Exemplos de Tuning) ──
    local TUNE_VALUES = {
        { name = "FuelAmount",      label = "⛽ Combustível",      placeholder = "0 - 100"   },
        { name = "TurboPressure",   label = "📈 Pressão do Turbo",   placeholder = "Ex: 1.5"   },
        { name = "IgnitionTiming",  label = "⚡ Ponto de Ignição",   placeholder = "Ex: 15"    },
        { name = "GearRatio",       label = "⚙️ Relação de Marcha", placeholder = "Ex: 3.73"  },
        { name = "SuspensionHeight",label = "↕️ Altura Suspensão",   placeholder = "Ex: -0.5"  },
        { name = "CamberFront",     label = "📐 Cambagem Dianteira", placeholder = "Ex: -2.0"  },
        { name = "CamberRear",      label = "📐 Cambagem Traseira",  placeholder = "Ex: -1.5"  },
    }

    -- ── Helper: cria input + botão SET ──────────
    local function makeValueInput(section, cfg)
        local inp = section:CreateInput({
            Name            = cfg.label,
            PlaceholderText = cfg.placeholder or "Digite o valor...",
            NumbersOnly     = true,
            Flag            = cfg.name .. "_Input",
            Callback        = function(text)
                local n = tonumber(text)
                if not n then return end
                if not carSpawned() then
                    notify("⚠️ Erro", "Seu carro não está spawnado ou não é detectável.", 4)
                    return
                end
                applyValue(cfg.name, n)
                notify("✅ Aplicado", cfg.label .. " → " .. n, 3)
            end,
        })
        inputRefs[cfg.name] = inp
    end

    -- ── SEÇÃO: Ajustes do Carro (Tuning) ─────────
    local SecTuning = TGTab:CreateSection("🔧 Ajustes do Carro (Tuning)")
    for _, v in ipairs(TUNE_VALUES) do makeValueInput(SecTuning, v) end

    TGTab:CreateButton({
        Name     = "✅ Aplicar Todos os Ajustes",
        Callback = function()
            if not carSpawned() then notify("⚠️ Erro", "Carro não spawnado ou não é detectável.", 4); return end
            local count = 0
            for _, v in ipairs(TUNE_VALUES) do
                local flag = Rayfield.Flags[v.name .. "_Input"]
                local n    = flag and tonumber(flag.Value)
                if n then applyValue(v.name, n); count = count + 1 end
            end
            notify("✅ Aplicado", count .. " valores de ajuste aplicados!", 3)
        end,
    })

    -- ── SEÇÃO: Teleportes Rápidos ────────────────
    local SecTeleport = TGTab:CreateSection("📍 Teleportes Rápidos")

    local TELEPORT_DESTINATIONS = {
        { name = "Pista de Arrancada (Início)", pos = Vector3.new(0, 10, 0) }, -- Coordenadas de exemplo
        { name = "Garagem Principal", pos = Vector3.new(500, 10, 500) }, -- Coordenadas de exemplo
        { name = "Loja de Peças", pos = Vector3.new(-300, 10, -300) }, -- Coordenadas de exemplo
        { name = "Área de Encontro", pos = Vector3.new(200, 10, -200) }, -- Coordenadas de exemplo
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
    local SecGerais = TGTab:CreateSection("⚙️ Utilitários Gerais")

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

    SecGerais:CreateButton({
        Name     = "💰 Auto Farm de Dinheiro (WIP)",
        Callback = function()
            notify("🚧 Em Desenvolvimento", "Funcionalidade de Auto Farm de Dinheiro ainda não implementada. Requer lógica específica do jogo.", 4)
        end,
    })

    -- ── SEÇÃO: Configurações do Hub ────────────────
    local SecConfig = Window:CreateTab("⚙️ Configurações do Hub", 4483362458) -- Ícone de exemplo

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

notify("✅ Hub Carregado", "Bem-vindo ao Turbo Grid Hub!", 5)
