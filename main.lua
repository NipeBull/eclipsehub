-- ════════════════════════════════════════════════════════════════════
--  UNIVERSAL HUB  |  by AbyssBorn / Karfi Team
--  UI: Rayfield (Sirius) — tema customizado leve
--  Estrutura: uma aba por jogo + aba de config global
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
    Name           = "Universal Hub",
    LoadingTitle   = "Universal Hub",
    LoadingSubtitle = "by AbyssBorn • Multi-Game",
    Theme          = HubTheme,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "UniversalHub",
        FileName   = "UniversalHub_Config",
    },
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

-- FILESYSTEM SHIM
local function _getfs(name, fallback)
    local ok, fn = pcall(function() return rawget(_G, name) end)
    if ok and type(fn) == "function" then return fn end
    return fallback
end
local _writefile  = _getfs("writefile",  function() end)
local _readfile   = _getfs("readfile",   function() return nil end)
local _makefolder = _getfs("makefolder", function() end)
local _isfile     = _getfs("isfile",     function() return false end)

-- Estado global
local State = {
    autoReapply   = false,
    anonActive    = false,
    anonConns     = {},
    imaAtivo      = false,
    imaConn       = nil,
    minhasCaixas  = {},
    colisoes      = {},
    deliveryAtivo = false,
    deliveryThread = nil,
}

-- Referências de input (para perfis)
local inputRefs = {}

-- ═════════════════════════════════════════════════════════════════════
--  CACHE DE VALORES (performance — zero scan por frame)
-- ═════════════════════════════════════════════════════════════════════
local _valueCache    = {}  -- [name] = { obj, ... }
local _transpBoxCache = {}

local function _cacheAdd(obj)
    if obj:IsA("ValueBase") then
        local n = obj.Name
        if not _valueCache[n] then _valueCache[n] = {} end
        for _, v in ipairs(_valueCache[n]) do
            if v == obj then return end
        end
        table.insert(_valueCache[n], obj)
    elseif obj:IsA("BasePart") and obj.Name == "TranspBox" then
        for _, v in ipairs(_transpBoxCache) do
            if v == obj then return end
        end
        table.insert(_transpBoxCache, obj)
    end
end

local function _cacheRemove(obj)
    if obj:IsA("ValueBase") then
        local n = obj.Name
        if not _valueCache[n] then return end
        for i, v in ipairs(_valueCache[n]) do
            if v == obj then table.remove(_valueCache[n], i); return end
        end
    elseif obj:IsA("BasePart") and obj.Name == "TranspBox" then
        for i, v in ipairs(_transpBoxCache) do
            if v == obj then table.remove(_transpBoxCache, i); return end
        end
    end
end

-- Popula cache em lotes (não trava o frame)
task.spawn(function()
    local all = game:GetDescendants()
    local i = 1
    while i <= #all do
        local lim = math.min(i + 249, #all)
        for j = i, lim do _cacheAdd(all[j]) end
        i = lim + 1
        task.wait()
    end
end)

game.DescendantAdded:Connect(_cacheAdd)
game.DescendantRemoving:Connect(_cacheRemove)

-- ═════════════════════════════════════════════════════════════════════
--  FUNÇÕES AUXILIARES
-- ═════════════════════════════════════════════════════════════════════

-- Ownership check
local function _isOwned(obj)
    local ov = obj:FindFirstChild("Owner")
        or (obj.Parent and obj.Parent:FindFirstChild("Owner"))
        or (obj.Parent and obj.Parent.Parent and obj.Parent.Parent:FindFirstChild("Owner"))
    if not ov then return true end
    if ov:IsA("ObjectValue") then
        return ov.Value == player or (ov.Value and ov.Value.Name == player.Name)
    elseif ov:IsA("StringValue") then
        return ov.Value == player.Name
    end
    return false
end

-- Verifica se o carro do player está spawnado
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

-- Aplica valor no cache
local _vconn     = {}
local _lastApplied = {}

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
    if State.autoReapply then
        _vconn[vname] = game.DescendantAdded:Connect(function(obj)
            if obj:IsA("ValueBase") and obj.Name == vname then
                task.defer(function() pcall(function() obj.Value = val end) end)
            end
        end)
    end
end

-- Aplica valor de pneu (com ownership)
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
--  IMÃ DE CAIXAS
-- ═════════════════════════════════════════════════════════════════════
local function encontrarCaixas()
    local caixas = {}
    for _, obj in ipairs(_transpBoxCache) do
        if obj and obj.Parent then
            local ov = obj:FindFirstChild("Owner")
            if ov and ov:IsA("ObjectValue") and ov.Value and ov.Value.Name == player.Name then
                table.insert(caixas, obj)
            end
        end
    end
    return caixas
end

local function pararIma()
    if not State.imaAtivo then return end
    State.imaAtivo = false
    if State.imaConn then
        State.imaConn:Disconnect()
        State.imaConn = nil
    end
    for _, box in ipairs(State.minhasCaixas) do
        if box and box.Parent then
            pcall(function() box.Anchored   = false end)
            pcall(function() box.CanCollide = State.colisoes[box] ~= nil and State.colisoes[box] or true end)
        end
    end
    State.minhasCaixas = {}
    State.colisoes     = {}
    notify("🔗 Imã", "Desativado. Caixas liberadas.", 3)
end

-- retorna true se conseguiu iniciar
local function iniciarIma()
    if State.imaAtivo then return true end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        notify("⚠️ Erro", "Personagem não encontrado.", 4)
        return false
    end
    State.minhasCaixas = encontrarCaixas()
    if #State.minhasCaixas == 0 then
        notify("🔗 Imã", "Nenhuma caixa encontrada. Spawne primeiro.", 4)
        return false
    end
    State.imaAtivo = true
    for _, box in ipairs(State.minhasCaixas) do
        if box and box.Parent then
            State.colisoes[box] = box.CanCollide
            pcall(function() box.CanCollide = false end)
            pcall(function() box.Anchored   = true  end)
        end
    end
    notify("🔗 Imã Ativado", "Puxando " .. #State.minhasCaixas .. " caixa(s).", 4)
    State.imaConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local c   = player.Character
            local r   = c and c:FindFirstChild("HumanoidRootPart")
            if not r then return end
            for _, box in ipairs(State.minhasCaixas) do
                if box and box.Parent then
                    box.CFrame = box.CFrame:Lerp(r.CFrame, 0.18)
                end
            end
        end)
    end)
    return true
end

-- ═════════════════════════════════════════════════════════════════════
--  AUTO ENTREGA (Delivery Farm)
-- ═════════════════════════════════════════════════════════════════════
local PICKUP_POS = Vector3.new(-25679, 32, -5879)

local DELIVERY_COORDS = {
    ["Caminhão"]              = Vector3.new(-25672, 35, -5895),
    ["Construção"]            = Vector3.new(-25220, 65, -5295),
    ["Comet Auto Peças"]      = Vector3.new( -3328, 65, -3407),
    ["Concessionaria"]        = Vector3.new( -3042, 65, -3692),
    ["Construção Mectropoly"] = Vector3.new( -3642, 65, -2506),
    ["Ferro Velho"]           = Vector3.new( -3125, 65, -4254),
    ["Garagem 4"]             = Vector3.new( -3375, 65, -2815),
    ["Posto Mectropoly"]      = Vector3.new( -3223, 65, -3713),
    ["Valley Drag Race"]      = Vector3.new( -3856, 65, -4901),
}

local _hiddenFrames = {}

local function parsePay(txt)
    if not txt then return 0 end
    local n = 0
    for num in txt:gmatch("%d+%.?%d*") do
        local v = tonumber(num) or 0
        if v > n then n = v end
    end
    return n
end

local function findDesc(parent, name)
    for _, c in ipairs(parent:GetDescendants()) do
        if c.Name == name then return c end
    end
    return nil
end

local function caixasEntregues()
    for _, obj in ipairs(_transpBoxCache) do
        if obj and obj.Parent then
            local ov = obj:FindFirstChild("Owner")
            if ov and ov:IsA("ObjectValue") and ov.Value and ov.Value.Name == player.Name then
                return false
            end
        end
    end
    return true
end

local function resolveDestino(text)
    if not text then return nil, nil end
    for name, pos in pairs(DELIVERY_COORDS) do
        if name == text then return pos, name end
    end
    local low = text:lower()
    for name, pos in pairs(DELIVERY_COORDS) do
        if low:find(name:lower(), 1, true) or name:lower():find(low, 1, true) then
            return pos, name
        end
    end
    return nil, nil
end

local function getTransportGui()
    local tg = pGui:FindFirstChild("TransportJobGui")
    if not tg then return nil end
    local mg = tg:FindFirstChild("MainGUI")
    if not mg then return nil end
    mg.Visible = true
    return mg
end

local function melhorJob(mainGui)
    local container = mainGui:FindFirstChild("Container")
    if not container then return nil end
    local mc = container:FindFirstChild("MainContainer")
    if not mc then return nil end
    local jl = mc:FindFirstChild("Jobs")
    if not jl then return nil end

    local best, bestPay = nil, -1
    local all = {}

    for _, jf in ipairs(jl:GetChildren()) do
        if jf:IsA("Frame") then
            local payObj  = findDesc(jf, "Pay")
            local destObj = findDesc(jf, "Destination")
            local startObj = findDesc(jf, "Start")
            if payObj and destObj and startObj then
                local pv = parsePay(payObj.Text)
                local entry = { frame = jf, payVal = pv, destination = destObj.Text, startBtn = startObj }
                table.insert(all, entry)
                if pv > bestPay then bestPay = pv; best = entry end
            end
        end
    end

    if best then
        _hiddenFrames = {}
        for _, j in ipairs(all) do
            if j.frame ~= best.frame then
                pcall(function() j.frame.Visible = false end)
                table.insert(_hiddenFrames, j.frame)
            end
        end
    end
    return best
end

local function restaurarFrames()
    for _, f in ipairs(_hiddenFrames) do
        pcall(function() f.Visible = true end)
    end
    _hiddenFrames = {}
end

local function clickBtn(btn)
    local ok = false
    if not ok then pcall(function() firesignal(btn.MouseButton1Click); ok = true end) end
    if not ok then pcall(function() firebutton(btn, "MouseButton1Click"); ok = true end) end
    if not ok then
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local ap  = btn.AbsolutePosition
            local as_ = btn.AbsoluteSize
            vim:SendMouseButtonEvent(ap.X + as_.X * .5, ap.Y + as_.Y * .5, 0, true,  game, 0)
            task.wait(0.06)
            vim:SendMouseButtonEvent(ap.X + as_.X * .5, ap.Y + as_.Y * .5, 0, false, game, 0)
            ok = true
        end)
    end
    return ok
end

-- Label de status para o delivery (atualizado pela UI)
local _dfStatusLabel = nil

local function dfLog(msg)
    if _dfStatusLabel then
        pcall(function() _dfStatusLabel.CurrentValue = msg end)
    end
    notify("🚚 Auto Entrega", msg, 2)
end

local function slowWalk(pos)
    local STEP   = 55
    local WAIT   = 0.05
    local PAUSEN = 15
    local PAUSET = 0.12
    local steps  = 0

    while State.deliveryAtivo do
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(0.5); continue end

        local diff = pos - hrp.Position
        if diff.Magnitude <= STEP then
            pcall(function() hrp.CFrame = CFrame.new(pos) * (hrp.CFrame - hrp.CFrame.Position) end)
            break
        end

        pcall(function()
            hrp.CFrame = CFrame.new(hrp.Position + diff.Unit * STEP) * (hrp.CFrame - hrp.CFrame.Position)
        end)
        steps = steps + 1
        task.wait(WAIT + (steps % PAUSEN == 0 and PAUSET or 0))
    end
end

local function deliveryLoop()
    local ciclo = 0
    while State.deliveryAtivo do
        ciclo = ciclo + 1
        dfLog("Ciclo #" .. ciclo .. " → indo ao ponto de coleta")
        slowWalk(PICKUP_POS)
        if not State.deliveryAtivo then break end

        task.wait(0.8)
        local mg = getTransportGui()
        if not mg then
            dfLog("GUI de entrega não encontrada! (aguardando 5s)")
            task.wait(5)
            continue
        end

        for i = 3, 1, -1 do
            dfLog("Carregando entregas... " .. i .. "s")
            task.wait(1)
            if not State.deliveryAtivo then break end
        end
        if not State.deliveryAtivo then break end

        local job = melhorJob(mg)
        if not job then
            dfLog("Sem entregas disponíveis. Tentando em 5s...")
            restaurarFrames()
            mg.Visible = false
            task.wait(5)
            continue
        end

        local destPos, destNome = resolveDestino(job.destination)
        if not destPos then
            dfLog("Destino desconhecido: " .. tostring(job.destination))
            restaurarFrames()
            mg.Visible = false
            task.wait(3)
            continue
        end

        dfLog("Melhor: R$" .. job.payVal .. " → " .. destNome)
        task.wait(0.4)
        clickBtn(job.startBtn)
        task.wait(0.4)
        clickBtn(job.startBtn)

        local confirmed = false
        for w = 1, 20 do
            if not State.deliveryAtivo then break end
            task.wait(1)
            if not caixasEntregues() then confirmed = true; break end
            if w % 4 == 0 then clickBtn(job.startBtn) end
            dfLog("Aguardando caixas... (" .. w .. "s)")
        end

        if not confirmed then
            dfLog("Timeout. Clique START manualmente!")
            for w = 1, 45 do
                if not State.deliveryAtivo then break end
                task.wait(1)
                if not caixasEntregues() then confirmed = true; break end
                dfLog("Aguardando (" .. w .. "/45s)...")
            end
        end

        if confirmed then restaurarFrames() end
        mg.Visible = false
        if not State.deliveryAtivo then break end

        if not confirmed then
            dfLog("Timeout total. Novo ciclo...")
            task.wait(2)
            continue
        end

        -- Espera caixas spawnarem
        for i = 7, 1, -1 do
            if not State.deliveryAtivo then break end
            dfLog("Aguardando spawn das caixas... " .. i .. "s")
            task.wait(1)
        end
        if not State.deliveryAtivo then break end

        dfLog("Ativando Imã...")
        if not State.imaAtivo then iniciarIma() end
        task.wait(2)

        dfLog("Indo para: " .. destNome)
        slowWalk(destPos)
        if not State.deliveryAtivo then break end

        dfLog("Chegou! Soltando caixas...")
        pararIma()
        task.wait(1.5)

        local tentativa = 0
        while not caixasEntregues() and State.deliveryAtivo do
            tentativa = tentativa + 1
            dfLog("Entregando... tentativa " .. tentativa)
            if not State.imaAtivo then iniciarIma() end
            task.wait(1.5)
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() hrp.CFrame = CFrame.new(destPos) * (hrp.CFrame - hrp.CFrame.Position) end)
            end
            task.wait(0.5)
            pararIma()
            task.wait(2)
        end

        if caixasEntregues() then
            dfLog("✅ Entrega concluída! Ciclo #" .. ciclo .. " — R$" .. job.payVal)
            notify("✅ Entrega Concluída!", "R$" .. job.payVal .. " ganhos — Ciclo #" .. ciclo, 5)
        end
        task.wait(2)
    end

    dfLog("Auto Entrega parado.")
end

-- ═════════════════════════════════════════════════════════════════════
--  SISTEMA DE PERFIS
-- ═════════════════════════════════════════════════════════════════════
local PROFILE_FOLDER = "UniversalHub"
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
    for _, group in ipairs({ "VALUES", "TUNE_VALUES", "MISC_VALUES" }) do
        local g = _G[group] or {}
        for _, v in ipairs(g) do
            local ref = inputRefs[v.name]
            if ref then data[v.name] = Rayfield.Flags[v.name .. "_Input"] and Rayfield.Flags[v.name .. "_Input"].Value or "" end
        end
    end
    local ok = pcall(_writefile, PROFILE_FOLDER .. "/" .. name .. ".json", HttpSvc:JSONEncode(data))
    if not ok then return false end
    local list  = readIndex()
    local found = false
    for _, n in ipairs(list) do if n == name then found = true; break end end
    if not found then table.insert(list, name); writeIndex(list) end
    return true
end

local function loadProfile(name)
    if not name or name == "" then return false end
    local ok, raw = pcall(_readfile, PROFILE_FOLDER .. "/" .. name .. ".json")
    if not (ok and raw and raw ~= "") then return false end
    local ok2, parsed = pcall(function() return HttpSvc:JSONDecode(raw) end)
    if not (ok2 and parsed) then return false end
    for k, v in pairs(parsed) do
        local n = tonumber(v)
        if n then applyValue(k, n) end
    end
    return true
end

local function deleteProfile(name)
    if not name or name == "" then return end
    local list    = readIndex()
    local newList = {}
    for _, n in ipairs(list) do if n ~= name then table.insert(newList, n) end end
    writeIndex(newList)
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
--  ██████████████████████████████████████████████████████████████████
--  CONSTRUÇÃO DAS ABAS
--  ► Cada jogo = uma aba no Window do Rayfield
--  ► Para adicionar um novo jogo: copie o bloco "do...end" de qualquer
--    jogo, mude o nome da aba e adicione suas funções.
--  ██████████████████████████████████████████████████████████████████
-- ═════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────
--  ► JOGO 1: MECÂNICA BRASILEIRA
-- ─────────────────────────────────────────────────
do
    local MBTab = Window:CreateTab("🔧  Mecânica BR", 4483362458)

    -- ── Dados específicos do jogo ────────────────
    local VALUES = {
        { name = "FuelLiters",      label = "⛽  Litros de Gasolina",   placeholder = "0 – 999"   },
        { name = "WaterPercentage", label = "💧  Fluido de Radiador",    placeholder = "0 – 100"   },
        { name = "OilPercentage",   label = "🛢  Porcentagem de Óleo",   placeholder = "0 – 100"   },
        { name = "FinalDrive",      label = "⚙️  Transmissão Final",     placeholder = "Ex: 3.73"  },
    }
    local TUNE_VALUES = {
        { name = "Turbos",        label = "🌀  Turbos",                placeholder = "0 – 4"     },
        { name = "TurboPressure", label = "📈  Pressão do Turbo",      placeholder = "Ex: 1.5"   },
        { name = "TurboSize",     label = "📐  Tamanho do Turbo",      placeholder = "Ex: 50"    },
        { name = "TurboLag",      label = "⏱  Turbo Lag",             placeholder = "Ex: 0.3"   },
        { name = "PartDamage",    label = "🔧  Dano do Motor (0=ok)",  placeholder = "0 – 100"   },
    }
    local MISC_VALUES = {
        { name = "RCamb",                 label = "🔩  Cambagem Traseira",  placeholder = "Ex: -2.5" },
        { name = "FCamb",                 label = "🔩  Cambagem Frontal",   placeholder = "Ex: -1.5" },
        { name = "IgnitionTime",          label = "⚡  Avanço de Ignição",  placeholder = "Ex: 15"   },
        { name = "AerodynamicEfficiency", label = "🌬  Aerodinâmica",        placeholder = "0 – 100"  },
    }
    local TELEPORT_DESTINATIONS = {
        { name = "📦  Entrega",               pos = Vector3.new(-25672,  35, -5895) },
        { name = "🏗  Construção City 2",      pos = Vector3.new(-25220,  65, -5295) },
        { name = "🔩  Comet Auto Peças",       pos = Vector3.new( -3328,  65, -3407) },
        { name = "🚗  Concessionária",         pos = Vector3.new( -3042,  65, -3692) },
        { name = "🏗  Construção Mectropoly",  pos = Vector3.new( -3642,  65, -2506) },
        { name = "🗑  Junkyard / Ferro Velho", pos = Vector3.new( -3125,  65, -4254) },
        { name = "🏠  Garagem",                pos = Vector3.new( -3375,  65, -2815) },
        { name = "⛽  Posto Mectropoly",       pos = Vector3.new( -3223,  65, -3713) },
        { name = "🏁  Valley Drag Race",       pos = Vector3.new( -3856,  65, -4901) },
    }

    -- ── Helper: cria input + botão SET ──────────
    local function makeValueInput(tab, cfg)
        local inp = tab:CreateInput({
            Name            = cfg.label,
            PlaceholderText = cfg.placeholder or "Digite o valor...",
            NumbersOnly     = true,
            Flag            = cfg.name .. "_Input",
            Callback        = function(text)
                local n = tonumber(text)
                if not n then return end
                if not carSpawned() then
                    notify("⚠️ Erro", "Seu carro não está spawnado.", 4)
                    return
                end
                applyValue(cfg.name, n)
                notify("✅ Aplicado", cfg.label .. " → " .. n, 3)
            end,
        })
        inputRefs[cfg.name] = inp
    end

    -- ── SEÇÃO: Líquidos & Gerais ─────────────────
    local SecLiquidos = MBTab:CreateSection("⛽  Líquidos & Gerais")
    for _, v in ipairs(VALUES) do makeValueInput(MBTab, v) end

    MBTab:CreateButton({
        Name     = "✅  Aplicar Todos (Líquidos)",
        Callback = function()
            if not carSpawned() then notify("⚠️ Erro", "Carro não spawnado.", 4); return end
            local count = 0
            for _, v in ipairs(VALUES) do
                local flag = Rayfield.Flags[v.name .. "_Input"]
                local n    = flag and tonumber(flag.Value)
                if n then applyValue(v.name, n); count = count + 1 end
            end
            notify("✅ Aplicado", count .. " valores de líquidos aplicados!", 3)
        end,
    })

    -- ── SEÇÃO: Tune / Turbo ──────────────────────
    local SecTune = MBTab:CreateSection("🌀  Tune & Turbo")
    for _, v in ipairs(TUNE_VALUES) do makeValueInput(MBTab, v) end

    MBTab:CreateButton({
        Name     = "✅  Aplicar Todos (Tune)",
        Callback = function()
            if not carSpawned() then notify("⚠️ Erro", "Carro não spawnado.", 4); return end
            local count = 0
            for _, v in ipairs(TUNE_VALUES) do
                local flag = Rayfield.Flags[v.name .. "_Input"]
                local n    = flag and tonumber(flag.Value)
                if n then applyValue(v.name, n); count = count + 1 end
            end
            notify("✅ Aplicado", count .. " valores de tune aplicados!", 3)
        end,
    })

    -- ── SEÇÃO: Cambagem & Aerodinâmica ──────────
    local SecMisc = MBTab:CreateSection("🔩  Cambagem & Aerodinâmica")
    for _, v in ipairs(MISC_VALUES) do makeValueInput(MBTab, v) end

    MBTab:CreateButton({
        Name     = "✅  Aplicar Todos (Misc)",
        Callback = function()
            if not carSpawned() then notify("⚠️ Erro", "Carro não spawnado.", 4); return end
            local count = 0
            for _, v in ipairs(MISC_VALUES) do
                local flag = Rayfield.Flags[v.name .. "_Input"]
                local n    = flag and tonumber(flag.Value)
                if n then applyValue(v.name, n); count = count + 1 end
            end
            notify("✅ Aplicado", count .. " valores misc aplicados!", 3)
        end,
    })

    -- ── SEÇÃO: Pneus ────────────────────────────
    local SecPneus = MBTab:CreateSection("🏁  Pneus")

    MBTab:CreateButton({
        Name     = "🏁  Semi-Slick (valor 1)",
        Callback = function()
            if not carSpawned() then notify("⚠️ Erro", "Carro não spawnado.", 4); return end
            applyTireValue("Ftire", 1); applyTireValue("Rtire", 1)
            notify("🏁 Pneus", "Semi-Slick aplicado.", 3)
        end,
    })
    MBTab:CreateButton({
        Name     = "🔵  Smooth (valor 2)",
        Callback = function()
            if not carSpawned() then notify("⚠️ Erro", "Carro não spawnado.", 4); return end
            applyTireValue("Ftire", 2); applyTireValue("Rtire", 2)
            notify("🔵 Pneus", "Smooth aplicado.", 3)
        end,
    })
    MBTab:CreateButton({
        Name     = "🔴  Drag (valor 3)",
        Callback = function()
            if not carSpawned() then notify("⚠️ Erro", "Carro não spawnado.", 4); return end
            applyTireValue("Ftire", 3); applyTireValue("Rtire", 3)
            notify("🔴 Pneus", "Drag aplicado.", 3)
        end,
    })

    -- ── SEÇÃO: Auto Farm ────────────────────────
    local SecFarm = MBTab:CreateSection("🤖  Auto Farm")

    local imaToggle = MBTab:CreateToggle({
        Name         = "🔗  Imã de Caixas",
        CurrentValue = false,
        Flag         = "MB_ImaToggle",
        Callback     = function(state)
            if state then
                if not iniciarIma() then
                    -- Falhou: volta o toggle para false
                    task.wait(0.1)
                    Rayfield.Flags["MB_ImaToggle"]:Set(false)
                end
            else
                pararIma()
            end
        end,
    })

    MBTab:CreateKeybind({
        Name       = "⌨️  Atalho do Imã",
        CurrentKey = Enum.KeyCode.H,
        Flag       = "MB_ImaKeybind",
        Callback   = function()
            local cur = Rayfield.Flags["MB_ImaToggle"] and Rayfield.Flags["MB_ImaToggle"].Value or false
            Rayfield.Flags["MB_ImaToggle"]:Set(not cur)
        end,
    })

    local deliveryToggle
    deliveryToggle = MBTab:CreateToggle({
        Name         = "🚚  Auto Entrega (Farm)",
        CurrentValue = false,
        Flag         = "MB_DeliveryToggle",
        Callback     = function(state)
            if state then
                State.deliveryAtivo  = true
                State.deliveryThread = task.spawn(function()
                    local ok, err = pcall(deliveryLoop)
                    if not ok then
                        notify("⚠️ Auto Entrega", "Erro: " .. tostring(err):sub(1, 60), 6)
                    end
                    -- Garante que o toggle volte ao false quando o loop encerrar
                    task.wait(0.1)
                    pcall(function() Rayfield.Flags["MB_DeliveryToggle"]:Set(false) end)
                end)
                notify("🚚 Auto Entrega", "Iniciando ciclos...", 4)
            else
                State.deliveryAtivo = false
                if State.deliveryThread then
                    pcall(function() task.cancel(State.deliveryThread) end)
                    State.deliveryThread = nil
                end
                if State.imaAtivo then pararIma() end
                notify("🚚 Auto Entrega", "Parado.", 3)
            end
        end,
    })

    -- Para tudo ao respawnar
    player.CharacterAdded:Connect(function()
        if State.imaAtivo then
            pararIma()
            pcall(function() Rayfield.Flags["MB_ImaToggle"]:Set(false) end)
        end
        if State.deliveryAtivo then
            State.deliveryAtivo = false
            pcall(function() Rayfield.Flags["MB_DeliveryToggle"]:Set(false) end)
        end
    end)

    -- ── SEÇÃO: Teleportes ───────────────────────
    local SecTP = MBTab:CreateSection("📍  Teleportes")
    for _, dest in ipairs(TELEPORT_DESTINATIONS) do
        local capturedPos = dest.pos
        MBTab:CreateButton({
            Name     = dest.name,
            Callback = function() doTeleport(capturedPos) end,
        })
    end

    -- ── SEÇÃO: Perfis de Configuração ───────────
    local SecPerfis = MBTab:CreateSection("💾  Perfis de Configuração")

    local profileNameInput = MBTab:CreateInput({
        Name            = "Nome do Perfil",
        PlaceholderText = "Ex: corrida, drift, turbo...",
        Flag            = "MB_ProfileName",
        Callback        = function() end,
    })

    local profileDropdown = MBTab:CreateDropdown({
        Name     = "📂  Perfis Salvos",
        Options  = readIndex(),
        CurrentOption = "",
        Flag     = "MB_ProfileDropdown",
        Callback = function(selected)
            if type(selected) == "table" then selected = selected[1] end
            if not selected or selected == "" then return end
            if loadProfile(selected) then
                notify("📂 Perfil", "'" .. selected .. "' carregado!", 3)
                pcall(function() Rayfield.Flags["MB_ProfileName"]:Set(selected) end)
            else
                notify("⚠️ Erro", "Não foi possível carregar '" .. selected .. "'.", 4)
            end
        end,
    })

    local function refreshDropdown()
        local list = readIndex()
        pcall(function() profileDropdown:Refresh(list, "") end)
    end

    MBTab:CreateButton({
        Name     = "💾  Salvar Perfil",
        Callback = function()
            local flag = Rayfield.Flags["MB_ProfileName"]
            local name = flag and flag.Value or ""
            name = name:match("^%s*(.-)%s*$")
            if name == "" then
                notify("⚠️ Aviso", "Digite um nome para o perfil.", 3)
                return
            end
            if saveProfile(name) then
                notify("💾 Perfil", "'" .. name .. "' salvo!", 3)
                refreshDropdown()
            else
                notify("⚠️ Erro", "Falha ao salvar o perfil.", 4)
            end
        end,
    })

    MBTab:CreateButton({
        Name     = "🗑  Excluir Perfil",
        Callback = function()
            local flag = Rayfield.Flags["MB_ProfileName"]
            local name = flag and flag.Value or ""
            name = name:match("^%s*(.-)%s*$")
            if name == "" then
                notify("⚠️ Aviso", "Digite ou selecione um perfil.", 3)
                return
            end
            deleteProfile(name)
            notify("🗑 Perfil", "'" .. name .. "' excluído.", 3)
            pcall(function() Rayfield.Flags["MB_ProfileName"]:Set("") end)
            refreshDropdown()
        end,
    })
end -- fim ► MECÂNICA BRASILEIRA

-- ─────────────────────────────────────────────────
--  ► JOGO 2: [EM BREVE — Adicione aqui]
--  Para adicionar um novo jogo:
--  1. Copie o bloco "do...end" acima
--  2. Mude o nome da aba: Window:CreateTab("🎮  Nome do Jogo", iconId)
--  3. Adicione suas funções específicas do jogo dentro do bloco
-- ─────────────────────────────────────────────────
do
    local NextTab = Window:CreateTab("🎮  Em Breve", 4483362458)
    local SecInfo = NextTab:CreateSection("🔜  Próximo Jogo")

    NextTab:CreateParagraph({
        Title   = "🚧  Em Desenvolvimento",
        Content = "Este espaço está reservado para o próximo jogo suportado.\n\nPara adicionar suporte a um jogo, edite o script e copie o bloco '► JOGO 2' — basta criar uma nova aba e adicionar as funções específicas do jogo dentro do bloco do...end.",
    })
end

-- ─────────────────────────────────────────────────
--  ► ABA: CONFIGURAÇÕES GLOBAIS
-- ─────────────────────────────────────────────────
do
    local CfgTab = Window:CreateTab("⚙️  Configurações", 4483362458)

    -- Seção geral
    local SecGeral = CfgTab:CreateSection("🔧  Geral")

    CfgTab:CreateToggle({
        Name         = "♻️  Auto-Reaplicar Valores",
        CurrentValue = State.autoReapply,
        Flag         = "CFG_AutoReapply",
        Callback     = function(state)
            State.autoReapply = state
            if state then
                -- Reinstala listeners para todos os valores já aplicados
                for vname, val in pairs(_lastApplied) do
                    if _vconn[vname] then
                        pcall(function() _vconn[vname]:Disconnect() end)
                    end
                    local vn, vv = vname, val
                    _vconn[vn] = game.DescendantAdded:Connect(function(obj)
                        if obj:IsA("ValueBase") and obj.Name == vn then
                            task.defer(function() pcall(function() obj.Value = vv end) end)
                        end
                    end)
                end
                notify("♻️ Auto-Reaplicar", "Ativado.", 3)
            else
                for vname, conn in pairs(_vconn) do
                    pcall(function() conn:Disconnect() end)
                    _vconn[vname] = nil
                end
                notify("♻️ Auto-Reaplicar", "Desativado.", 3)
            end
        end,
    })

    CfgTab:CreateToggle({
        Name         = "🕵️  Modo Anônimo",
        CurrentValue = State.anonActive,
        Flag         = "CFG_AnonMode",
        Callback     = function(state)
            if state then enableAnon() else disableAnon() end
        end,
    })

    -- Seção de créditos
    local SecCredits = CfgTab:CreateSection("ℹ️  Sobre")

    CfgTab:CreateParagraph({
        Title   = "Universal Hub",
        Content = "Desenvolvido por AbyssBorn & Karfi Team.\n\n• Mecânica Brasileira: totalmente funcional\n• Imã de Caixas, Auto Entrega, Teleportes, Tune\n• Estrutura expansível: adicione novos jogos facilmente\n• Use a aba '🎮 Em Breve' como template para novos jogos",
    })
end

-- ═════════════════════════════════════════════════════════════════════
--  INICIALIZAÇÃO
-- ═════════════════════════════════════════════════════════════════════
task.wait(1)
Rayfield:LoadConfiguration()
print("🌐 Universal Hub | AbyssBorn | Carregado com sucesso!")
