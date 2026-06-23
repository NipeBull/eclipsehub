-- ════════════════════════════════════════════════════════════════════
--  ECLIPSE HUB | Powered By AbyssBorn
--  Versão aprimorada e modularizada
-- ════════════════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ─────────────────────────────────────────────────
--  TEMA E JANELA PRINCIPAL
-- ─────────────────────────────────────────────────
-- Um tema customizado dá um visual mais profissional ao seu hub.
local AppleTheme = {
    TextColor            = Color3.fromRGB(255, 255, 255),
    Background           = Color3.fromRGB(18,  18,  22),
    Topbar               = Color3.fromRGB(25,  25,  32),
    Shadow               = Color3.fromRGB(10,  10,  14),
    NotificationBackground = Color3.fromRGB(30, 30, 40),
    NotificationActionsBackground = Color3.fromRGB(40, 40, 55),
    TabBackground        = Color3.fromRGB(22,  22,  30),
    TabStroke            = Color3.fromRGB(60,  60,  90),
    TabTextColor         = Color3.fromRGB(200, 200, 215),
    SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
    ElementBackground    = Color3.fromRGB(30,  30,  42),
    ElementBackgroundHover = Color3.fromRGB(40, 40, 58),
    SecondaryElementBackground = Color3.fromRGB(24, 24, 34),
    ElementStroke        = Color3.fromRGB(70,  70, 110),
    SecondaryElementStroke = Color3.fromRGB(50, 50, 80),
    InputBackground      = Color3.fromRGB(28,  28,  40),
    InputStroke          = Color3.fromRGB(70,  70, 110),
    PlaceholderColor     = Color3.fromRGB(120, 120, 160),
}

local Window = Rayfield:CreateWindow({
    Name = "Eclipse Hub",
    LoadingTitle = "Eclipse Hub",
    LoadingSubtitle = "by AbyssBorn • Mecânica Brasileira",
    Theme = AppleTheme,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EclipseHub",
        FileName = "EclipseHub_Settings"
    }
})

-- ─────────────────────────────────────────────────
--  SERVIÇOS E VARIÁVEIS GLOBAIS
-- ─────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player     = Players.LocalPlayer
local pGui       = player:WaitForChild("PlayerGui")

-- FILESYSTEM SHIM (para compatibilidade com diferentes executores)
local function _getfs(name, fallback)
    local ok, fn = pcall(function() return rawget(_G, name) end)
    if ok and type(fn) == "function" then return fn end
    return fallback
end

local _writefile  = _getfs("writefile",  function() end)
local _readfile   = _getfs("readfile",   function() return nil end)
local _makefolder = _getfs("makefolder", function() end)
local _isfile     = _getfs("isfile",     function() return false end)

-- ESTADO GLOBAL (para controlar as funções)
local AF = {
    imaAtivo              = false,
    imaLoopConnection     = nil,
    minhasCaixas          = {},
    colisoesOriginais     = {},
    autoReapply           = false,
    deliveryFarmAtivo     = false,
    deliveryFarmCoroutine = nil,
    anonActive            = false,
    anonConns             = {},
}

-- Referência global para os inputs, acessível pelo sistema de perfis
inputRefs = {}

-- ─────────────────────────────────────────────────
--  DADOS DO JOGO
-- ─────────────────────────────────────────────────
VALUES = {
    { name = "FuelLiters",      label = "⛽  Litros de Gasolina"   },
    { name = "WaterPercentage", label = "💧  Fluido de Radiador"    },
    { name = "OilPercentage",   label = "🛢  Porcentagem de Óleo"   },
    { name = "FinalDrive",      label = "⚙️  Transmissão Final"     },
}
TUNE_VALUES = {
    { name = "Turbos",       label = "🌀  Turbos"           },
    { name = "TurboPressure",label = "📈  Pressão do Turbo" },
    { name = "TurboSize",    label = "📐  Tamanho do Turbo" },
    { name = "TurboLag",     label = "⏱  Turbo Lag"        },
    { name = "PartDamage",   label = "🔧  Consertar Motor (0=ok)" },
}
MISC_VALUES = {
    { name = "RCamb",                 label = "🔩  Cambagem Traseira"  },
    { name = "FCamb",                 label = "🔩  Cambagem Frontal"   },
    { name = "IgnitionTime",          label = "⚡  Avanço de Ignição"  },
    { name = "AerodynamicEfficiency", label = "🌬  Aerodinâmica"       },
}
local TELEPORT_DESTINATIONS = {
    { name = "Entrega",               pos = Vector3.new(-25672,  35, -5895) },
    { name = "Construção City 2",     pos = Vector3.new(-25220,  65, -5295) },
    { name = "Comet Auto Peças",      pos = Vector3.new( -3328,  65, -3407) },
    { name = "Concessionária",        pos = Vector3.new( -3042,  65, -3692) },
    { name = "Construção Mectropoly", pos = Vector3.new( -3642,  65, -2506) },
    { name = "Junkyard / Ferro Velho",pos = Vector3.new( -3125,  65, -4254) },
    { name = "Garagem",               pos = Vector3.new( -3375,  65, -2815) },
    { name = "Posto Mectropoly",      pos = Vector3.new( -3223,  65, -3713) },
    { name = "Valley Drag Race",      pos = Vector3.new( -3856,  65, -4901) },
}
local DELIVERY_COORDS = {
    ["Caminhão"]              = Vector3.new(-25672,  35, -5895),
    ["Construção"]            = Vector3.new(-25220,  65, -5295),
    ["Comet Auto Peças"]      = Vector3.new( -3328,  65, -3407),
    ["Concessionaria"]        = Vector3.new( -3042,  65, -3692),
    ["Construção Mectropoly"] = Vector3.new( -3642,  65, -2506),
    ["Ferro Velho"]           = Vector3.new( -3125,  65, -4254),
    ["Garagem 4"]             = Vector3.new( -3375,  65, -2815),
    ["Posto Mectropoly"]      = Vector3.new( -3223,  65, -3713),
    ["Valley Drag Race"]      = Vector3.new( -3856,  65, -4901),
}
local PICKUP_POS = Vector3.new(-25679, 32, -5879)

-- ─────────────────────────────────────────────────
--  SISTEMA DE CACHE (Melhora a performance)
-- ─────────────────────────────────────────────────
local _valueCache = {}
local _transpBoxCache = {}

local function _cacheAdd(obj)
    if obj:IsA("ValueBase") then
        local n = obj.Name
        if not _valueCache[n] then _valueCache[n] = {} end
        table.insert(_valueCache[n], obj)
    elseif obj:IsA("BasePart") and obj.Name == "TranspBox" then
        table.insert(_transpBoxCache, obj)
    end
end

local function _cacheRemove(obj)
    if obj:IsA("ValueBase") then
        local n = obj.Name
        if _valueCache[n] then
            for i, v in ipairs(_valueCache[n]) do
                if v == obj then table.remove(_valueCache[n], i); return end
            end
        end
    elseif obj:IsA("BasePart") and obj.Name == "TranspBox" then
        for i, v in ipairs(_transpBoxCache) do
            if v == obj then table.remove(_transpBoxCache, i); return end
        end
    end
end

task.spawn(function()
    for _, obj in ipairs(game:GetDescendants()) do _cacheAdd(obj) end
end)
game.DescendantAdded:Connect(_cacheAdd)
game.DescendantRemoving:Connect(_cacheRemove)

-- ─────────────────────────────────────────────────
--  FUNÇÕES DE APLICAÇÃO DE VALOR (LÓGICA FALTANTE)
-- ─────────────────────────────────────────────────
local _vconn = {}

local function _isOwned(obj)
    local ownerVal = obj:FindFirstChild("Owner")
        or (obj.Parent and obj.Parent:FindFirstChild("Owner"))
        or (obj.Parent and obj.Parent.Parent and obj.Parent.Parent:FindFirstChild("Owner"))
    if not ownerVal then return true end
    if ownerVal:IsA("ObjectValue") then
        return ownerVal.Value == player
            or (ownerVal.Value and ownerVal.Value.Name == player.Name)
    elseif ownerVal:IsA("StringValue") then
        return ownerVal.Value == player.Name
    end
    return false
end

local function applyValue(vname, val)
    if _vconn[vname] then
        pcall(function() _vconn[vname]:Disconnect() end)
        _vconn[vname] = nil
    end
    local list = _valueCache[vname]
    if list then
        for _, obj in ipairs(list) do pcall(function() obj.Value = val end) end
    end
    if AF.autoReapply then
        _vconn[vname] = game.DescendantAdded:Connect(function(obj)
            if obj:IsA("ValueBase") and obj.Name == vname then
                task.defer(pcall, function() obj.Value = val end)
            end
        end)
    end
end

local function applyTireValue(tireName, val)
    local list = _valueCache[tireName]
    if list and #list > 0 then
        for _, obj in ipairs(list) do
            if _isOwned(obj) then pcall(function() obj.Value = val end) end
        end
    else
        local conn
        conn = game.DescendantAdded:Connect(function(obj)
            if obj:IsA("ValueBase") and obj.Name == tireName and _isOwned(obj) then
                pcall(function() obj.Value = val end)
                pcall(function() conn:Disconnect() end)
            end
        end)
        task.delay(5, function() pcall(function() conn:Disconnect() end) end)
    end
end

local function carSpawned()
    local owners = _valueCache["Owner"]
    if not owners then return false end
    for _, obj in ipairs(owners) do
        if obj and obj.Parent and obj.Value then
            local name = (type(obj.Value) == "userdata" and obj.Value.Name) or tostring(obj.Value)
            if name == player.Name then return true end
        end
    end
    return false
end

-- ─────────────────────────────────────────────────
--  LÓGICA DO IMÃ DE CAIXAS
-- ─────────────────────────────────────────────────
local function encontrarMinhasCaixas()
    local caixas = {}
    for _, obj in ipairs(_transpBoxCache) do
        if obj and obj.Parent then
            local owner = obj:FindFirstChild("Owner")
            if owner and owner:IsA("ObjectValue") and owner.Value and owner.Value.Name == player.Name then
                table.insert(caixas, obj)
            end
        end
    end
    return caixas
end
local function pararIma()
    if not AF.imaAtivo then return end
    AF.imaAtivo = false
    if AF.imaLoopConnection then AF.imaLoopConnection:Disconnect(); AF.imaLoopConnection = nil end
    for _, box in ipairs(AF.minhasCaixas) do
        if box and box.Parent then
            box.Anchored = false
            box.CanCollide = AF.colisoesOriginais[box] or true
        end
    end
    AF.minhasCaixas = {}
    AF.colisoesOriginais = {}
    Rayfield:Notify({ title = "🔗 Imã", content = "Desativado.", duration = 3 })
end
local function iniciarIma()
    if AF.imaAtivo then return true end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Rayfield:Notify({ title = "⚠️ Erro", content = "Personagem não encontrado.", duration = 4 })
        return false
    end
    AF.minhasCaixas = encontrarMinhasCaixas()
    if #AF.minhasCaixas == 0 then
        Rayfield:Notify({ title = "🔗 Imã", content = "Nenhuma caixa encontrada.", duration = 4 })
        return false
    end

    AF.imaAtivo = true
    for _, box in ipairs(AF.minhasCaixas) do
        if box and box.Parent then
            AF.colisoesOriginais[box] = box.CanCollide
            box.CanCollide = false
            box.Anchored = true
        end
    end
    Rayfield:Notify({
        title   = "🔗 Imã Ativado",
        content = "Puxando " .. #AF.minhasCaixas .. " caixa(s).",
        duration = 4,
    })
    AF.imaLoopConnection = RunService.Heartbeat:Connect(function()
        local c    = player.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        if root then
            for _, box in ipairs(AF.minhasCaixas) do
                if box and box.Parent then
                    box.CFrame = box.CFrame:Lerp(root.CFrame, 0.2)
                end
            end
        end
    end)
    return true
end

-- ─────────────────────────────────────────────────
--  TELEPORTE SUAVE (Evita detecção e bugs)
-- ─────────────────────────────────────────────────
local function doTeleport(pos)
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Rayfield:Notify({ title = "⚠️ Erro", content = "Personagem não encontrado.", duration = 4 })
        return
    end

    Rayfield:Notify({ title = "📍 Teleportando", content = "Aguarde...", duration = 2 })

    task.spawn(function()
        local STEP_SIZE   = 55
        local STEP_WAIT   = 0.05
        local PAUSE_EVERY = 15
        local PAUSE_TIME  = 0.12
        local stepCount   = 0

        while (hrp.Position - pos).Magnitude > STEP_SIZE do
            local dir = (pos - hrp.Position).Unit
            hrp.CFrame = CFrame.new(hrp.Position + dir * STEP_SIZE)
            stepCount  = stepCount + 1
            task.wait(STEP_WAIT + (stepCount % PAUSE_EVERY == 0 and PAUSE_TIME or 0))
        end
        hrp.CFrame = CFrame.new(pos) * (hrp.CFrame - hrp.CFrame.Position)
        Rayfield:Notify({ title = "✅ Teleporte", content = "Você chegou!", duration = 3 })
    end)
end

-- ─────────────────────────────────────────────────
--  SISTEMA DE PERFIS (NOVO)
-- ─────────────────────────────────────────────────
local PROFILE_FOLDER = "EclipseHub"
local PROFILE_INDEX  = PROFILE_FOLDER .. "/profiles_index.txt"

local function ensureFolder()
    pcall(function() _makefolder(PROFILE_FOLDER) end)
end

local function readIndex()
    ensureFolder()
    local ok, data = pcall(_readfile, PROFILE_INDEX)
    if not (ok and data and data ~= "") then return {} end
    local list = {}
    for name in data:gmatch("[^\n]+") do
        if name ~= "" then table.insert(list, name) end
    end
    return list
end

local function writeIndex(list)
    ensureFolder()
    pcall(_writefile, PROFILE_INDEX, table.concat(list, "\n"))
end

local function saveProfile(name)
    if not name or name == "" then return false end
    ensureFolder()

    local data = {}
    for _, v in ipairs(VALUES or {}) do
        local ref = inputRefs and inputRefs[v.name]
        if ref then data[v.name] = ref.Value end
    end
    for _, v in ipairs(TUNE_VALUES or {}) do
        local ref = inputRefs and inputRefs[v.name]
        if ref then data[v.name] = ref.Value end
    end
    for _, v in ipairs(MISC_VALUES or {}) do
        local ref = inputRefs and inputRefs[v.name]
        if ref then data[v.name] = ref.Value end
    end

    local json = HttpService:JSONEncode(data)
    local ok = pcall(_writefile, PROFILE_FOLDER .. "/" .. name .. ".json", json)
    if not ok then return false end

    local list = readIndex()
    local found = false
    for _, n in ipairs(list) do
        if n == name then found = true; break end
    end
    if not found then
        table.insert(list, name)
        writeIndex(list)
    end
    return true
end

local function loadProfile(name)
    if not name or name == "" then return false end
    local path = PROFILE_FOLDER .. "/" .. name .. ".json"
    local ok, data = pcall(_readfile, path)
    if not (ok and data and data ~= "") then return false end

    local parsed
    local jok = pcall(function()
        parsed = HttpService:JSONDecode(data)
    end)
    if not (jok and parsed) then return false end

    for k, v in pairs(parsed) do
        local n = tonumber(v)
        if n and inputRefs and inputRefs[k] then
            pcall(function() inputRefs[k]:Set(tostring(n)) end)
            applyValue(k, n)
        end
    end
    return true
end

local function deleteProfile(name)
    if not name or name == "" then return end
    pcall(function()
        local path = PROFILE_FOLDER .. "/" .. name .. ".json"
        if _isfile(path) then
            local delfile = _getfs("delfile", function() end)
            delfile(path)
        end
    end)
    local list = readIndex()
    for i, n in ipairs(list) do
        if n == name then table.remove(list, i); break end
    end
    writeIndex(list)
end

-- ==================== CONSTRUÇÃO DA UI ====================

-- Abas separadas para melhor organização
local MiscTab   = Window:CreateTab("⚗️  Misc", 4483362458)
local TuneTab   = Window:CreateTab("🔧  Tune", 4483362458)
local FarmTab   = Window:CreateTab("🤖  Auto Farm", 4483362458)
local TpTab     = Window:CreateTab("📍  Teleportes", 4483362458)
local ConfigTab = Window:CreateTab("⚙️  Configs", 4483362458)

-- Helper para criar inputs de valor
local function createValueRow(tab, cfg)
    local input = tab:CreateInput({
        Name            = cfg.label,
        PlaceholderText = cfg.placeholder or "Digite o valor...",
        NumbersOnly     = true,
        Callback        = function(text)
            local n = tonumber(text)
            if not n then return end
            if not carSpawned() then
                Rayfield:Notify({ title = "⚠️ Erro", content = "Seu carro não está spawnado.", duration = 4 })
                return
            end
            applyValue(cfg.name, n)
            Rayfield:Notify({
                title   = "✅ Aplicado",
                content = cfg.label .. " → " .. n,
                duration = 3,
            })
        end,
    })
    inputRefs[cfg.name] = input
end

-- === ABA MISC ===
local MiscSection  = MiscTab:CreateSection("Líquidos & Gerais")
for _, v in ipairs(VALUES) do createValueRow(MiscSection, v) end

local MiscSection2 = MiscTab:CreateSection("Cambagem & Aerodinâmica")
for _, v in ipairs(MISC_VALUES) do createValueRow(MiscSection2, v) end

-- === ABA TUNE ===
local TuneSection = TuneTab:CreateSection("Turbo & Motor")
for _, v in ipairs(TUNE_VALUES) do createValueRow(TuneSection, v) end

local TireSection = TuneTab:CreateSection("Pneus")
TireSection:CreateButton({
    Name     = "🏁  Semi-Slick",
    Callback = function()
        applyTireValue("Ftire", 1); applyTireValue("Rtire", 1)
        Rayfield:Notify({ title = "🏁 Pneus", content = "Semi-Slick aplicado.", duration = 3 })
    end
})
TireSection:CreateButton({
    Name     = "🔵  Smooth",
    Callback = function()
        applyTireValue("Ftire", 2); applyTireValue("Rtire", 2)
        Rayfield:Notify({ title = "🔵 Pneus", content = "Smooth aplicado.", duration = 3 })
    end
})
TireSection:CreateButton({
    Name     = "🔴  Drag",
    Callback = function()
        applyTireValue("Ftire", 3); applyTireValue("Rtire", 3)
        Rayfield:Notify({ title = "🔴 Pneus", content = "Drag aplicado.", duration = 3 })
    end
})

-- === ABA AUTO FARM ===
local ImaSection = FarmTab:CreateSection("🔗 Imã de Caixas")

local imaToggle = ImaSection:CreateToggle({
    Name         = "Ativar Imã de Caixas",
    CurrentValue = false,
    Flag         = "ToggleMagnet",
    Callback     = function(state)
        if state then
            if not iniciarIma() then
                imaToggle:Set(false)
            end
        else
            pararIma()
        end
    end,
})

ImaSection:CreateKeybind({
    Name       = "Atalho do Imã",
    CurrentKey = Enum.KeyCode.H,
    Callback   = function()
        imaToggle:Set(not Rayfield.Flags["ToggleMagnet"].Value)
    end,
})

local DeliverySection = FarmTab:CreateSection("🚚 Auto Entrega")

local deliveryToggle
deliveryToggle = DeliverySection:CreateToggle({
    Name         = "Iniciar Auto Entrega (Em Breve)",
    CurrentValue = false,
    Flag         = "ToggleDelivery",
    Callback     = function(state)
        -- A lógica do auto delivery será adicionada aqui no futuro
        Rayfield:Notify({ title = "🚚 Auto Entrega", content = state and "Ativado (Função em desenvolvimento)" or "Desativado", duration = 4 })
        if state then
            -- Para não ficar ativo sem função
            task.wait(0.1)
            deliveryToggle:Set(false)
        end
    end,
})

player.CharacterAdded:Connect(function()
    if AF.deliveryFarmAtivo then deliveryToggle:Set(false) end
    if AF.imaAtivo then pararIma() end
end)

-- === ABA TELEPORTES ===
local TpSection = TpTab:CreateSection("Locais Principais")
for _, dest in ipairs(TELEPORT_DESTINATIONS) do
    TpSection:CreateButton({
        Name = "→ " .. dest.name,
        Callback = function() doTeleport(dest.pos) end,
    })
end

-- === ABA CONFIGURAÇÕES ===
local GeneralConfig = ConfigTab:CreateSection("Geral")

GeneralConfig:CreateToggle({
    Name         = "Auto-Reaplicar Valores",
    CurrentValue = AF.autoReapply,
    Flag         = "AutoReapply",
    Callback     = function(state)
        AF.autoReapply = state
        Rayfield:Notify({
            title   = "⚙️ Config",
            content = "Auto-Reaplicar " .. (state and "ativado." or "desativado."),
            duration = 3,
        })
    end,
})

-- Modo Anônimo (Exemplo de nova funcionalidade)
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
    if AF.anonActive then return end
    AF.anonActive = true
    local anonName = "Anonymous"

    setAnonName(anonName)
    AF.anonConns[1] = player.CharacterAdded:Connect(function()
        task.wait(1)
        if AF.anonActive then setAnonName(anonName) end
    end)
    AF.anonConns[2] = task.spawn(function()
        while AF.anonActive do
            task.wait(2)
            if AF.anonActive then setAnonName(anonName) end
        end
    end)
    Rayfield:Notify({ title = "🕵️ Modo Anônimo", content = "Ativado.", duration = 3 })
end

local function disableAnon()
    if not AF.anonActive then return end
    AF.anonActive = false
    for _, c in ipairs(AF.anonConns) do
        pcall(function()
            if type(c) == "thread" then task.cancel(c) else c:Disconnect() end
        end)
    end
    AF.anonConns = {}
    setAnonName(player.Name)
    Rayfield:Notify({ title = "🕵️ Modo Anônimo", content = "Desativado.", duration = 3 })
end

GeneralConfig:CreateToggle({
    Name         = "Modo Anônimo",
    CurrentValue = AF.anonActive,
    Flag         = "AnonymousMode",
    Callback     = function(state)
        if state then enableAnon() else disableAnon() end
    end,
})

-- Sistema de Perfis na UI
local ProfileSection = ConfigTab:CreateSection("Perfis de Configuração")

local profileNameInput = ProfileSection:CreateInput({
    Name            = "Nome do Perfil",
    PlaceholderText = "Ex: corrida, drift...",
    Flag            = "ProfileNameInput",
    Callback        = function() end,
})

local profileDropdown

local function refreshProfileList()
    local list = readIndex()
    if profileDropdown then
        profileDropdown:Refresh(list, nil)
    end
end

profileDropdown = ProfileSection:CreateDropdown({
    Name     = "Perfis Salvos",
    Values   = readIndex(),
    Flag     = "ProfileDropdown",
    Callback = function(selected)
        if loadProfile(selected) then
            profileNameInput:Set(selected)
            Rayfield:Notify({ title = "📂 Perfil", content = "'" .. selected .. "' carregado!", duration = 3 })
        else
            Rayfield:Notify({ title = "⚠️ Erro", content = "Falha ao carregar '" .. selected .. "'.", duration = 4 })
        end
    end,
})

ProfileSection:CreateButton({
    Name     = "💾  Salvar Perfil",
    Callback = function()
        local name = Rayfield.Flags["ProfileNameInput"] and Rayfield.Flags["ProfileNameInput"].Value or ""
        if name and name ~= "" then
            if saveProfile(name) then
                Rayfield:Notify({ title = "💾 Perfil", content = "'" .. name .. "' salvo!", duration = 3 })
                refreshProfileList()
            else
                Rayfield:Notify({ title = "⚠️ Erro", content = "Falha ao salvar o perfil.", duration = 4 })
            end
        else
            Rayfield:Notify({ title = "⚠️ Aviso", content = "Digite um nome para o perfil.", duration = 3 })
        end
    end,
})

ProfileSection:CreateButton({
    Name     = "🗑  Excluir Perfil",
    Callback = function()
        local name = Rayfield.Flags["ProfileNameInput"] and Rayfield.Flags["ProfileNameInput"].Value or ""
        if name and name ~= "" then
            deleteProfile(name)
            Rayfield:Notify({ title = "🗑 Perfil", content = "'" .. name .. "' excluído.", duration = 3 })
            profileNameInput:Set("")
            refreshProfileList()
        else
            Rayfield:Notify({ title = "⚠️ Aviso", content = "Digite ou selecione um perfil.", duration = 3 })
        end
    end,
})

-- ==================== INICIALIZAÇÃO ====================
task.wait(1)
refreshProfileList()
Rayfield:LoadConfiguration()

print("🌑 Eclipse Hub | Mecânica Brasileira | Carregado com sucesso!")
