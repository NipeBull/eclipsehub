-- ════════════════════════════════════════════════════════════════════
--  ECLIPSE HUB  |  by AbyssBorn  |  Glass Edition
--  Unificado: Mectropoly + Exercito Brasileiro + Turbo Grid
--  Rayfield: https://sirius.menu/rayfield
-- ════════════════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ─────────────────────────────────────────────────
--  TEMA APPLE / GLASSMORPHISM
-- ─────────────────────────────────────────────────
local AppleTheme = {
    TextColor                     = Color3.fromRGB(255, 255, 255),
    Background                    = Color3.fromRGB(18,  18,  22),
    Topbar                        = Color3.fromRGB(25,  25,  32),
    Shadow                        = Color3.fromRGB(10,  10,  14),
    NotificationBackground        = Color3.fromRGB(30,  30,  42),
    NotificationActionsBackground = Color3.fromRGB(40,  40,  58),
    TabBackground                 = Color3.fromRGB(22,  22,  30),
    TabStroke                     = Color3.fromRGB(60,  60,  90),
    TabTextColor                  = Color3.fromRGB(200, 200, 215),
    SelectedTabTextColor          = Color3.fromRGB(255, 255, 255),
    ElementBackground             = Color3.fromRGB(30,  30,  42),
    ElementBackgroundHover        = Color3.fromRGB(40,  40,  58),
    SecondaryElementBackground    = Color3.fromRGB(24,  24,  34),
    ElementStroke                 = Color3.fromRGB(70,  70, 110),
    SecondaryElementStroke        = Color3.fromRGB(50,  50,  80),
    SliderBackground              = Color3.fromRGB(40,  40,  58),
    SliderProgress                = Color3.fromRGB(100, 130, 255),
    SliderStroke                  = Color3.fromRGB(60,   80, 180),
    ToggleBackground              = Color3.fromRGB(40,  40,  58),
    ToggleEnabled                 = Color3.fromRGB(80,  160, 255),
    ToggleDisabled                = Color3.fromRGB(55,  55,  75),
    ToggleEnabledStroke           = Color3.fromRGB(60,  130, 220),
    ToggleDisabledStroke          = Color3.fromRGB(45,  45,  65),
    ToggleEnabledOuterStroke      = Color3.fromRGB(90,  150, 255),
    ToggleDisabledOuterStroke     = Color3.fromRGB(40,  40,  60),
    DropdownSelected              = Color3.fromRGB(80,  130, 255),
    DropdownUnselected            = Color3.fromRGB(50,  50,  70),
    InputBackground               = Color3.fromRGB(28,  28,  40),
    InputStroke                   = Color3.fromRGB(70,  70, 110),
    PlaceholderColor              = Color3.fromRGB(120, 120, 160),
}

local Window = Rayfield:CreateWindow({
    Name                 = "Eclipse Hub",
    Icon                 = 0,
    LoadingTitle         = "Eclipse Hub",
    LoadingSubtitle      = "by AbyssBorn  |  Glass Edition",
    Theme                = AppleTheme,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving  = {
        Enabled    = true,
        FolderName = "EclipseHub",
        FileName   = "EclipseHub_Settings",
    },
    KeySystem = false,
})

-- ─────────────────────────────────────────────────
--  ABAS  (asset ID numérico obrigatório)
-- ─────────────────────────────────────────────────
local TabMect  = Window:CreateTab("Mectropoly",  4483362458)
local TabTune  = Window:CreateTab("Tune",        4483362458)
local TabFarm  = Window:CreateTab("Auto Farm",   4483362458)
local TabTP    = Window:CreateTab("Teleportes",  4483362458)
local TabEB    = Window:CreateTab("Exercito BR", 4483362458)
local TabTG    = Window:CreateTab("Turbo Grid",  4483362458)
local TabCfg   = Window:CreateTab("Configs",     4483362458)

-- ─────────────────────────────────────────────────
--  SERVIÇOS
-- ─────────────────────────────────────────────────
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player      = Players.LocalPlayer
local pGui        = player:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────────
--  FILESYSTEM SHIM
-- ─────────────────────────────────────────────────
local function _getfs(name, fallback)
    local ok, fn = pcall(function() return rawget(_G, name) end)
    if ok and type(fn) == "function" then return fn end
    return fallback
end

local _writefile  = _getfs("writefile",  function() end)
local _readfile   = _getfs("readfile",   function() return nil end)
local _makefolder = _getfs("makefolder", function() end)
local _delfile    = _getfs("delfile",    function() end)
local _isfile     = _getfs("isfile",     function() return false end)

-- ─────────────────────────────────────────────────
--  ESTADO GLOBAL
-- ─────────────────────────────────────────────────
local AF = {
    imaAtivo              = false,
    imaLoopConnection     = nil,
    minhasCaixas          = {},
    colisoesOriginais     = {},
    imaGrudadas           = false,
    autoReapply           = false,
    deliveryFarmAtivo     = false,
    deliveryFarmThread    = nil,
    anonActive            = false,
    anonConns             = {},
    dashSpeed             = 80,
    statusEnabled         = true,
}

local _lastApplied = {}
local _vconn       = {}
inputRefs = {} -- global, usado pelo sistema de perfis

-- ─────────────────────────────────────────────────
--  HELPER: NOTIFY  (PascalCase — API Sirius)
-- ─────────────────────────────────────────────────
local function Notify(title, content, duration)
    Rayfield:Notify({
        Title    = tostring(title),
        Content  = tostring(content),
        Duration = duration or 3,
        Image    = 4483362458,
    })
end

-- ─────────────────────────────────────────────────
--  CACHE DE INSTÂNCIAS
-- ─────────────────────────────────────────────────
local _valueCache     = {}
local _transpBoxCache = {}

local function _cacheAdd(obj)
    if obj:IsA("ValueBase") then
        local n = obj.Name
        if not _valueCache[n] then _valueCache[n] = {} end
        for _, v in ipairs(_valueCache[n]) do if v == obj then return end end
        table.insert(_valueCache[n], obj)
    elseif obj:IsA("BasePart") and obj.Name == "TranspBox" then
        for _, v in ipairs(_transpBoxCache) do if v == obj then return end end
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
    local all = game:GetDescendants()
    for i = 1, #all, 200 do
        for j = i, math.min(i + 199, #all) do _cacheAdd(all[j]) end
        task.wait()
    end
end)
game.DescendantAdded:Connect(_cacheAdd)
game.DescendantRemoving:Connect(_cacheRemove)

-- ─────────────────────────────────────────────────
--  HELPERS DE VALOR
-- ─────────────────────────────────────────────────
local function _isOwned(obj)
    local o = obj:FindFirstChild("Owner")
        or (obj.Parent and obj.Parent:FindFirstChild("Owner"))
        or (obj.Parent and obj.Parent.Parent and obj.Parent.Parent:FindFirstChild("Owner"))
        or (obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Parent
            and obj.Parent.Parent.Parent:FindFirstChild("Owner"))
    if not o then return true end
    if o:IsA("ObjectValue") then
        return o.Value == player or (o.Value and o.Value.Name == player.Name)
    elseif o:IsA("StringValue") then
        return o.Value == player.Name
    end
    return false
end

local function applyValue(vname, val)
    _lastApplied[vname] = val
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
                task.defer(function() pcall(function() obj.Value = val end) end)
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
--  TELEPORTE SUAVE (compartilhado entre abas)
-- ─────────────────────────────────────────────────
local function doTeleport(pos, nome)
    nome = nome or "destino"
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Notify("Teleporte", "Personagem nao encontrado. Respawne e tente novamente.", 4)
        return
    end
    Notify("Teleporte", "Indo para " .. nome .. "...", 2)
    task.spawn(function()
        local STEP_SIZE, STEP_WAIT, PAUSE_EVERY, PAUSE_TIME = 55, 0.05, 15, 0.12
        local steps = 0
        while (hrp.Position - pos).Magnitude > STEP_SIZE do
            hrp.CFrame = CFrame.new(hrp.Position + (pos - hrp.Position).Unit * STEP_SIZE)
                       * (hrp.CFrame - hrp.CFrame.Position)
            steps = steps + 1
            task.wait(STEP_WAIT + (steps % PAUSE_EVERY == 0 and PAUSE_TIME or 0))
        end
        hrp.CFrame = CFrame.new(pos) * (hrp.CFrame - hrp.CFrame.Position)
        Notify("Teleporte", "Chegou em " .. nome .. "!", 2)
    end)
end

-- ─────────────────────────────────────────────────
--  MODO ANÔNIMO (compartilhado)
-- ─────────────────────────────────────────────────
local _realName = player.Name

local function setAnonName(name)
    pcall(function()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.DisplayName = name end
        local head = char:FindFirstChild("Head")
        if head then
            local nt = head:FindFirstChild("NameTag")
            if nt then pcall(function() nt.Text = name end) end
        end
    end)
    -- tenta ocultar no CoreGui também
    pcall(function()
        local cg = game:GetService("CoreGui")
        local rg = cg:FindFirstChild("RobloxGui", true)
        if not rg then return end
        for _, obj in ipairs(rg:GetDescendants()) do
            pcall(function()
                if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text == _realName then
                    obj.Text = name
                end
            end)
        end
    end)
end

local function enableAnon()
    if AF.anonActive then return end
    AF.anonActive = true
    setAnonName("Anonymous")
    AF.anonConns[1] = player.CharacterAdded:Connect(function()
        task.wait(1); if AF.anonActive then setAnonName("Anonymous") end
    end)
    AF.anonConns[2] = task.spawn(function()
        while AF.anonActive do task.wait(2); if AF.anonActive then setAnonName("Anonymous") end end
    end)
    Notify("Modo Anonimo", "Seu nome esta oculto como 'Anonymous'.", 3)
end

local function disableAnon()
    if not AF.anonActive then return end
    AF.anonActive = false
    for _, c in ipairs(AF.anonConns) do
        pcall(function() if type(c) == "thread" then task.cancel(c) else c:Disconnect() end end)
    end
    AF.anonConns = {}
    setAnonName(_realName)
    Notify("Modo Anonimo", "Seu nome voltou ao normal.", 3)
end

-- ════════════════════════════════════════════════
--  DADOS — MECTROPOLY
-- ════════════════════════════════════════════════
local VALUES = {
    { name = "FuelLiters",      label = "Litros de Gasolina"     },
    { name = "WaterPercentage", label = "Fluido de Radiador (%)" },
    { name = "OilPercentage",   label = "Oleo (%)"               },
    { name = "FinalDrive",      label = "Transmissao Final"       },
}

local TUNE_VALUES = {
    { name = "Turbos",        label = "Turbos",             min = 0 },
    { name = "TurboPressure", label = "Pressao do Turbo",   min = 0 },
    { name = "TurboSize",     label = "Tamanho do Turbo",   min = 0 },
    { name = "TurboLag",      label = "Turbo Lag",          min = 0 },
    { name = "PartDamage",    label = "Dano do Motor (0=ok)", min = 0, max = 100 },
}

local MISC_VALUES = {
    { name = "RCamb",                 label = "Cambagem Traseira" },
    { name = "FCamb",                 label = "Cambagem Frontal"  },
    { name = "IgnitionTime",          label = "Avanco de Ignicao" },
    { name = "AerodynamicEfficiency", label = "Aerodinamica"      },
}

local MECT_TP = {
    { name = "Entrega (Caminhao)",    pos = Vector3.new(-25672, 35, -5895) },
    { name = "Construcao City 2",     pos = Vector3.new(-25220, 65, -5295) },
    { name = "Comet Auto Pecas",      pos = Vector3.new( -3328, 65, -3407) },
    { name = "Concessionaria",        pos = Vector3.new( -3042, 65, -3692) },
    { name = "Construcao Mectropoly", pos = Vector3.new( -3642, 65, -2506) },
    { name = "Ferro Velho",           pos = Vector3.new( -3125, 65, -4254) },
    { name = "Garagem",               pos = Vector3.new( -3375, 65, -2815) },
    { name = "Posto Mectropoly",      pos = Vector3.new( -3223, 65, -3713) },
    { name = "Valley Drag Race",      pos = Vector3.new( -3856, 65, -4901) },
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

-- ════════════════════════════════════════════════
--  DADOS — EXERCITO BRASILEIRO
-- ════════════════════════════════════════════════
local EB_TP = {
    { name = "Base Principal",      pos = Vector3.new(  0,   100,    0) },
    { name = "Area de Treinamento", pos = Vector3.new(500,   100,  500) },
    { name = "Parkour (Torre Apex)",pos = Vector3.new(366,  1087, -2052) },
    { name = "Estande de Tiro",     pos = Vector3.new(-300,  100, -300) },
    { name = "Quartel",             pos = Vector3.new(200,   100, -200) },
}

-- ════════════════════════════════════════════════
--  DADOS — TURBO GRID
-- ════════════════════════════════════════════════
local TG_TUNE = {
    { name = "FuelAmount",       label = "Combustivel",        placeholder = "0 - 100" },
    { name = "TurboPressureTG",  label = "Pressao do Turbo",   placeholder = "Ex: 1.5" },
    { name = "IgnitionTiming",   label = "Ponto de Ignicao",   placeholder = "Ex: 15"  },
    { name = "GearRatio",        label = "Relacao de Marcha",  placeholder = "Ex: 3.73"},
    { name = "SuspensionHeight", label = "Altura Suspensao",   placeholder = "Ex: -0.5"},
    { name = "CamberFront",      label = "Cambagem Dianteira",  placeholder = "Ex: -2.0"},
    { name = "CamberRear",       label = "Cambagem Traseira",   placeholder = "Ex: -1.5"},
}

local TG_TP = {
    { name = "Pista de Arrancada", pos = Vector3.new(0,   10,    0) },
    { name = "Garagem Principal",  pos = Vector3.new(500, 10,  500) },
    { name = "Loja de Pecas",      pos = Vector3.new(-300,10, -300) },
    { name = "Area de Encontro",   pos = Vector3.new(200, 10, -200) },
}

-- ════════════════════════════════════════════════
--  IMA DE CAIXAS (Mectropoly)
-- ════════════════════════════════════════════════
local function encontrarMinhasCaixas()
    local caixas = {}
    for _, obj in ipairs(_transpBoxCache) do
        if obj and obj.Parent then
            local own = obj:FindFirstChild("Owner")
            if own and own:IsA("ObjectValue") and own.Value and own.Value.Name == player.Name then
                table.insert(caixas, obj)
            end
        end
    end
    return caixas
end

local function pararIma()
    if not AF.imaAtivo then return end
    AF.imaAtivo     = false
    AF.imaGrudadas  = false
    if AF.imaLoopConnection then
        AF.imaLoopConnection:Disconnect()
        AF.imaLoopConnection = nil
    end
    for _, box in ipairs(AF.minhasCaixas) do
        if box and box.Parent then
            box.Anchored   = false
            box.CanCollide = AF.colisoesOriginais[box] or true
        end
    end
    AF.minhasCaixas      = {}
    AF.colisoesOriginais = {}
    Notify("Ima de Caixas", "Ima desativado.", 2)
end

local function iniciarIma()
    if AF.imaAtivo then return true end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Notify("Ima", "Personagem nao encontrado.", 3)
        return false
    end
    AF.minhasCaixas = encontrarMinhasCaixas()
    if #AF.minhasCaixas == 0 then
        Notify("Ima", "Nenhuma caixa sua foi encontrada. Spawn as caixas primeiro.", 4)
        return false
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
    Notify("Ima Ativado", "Puxando " .. #AF.minhasCaixas .. " caixa(s).", 2)
    AF.imaLoopConnection = RunService.Heartbeat:Connect(function()
        local c    = player.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local alvo = root.CFrame
        local todasGrud = true
        for _, box in ipairs(AF.minhasCaixas) do
            if box and box.Parent then
                local dist = (alvo.Position - box.Position).Magnitude
                if dist > 0.05 then
                    todasGrud = false
                    box.CFrame = box.CFrame:Lerp(alvo, 0.2)
                else
                    box.CFrame = alvo
                end
            end
        end
        if todasGrud and not AF.imaGrudadas then AF.imaGrudadas = true end
        if AF.imaGrudadas then
            for _, box in ipairs(AF.minhasCaixas) do
                if box and box.Parent then box.CFrame = alvo end
            end
        end
    end)
    return true
end

-- ════════════════════════════════════════════════
--  DELIVERY FARM (Mectropoly)
-- ════════════════════════════════════════════════
local function slowWalk(destino)
    local STEP_SIZE, STEP_WAIT, PAUSE_EVERY, PAUSE_TIME = 55, 0.05, 15, 0.12
    local steps = 0
    while AF.deliveryFarmAtivo do
        local ok, hrp = pcall(function()
            return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        end)
        if not (ok and hrp) then task.wait(0.5); continue end
        local diff = destino - hrp.Position
        if diff.Magnitude <= STEP_SIZE then
            hrp.CFrame = CFrame.new(destino) * (hrp.CFrame - hrp.CFrame.Position)
            break
        end
        hrp.CFrame = CFrame.new(hrp.Position + diff.Unit * STEP_SIZE) * (hrp.CFrame - hrp.CFrame.Position)
        steps = steps + 1
        task.wait(STEP_WAIT + (steps % PAUSE_EVERY == 0 and PAUSE_TIME or 0))
    end
end

local function getTransportGui()
    local tGui = pGui:FindFirstChild("TransportJobGui")
    local main = tGui and tGui:FindFirstChild("MainGUI")
    if main then main.Visible = true end
    return main
end

local function parsePay(txt)
    local n = 0
    for num in (txt or ""):gmatch("%d+%.?%d*") do
        local v = tonumber(num) or 0
        if v > n then n = v end
    end
    return n
end

local function _findDesc(parent, name)
    for _, c in ipairs(parent:GetDescendants()) do
        if c.Name == name then return c end
    end
end

local _hiddenJobFrames = {}

local function melhorJob(mainGui)
    local container = mainGui:FindFirstChild("Container")
    if not container then return nil end
    local mc = container:FindFirstChild("MainContainer")
    if not mc then return nil end
    local jobsList = mc:FindFirstChild("Jobs")
    if not jobsList then return nil end

    local melhor, melhorPay = nil, -1
    local allJobs = {}
    for _, f in ipairs(jobsList:GetChildren()) do
        if f:IsA("Frame") then
            local payObj   = _findDesc(f, "Pay")
            local destObj  = _findDesc(f, "Destination")
            local startObj = _findDesc(f, "Start")
            if payObj and destObj and startObj then
                local pv = parsePay(payObj.Text)
                local e  = { frame = f, payVal = pv, destination = destObj.Text, startBtn = startObj }
                table.insert(allJobs, e)
                if pv > melhorPay then melhorPay = pv; melhor = e end
            end
        end
    end
    if melhor then
        _hiddenJobFrames = {}
        for _, j in ipairs(allJobs) do
            if j.frame ~= melhor.frame then
                pcall(function() j.frame.Visible = false end)
                table.insert(_hiddenJobFrames, j.frame)
            end
        end
        pcall(function() melhor.frame.LayoutOrder = -999 end)
        pcall(function()
            if jobsList:IsA("ScrollingFrame") then
                jobsList.CanvasPosition = Vector2.new(0,0)
            end
        end)
    end
    return melhor
end

local function restaurarJobFrames()
    for _, f in ipairs(_hiddenJobFrames) do pcall(function() f.Visible = true end) end
    _hiddenJobFrames = {}
end

local function caixasEntregues()
    for _, obj in ipairs(_transpBoxCache) do
        if obj and obj.Parent then
            local own = obj:FindFirstChild("Owner")
            if own and own:IsA("ObjectValue") and own.Value and own.Value.Name == player.Name then
                return false
            end
        end
    end
    return true
end

local function resolveDestino(destText)
    if not destText then return nil end
    for name, pos in pairs(DELIVERY_COORDS) do
        if destText:lower():find(name:lower(), 1, true) or name:lower():find(destText:lower(), 1, true) then
            return pos, name
        end
    end
end

local function clickBtn(btn)
    local ok = false
    if not ok then pcall(function() firesignal(btn.MouseButton1Click); ok = true end) end
    if not ok then pcall(function() firebutton(btn, "MouseButton1Click"); ok = true end) end
    if not ok then
        pcall(function()
            btn.MouseButton1Down:Fire(0, 0)
            task.wait(0.06)
            btn.MouseButton1Up:Fire(0, 0)
            btn.MouseButton1Click:Fire()
            ok = true
        end)
    end
end

local function getActiveJobDestination(mainGui)
    local dest = nil
    pcall(function()
        for _, c in ipairs(mainGui:GetDescendants()) do
            if c.Name == "Destination" and c:IsA("TextLabel") and c.Text ~= "" then
                local inJobs = false
                local p = c.Parent
                while p and p ~= mainGui do
                    if p.Name == "Jobs" then inJobs = true; break end
                    p = p.Parent
                end
                if not inJobs then dest = c.Text; return end
            end
        end
    end)
    return dest
end

local function deliveryFarmLoop()
    local ciclo = 0
    while AF.deliveryFarmAtivo do
        ciclo = ciclo + 1
        Notify("Auto Entrega", "Ciclo #" .. ciclo .. " — indo ao ponto de coleta", 2)
        slowWalk(PICKUP_POS)
        if not AF.deliveryFarmAtivo then break end

        task.wait(0.8)
        local mainGui = getTransportGui()

        if not mainGui then
            Notify("Auto Entrega", "GUI de entrega nao encontrada. Fique perto do caminhao.", 4)
            task.wait(3); continue
        end

        pcall(function()
            for _, obj in ipairs(mainGui:GetDescendants()) do
                if obj:IsA("ScrollingFrame") then obj.CanvasPosition = Vector2.new(0,0) end
            end
        end)

        for i = 3, 1, -1 do
            task.wait(1)
            if not AF.deliveryFarmAtivo then break end
        end
        if not AF.deliveryFarmAtivo then break end

        local job = melhorJob(mainGui)
        if not job then
            Notify("Auto Entrega", "Nenhuma entrega disponivel. Tentando novamente em 5s...", 4)
            restaurarJobFrames(); mainGui.Visible = false
            task.wait(5); continue
        end

        local destPos, destNome = resolveDestino(job.destination)
        if not destPos then
            Notify("Auto Entrega", "Destino desconhecido: " .. tostring(job.destination), 4)
            restaurarJobFrames(); mainGui.Visible = false
            task.wait(3); continue
        end

        Notify("Auto Entrega", "Melhor entrega: R$" .. job.payVal .. " para " .. destNome, 3)
        task.wait(0.4); clickBtn(job.startBtn); task.wait(0.4); clickBtn(job.startBtn)

        local confirmed = false
        for w = 1, 20 do
            if not AF.deliveryFarmAtivo then break end
            task.wait(1)
            if not caixasEntregues() then confirmed = true; break end
            if w % 4 == 0 then clickBtn(job.startBtn) end
        end

        if not confirmed and AF.deliveryFarmAtivo then
            Notify("Auto Entrega", "Clique em START manualmente na GUI!", 5)
            for w = 1, 45 do
                if not AF.deliveryFarmAtivo then break end
                task.wait(1)
                if not caixasEntregues() then confirmed = true; break end
            end
        end

        if confirmed then restaurarJobFrames() end

        local actualDest = getActiveJobDestination(mainGui)
        if actualDest and actualDest ~= "" then
            local np, nn = resolveDestino(actualDest)
            if np then destPos = np; destNome = nn end
        end

        mainGui.Visible = false
        if not AF.deliveryFarmAtivo then break end

        if not confirmed then
            restaurarJobFrames(); task.wait(2)
        else
            -- aguarda caixas spawarem
            for i = 7, 1, -1 do
                if not AF.deliveryFarmAtivo then break end
                task.wait(1)
            end
            if not AF.deliveryFarmAtivo then break end

            iniciarIma(); task.wait(2)

            Notify("Auto Entrega", "Indo entregar em " .. destNome .. " — R$" .. job.payVal, 3)
            slowWalk(destPos)
            if not AF.deliveryFarmAtivo then break end

            pararIma(); task.wait(1.5)

            local tentativa = 0
            while not caixasEntregues() and AF.deliveryFarmAtivo do
                tentativa = tentativa + 1
                iniciarIma(); task.wait(1.5)
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function()
                        hrp.CFrame = CFrame.new(destPos) * (hrp.CFrame - hrp.CFrame.Position)
                    end)
                end
                task.wait(0.5); pararIma(); task.wait(2)

                if tentativa % 3 == 0 and not caixasEntregues() then
                    for _, off in ipairs({
                        Vector3.new(1,0,0), Vector3.new(-1,0,0),
                        Vector3.new(0,0,1), Vector3.new(0,0,-1)
                    }) do
                        if caixasEntregues() or not AF.deliveryFarmAtivo then break end
                        if hrp then
                            pcall(function()
                                hrp.CFrame = CFrame.new(destPos + off) * (hrp.CFrame - hrp.CFrame.Position)
                            end)
                        end
                        iniciarIma(); task.wait(0.8); pararIma(); task.wait(1)
                    end
                end
            end

            if caixasEntregues() then
                Notify("Entrega Concluida!", "R$" .. job.payVal .. " recebidos — Ciclo #" .. ciclo, 5)
            else
                Notify("Auto Entrega", "Nao foi possivel confirmar a entrega. Reiniciando ciclo...", 4)
            end
            task.wait(2)
        end
    end
    pararIma()
    Notify("Auto Entrega", "Farm encerrado.", 3)
end

-- ════════════════════════════════════════════════
--  SISTEMA DE PERFIS
-- ════════════════════════════════════════════════
local CFG_FOLDER = "EclipseHub"
local CFG_INDEX  = CFG_FOLDER .. "/index.json"

pcall(_makefolder, CFG_FOLDER)

local function readIndex()
    local ok, raw = pcall(_readfile, CFG_INDEX)
    if not (ok and raw and raw ~= "") then return {} end
    local list = {}
    for name in raw:gmatch('"([^"]+)"') do table.insert(list, name) end
    return list
end

local function writeIndex(list)
    local parts = {}
    for _, n in ipairs(list) do table.insert(parts, '"' .. n:gsub('"', '\\"') .. '"') end
    pcall(_writefile, CFG_INDEX, "[" .. table.concat(parts, ",") .. "]")
end

local function addToIndex(name)
    local list = readIndex()
    for _, n in ipairs(list) do if n == name then return end end
    table.insert(list, name); writeIndex(list)
end

local function removeFromIndex(name)
    local list, new = readIndex(), {}
    for _, n in ipairs(list) do if n ~= name then table.insert(new, n) end end
    writeIndex(new)
end

local function saveProfile(name)
    if not name or name == "" then return false end
    local data = { dashSpeed = AF.dashSpeed, autoReapply = AF.autoReapply, statusEnabled = AF.statusEnabled }
    for vname, val in pairs(_lastApplied) do data["inp_" .. vname] = val end
    local ok = pcall(_writefile, CFG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    if ok then addToIndex(name) end
    return ok
end

local function loadProfile(name)
    if not name or name == "" then return false end
    local ok, raw = pcall(_readfile, CFG_FOLDER .. "/" .. name .. ".json")
    if not (ok and raw and raw ~= "") then return false end
    local jok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not (jok and data) then return false end
    if data.dashSpeed     then AF.dashSpeed     = tonumber(data.dashSpeed)     or AF.dashSpeed     end
    if data.autoReapply   ~= nil then AF.autoReapply   = data.autoReapply   end
    if data.statusEnabled ~= nil then AF.statusEnabled = data.statusEnabled end
    for k, v in pairs(data) do
        if k:sub(1, 4) == "inp_" then
            local vname = k:sub(5)
            local n = tonumber(v)
            if n then _lastApplied[vname] = n; applyValue(vname, n) end
        end
    end
    return true
end

local function deleteProfile(name)
    pcall(function() _delfile(CFG_FOLDER .. "/" .. name .. ".json") end)
    removeFromIndex(name)
end

-- ════════════════════════════════════════════════
--  HELPER: input numérico para tabs
-- ════════════════════════════════════════════════
local function createValueRow(tab, cfg)
    local input = tab:CreateInput({
        Name                     = cfg.label,
        CurrentValue             = "",
        PlaceholderText          = cfg.placeholder or "Digite o valor...",
        RemoveTextAfterFocusLost = false,
        Flag                     = "Input_" .. cfg.name,
        Callback                 = function(text)
            local n = tonumber(text)
            if not n then
                Notify("Valor Invalido", "'" .. tostring(text) .. "' nao e numero valido.", 3)
                return
            end
            if cfg.min ~= nil and n < cfg.min then n = cfg.min end
            if cfg.max ~= nil and n > cfg.max then n = cfg.max end
            if not carSpawned() then
                Notify("Carro nao spawnado", "Spawne seu carro antes de aplicar valores.", 4)
                return
            end
            applyValue(cfg.name, n)
            Notify("Aplicado", cfg.label .. " = " .. n, 2)
        end,
    })
    inputRefs[cfg.name] = input
end

-- ════════════════════════════════════════════════
--  ABA: MECTROPOLY
-- ════════════════════════════════════════════════
TabMect:CreateSection("Liquidos e Combustivel")
for _, v in ipairs(VALUES) do createValueRow(TabMect, v) end

TabMect:CreateButton({
    Name     = "Aplicar Todos (Liquidos)",
    Callback = function()
        if not carSpawned() then Notify("Erro", "Carro nao spawnado!", 3); return end
        local c = 0
        for _, v in ipairs(VALUES) do
            local val = _lastApplied[v.name]
            if val then applyValue(v.name, val); c = c + 1 end
        end
        Notify("Aplicado", c .. " valores de liquidos aplicados!", 2)
    end,
})

TabMect:CreateSection("Cambagem, Ignicao e Aerodinamica")
for _, v in ipairs(MISC_VALUES) do createValueRow(TabMect, v) end

TabMect:CreateButton({
    Name     = "Aplicar Todos (Misc)",
    Callback = function()
        if not carSpawned() then Notify("Erro", "Carro nao spawnado!", 3); return end
        local c = 0
        for _, v in ipairs(MISC_VALUES) do
            local val = _lastApplied[v.name]
            if val then applyValue(v.name, val); c = c + 1 end
        end
        Notify("Aplicado", c .. " valores aplicados!", 2)
    end,
})

-- ════════════════════════════════════════════════
--  ABA: TUNE
-- ════════════════════════════════════════════════
TabTune:CreateSection("Turbo e Motor")
for _, v in ipairs(TUNE_VALUES) do createValueRow(TabTune, v) end

TabTune:CreateButton({
    Name     = "Aplicar Todos (Tune)",
    Callback = function()
        if not carSpawned() then Notify("Erro", "Carro nao spawnado!", 3); return end
        local c = 0
        for _, v in ipairs(TUNE_VALUES) do
            local val = _lastApplied[v.name]
            if val then applyValue(v.name, val); c = c + 1 end
        end
        Notify("Aplicado", c .. " valores de tune aplicados!", 2)
    end,
})

TabTune:CreateSection("Tipo de Pneu")
for _, t in ipairs({ {name="Semi-Slick", val=1}, {name="Smooth", val=2}, {name="Drag", val=3} }) do
    local tt = t
    TabTune:CreateButton({
        Name     = tt.name,
        Callback = function()
            if not carSpawned() then Notify("Erro", "Carro nao spawnado!", 3); return end
            applyTireValue("Ftire", tt.val); applyTireValue("Rtire", tt.val)
            Notify("Pneus", "Pneu " .. tt.name .. " aplicado (Ftire + Rtire = " .. tt.val .. ").", 2)
        end,
    })
end

-- ════════════════════════════════════════════════
--  ABA: AUTO FARM
-- ════════════════════════════════════════════════
TabFarm:CreateSection("Ima de Caixas")

local imaToggle = TabFarm:CreateToggle({
    Name         = "Ativar Ima de Caixas",
    CurrentValue = false,
    Flag         = "ImaToggle",
    Callback     = function(state)
        if state then
            if not iniciarIma() then imaToggle:Set(false) end
        else
            pararIma()
        end
    end,
})

TabFarm:CreateKeybind({
    Name           = "Atalho do Ima (padrao: H)",
    CurrentKeybind = "H",
    HoldToInteract = false,
    Flag           = "KeybindIma",
    Callback       = function()
        local newVal = not imaToggle.CurrentValue
        imaToggle:Set(newVal)
    end,
})

TabFarm:CreateSection("Auto Entrega — Delivery Farm")

local deliveryToggle
deliveryToggle = TabFarm:CreateToggle({
    Name         = "Iniciar Delivery Farm",
    CurrentValue = false,
    Flag         = "DeliveryFarmToggle",
    Callback     = function(state)
        AF.deliveryFarmAtivo = state
        if state then
            if AF.deliveryFarmThread then task.cancel(AF.deliveryFarmThread) end
            Notify("Auto Entrega", "Iniciando ciclos de entrega...", 3)
            AF.deliveryFarmThread = task.spawn(function()
                local ok, err = pcall(deliveryFarmLoop)
                if not ok then Notify("Erro no Farm", tostring(err):sub(1,80), 5) end
                AF.deliveryFarmAtivo = false
                deliveryToggle:Set(false)
            end)
        else
            AF.deliveryFarmAtivo = false
            if AF.deliveryFarmThread then
                task.cancel(AF.deliveryFarmThread)
                AF.deliveryFarmThread = nil
            end
            if AF.imaAtivo then pararIma() end
            Notify("Auto Entrega", "Farm encerrado.", 2)
        end
    end,
})

TabFarm:CreateParagraph({
    Title   = "Como funciona",
    Content = "Vai ao ponto de coleta, seleciona a melhor entrega (maior pagamento), ativa o ima, entrega as caixas e repete automaticamente.",
})

player.CharacterAdded:Connect(function()
    if AF.deliveryFarmAtivo then
        AF.deliveryFarmAtivo = false
        if AF.deliveryFarmThread then
            pcall(function() task.cancel(AF.deliveryFarmThread) end)
        end
        deliveryToggle:Set(false)
        Notify("Auto Entrega", "Farm pausado por respawn. Reative manualmente.", 4)
    end
    if AF.imaAtivo then pararIma() end
end)

-- ════════════════════════════════════════════════
--  ABA: TELEPORTES (Mectropoly)
-- ════════════════════════════════════════════════
TabTP:CreateSection("Mectropoly")
for _, dest in ipairs(MECT_TP) do
    local d = dest
    TabTP:CreateButton({
        Name     = d.name,
        Callback = function() doTeleport(d.pos, d.name) end,
    })
end

-- ════════════════════════════════════════════════
--  ABA: EXERCITO BRASILEIRO
-- ════════════════════════════════════════════════
TabEB:CreateSection("Teleportes — Exercito Brasileiro")
for _, dest in ipairs(EB_TP) do
    local d = dest
    TabEB:CreateButton({
        Name     = d.name,
        Callback = function() doTeleport(d.pos, d.name) end,
    })
end

TabEB:CreateSection("Utilitarios")

TabEB:CreateToggle({
    Name         = "Modo Anonimo",
    CurrentValue = false,
    Flag         = "AnonModeEB",
    Callback     = function(state)
        if state then enableAnon() else disableAnon() end
    end,
})

TabEB:CreateSection("Funcoes de Treinamento")

TabEB:CreateButton({
    Name     = "Auto Parkour (WIP)",
    Callback = function()
        Notify("Em Desenvolvimento", "Auto Parkour ainda nao implementado. Requer mapeamento da pista.", 4)
    end,
})

TabEB:CreateButton({
    Name     = "Auto Treino de Tiro (WIP)",
    Callback = function()
        Notify("Em Desenvolvimento", "Auto Treino de Tiro ainda nao implementado. Requer localizacao dos alvos.", 4)
    end,
})

TabEB:CreateSection("Patentes e Missoes")

TabEB:CreateButton({
    Name     = "Auto Patente (WIP)",
    Callback = function()
        Notify("Em Desenvolvimento", "Auto Patente ainda nao implementado.", 4)
    end,
})

TabEB:CreateButton({
    Name     = "Auto Missoes (WIP)",
    Callback = function()
        Notify("Em Desenvolvimento", "Auto Missoes ainda nao implementado.", 4)
    end,
})

-- ════════════════════════════════════════════════
--  ABA: TURBO GRID
-- ════════════════════════════════════════════════
TabTG:CreateSection("Ajustes do Carro (Tuning)")

for _, v in ipairs(TG_TUNE) do
    local cfg = v
    TabTG:CreateInput({
        Name                     = cfg.label,
        CurrentValue             = "",
        PlaceholderText          = cfg.placeholder or "Digite o valor...",
        RemoveTextAfterFocusLost = false,
        Flag                     = "InputTG_" .. cfg.name,
        Callback                 = function(text)
            local n = tonumber(text)
            if not n then
                Notify("Valor Invalido", "'" .. tostring(text) .. "' nao e numero valido.", 3)
                return
            end
            -- aplica direto via cache (mesma lógica do Mectropoly)
            applyValue(cfg.name, n)
            Notify("Turbo Grid", cfg.label .. " = " .. n, 2)
        end,
    })
end

TabTG:CreateSection("Teleportes — Turbo Grid")
for _, dest in ipairs(TG_TP) do
    local d = dest
    TabTG:CreateButton({
        Name     = d.name,
        Callback = function() doTeleport(d.pos, d.name) end,
    })
end

TabTG:CreateSection("Utilitarios TG")

TabTG:CreateToggle({
    Name         = "Modo Anonimo",
    CurrentValue = false,
    Flag         = "AnonModeTG",
    Callback     = function(state)
        if state then enableAnon() else disableAnon() end
    end,
})

TabTG:CreateButton({
    Name     = "Auto Farm de Dinheiro (WIP)",
    Callback = function()
        Notify("Em Desenvolvimento", "Auto Farm de Dinheiro nao implementado. Requer logica especifica do jogo.", 4)
    end,
})

-- ════════════════════════════════════════════════
--  ABA: CONFIGS
-- ════════════════════════════════════════════════
TabCfg:CreateSection("Dash (Tecla X)")

TabCfg:CreateSlider({
    Name         = "Velocidade do Dash",
    Range        = {10, 300},
    Increment    = 10,
    Suffix       = " studs",
    CurrentValue = 80,
    Flag         = "DashSpeed",
    Callback     = function(val) AF.dashSpeed = val end,
})

UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.X then
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local camCF = workspace.CurrentCamera.CFrame
        local dir   = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit * AF.dashSpeed
        pcall(function()
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e7, 0, 1e7)
            bv.Velocity = dir
            bv.Parent   = hrp
            task.delay(0.2, function() pcall(function() bv:Destroy() end) end)
        end)
    end
end)

TabCfg:CreateSection("Preferencias Gerais")

TabCfg:CreateToggle({
    Name         = "Auto-Reaplicar Valores",
    CurrentValue = false,
    Flag         = "AutoReapply",
    Callback     = function(state)
        AF.autoReapply = state
        if not state then
            for vname, conn in pairs(_vconn) do
                pcall(function() conn:Disconnect() end)
                _vconn[vname] = nil
            end
        end
        Notify("Config", "Auto-Reaplicar " .. (state and "ativado." or "desativado."), 2)
    end,
})

TabCfg:CreateToggle({
    Name         = "Modo Anonimo",
    CurrentValue = false,
    Flag         = "AnonModeGlobal",
    Callback     = function(state)
        if state then enableAnon() else disableAnon() end
    end,
})

TabCfg:CreateSection("Perfis de Configuracao")

local currentProfileName = ""

TabCfg:CreateInput({
    Name                     = "Nome do Perfil",
    CurrentValue             = "",
    PlaceholderText          = "Ex: drift, corrida, tudo_zerado...",
    RemoveTextAfterFocusLost = false,
    Flag                     = "ProfileNameInput",
    Callback                 = function(text)
        currentProfileName = text:match("^%s*(.-)%s*$"):gsub("[^%w%-%_]", "_"):sub(1, 32)
    end,
})

TabCfg:CreateButton({
    Name     = "Salvar Perfil",
    Callback = function()
        if currentProfileName == "" then
            Notify("Aviso", "Digite um nome para o perfil antes de salvar.", 3)
            return
        end
        if saveProfile(currentProfileName) then
            Notify("Perfil Salvo", "'" .. currentProfileName .. "' salvo com sucesso.", 3)
        else
            Notify("Erro ao Salvar", "Falha ao salvar. Seu executor suporta writefile?", 4)
        end
    end,
})

TabCfg:CreateButton({
    Name     = "Carregar Perfil",
    Callback = function()
        if currentProfileName == "" then
            Notify("Aviso", "Digite o nome do perfil para carregar.", 3)
            return
        end
        if loadProfile(currentProfileName) then
            Notify("Perfil Carregado", "'" .. currentProfileName .. "' carregado.", 3)
        else
            Notify("Erro", "Perfil '" .. currentProfileName .. "' nao encontrado ou corrompido.", 4)
        end
    end,
})

TabCfg:CreateButton({
    Name     = "Excluir Perfil",
    Callback = function()
        if currentProfileName == "" then
            Notify("Aviso", "Digite o nome do perfil para excluir.", 3)
            return
        end
        deleteProfile(currentProfileName)
        Notify("Perfil Excluido", "'" .. currentProfileName .. "' removido.", 3)
    end,
})

TabCfg:CreateButton({
    Name     = "Listar Perfis Salvos",
    Callback = function()
        local list = readIndex()
        if #list == 0 then
            Notify("Perfis", "Nenhum perfil salvo ainda.", 3)
        else
            Notify("Perfis Salvos", table.concat(list, ", "), 6)
        end
    end,
})

-- ─────────────────────────────────────────────────
--  INICIALIZAÇÃO FINAL
-- ─────────────────────────────────────────────────
task.delay(0.8, function()
    local profiles = readIndex()
    if #profiles > 0 then
        if loadProfile(profiles[1]) then
            currentProfileName = profiles[1]
        end
    end
end)

Rayfield:LoadConfiguration()
Notify("Eclipse Hub", "Hub carregado com sucesso!", 4)
print("[Eclipse Hub] Carregado — Mectropoly | EB | Turbo Grid")
