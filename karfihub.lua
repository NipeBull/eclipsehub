[
    -- ════════════════════════════════════════════════════════════════════
--  KARFI HUB  v4.0  —  LocalScript
--  Organizado para melhor legibilidade. Funções e variáveis intactas.
-- ════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────
--  SERVIÇOS
-- ─────────────────────────────────────────────────

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local RunService    = game:GetService("RunService")
local player        = Players.LocalPlayer
local pGui          = player:WaitForChild("PlayerGui")


-- ─────────────────────────────────────────────────
--  FILESYSTEM SHIM
--  Usa rawget para não crashar no Velocity se
--  os globals não existirem.
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
--  PALETA DE CORES  (dark industrial)
-- ─────────────────────────────────────────────────

local P = {
    win      = Color3.fromRGB( 10,  10,  11),
    sidebar  = Color3.fromRGB( 10,  10,  11),
    row      = Color3.fromRGB( 24,  24,  29),
    rowHov   = Color3.fromRGB( 24,  24,  29),
    section  = Color3.fromRGB( 17,  17,  20),
    input    = Color3.fromRGB( 31,  31,  38),
    blue     = Color3.fromRGB(212, 255,   0),
    blueL    = Color3.fromRGB(234, 255,  80),
    cream    = Color3.fromRGB(240, 239, 234),
    textPri  = Color3.fromRGB(240, 239, 234),
    textSub  = Color3.fromRGB(156, 156, 168),
    textDim  = Color3.fromRGB( 90,  90, 104),
    divider  = Color3.fromRGB( 42,  42,  53),
    togOn    = Color3.fromRGB(212, 255,   0),
    togOff   = Color3.fromRGB( 31,  31,  38),
    success  = Color3.fromRGB( 57, 217, 138),
    err      = Color3.fromRGB(255,  68,  85),
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
    { name = "IgnitionTime",          label = "Avanço de Ignição" },
    { name = "AerodynamicEfficiency", label = "Aerodinâmica"      },
}


-- ─────────────────────────────────────────────────
--  DADOS — DESTINOS DE TELEPORTE
-- ─────────────────────────────────────────────────

local TELEPORT_DESTINATIONS = {
    { label = "Entrega",               pos = Vector3.new(-25672, 35, -5895) },
    { label = "Construção city 2",     pos = Vector3.new(-25220, 65, -5295) },
    { label = "Comet Auto Peças",      pos = Vector3.new( -3328, 65, -3407) },
    { label = "Concessionaria",        pos = Vector3.new( -3042, 65, -3692) },
    { label = "Construção Mectropoly", pos = Vector3.new( -3642, 65, -2506) },
    { label = "Junkyard/Ferro Velho",  pos = Vector3.new( -3125, 65, -4254) },
    { label = "Garagem",               pos = Vector3.new( -3375, 65, -2815) },
    { label = "Posto Mectropoly",      pos = Vector3.new( -3223, 65, -3713) },
    { label = "Valley Drag Race",      pos = Vector3.new( -3856, 65, -4901) },
}

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

local PICKUP_POS = Vector3.new(-25679, 32, -5879)


-- ════════════════════════════════════════════════════════════════════
--  CACHE DE VALUES
--  Indexa todos os ValueBase do jogo na inicialização e os mantém
--  atualizados via sinais. applyValue / applyTireValue fazem zero
--  scans na árvore do jogo.
-- ════════════════════════════════════════════════════════════════════

local _valueCache = {}   -- [name] = { obj, obj, ... }

local function _cacheAdd(obj)
    if not obj:IsA("ValueBase") then return end
    local n = obj.Name
    if not _valueCache[n] then _valueCache[n] = {} end
    for _, v in ipairs(_valueCache[n]) do
        if v == obj then return end   -- evita duplicatas
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

-- Popula o cache em lotes de 200 objetos por frame para não travar
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
--  HELPER — verifica se um objeto pertence ao player
-- ─────────────────────────────────────────────────

local function _isOwned(obj)
    local ownerVal =
        obj:FindFirstChild("Owner")
        or (obj.Parent and obj.Parent:FindFirstChild("Owner"))
        or (obj.Parent and obj.Parent.Parent
            and obj.Parent.Parent:FindFirstChild("Owner"))
        or (obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Parent
            and obj.Parent.Parent.Parent:FindFirstChild("Owner"))

    if not ownerVal then return true end   -- sem tag = assume nosso

    if ownerVal:IsA("ObjectValue") then
        return ownerVal.Value == player
            or (ownerVal.Value ~= nil and ownerVal.Value.Name == player.Name)
    elseif ownerVal:IsA("StringValue") then
        return ownerVal.Value == player.Name
    end

    return false
end


-- ─────────────────────────────────────────────────
--  APLICAR VALOR  (lookup no cache, sem scan)
-- ─────────────────────────────────────────────────

local _lastApplied = {}   -- [vname] = val  (usado pelo autoReapply)
local _vconn       = {}

local function applyValue(vname, val)
    _lastApplied[vname] = val

    -- Remove listener antigo de autoReapply
    if _vconn[vname] then
        pcall(function() _vconn[vname]:Disconnect() end)
        _vconn[vname] = nil
    end

    -- Aplica imediatamente via cache
    local list = _valueCache[vname]
    if list then
        for _, obj in ipairs(list) do
            pcall(function() obj.Value = val end)
        end
    end

    -- autoReapply: monitora novos objetos com esse nome
    if AF.autoReapply then
        _vconn[vname] = game.DescendantAdded:Connect(function(obj)
            if obj:IsA("ValueBase") and obj.Name == vname then
                task.defer(function() pcall(function() obj.Value = val end) end)
            end
        end)
    end
end


-- ─────────────────────────────────────────────────
--  APLICAR VALOR DE PNEU  (cache + ownership check)
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
        -- Cache miss: espera o objeto aparecer uma vez
        local conn
        conn = game.DescendantAdded:Connect(function(obj)
            if obj:IsA("ValueBase") and obj.Name == tireName then
                if _isOwned(obj) then
                    pcall(function() obj.Value = val end)
                end
                conn:Disconnect()
            end
        end)
        -- Auto-cleanup após 5s caso o objeto nunca apareça
        task.delay(5, function()
            pcall(function() conn:Disconnect() end)
        end)
    end
end


-- ════════════════════════════════════════════════════════════════════
--  HELPERS DE UI
-- ════════════════════════════════════════════════════════════════════

-- Tween simplificado
local function tw(o, props, t, sty, dir)
    TweenService:Create(
        o,
        TweenInfo.new(
            t   or .18,
            sty or Enum.EasingStyle.Quart,
            dir or Enum.EasingDirection.Out
        ),
        props
    ):Play()
end

-- Aplica UICorner
local function rnd(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 4)
    c.Parent = o
    return c
end

-- Aplica UIStroke (borda)
local function brdr(o, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color       = col or P.divider
    s.Thickness   = th  or 1
    s.Transparency= tr  or 0
    s.Parent      = o
    return s
end

-- Corner radius 100% (pílula)
local function pill(o)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = o
    return c
end


-- ─────────────────────────────────────────────────
--  REGISTRO DE TEMA
--  Permite que applyThemeData atualize objetos
--  da UI automaticamente ao trocar de tema.
-- ─────────────────────────────────────────────────

local _themeReg = {}

local function regC(obj, prop, key)
    table.insert(_themeReg, { obj = obj, prop = prop, key = key })
end

local function applyReg(entry)
    pcall(function()
        local val = P[entry.key]
        if val then entry.obj[entry.prop] = val end
    end)
end


-- ════════════════════════════════════════════════════════════════════
--  SCREENGUI  /  JANELA PRINCIPAL
-- ════════════════════════════════════════════════════════════════════

local SG = Instance.new("ScreenGui")
SG.Name            = "KarfiHub_v4"
SG.ResetOnSpawn    = false
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.Parent          = pGui

local WIN_W, WIN_H, SIDE_W = 700, 570, 165

local Win = Instance.new("Frame")
    Win.Name                = "Win"
    Win.Size                = UDim2.new(0, WIN_W, 0, WIN_H)
    Win.Position            = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
    Win.BackgroundColor3    = P.win
    Win.BackgroundTransparency = 0.0
    Win.BorderSizePixel     = 0
    Win.ClipsDescendants    = true
    Win.Parent              = SG
rnd(Win, 6)
brdr(Win, Color3.fromRGB(54, 54, 66), 1, 0)

local WallpaperFrame = Instance.new("Frame")
    WallpaperFrame.Name                    = "Wallpaper"
    WallpaperFrame.Size                    = UDim2.new(1, 0, 1, 0)
    WallpaperFrame.BackgroundColor3        = P.win
    WallpaperFrame.BackgroundTransparency  = 0
    WallpaperFrame.BorderSizePixel         = 0
    WallpaperFrame.ZIndex                  = 0
    WallpaperFrame.Parent                  = Win
rnd(WallpaperFrame, 6)


-- ─────────────────────────────────────────────────
--  BARRA SUPERIOR (TopBar)
-- ─────────────────────────────────────────────────

local TopBar = Instance.new("Frame")
    TopBar.Size                    = UDim2.new(1, 0, 0, 46)
    TopBar.BackgroundColor3        = P.win
    TopBar.BackgroundTransparency  = 0
    TopBar.BorderSizePixel         = 0
    TopBar.ZIndex                  = 20
    TopBar.Parent                  = Win
regC(TopBar, "BackgroundColor3", "win")

-- Frame interno que cobre a metade inferior (esconde o rnd da janela)
do
    local fix = Instance.new("Frame")
    fix.Size                    = UDim2.new(1, 0, 0.5, 0)
    fix.Position                = UDim2.new(0, 0, 0.5, 0)
    fix.BackgroundColor3        = P.win
    fix.BackgroundTransparency  = 0
    fix.BorderSizePixel         = 0
    fix.ZIndex                  = 19
    fix.Parent                  = TopBar
end

-- Logo "K"
local LogoMark = Instance.new("Frame")
    LogoMark.Name             = "LogoMark"
    LogoMark.Size             = UDim2.new(0, 26, 0, 26)
    LogoMark.Position         = UDim2.new(0, 12, 0.5, -13)
    LogoMark.BackgroundColor3 = P.blue
    LogoMark.BorderSizePixel  = 0
    LogoMark.ZIndex           = 21
    LogoMark.Parent           = TopBar
regC(LogoMark, "BackgroundColor3", "blue")

local LogoK = Instance.new("TextLabel")
    LogoK.Text                 = "K"
    LogoK.Size                 = UDim2.new(1, 0, 1, 0)
    LogoK.BackgroundTransparency = 1
    LogoK.TextColor3           = Color3.fromRGB(10, 10, 11)
    LogoK.TextSize             = 16
    LogoK.Font                 = Enum.Font.GothamBlack
    LogoK.TextXAlignment       = Enum.TextXAlignment.Center
    LogoK.ZIndex               = 22
    LogoK.Parent               = LogoMark

-- Nome e versão
local HubName = Instance.new("TextLabel")
    HubName.Text               = "KARFI HUB"
    HubName.Size               = UDim2.new(0, 130, 0, 18)
    HubName.Position           = UDim2.new(0, 46, 0, 8)
    HubName.BackgroundTransparency = 1
    HubName.TextColor3         = P.textPri
    HubName.TextSize           = 14
    HubName.Font               = Enum.Font.GothamBlack
    HubName.TextXAlignment     = Enum.TextXAlignment.Left
    HubName.ZIndex             = 21
    HubName.Parent             = TopBar
regC(HubName, "TextColor3", "textPri")

local HubSub = Instance.new("TextLabel")
    HubSub.Text                = "v4.0  · Made By KARFI HUB TEAM "
    HubSub.Size                = UDim2.new(0, 200, 0, 12)
    HubSub.Position            = UDim2.new(0, 46, 0, 27)
    HubSub.BackgroundTransparency = 1
    HubSub.TextColor3          = P.textDim
    HubSub.TextSize            = 10
    HubSub.Font                = Enum.Font.Gotham
    HubSub.TextXAlignment      = Enum.TextXAlignment.Left
    HubSub.ZIndex              = 21
    HubSub.Parent              = TopBar
regC(HubSub, "TextColor3", "textDim")

-- Badge da tecla de toggle
local KeyBadge = Instance.new("TextLabel")
    KeyBadge.Name             = "KeyBadge"
    KeyBadge.Text             = "RShift"
    KeyBadge.Size             = UDim2.new(0, 60, 0, 22)
    KeyBadge.Position         = UDim2.new(1, -148, 0, 12)
    KeyBadge.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    KeyBadge.TextColor3       = P.blue
    KeyBadge.TextSize         = 10
    KeyBadge.Font             = Enum.Font.GothamBold
    KeyBadge.BorderSizePixel  = 0
    KeyBadge.ZIndex           = 22
    KeyBadge.Parent           = TopBar
rnd(KeyBadge, 2)
brdr(KeyBadge, P.blue, 1, 0.4)

-- Botões de janela (minimizar / fechar)
local function makeWinBtn(icon, xOff, clickFn)
    local b = Instance.new("TextButton")
        b.Text                 = icon
        b.Size                 = UDim2.new(0, 22, 0, 22)
        b.Position             = UDim2.new(1, xOff, 0, 12)
        b.BackgroundColor3     = Color3.fromRGB(26, 26, 31)
        b.BackgroundTransparency = 0.2
        b.TextColor3           = P.textDim
        b.TextSize             = 11
        b.Font                 = Enum.Font.GothamBold
        b.BorderSizePixel      = 0
        b.ZIndex               = 22
        b.Parent               = TopBar
    rnd(b, 2)

    b.MouseEnter:Connect(function()
        tw(b, { BackgroundTransparency = 0, TextColor3 = P.textPri })
    end)
    b.MouseLeave:Connect(function()
        tw(b, { BackgroundTransparency = 0.2, TextColor3 = P.textDim })
    end)
    b.MouseButton1Click:Connect(clickFn)
end

-- Minimizar
makeWinBtn("–", -84, function()
    AF.guiOpen = false
    tw(Win, { Size = UDim2.new(0, WIN_W, 0, 0) }, .25,
        Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(.22, function()
        if not AF.guiOpen then Win.Visible = false end
    end)
end)

-- Fechar
makeWinBtn("x", -58, function()
    Win.Visible = false
    AF.guiOpen  = false
end)

-- Linha divisória do TopBar
local TBLine = Instance.new("Frame")
    TBLine.Size             = UDim2.new(1, 0, 0, 1)
    TBLine.Position         = UDim2.new(0, 0, 1, -1)
    TBLine.BackgroundColor3 = P.divider
    TBLine.BackgroundTransparency = 0
    TBLine.BorderSizePixel  = 0
    TBLine.ZIndex           = 20
    TBLine.Parent           = TopBar


-- ─────────────────────────────────────────────────
--  SIDEBAR
-- ─────────────────────────────────────────────────

local Sidebar = Instance.new("Frame")
    Sidebar.Name                   = "Sidebar"
    Sidebar.Size                   = UDim2.new(0, SIDE_W, 1, -46)
    Sidebar.Position               = UDim2.new(0, 0, 0, 46)
    Sidebar.BackgroundColor3       = P.win
    Sidebar.BackgroundTransparency = 0
    Sidebar.BorderSizePixel        = 0
    Sidebar.ZIndex                 = 10
    Sidebar.Parent                 = Win
regC(Sidebar, "BackgroundColor3", "win")

local SBLine = Instance.new("Frame")
    SBLine.Size             = UDim2.new(0, 1, 1, 0)
    SBLine.Position         = UDim2.new(1, -1, 0, 0)
    SBLine.BackgroundColor3 = P.divider
    SBLine.BorderSizePixel  = 0
    SBLine.ZIndex           = 11
    SBLine.Parent           = Sidebar

local SideLabel = Instance.new("TextLabel")
    SideLabel.Text                 = "MENU"
    SideLabel.Size                 = UDim2.new(1, -16, 0, 14)
    SideLabel.Position             = UDim2.new(0, 12, 0, 12)
    SideLabel.BackgroundTransparency = 1
    SideLabel.TextColor3           = P.textDim
    SideLabel.TextSize             = 9
    SideLabel.Font                 = Enum.Font.GothamBold
    SideLabel.TextXAlignment       = Enum.TextXAlignment.Left
    SideLabel.ZIndex               = 11
    SideLabel.Parent               = Sidebar

local NavList = Instance.new("Frame")
    NavList.Size                   = UDim2.new(1, 0, 1, -80)
    NavList.Position               = UDim2.new(0, 0, 0, 30)
    NavList.BackgroundTransparency = 1
    NavList.BorderSizePixel        = 0
    NavList.ZIndex                 = 11
    NavList.Parent                 = Sidebar
do
    local l = Instance.new("UIListLayout")
        l.Padding    = UDim.new(0, 0)
        l.SortOrder  = Enum.SortOrder.LayoutOrder
        l.Parent     = NavList

    local p = Instance.new("UIPadding")
        p.PaddingLeft  = UDim.new(0, 0)
        p.PaddingRight = UDim.new(0, 0)
        p.PaddingTop   = UDim.new(0, 2)
        p.Parent       = NavList
end

-- Rodapé da sidebar (nome do player)
local SBBottom = Instance.new("Frame")
    SBBottom.Size                   = UDim2.new(1, 0, 0, 44)
    SBBottom.Position               = UDim2.new(0, 0, 1, -44)
    SBBottom.BackgroundColor3       = P.win
    SBBottom.BackgroundTransparency = 0
    SBBottom.BorderSizePixel        = 0
    SBBottom.ZIndex                 = 11
    SBBottom.Parent                 = Sidebar

local SBBottomLine = Instance.new("Frame")
    SBBottomLine.Size             = UDim2.new(1, 0, 0, 1)
    SBBottomLine.BackgroundColor3 = P.divider
    SBBottomLine.BorderSizePixel  = 0
    SBBottomLine.ZIndex           = 12
    SBBottomLine.Parent           = SBBottom

local SBDot = Instance.new("Frame")
    SBDot.Size             = UDim2.new(0, 6, 0, 6)
    SBDot.Position         = UDim2.new(0, 12, 0.5, -3)
    SBDot.BackgroundColor3 = P.blue   -- era P.success (verde); agora usa accent do tema
    SBDot.BorderSizePixel  = 0
    SBDot.ZIndex           = 12
    SBDot.Parent           = SBBottom
pill(SBDot)

local SBPlayerName = Instance.new("TextLabel")
    SBPlayerName.Text                 = player.Name
    SBPlayerName.Size                 = UDim2.new(1, -26, 1, 0)
    SBPlayerName.Position             = UDim2.new(0, 24, 0, 0)
    SBPlayerName.BackgroundTransparency = 1
    SBPlayerName.TextColor3           = P.textSub
    SBPlayerName.TextSize             = 11
    SBPlayerName.Font                 = Enum.Font.GothamBold
    SBPlayerName.TextXAlignment       = Enum.TextXAlignment.Left
    SBPlayerName.ZIndex               = 12
    SBPlayerName.Parent               = SBBottom


-- ─────────────────────────────────────────────────
--  ÁREA DE CONTEÚDO
-- ─────────────────────────────────────────────────

local Content = Instance.new("Frame")
    Content.Name                   = "Content"
    Content.Size                   = UDim2.new(1, -SIDE_W, 1, -46)
    Content.Position               = UDim2.new(0, SIDE_W, 0, 46)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel        = 0
    Content.ZIndex                 = 5
    Content.Parent                 = Win


-- ─────────────────────────────────────────────────
--  BARRA DE STATUS
-- ─────────────────────────────────────────────────

local StatBar = Instance.new("Frame")
    StatBar.Size             = UDim2.new(1, 0, 0, 28)
    StatBar.Position         = UDim2.new(0, 0, 1, -28)
    StatBar.BackgroundColor3 = P.win
    StatBar.BackgroundTransparency = 0
    StatBar.BorderSizePixel  = 0
    StatBar.ZIndex           = 15
    StatBar.Parent           = Content

local StatLine = Instance.new("Frame")
    StatLine.Size             = UDim2.new(1, 0, 0, 1)
    StatLine.BackgroundColor3 = P.divider
    StatLine.BorderSizePixel  = 0
    StatLine.ZIndex           = 16
    StatLine.Parent           = StatBar

local StatDot = Instance.new("Frame")
    StatDot.Size             = UDim2.new(0, 5, 0, 5)
    StatDot.Position         = UDim2.new(0, 10, 0.5, -2)
    StatDot.BackgroundColor3 = P.blue
    StatDot.BorderSizePixel  = 0
    StatDot.ZIndex           = 16
    StatDot.Parent           = StatBar
pill(StatDot)

local StatSep = Instance.new("Frame")
    StatSep.Size             = UDim2.new(0, 1, 0, 12)
    StatSep.Position         = UDim2.new(0, 22, 0.5, -6)
    StatSep.BackgroundColor3 = P.divider
    StatSep.BorderSizePixel  = 0
    StatSep.ZIndex           = 16
    StatSep.Parent           = StatBar

local StatLbl = Instance.new("TextLabel")
    StatLbl.Text               = "Pronto"
    StatLbl.Size               = UDim2.new(0.5, -30, 1, 0)
    StatLbl.Position           = UDim2.new(0, 28, 0, 0)
    StatLbl.BackgroundTransparency = 1
    StatLbl.TextColor3         = P.textDim
    StatLbl.TextSize           = 10
    StatLbl.Font               = Enum.Font.GothamBold
    StatLbl.TextXAlignment     = Enum.TextXAlignment.Left
    StatLbl.ZIndex             = 16
    StatLbl.Parent             = StatBar

local StatVersion = Instance.new("TextLabel")
    StatVersion.Text               = "KARFI HUB v4"
    StatVersion.Size               = UDim2.new(0.5, -10, 1, 0)
    StatVersion.Position           = UDim2.new(0.5, 0, 0, 0)
    StatVersion.BackgroundTransparency = 1
    StatVersion.TextColor3         = P.textDim
    StatVersion.TextSize           = 10
    StatVersion.Font               = Enum.Font.GothamBold
    StatVersion.TextXAlignment     = Enum.TextXAlignment.Right
    StatVersion.ZIndex             = 16
    StatVersion.Parent             = StatBar

-- Exibe uma mensagem na barra de status por 3.5s
local function setStatus(msg, col)
    if not AF.statusEnabled then 
        return 
    end
    
    StatLbl.Text       = msg
    StatLbl.TextColor3 = col or P.textDim
    
    tw(StatDot, { 
        BackgroundColor3 = col or P.blue 
    })
    task.delay(3.5, function()
        if StatLbl.Text == msg then
            StatLbl.Text       = "Pronto"
            StatLbl.TextColor3 = P.textDim
            tw(StatDot, { 
                BackgroundColor3 = P.blue 
            })
        end
    end)
end


-- ════════════════════════════════════════════════════════════════════
--  INFOBOX  (notificação flutuante no canto superior direito)
-- ════════════════════════════════════════════════════════════════════

local IB_W, IB_H = 300, 72

local InfoBox = Instance.new("Frame")
    InfoBox.Name             = "InfoBox"
    InfoBox.Size             = UDim2.new(0, IB_W, 0, IB_H)
    InfoBox.Position         = UDim2.new(1, -(IB_W+16), 0, -(IB_H+10))
    InfoBox.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
    InfoBox.BackgroundTransparency = 0
    InfoBox.BorderSizePixel  = 0
    InfoBox.ZIndex           = 100
    InfoBox.Visible          = false
    InfoBox.Parent           = SG
rnd(InfoBox, 4)
local IBStroke              = brdr(InfoBox, P.blue, 1, 0.3)

local IBIconCircle = Instance.new("Frame")
    IBIconCircle.Size                   = UDim2.new(0, 32, 0, 32)
    IBIconCircle.Position               = UDim2.new(0, IB_H/2 - 16, 0.5, -16)
    IBIconCircle.BackgroundColor3       = P.blue
    IBIconCircle.BackgroundTransparency = 0.2
    IBIconCircle.BorderSizePixel        = 0
    IBIconCircle.ZIndex                 = 101
    IBIconCircle.Parent                 = InfoBox
regC(IBIconCircle, "BackgroundColor3", "blue")
rnd(IBIconCircle, 4)

local IBIcon = Instance.new("TextLabel")
    IBIcon.Text                 = ""
    IBIcon.Size                 = UDim2.new(1, 0, 1, 0)
    IBIcon.BackgroundTransparency = 1
    IBIcon.TextColor3           = Color3.fromRGB(255, 255, 255)
    IBIcon.TextSize             = 14
    IBIcon.Font                 = Enum.Font.GothamBold
    IBIcon.TextXAlignment       = Enum.TextXAlignment.Center
    IBIcon.ZIndex               = 102
    IBIcon.Parent               = IBIconCircle

local TEXT_X = IB_H/2 + 26
local TEXT_W = -(TEXT_X + IB_H/2 + 4)

local IBLabel = Instance.new("TextLabel")
    IBLabel.Name               = "IBLabel"
    IBLabel.Text               = ""
    IBLabel.Size               = UDim2.new(1, TEXT_W, 0, 17)
    IBLabel.Position           = UDim2.new(0, TEXT_X, 0, 19)
    IBLabel.BackgroundTransparency = 1
    IBLabel.TextColor3         = P.textPri
    IBLabel.TextSize           = 13
    IBLabel.Font               = Enum.Font.GothamBold
    IBLabel.TextXAlignment     = Enum.TextXAlignment.Left
    IBLabel.TextTruncate       = Enum.TextTruncate.AtEnd
    IBLabel.ZIndex             = 101
    IBLabel.Parent             = InfoBox
regC(IBLabel, "TextColor3", "textPri")

local IBValue = Instance.new("TextLabel")
    IBValue.Name               = "IBValue"
    IBValue.Text               = ""
    IBValue.Size               = UDim2.new(1, TEXT_W, 0, 13)
    IBValue.Position           = UDim2.new(0, TEXT_X, 0, 40)
    IBValue.BackgroundTransparency = 1
    IBValue.TextColor3         = P.blueL
    IBValue.TextSize           = 11
    IBValue.Font               = Enum.Font.GothamBold
    IBValue.TextXAlignment     = Enum.TextXAlignment.Left
    IBValue.ZIndex             = 101
    IBValue.Parent             = InfoBox
regC(IBValue, "TextColor3", "blueL")

-- Barra de progresso do timer da InfoBox
local IBBarBg = Instance.new("Frame")
    IBBarBg.Size             = UDim2.new(1, -IB_H, 0, 3)
    IBBarBg.Position         = UDim2.new(0, IB_H/2, 1, -6)
    IBBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    IBBarBg.BorderSizePixel  = 0
    IBBarBg.ZIndex           = 101
    IBBarBg.Parent           = InfoBox
rnd(IBBarBg, 2)

local IBBar = Instance.new("Frame")
    IBBar.Name             = "IBBar"
    IBBar.Size             = UDim2.new(1, 0, 1, 0)
    IBBar.BackgroundColor3 = P.blue
    IBBar.BorderSizePixel  = 0
    IBBar.ZIndex           = 102
    IBBar.Parent           = IBBarBg
regC(IBBar, "BackgroundColor3", "blue")
rnd(IBBar, 2)

-- Helper: verifica se o carro do player está spawnado
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

local ibGeneration  = 0
local POS_HIDDEN    = UDim2.new(1, -(IB_W+16), 0, -(IB_H+10))
local POS_SHOWN     = UDim2.new(1, -(IB_W+16), 0,  16)

-- Exibe a InfoBox com texto e barra de progresso animada
local function showInfoBox(labelText, valueText, isError)
    local duration  = isError and 3 or 4
    local accentCol = isError and P.err  or P.blue
    local iconText  = isError and ""   or ""

    IBLabel.Text              = labelText
    IBValue.Text              = isError and "" or ("Valor definido:  " .. tostring(valueText))
    IBValue.TextColor3        = isError and P.err or P.blueL
    IBIcon.Text               = iconText
    IBIconCircle.BackgroundColor3 = accentCol
    IBBar.BackgroundColor3    = accentCol
    InfoBox.BackgroundColor3  = isError
        and Color3.fromRGB(22, 10, 12)
        or  Color3.fromRGB(17, 17, 20)

    local stroke = InfoBox:FindFirstChildWhichIsA("UIStroke")
    if stroke then tw(stroke, { Color = accentCol }) end

    IBBar.Size     = UDim2.new(1, 0, 1, 0)
    ibGeneration   = ibGeneration + 1
    local myGen    = ibGeneration

    InfoBox.Position = POS_HIDDEN
    InfoBox.Visible  = true
    tw(InfoBox, { 
        Position = POS_SHOWN 
    }, 
        0.3, 
        Enum.EasingStyle.Back, 
        Enum.EasingDirection.Out
    )
    tw(IBBar,   { 
        Size = UDim2.new(0, 0, 1, 0)
    }, 
        duration, 
        Enum.EasingStyle.Linear
    )

    task.spawn(function()

        task.wait(duration)

        if ibGeneration ~= myGen then 
            return 
        end

        local t = TweenService:Create(
            InfoBox,
            TweenInfo.new(0.3, 
            Enum.EasingStyle.Quart, 
            Enum.EasingDirection.In
        ),
            { Position = POS_HIDDEN }
        )
        t:Play()

        t.Completed:Connect(function() 
            InfoBox.Visible = false 
        end)
    end)
end

-- Botão invisível para fechar a InfoBox ao clicar
local ibBtn = Instance.new("TextButton")
    ibBtn.Size                 = UDim2.new(1, 0, 1, 0)
    ibBtn.BackgroundTransparency = 1
    ibBtn.Text                 = ""
    ibBtn.ZIndex               = 103
    ibBtn.Parent               = InfoBox
    ibBtn.MouseButton1Click:Connect(function()

        ibGeneration = ibGeneration + 1

        local t2 = TweenService:Create(
            InfoBox,
            TweenInfo.new(0.2, 
            Enum.EasingStyle.Quart, 
            Enum.EasingDirection.In
        ),
            { Position = POS_HIDDEN }
        )
        t2:Play()

        t2.Completed:Connect(function() 
            InfoBox.Visible = false 
        end)
    end)

-- Host do conteúdo das páginas (excluindo a barra de status)
local PHost = Instance.new("Frame")
    PHost.Name                   = "PHost"
    PHost.Size                   = UDim2.new(1, 0, 1, -28)
    PHost.BackgroundTransparency = 1
    PHost.BorderSizePixel        = 0
    PHost.ZIndex                 = 6
    PHost.Parent                 = Content


-- ════════════════════════════════════════════════════════════════════
--  SISTEMA DE ABAS
-- ════════════════════════════════════════════════════════════════════

local navBtns = {}
local pages   = {}

local NAV = {
    { id = "Tune",     label = "Tune",     icon = "⚙" },
    { id = "Misc",     label = "Misc",     icon = "≡" },
    { id = "AutoFarm", label = "AutoFarm", icon = "↺" },
    { id = "TP",       label = "TP",       icon = "→" },
    { id = "Config",   label = "Config",   icon = "✦" },
}

-- Cria uma ScrollingFrame para cada aba
local function makePage(id)
    local pg = Instance.new("ScrollingFrame")
        pg.Name                 = id
        pg.Size                 = UDim2.new(1, 0, 1, 0)
        pg.BackgroundTransparency = 1
        pg.BorderSizePixel      = 0
        pg.ScrollBarThickness   = 2
        pg.ScrollBarImageColor3 = P.blue
        pg.ScrollingDirection   = Enum.ScrollingDirection.Y
        pg.CanvasSize           = UDim2.new(0, 0, 0, 0)
        pg.AutomaticCanvasSize  = Enum.AutomaticSize.Y
        pg.Visible              = false
        pg.ZIndex               = 7
        pg.Parent               = PHost

    local ul = Instance.new("UIListLayout")
        ul.Padding             = UDim.new(0, 0)
        ul.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ul.Parent              = pg

    pages[id] = pg
    return pg
end

-- Troca a aba ativa
local function switchTab(id)
    if AF.activeTab == id then return end

    pages[AF.activeTab].Visible = false
    local old = navBtns[AF.activeTab]
    if old then
        tw(old.bg,  { BackgroundTransparency = 1 })
        tw(old.lbl, { TextColor3 = P.textSub })
        old.bar.BackgroundTransparency = 1
    end

    AF.activeTab         = id
    pages[id].Visible    = true
    local nb             = navBtns[id]
    if nb then
        tw(nb.bg,  { BackgroundTransparency = 0 })
        tw(nb.lbl, { TextColor3 = P.textPri })
        nb.bar.BackgroundTransparency = 0
    end
end

-- Cria um botão na sidebar para cada aba
local function makeNavBtn(item, order)
    local btn = Instance.new("TextButton")
        btn.Name                 = item.id
        btn.Size                 = UDim2.new(1, 0, 0, 38)
        btn.BackgroundTransparency = 1
        btn.TextTransparency     = 1
        btn.BorderSizePixel      = 0
        btn.ZIndex               = 12
        btn.LayoutOrder          = order or 0
        btn.Parent               = NavList

    local bg = Instance.new("Frame")
        bg.Name             = "bg"
        bg.Size             = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
        bg.BackgroundTransparency = 1
        bg.BorderSizePixel  = 0
        bg.ZIndex           = 12
        bg.Parent           = btn

    local bar = Instance.new("Frame")
        bar.Name             = "bar"
        bar.Size             = UDim2.new(0, 2, 1, 0)
        bar.Position         = UDim2.new(0, 0, 0, 0)
        bar.BackgroundColor3 = P.blue
        bar.BackgroundTransparency = 1
        bar.BorderSizePixel  = 0
        bar.ZIndex           = 13
        bar.Parent           = btn

    local lbl = Instance.new("TextLabel")
        lbl.Name               = "lbl"
        lbl.Text               = item.label
        lbl.Size               = UDim2.new(1, -16, 1, 0)
        lbl.Position           = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3         = P.textSub
        lbl.TextSize           = 12
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextXAlignment     = Enum.TextXAlignment.Left
        lbl.ZIndex             = 13
        lbl.Parent             = btn

    navBtns[item.id] = { btn = btn, bg = bg, lbl = lbl, bar = bar }

    btn.MouseEnter:Connect(function()
        if AF.activeTab ~= item.id then
            tw(bg,  { BackgroundTransparency = 0.6 })
            tw(lbl, { TextColor3 = P.textPri })
        end
    end)
    btn.MouseLeave:Connect(function()
        if AF.activeTab ~= item.id then
            tw(bg,  { BackgroundTransparency = 1 })
            tw(lbl, { TextColor3 = P.textSub })
        end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(item.id) end)
end

-- Instancia todas as páginas e botões
for i, item in ipairs(NAV) do
    makePage(item.id)
    makeNavBtn(item, i)
end

-- Ativa a aba "Misc" por padrão
pages["Misc"].Visible                      = true
navBtns["Misc"].bg.BackgroundTransparency  = 0
navBtns["Misc"].lbl.TextColor3             = P.textPri
navBtns["Misc"].bar.BackgroundTransparency = 0


-- ════════════════════════════════════════════════════════════════════
--  COMPONENTES REUTILIZÁVEIS DE UI
-- ════════════════════════════════════════════════════════════════════

-- Cabeçalho de seção com linha accent colorida
local function makeSectionHeader(page, title, sub)
    local hdr = Instance.new("Frame")
        hdr.Size             = UDim2.new(1, 0, 0, 62)
        hdr.BackgroundColor3 = P.section
        hdr.BackgroundTransparency = 0
        hdr.BorderSizePixel  = 0
        hdr.ZIndex           = 8
        hdr.Parent           = page
    regC(hdr, "BackgroundColor3", "section")

    local accent = Instance.new("Frame")
        accent.Size             = UDim2.new(0, 3, 1, 0)
        accent.Position         = UDim2.new(0, 0, 0, 0)
        accent.BackgroundColor3 = P.blue
        accent.BorderSizePixel  = 0
        accent.ZIndex           = 9
        accent.Parent           = hdr

    regC(accent, 
    "BackgroundColor3", 
    "blue"
)

    local t = Instance.new("TextLabel")
        t.Text               = string.upper(title)
        t.Size               = UDim2.new(1, -20, 0, 22)
        t.Position           = UDim2.new(0, 14, 0, 10)
        t.BackgroundTransparency = 1
        t.TextColor3         = P.textPri
        t.TextSize           = 15
        t.Font               = Enum.Font.GothamBlack
        t.TextXAlignment     = Enum.TextXAlignment.Left
        t.ZIndex             = 9
        t.Parent             = hdr

    regC(t, 
    "TextColor3", 
    "textPri"
)

    local s = Instance.new("TextLabel")
        s.Text               = sub
        s.Size               = UDim2.new(1, -20, 0, 14)
        s.Position           = UDim2.new(0, 14, 0, 34)
        s.BackgroundTransparency = 1
        s.TextColor3         = P.textDim
        s.TextSize           = 10
        s.Font               = Enum.Font.Gotham
        s.TextXAlignment     = Enum.TextXAlignment.Left
        s.ZIndex             = 9
        s.Parent             = hdr
    regC(s, 
    "TextColor3",
    "textDim"
)

    local div = Instance.new("Frame")
        div.Size             = UDim2.new(1, 0, 0, 1)
        div.Position         = UDim2.new(0, 0, 1, -1)
        div.BackgroundColor3 = P.divider
        div.BorderSizePixel  = 0
        div.ZIndex           = 9
        div.Parent           = hdr

    regC(div, 
    "BackgroundColor3", 
    "divider"
)
end

-- Linha de valor numérico com campo de input e botão SET
local inputRefs = {}

local function makeValueRow(page, cfg)
    local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = P.rowHov
        row.BackgroundTransparency = 1
        row.BorderSizePixel  = 0
        row.ZIndex           = 8
        row.Parent           = page
    regC(row, 
    "BackgroundColor3", 
    "rowHov"
)

    row.MouseEnter:Connect(function() 
        tw(row, 
        { 
            BackgroundTransparency = 0 
        },    
        0.12
    ) 
end)

    row.MouseEnter:Connect(function() 
        tw(row, 
        { 
            BackgroundTransparency = 1 
        },    
        0.15
    ) 
end)

    local lbl = Instance.new("TextLabel")
        lbl.Text               = cfg.label
        lbl.Size               = UDim2.new(0, 200, 0, 18)
        lbl.Position           = UDim2.new(0, 14, 0, 9)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3         = P.textPri
        lbl.TextSize           = 13
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextXAlignment     = Enum.TextXAlignment.Left
        lbl.ZIndex             = 9
        lbl.Parent             = row

    regC(lbl, 
        "TextColor3", 
        "textPri"
    )

    local sub = Instance.new("TextLabel")
        sub.Text               = ""
        sub.Size               = UDim2.new(0, 200, 0, 13)
        sub.Position           = UDim2.new(0, 14, 0, 28)
        sub.BackgroundTransparency = 1
        sub.TextColor3         = P.textDim
        sub.TextSize           = 10
        sub.Font               = Enum.Font.Gotham
        sub.TextXAlignment     = Enum.TextXAlignment.Left
        sub.ZIndex             = 9
        sub.Parent             = row
        
    regC(sub, 
        "TextColor3", 
        "textDim"
    )

    local inpF = Instance.new("Frame")
        inpF.Size             = UDim2.new(0, 96, 0, 30)
        inpF.Position         = UDim2.new(1, -158, 0.5, -15)
        inpF.BackgroundColor3 = P.input
        inpF.BorderSizePixel  = 0
        inpF.ZIndex           = 9
        inpF.Parent           = row

    rnd(inpF, 2)
    regC(inpF, 
        "BackgroundColor3", 
        "input"
    )

    local inpS = brdr(inpF, P.divider, 1)
    regC(inpS, 
        "Color", 
        "divider"
    )

    local inp = Instance.new("TextBox")
        inp.PlaceholderText    = cfg.placeholder or "valor..."
        inp.Text               = ""
        inp.Size               = UDim2.new(1, -8, 1, 0)
        inp.Position           = UDim2.new(0, 6, 0, 0)
        inp.BackgroundTransparency = 1
        inp.TextColor3         = P.textPri
        inp.PlaceholderColor3  = P.textDim
        inp.TextSize           = 12
        inp.Font               = Enum.Font.Gotham
        inp.ClearTextOnFocus   = false
        inp.BorderSizePixel    = 0
        inp.ZIndex             = 10
        inp.Parent             = inpF
    regC(inp, 
        "TextColor3",        
        "textPri"
    )
    regC(inp, 
        "PlaceholderColor3", 
        "textDim"
    )

    inp.Focused:Connect(function()   
        tw(inpS, 
        { 
            Color = P.blue    
        }) 
    end)
    inp.FocusLost:Connect(function() 
        tw(inpS, 
        { 
            Color = P.divider 
        }) 
    end)

    local setBtn = Instance.new("TextButton")
        setBtn.Text             = "SET"
        setBtn.Size             = UDim2.new(0, 50, 0, 30)
        setBtn.Position         = UDim2.new(1, -54, 0.5, -15)
        setBtn.BackgroundColor3 = P.blue
        setBtn.BorderSizePixel  = 0
        setBtn.TextColor3       = Color3.fromRGB(10, 10, 11)
        setBtn.TextSize         = 11
        setBtn.Font             = Enum.Font.GothamBold
        setBtn.ZIndex           = 10
        setBtn.Parent           = row
    rnd(setBtn, 2)
    regC(setBtn, 
        "BackgroundColor3", 
        "blue"
    )

    setBtn.MouseEnter:Connect(function() 
        tw(setBtn, 
        {   
            BackgroundColor3 = P.blueL 
        }, 0.12
    ) 
    end)
    setBtn.MouseLeave:Connect(function() 
        tw(setBtn, 
        { 
            BackgroundColor3 = P.blue  
        }, 0.12
    ) 
end)

    local div = Instance.new("Frame")
        div.Size                   = UDim2.new(1, 0, 0, 1)
        div.Position               = UDim2.new(0, 0, 1, -1)
        div.BackgroundColor3       = P.divider
        div.BackgroundTransparency = 0
        div.BorderSizePixel        = 0
        div.ZIndex                 = 8
        div.Parent                 = row
    regC(div, 
        "BackgroundColor3", 
        "divider"
    )

    -- Lógica de aplicação do valor
    local function doApply()
        local n = tonumber(inp.Text)
        if not n then
            setStatus("X  Invalido: " .. cfg.label, P.err)
            return
        end

        if cfg.min ~= nil and n < cfg.min then 
            n = cfg.min; inp.Text = tostring(n) 
        end
        if cfg.max ~= nil and n > cfg.max then 
            n = cfg.max; inp.Text = tostring(n) 
        end

        if not carSpawned() then
            setStatus("X  Carro nao spawnado", P.err)
            showInfoBox("Seu carro nao esta spawnado", "", true)
            return
        end

        applyValue(cfg.name, n)
        setStatus("OK  " .. cfg.label .. "  ->  " .. n, P.success)
        tw(inpS,   
        { 
            Color = P.success 
        })
        tw(setBtn, 
        { 
            BackgroundColor3 = P.success, 
            TextColor3 = Color3.fromRGB(10, 10, 11) 
        })

        task.delay(2, function()
            tw(inpS,   
            { 
                Color = P.divider 
            })

            tw(setBtn, 
            { 
                BackgroundColor3 = P.blue, 
                TextColor3 = Color3.fromRGB(10, 10, 11) 
            })
        end)

        showInfoBox(cfg.label, n)
    end

    setBtn.MouseButton1Click:Connect(doApply)
    inp.FocusLost:Connect(function(e) 
        if e then doApply() 
        end
    end)

    inputRefs[cfg.name] = { inp = inp }
end

-- Botão "Aplicar Todos" para um grupo de valores
local function makeApplyAllRow(page, label, valueList)
    local row = Instance.new("Frame")
        
        row.BackgroundTransparency = 1
        row.BorderSizePixel        = 0
        row.ZIndex                 = 8
        row.Parent                 = page

    local btn = Instance.new("TextButton")
        btn.Text             = label
        btn.Size             = UDim2.new(1, -20, 0, 34)
        btn.Position         = UDim2.new(0, 10, 0.5, -17)
        btn.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
        btn.BorderSizePixel  = 0
        btn.TextColor3       = P.blue
        btn.TextSize         = 12
        btn.Font             = Enum.Font.GothamBold
        btn.ZIndex           = 9
        btn.Parent           = row

    rnd(btn, 2)
    local applyAllStroke = brdr(btn, P.divider, 1, 0)

    regC(btn,            
        "TextColor3", 
        "blue"
    )
    regC(applyAllStroke, 
        "Color",      
        "divider"
    )

    btn.MouseEnter:Connect(function()
        tw(btn, 
        { 
            BackgroundColor3 = Color3.fromRGB(24, 24, 29), 
            TextColor3 = P.blueL 
        })

        local s             = btn:FindFirstChildWhichIsA("UIStroke")

        if s then 
            tw(s, 
            { 
                Color = P.blue 
            }) 
        end
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, 
        { 
            BackgroundColor3 = Color3.fromRGB(17, 17, 20), 
            TextColor3 = P.blue 
        })

        local s             = btn:FindFirstChildWhichIsA("UIStroke")

        if s then 
            tw(s, { Color = P.divider }) 
        end
    end)
    btn.MouseButton1Click:Connect(function()
        if not carSpawned() then
            setStatus("X  Carro nao spawnado", P.err)
            showInfoBox("Seu carro nao esta spawnado", "", true)
            return
        end

        local count = 0
        for _, v in ipairs(valueList) do
            local ref           = inputRefs[v.name]
            if ref then
                local n         = tonumber(ref.inp.Text)

                if n then 
                    applyValue(v.name, n); 
                    count = count + 1 
                end
            end
        end

        setStatus("OK  " .. count .. " valores aplicados!", P.success)
        btn.Text = "OK — TUDO APLICADO"


        tw(btn, 
        {
             BackgroundColor3 = Color3.fromRGB(14, 28, 18), 
             TextColor3 = P.success 
        })

        task.delay(2.5, function()
            btn.Text            = label
            tw(btn, 
            { 
                BackgroundColor3 = Color3.fromRGB(17, 17, 20), 
                TextColor3 = P.blue 
            })
        end)

        showInfoBox("Todos os valores (" .. count .. ")", count .. " valores aplicados")
    end)
end

-- Linha com toggle switch
local function makeToggleRow(page, label, sublabel, onToggle)
    local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = P.rowHov
        row.BackgroundTransparency = 1
        row.BorderSizePixel  = 0
        row.ZIndex           = 8
        row.Parent           = page
    regC(row, 
        "BackgroundColor3", 
        "rowHov"
    )

    row.MouseEnter:Connect(function() 
        tw(row, 
        { 
            BackgroundTransparency = 0 
        }, 0.12) 
    end)
    row.MouseLeave:Connect(function() 
        tw(row, 
        { 
            BackgroundTransparency = 1 
        }, 0.15) 
    end)

    local lbl = Instance.new("TextLabel")
        lbl.Text               = label
        lbl.Size               = UDim2.new(0, 210, 0, 18)
        lbl.Position           = UDim2.new(0, 14, 0, 9)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3         = P.textPri
        lbl.TextSize           = 13
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextXAlignment     = Enum.TextXAlignment.Left
        lbl.ZIndex             = 9
        lbl.Parent             = row
    regC(lbl, 
        "TextColor3", 
        "textPri"
    )

    local sub = Instance.new("TextLabel")
        sub.Text               = sublabel or ""
        sub.Size               = UDim2.new(0, 230, 0, 13)
        sub.Position           = UDim2.new(0, 14, 0, 28)
        sub.BackgroundTransparency = 1
        sub.TextColor3         = P.textDim
        sub.TextSize           = 10
        sub.Font               = Enum.Font.Gotham
        sub.TextXAlignment     = Enum.TextXAlignment.Left
        sub.ZIndex             = 9
        sub.Parent             = row
    regC(sub, 
        "TextColor3", 
        "textDim"
    )

    local track = Instance.new("Frame")
        track.Size             = UDim2.new(0, 40, 0, 20)
        track.Position         = UDim2.new(1, -52, 0.5, -10)
        track.BackgroundColor3 = P.togOff
        track.BorderSizePixel  = 0
        track.ZIndex           = 9
        track.Parent           = row

    pill(track)

    local trackStroke = brdr(track, P.divider, 1, 0)

    regC(track,       
        "BackgroundColor3", 
        "togOff"
    )
    regC(trackStroke, 
        "Color",            
        "divider"
    )

    local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 12, 0, 12)
        knob.Position         = UDim2.new(0, 3, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(90, 90, 104)
        knob.BorderSizePixel  = 0
        knob.ZIndex           = 10
        knob.Parent           = track
    pill(knob)

    local togState = false
    local togBtn   = Instance.new("TextButton")
        togBtn.Size                 = UDim2.new(1, 0, 1, 0)
        togBtn.BackgroundTransparency = 1
        togBtn.Text                 = ""
        togBtn.ZIndex               = 11
        togBtn.Parent               = track

    togBtn.MouseButton1Click:Connect(function()
        togState = not togState

        if togState then
            tw(track, 
            { 
                BackgroundColor3 = P.togOn 
            })
            tw(knob,  
            { 
                Position = UDim2.new(0, 22, 0.5, -6),
                BackgroundColor3 = Color3.fromRGB(10, 10, 11) 
            })

            local s                 = track:FindFirstChildWhichIsA("UIStroke")
            if s then 
                tw(s, 
                { 
                    Color = P.blue 
                }) 
            end
        else
            tw(track, 
            { 
                BackgroundColor3 = P.togOff 
            })
            tw(knob,  
            { 
                Position = UDim2.new(0, 3, 0.5, -6),
                BackgroundColor3 = Color3.fromRGB(90, 90, 104) 
            })

            local s                = track:FindFirstChildWhichIsA("UIStroke")

            if s then 
                tw(s, { Color = P.divider }) end
        end

        if onToggle then 
            onToggle(togState)
        end
    end)

    local div = Instance.new("Frame")
        div.Size                   = UDim2.new(1, 0, 0, 1)
        div.Position               = UDim2.new(0, 0, 1, -1)
        div.BackgroundColor3       = P.divider
        div.BackgroundTransparency = 0
        div.BorderSizePixel        = 0
        div.ZIndex                 = 8
        div.Parent                 = row
    regC(div, 
        "BackgroundColor3", 
        "divider"
    )
end

-- Linha com label, sublabel e botão de ação genérico
local function makeInputRow(page, label, defaultSub, btnLabel, onBtn)
    local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = P.rowHov
        row.BackgroundTransparency = 1
        row.BorderSizePixel  = 0
        row.ZIndex           = 8
        row.Parent           = page
    regC(row, 
        "BackgroundColor3", 
        "rowHov"
    )

    row.MouseEnter:Connect(function() 
        tw(row, 
        { 
            BackgroundTransparency = 0 
        }) 
    end)

    row.MouseLeave:Connect(function() 
        tw(row, 
        { 
            BackgroundTransparency = 1 
        })
     end)

    local lbl = Instance.new("TextLabel")
        lbl.Text               = label
        lbl.Size               = UDim2.new(0, 200, 0, 18)
        lbl.Position           = UDim2.new(0, 14, 0, 9)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3         = P.textPri
        lbl.TextSize           = 13
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextXAlignment     = Enum.TextXAlignment.Left
        lbl.ZIndex             = 9
        lbl.Parent             = row

    regC(lbl, 
        "TextColor3", 
        "textPri"
    )

    local subLbl = Instance.new("TextLabel")
        subLbl.Name                = "sub"
        subLbl.Text                = defaultSub
        subLbl.Size                = UDim2.new(0, 220, 0, 13)
        subLbl.Position            = UDim2.new(0, 14, 0, 28)
        subLbl.BackgroundTransparency = 1
        subLbl.TextColor3          = P.textDim
        subLbl.TextSize            = 10
        subLbl.Font                = Enum.Font.Gotham
        subLbl.TextXAlignment      = Enum.TextXAlignment.Left
        subLbl.ZIndex              = 9
        subLbl.Parent              = row

    regC(subLbl,
        "TextColor3", 
        "textDim"
    )

    local btn = Instance.new("TextButton")
        btn.Text             = btnLabel
        btn.Size             = UDim2.new(0, 60, 0, 26)
        btn.Position         = UDim2.new(1, -72, 0.5, -13)
        btn.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
        btn.BorderSizePixel  = 0
        btn.TextColor3       = P.blue
        btn.TextSize         = 11
        btn.Font             = Enum.Font.GothamBold
        btn.ZIndex           = 9
        btn.Parent           = row

    rnd(btn, 2)
    local inputRowStroke = brdr(btn, P.divider, 1, 0)
    regC(btn,             
        "TextColor3",
        "blue"
    )
    regC(inputRowStroke,  
        "Color",      
        "divider"
    )

    btn.MouseEnter:Connect(function()
        tw(btn, 
        { 
            BackgroundColor3 = Color3.fromRGB(24, 24, 29) 
        })
        
        local s             = btn:FindFirstChildWhichIsA("UIStroke")

        if s then 
            tw(s, 
            { 
                Color = P.blue 
            }) 
        end
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, 
        { 
            BackgroundColor3 = Color3.fromRGB(17, 17, 20) 
        })

        local s             = btn:FindFirstChildWhichIsA("UIStroke")

        if s then 
            tw(s, 
            { 
                Color = P.divider 
            })
        end
    end)

    btn.MouseButton1Click:Connect(function()
        if onBtn then 
            onBtn(btn, subLbl) 
        end
    end)

    local div = Instance.new("Frame")
        div.Size                   = UDim2.new(1, 0, 0, 1)
        div.Position               = UDim2.new(0, 0, 1, -1)
        div.BackgroundColor3       = P.divider
        div.BackgroundTransparency = 0
        div.BorderSizePixel        = 0
        div.ZIndex                 = 8
        div.Parent                 = row
    regC(div, 
        "BackgroundColor3", 
        "divider"
    )
end


-- ════════════════════════════════════════════════════════════════════
--  CONSTRUÇÃO DAS PÁGINAS
--  Bloco isolado para liberar locais e ficar sob o limite de 200
--  do LuaU.
-- ════════════════════════════════════════════════════════════════════

do

-- ─────────────────────────────────────────────────
--  PÁGINA: MISC
-- ─────────────────────────────────────────────────

do
    local pgMisc = pages["Misc"]

    makeSectionHeader(pgMisc, "CONFIG EXTRAS", "Liquidos do motor e combustivel.")
    for _, v in ipairs(VALUES) do makeValueRow(pgMisc, v) end
    makeApplyAllRow(pgMisc, "Aplicar Todos as mudanças", VALUES)

    makeSectionHeader(pgMisc, "Config Gerais", "Cambagem, ignição e aerodinâmica.")
    for _, v in ipairs(MISC_VALUES) do makeValueRow(pgMisc, v) end
    makeApplyAllRow(pgMisc, "Aplicar Todos (Misc)", MISC_VALUES)
end


-- ─────────────────────────────────────────────────
--  PÁGINA: TUNE
-- ─────────────────────────────────────────────────

do
    local pgTune = pages["Tune"]

    makeSectionHeader(pgTune, "Turbo & Tune", "Ajustes de turbo e relação de marcha.")
    for _, v in ipairs(TUNE_VALUES) do makeValueRow(pgTune, v) end

    -- Linha de seleção de tipo de pneu
    local tireRow = Instance.new("Frame")
        tireRow.Size             = UDim2.new(1, 0, 0, 54)
        tireRow.BackgroundColor3 = P.rowHov
        tireRow.BackgroundTransparency = 1
        tireRow.BorderSizePixel  = 0
        tireRow.ZIndex           = 8
        tireRow.Parent           = pgTune
    regC(tireRow, "BackgroundColor3", "rowHov")
    tireRow.MouseEnter:Connect(function() tw(tireRow, { BackgroundTransparency = 0 }, 0.12) end)
    tireRow.MouseLeave:Connect(function() tw(tireRow, { BackgroundTransparency = 1 }, 0.15) end)

    local tl = Instance.new("TextLabel")
    tl.Text               = "Tipo de Pneu"
    tl.Size               = UDim2.new(0, 150, 0, 18)
    tl.Position           = UDim2.new(0, 14, 0, 9)
    tl.BackgroundTransparency = 1
    tl.TextColor3         = P.textPri
    tl.TextSize           = 13
    tl.Font               = Enum.Font.GothamBold
    tl.TextXAlignment     = Enum.TextXAlignment.Left
    tl.ZIndex             = 9
    tl.Parent             = tireRow
    regC(tl, "TextColor3", "textPri")

    local ts = Instance.new("TextLabel")
        ts.Text               = "Slick  Smooth  Drag"
        ts.Size               = UDim2.new(0, 240, 0, 13)
        ts.Position           = UDim2.new(0, 14, 0, 28)
        ts.BackgroundTransparency = 1
        ts.TextColor3         = P.textDim
        ts.TextSize           = 10
        ts.Font               = Enum.Font.Gotham
        ts.TextXAlignment     = Enum.TextXAlignment.Left
        ts.ZIndex             = 9
        ts.Parent             = tireRow
    regC(ts, "TextColor3", "textDim")

    local tBtnRow = Instance.new("Frame")
        tBtnRow.Size                   = UDim2.new(0, 186, 0, 30)
        tBtnRow.Position               = UDim2.new(1, -196, 0.5, -15)
        tBtnRow.BackgroundTransparency = 1
        tBtnRow.ZIndex                 = 9
        tBtnRow.Parent                 = tireRow
    do
        local ll = Instance.new("UIListLayout")
            ll.FillDirection       = Enum.FillDirection.Horizontal
            ll.Padding             = UDim.new(0, 4)
            ll.HorizontalAlignment = Enum.HorizontalAlignment.Right
            ll.VerticalAlignment   = Enum.VerticalAlignment.Center
            ll.Parent              = tBtnRow
    end

    local function makeTireBtn(name, val)
        local b = Instance.new("TextButton")
            b.Text             = name
            b.Size             = UDim2.new(0, 58, 0, 28)
            b.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
            b.BorderSizePixel  = 0
            b.TextColor3       = P.blue
            b.TextSize         = 11
            b.Font             = Enum.Font.GothamBold
            b.ZIndex           = 10
            b.Parent           = tBtnRow
        rnd(b, 2)
        local tbS = brdr(b, P.divider, 1, 0)
        regC(b,   "TextColor3", "blue")
        regC(tbS, "Color",      "divider")

        b.MouseEnter:Connect(function()
            tw(b, { BackgroundColor3 = P.blue, TextColor3 = Color3.fromRGB(10, 10, 11) })
        end)
        b.MouseLeave:Connect(function()
            tw(b, { BackgroundColor3 = Color3.fromRGB(17, 17, 20), TextColor3 = P.blue })
        end)
        b.MouseButton1Click:Connect(function()
            if not carSpawned() then
                setStatus("X  Carro nao spawnado", P.err)
                showInfoBox("Seu carro nao esta spawnado", "", true)
                return
            end
            applyTireValue(TIRE_VALUES.front, val)
            applyTireValue(TIRE_VALUES.rear,  val)
            setStatus("OK  Pneu " .. name .. " -> " .. val, P.success)
            tw(b, { BackgroundColor3 = P.success, TextColor3 = Color3.fromRGB(10, 10, 11) })
            task.delay(1.5, function()
                tw(b, { BackgroundColor3 = Color3.fromRGB(17, 17, 20), TextColor3 = P.blue })
            end)
            showInfoBox("Tipo de Pneu  —  " .. name, "Ftire & Rtire = " .. val)
        end)
    end

    -- Valores corretos: 1=Semi-Slick, 2=Smooth, 3=Drag
    makeTireBtn("Semi",   1)
    makeTireBtn("Smooth", 2)
    makeTireBtn("Drag",   3)

    do
        local div = Instance.new("Frame")
            div.Size             = UDim2.new(1, 0, 0, 1)
            div.Position         = UDim2.new(0, 0, 1, -1)
            div.BackgroundColor3 = P.divider
            div.BackgroundTransparency = 0
            div.BorderSizePixel  = 0
            div.ZIndex           = 8
            div.Parent           = tireRow
        regC(div, "BackgroundColor3", "divider")
    end

    makeApplyAllRow(pgTune, "Aplicar Todos (Tune)", TUNE_VALUES)
end


-- ─────────────────────────────────────────────────
--  PÁGINA: TP (Teleportes)
-- ─────────────────────────────────────────────────

do
    local pgTP = pages["TP"]
    makeSectionHeader(pgTP, "Teleports", "Viaje rapidamente para qualquer local.")

    -- Teleporte suavizado em passos para evitar anti-cheat
    local function doTeleport(destino, btn, originalText)
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp       = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            setStatus("X  Personagem nao encontrado", P.err)
            return
        end

        if btn then
            btn.Text = "..."
            tw(btn, { BackgroundColor3 = Color3.fromRGB(17, 17, 20) }, 0.1)
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

            if btn then
                btn.Text = "OK"
                tw(btn, { BackgroundColor3 = P.success, TextColor3 = Color3.fromRGB(10, 10, 11) }, 0.15)
                task.delay(1.8, function()
                    btn.Text = originalText
                    tw(btn, { BackgroundColor3 = P.blue, TextColor3 = Color3.fromRGB(10, 10, 11) }, 0.2)
                end)
            end

            local posStr = math.floor(destino.X) .. "," .. math.floor(destino.Y) .. "," .. math.floor(destino.Z)
            setStatus("TP  ->  " .. posStr, P.success)
        end)
    end

    -- Gera uma linha para cada destino
    for idx, dest in ipairs(TELEPORT_DESTINATIONS) do
        local row = Instance.new("Frame")
            row.Size             = UDim2.new(1, 0, 0, 56)
            row.BackgroundColor3 = P.rowHov
            row.BackgroundTransparency = 1
            row.BorderSizePixel  = 0
            row.ZIndex           = 8
            row.Parent           = pgTP
        regC(row, "BackgroundColor3", "rowHov")
        row.MouseEnter:Connect(function() tw(row, { BackgroundTransparency = 0 }, 0.12) end)
        row.MouseLeave:Connect(function() tw(row, { BackgroundTransparency = 1 }, 0.15) end)

        local numLbl = Instance.new("TextLabel")
            numLbl.Text               = string.format("%02d", idx)
            numLbl.Size               = UDim2.new(0, 28, 1, 0)
            numLbl.Position           = UDim2.new(0, 10, 0, 0)
            numLbl.BackgroundTransparency = 1
            numLbl.TextColor3         = P.textDim
            numLbl.TextSize           = 18
            numLbl.Font               = Enum.Font.GothamBlack
            numLbl.TextXAlignment     = Enum.TextXAlignment.Center
            numLbl.ZIndex             = 9
            numLbl.Parent             = row

        regC(numLbl, 
            "TextColor3", 
            "textDim"
        )
        row.MouseEnter:Connect(function() 
            tw(numLbl, 
            { 
                TextColor3 = P.blue    
            }) 
        end)
        row.MouseLeave:Connect(function() 
            tw(numLbl, 
            { 
                TextColor3 = P.textDim 
            }) 
        end)

        local nameLbl = Instance.new("TextLabel")
            nameLbl.Text               = dest.label
            nameLbl.Size               = UDim2.new(0, 200, 0, 18)
            nameLbl.Position           = UDim2.new(0, 44, 0, 9)
            nameLbl.BackgroundTransparency = 1
            nameLbl.TextColor3         = P.textPri
            nameLbl.TextSize           = 13
            nameLbl.Font               = Enum.Font.GothamBold
            nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
            nameLbl.ZIndex             = 9
            nameLbl.Parent             = row

        regC(nameLbl, 
            "TextColor3", 
            "textPri"
        )

        local coordLbl = Instance.new("TextLabel")
            coordLbl.Text               = string.format("X %d  Y %d  Z %d", dest.pos.X, dest.pos.Y, dest.pos.Z)
            coordLbl.Size               = UDim2.new(0, 220, 0, 13)
            coordLbl.Position           = UDim2.new(0, 44, 0, 28)
            coordLbl.BackgroundTransparency = 1
            coordLbl.TextColor3         = P.textDim
            coordLbl.TextSize           = 10
            coordLbl.Font               = Enum.Font.Gotham
            coordLbl.TextXAlignment     = Enum.TextXAlignment.Left
            coordLbl.ZIndex             = 9
            coordLbl.Parent             = row

        regC(coordLbl, 
            "TextColor3", 
            "textDim"
        )

        local tpBtn = Instance.new("TextButton")
            tpBtn.Text             = "IR"
            tpBtn.Size             = UDim2.new(0, 48, 0, 28)
            tpBtn.Position         = UDim2.new(1, -58, 0.5, -14)
            tpBtn.BackgroundColor3 = P.blue
            tpBtn.BorderSizePixel  = 0
            tpBtn.TextColor3       = Color3.fromRGB(10, 10, 11)
            tpBtn.TextSize         = 11
            tpBtn.Font             = Enum.Font.GothamBold
            tpBtn.ZIndex           = 10
            tpBtn.Parent           = row
        rnd(tpBtn, 2)

        regC(tpBtn, 
            "BackgroundColor3", 
            "blue"
        )

        tpBtn.MouseEnter:Connect(function() 
            tw(tpBtn, 
            { 
                BackgroundColor3 = P.blueL 
            }, 0.12) 
        end)
        tpBtn.MouseLeave:Connect(function() 
            tw(tpBtn, 
            { 
                BackgroundColor3 = P.blue  
            }, 0.12) 
        end)

        local capturedDest  = dest.pos
        local originalText  = "IR"
        tpBtn.MouseButton1Click:Connect(function()
            doTeleport(capturedDest, tpBtn, originalText)
        end)

        local div = Instance.new("Frame")
            div.Size                   = UDim2.new(1, 0, 0, 1)
            div.Position               = UDim2.new(0, 0, 1, -1)
            div.BackgroundColor3       = P.divider
            div.BackgroundTransparency = 0
            div.BorderSizePixel        = 0
            div.ZIndex                 = 8
            div.Parent                 = row
        regC(div, 
            "BackgroundColor3", 
            "divider"
        )
    end
end


-- ─────────────────────────────────────────────────
--  PÁGINA: AUTOFARM
-- ─────────────────────────────────────────────────

local pgAutoFarm = pages["AutoFarm"]
makeSectionHeader(pgAutoFarm, "Auto Farm — Imã", "Puxa suas caixas automaticamente.")

-- Cache dedicado para TranspBox (BasePart, não ValueBase)
local _transpBoxCache = {}

local function _transpCacheAdd(obj)
    if not (obj:IsA("BasePart") and obj.Name == "TranspBox") then 
        return 
    end
    for _, v in ipairs(_transpBoxCache) 
    do 
        if v == obj then 
            return 
        end 
    end
    
    table.insert(_transpBoxCache, obj)
end

local function _transpCacheRemove(obj)
    if not (obj:IsA("BasePart") and obj.Name == "TranspBox") then 
        return 
    end

    for i, v in ipairs(_transpBoxCache) do
        if v == obj then 
            table.remove(_transpBoxCache, i); 
            return 
        end
    end
end

task.defer(function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        _transpCacheAdd(obj)
    end
end)

workspace.DescendantAdded:Connect(_transpCacheAdd)
workspace.DescendantRemoving:Connect(_transpCacheRemove)

-- Retorna todas as TranspBox que pertencem ao player
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

-- Para o imã e restaura física das caixas
local function pararIma(statusLbl, knob, track)
    if not AF.imaAtivo then 
        return 
    end
    AF.imaAtivo    = false
    AF.imaGrudadas = false

    if imaLoopConnection then
        imaLoopConnection:Disconnect()
        imaLoopConnection = nil
    end

    for _, box in ipairs(AF.minhasCaixas) do
        if box and box.Parent then
            box.Anchored   = false
            box.CanCollide = AF.colisoesOriginais[box] ~= nil
                and AF.colisoesOriginais[box] or true
            pcall(function() box.Anchored = false end)
            pcall(function() box.CanCollide = AF.colisoesOriginais[box] or true end)
        end
    end

    AF.colisoesOriginais = {}
    AF.minhasCaixas      = {}

    if track and knob then
        tw(track, { BackgroundColor3 = P.togOff })
        tw(knob,  { Position = UDim2.new(0, 3, 0.5, -6),
                    BackgroundColor3 = Color3.fromRGB(90, 90, 104) })
    end
    if statusLbl then 
        statusLbl.Text = "Ima desativado  —  caixas liberadas" 
    end
    setStatus("Imã desativado", P.textDim)
end

-- Inicia o imã: ancora caixas e as puxa em loop via Heartbeat
local function iniciarIma(statusLbl, knob, track)
    if AF.imaAtivo then 
        return 
    end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        setStatus("X  Personagem nao encontrado", P.err)
        if statusLbl then 
            statusLbl.Text = "Personagem nao encontrado" 
        end
        
        return
    end

    AF.minhasCaixas = encontrarMinhasCaixas()
    if #AF.minhasCaixas == 0 then
        setStatus("X  Nenhuma caixa encontrada — spawne primeiro", P.err)
        if statusLbl then 
            statusLbl.Text = "Nenhuma TranspBox encontrada!" 
        end
        if track and knob then
            tw(track, 
            { 
                BackgroundColor3 = P.togOff 
            })
            tw(knob,  
            { 
                Position = UDim2.new(0, 3, 0.5, -6),
                BackgroundColor3 = Color3.fromRGB(90, 90, 104) 
            })
        end
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

    if statusLbl then
        statusLbl.Text = string.format("Puxando %d caixa(s)...", #AF.minhasCaixas)
    end
    setStatus(string.format("Imã ativo — %d caixa(s)", #AF.minhasCaixas), P.success)

    local velocidade = 0.12
    imaLoopConnection = RunService.Heartbeat:Connect(function()
    AF.imaLoopConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            local c    = player.Character
            local hrp2 = c and c:FindFirstChild("HumanoidRootPart")
            if not hrp2 then return end

            local alvo        = hrp2.CFrame
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
                if statusLbl then
                    statusLbl.Text = string.format(" %d caixa(s) grudada(s)!", #AF.minhasCaixas)
                end
                setStatus(string.format("Ima — %d caixa(s) grudada(s)", #AF.minhasCaixas), P.success)
            end

            if AF.imaGrudadas then
                for _, box in ipairs(AF.minhasCaixas) do
                    if box and box.Parent then box.CFrame = alvo end
                end
            end
        end)
    end)
end

-- ── Card principal do Imã ────────────────────────

local afRow = Instance.new("Frame")
    afRow.Size             = UDim2.new(1, 0, 0, 84)
    afRow.BackgroundColor3 = P.rowHov
    afRow.BackgroundTransparency = 1
    afRow.BorderSizePixel  = 0
    afRow.ZIndex           = 8
    afRow.Parent           = pgAutoFarm
regC(afRow, 
    "BackgroundColor3", 
    "rowHov"
)
afRow.MouseEnter:Connect(function() 
    tw(afRow,
    { 
        BackgroundTransparency = 0 
    }, 0.12) 
end)
afRow.MouseLeave:Connect(function() 
    tw(afRow,
    { 
        BackgroundTransparency = 0 
    }, 0.12) 
end)

local afAccent = Instance.new("Frame")   -- era P.success (verde), agora P.blue
    afAccent.Size             = UDim2.new(0, 3, 1, 0)
    afAccent.Position         = UDim2.new(0, 0, 0, 0)
    afAccent.BackgroundColor3 = P.textDim
    afAccent.BorderSizePixel  = 0
    afAccent.ZIndex           = 9
    afAccent.Parent           = afRow
regC(afAccent, 
    "BackgroundColor3", 
    "textDim"
)

local afTitle = Instance.new("TextLabel")
    afTitle.Text               = "Imã de Caixas"
    afTitle.Size               = UDim2.new(0, 200, 0, 18)
    afTitle.Position           = UDim2.new(0, 14, 0, 10)
    afTitle.BackgroundTransparency = 1
    afTitle.TextColor3         = P.textPri
    afTitle.TextSize           = 13
    afTitle.Font               = Enum.Font.GothamBold
    afTitle.TextXAlignment     = Enum.TextXAlignment.Left
    afTitle.ZIndex             = 9
    afTitle.Parent             = afRow
regC(afTitle, 
    "TextColor3",
    "textPri"
)

local afSub = Instance.new("TextLabel")
    afSub.Text               = "Pressione H para ativar / desativar"
    afSub.Size               = UDim2.new(0, 260, 0, 13)
    afSub.Position           = UDim2.new(0, 14, 0, 30)
    afSub.BackgroundTransparency = 1
    afSub.TextColor3         = P.textDim
    afSub.TextSize           = 10
    afSub.Font               = Enum.Font.Gotham
    afSub.TextXAlignment     = Enum.TextXAlignment.Left
    afSub.ZIndex             = 9
    afSub.Parent             = afRow
regC(afSub, 
    "TextColor3", 
    "textDim"
)

local afStatus = Instance.new("TextLabel")
    afStatus.Text               = "Desativado"
    afStatus.Size               = UDim2.new(1, -100, 0, 13)
    afStatus.Position           = UDim2.new(0, 14, 0, 50)
    afStatus.BackgroundTransparency = 1
    afStatus.TextColor3         = P.textDim
    afStatus.TextSize           = 10
    afStatus.Font               = Enum.Font.GothamBold
    afStatus.TextXAlignment     = Enum.TextXAlignment.Left
    afStatus.ZIndex             = 9
    afStatus.Parent             = afRow
regC(afStatus, 
    "TextColor3", 
    "textDim"
)

local afTrack = Instance.new("Frame")
    afTrack.Size             = UDim2.new(0, 34, 0, 18)
    afTrack.Position         = UDim2.new(1, -50, 0, 12)
    afTrack.BackgroundColor3 = P.togOff
    afTrack.BorderSizePixel  = 0
    afTrack.ZIndex           = 9
    afTrack.Parent           = afRow
regC(afTrack, 
    "BackgroundColor3", 
    "togOff"
)
rnd(afTrack, 2)
brdr(afTrack, P.divider, 1, 0)

local afKnob = Instance.new("Frame")
    afKnob.Size             = UDim2.new(0, 12, 0, 12)
    afKnob.Position         = UDim2.new(0, 3, 0.5, -6)
    afKnob.BackgroundColor3 = Color3.fromRGB(90, 90, 104)
    afKnob.BorderSizePixel  = 0
    afKnob.ZIndex           = 10
    afKnob.Parent           = afTrack

local afTogBtn = Instance.new("TextButton")
    afTogBtn.Size                 = UDim2.new(1, 0, 1, 0)
    afTogBtn.BackgroundTransparency = 1
    afTogBtn.Text                 = ""
    afTogBtn.ZIndex               = 11
    afTogBtn.Parent               = afTrack

-- Badge "H" (atalho de teclado)
local afHBadge = Instance.new("TextLabel")
    afHBadge.Text             = "H"
    afHBadge.Size             = UDim2.new(0, 22, 0, 22)
    afHBadge.Position         = UDim2.new(1, -50, 0, 38)
    afHBadge.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
    afHBadge.TextColor3       = P.blue
    afHBadge.TextSize         = 12
    afHBadge.Font             = Enum.Font.GothamBold
    afHBadge.BorderSizePixel  = 0
    afHBadge.ZIndex           = 10
    afHBadge.Parent           = afRow
regC(afHBadge, 
    "TextColor3", 
    "blue"
)
rnd(afHBadge, 2)
brdr(afHBadge, P.blue, 1, 0.4)

local afDiv = Instance.new("Frame")
    afDiv.Size                   = UDim2.new(1, 0, 0, 1)
    afDiv.Position               = UDim2.new(0, 0, 1, -1)
    afDiv.BackgroundColor3       = P.divider
    afDiv.BackgroundTransparency = 0
    afDiv.BorderSizePixel        = 0
    afDiv.ZIndex                 = 8
    afDiv.Parent                 = afRow
regC(afDiv, 
    "BackgroundColor3", 
    "divider"
)

-- Card informativo abaixo do toggle do imã
local afInfoCard = Instance.new("Frame")
    afInfoCard.Size             = UDim2.new(1, 0, 0, 44)
    afInfoCard.BackgroundColor3 = P.section
    afInfoCard.BackgroundTransparency = 0
    afInfoCard.BorderSizePixel  = 0
    afInfoCard.ZIndex           = 8
    afInfoCard.Parent           = pgAutoFarm
regC(afInfoCard, 
    "BackgroundColor3", 
    "section"
)

local afAccentStrip = Instance.new("Frame")
    afAccentStrip.Size             = UDim2.new(0, 3, 1, 0)
    afAccentStrip.BackgroundColor3 = P.blue
    afAccentStrip.BorderSizePixel  = 0
    afAccentStrip.ZIndex           = 9
    afAccentStrip.Parent           = afInfoCard
regC(afAccentStrip, 
    "BackgroundColor3", 
    "blue"
)

local afInfo = Instance.new("TextLabel")
    afInfo.Text               = "Puxa todas as suas caixas até o personagem e as mantém grudadas enquanto ativo."
    afInfo.Size               = UDim2.new(1, -24, 1, 0)
    afInfo.Position           = UDim2.new(0, 14, 0, 0)
    afInfo.BackgroundTransparency = 1
    afInfo.TextColor3         = P.textSub
    afInfo.TextSize           = 11
    afInfo.Font               = Enum.Font.Gotham
    afInfo.TextXAlignment     = Enum.TextXAlignment.Left
    afInfo.TextYAlignment     = Enum.TextYAlignment.Center
    afInfo.TextWrapped        = true
    afInfo.ZIndex             = 9
    afInfo.Parent             = afInfoCard
regC(afInfo, "TextColor3", "textSub")

-- Toggle lógico do imã
local function toggleIma()
    if AF.imaAtivo then
        pararIma(afStatus, afKnob, afTrack)
        afStatus.TextColor3 = P.textDim
        tw(afAccent, { BackgroundColor3 = P.textDim })
    else
        tw(afTrack, { BackgroundColor3 = P.togOn })
        tw(afKnob,  { Position = UDim2.new(0, 19, 0.5, -6),
                      BackgroundColor3 = Color3.fromRGB(10, 10, 11) })
        do
            local s = afTrack:FindFirstChildWhichIsA("UIStroke")
            if s then 
                tw(s, 
                { 
                    Color = P.blue 
                }) 
            end
        end
        afStatus.TextColor3 = P.blue   -- era P.success (verde)
        tw(afAccent, 
        { 
            BackgroundColor3 = P.blue 
        })   -- era P.success (verde)
        iniciarIma(afStatus, afKnob, afTrack)
    end
end


-- ════════════════════════════════════════════════════════════════════
--  AUTO ENTREGA (Delivery Farm)
-- ════════════════════════════════════════════════════════════════════

local deliveryFarmAtivo  = false
local deliveryFarmThread = nil

-- Separador visual
local afSep = Instance.new("Frame")
    afSep.Size             = UDim2.new(1, 0, 0, 1)
    afSep.BackgroundColor3 = P.divider
    afSep.BackgroundTransparency = 0
    afSep.BorderSizePixel  = 0
    afSep.ZIndex           = 8
    afSep.Parent           = pgAutoFarm

regC(afSep, 
    "BackgroundColor3",
    "divider"
)

-- Cabeçalho da seção Auto Entrega
local dfSectionHdr = Instance.new("Frame")
    dfSectionHdr.Size             = UDim2.new(1, 0, 0, 62)
    dfSectionHdr.BackgroundColor3 = P.section
    dfSectionHdr.BackgroundTransparency = 0
    dfSectionHdr.BorderSizePixel  = 0
    dfSectionHdr.ZIndex           = 8
    dfSectionHdr.Parent           = pgAutoFarm

regC(dfSectionHdr, 
    "BackgroundColor3", 
    "section"
)

local dfSectionAccent = Instance.new("Frame")
    dfSectionAccent.Size             = UDim2.new(0, 3, 1, 0)
    dfSectionAccent.BackgroundColor3 = P.blue   -- era laranja
    dfSectionAccent.BorderSizePixel  = 0
    dfSectionAccent.ZIndex           = 9
    dfSectionAccent.Parent           = dfSectionHdr

regC(dfSectionAccent, 
    "BackgroundColor3", 
    "blue"
)

local dfSectionTitle = Instance.new("TextLabel")
    dfSectionTitle.Text               = "AUTO ENTREGA"
    dfSectionTitle.Size               = UDim2.new(1, -20, 0, 22)
    dfSectionTitle.Position           = UDim2.new(0, 14, 0, 10)
    dfSectionTitle.BackgroundTransparency = 1
    dfSectionTitle.TextColor3         = P.textPri
    dfSectionTitle.TextSize           = 15
    dfSectionTitle.Font               = Enum.Font.GothamBlack
    dfSectionTitle.TextXAlignment     = Enum.TextXAlignment.Left
    dfSectionTitle.ZIndex             = 9
    dfSectionTitle.Parent             = dfSectionHdr

regC(dfSectionTitle, 
    "TextColor3", 
    "textPri"
)

local dfSectionSub = Instance.new("TextLabel")
    dfSectionSub.Text               = "Coleta, ativa Imã e entrega automaticamente (Entrega)"
    dfSectionSub.Size               = UDim2.new(1, -20, 0, 14)
    dfSectionSub.Position           = UDim2.new(0, 14, 0, 34)
    dfSectionSub.BackgroundTransparency = 1
    dfSectionSub.TextColor3         = P.textDim
    dfSectionSub.TextSize           = 10
    dfSectionSub.Font               = Enum.Font.Gotham
    dfSectionSub.TextXAlignment     = Enum.TextXAlignment.Left
    dfSectionSub.ZIndex             = 9
    dfSectionSub.Parent             = dfSectionHdr

regC(dfSectionSub, 
    "TextColor3", 
    "textDim"
)
do
    local div = Instance.new("Frame")
        div.Size             = UDim2.new(1, 0, 0, 1)
        div.Position         = UDim2.new(0, 0, 1, -1)
        div.BackgroundColor3 = P.divider
        div.BorderSizePixel  = 0
        div.ZIndex           = 9
        div.Parent           = dfSectionHdr
end

-- Card do Delivery Farm
local dfCard = Instance.new("Frame")
    dfCard.Size             = UDim2.new(1, 0, 0, 104)
    dfCard.BackgroundColor3 = P.rowHov
    dfCard.BackgroundTransparency = 1
    dfCard.BorderSizePixel  = 0
    dfCard.ZIndex           = 8
    dfCard.Parent           = pgAutoFarm

regC(dfCard, 
    "BackgroundColor3", 
    "rowHov"
)
dfCard.MouseEnter:Connect(function() 
    tw(dfCard, 
    { 
        BackgroundTransparency = 0 
    }, 0.12) 
end)
dfCard.MouseLeave:Connect(function() 
    tw(dfCard, 
    { 
        BackgroundTransparency = 1 
    }, 0.15) 
end)

local dfAccentBar = Instance.new("Frame")
    dfAccentBar.Size             = UDim2.new(0, 3, 1, 0)
    dfAccentBar.BackgroundColor3 = P.textDim
    dfAccentBar.BorderSizePixel  = 0
    dfAccentBar.ZIndex           = 9
    dfAccentBar.Parent           = dfCard

regC(dfAccentBar, 
    "BackgroundColor3",
    "textDim"
)

local dfTitle = Instance.new("TextLabel")
    dfTitle.Text               = "Auto Entrega  (Entrega)"
    dfTitle.Size               = UDim2.new(0, 230, 0, 18)
    dfTitle.Position           = UDim2.new(0, 14, 0, 10)
    dfTitle.BackgroundTransparency = 1
    dfTitle.TextColor3         = P.textPri
    dfTitle.TextSize           = 13
    dfTitle.Font               = Enum.Font.GothamBold
    dfTitle.TextXAlignment     = Enum.TextXAlignment.Left
    dfTitle.ZIndex             = 9
    dfTitle.Parent             = dfCard

regC(dfTitle, 
    "TextColor3", 
    "textPri"
)

local dfSub = Instance.new("TextLabel")
    dfSub.Text               = "Escolhe a melhor entrega e entrega automaticamente"
    dfSub.Size               = UDim2.new(1, -60, 0, 13)
    dfSub.Position           = UDim2.new(0, 14, 0, 30)
    dfSub.BackgroundTransparency = 1
    dfSub.TextColor3         = P.textDim
    dfSub.TextSize           = 10
    dfSub.Font               = Enum.Font.Gotham
    dfSub.TextXAlignment     = Enum.TextXAlignment.Left
    dfSub.TextWrapped        = true
    dfSub.ZIndex             = 9
    dfSub.Parent             = dfCard

regC(dfSub, 
    "TextColor3", 
    "textDim"
)

local dfStatusA = Instance.new("TextLabel")
    dfStatusA.Text               = "Aguardando inicio..."
    dfStatusA.Size               = UDim2.new(1, -60, 0, 13)
    dfStatusA.Position           = UDim2.new(0, 14, 0, 50)
    dfStatusA.BackgroundTransparency = 1
    dfStatusA.TextColor3         = P.textDim
    dfStatusA.TextSize           = 10
    dfStatusA.Font               = Enum.Font.GothamBold
    dfStatusA.TextXAlignment     = Enum.TextXAlignment.Left
    dfStatusA.ZIndex             = 9
    dfStatusA.Parent             = dfCard

regC(dfStatusA, 
    "TextColor3", 
    "textDim"
)

local dfStatusB = Instance.new("TextLabel")
    dfStatusB.Text               = ""
    dfStatusB.Size               = UDim2.new(1, -60, 0, 13)
    dfStatusB.Position           = UDim2.new(0, 14, 0, 66)
    dfStatusB.BackgroundTransparency = 1
    dfStatusB.TextColor3         = P.blueL
    dfStatusB.TextSize           = 10
    dfStatusB.Font               = Enum.Font.Gotham
    dfStatusB.TextXAlignment     = Enum.TextXAlignment.Left
    dfStatusB.ZIndex             = 9
    dfStatusB.Parent             = dfCard

regC(dfStatusB, 
    "TextColor3", 
    "blueL"
)

local dfTrack = Instance.new("Frame")
    dfTrack.Size             = UDim2.new(0, 34, 0, 18)
    dfTrack.Position         = UDim2.new(1, -50, 0, 12)
    dfTrack.BackgroundColor3 = P.togOff
    dfTrack.BorderSizePixel  = 0
    dfTrack.ZIndex           = 9
    dfTrack.Parent           = dfCard

regC(dfTrack, 
    "BackgroundColor3", 
    "togOff"
)

rnd(dfTrack, 2)
brdr(dfTrack, P.divider, 1, 0)

local dfKnob = Instance.new("Frame")
    dfKnob.Size             = UDim2.new(0, 12, 0, 12)
    dfKnob.Position         = UDim2.new(0, 3, 0.5, -6)
    dfKnob.BackgroundColor3 = Color3.fromRGB(90, 90, 104)
    dfKnob.BorderSizePixel  = 0
    dfKnob.ZIndex           = 10
    dfKnob.Parent           = dfTrack

local dfTogBtn = Instance.new("TextButton")
    dfTogBtn.Size                 = UDim2.new(1, 0, 1, 0)
    dfTogBtn.BackgroundTransparency = 1
    dfTogBtn.Text                 = ""
    dfTogBtn.ZIndex               = 11
    dfTogBtn.Parent               = dfTrack
do
    local div = Instance.new("Frame")
        div.Size                   = UDim2.new(1, 0, 0, 1)
        div.Position               = UDim2.new(0, 0, 1, -1)
        div.BackgroundColor3       = P.divider
        div.BackgroundTransparency = 0
        div.BorderSizePixel        = 0
        div.ZIndex                 = 8
        div.Parent                 = dfCard
end

-- Card informativo do Delivery Farm
local dfInfoCard = Instance.new("Frame")
    dfInfoCard.Size             = UDim2.new(1, 0, 0, 44)
    dfInfoCard.BackgroundColor3 = P.section
    dfInfoCard.BackgroundTransparency = 0
    dfInfoCard.BorderSizePixel  = 0
    dfInfoCard.ZIndex           = 8
    dfInfoCard.Parent           = pgAutoFarm
regC(dfInfoCard, "BackgroundColor3", "section")

local dfInfoStrip = Instance.new("Frame")
    dfInfoStrip.Size             = UDim2.new(0, 3, 1, 0)
    dfInfoStrip.BackgroundColor3 = P.blue   -- era laranja
    dfInfoStrip.BorderSizePixel  = 0
    dfInfoStrip.ZIndex           = 9
    dfInfoStrip.Parent           = dfInfoCard
regC(dfInfoStrip, "BackgroundColor3", "blue")

local dfInfo = Instance.new("TextLabel")
    dfInfo.Text               = "Vai ao ponto de coleta → pega a melhor entrega → ativa Imã → entrega → repete."
    dfInfo.Size               = UDim2.new(1, -24, 1, 0)
    dfInfo.Position           = UDim2.new(0, 14, 0, 0)
    dfInfo.BackgroundTransparency = 1
    dfInfo.TextColor3         = P.textSub
    dfInfo.TextSize           = 10
    dfInfo.Font               = Enum.Font.Gotham
    dfInfo.TextXAlignment     = Enum.TextXAlignment.Left
    dfInfo.TextYAlignment     = Enum.TextYAlignment.Center
    dfInfo.TextWrapped        = true
    dfInfo.ZIndex             = 9
    dfInfo.Parent             = dfInfoCard
regC(dfInfo, "TextColor3", "textSub")

-- ── Funções do Delivery Farm ─────────────────────

-- Atualiza os dois labels de status do dfCard
local function dfLog(a, b)
    dfStatusA.Text = a or ""
    dfStatusB.Text = b or ""
    if AF.statusEnabled then setStatus(a or "", P.blueL) end
end

-- Caminha suavizado em direção a `destino`
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
            if not hrp then
                task.wait(0.5)
            else
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
            end
        end)

        local char2 = player.Character
        local hrp2  = char2 and char2:FindFirstChild("HumanoidRootPart")
        if hrp2 and (hrp2.Position - destino).Magnitude <= STEP_SIZE then break end
        if not ok2 then task.wait(0.2) end
    end
end

-- Obtém o MainGUI do TransportJobGui (e o torna visível)
local function getTransportGui()
    local tGui = pGui:FindFirstChild("TransportJobGui")
    if not tGui then return nil end
    local main = tGui:FindFirstChild("MainGUI")
    if not main then return nil end
    main.Visible = true
    return main
end

-- Extrai o maior número de uma string de texto (pagamento)
local function parsePay(txt)
    if not txt then return 0 end
    local n = 0
    for num in txt:gmatch("%d+%.?%d*") do
        local v = tonumber(num) or 0
        if v > n then n = v end
    end
    return n
end

local _hiddenJobFrames = {}   -- frames escondidos por melhorJob()

local function _findDesc(parent, name)
    for _, c in ipairs(parent:GetDescendants()) do
        if c.Name == name then return c end
    end
    return nil
end

-- Filtra a lista de entregas: mostra só a de maior valor, esconde as demais
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

-- Restaura todos os frames escondidos pelo melhorJob()
local function restaurarJobFrames()
    for _, frame in ipairs(_hiddenJobFrames) do
        pcall(function() frame.Visible = true end)
    end
    _hiddenJobFrames = {}
end

-- Retorna true se o player não tem mais nenhuma TranspBox
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

-- Resolve o destino de entrega a partir do texto da GUI
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

-- Loop principal do Delivery Farm
local function deliveryFarmLoop()

    -- Tenta clicar num TextButton por múltiplos métodos
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

    -- Lê o destino do job ativo fora da lista de jobs
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

    -- Ativa o imã de dentro do loop de entrega
    local function imaOn()
        if not AF.imaAtivo then
            tw(afTrack, { BackgroundColor3 = P.togOn })
            tw(afKnob,  { Position = UDim2.new(0, 19, 0.5, -6),
                          BackgroundColor3 = Color3.fromRGB(10, 10, 11) })
            afStatus.TextColor3 = P.blue
            tw(afAccent, { BackgroundColor3 = P.blue })
            iniciarIma(afStatus, afKnob, afTrack)
        end
    end

    -- Desativa o imã de dentro do loop de entrega
    local function imaOff()
        if AF.imaAtivo then
            pararIma(afStatus, afKnob, afTrack)
            afStatus.TextColor3 = P.textDim
            tw(afTrack, { BackgroundColor3 = P.togOff })
            tw(afKnob,  { Position = UDim2.new(0, 3, 0.5, -6),
                          BackgroundColor3 = Color3.fromRGB(90, 90, 104) })
            tw(afAccent, { BackgroundColor3 = P.textDim })
        end
    end

    -- ── Loop de ciclos ───────────────────────────────

    local ciclo = 0
    while deliveryFarmAtivo do
        ciclo = ciclo + 1

        -- PASSO 1: ir ao ponto de coleta
        dfLog("Ciclo #" .. ciclo .. " -> ponto de coleta", "")
        slowWalk(PICKUP_POS)
        if not deliveryFarmAtivo then break end

        -- PASSO 2: abrir GUI de entrega
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
            dfLog("GUI de entrega nao encontrada!", "Certifique-se de estar no local")
            task.wait(3)
        else
            -- PASSO 3: aguardar jobs carregarem (3s)
            for i = 3, 1, -1 do
                dfLog("Carregando entregas... " .. i .. "s", "Aguarde...")
                task.wait(1)
                if not deliveryFarmAtivo then break end
            end
            if not deliveryFarmAtivo then break end

            -- PASSO 4: filtrar jobs e clicar no melhor
            local job = melhorJob(mainGui)
            if not job then
                dfLog("Nenhuma entrega disponivel", "Tentando em 5s...")
                restaurarJobFrames()
                mainGui.Visible = false
                task.wait(5)
            else
                local destPos, destNome = resolveDestino(job.destination)
                if not destPos then
                    dfLog("Destino desconhecido: " .. tostring(job.destination), "Pulando...")
                    restaurarJobFrames()
                    mainGui.Visible = false
                    task.wait(3)
                else
                    dfLog("Melhor: R$" .. job.payVal .. " -> " .. destNome, "Clicando START...")
                    task.wait(0.4)
                    clickBtn(job.startBtn)
                    task.wait(0.4)
                    clickBtn(job.startBtn)   -- segundo clique de segurança

                    -- PASSO 5: aguardar servidor spawnar caixas
                    local confirmed = false
                    for w = 1, 20 do
                        if not deliveryFarmAtivo then break end
                        task.wait(1)
                        if not caixasEntregues() then
                            confirmed = true; break
                        end
                        if w % 4 == 0 then
                            clickBtn(job.startBtn)
                            dfLog("Re-clicando... (" .. w .. "s)", "R$" .. job.payVal .. " -> " .. destNome)
                        else
                            dfLog("Aguardando caixas... (" .. w .. "s)", "R$" .. job.payVal .. " -> " .. destNome)
                        end
                    end

                    -- Fallback manual (45s)
                    if not confirmed and deliveryFarmAtivo then
                        dfLog("Clique START manualmente!", "R$" .. job.payVal .. " -> " .. destNome)
                        setStatus("Clique START para continuar", P.blueL)
                        for w = 1, 45 do
                            if not deliveryFarmAtivo then break end
                            task.wait(1)
                            if not caixasEntregues() then confirmed = true; break end
                            dfLog("Aguardando (" .. w .. "/45s)...", "R$" .. job.payVal .. " -> " .. destNome)
                        end
                    end

                    -- PASSO 6: caixas pegas → restaura lista de jobs
                    if confirmed then restaurarJobFrames() end

                    -- Verifica se o servidor redirecionou para outro destino
                    local actualDest = getActiveJobDestination(mainGui)
                    if actualDest and actualDest ~= "" then
                        local newPos, newNome = resolveDestino(actualDest)
                        if newPos then destPos = newPos; destNome = newNome end
                    end

                    mainGui.Visible = false
                    if not deliveryFarmAtivo then break end

                    if not confirmed then
                        restaurarJobFrames()
                        dfLog("Timeout. Novo ciclo...", "")
                        task.wait(2)
                    else
                        -- PASSO 7: espera 7s para caixas spawnarem, depois ativa imã
                        for i = 7, 1, -1 do
                            if not deliveryFarmAtivo then break end
                            dfLog("Aguardando caixas spawnarem... " .. i .. "s", "Preparando Ima...")
                            task.wait(1)
                        end
                        if not deliveryFarmAtivo then break end

                        dfLog("Ativando Ima...", "Indo para " .. destNome)
                        imaOn()
                        task.wait(2)

                        showInfoBox("Indo entregar em: " .. destNome, "R$ " .. job.payVal)
                        dfLog("Indo para: " .. destNome, "R$" .. job.payVal .. " ao entregar")
                        slowWalk(destPos)
                        if not deliveryFarmAtivo then break end

                        -- PASSO 8: chegou — solta caixas e garante 100% de entrega
                        dfLog("Chegou em " .. destNome .. "!", "Soltando caixas...")
                        imaOff()
                        task.wait(1.5)

                        local tentativa = 0
                        while not caixasEntregues() and deliveryFarmAtivo do
                            tentativa = tentativa + 1
                            dfLog("Entregando... tentativa " .. tentativa, "Aguardando todas as caixas...")

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

                            -- A cada 3 tentativas, tenta offsets ao redor do ponto
                            if tentativa % 3 == 0 and not caixasEntregues() then
                                dfLog("Ajustando posicao...", "Tentativa " .. tentativa)
                                local offsets = {
                                    Vector3.new( 1, 0,  0), Vector3.new(-1, 0,  0),
                                    Vector3.new( 0, 0,  1), Vector3.new( 0, 0, -1),
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
                            dfLog("Entrega 100% concluida! Ciclo #" .. ciclo, "R$" .. job.payVal .. " ganhos")
                            setStatus("Entrega OK  R$ " .. job.payVal, P.success)
                            showInfoBox("Entrega concluida!", "R$ " .. job.payVal .. " ganhos — Ciclo #" .. ciclo)
                        end

                        task.wait(2)
                        if deliveryFarmAtivo then
                            showInfoBox("Buscando proxima entrega...", "Voltando ao ponto de coleta")
                        end
                    end
                end
            end
        end
    end

    dfLog("Auto Entrega parado", "")
end

-- Toggle do Delivery Farm
local function toggleDeliveryFarm()
    if deliveryFarmAtivo then
        deliveryFarmAtivo = false
        if deliveryFarmThread then
            task.cancel(deliveryFarmThread)
            deliveryFarmThread = nil
        end
        if AF.imaAtivo then
            pararIma(afStatus, afKnob, afTrack)
            tw(afTrack, { BackgroundColor3 = P.togOff })
            tw(afKnob,  { Position = UDim2.new(0, 3, 0.5, -6),
                          BackgroundColor3 = Color3.fromRGB(90, 90, 104) })
            afStatus.TextColor3 = P.textDim
            tw(afAccent, { BackgroundColor3 = P.textDim })
        end
        tw(dfTrack,    { BackgroundColor3 = P.togOff })
        tw(dfKnob,     { Position = UDim2.new(0, 3, 0.5, -6),
                         BackgroundColor3 = Color3.fromRGB(90, 90, 104) })
        tw(dfAccentBar, { BackgroundColor3 = P.textDim })
        dfLog("Auto Entrega desativado", "")
        setStatus("Auto Entrega desativado", P.textDim)
    else
        deliveryFarmAtivo  = true
        tw(dfTrack, { BackgroundColor3 = P.togOn })
        tw(dfKnob,  { Position = UDim2.new(0, 19, 0.5, -6),
                      BackgroundColor3 = Color3.fromRGB(10, 10, 11) })
        do
            local s = dfTrack:FindFirstChildWhichIsA("UIStroke")
            if s then tw(s, { Color = P.blue }) end
        end
        tw(dfAccentBar, { BackgroundColor3 = P.blue })   -- era laranja
        dfLog("Auto Entrega ativado!", "Iniciando ciclo...")
        setStatus("Auto Entrega iniciado!", P.success)

        deliveryFarmThread = task.spawn(function()
            local ok, err = pcall(deliveryFarmLoop)
            if not ok then
                dfLog("Erro no loop de entrega", tostring(err):sub(1, 60))
            end
        end)
    end
end

dfTogBtn.MouseButton1Click:Connect(toggleDeliveryFarm)

-- Para o Delivery Farm ao respawnar o personagem
player.CharacterAdded:Connect(function()
    pcall(function()
        if deliveryFarmAtivo then
            deliveryFarmAtivo = false
            if deliveryFarmThread then
                pcall(function() task.cancel(deliveryFarmThread) end)
            end
            tw(dfTrack, { BackgroundColor3 = P.togOff })
            tw(dfKnob,  { Position = UDim2.new(0, 3, 0.5, -6),
                          BackgroundColor3 = Color3.fromRGB(90, 90, 104) })
            dfLog("Auto Entrega parado (respawn)", "")
        end
    end)
end)

-- Conecta o toggle do imã ao botão e à tecla H
afTogBtn.MouseButton1Click:Connect(toggleIma)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then toggleIma() end
end)

player.CharacterAdded:Connect(function()
    if AF.imaAtivo then pararIma(afStatus, afKnob, afTrack) end
end)

end -- fim do bloco de construção de páginas


-- ─────────────────────────────────────────────────
--  PÁGINA: CONFIG
-- ─────────────────────────────────────────────────

local pgConfig = pages["Config"]
makeSectionHeader(pgConfig, "Configuracoes", "Teclas e preferencias do hub.")

-- Linha: redefinir tecla de toggle
makeInputRow(pgConfig, "Tecla de Toggle", "Atual:  RightShift", "BIND", function(btn, subLbl)
    if AF.waitingBind then return end
    AF.waitingBind = true
    btn.Text = "..."
    tw(btn, { TextColor3 = P.blueL })

    local conn
    conn = UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            AF.togllekey   = inp.KeyCode
            AF.waitingBind = false
            local kn       = inp.KeyCode.Name
            btn.Text       = "BIND"
            tw(btn, { TextColor3 = P.blue })
            if subLbl then subLbl.Text = "Atual:  " .. kn end
            KeyBadge.Text = kn:sub(1, 8)
            setStatus("OK  Tecla: " .. kn, P.success)
            conn:Disconnect()
        end
    end)
end)

-- Linha: toggle de notificações de status
makeToggleRow(pgConfig,
    "Notificacoes de Status",
    "Mostra mensagens na barra de status.",
    function(on)
        AF.statusEnabled = on
        if on then
            tw(StatBar, { BackgroundTransparency = 0.0 }, 0.2)
            setStatus("Notificacoes ativadas", P.success)
        else
            tw(StatBar, { BackgroundTransparency = 1.0 }, 0.2)
        end
    end
)

-- Linha: toggle de auto-reaplicar valores
makeToggleRow(pgConfig,
    "Auto-Reaplicar Valores",
    "Reaaplica automaticamente ao spawnar o carro.",
    function(on)
        AF.autoReapply  = on
        AF.statusEnabled = true
        if on then
            for vname, val in pairs(_lastApplied) do
                if _vconn[vname] then
                    pcall(function() _vconn[vname]:Disconnect() end)
                end
                local v, capturedVal = vname, val
                _vconn[v] = game.DescendantAdded:Connect(function(obj)
                    if obj:IsA("ValueBase") and obj.Name == v then
                        task.defer(function() pcall(function() obj.Value = capturedVal end) end)
                    end
                end)
            end
            setStatus("Auto-Reaplicar ativado", P.success)
        else
            for vname, conn in pairs(_vconn) do
                pcall(function() conn:Disconnect() end)
                _vconn[vname] = nil
            end
            setStatus("Auto-Reaplicar desativado", P.textDim)
        end
    end
)

-- ── Modo Anônimo ─────────────────────────────────
-- Isolado em do...end para economizar registros locais

local _anonActive = false
local _anonConns  = {}

do
    local _realName = player.Name
    local _anonName = "Anonymous"

    local function setAnonName(name)
        pcall(function() SBPlayerName.Text = name end)
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
        -- Varre o CoreGui para substituir o nome em labels visíveis
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
        if _anonActive then return end
        _anonActive  = true
        setAnonName(_anonName)
        _anonConns[1] = player.CharacterAdded:Connect(function()
            task.wait(1)
            if _anonActive then setAnonName(_anonName) end
        end)
        _anonConns[2] = task.spawn(function()
            while _anonActive do
                task.wait(2)
                if _anonActive then setAnonName(_anonName) end
            end
        end)
        setStatus("Modo Anonimo ativado", P.success)
    end

    local function disableAnon()
        if not _anonActive then return end
        _anonActive = false
        for _, c in ipairs(_anonConns) do
            pcall(function()
                if type(c) == "userdata" then c:Disconnect()
                elseif type(c) == "thread" then task.cancel(c) end
            end)
        end
        _anonConns = {}
        setAnonName(_realName)
        setStatus("Modo Anonimo desativado", P.textDim)
    end

    makeToggleRow(pgConfig,
        "Modo Anonimo",
        "Oculta seu nome no hub e no leaderboard.",
        function(on)
            if on then enableAnon() else disableAnon() end
        end
    )
end


-- ════════════════════════════════════════════════════════════════════
--  SISTEMA DE TEMAS
-- ════════════════════════════════════════════════════════════════════

local THEMES = {
    {
        id       = "dark",
        name     = "Dark",
        win      = Color3.fromRGB( 10,  10,  11),
        sidebar  = Color3.fromRGB( 10,  10,  11),
        rowHov   = Color3.fromRGB( 24,  24,  29),
        section  = Color3.fromRGB( 17,  17,  20),
        input    = Color3.fromRGB( 31,  31,  38),
        divider  = Color3.fromRGB( 42,  42,  53),
        accent   = Color3.fromRGB(212, 255,   0),
        accentL  = Color3.fromRGB(234, 255,  80),
        textPri  = Color3.fromRGB(240, 239, 234),
        textSub  = Color3.fromRGB(156, 156, 168),
        textDim  = Color3.fromRGB( 90,  90, 104),
        togOff   = Color3.fromRGB( 31,  31,  38),
        winBorder= Color3.fromRGB( 54,  54,  66),
        sw       = { "#0A0A0B", "#000000", "#EAFF50", "#F0EFEA" },
    },
}

local currentThemeIdx = 1

-- Aplica todos os dados de um tema à UI
local function applyThemeData(th)
    -- 1. Atualiza a tabela P
    P.win    = th.win;    P.sidebar = th.sidebar; P.rowHov  = th.rowHov
    P.section= th.section; P.input = th.input;   P.divider = th.divider
    P.blue   = th.accent; P.blueL  = th.accentL; P.togOn   = th.accent
    P.togOff = th.togOff; P.textPri= th.textPri; P.textSub = th.textSub
    P.textDim= th.textDim

    -- 2. Elementos estruturais
    Win.BackgroundColor3            = th.win
    WallpaperFrame.BackgroundColor3 = th.win
    Sidebar.BackgroundColor3        = th.sidebar
    SBBottom.BackgroundColor3       = th.sidebar
    StatBar.BackgroundColor3        = th.win
    StatLine.BackgroundColor3       = th.divider
    StatLbl.TextColor3              = th.textDim
    StatVersion.TextColor3          = th.textDim
    StatDot.BackgroundColor3        = th.accent
    SBLine.BackgroundColor3         = th.divider
    SBBottomLine.BackgroundColor3   = th.divider
    TBLine.BackgroundColor3         = th.divider
    HubName.TextColor3              = th.textPri
    HubSub.TextColor3               = th.textDim
    KeyBadge.TextColor3             = th.accentL
    KeyBadge.BackgroundColor3       = th.win
    LogoMark.BackgroundColor3       = th.accent
    SBDot.BackgroundColor3          = th.accent
    SBPlayerName.TextColor3         = th.textSub
    TopBar.BackgroundColor3         = th.win

    -- Frame interno do TopBar
    for _, c in ipairs(TopBar:GetChildren()) do
        if c:IsA("Frame") and c.Name ~= "LogoMark" then
            c.BackgroundColor3 = th.win
        end
    end

    -- Bordas
    do local s = Win:FindFirstChildWhichIsA("UIStroke")
        if s then s.Color = th.winBorder end end
    do local s = KeyBadge:FindFirstChildWhichIsA("UIStroke")
        if s then s.Color = th.accent end end

    -- Cor do "K" dentro do LogoMark
    do
        local lk = LogoMark:FindFirstChild("TextLabel")
        if not lk then
            for _, c in ipairs(LogoMark:GetChildren()) do
                if c:IsA("TextLabel") then lk = c; break end
            end
        end
        if lk then lk.TextColor3 = Color3.fromRGB(10, 10, 11) end
    end

    -- 3. Botões de navegação
    for id, nb in pairs(navBtns) do
        nb.bg.BackgroundColor3  = th.rowHov
        nb.lbl.TextColor3       = (id == AF.activeTab) and th.textPri or th.textSub
        nb.bar.BackgroundColor3 = th.accent
    end

    -- 4. Botões de janela
    for _, child in ipairs(TopBar:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = Color3.fromRGB(26, 26, 31)
            child.TextColor3       = th.textDim
        end
    end

    -- 5. InfoBox
    IBStroke.Color                = th.accent
    IBIconCircle.BackgroundColor3 = th.accent
    IBBar.BackgroundColor3        = th.accent
    IBLabel.TextColor3            = th.textPri
    IBValue.TextColor3            = th.accentL
    InfoBox.BackgroundColor3      = th.section
    do local s = InfoBox:FindFirstChildWhichIsA("UIStroke")
        if s then s.Color = th.accent end end

    -- 6. Strips de accent do AutoFarm
    dfSectionAccent.BackgroundColor3 = th.accent
    dfInfoStrip.BackgroundColor3     = th.accent
    afAccentStrip.BackgroundColor3   = th.accent

    -- 7. Separadores
    StatSep.BackgroundColor3 = th.divider
    SBDot.BackgroundColor3   = th.accent

    -- 8. Scrollbars
    for _, pg in pairs(pages) do
        pg.ScrollBarImageColor3 = th.accent
    end

    -- 9. Registros de tema (_themeReg)
    for _, entry in ipairs(_themeReg) do applyReg(entry) end

    -- 10. Barras accent dos botões de nav
    for _, obj in ipairs(SG:GetDescendants()) do
        pcall(function()
            if obj.Name == "bar" and obj:IsA("Frame") then
                obj.BackgroundColor3 = th.accent
            end
        end)
    end
end

-- ── Seção de temas na página Config ──────────────

local thHdr = Instance.new("Frame")
thHdr.Size                   = UDim2.new(1, 0, 0, 26)
thHdr.BackgroundTransparency = 1
thHdr.ZIndex                 = 8
thHdr.Parent                 = pgConfig

local thHl = Instance.new("TextLabel")
thHl.Text               = "  TEMA DE CORES"
thHl.Size               = UDim2.new(1, 0, 1, 0)
thHl.BackgroundTransparency = 1
thHl.TextColor3         = P.textDim
thHl.TextSize           = 10
thHl.Font               = Enum.Font.GothamBold
thHl.TextXAlignment     = Enum.TextXAlignment.Left
thHl.ZIndex             = 9
thHl.Parent             = thHdr

local themeBtnRefs = {}

for ti, th in ipairs(THEMES) do
    local isActive = (ti == currentThemeIdx)

    local tRow = Instance.new("Frame")
        tRow.Size             = UDim2.new(1, 0, 0, 54)
        tRow.BackgroundColor3 = P.rowHov
        tRow.BackgroundTransparency = isActive and 0 or 1
        tRow.BorderSizePixel  = 0
        tRow.ZIndex           = 8
        tRow.Parent           = pgConfig

    local tAccent = Instance.new("Frame")
        tAccent.Size             = UDim2.new(0, 3, 1, 0)
        tAccent.BackgroundColor3 = isActive and th.accent or P.divider
        tAccent.BackgroundTransparency = isActive and 0 or 1
        tAccent.BorderSizePixel  = 0
        tAccent.ZIndex           = 9
        tAccent.Parent           = tRow

    -- Swatches de cor do tema
    local sfWrap = Instance.new("Frame")
        sfWrap.Size                   = UDim2.new(0, 76, 0, 28)
        sfWrap.Position               = UDim2.new(0, 14, 0.5, -14)
        sfWrap.BackgroundTransparency = 1
        sfWrap.ZIndex                 = 9
        sfWrap.Parent                 = tRow
    do
        local ll = Instance.new("UIListLayout")
        ll.FillDirection      = Enum.FillDirection.Horizontal
        ll.Padding            = UDim.new(0, 2)
        ll.VerticalAlignment  = Enum.VerticalAlignment.Center
        ll.Parent             = sfWrap
    end
    for _, hex in ipairs(th.sw) do
        local r  = tonumber(hex:sub(2, 3), 16) or 0
        local g  = tonumber(hex:sub(4, 5), 16) or 0
        local b2 = tonumber(hex:sub(6, 7), 16) or 0
        local sf = Instance.new("Frame")
        sf.Size             = UDim2.new(0, 16, 0, 24)
        sf.BackgroundColor3 = Color3.fromRGB(r, g, b2)
        sf.BorderSizePixel  = 0
        sf.ZIndex           = 10
        sf.Parent           = sfWrap
    end

    local tnl = Instance.new("TextLabel")
        tnl.Text               = th.name
        tnl.Size               = UDim2.new(0, 100, 0, 18)
        tnl.Position           = UDim2.new(0, 100, 0.5, -9)
        tnl.BackgroundTransparency = 1
        tnl.TextColor3         = isActive and P.textPri or P.textSub
        tnl.TextSize           = 12
        tnl.Font               = Enum.Font.GothamBold
        tnl.TextXAlignment     = Enum.TextXAlignment.Left
        tnl.ZIndex             = 9
        tnl.Parent             = tRow

    local tbtn = Instance.new("TextButton")
        tbtn.Text             = isActive and "ATIVO" or "USAR"
        tbtn.Size             = UDim2.new(0, 66, 0, 28)
        tbtn.Position         = UDim2.new(1, -78, 0.5, -14)
        tbtn.BackgroundColor3 = isActive and th.accent or Color3.fromRGB(17, 17, 20)
        tbtn.BorderSizePixel  = 0
        tbtn.TextColor3       = isActive and Color3.fromRGB(10, 10, 11) or P.blue
        tbtn.TextSize         = 11
        tbtn.Font             = Enum.Font.GothamBold
        tbtn.ZIndex           = 9
        tbtn.Parent           = tRow
    rnd(tbtn, 2)
    if not isActive then 
        brdr(tbtn, P.divider, 1, 0) 
    end

    do
        local div = Instance.new("Frame")
            div.Size                   = UDim2.new(1, 0, 0, 1)
            div.Position               = UDim2.new(0, 0, 1, -1)
            div.BackgroundColor3       = P.divider
            div.BackgroundTransparency = 0
            div.BorderSizePixel        = 0
            div.ZIndex                 = 8
            div.Parent                 = tRow
    end

    table.insert(themeBtnRefs, {
        row     = tRow,
        btn     = tbtn,
        th      = th,
        idx     = ti,
        accent  = tAccent,
        namelbl = tnl,
    })

    tbtn.MouseEnter:Connect(function()
        if currentThemeIdx ~= ti then
            tw(tbtn, { BackgroundColor3 = Color3.fromRGB(24, 24, 29) })
        end
    end)

    tbtn.MouseLeave:Connect(function()
        if currentThemeIdx ~= ti then
            tw(tbtn, { BackgroundColor3 = Color3.fromRGB(17, 17, 20) })
        end
    end)
    
    tbtn.MouseButton1Click:Connect(function()
        if currentThemeIdx == ti then 
            return 
        end

        currentThemeIdx = ti
        
        applyThemeData(th)

        for _, ref in ipairs(themeBtnRefs) do
            if ref.idx == ti then

                ref.btn.Text = "ATIVO"

                tw(ref.btn,    { 
                    BackgroundColor3 = th.accent,    
                    TextColor3 = Color3.fromRGB(10, 10, 11) 
                })

                tw(ref.row,    { 
                    BackgroundTransparency = 0,      
                    BackgroundColor3 = th.rowHov 
                })

                ref.row.BackgroundColor3 = th.rowHov
                tw(ref.accent, { 
                    BackgroundColor3 = th.accent,    
                    BackgroundTransparency = 0 
                })

                tw(ref.namelbl,{ 
                    TextColor3 = th.textPri 
                })
            else
                ref.btn.Text = "USAR"
                tw(ref.btn,    { 
                    BackgroundColor3 = Color3.fromRGB(17, 17, 20), 
                    TextColor3 = P.blue 
                })
                tw(ref.row,    { 
                    BackgroundTransparency = 1 
                })
                tw(ref.accent, { 
                    BackgroundTransparency = 1 
                })
                tw(ref.namelbl,{ 
                    TextColor3 = P.textSub 
                })
            end
        end
        setStatus("Tema: " .. th.name, P.success)
    end)
end


-- ════════════════════════════════════════════════════════════════════
--  DRAG / TOGGLE / DASH
--  Bloco isolado para não estourar o limite de 200 locais do LuaU.
-- ════════════════════════════════════════════════════════════════════

do
    -- ── Arrastar a janela ────────────────────────

    local dragging   = false
    local dragOffset = Vector2.new(0, 0)

    TopBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging   = true
            local ap   = Win.AbsolutePosition
            dragOffset = Vector2.new(inp.Position.X - ap.X, inp.Position.Y - ap.Y)
        end
    end)

    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local ss = SG.AbsoluteSize
            local nx = math.clamp(inp.Position.X - dragOffset.X, 0, ss.X - WIN_W)
            local ny = math.clamp(inp.Position.Y - dragOffset.Y, 0, ss.Y - WIN_H)
            Win.Position = UDim2.new(0, nx, 0, ny)
        end
    end)

    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- ── Toggle da GUI + Dash (tecla X) ──────────

    UIS.InputBegan:Connect(function(inp, gpe)
        -- Toggle GUI
        if not AF.waitingBind and inp.KeyCode == AF.togllekey then
            AF.guiOpen = not AF.guiOpen
            if AF.guiOpen then
                Win.Visible = true
                Win.Size    = UDim2.new(0, WIN_W, 0, 0)
                tw(Win, { Size = UDim2.new(0, WIN_W, 0, WIN_H) }, .35,
                    Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            else
                tw(Win, { Size = UDim2.new(0, WIN_W, 0, 0) }, .25,
                    Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                task.delay(.22, function()
                    if not AF.guiOpen then Win.Visible = false end
                end)
            end
            return
        end

        -- Dash
        if not gpe and inp.KeyCode == Enum.KeyCode.X then
            local spd  = tonumber(spInp.Text) or 0
            if spd == 0 then return end
            local char = player.Character
            if not char then return end
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local dir  = hrp.CFrame.LookVector * spd

            -- Método 1: AssemblyLinearVelocity (preferido)
            local ok1 = pcall(function()
                hrp.AssemblyLinearVelocity = dir
            end)

            -- Método 2: LinearVelocity constraint (nova API)
            if not ok1 then
                pcall(function()
                    local att = Instance.new("Attachment"); att.Parent = hrp
                    local lv  = Instance.new("LinearVelocity")
                    lv.Attachment0  = att
                    lv.VectorVelocity = dir
                    lv.MaxForce     = 1e7
                    lv.RelativeTo   = Enum.ActuatorRelativeTo.World
                    lv.Parent       = hrp
                    task.delay(0.18, function()
                        pcall(function() lv:Destroy(); att:Destroy() end)
                    end)
                end)
            end

            -- Método 3: BodyVelocity (deprecated, fallback)
            if not ok1 then
                pcall(function()
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(1e7, 0, 1e7)
                    bv.Velocity = dir
                    bv.Parent   = hrp
                    task.delay(0.2, function() pcall(function() bv:Destroy() end) end)
                end)
            end

            setStatus("Dash: " .. spd .. " studs/s", P.blueL)
        end
    end)
end -- fim do bloco drag/toggle/dash


-- ════════════════════════════════════════════════════════════════════
--  SALVAR / CARREGAR CONFIG (arquivo único)
-- ════════════════════════════════════════════════════════════════════

local SAVE_FILE = "karfi_hub_config.json"

-- Serialização JSON mínima (apenas tipos primitivos)
local function jsonEncode(t)
    local parts = {}
    for k, v in pairs(t) do
        local key = '"' .. tostring(k) .. '"'
        local val
        if     type(v) == "string"  then val = '"' .. v:gsub('"', '\"') .. '"'
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

-- Monta o objeto de dados a salvar
local function buildSaveData()
    local d = {}
    d.togllekey     = togllekey.Name
    d.theme         = currentThemeIdx
    d.statusEnabled = AF.statusEnabled
    d.autoReapply   = AF.autoReapply
    for vname, ref in pairs(inputRefs) do
        d["inp_" .. vname] = ref.inp.Text
    end
    if spInp then d.inp_SpeedDash = spInp.Text end
    return d
end

local function saveConfig()
    local ok = pcall(function()
        _writefile(SAVE_FILE, jsonEncode(buildSaveData()))
    end)
    if ok then setStatus("Config salva!", P.success)
    else       setStatus("Erro ao salvar config", P.err) end
end

local function loadConfig()
    local ok, raw = pcall(_readfile, SAVE_FILE)
    if not ok or not raw or raw == "" then return end
    local ok2, d = pcall(jsonDecode, raw)
    if not ok2 or not d then return end

    if d.togllekey and Enum.KeyCode[d.togllekey] then
        AF.togllekey  = Enum.KeyCode[d.togllekey]
        KeyBadge.Text = d.togllekey:sub(1, 8)
    end
    if d.theme and THEMES[d.theme] then
        currentThemeIdx = d.theme
        applyThemeData(THEMES[d.theme])
        for _, ref in ipairs(themeBtnRefs) do
            if ref.idx == d.theme then
                ref.btn.Text = "ATIVO"
                tw(ref.btn, { BackgroundColor3 = THEMES[d.theme].accent,
                               TextColor3      = Color3.fromRGB(10, 10, 11) })
                tw(ref.row, { BackgroundTransparency = 0,
                               BackgroundColor3 = THEMES[d.theme].rowHov })
            else
                ref.btn.Text = "USAR"
                tw(ref.btn, { BackgroundColor3 = Color3.fromRGB(17, 17, 20),
                               TextColor3      = P.blue })
                tw(ref.row, { BackgroundTransparency = 1 })
            end
        end
    end
    if d.statusEnabled ~= nil then AF.statusEnabled = d.statusEnabled end
    if d.autoReapply   ~= nil then AF.autoReapply   = d.autoReapply   end
    for vname, ref in pairs(inputRefs) do
        local saved = d["inp_" .. vname]
        if saved and saved ~= "" then ref.inp.Text = tostring(saved) end
    end
    if spInp and d.inp_SpeedDash and d.inp_SpeedDash ~= "" then
        spInp.Text = tostring(d.inp_SpeedDash)
    end
    setStatus("Config carregada!", P.success)
end


-- ════════════════════════════════════════════════════════════════════
--  SISTEMA DE PERFIS MÚLTIPLOS
-- ════════════════════════════════════════════════════════════════════

local CFG_FOLDER        = "karfi_configs"
local CFG_INDEX         = CFG_FOLDER .. "/index.json"
local activeProfileName = "default"

pcall(_makefolder, CFG_FOLDER)

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
        table.insert(parts, '"' .. n:gsub('"', '\"') .. '"')
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

local function saveProfile(name)
    local path = profilePath(name)
    local ok   = pcall(_writefile, path, jsonEncode(buildSaveData()))
    if ok then addToIndex(name) end
    return ok
end

local function loadProfile(name)
    local path      = profilePath(name)
    local ok, raw   = pcall(_readfile, path)
    if not ok or not raw or raw == "" then return false end
    local ok2, d    = pcall(jsonDecode, raw)
    if not ok2 or not d then return false end

    if d.togglekey and Enum.KeyCode[d.togglekey] then
        AF.togllekey  = Enum.KeyCode[d.togglekey]
        KeyBadge.Text = d.togglekey:sub(1, 8)
    end
    if d.theme and THEMES[d.theme] then
        currentThemeIdx = d.theme
        applyThemeData(THEMES[d.theme])
        for _, ref in ipairs(themeBtnRefs) do
            if ref.idx == d.theme then
                ref.btn.Text = "ATIVO"
                tw(ref.btn, { BackgroundColor3 = THEMES[d.theme].accent,
                               TextColor3      = Color3.fromRGB(10, 10, 11) })
                tw(ref.row, { BackgroundTransparency = 0,
                               BackgroundColor3 = THEMES[d.theme].rowHov })
                ref.row.BackgroundColor3 = THEMES[d.theme].rowHov
            else
                ref.btn.Text = "USAR"
                tw(ref.btn, { BackgroundColor3 = Color3.fromRGB(17, 17, 20),
                               TextColor3      = P.blue })
                tw(ref.row, { BackgroundTransparency = 1 })
            end
        end
    end
    if d.statusEnabled ~= nil then AF.statusEnabled = d.statusEnabled end
    if d.autoReapply   ~= nil then AF.autoReapply   = d.autoReapply   end
    for vname, ref in pairs(inputRefs) do
        local v = d["inp_" .. vname]
        if v and tostring(v) ~= "" then ref.inp.Text = tostring(v) end
    end
    if spInp and d.inp_SpeedDash and tostring(d.inp_SpeedDash) ~= "" then
        spInp.Text = tostring(d.inp_SpeedDash)
    end
    activeProfileName = name
    return true
end

local function deleteProfile(name)
    local ok = pcall(_delfile, profilePath(name))
    if not ok then pcall(_writefile, profilePath(name), "{}") end
    removeFromIndex(name)
end


-- ─────────────────────────────────────────────────
--  UI DE GERENCIAMENTO DE PERFIS
-- ─────────────────────────────────────────────────

local cfgMgmtHdr = Instance.new("Frame")
    cfgMgmtHdr.Size                   = UDim2.new(1, 0, 0, 26)
    cfgMgmtHdr.BackgroundTransparency = 1
    cfgMgmtHdr.BorderSizePixel        = 0
    cfgMgmtHdr.ZIndex                 = 8
    cfgMgmtHdr.Parent                 = pgConfig

local cfgMgmtLbl = Instance.new("TextLabel")
    cfgMgmtLbl.Text               = "  PERFIS DE CONFIGURAÇÃO"
    cfgMgmtLbl.Size               = UDim2.new(1, 0, 1, 0)
    cfgMgmtLbl.BackgroundTransparency = 1
    cfgMgmtLbl.TextColor3         = P.textDim
    cfgMgmtLbl.TextSize           = 10
    cfgMgmtLbl.Font               = Enum.Font.GothamBold
    cfgMgmtLbl.TextXAlignment     = Enum.TextXAlignment.Left
    cfgMgmtLbl.ZIndex             = 9
    cfgMgmtLbl.Parent             = cfgMgmtHdr

-- Campo de nome do perfil
local nameCard = Instance.new("Frame")
    nameCard.Size             = UDim2.new(1, 0, 0, 60)
    nameCard.BackgroundColor3 = P.rowHov
    nameCard.BackgroundTransparency = 0
    nameCard.BorderSizePixel  = 0
    nameCard.ZIndex           = 8
    nameCard.Parent           = pgConfig
rnd(nameCard, 2)

local nameLblTop = Instance.new("TextLabel")
    nameLblTop.Text               = "Nome do perfil:"
    nameLblTop.Size               = UDim2.new(1, -28, 0, 16)
    nameLblTop.Position           = UDim2.new(0, 14, 0, 8)
    nameLblTop.BackgroundTransparency = 1
    nameLblTop.TextColor3         = P.textSub
    nameLblTop.TextSize           = 10
    nameLblTop.Font               = Enum.Font.GothamBold
    nameLblTop.TextXAlignment     = Enum.TextXAlignment.Left
    nameLblTop.ZIndex             = 9
    nameLblTop.Parent             = nameCard

local nameInpF = Instance.new("Frame")
    nameInpF.Size             = UDim2.new(1, -24, 0, 28)
    nameInpF.Position         = UDim2.new(0, 12, 0, 28)
    nameInpF.BackgroundColor3 = P.input
    nameInpF.BorderSizePixel  = 0
    nameInpF.ZIndex           = 9
    nameInpF.Parent           = nameCard
rnd(nameInpF, 2)
local nameInpS = Instance.new("UIStroke")
    nameInpS.Color     = P.divider
    nameInpS.Thickness = 1
    nameInpS.Parent    = nameInpF

local nameInp = Instance.new("TextBox")
    nameInp.PlaceholderText    = "ex: turbo_max, corrida..."
    nameInp.Text               = "default"
    nameInp.Size               = UDim2.new(1, -8, 1, 0)
    nameInp.Position           = UDim2.new(0, 6, 0, 0)
    nameInp.BackgroundTransparency = 1
    nameInp.TextColor3         = P.textPri
    nameInp.PlaceholderColor3  = P.textDim
    nameInp.TextSize           = 11
    nameInp.Font               = Enum.Font.Gotham
    nameInp.ClearTextOnFocus   = false
    nameInp.TextXAlignment     = Enum.TextXAlignment.Left
    nameInp.BorderSizePixel    = 0
    nameInp.ZIndex             = 10
    nameInp.Parent             = nameInpF
nameInp.Focused:Connect(function()   
    tw(nameInpS, { 
        Color = P.blue    
    }) 
end)
nameInp.FocusLost:Connect(function() 
    tw(nameInpS, { 
        Color = P.divider 
    }) 
end)

-- Linha de botões de ação (Salvar / Carregar / Excluir)
local cfgActCard = Instance.new("Frame")
    cfgActCard.Size                   = UDim2.new(1, 0, 0, 44)
    cfgActCard.BackgroundTransparency = 1
    cfgActCard.BorderSizePixel        = 0
    cfgActCard.ZIndex                 = 8
    cfgActCard.Parent                 = pgConfig

local cfgActLayout = Instance.new("UIListLayout")
    cfgActLayout.FillDirection       = Enum.FillDirection.Horizontal
    cfgActLayout.Padding             = UDim.new(0, 6)
    cfgActLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cfgActLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    cfgActLayout.Parent              = cfgActCard

-- Cria um botão de ação de config estilizado
local function makeCfgBtn(parent, label, bgCol, hoverCol, w, callback)
    local b = Instance.new("TextButton")
        b.Text             = label
        b.Size             = UDim2.new(0, w, 0, 32)
        b.BackgroundColor3 = bgCol
        b.BorderSizePixel  = 0
        b.TextColor3       = Color3.fromRGB(10, 10, 11)
        b.TextSize         = 11
        b.Font             = Enum.Font.GothamBold
        b.ZIndex           = 9
        b.Parent           = parent
    rnd(b, 2)
    b.MouseEnter:Connect(function()  
        tw(b, { 
            BackgroundColor3 = hoverCol 
        }, 0.12) 
    end)
    b.MouseLeave:Connect(function()  
        tw(b, { 
            BackgroundColor3 = bgCol    
        }, 0.12) 
    end)
    b.MouseButton1Click:Connect(function() 
        callback(b) 
    end)
    return b
end

-- Referência antecipada (usada dentro dos botões)
local function refreshProfileList() end

-- Botão SALVAR
makeCfgBtn(cfgActCard, "Salvar", P.blue, P.blueL, 144, function(b)
    local name = nameInp.Text:match("^%s*(.-)%s*$")
    if name == "" then 
        name = "default" 
    end
    name = name:gsub("[^%w%-%_]", "_"):sub(1, 24)

    local ok = saveProfile(name)
    activeProfileName = ok and name or activeProfileName
    b.Text = ok and "Salvo!" or "Erro"
    tw(b, { 
        BackgroundColor3 = ok and P.success or P.err 
    }, 0.12)
    setStatus(
        ok and ("Perfil '" .. name .. "' salvo!") or "Erro ao salvar",
        ok and P.success or P.err
    )
    task.delay(2, function()
        b.Text = "Salvar"
        tw(b, { BackgroundColor3 = P.blue }, 0.12)
    end)
    task.defer(refreshProfileList)
end)

-- Botão CARREGAR
makeCfgBtn(cfgActCard, "Carregar",
    Color3.fromRGB(50, 110, 80), Color3.fromRGB(65, 140, 100), 144,
    function(b)
        local name = nameInp.Text:match("^%s*(.-)%s*$")
        if name == "" then 
            setStatus("Digite um nome de perfil", P.err); 
            return 
        end
        name = name:gsub("[^%w%-%_]", "_"):sub(1, 24)

        local ok = loadProfile(name)
        b.Text = ok and "Carregado!" or "Nao encontrado"
        tw(b, { 
            BackgroundColor3 = ok and P.success or P.err 
        }, 0.12)
        setStatus(
            ok and ("Perfil '" .. name .. "' carregado!") or "Perfil nao encontrado",
            ok and P.success or P.err
        )
        task.delay(2, function()
            b.Text = "Carregar"
            tw(b, { 
                BackgroundColor3 = Color3.fromRGB(50, 110, 80) 
            }, 0.12)
        end)
    end
)

-- Botão EXCLUIR (com confirmação dupla)
local deletePending = false
makeCfgBtn(cfgActCard, "Excluir",
    Color3.fromRGB(80, 25, 25), P.err, 98,
    function(b)
        if not deletePending then

            deletePending = true
            b.Text = "Confirmar?"

            tw(b, { 
                BackgroundColor3 = P.err 
            }, 0.12)

            task.delay(3, function()
                if deletePending then

                    deletePending = false
                    b.Text = "Excluir"

                    tw(b, { 
                        BackgroundColor3 = Color3.fromRGB(80, 25, 25) 
                    }, 0.12)
                end
            end)
        else

            deletePending = false

            local name = nameInp.Text:match("^%s*(.-)%s*$"):gsub("[^%w%-%_]", "_"):sub(1, 24)
            deleteProfile(name)

            b.Text = "Excluido"

            tw(b, { 
                BackgroundColor3 = P.success, 
                TextColor3 = Color3.fromRGB(10, 10, 11) 
            }, 0.12)

            setStatus("Perfil '" .. name .. "' excluido", P.textDim)

            task.delay(2, function()
                b.Text = "Excluir"

                tw(b, { 
                    BackgroundColor3 = Color3.fromRGB(80, 25, 25) 
                }, 0.12)
            end)
            refreshProfileList()
        end
    end
)

-- ── Lista de perfis salvos ───────────────────────

local listHdr = Instance.new("Frame")
    listHdr.Size                   = UDim2.new(1, 0, 0, 26)
    listHdr.BackgroundTransparency = 1
    listHdr.BorderSizePixel        = 0
    listHdr.ZIndex                 = 8
    listHdr.Parent                 = pgConfig

local listHl = Instance.new("TextLabel")
    listHl.Text               = "  PERFIS SALVOS"
    listHl.Size               = UDim2.new(1, 0, 1, 0)
    listHl.BackgroundTransparency = 1
    listHl.TextColor3         = P.textDim
    listHl.TextSize           = 10
    listHl.Font               = Enum.Font.GothamBold
    listHl.TextXAlignment     = Enum.TextXAlignment.Left
    listHl.ZIndex             = 9
    listHl.Parent             = listHdr

local profileListFrame = Instance.new("ScrollingFrame")
    profileListFrame.Size                  = UDim2.new(1, 0, 0, 160)
    profileListFrame.BackgroundColor3      = Color3.fromRGB(13, 13, 16)
    profileListFrame.BackgroundTransparency= 0
    profileListFrame.BorderSizePixel       = 0
    profileListFrame.ScrollBarThickness    = 2
    profileListFrame.ScrollBarImageColor3  = P.blue
    profileListFrame.CanvasSize            = UDim2.new(0, 0, 0, 0)
    profileListFrame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    profileListFrame.ZIndex                = 8
    profileListFrame.Parent                = pgConfig
rnd(profileListFrame, 2)

local profileListLayout = Instance.new("UIListLayout")
    profileListLayout.Padding = UDim.new(0, 0)
    profileListLayout.Parent  = profileListFrame

local profilePad = Instance.new("UIPadding")
    profilePad.PaddingTop    = UDim.new(0, 4)
    profilePad.PaddingBottom = UDim.new(0, 4)
    profilePad.PaddingLeft   = UDim.new(0, 8)
    profilePad.PaddingRight  = UDim.new(0, 8)
    profilePad.Parent        = profileListFrame

local emptyLbl = Instance.new("TextLabel")
    emptyLbl.Text               = "Nenhum perfil salvo ainda."
    emptyLbl.Size               = UDim2.new(1, 0, 0, 40)
    emptyLbl.BackgroundTransparency = 1
    emptyLbl.TextColor3         = P.textDim
    emptyLbl.TextSize           = 10
    emptyLbl.Font               = Enum.Font.Gotham
    emptyLbl.TextXAlignment     = Enum.TextXAlignment.Center
    emptyLbl.ZIndex             = 9
    emptyLbl.Parent             = profileListFrame

-- Reconstrói a lista de perfis salvos
function refreshProfileList()
    for _, child in ipairs(profileListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local profiles = readIndex()
    emptyLbl.Visible = (#profiles == 0)

    for _, pname in ipairs(profiles) do
        local isActive = (pname == activeProfileName)

        local entry = Instance.new("Frame")
            entry.Size             = UDim2.new(1, 0, 0, 36)
            entry.BackgroundColor3 = isActive
                and Color3.fromRGB(24, 24, 29)
                or  Color3.fromRGB(17, 17, 20)
            entry.BackgroundTransparency = 0
            entry.BorderSizePixel  = 0
            entry.ZIndex           = 9
            entry.Parent           = profileListFrame

        local eAccent = Instance.new("Frame")
            eAccent.Size             = UDim2.new(0, 3, 1, 0)
            eAccent.BackgroundColor3 = isActive and P.blue or P.divider
            eAccent.BorderSizePixel  = 0
            eAccent.ZIndex           = 10
            eAccent.Parent           = entry

        local nl = Instance.new("TextLabel")
            nl.Text               = (isActive and "● " or "  ") .. pname
            nl.Size               = UDim2.new(1, -120, 1, 0)
            nl.Position           = UDim2.new(0, 14, 0, 0)
            nl.BackgroundTransparency = 1
            nl.TextColor3         = isActive and P.blue or P.textSub
            nl.TextSize           = 12
            nl.Font               = Enum.Font.GothamBold
            nl.TextXAlignment     = Enum.TextXAlignment.Left
            nl.ZIndex             = 10
            nl.Parent             = entry

        -- Botão USAR
        local usarBtn = Instance.new("TextButton")
            usarBtn.Text             = isActive and "ATIVO" or "USAR"
            usarBtn.Size             = UDim2.new(0, 52, 0, 24)
            usarBtn.Position         = UDim2.new(1, -118, 0.5, -12)
            usarBtn.BackgroundColor3 = isActive and P.blue or Color3.fromRGB(17, 17, 20)
            usarBtn.BorderSizePixel  = 0
            usarBtn.TextColor3       = isActive and Color3.fromRGB(10, 10, 11) or P.blue
            usarBtn.TextSize         = 10
            usarBtn.Font             = Enum.Font.GothamBold
            usarBtn.ZIndex           = 11
            usarBtn.Parent           = entry
            rnd(usarBtn, 2)
        if not isActive then 
            brdr(usarBtn, P.divider, 1, 0) 
        end

        usarBtn.MouseButton1Click:Connect(function()
            local ok = loadProfile(pname)
            if ok then
                nameInp.Text = pname
                setStatus("Perfil '" .. pname .. "' carregado!", P.success)
                refreshProfileList()
            end
        end)

        -- Botão ↑ (preenche o campo de nome)
        local editBtn = Instance.new("TextButton")
            editBtn.Text             = "↑"
            editBtn.Size             = UDim2.new(0, 30, 0, 24)
            editBtn.Position         = UDim2.new(1, -58, 0.5, -12)
            editBtn.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
            editBtn.BorderSizePixel  = 0
            editBtn.TextColor3       = P.textDim
            editBtn.TextSize         = 13
            editBtn.Font             = Enum.Font.GothamBold
            editBtn.ZIndex           = 11
            editBtn.Parent           = entry
        rnd(editBtn, 2)
        brdr(editBtn, P.divider, 1, 0)

        editBtn.MouseButton1Click:Connect(function()
            nameInp.Text = pname
            setStatus("Nome preenchido: " .. pname, P.blueL)
        end)

        do
            local ediv = Instance.new("Frame")
                ediv.Size                   = UDim2.new(1, 0, 0, 1)
                ediv.Position               = UDim2.new(0, 0, 1, -1)
                ediv.BackgroundColor3       = P.divider
                ediv.BackgroundTransparency = 0
                ediv.BorderSizePixel        = 0
                ediv.ZIndex                 = 9
                ediv.Parent                 = entry
        end
    end
end

refreshProfileList()

-- Carrega o primeiro perfil automaticamente após 0.1s
task.delay(0.1, function()
    local profiles = readIndex()
    if #profiles > 0 then
        loadProfile(profiles[1])
        nameInp.Text = profiles[1]
    end
end)

end -- fim do bloco principal de construção

print("KARFI HUB 100% Carregado|Profiles em: " .. CFG_FOLDER)
]
