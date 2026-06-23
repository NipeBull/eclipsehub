-- ════════════════════════════════════════════════════════════════════
--  KARFI HUB  v4.0  —  LocalScript  [RAYFIELD EDITION]
--  GUI manual removida e substituída por Rayfield.
--  Toda a lógica de jogo permanece 100% intacta.
-- ════════════════════════════════════════════════════════════════════
-- ════════════════════════════════════════════════════════════════════
--  KARFI HUB — KEY SYSTEM  (JnKie SDK + DB externa)
-- ════════════════════════════════════════════════════════════════════
--
--  CONFIGURAÇÃO  ← edite APENAS este bloco
-- ────────────────────────────────────────────────────────────────────
local KS_CONFIG = {
    -- ► Coloque aqui o NOME DO SERVIÇO exato do painel JnKie
    service    = "KarfiHub",

    -- ► Coloque aqui o IDENTIFIER (número do serviço no painel JnKie)
    identifier = "35760",

    -- ► Provider padrão configurado no painel ("Key", "Mixed", etc.)
    provider   = "Key",

    -- ► Link que aparece no botão "Obter Key" (Discord, loja, etc.)
    getKeyURL  = "https://discord.gg/bRKJx7EjYa",

    -- ► Máximo de tentativas erradas antes de encerrar
    maxAttempts = 5,

    -- ► Arquivo local onde a key válida é salva (evita pedir de novo)
    saveFile   = "karfi_key.txt",
}
-- ════════════════════════════════════════════════════════════════════
--  FIM DA CONFIGURAÇÃO — não edite abaixo desta linha
-- ════════════════════════════════════════════════════════════════════

-- ── Filesystem helpers (usados pelo key system) ──────────────────────
local function _getfs_ks(name, fallback)
    local ok, fn = pcall(function() return rawget(_G, name) end)
    if ok and type(fn) == "function" then return fn end
    return fallback
end
local _writefile_ks  = _getfs_ks("writefile",  function() end)
local _readfile_ks   = _getfs_ks("readfile",   function() return nil end)
local _isfile_ks     = _getfs_ks("isfile",     function() return false end)

-- ── Carrega SDK do JnKie ─────────────────────────────────────────────
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service    = KS_CONFIG.service
Junkie.identifier = KS_CONFIG.identifier
Junkie.provider   = KS_CONFIG.provider

-- ── GUI de Key (Rayfield-style, nativa) ──────────────────────────────
local TweenService_ks = game:GetService("TweenService")
local Players_ks      = game:GetService("Players")
local UIS_ks          = game:GetService("UserInputService")
local player_ks       = Players_ks.LocalPlayer
local pGui_ks         = player_ks:WaitForChild("PlayerGui")

local function buildKeyGUI()
    -- Remove GUI antiga se existir
    local old = pGui_ks:FindFirstChild("KarfiKeyGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name            = "KarfiKeyGui"
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.Parent          = pGui_ks

    -- Fundo escuro
    local bg = Instance.new("Frame")
    bg.Size            = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    bg.BackgroundTransparency = 0.1
    bg.BorderSizePixel = 0
    bg.Parent          = sg

    -- Painel central
    local panel = Instance.new("Frame")
    panel.Size             = UDim2.fromOffset(440, 280)
    panel.Position         = UDim2.new(0.5, -220, 0.5, -140)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
    panel.BorderSizePixel  = 0
    panel.Parent           = bg
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

    -- Borda colorida top
    local accent = Instance.new("Frame")
    accent.Size             = UDim2.new(1, 0, 0, 3)
    accent.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    accent.BorderSizePixel  = 0
    accent.Parent           = panel
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 12)

    -- Título
    local title = Instance.new("TextLabel")
    title.Size              = UDim2.new(1, -40, 0, 36)
    title.Position          = UDim2.fromOffset(20, 18)
    title.BackgroundTransparency = 1
    title.Text              = "KARFI HUB  v4.0"
    title.TextColor3        = Color3.fromRGB(255, 255, 255)
    title.TextSize          = 20
    title.Font              = Enum.Font.GothamBold
    title.TextXAlignment    = Enum.TextXAlignment.Left
    title.Parent            = panel

    -- Subtítulo
    local sub = Instance.new("TextLabel")
    sub.Size              = UDim2.new(1, -40, 0, 20)
    sub.Position          = UDim2.fromOffset(20, 52)
    sub.BackgroundTransparency = 1
    sub.Text              = "Insira sua key de acesso para continuar"
    sub.TextColor3        = Color3.fromRGB(160, 160, 180)
    sub.TextSize          = 13
    sub.Font              = Enum.Font.Gotham
    sub.TextXAlignment    = Enum.TextXAlignment.Left
    sub.Parent            = panel

    -- Label status / erro
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size              = UDim2.new(1, -40, 0, 18)
    statusLbl.Position          = UDim2.fromOffset(20, 76)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text              = ""
    statusLbl.TextColor3        = Color3.fromRGB(240, 80, 80)
    statusLbl.TextSize          = 12
    statusLbl.Font              = Enum.Font.Gotham
    statusLbl.TextXAlignment    = Enum.TextXAlignment.Left
    statusLbl.Parent            = panel

    -- Campo de input
    local inputBg = Instance.new("Frame")
    inputBg.Size             = UDim2.new(1, -40, 0, 44)
    inputBg.Position         = UDim2.fromOffset(20, 108)
    inputBg.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    inputBg.BorderSizePixel  = 0
    inputBg.Parent           = panel
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 8)

    local inputBox = Instance.new("TextBox")
    inputBox.Size              = UDim2.new(1, -20, 1, 0)
    inputBox.Position          = UDim2.fromOffset(10, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Text              = ""
    inputBox.PlaceholderText   = "Cole sua key aqui..."
    inputBox.TextColor3        = Color3.fromRGB(230, 230, 255)
    inputBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 110)
    inputBox.TextSize          = 14
    inputBox.Font              = Enum.Font.GothamMono
    inputBox.ClearTextOnFocus  = false
    inputBox.Parent            = inputBg

    -- Botão Validar
    local btnValidar = Instance.new("TextButton")
    btnValidar.Size             = UDim2.new(0.55, -5, 0, 44)
    btnValidar.Position         = UDim2.fromOffset(20, 170)
    btnValidar.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    btnValidar.Text             = "Validar Key"
    btnValidar.TextColor3       = Color3.fromRGB(255, 255, 255)
    btnValidar.TextSize         = 14
    btnValidar.Font             = Enum.Font.GothamBold
    btnValidar.BorderSizePixel  = 0
    btnValidar.AutoButtonColor  = false
    btnValidar.Parent           = panel
    Instance.new("UICorner", btnValidar).CornerRadius = UDim.new(0, 8)

    -- Botão Obter Key
    local btnGetKey = Instance.new("TextButton")
    btnGetKey.Size             = UDim2.new(0.45, -15, 0, 44)
    btnGetKey.Position         = UDim2.new(0.55, 0, 0, 170)
    btnGetKey.BackgroundColor3 = Color3.fromRGB(32, 34, 48)
    btnGetKey.Text             = "Obter Key"
    btnGetKey.TextColor3       = Color3.fromRGB(99, 102, 241)
    btnGetKey.TextSize         = 14
    btnGetKey.Font             = Enum.Font.GothamBold
    btnGetKey.BorderSizePixel  = 0
    btnGetKey.AutoButtonColor  = false
    btnGetKey.Parent           = panel
    Instance.new("UICorner", btnGetKey).CornerRadius = UDim.new(0, 8)

    -- Contador de tentativas
    local attemptsLbl = Instance.new("TextLabel")
    attemptsLbl.Size              = UDim2.new(1, -40, 0, 16)
    attemptsLbl.Position          = UDim2.fromOffset(20, 228)
    attemptsLbl.BackgroundTransparency = 1
    attemptsLbl.Text              = ""
    attemptsLbl.TextColor3        = Color3.fromRGB(100, 100, 120)
    attemptsLbl.TextSize          = 11
    attemptsLbl.Font              = Enum.Font.Gotham
    attemptsLbl.TextXAlignment    = Enum.TextXAlignment.Left
    attemptsLbl.Parent            = panel

    -- Rodapé
    local footer = Instance.new("TextLabel")
    footer.Size              = UDim2.new(1, -40, 0, 16)
    footer.Position          = UDim2.fromOffset(20, 250)
    footer.BackgroundTransparency = 1
    footer.Text              = "Powered by JnKie Key System  •  DB externa"
    footer.TextColor3        = Color3.fromRGB(55, 55, 70)
    footer.TextSize          = 10
    footer.Font              = Enum.Font.Gotham
    footer.TextXAlignment    = Enum.TextXAlignment.Left
    footer.Parent            = panel

    return sg, inputBox, btnValidar, btnGetKey, statusLbl, attemptsLbl
end

-- ── Lógica de validação ───────────────────────────────────────────────
local function runKeySystem()
    -- Tenta carregar key salva localmente
    local savedKey = nil
    pcall(function()
        if _isfile_ks(KS_CONFIG.saveFile) then
            savedKey = _readfile_ks(KS_CONFIG.saveFile)
            if savedKey then savedKey = savedKey:match("^%s*(.-)%s*$") end
            if savedKey == "" then savedKey = nil end
        end
    end)

    if savedKey then
        -- Valida a key salva na DB do JnKie
        local ok, result = pcall(function()
            return Junkie.check_key(savedKey)
        end)
        if ok and result and result.valid then
            -- Key salva ainda válida → pula a GUI
            getgenv().SCRIPT_KEY = savedKey
            -- Expõe runtime variables do JnKie
            if result.is_premium ~= nil then
                getgenv().JD_IS_PREMIUM = result.is_premium
            end
            return true
        else
            -- Key salva inválida/expirada → apaga e pede de novo
            pcall(function() _writefile_ks(KS_CONFIG.saveFile, "") end)
        end
    end

    -- Constrói a GUI de key
    local gui, inputBox, btnValidar, btnGetKey, statusLbl, attemptsLbl =
        buildKeyGUI()

    local attempts   = 0
    local validated  = false
    local validating = false

    local function setStatus(msg, isOk)
        statusLbl.Text       = msg
        statusLbl.TextColor3 = isOk
            and Color3.fromRGB(80, 220, 120)
            or  Color3.fromRGB(240, 80, 80)
    end

    local function tweenBtn(btn, col)
        TweenService_ks:Create(btn,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad),
            { BackgroundColor3 = col }
        ):Play()
    end

    -- Hover effects
    btnValidar.MouseEnter:Connect(function()
        if not validating then
            tweenBtn(btnValidar, Color3.fromRGB(120, 122, 255))
        end
    end)
    btnValidar.MouseLeave:Connect(function()
        if not validating then
            tweenBtn(btnValidar, Color3.fromRGB(99, 102, 241))
        end
    end)
    btnGetKey.MouseEnter:Connect(function()
        tweenBtn(btnGetKey, Color3.fromRGB(40, 44, 65))
    end)
    btnGetKey.MouseLeave:Connect(function()
        tweenBtn(btnGetKey, Color3.fromRGB(32, 34, 48))
    end)

    -- Botão "Obter Key": pega link do JnKie e copia para clipboard
    btnGetKey.MouseButton1Click:Connect(function()
        local ok, link = pcall(function()
            return Junkie.get_key_link()
        end)
        if ok and link then
            pcall(function() setclipboard(link) end)
            setStatus("Link copiado! Cole no navegador.", true)
        else
            -- Fallback: abre o link configurado manualmente
            pcall(function() setclipboard(KS_CONFIG.getKeyURL) end)
            setStatus("Link do Discord copiado!", true)
        end
    end)

    -- Botão "Validar Key"
    btnValidar.MouseButton1Click:Connect(function()
        if validating or validated then return end

        local key = inputBox.Text:match("^%s*(.-)%s*$")
        if not key or #key < 3 then
            setStatus("Digite uma key válida.", false)
            return
        end

        validating = true
        btnValidar.Text = "Verificando..."
        tweenBtn(btnValidar, Color3.fromRGB(70, 72, 180))

        -- Chama a API do JnKie (DB externa)
        local ok, result = pcall(function()
            return Junkie.check_key(key)
        end)

        attempts = attempts + 1
        attemptsLbl.Text = string.format(
            "Tentativas: %d / %d", attempts, KS_CONFIG.maxAttempts
        )

        if ok and result and result.valid then
            -- ✅ Key válida
            validated = true
            setStatus("✓ Key válida! Carregando o hub...", true)
            btnValidar.Text = "✓ Validado!"
            tweenBtn(btnValidar, Color3.fromRGB(50, 200, 100))

            -- Salva localmente para não pedir de novo
            pcall(function() _writefile_ks(KS_CONFIG.saveFile, key) end)

            -- Expõe para o resto do script
            getgenv().SCRIPT_KEY = key
            if result.is_premium ~= nil then
                getgenv().JD_IS_PREMIUM = result.is_premium
            end

            task.wait(1.2)
            gui:Destroy()
        else
            -- ❌ Key inválida
            validating = false
            btnValidar.Text = "Validar Key"
            tweenBtn(btnValidar, Color3.fromRGB(99, 102, 241))

            local errMsg = "Key inválida."
            if ok and result then
                local m = result.message or result.error or ""
                if m == "KEY_EXPIRED" then
                    errMsg = "Key expirada. Renove sua assinatura."
                elseif m == "HWID_MISMATCH" then
                    errMsg = "HWID diferente. Contate o suporte."
                elseif m == "HWID_BANNED" then
                    errMsg = "Seu HWID está banido."
                    task.wait(1)
                    player_ks:Kick("[Karfi Hub] HWID banido.")
                    return
                elseif m == "SERVICE_MISMATCH" then
                    errMsg = "Key de outro serviço."
                elseif m ~= "" then
                    errMsg = "Erro: " .. m:sub(1, 50)
                end
            end
            setStatus(errMsg, false)

            if attempts >= KS_CONFIG.maxAttempts then
                setStatus("Muitas tentativas. Encerrando...", false)
                task.wait(2)
                player_ks:Kick("[Karfi Hub] Tentativas de key esgotadas.")
                return
            end
        end
    end)

    -- Aguarda validação (bloqueia o script aqui)
    while not validated do
        task.wait(0.1)
    end

    return true
end

-- ── Executa o key system AGORA (bloqueia até validar) ────────────────
do
    local ok, err = pcall(runKeySystem)
    if not ok then
        warn("[Karfi Hub] Erro no Key System: " .. tostring(err))
        -- Se o JnKie falhar completamente, encerra o script por segurança
        game:GetService("Players").LocalPlayer:Kick(
            "[Karfi Hub] Erro ao conectar ao servidor de keys. Tente novamente."
        )
        return
    end
end

-- ─────────────────────────────────────────────────
--  SERVIÇOS
-- ─────────────────────────────────────────────────

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player       = Players.LocalPlayer
local pGui         = player:WaitForChild("PlayerGui")


-- ─────────────────────────────────────────────────
-- ─────────────────────────────────────────────────
--  FILESYSTEM SHIM  (reutiliza helpers do key system)
-- ─────────────────────────────────────────────────

local _writefile  = _writefile_ks
local _readfile   = _readfile_ks
local _makefolder = _getfs_ks("makefolder", function() end)
local _delfile    = _getfs_ks("delfile",    function() end)


-- ─────────────────────────────────────────────────
--  ESTADO GLOBAL — AUTO FARM (Imã)
-- ─────────────────────────────────────────────────

local AF = {
    imaAtivo          = false,
    imaLoopConnection = nil,
    minhasCaixas      = {},
    colisoesOriginais = {},
    imaGrudadas       = false,
    togllekey         = Enum.KeyCode.RightShift,
    waitingBind       = false,
    guiOpen           = true,
    activeTab         = "Misc",
    statusEnabled     = true,
    autoReapply       = false,
}


-- ─────────────────────────────────────────────────
--  DADOS — VALORES DO VEÍCULO
-- ─────────────────────────────────────────────────

local TIRE_VALUES = {
    front = "Ftire",
    rear  = "Rtire",
}

local VALUES = {
    { name = "FuelLiters",        label = "Litros de Gasolina"  },
    { name = "WaterPercentage",   label = "Fluido de Radiador"  },
    { name = "OilPercentage",     label = "Porcentagem de Oleo" },
    { name = "FinalDrive",        label = "Transmissao Final"   },
}

local TUNE_VALUES = {
    { name = "Turbos",       label = "Turbos"          },
    { name = "TurboPressure",label = "Pressao do Turbo"},
    { name = "TurboSize",    label = "Tamanho do Turbo"},
    { name = "TurboLag",     label = "Turbo Lag"       },
    { name = "PartDamage",   label = "Consertar Motor",
      min = 0, max = 100, placeholder = "0 a 100"      },
}

local MISC_VALUES = {
    { name = "RCamb",                 label = "Cambagem traseira" },
    { name = "FCamb",                 label = "Cambagem frontal"  },
    { name = "IgnitionTime",          label = "Avanco de Ignicao" },
    { name = "AerodynamicEfficiency", label = "Aerodinamica"      },
}


-- ─────────────────────────────────────────────────
--  DADOS — DESTINOS DE TELEPORTE
-- ─────────────────────────────────────────────────

local TELEPORT_DESTINATIONS = {
    { label = "Entrega",               pos = Vector3.new(-25672, 35, -5895) },
    { label = "Construcao city 2",     pos = Vector3.new(-25220, 65, -5295) },
    { label = "Comet Auto Pecas",      pos = Vector3.new( -3328, 65, -3407) },
    { label = "Concessionaria",        pos = Vector3.new( -3042, 65, -3692) },
    { label = "Construcao Mectropoly", pos = Vector3.new( -3642, 65, -2506) },
    { label = "Junkyard/Ferro Velho",  pos = Vector3.new( -3125, 65, -4254) },
    { label = "Garagem",               pos = Vector3.new( -3375, 65, -2815) },
    { label = "Posto Mectropoly",      pos = Vector3.new( -3223, 65, -3713) },
    { label = "Valley Drag Race",      pos = Vector3.new( -3856, 65, -4901) },
}

local DELIVERY_COORDS = {
    ["Caminhao"]              = Vector3.new(-25672, 35, -5895),
    ["Construcao"]            = Vector3.new(-25220, 65, -5295),
    ["Comet Auto Pecas"]      = Vector3.new( -3328, 65, -3407),
    ["Concessionaria"]        = Vector3.new( -3042, 65, -3692),
    ["Construcao Mectropoly"] = Vector3.new( -3642, 65, -2506),
    ["Ferro Velho"]           = Vector3.new( -3125, 65, -4254),
    ["Garagem 4"]             = Vector3.new( -3375, 65, -2815),
    ["Posto Mectropoly"]      = Vector3.new( -3223, 65, -3713),
    ["Valley Drag Race"]      = Vector3.new( -3856, 65, -4901),
}

local PICKUP_POS = Vector3.new(-25679, 32, -5879)


-- ════════════════════════════════════════════════════════════════════
--  CACHE DE VALUES
-- ════════════════════════════════════════════════════════════════════

local _valueCache = {}

local function _cacheAdd(obj)
    if not obj:IsA("ValueBase") then return end
    local n = obj.Name
    if not _valueCache[n] then _valueCache[n] = {} end
    for _, v in ipairs(_valueCache[n]) do
        if v == obj then return end
    end
    table.insert(_valueCache[n], obj)
end

local function _cacheRemove(obj)
    if not obj:IsA("ValueBase") then return end
    local n = obj.Name
    if not _valueCache[n] then return end
    for i, v in ipairs(_valueCache[n]) do
        if v == obj then
            table.remove(_valueCache[n], i)
            return
        end
    end
end

task.spawn(function()
    local all = game:GetDescendants()
    local i   = 1
    while i <= #all do
        local batch = math.min(i + 199, #all)
        for j = i, batch do
            if all[j]:IsA("ValueBase") then _cacheAdd(all[j]) end
        end
        i = batch + 1
        task.wait()
    end
end)

game.DescendantAdded:Connect(_cacheAdd)
game.DescendantRemoving:Connect(_cacheRemove)


-- ─────────────────────────────────────────────────
--  HELPER — verifica se objeto pertence ao player
-- ─────────────────────────────────────────────────

local function _isOwned(obj)
    local ownerVal =
        obj:FindFirstChild("Owner")
        or (obj.Parent and obj.Parent:FindFirstChild("Owner"))
        or (obj.Parent and obj.Parent.Parent
            and obj.Parent.Parent:FindFirstChild("Owner"))
        or (obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Parent
            and obj.Parent.Parent.Parent:FindFirstChild("Owner"))

    if not ownerVal then return true end

    if ownerVal:IsA("ObjectValue") then
        return ownerVal.Value == player
            or (ownerVal.Value ~= nil and ownerVal.Value.Name == player.Name)
    elseif ownerVal:IsA("StringValue") then
        return ownerVal.Value == player.Name
    end

    return false
end


-- ─────────────────────────────────────────────────
--  APLICAR VALOR
-- ─────────────────────────────────────────────────

local _lastApplied = {}
local _vconn       = {}

local function applyValue(vname, val)
    _lastApplied[vname] = val

    if _vconn[vname] then
        pcall(function() _vconn[vname]:Disconnect() end)
        _vconn[vname] = nil
    end

    local list = _valueCache[vname]
    if list then
        for _, obj in ipairs(list) do
            pcall(function() obj.Value = val end)
        end
    end

    if AF.autoReapply then
        _vconn[vname] = game.DescendantAdded:Connect(function(obj)
            if obj:IsA("ValueBase") and obj.Name == vname then
                task.defer(function() pcall(function() obj.Value = val end) end)
            end
        end)
    end
end


-- ─────────────────────────────────────────────────
--  APLICAR VALOR DE PNEU
-- ─────────────────────────────────────────────────

local function applyTireValue(tireName, val)
    local list = _valueCache[tireName]

    if list and #list > 0 then
        for _, obj in ipairs(list) do
            if _isOwned(obj) then
                pcall(function() obj.Value = val end)
            end
        end
    else
        local conn
        conn = game.DescendantAdded:Connect(function(obj)
            if obj:IsA("ValueBase") and obj.Name == tireName then
                if _isOwned(obj) then
                    pcall(function() obj.Value = val end)
                end
                conn:Disconnect()
            end
        end)
        task.delay(5, function()
            pcall(function() conn:Disconnect() end)
        end)
    end
end


-- ─────────────────────────────────────────────────
--  HELPER — carro spawnado
-- ─────────────────────────────────────────────────

local function carSpawned()
    local owners = _valueCache["Owner"]
    if not owners then return false end
    for _, obj in ipairs(owners) do
        if obj and obj.Parent then
            local v = obj.Value
            if v then
                local name = (type(v) == "userdata" and v.Name) or tostring(v)
                if name == player.Name then return true end
            end
        end
    end
    return false
end


-- ═══════════════════════════════════════════════════════════════════
--  RAYFIELD LOADER
-- ═══════════════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

local Window = Rayfield:CreateWindow({
    Name             = "KARFI HUB  v4",
    Icon             = 0,
    LoadingTitle     = "KARFI HUB",
    LoadingSubtitle  = "Carregando...",
    Theme            = "Default",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,

    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "KarfiHub",
        FileName   = "KarfiConfig",
    },

    Discord = {
        Enabled    = false,
    },

    -- KeySystem desativado no Rayfield: a validação é feita
    -- pelo JnKie Key System no bloco acima (DB externa, keys pagas).
    KeySystem = false,
})


-- ─────────────────────────────────────────────────
--  NOTIFICAÇÃO HELPER
-- ─────────────────────────────────────────────────

local function notify(title, content, duration, icon)
    Rayfield:Notify({
        Title    = title or "Karfi Hub",
        Content  = content or "",
        Duration = duration or 3,
        Image    = icon or 4483362458,
    })
end


-- ═══════════════════════════════════════════════════════════════════
--  ABA: MISC  (Config Extras + Config Gerais)
-- ═══════════════════════════════════════════════════════════════════

local TabMisc = Window:CreateTab("Misc", 4483362458)

-- ── Seção: Config Extras ─────────────────────────

TabMisc:CreateSection("Config Extras — Liquidos e Combustivel")

for _, v in ipairs(VALUES) do
    local cfg = v
    TabMisc:CreateInput({
        Name        = cfg.label,
        PlaceholderText = cfg.placeholder or "valor...",
        RemoveTextAfterFocusLost = false,
        Callback    = function(Value)
            local n = tonumber(Value)
            if not n then
                notify("Erro", "Valor invalido: " .. cfg.label, 3)
                return
            end
            if not carSpawned() then
                notify("Erro", "Seu carro nao esta spawnado!", 3)
                return
            end
            applyValue(cfg.name, n)
            notify("OK", cfg.label .. " -> " .. n, 2)
        end,
    })
end

TabMisc:CreateButton({
    Name     = "Aplicar Todos (Config Extras)",
    Callback = function()
        if not carSpawned() then
            notify("Erro", "Seu carro nao esta spawnado!", 3)
            return
        end
        -- lê os valores dos inputs via _lastApplied (aplicados individualmente)
        local count = 0
        for _, v in ipairs(VALUES) do
            local val = _lastApplied[v.name]
            if val then applyValue(v.name, val); count = count + 1 end
        end
        notify("OK", count .. " valores aplicados!", 2)
    end,
})

-- ── Seção: Config Gerais ─────────────────────────

TabMisc:CreateSection("Config Gerais — Cambagem, Ignicao e Aerodinamica")

for _, v in ipairs(MISC_VALUES) do
    local cfg = v
    TabMisc:CreateInput({
        Name        = cfg.label,
        PlaceholderText = "valor...",
        RemoveTextAfterFocusLost = false,
        Callback    = function(Value)
            local n = tonumber(Value)
            if not n then
                notify("Erro", "Valor invalido: " .. cfg.label, 3)
                return
            end
            if not carSpawned() then
                notify("Erro", "Seu carro nao esta spawnado!", 3)
                return
            end
            applyValue(cfg.name, n)
            notify("OK", cfg.label .. " -> " .. n, 2)
        end,
    })
end

TabMisc:CreateButton({
    Name     = "Aplicar Todos (Config Gerais)",
    Callback = function()
        if not carSpawned() then
            notify("Erro", "Seu carro nao esta spawnado!", 3)
            return
        end
        local count = 0
        for _, v in ipairs(MISC_VALUES) do
            local val = _lastApplied[v.name]
            if val then applyValue(v.name, val); count = count + 1 end
        end
        notify("OK", count .. " valores aplicados!", 2)
    end,
})


-- ═══════════════════════════════════════════════════════════════════
--  ABA: TUNE  (Turbo & Pneus)
-- ═══════════════════════════════════════════════════════════════════

local TabTune = Window:CreateTab("Tune", 4483362458)

TabTune:CreateSection("Turbo & Tune")

for _, v in ipairs(TUNE_VALUES) do
    local cfg = v
    TabTune:CreateInput({
        Name        = cfg.label,
        PlaceholderText = cfg.placeholder or "valor...",
        RemoveTextAfterFocusLost = false,
        Callback    = function(Value)
            local n = tonumber(Value)
            if not n then
                notify("Erro", "Valor invalido: " .. cfg.label, 3)
                return
            end
            if cfg.min ~= nil and n < cfg.min then n = cfg.min end
            if cfg.max ~= nil and n > cfg.max then n = cfg.max end
            if not carSpawned() then
                notify("Erro", "Seu carro nao esta spawnado!", 3)
                return
            end
            applyValue(cfg.name, n)
            notify("OK", cfg.label .. " -> " .. n, 2)
        end,
    })
end

TabTune:CreateButton({
    Name     = "Aplicar Todos (Tune)",
    Callback = function()
        if not carSpawned() then
            notify("Erro", "Seu carro nao esta spawnado!", 3)
            return
        end
        local count = 0
        for _, v in ipairs(TUNE_VALUES) do
            local val = _lastApplied[v.name]
            if val then applyValue(v.name, val); count = count + 1 end
        end
        notify("OK", count .. " valores aplicados!", 2)
    end,
})

-- ── Seção: Pneus ─────────────────────────────────

TabTune:CreateSection("Tipo de Pneu  —  Slick | Smooth | Drag")

local TIRE_TYPES = {
    { name = "Semi-Slick", val = 1 },
    { name = "Smooth",     val = 2 },
    { name = "Drag",       val = 3 },
}

for _, t in ipairs(TIRE_TYPES) do
    local tt = t
    TabTune:CreateButton({
        Name     = tt.name,
        Callback = function()
            if not carSpawned() then
                notify("Erro", "Seu carro nao esta spawnado!", 3)
                return
            end
            applyTireValue(TIRE_VALUES.front, tt.val)
            applyTireValue(TIRE_VALUES.rear,  tt.val)
            notify("OK", "Pneu " .. tt.name .. " aplicado (Ftire & Rtire = " .. tt.val .. ")", 2)
        end,
    })
end


-- ═══════════════════════════════════════════════════════════════════
--  ABA: AUTO FARM
-- ═══════════════════════════════════════════════════════════════════

local TabAF = Window:CreateTab("AutoFarm", 4483362458)

-- ── Cache TranspBox ──────────────────────────────

local _transpBoxCache = {}

local function _transpCacheAdd(obj)
    if not (obj:IsA("BasePart") and obj.Name == "TranspBox") then return end
    for _, v in ipairs(_transpBoxCache) do if v == obj then return end end
    table.insert(_transpBoxCache, obj)
end

local function _transpCacheRemove(obj)
    if not (obj:IsA("BasePart") and obj.Name == "TranspBox") then return end
    for i, v in ipairs(_transpBoxCache) do
        if v == obj then table.remove(_transpBoxCache, i); return end
    end
end

task.defer(function()
    for _, obj in ipairs(workspace:GetDescendants()) do _transpCacheAdd(obj) end
end)

workspace.DescendantAdded:Connect(_transpCacheAdd)
workspace.DescendantRemoving:Connect(_transpCacheRemove)

local function encontrarMinhasCaixas()
    local caixas = {}
    for _, obj in ipairs(_transpBoxCache) do
        if obj and obj.Parent then
            local ownerObj = obj:FindFirstChild("Owner")
            if ownerObj and ownerObj:IsA("ObjectValue") then
                if ownerObj.Value and ownerObj.Value.Name == player.Name then
                    table.insert(caixas, obj)
                end
            end
        end
    end
    return caixas
end

-- ── Ima toggle references (mantidos para Delivery Farm) ──

local afStatus  = { Text = "Desativado" }
local afKnob    = nil
local afTrack   = nil
local afAccent  = nil

local function pararIma()
    if not AF.imaAtivo then return end
    AF.imaAtivo    = false
    AF.imaGrudadas = false

    if AF.imaLoopConnection then
        AF.imaLoopConnection:Disconnect()
        AF.imaLoopConnection = nil
    end

    for _, box in ipairs(AF.minhasCaixas) do
        if box and box.Parent then
            box.Anchored   = false
            pcall(function() box.CanCollide = AF.colisoesOriginais[box] or true end)
        end
    end

    AF.colisoesOriginais = {}
    AF.minhasCaixas      = {}
    afStatus.Text        = "Ima desativado"
end

local function iniciarIma()
    if AF.imaAtivo then return end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        notify("Erro", "Personagem nao encontrado", 3)
        return
    end

    AF.minhasCaixas = encontrarMinhasCaixas()
    if #AF.minhasCaixas == 0 then
        notify("Erro", "Nenhuma TranspBox encontrada! Spawne as caixas primeiro.", 3)
        afStatus.Text = "Nenhuma TranspBox encontrada!"
        return
    end

    AF.imaAtivo    = true
    AF.imaGrudadas = false

    for _, box in ipairs(AF.minhasCaixas) do
        if box and box.Parent then
            AF.colisoesOriginais[box] = box.CanCollide
            box.CanCollide = false
            box.Anchored   = true
        end
    end

    afStatus.Text = string.format("Puxando %d caixa(s)...", #AF.minhasCaixas)
    notify("Ima Ativado", string.format("%d caixa(s) sendo puxadas", #AF.minhasCaixas), 2)

    local velocidade = 0.12
    AF.imaLoopConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            local c    = player.Character
            local hrp2 = c and c:FindFirstChild("HumanoidRootPart")
            if not hrp2 then return end

            local alvo          = hrp2.CFrame
            local todasGrudadas = true

            for _, box in ipairs(AF.minhasCaixas) do
                if box and box.Parent then
                    local dist = (alvo.Position - box.Position).Magnitude
                    if dist > 0.05 then
                        todasGrudadas = false
                        box.CFrame    = box.CFrame:Lerp(alvo, velocidade)
                    else
                        box.CFrame = alvo
                    end
                    box.CFrame = box.CFrame:Lerp(hrp2.CFrame, 0.2)
                end
            end

            if todasGrudadas and not AF.imaGrudadas then
                AF.imaGrudadas = true
                afStatus.Text  = string.format("%d caixa(s) grudada(s)!", #AF.minhasCaixas)
            end

            if AF.imaGrudadas then
                for _, box in ipairs(AF.minhasCaixas) do
                    if box and box.Parent then box.CFrame = alvo end
                end
            end
        end)
    end)
end

local function toggleIma()
    if AF.imaAtivo then
        pararIma()
    else
        iniciarIma()
    end
end

-- ── Seção: Imã de Caixas ─────────────────────────

TabAF:CreateSection("Ima de Caixas — Puxa suas caixas automaticamente")

TabAF:CreateToggle({
    Name         = "Ima de Caixas  (Tecla H)",
    CurrentValue = false,
    Flag         = "ImaToggle",
    Callback     = function(Value)
        if Value then
            iniciarIma()
        else
            pararIma()
        end
    end,
})

-- ── Seção: Delivery Farm ─────────────────────────

TabAF:CreateSection("Auto Entrega — Delivery Farm")

-- Variáveis do Delivery Farm
local deliveryFarmAtivo  = false
local deliveryFarmThread = nil

local function caixasEntregues()
    for _, obj in ipairs(_transpBoxCache) do
        if obj and obj.Parent then
            local ownerObj = obj:FindFirstChild("Owner")
            if ownerObj and ownerObj:IsA("ObjectValue") then
                if ownerObj.Value and ownerObj.Value.Name == player.Name then
                    return false
                end
            end
        end
    end
    return true
end

local function resolveDestino(destText)
    if not destText then return nil end
    for name, pos in pairs(DELIVERY_COORDS) do
        if name == destText then return pos, name end
    end
    local lower = destText:lower()
    for name, pos in pairs(DELIVERY_COORDS) do
        if lower:find(name:lower(), 1, true)
           or name:lower():find(lower, 1, true)
        then
            return pos, name
        end
    end
    return nil, nil
end

local function getTransportGui()
    local tGui = pGui:FindFirstChild("TransportJobGui")
    if not tGui then return nil end
    local main = tGui:FindFirstChild("MainGUI")
    if not main then return nil end
    main.Visible = true
    return main
end

local function parsePay(txt)
    if not txt then return 0 end
    local n = 0
    for num in txt:gmatch("%d+%.?%d*") do
        local v = tonumber(num) or 0
        if v > n then n = v end
    end
    return n
end

local _hiddenJobFrames = {}

local function _findDesc(parent, name)
    for _, c in ipairs(parent:GetDescendants()) do
        if c.Name == name then return c end
    end
    return nil
end

local function melhorJob(mainGui)
    local container     = mainGui:FindFirstChild("Container")
    if not container then return nil end
    local mainContainer = container:FindFirstChild("MainContainer")
    if not mainContainer then return nil end
    local jobsList      = mainContainer:FindFirstChild("Jobs")
    if not jobsList then return nil end

    local allJobs   = {}
    local melhor    = nil
    local melhorPay = -1

    for _, jobFrame in ipairs(jobsList:GetChildren()) do
        if jobFrame:IsA("Frame") then
            local payObj   = _findDesc(jobFrame, "Pay")
            local destObj  = _findDesc(jobFrame, "Destination")
            local startObj = _findDesc(jobFrame, "Start")
            if payObj and destObj and startObj then
                local payVal = parsePay(payObj.Text)
                local entry  = {
                    frame       = jobFrame,
                    payVal      = payVal,
                    destination = destObj.Text,
                    startBtn    = startObj,
                }
                table.insert(allJobs, entry)
                if payVal > melhorPay then
                    melhorPay = payVal
                    melhor    = entry
                end
            end
        end
    end

    if melhor then
        _hiddenJobFrames = {}
        for _, job in ipairs(allJobs) do
            if job.frame ~= melhor.frame then
                pcall(function() job.frame.Visible = false end)
                table.insert(_hiddenJobFrames, job.frame)
            end
        end
        pcall(function() melhor.frame.LayoutOrder = -999 end)
        pcall(function()
            if jobsList:IsA("ScrollingFrame") then
                jobsList.CanvasPosition = Vector2.new(0, 0)
            end
        end)
    end

    return melhor
end

local function restaurarJobFrames()
    for _, frame in ipairs(_hiddenJobFrames) do
        pcall(function() frame.Visible = true end)
    end
    _hiddenJobFrames = {}
end

local function slowWalk(destino)
    local STEP_SIZE   = 55
    local STEP_WAIT   = 0.05
    local PAUSE_EVERY = 15
    local PAUSE_TIME  = 0.12
    local stepCount   = 0

    while deliveryFarmAtivo do
        local ok2 = pcall(function()
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.5) return end

            local cur  = hrp.Position
            local diff = destino - cur
            local dist = diff.Magnitude

            if dist <= STEP_SIZE then
                hrp.CFrame = CFrame.new(destino) * (hrp.CFrame - hrp.CFrame.Position)
            end

            if (hrp.Position - destino).Magnitude > STEP_SIZE then
                local nextPos = cur + diff.Unit * STEP_SIZE
                hrp.CFrame    = CFrame.new(nextPos) * (hrp.CFrame - hrp.CFrame.Position)
                stepCount     = stepCount + 1
                if stepCount % PAUSE_EVERY == 0 then
                    task.wait(STEP_WAIT + PAUSE_TIME)
                else
                    task.wait(STEP_WAIT)
                end
            else
                task.wait(STEP_WAIT)
            end
        end)

        local char2 = player.Character
        local hrp2  = char2 and char2:FindFirstChild("HumanoidRootPart")
        if hrp2 and (hrp2.Position - destino).Magnitude <= STEP_SIZE then break end
        if not ok2 then task.wait(0.2) end
    end
end

local function getActiveJobDestination(mainGui)
    local dest = nil
    pcall(function()
        local searches = { "ActiveJob","CurrentJob","RunningJob","JobActive","Active" }
        for _, name in ipairs(searches) do
            local panel = mainGui:FindFirstChild(name, true)
            if panel then
                local d = panel:FindFirstChild("Destination", true)
                if d and d.Text and d.Text ~= "" then dest = d.Text; return end
            end
        end
        for _, c in ipairs(mainGui:GetDescendants()) do
            if c.Name == "Destination" and c:IsA("TextLabel") and c.Text ~= "" then
                local inJobsList = false
                local p = c.Parent
                while p and p ~= mainGui do
                    if p.Name == "Jobs" then inJobsList = true; break end
                    p = p.Parent
                end
                if not inJobsList then dest = c.Text; return end
            end
        end
    end)
    return dest
end

local function deliveryFarmLoop()

    local function clickBtn(btn)
        local ok = false
        if not ok then pcall(function() firesignal(btn.MouseButton1Click); ok = true end) end
        if not ok then pcall(function() firebutton(btn, "MouseButton1Click"); ok = true end) end
        if not ok then
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                local ap  = btn.AbsolutePosition
                local as_ = btn.AbsoluteSize
                vim:SendMouseButtonEvent(ap.X + as_.X*.5, ap.Y + as_.Y*.5, 0, true,  game, 0)
                task.wait(0.06)
                vim:SendMouseButtonEvent(ap.X + as_.X*.5, ap.Y + as_.Y*.5, 0, false, game, 0)
                ok = true
            end)
        end
        if not ok then
            pcall(function()
                btn.MouseButton1Down:Fire(0, 0)
                task.wait(0.06)
                btn.MouseButton1Up:Fire(0, 0)
                btn.MouseButton1Click:Fire()
                ok = true
            end)
        end
        return ok
    end

    local function imaOn()
        if not AF.imaAtivo then iniciarIma() end
    end

    local function imaOff()
        if AF.imaAtivo then pararIma() end
    end

    local ciclo = 0
    while deliveryFarmAtivo do
        ciclo = ciclo + 1
        notify("Delivery Farm", "Ciclo #" .. ciclo .. " — indo ao ponto de coleta", 2)
        slowWalk(PICKUP_POS)
        if not deliveryFarmAtivo then break end

        task.wait(0.8)
        local mainGui = getTransportGui()
        if mainGui then
            pcall(function()
                for _, obj in ipairs(mainGui:GetDescendants()) do
                    if obj:IsA("ScrollingFrame") then
                        obj.CanvasPosition = Vector2.new(0, 0)
                    end
                end
            end)
        end

        if not mainGui then
            notify("Aviso", "GUI de entrega nao encontrada!", 3)
            task.wait(3)
        else
            for i = 3, 1, -1 do
                task.wait(1)
                if not deliveryFarmAtivo then break end
            end
            if not deliveryFarmAtivo then break end

            local job = melhorJob(mainGui)
            if not job then
                restaurarJobFrames()
                mainGui.Visible = false
                task.wait(5)
            else
                local destPos, destNome = resolveDestino(job.destination)
                if not destPos then
                    restaurarJobFrames()
                    mainGui.Visible = false
                    task.wait(3)
                else
                    notify("Entrega", "Melhor: R$" .. job.payVal .. " -> " .. destNome, 2)
                    task.wait(0.4)
                    clickBtn(job.startBtn)
                    task.wait(0.4)
                    clickBtn(job.startBtn)

                    local confirmed = false
                    for w = 1, 20 do
                        if not deliveryFarmAtivo then break end
                        task.wait(1)
                        if not caixasEntregues() then confirmed = true; break end
                        if w % 4 == 0 then clickBtn(job.startBtn) end
                    end

                    if not confirmed and deliveryFarmAtivo then
                        notify("Aviso", "Clique START manualmente!", 4)
                        for w = 1, 45 do
                            if not deliveryFarmAtivo then break end
                            task.wait(1)
                            if not caixasEntregues() then confirmed = true; break end
                        end
                    end

                    if confirmed then restaurarJobFrames() end

                    local actualDest = getActiveJobDestination(mainGui)
                    if actualDest and actualDest ~= "" then
                        local newPos, newNome = resolveDestino(actualDest)
                        if newPos then destPos = newPos; destNome = newNome end
                    end

                    mainGui.Visible = false
                    if not deliveryFarmAtivo then break end

                    if not confirmed then
                        restaurarJobFrames()
                        task.wait(2)
                    else
                        for i = 7, 1, -1 do
                            if not deliveryFarmAtivo then break end
                            task.wait(1)
                        end
                        if not deliveryFarmAtivo then break end

                        imaOn()
                        task.wait(2)

                        notify("Indo entregar", destNome .. " — R$ " .. job.payVal, 3)
                        slowWalk(destPos)
                        if not deliveryFarmAtivo then break end

                        imaOff()
                        task.wait(1.5)

                        local tentativa = 0
                        while not caixasEntregues() and deliveryFarmAtivo do
                            tentativa = tentativa + 1
                            imaOn(); task.wait(1.5)

                            local char = player.Character
                            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                pcall(function()
                                    hrp.CFrame = CFrame.new(destPos) * (hrp.CFrame - hrp.CFrame.Position)
                                end)
                            end
                            task.wait(0.5)
                            imaOff(); task.wait(2)

                            if tentativa % 3 == 0 and not caixasEntregues() then
                                local offsets = {
                                    Vector3.new(1,0,0), Vector3.new(-1,0,0),
                                    Vector3.new(0,0,1), Vector3.new(0,0,-1),
                                }
                                for _, off in ipairs(offsets) do
                                    if caixasEntregues() or not deliveryFarmAtivo then break end
                                    if hrp then
                                        pcall(function()
                                            hrp.CFrame = CFrame.new(destPos + off)
                                                * (hrp.CFrame - hrp.CFrame.Position)
                                        end)
                                    end
                                    imaOn(); task.wait(0.8); imaOff(); task.wait(1)
                                end
                            end
                        end

                        if caixasEntregues() then
                            notify("Entrega OK!", "R$ " .. job.payVal .. " ganhos — Ciclo #" .. ciclo, 4)
                        end

                        task.wait(2)
                    end
                end
            end
        end
    end
end

local function toggleDeliveryFarm(Value)
    if Value then
        deliveryFarmAtivo  = true
        notify("Auto Entrega", "Iniciando ciclos...", 2)
        deliveryFarmThread = task.spawn(function()
            local ok, err = pcall(deliveryFarmLoop)
            if not ok then
                notify("Erro", tostring(err):sub(1, 60), 4)
            end
        end)
    else
        deliveryFarmAtivo = false
        if deliveryFarmThread then
            task.cancel(deliveryFarmThread)
            deliveryFarmThread = nil
        end
        if AF.imaAtivo then pararIma() end
        notify("Auto Entrega", "Parado.", 2)
    end
end

TabAF:CreateToggle({
    Name         = "Auto Entrega (Delivery Farm)",
    CurrentValue = false,
    Flag         = "DeliveryFarmToggle",
    Callback     = function(Value)
        toggleDeliveryFarm(Value)
    end,
})

TabAF:CreateParagraph({
    Title   = "Como funciona",
    Content = "Vai ao ponto de coleta → pega a melhor entrega → ativa Ima → entrega → repete automaticamente.",
})

-- Para Delivery Farm ao respawnar
player.CharacterAdded:Connect(function()
    pcall(function()
        if deliveryFarmAtivo then
            deliveryFarmAtivo = false
            if deliveryFarmThread then
                pcall(function() task.cancel(deliveryFarmThread) end)
            end
            notify("Aviso", "Auto Entrega parado (respawn)", 3)
        end
        if AF.imaAtivo then pararIma() end
    end)
end)

-- Tecla H: toggle imã
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then toggleIma() end
end)


-- ═══════════════════════════════════════════════════════════════════
--  ABA: TP  (Teleportes)
-- ═══════════════════════════════════════════════════════════════════

local TabTP = Window:CreateTab("TP", 4483362458)

TabTP:CreateSection("Teleportes — Viaje rapidamente para qualquer local")

-- Função de teleporte suavizado (anti-cheat friendly)
local function doTeleport(destino)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp       = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        notify("Erro", "Personagem nao encontrado", 3)
        return
    end

    task.spawn(function()
        local STEP_SIZE   = 55
        local STEP_WAIT   = 0.05
        local PAUSE_EVERY = 15
        local PAUSE_TIME  = 0.12
        local stepCount   = 0

        while true do
            local cur  = hrp.Position
            local diff = destino - cur
            local dist = diff.Magnitude

            if dist <= STEP_SIZE then
                hrp.CFrame = CFrame.new(destino) * (hrp.CFrame - hrp.CFrame.Position)
                break
            end

            local dir     = diff.Unit
            local nextPos = cur + dir * STEP_SIZE
            hrp.CFrame    = CFrame.new(nextPos) * (hrp.CFrame - hrp.CFrame.Position)

            stepCount = stepCount + 1
            if stepCount % PAUSE_EVERY == 0 then
                task.wait(STEP_WAIT + PAUSE_TIME)
            else
                task.wait(STEP_WAIT)
            end
        end

        local posStr = math.floor(destino.X) .. "," .. math.floor(destino.Y) .. "," .. math.floor(destino.Z)
        notify("Teleporte", "Chegou em " .. posStr, 2)
    end)
end

for _, dest in ipairs(TELEPORT_DESTINATIONS) do
    local d = dest
    TabTP:CreateButton({
        Name     = d.label,
        Callback = function()
            doTeleport(d.pos)
        end,
    })
end

-- ─────────────────────────────────────────────────
--  ADICIONAR NOVOS JOGOS / DESTINOS AQUI
--  Basta inserir mais entradas em TELEPORT_DESTINATIONS
--  acima e elas aparecerão automaticamente como botões.
-- ─────────────────────────────────────────────────


-- ═══════════════════════════════════════════════════════════════════
--  ABA: CONFIG
-- ═══════════════════════════════════════════════════════════════════

local TabConfig = Window:CreateTab("Config", 4483362458)

-- ── Keybind ──────────────────────────────────────

TabConfig:CreateSection("Tecla de Toggle da GUI")

TabConfig:CreateKeybind({
    Name         = "Tecla de Toggle",
    CurrentKeybind = "RightShift",
    HoldToInteract = false,
    Flag         = "GuiToggleKey",
    Callback     = function(Keybind)
        local kc = Enum.KeyCode[Keybind]
        if kc then
            AF.togllekey = kc
            notify("Config", "Tecla definida: " .. Keybind, 2)
        end
    end,
})

-- ── Velocidade do Dash ───────────────────────────

TabConfig:CreateSection("Dash")

local dashSpeed = 80
local spInpRef  = nil   -- proxy

TabConfig:CreateSlider({
    Name         = "Velocidade do Dash",
    Range        = {10, 300},
    Increment    = 10,
    Suffix       = "studs/s",
    CurrentValue = 80,
    Flag         = "DashSpeed",
    Callback     = function(Value)
        dashSpeed = Value
    end,
})

-- Dash (tecla X) — mesma lógica original
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.X then
        local spd  = dashSpeed
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local camCF = workspace.CurrentCamera.CFrame
        local dir   = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit * spd

        pcall(function()
            local bv         = Instance.new("BodyVelocity")
            bv.MaxForce      = Vector3.new(1e7, 0, 1e7)
            bv.Velocity      = dir
            bv.Parent        = hrp
            task.delay(0.2, function() pcall(function() bv:Destroy() end) end)
        end)
    end
end)

-- ── Notificações de Status ────────────────────────

TabConfig:CreateSection("Preferencias")

TabConfig:CreateToggle({
    Name         = "Notificacoes de Status",
    CurrentValue = true,
    Flag         = "StatusNotifs",
    Callback     = function(Value)
        AF.statusEnabled = Value
        if Value then
            notify("Config", "Notificacoes ativadas", 2)
        end
    end,
})

-- ── Auto-Reaplicar ───────────────────────────────

TabConfig:CreateToggle({
    Name         = "Auto-Reaplicar Valores",
    CurrentValue = false,
    Flag         = "AutoReapply",
    Callback     = function(Value)
        AF.autoReapply = Value
        if Value then
            for vname, val in pairs(_lastApplied) do
                if _vconn[vname] then
                    pcall(function() _vconn[vname]:Disconnect() end)
                end
                local v2, capturedVal = vname, val
                _vconn[v2] = game.DescendantAdded:Connect(function(obj)
                    if obj:IsA("ValueBase") and obj.Name == v2 then
                        task.defer(function() pcall(function() obj.Value = capturedVal end) end)
                    end
                end)
            end
            notify("Config", "Auto-Reaplicar ativado", 2)
        else
            for vname, conn in pairs(_vconn) do
                pcall(function() conn:Disconnect() end)
                _vconn[vname] = nil
            end
            notify("Config", "Auto-Reaplicar desativado", 2)
        end
    end,
})

-- ── Modo Anônimo ─────────────────────────────────

TabConfig:CreateSection("Modo Anonimo")

do
    local _realName  = player.Name
    local _anonName  = "Anonymous"
    local _anonActive2 = false
    local _anonConns2  = {}

    local function setAnonName(name)
        pcall(function()
            local char = player.Character
            if char then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.DisplayName = name end
                local head = char:FindFirstChild("Head")
                if head then
                    local nt = head:FindFirstChild("NameTag")
                    if nt then pcall(function() nt.Text = name end) end
                end
            end
        end)
        pcall(function()
            local ok, CoreGui = pcall(function() return game:GetService("CoreGui") end)
            if not ok or not CoreGui then return end
            local ok2, rg = pcall(function() return CoreGui:FindFirstChild("RobloxGui", true) end)
            if not ok2 or not rg then return end
            local ok3, desc = pcall(function() return rg:GetDescendants() end)
            if not ok3 or not desc then return end
            for _, obj in ipairs(desc) do
                pcall(function()
                    if not obj or not obj.Parent then return end
                    if not obj:IsA("TextLabel") and not obj:IsA("TextButton") then return end
                    local ok4, txt = pcall(function() return obj.Text end)
                    if ok4 and txt == _realName then
                        pcall(function() obj.Text = name end)
                    end
                end)
            end
        end)
    end

    local function enableAnon()
        if _anonActive2 then return end
        _anonActive2  = true
        setAnonName(_anonName)
        _anonConns2[1] = player.CharacterAdded:Connect(function()
            task.wait(1)
            if _anonActive2 then setAnonName(_anonName) end
        end)
        _anonConns2[2] = task.spawn(function()
            while _anonActive2 do
                task.wait(2)
                if _anonActive2 then setAnonName(_anonName) end
            end
        end)
        notify("Config", "Modo Anonimo ativado", 2)
    end

    local function disableAnon()
        if not _anonActive2 then return end
        _anonActive2 = false
        for _, c in ipairs(_anonConns2) do
            pcall(function()
                if type(c) == "userdata" then c:Disconnect()
                elseif type(c) == "thread" then task.cancel(c) end
            end)
        end
        _anonConns2 = {}
        setAnonName(_realName)
        notify("Config", "Modo Anonimo desativado", 2)
    end

    TabConfig:CreateToggle({
        Name         = "Modo Anonimo",
        CurrentValue = false,
        Flag         = "AnonMode",
        Callback     = function(Value)
            if Value then enableAnon() else disableAnon() end
        end,
    })
end

-- ── Perfis (Save/Load) ───────────────────────────

TabConfig:CreateSection("Perfis — Salvar e Carregar Configuracoes")

local CFG_FOLDER        = "karfi_configs"
local CFG_INDEX         = CFG_FOLDER .. "/index.json"
local activeProfileName = "default"

pcall(_makefolder, CFG_FOLDER)

local function jsonEncode(t)
    local parts = {}
    for k, v in pairs(t) do
        local key = '"' .. tostring(k) .. '"'
        local val
        if     type(v) == "string"  then val = '"' .. v:gsub('"', '\\"') .. '"'
        elseif type(v) == "number"  then val = tostring(v)
        elseif type(v) == "boolean" then val = tostring(v)
        else                             val = '"unsupported"'
        end
        table.insert(parts, key .. ":" .. val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function jsonDecode(s)
    local t = {}
    for k, v in s:gmatch('"([^"]+)":([^,}]+)') do
        v = v:match("^%s*(.-)%s*$")
        if     v == "true"       then t[k] = true
        elseif v == "false"      then t[k] = false
        elseif v:sub(1,1) == '"' then t[k] = v:sub(2, -2)
        else                          t[k] = tonumber(v) or v
        end
    end
    return t
end

local function readIndex()
    local ok, raw = pcall(_readfile, CFG_INDEX)
    if not ok or not raw or raw == "" then return {} end
    local t = {}
    for name in raw:gmatch('"([^"]+)"') do table.insert(t, name) end
    return t
end

local function writeIndex(list)
    local parts = {}
    for _, n in ipairs(list) do
        table.insert(parts, '"' .. n:gsub('"', '\\"') .. '"')
    end
    pcall(_writefile, CFG_INDEX, "[" .. table.concat(parts, ",") .. "]")
end

local function addToIndex(name)
    local list = readIndex()
    for _, n in ipairs(list) do if n == name then return end end
    table.insert(list, name)
    writeIndex(list)
end

local function removeFromIndex(name)
    local list    = readIndex()
    local newList = {}
    for _, n in ipairs(list) do
        if n ~= name then table.insert(newList, n) end
    end
    writeIndex(newList)
end

local function profilePath(name)
    return CFG_FOLDER .. "/" .. name .. ".json"
end

local function buildSaveData()
    local d = {}
    d.togllekey     = AF.togllekey.Name
    d.statusEnabled = AF.statusEnabled
    d.autoReapply   = AF.autoReapply
    d.dashSpeed     = dashSpeed
    for vname, val in pairs(_lastApplied) do
        d["inp_" .. vname] = val
    end
    return d
end

local function saveProfile(name)
    local path = profilePath(name)
    local ok   = pcall(_writefile, path, jsonEncode(buildSaveData()))
    if ok then addToIndex(name) end
    return ok
end

local function loadProfile(name)
    local path    = profilePath(name)
    local ok, raw = pcall(_readfile, path)
    if not ok or not raw or raw == "" then return false end
    local ok2, d  = pcall(jsonDecode, raw)
    if not ok2 or not d then return false end

    if d.togllekey and Enum.KeyCode[d.togllekey] then
        AF.togllekey = Enum.KeyCode[d.togllekey]
    end
    if d.statusEnabled ~= nil then AF.statusEnabled = d.statusEnabled end
    if d.autoReapply   ~= nil then AF.autoReapply   = d.autoReapply   end
    if d.dashSpeed     ~= nil then dashSpeed         = tonumber(d.dashSpeed) or dashSpeed end
    for vname, _ in pairs(_lastApplied) do
        local v = d["inp_" .. vname]
        if v then _lastApplied[vname] = tonumber(v) or v end
    end
    activeProfileName = name
    return true
end

local function deleteProfile(name)
    local ok = pcall(_delfile, profilePath(name))
    if not ok then pcall(_writefile, profilePath(name), "{}") end
    removeFromIndex(name)
end

-- Input para nome do perfil
local currentProfileName = ""

TabConfig:CreateInput({
    Name        = "Nome do Perfil",
    PlaceholderText = "ex: meu_perfil",
    RemoveTextAfterFocusLost = false,
    Callback    = function(Value)
        currentProfileName = Value:match("^%s*(.-)%s*$"):gsub("[^%w%-%_]", "_"):sub(1, 24)
    end,
})

TabConfig:CreateButton({
    Name     = "Salvar Perfil",
    Callback = function()
        local name = currentProfileName
        if name == "" then
            notify("Erro", "Digite um nome para o perfil!", 3)
            return
        end
        local ok = saveProfile(name)
        if ok then
            notify("Perfil", "Perfil '" .. name .. "' salvo!", 2)
        else
            notify("Erro", "Falha ao salvar perfil", 3)
        end
    end,
})

TabConfig:CreateButton({
    Name     = "Carregar Perfil",
    Callback = function()
        local name = currentProfileName
        if name == "" then
            notify("Erro", "Digite o nome do perfil!", 3)
            return
        end
        local ok = loadProfile(name)
        if ok then
            notify("Perfil", "Perfil '" .. name .. "' carregado!", 2)
        else
            notify("Erro", "Perfil '" .. name .. "' nao encontrado", 3)
        end
    end,
})

TabConfig:CreateButton({
    Name     = "Excluir Perfil",
    Callback = function()
        local name = currentProfileName
        if name == "" then
            notify("Erro", "Digite o nome do perfil!", 3)
            return
        end
        deleteProfile(name)
        notify("Perfil", "Perfil '" .. name .. "' excluido", 2)
    end,
})

TabConfig:CreateButton({
    Name     = "Listar Perfis Salvos (console)",
    Callback = function()
        local profiles = readIndex()
        if #profiles == 0 then
            notify("Perfis", "Nenhum perfil salvo ainda.", 3)
        else
            notify("Perfis Salvos", table.concat(profiles, ", "), 5)
        end
    end,
})

-- Carrega o primeiro perfil automaticamente
task.delay(0.5, function()
    local profiles = readIndex()
    if #profiles > 0 then
        loadProfile(profiles[1])
        currentProfileName = profiles[1]
    end
end)


-- ════════════════════════════════════════════════════════════════════
--  TOGGLE DA GUI  (tecla configurada)
-- ════════════════════════════════════════════════════════════════════

UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if not AF.waitingBind and inp.KeyCode == AF.togllekey then
        -- O Rayfield tem seu próprio sistema de minimizar/fechar,
        -- mas mantemos a variável para compatibilidade.
        AF.guiOpen = not AF.guiOpen
    end
end)


-- ════════════════════════════════════════════════════════════════════
--  FINALIZAÇÃO
-- ════════════════════════════════════════════════════════════════════

print("KARFI HUB [RAYFIELD] 100% Carregado | Profiles em: " .. CFG_FOLDER)
