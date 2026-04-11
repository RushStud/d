do
    local cg = game:GetService("CoreGui")
    for _, n in next, {"HittaHub","HittaHubMini"} do
        local old = cg:FindFirstChild(n) if old then old:Destroy() end
    end
    for _, e in next, game:GetService("Lighting"):GetChildren() do
        if e:IsA("DepthOfFieldEffect") and e.Name == "HittaDOF" then
            e:Destroy()
        end
    end
end

local uis      = game:GetService("UserInputService")
local rs       = game:GetService("RunService")
local ts       = game:GetService("TweenService")
local lighting = game:GetService("Lighting")
local http     = game:GetService("HttpService")
local coregui  = game:GetService("CoreGui")

local exp, clamp, floor, rgb = math.exp, math.clamp, math.floor, Color3.fromRGB

local fonts = {}
do
    local function regFont(name, weight, style, asset)
        if not isfile(asset.id) then writefile(asset.id, asset.font) end
        if isfile(name .. ".font") then delfile(name .. ".font") end
        local data = {
            name  = name,
            faces = {{ name="Normal", weight=weight, style=style, assetId=getcustomasset(asset.id) }},
        }
        writefile(name .. ".font", http:JSONEncode(data))
        return getcustomasset(name .. ".font")
    end

    local medium = regFont("HittaMedium", 200, "Normal", {
        id   = "HittaMedium.ttf",
        font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-Medium.ttf"),
    })
    local semibold = regFont("HittaSemiBold", 200, "Normal", {
        id   = "HittaSemiBold.ttf",
        font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-SemiBold.ttf"),
    })

    fonts = {
        regular = Font.new(medium,   Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        semi    = Font.new(semibold, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        bold    = Font.new(semibold, Enum.FontWeight.Bold,    Enum.FontStyle.Normal),
    }
end

local acrylicOn      = false
local hittaDOF       = nil
local dofTween       = nil
local accent         = rgb(235,235,235)
local accentTrackers = {}
local toggleKey      = Enum.KeyCode.RightShift
local cfgDir         = "HITTA"
local miniBars       = {}
local widgetState    = {}

local w, h      = 700, 550
local topH      = 48
local sideW     = 175
local rad       = 12
local vp        = workspace.CurrentCamera.ViewportSize

local FS_MAX_W = 1400
local FS_MAX_H = 900

local function make(c, p)
    local o = Instance.new(c)
    for k, v in next, p do o[k] = v end
    return o
end

local function tw(obj, props, style, t)
    if not obj or not obj:IsDescendantOf(game) then return end
    ts:Create(obj, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function tween(obj, props, style, dir, t)
    if not obj or not obj:IsDescendantOf(game) then return end
    return ts:Create(obj, TweenInfo.new(t or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
end

local function drag(handle, target)
    local active, origin, sp = false, nil, nil
    local gx, gy, sx, sy = 0, 0, 0, 0
    local function beginDrag(pos)
        active = true; origin = pos; sp = target.Position
        gx = sp.X.Offset; gy = sp.Y.Offset
        sx = sp.X.Scale;  sy = sp.Y.Scale
    end
    handle.InputBegan:Connect(function(i)
        local t = i.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then beginDrag(i.Position) end
    end)
    handle.InputEnded:Connect(function(i)
        local t = i.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then active = false end
    end)
    uis.InputChanged:Connect(function(i)
        if not active then return end
        local t = i.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            gx = sp.X.Offset + (i.Position.X - origin.X)
            gy = sp.Y.Offset + (i.Position.Y - origin.Y)
        end
    end)
    rs.RenderStepped:Connect(function(dt)
        if not active or not target or not target.Parent then return end
        local f  = 1 - exp(-14 * dt)
        local cx = target.Position.X.Offset
        local cy = target.Position.Y.Offset
        target.Position = UDim2.new(sx, cx + (gx - cx) * f, sy, cy + (gy - cy) * f)
    end)
end

local function setAccentColor(color)
    accent = color
    for _, t in next, accentTrackers do
        pcall(function()
            if t.obj and t.obj:IsDescendantOf(game) and t.check() then
                tw(t.obj, {[t.prop]=color}, nil, 0.2)
            end
        end)
    end
end

local gui = make("ScreenGui", {
    Parent=coregui, Name="HittaHub", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true,
})
local miniGui = make("ScreenGui", {
    Parent=coregui, Name="HittaHubMini", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true,
    Enabled=false, DisplayOrder=999,
})

local win = make("Frame", {
    Parent=gui, Size=UDim2.new(0,w,0,h),
    Position=UDim2.new(0,floor((vp.X-w)/2),0,floor((vp.Y-h)/2)),
    BackgroundTransparency=1, BorderSizePixel=0,
})

local shadow = make("ImageLabel", {
    Parent=win,
    AnchorPoint=Vector2.new(0.5, 0.5),
    Position=UDim2.new(0.5, 0, 0.5, 0),
    Size=UDim2.new(1, 75, 1, 75),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    BackgroundColor3=rgb(255,255,255),
    Image="rbxassetid://112971167999062",
    ImageColor3=rgb(0, 0, 0),
    ScaleType=Enum.ScaleType.Slice,
    SliceCenter=Rect.new(Vector2.new(112,112), Vector2.new(147,147)),
    SliceScale=0.75,
    ZIndex=-100,
})
make("UICorner", {Parent=shadow, CornerRadius=UDim.new(0,5)})

local bg = make("Frame", {
    Parent=win, Size=UDim2.new(1,0,1,0),
    BackgroundColor3=rgb(10,10,10), BorderSizePixel=0,
    ClipsDescendants=true,
})
make("UICorner", {Parent=bg, CornerRadius=UDim.new(0,rad)})
local bgClipBottom = make("Frame", {
    Parent=win, AnchorPoint=Vector2.new(0,1),
    Position=UDim2.new(0,0,1,0),
    Size=UDim2.new(1,0,0,rad),
    BackgroundColor3=rgb(0,0,0),
    BackgroundTransparency=1,
    BorderSizePixel=0, ZIndex=600,
    ClipsDescendants=true,
})

local fadeOverlay = make("Frame", {
    Parent=win, Size=UDim2.new(1,0,1,0),
    BackgroundColor3=rgb(0,0,0), BackgroundTransparency=1,
    BorderSizePixel=0, ZIndex=500, Active=false,
})
make("UICorner", {Parent=fadeOverlay, CornerRadius=UDim.new(0,rad)})

local topbarBG, sidebarBG

local topbar = make("Frame", {
    Parent=bg, Size=UDim2.new(1,0,0,topH),
    BackgroundTransparency=1, BorderSizePixel=0,
    ClipsDescendants=true, Active=true, ZIndex=3,
})
topbarBG = make("Frame", {
    Parent=topbar, Position=UDim2.new(0,0,0,0),
    Size=UDim2.new(1,0,0,topH+rad),
    BackgroundColor3=rgb(7,7,7), BorderSizePixel=0, ZIndex=3,
})
make("UICorner", {Parent=topbarBG, CornerRadius=UDim.new(0,rad)})
make("Frame", {
    Parent=bg, Position=UDim2.new(0,0,0,topH),
    Size=UDim2.new(1,0,0,1), BackgroundColor3=rgb(25,25,28), BorderSizePixel=0, ZIndex=4,
})

local hittaLogo = make("ImageLabel", {
    Parent=topbar, Size=UDim2.new(0,26,0,26),
    Position=UDim2.new(0,14,0,floor((topH-26)/2)),
    BackgroundTransparency=1, Image="rbxassetid://110745379320861",
    ImageColor3=accent, ScaleType=Enum.ScaleType.Fit, ZIndex=4,
})
table.insert(accentTrackers, {obj=hittaLogo, prop="ImageColor3", check=function() return true end})

local titleFrame = make("Frame", {
    Parent=topbar, Size=UDim2.new(0,120,0,22),
    Position=UDim2.new(0,48,0,floor((topH-22)/2)),
    BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.X, ZIndex=4,
})
make("UIListLayout", {
    Parent=titleFrame, FillDirection=Enum.FillDirection.Horizontal,
    VerticalAlignment=Enum.VerticalAlignment.Center,
    SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5),
})
local hittaLabel = make("TextLabel", {
    Parent=titleFrame, Size=UDim2.new(0,0,0,22), AutomaticSize=Enum.AutomaticSize.X,
    BackgroundTransparency=1, FontFace=fonts.bold,
    Text="Hitta", TextColor3=accent, TextSize=16,
    TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Center, ZIndex=4, LayoutOrder=1,
})
table.insert(accentTrackers, {obj=hittaLabel, prop="TextColor3", check=function() return true end})
make("TextLabel", {
    Parent=titleFrame, Size=UDim2.new(0,0,0,22), AutomaticSize=Enum.AutomaticSize.X,
    BackgroundTransparency=1, FontFace=fonts.bold,
    Text="Hub", TextColor3=rgb(235,235,235), TextSize=16,
    TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Center, ZIndex=4, LayoutOrder=2,
})

local function makePill(labelText, order, trackAccent)
    make("Frame", {
        Parent=titleFrame, Size=UDim2.new(0,4,0,1),
        BackgroundTransparency=1, LayoutOrder=order, ZIndex=4,
    })
    local f = make("Frame", {
        Parent=titleFrame, Size=UDim2.new(0,0,0,18), AutomaticSize=Enum.AutomaticSize.X,
        BackgroundColor3=rgb(30,30,32), BorderSizePixel=0, ZIndex=5, LayoutOrder=order+1,
    })
    make("UICorner", {Parent=f, CornerRadius=UDim.new(0,999)})
    make("UIPadding", {Parent=f, PaddingLeft=UDim.new(0,7), PaddingRight=UDim.new(0,7)})
    local stroke = make("UIStroke", {
        Parent=f, Color=trackAccent and accent or rgb(42,42,46),
        Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
        Transparency=trackAccent and 0.55 or 0,
    })
    local lbl = make("TextLabel", {
        Parent=f, Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
        BackgroundTransparency=1, FontFace=fonts.bold,
        Text=labelText,
        TextColor3=trackAccent and accent or rgb(130,130,138),
        TextTransparency=trackAccent and 0.25 or 0,
        TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center, ZIndex=6,
    })
    if trackAccent then
        table.insert(accentTrackers, {obj=stroke, prop="Color",      check=function() return true end})
        table.insert(accentTrackers, {obj=lbl,    prop="TextColor3", check=function() return true end})
    end
    return f, lbl, stroke
end

makePill("v1.0", 3, true)

local _, clockLbl = makePill("--:--", 5, true)
task.spawn(function()
    while clockLbl and clockLbl:IsDescendantOf(game) do
        local t = os.date("*t")
        clockLbl.Text = string.format("%02d:%02d", t.hour, t.min)
        task.wait(60 - os.date("*t").sec)
    end
end)

local _, tierLbl = makePill("", 7, true)

local btnRow = make("Frame", {
    Parent=topbar, AnchorPoint=Vector2.new(1,0),
    Position=UDim2.new(1,-14,0,floor((topH-16)/2)),
    Size=UDim2.new(0,0,0,16), BackgroundTransparency=1,
    AutomaticSize=Enum.AutomaticSize.X, ZIndex=4,
})
make("UIListLayout", {
    Parent=btnRow, FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Right,
    VerticalAlignment=Enum.VerticalAlignment.Center,
    Padding=UDim.new(0,16), SortOrder=Enum.SortOrder.LayoutOrder,
})

local sidebar, content
local minimized, fullscreen = false, false
local savedSize, savedPos
local minimizing = false

local iconX, iconY = 16, -80
local openIcon = make("ImageButton", {
    Parent=miniGui, Size=UDim2.new(0,40,0,40),
    Position=UDim2.new(0,iconX,1,iconY),
    BackgroundTransparency=1, Image="rbxassetid://110745379320861",
    ImageColor3=accent, ScaleType=Enum.ScaleType.Fit,
    AutoButtonColor=false, ZIndex=99,
})
make("UIScale", {Parent=openIcon, Scale=1})
table.insert(accentTrackers, {obj=openIcon, prop="ImageColor3", check=function() return true end})
openIcon.MouseEnter:Connect(function() tw(openIcon,{ImageTransparency=0.35},nil,0.1) end)
openIcon.MouseLeave:Connect(function() tw(openIcon,{ImageTransparency=0},nil,0.12) end)
openIcon.MouseButton1Down:Connect(function() tw(openIcon.UIScale,{Scale=0.82},Enum.EasingStyle.Quint,0.1) end)
openIcon.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        tw(openIcon.UIScale,{Scale=1},Enum.EasingStyle.Quint,0.18)
    end
end)
drag(openIcon, openIcon)

local function applyBlur(on)

    if dofTween then
        pcall(function() dofTween:Cancel() end)
        dofTween = nil
    end
    if on then
        if not hittaDOF or not hittaDOF.Parent then
            hittaDOF = Instance.new("DepthOfFieldEffect")
            hittaDOF.Name          = "HittaDOF"
            hittaDOF.FocusDistance = 5
            hittaDOF.InFocusRadius = 1
            hittaDOF.NearIntensity = 1
            hittaDOF.FarIntensity  = 1
            hittaDOF.Enabled       = false
            hittaDOF.Parent        = lighting
        end
        hittaDOF.Enabled = true
    else
        if hittaDOF and hittaDOF.Parent then
            dofTween = ts:Create(hittaDOF, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FarIntensity=0})
            dofTween:Play()
            dofTween.Completed:Connect(function()
                if (not acrylicOn or force) and hittaDOF then
                    hittaDOF.Enabled = false
                    hittaDOF.Parent  = nil
                end
            end)
        end
    end
end

local function setAcrylic(enabled)
    acrylicOn = enabled
    local d = 0.35
    local bgT    = enabled and 0.4 or 0
    local barBgT = enabled and 1   or 0
    tw(bg,        {BackgroundTransparency=bgT},    Enum.EasingStyle.Quint, d)
    tw(topbarBG,  {BackgroundTransparency=barBgT}, Enum.EasingStyle.Quint, d)
    tw(sidebarBG, {BackgroundTransparency=barBgT}, Enum.EasingStyle.Quint, d)
    for _, bar in next, miniBars do
        tw(bar, {BackgroundTransparency=enabled and 1 or 0}, Enum.EasingStyle.Quint, d)
    end
    applyBlur(enabled)
end

local function setMinimize()
    if minimizing then return end
    minimizing = true
    if minimized then
        minimized = false
        win.Size     = savedSize or UDim2.new(0,w,0,h)
        win.Position = savedPos  or UDim2.new(0,floor((vp.X-w)/2),0,floor((vp.Y-h)/2))
        fadeOverlay.BackgroundTransparency = 0
        win.Visible = true
        bg.BackgroundTransparency = acrylicOn and 0.4 or 0
        tw(fadeOverlay, {BackgroundTransparency=1}, Enum.EasingStyle.Quint, 0.3)
        if acrylicOn then
            topbarBG.BackgroundTransparency = 1
            sidebarBG.BackgroundTransparency = 1
            applyBlur(true)
        end
        task.delay(0.05, function() sidebar.Visible=true; content.Visible=true end)
        task.delay(0.08, function() miniGui.Enabled=false end)
        task.delay(0.35, function() minimizing=false end)
    else
        savedSize=win.Size; savedPos=win.Position; minimized=true
        sidebar.Visible=false; content.Visible=false
        applyBlur(false, true)
        if acrylicOn then
            tw(bg, {BackgroundTransparency=1}, nil, 0.18)
        end
        tw(fadeOverlay, {BackgroundTransparency = acrylicOn and 0.75 or 0}, nil, 0.18)
        tween(win, {
            Size=UDim2.new(0,w,0,0),
            Position=UDim2.new(0,savedPos.X.Offset,0,savedPos.Y.Offset+savedSize.Y.Offset/2),
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.In, 0.26):Play()
        task.delay(0.28, function()
            win.Visible=false
            openIcon.Position=UDim2.new(0,iconX,1,iconY)
            miniGui.Enabled=true
        end)
        task.delay(0.38, function() minimizing=false end)
    end
end

local fsNormalSize, fsNormalPos
local function setFullscreen()
    if minimized then return end
    local vp2 = workspace.CurrentCamera.ViewportSize
    local fsDur  = 0.35
    local fsEase = Enum.EasingStyle.Cubic
    local fsDir  = Enum.EasingDirection.Out
    if fullscreen then
        fullscreen = false
        local targetSize = fsNormalSize or UDim2.new(0,w,0,h)
        local targetPos  = fsNormalPos  or UDim2.new(0,floor((vp2.X-w)/2),0,floor((vp2.Y-h)/2))
        tween(win, {Size=targetSize, Position=targetPos}, fsEase, fsDir, fsDur):Play()
    else
        fsNormalSize = win.Size
        fsNormalPos  = win.Position
        fullscreen = true
        local targetW = math.min(vp2.X - 40, FS_MAX_W)
        local targetH = math.min(vp2.Y - 40, FS_MAX_H)
        tween(win, {
            Size=UDim2.new(0,targetW,0,targetH),
            Position=UDim2.new(0,floor((vp2.X-targetW)/2),0,floor((vp2.Y-targetH)/2)),
        }, fsEase, fsDir, fsDur):Play()
    end
end

local function doClose()
    applyBlur(false)
    local vp2 = workspace.CurrentCamera.ViewportSize
    local tw2, th2 = w*0.85, h*0.85
    tween(win, {
        Size=UDim2.new(0,tw2,0,th2),
        Position=UDim2.new(0,floor((vp2.X-tw2)/2),0,floor((vp2.Y-th2)/2)),
    }, Enum.EasingStyle.Quint, Enum.EasingDirection.In, 0.35):Play()
    if acrylicOn then
        tw(bg, {BackgroundTransparency=1}, Enum.EasingStyle.Quint, 0.3)
    end
    tw(fadeOverlay, {BackgroundTransparency = acrylicOn and 0.75 or 0}, Enum.EasingStyle.Quint, 0.3)
    task.delay(0.38, function()
        if hittaDOF then hittaDOF:Destroy(); hittaDOF = nil end
        if gui and gui.Parent then gui:Destroy() end
        if miniGui and miniGui.Parent then miniGui:Destroy() end
    end)
end

openIcon.MouseButton1Click:Connect(setMinimize)

for _, b in next, {
    {icon="rbxassetid://101163833817627", order=1, action=setMinimize},
    {icon="rbxassetid://103845371952278", order=2, action=setFullscreen},
    {icon="rbxassetid://118419582729473", order=3, action=doClose},
} do
    local holder = make("Frame", {Parent=btnRow, Size=UDim2.new(0,16,0,16), BackgroundTransparency=1, ZIndex=5, LayoutOrder=b.order})
    local img    = make("ImageLabel", {Parent=holder, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Image=b.icon, ImageColor3=rgb(200,200,205), ScaleType=Enum.ScaleType.Fit, ZIndex=6})
    local scale  = make("UIScale", {Parent=img, Scale=1})
    local mbtn   = make("TextButton", {Parent=holder, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", AutoButtonColor=false, ZIndex=7})
    mbtn.MouseEnter:Connect(function() tw(img,{ImageColor3=rgb(255,255,255)},nil,0.1) end)
    mbtn.MouseLeave:Connect(function() tw(img,{ImageColor3=rgb(200,200,205)},nil,0.1) end)
    mbtn.MouseButton1Down:Connect(function() tw(scale,{Scale=0.78},Enum.EasingStyle.Quint,0.1) end)
    mbtn.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then tw(scale,{Scale=1},Enum.EasingStyle.Quint,0.18) end
    end)
    mbtn.MouseButton1Click:Connect(b.action)
end
drag(topbar, win)

sidebar = make("Frame", {
    Parent=bg, Position=UDim2.new(0,0,0,topH+1),
    Size=UDim2.new(0,sideW,1,-(topH+1)),
    BackgroundTransparency=1, BorderSizePixel=0,
    ClipsDescendants=true, ZIndex=2,
})
sidebarBG = make("Frame", {
    Parent=sidebar, Position=UDim2.new(0,0,0,-rad),
    Size=UDim2.new(1,rad,1,rad),
    BackgroundColor3=rgb(7,7,7), BorderSizePixel=0, ZIndex=2,
})
make("UICorner", {Parent=sidebarBG, CornerRadius=UDim.new(0,rad)})
make("Frame", {
    Parent=bg, Position=UDim2.new(0,sideW,0,topH+1),
    Size=UDim2.new(0,1,1,-(topH+1)), BackgroundColor3=rgb(25,25,28),
    BorderSizePixel=0, ZIndex=4,
})

local sideScroll = make("ScrollingFrame", {
    Parent=sidebar, Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=0, CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=5,
})
make("UIListLayout", {Parent=sideScroll, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2)})
make("UIPadding", {
    Parent=sideScroll,
    PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,8),
    PaddingRight=UDim.new(0,8), PaddingBottom=UDim.new(0,20),
})

content = make("Frame", {
    Parent=bg, Position=UDim2.new(0,sideW+1,0,topH+1),
    Size=UDim2.new(1,-(sideW+1),1,-(topH+1)),
    BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true,
})

local overlay = make("Frame", {
    Parent=content, Size=UDim2.new(1,0,1,0),
    BackgroundColor3=rgb(10,10,10), BackgroundTransparency=1,
    BorderSizePixel=0, ZIndex=100,
})

local notifRight = make("Frame", {
    Parent=gui, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-16,1,-16),
    Size=UDim2.new(0,260,1,0), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=200,
})
make("UIListLayout", {Parent=notifRight, SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Bottom, Padding=UDim.new(0,8)})
local notifLeft = make("Frame", {
    Parent=gui, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,16,1,-16),
    Size=UDim2.new(0,260,1,0), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=200,
})
make("UIListLayout", {Parent=notifLeft, SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Bottom, Padding=UDim.new(0,8)})

local function Notify(title, body, duration, side)
    duration = duration or 4
    side = side or "right"
    local holder = side == "left" and notifLeft or notifRight
    local fromX  = side == "left" and -1 or 2

    local container = make("Frame", {
        Parent=holder, Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true, ZIndex=200,
    })
    local card = make("Frame", {
        Parent=container, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(fromX,0,1,0),
        Size=UDim2.new(1,0,0,0), BackgroundColor3=rgb(16,16,18),
        BackgroundTransparency=acrylicOn and 0.35 or 0,
        BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y, ClipsDescendants=true, ZIndex=201,
    })
    make("UICorner", {Parent=card, CornerRadius=UDim.new(0,10)})

    local inner = make("Frame", {
        Parent=card, Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, ZIndex=204,
    })
    make("UIListLayout", {Parent=inner, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,3)})
    make("UIPadding", {
        Parent=inner, PaddingTop=UDim.new(0,11), PaddingBottom=UDim.new(0,14),
        PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,34),
    })
    make("TextLabel", {
        Parent=inner, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, FontFace=fonts.bold,
        Text=title, TextColor3=rgb(215,215,215), TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, ZIndex=205, LayoutOrder=1,
    })
    if body and body ~= "" then
        make("TextLabel", {
            Parent=inner, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, FontFace=fonts.regular,
            Text=body, TextColor3=rgb(75,75,78), TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, ZIndex=205, LayoutOrder=2,
        })
    end

    local track = make("Frame", {
        Parent=inner, Size=UDim2.new(1,0,0,3),
        BackgroundColor3=rgb(28,28,30), BorderSizePixel=0, ZIndex=203, LayoutOrder=3,
    })
    make("UICorner", {Parent=track, CornerRadius=UDim.new(0,999)})
    local fill = make("Frame", {
        Parent=track, Size=UDim2.new(1,0,1,0),
        BackgroundColor3=rgb(120,120,125), BorderSizePixel=0, ZIndex=204,
    })
    make("UICorner", {Parent=fill, CornerRadius=UDim.new(0,999)})

    local xbtn = make("TextButton", {
        Parent=card, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-9,0,8),
        Size=UDim2.new(0,18,0,18), BackgroundTransparency=1,
        Text="×", FontFace=fonts.bold, TextSize=20, TextColor3=rgb(55,55,58), ZIndex=206,
    })
    xbtn.MouseEnter:Connect(function() tw(xbtn,{TextColor3=rgb(190,190,190)},nil,0.1) end)
    xbtn.MouseLeave:Connect(function() tw(xbtn,{TextColor3=rgb(55,55,58)},nil,0.1) end)

    local closed = false
    local function close()
        if closed then return end; closed=true
        tween(card,{Position=UDim2.new(fromX,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In,0.3):Play()
        tween(container,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In,0.3):Play()
        task.delay(0.32, function()
            if container and container.Parent then container:Destroy() end
        end)
    end
    xbtn.MouseButton1Click:Connect(close)

    task.spawn(function()
        task.wait()
        task.wait()
        local nh = card.AbsoluteSize.Y
        if nh < 10 then task.wait(0.05); nh = card.AbsoluteSize.Y end
        tween(container,{Size=UDim2.new(1,0,0,nh)},Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0.38):Play()
        tween(card,{Position=UDim2.new(0,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0.38):Play()
        task.wait(0.4)
        ts:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,1,0)}):Play()
        task.wait(duration)
        close()
    end)
end

local function notifyAction(title, body, btnText, callback, duration, side)
    duration = duration or 8
    side = side or "right"
    local holder = side == "left" and notifLeft or notifRight
    local fromX  = side == "left" and -1 or 2

    local container = make("Frame", {
        Parent=holder, Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true, ZIndex=200,
    })
    local card = make("Frame", {
        Parent=container, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(fromX,0,1,0),
        Size=UDim2.new(1,0,0,0), BackgroundColor3=rgb(16,16,18), BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y, ClipsDescendants=true, ZIndex=201,
    })
    make("UICorner", {Parent=card, CornerRadius=UDim.new(0,10)})

    local inner = make("Frame", {
        Parent=card, Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, ZIndex=204,
    })
    make("UIListLayout", {Parent=inner, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
    make("UIPadding", {
        Parent=inner, PaddingTop=UDim.new(0,11), PaddingBottom=UDim.new(0,12),
        PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,34),
    })
    make("TextLabel", {
        Parent=inner, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, FontFace=fonts.bold,
        Text=title, TextColor3=rgb(215,215,215), TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, ZIndex=205, LayoutOrder=1,
    })
    if body and body ~= "" then
        make("TextLabel", {
            Parent=inner, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, FontFace=fonts.regular,
            Text=body, TextColor3=rgb(75,75,78), TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, ZIndex=205, LayoutOrder=2,
        })
    end

    local btn = make("TextButton", {
        Parent=inner, Size=UDim2.new(1,0,0,26), LayoutOrder=3,
        BackgroundColor3=rgb(26,26,30), BorderSizePixel=0,
        Text=btnText, FontFace=fonts.semi, TextSize=12,
        TextColor3=rgb(170,170,180), AutoButtonColor=false, ZIndex=205,
    })
    make("UICorner", {Parent=btn, CornerRadius=UDim.new(0,6)})
    make("UIStroke", {Parent=btn, Color=rgb(38,38,44), Thickness=1})
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=rgb(32,32,38),TextColor3=rgb(215,215,225)},nil,0.1) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=rgb(26,26,30),TextColor3=rgb(170,170,180)},nil,0.1) end)

    local xbtn = make("TextButton", {
        Parent=card, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-9,0,8),
        Size=UDim2.new(0,18,0,18), BackgroundTransparency=1,
        Text="×", FontFace=fonts.bold, TextSize=20, TextColor3=rgb(55,55,58), ZIndex=206,
    })
    xbtn.MouseEnter:Connect(function() tw(xbtn,{TextColor3=rgb(190,190,190)},nil,0.1) end)
    xbtn.MouseLeave:Connect(function() tw(xbtn,{TextColor3=rgb(55,55,58)},nil,0.1) end)

    local closed = false
    local function close()
        if closed then return end; closed=true
        tween(card,{Position=UDim2.new(fromX,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In,0.3):Play()
        tween(container,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In,0.3):Play()
        task.delay(0.32, function()
            if container and container.Parent then container:Destroy() end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        close()
        if callback then callback() end
    end)
    xbtn.MouseButton1Click:Connect(close)

    task.spawn(function()
        task.wait()
        local nh = card.AbsoluteSize.Y
        tween(container,{Size=UDim2.new(1,0,0,nh)},Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0.38):Play()
        tween(card,{Position=UDim2.new(0,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0.38):Play()
        task.wait(duration)
        close()
    end)
end

local tabs      = {}
local tabFrames = {}
local activeTab = nil
local tabOrder  = 0

local function animateIn(newFrame, oldFrame)
    if oldFrame then
        oldFrame.Visible = false
    end
    if newFrame then
        newFrame.Position = UDim2.new(0.06, 0, 0, 0)
        newFrame.BackgroundTransparency = 1
        newFrame.Visible = true
        tween(newFrame, {Position=UDim2.new(0,0,0,0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0.22):Play()
    end
end

local function selectTab(name)
    local oldFrame = activeTab and tabFrames[activeTab] or nil
    for n, t in next, tabs do
        local is = n == name
        tw(t.bg,  {BackgroundTransparency=is and 0.88 or 1}, nil, 0.12)
        tw(t.lbl, {TextTransparency=is and 0 or 0.45},       nil, 0.12)
        if t.icon then tw(t.icon, {ImageTransparency=is and 0 or 0.45}, nil, 0.12) end
    end
    if activeTab ~= name then
        animateIn(tabFrames[name], oldFrame)
    end
    activeTab = name
end

local function addTab(name, icon)
    tabOrder = tabOrder + 1

    local tbg = make("TextButton", {
        Parent=sideScroll, Size=UDim2.new(1,0,0,34),
        BackgroundTransparency=1, Text="", AutoButtonColor=false,
        ZIndex=6, LayoutOrder=tabOrder,
    })
    local tround = make("Frame", {
        Parent=tbg, Size=UDim2.new(1,0,1,0),
        BackgroundColor3=rgb(255,255,255), BackgroundTransparency=1,
        BorderSizePixel=0, ZIndex=6,
    })
    make("UICorner", {Parent=tround, CornerRadius=UDim.new(0,8)})

    local ticon = nil
    local lx = 12
    if icon then
        lx = 34
        ticon = make("ImageLabel", {
            Parent=tbg, Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,12,0,9),
            BackgroundTransparency=1, Image=icon,
            ImageColor3=rgb(160,160,165), ScaleType=Enum.ScaleType.Fit, ZIndex=7,
        })
        table.insert(accentTrackers, {obj=ticon, prop="ImageColor3", check=function() return true end})
    end

    local tlbl = make("TextLabel", {
        Parent=tbg, Size=UDim2.new(1,-lx-4,1,0), Position=UDim2.new(0,lx,0,0),
        BackgroundTransparency=1, FontFace=fonts.semi,
        Text=name, TextColor3=rgb(180,180,180), TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7,
    })

    local cf = make("ScrollingFrame", {
        Parent=content, Size=UDim2.new(1,-6,1,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=2, ScrollBarImageColor3=rgb(40,40,44),
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false, ZIndex=2,
    })
    make("UIListLayout", {Parent=cf, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
    make("UIPadding", {
        Parent=cf, PaddingTop=UDim.new(0,14), PaddingBottom=UDim.new(0,14),
        PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
    })

    tabs[name]      = {bg=tround, lbl=tlbl, icon=ticon}
    tabFrames[name] = cf

    tbg.MouseButton1Click:Connect(function() selectTab(name) end)
    tbg.MouseEnter:Connect(function()
        if activeTab ~= name then tw(tround,{BackgroundTransparency=0.95},nil,0.1) end
    end)
    tbg.MouseLeave:Connect(function()
        if activeTab ~= name then tw(tround,{BackgroundTransparency=1},nil,0.1) end
    end)
    return cf
end

local function addMiniTabBar(parentScroll)
    local barH = 38
    parentScroll.ScrollBarThickness  = 0
    parentScroll.CanvasSize          = UDim2.new(0,0,0,0)
    parentScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
    for _, ch in next, parentScroll:GetChildren() do
        if ch:IsA("UIListLayout") or ch:IsA("UIPadding") then ch:Destroy() end
    end

    local bar = make("Frame", {
        Parent=parentScroll, Size=UDim2.new(1,0,0,barH), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=rgb(9,9,9), BorderSizePixel=0, ZIndex=6, ClipsDescendants=true,
    })
    table.insert(miniBars, bar)
    if acrylicOn then bar.BackgroundTransparency = 1 end

    make("Frame", {
        Parent=bar, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0),
        Size=UDim2.new(1,0,0,1), BackgroundColor3=rgb(28,28,31), BorderSizePixel=0, ZIndex=7,
    })

    local tabRow = make("Frame", {
        Parent=bar, Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, ZIndex=7,
    })
    make("UIListLayout", {
        Parent=tabRow, FillDirection=Enum.FillDirection.Horizontal,
        VerticalAlignment=Enum.VerticalAlignment.Bottom,
        Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder,
    })

    local indicator = make("Frame", {
        Parent=bar, Size=UDim2.new(0,0,0,2), Position=UDim2.new(0,14,1,-1),
        BackgroundColor3=accent, BorderSizePixel=0, ZIndex=8,
    })
    make("UICorner", {Parent=indicator, CornerRadius=UDim.new(0,999)})
    table.insert(accentTrackers, {obj=indicator, prop="BackgroundColor3", check=function() return true end})

    local area = make("Frame", {
        Parent=parentScroll, Position=UDim2.new(0,0,0,barH+1),
        Size=UDim2.new(1,0,1,-(barH+1)),
        BackgroundTransparency=1, ClipsDescendants=true, ZIndex=3,
    })

    local miniTabs   = {}
    local miniFrames = {}
    local tabNames   = {}
    local activeMini = nil
    local tabOrd     = 0
    local animating  = false

    local function moveIndicator(btn)
        task.spawn(function()
            task.wait(0.05)
            local relX = btn.AbsolutePosition.X - bar.AbsolutePosition.X + 14
            local bw   = math.max(btn.AbsoluteSize.X - 28, 0)
            tw(indicator, {
                Position = UDim2.new(0, relX, 1, -1),
                Size     = UDim2.new(0, bw, 0, 2),
            }, Enum.EasingStyle.Quint, 0.22)
        end)
    end

    local function selectMini(name)
        if animating or name == activeMini then return end
        animating = true
        if activeMini and miniFrames[activeMini] then miniFrames[activeMini].Visible = false end
        if miniFrames[name] then miniFrames[name].Visible = true end
        for n, t in next, miniTabs do
            tw(t.lbl, {TextTransparency = n == name and 0 or 0.5}, nil, 0.15)
        end
        moveIndicator(miniTabs[name].btn)
        activeMini = name
        task.delay(0.15, function() animating = false end)
    end

    local function addMiniTab(name)
        tabOrd = tabOrd + 1
        table.insert(tabNames, name)

        local btn = make("TextButton", {
            Parent=tabRow, AutomaticSize=Enum.AutomaticSize.X,
            Size=UDim2.new(0,0,1,-5), BackgroundTransparency=1,
            Text="", AutoButtonColor=false, ZIndex=8, LayoutOrder=tabOrd,
        })
        make("UIPadding", {Parent=btn, PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14)})
        local lbl = make("TextLabel", {
            Parent=btn, Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1, FontFace=fonts.semi,
            Text=name, TextColor3=rgb(180,180,180),
            TextTransparency=0.5, TextSize=12, ZIndex=9,
        })

        local scroll = make("ScrollingFrame", {
            Parent=area, Size=UDim2.new(1,-6,1,0),
            BackgroundTransparency=1, BorderSizePixel=0,
            ScrollBarThickness=2, ScrollBarImageColor3=rgb(40,40,44),
            CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Visible=false, ZIndex=2,
        })
        make("UIListLayout", {Parent=scroll, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
        make("UIPadding", {
            Parent=scroll,
            PaddingTop=UDim.new(0,14), PaddingBottom=UDim.new(0,14),
            PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
        })

        miniTabs[name]   = {btn=btn, lbl=lbl}
        miniFrames[name] = scroll

        btn.MouseButton1Click:Connect(function() selectMini(name) end)
        btn.MouseEnter:Connect(function()
            if activeMini ~= name then tw(lbl,{TextTransparency=0.25},nil,0.1) end
        end)
        btn.MouseLeave:Connect(function()
            if activeMini ~= name then tw(lbl,{TextTransparency=0.5},nil,0.1) end
        end)
        if tabOrd == 1 then task.delay(0.08, function() selectMini(name) end) end
        return scroll
    end

    return addMiniTab
end

local function addSectionLabel(parent, label)
    local wrap = make("Frame", {Parent=parent, Size=UDim2.new(1,0,0,24), BackgroundTransparency=1})
    make("TextLabel", {
        Parent=wrap, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, FontFace=fonts.bold,
        Text=label, TextColor3=rgb(55,55,62), TextSize=10, TextXAlignment=Enum.TextXAlignment.Left,
    })
    make("Frame", {
        Parent=wrap, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0),
        Size=UDim2.new(1,0,0,1), BackgroundColor3=rgb(28,28,32), BorderSizePixel=0,
    })
    return parent
end

local function addButton(parent, label, callback)
    local b = make("TextButton", {
        Parent=parent, Size=UDim2.new(1,0,0,30),
        BackgroundColor3=rgb(20,20,22), BorderSizePixel=0, Text="", AutoButtonColor=false,
    })
    make("UICorner", {Parent=b, CornerRadius=UDim.new(0,7)})
    make("UIStroke", {Parent=b, Color=rgb(32,32,34), Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    local lbl = make("TextLabel", {
        Parent=b, Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, FontFace=fonts.semi,
        Text=label, TextColor3=rgb(170,170,170), TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=rgb(25,25,28)}); tw(lbl,{TextColor3=rgb(210,210,210)}) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=rgb(20,20,22)}); tw(lbl,{TextColor3=rgb(170,170,170)}) end)
    b.MouseButton1Down:Connect(function() tw(b,{Size=UDim2.new(0.97,0,0,27),Position=UDim2.new(0.015,0,0,1.5)},Enum.EasingStyle.Quad,0.07) end)
    b.MouseButton1Up:Connect(function()   tw(b,{Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,0)},Enum.EasingStyle.Back,0.15) end)
    b.MouseButton1Click:Connect(callback or function() end)
    return b
end

local function addToggle(parent, label, default, callback)
    local tw2, th2, ks2 = 36, 18, 12
    local ko2 = th2/2 - ks2/2
    local on = default or false
    local row = make("Frame", {Parent=parent, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1})
    make("TextLabel", {
        Parent=row, Size=UDim2.new(1,-(tw2+10),1,0),
        BackgroundTransparency=1, FontFace=fonts.regular, Text=label,
        TextColor3=rgb(170,170,170), TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
    })
    local trk = make("TextButton", {
        Parent=row, AnchorPoint=Vector2.new(1,0),
        Position=UDim2.new(1,0,0,floor((30-th2)/2)),
        Size=UDim2.new(0,tw2,0,th2), BackgroundColor3=rgb(38,38,38),
        BorderSizePixel=0, Text="", AutoButtonColor=false,
    })
    make("UICorner", {Parent=trk, CornerRadius=UDim.new(0,999)})
    local knb = make("Frame", {
        Parent=trk, Size=UDim2.new(0,ks2,0,ks2), Position=UDim2.new(0,ko2,0,ko2),
        BackgroundColor3=rgb(110,110,110), BorderSizePixel=0,
    })
    make("UICorner", {Parent=knb, CornerRadius=UDim.new(0,999)})
    table.insert(accentTrackers, {obj=trk, prop="BackgroundColor3", check=function() return on end})

    local function setVal(v, silent)
        on = v
        tw(trk, {BackgroundColor3=on and accent or rgb(38,38,38)})
        tw(knb, {
            Position=on and UDim2.new(1,-(ks2+ko2),0,ko2) or UDim2.new(0,ko2,0,ko2),
            BackgroundColor3=on and rgb(18,18,18) or rgb(110,110,110),
        })
        if callback and not silent then callback(on) end
    end

    widgetState[label] = {
        get = function() return on end,
        set = function(v) setVal(v, false) end,
    }

    setVal(on, true)
    trk.MouseButton1Click:Connect(function() setVal(not on) end)
    return row, setVal
end

local function addSlider(parent, label, min_, max_, default_, callback)
    local val = default_ or min_
    local dragging = false

    local wrap = make("Frame", {Parent=parent, Size=UDim2.new(1,0,0,44), BackgroundTransparency=1})
    make("TextLabel", {
        Parent=wrap, Size=UDim2.new(1,-50,0,20),
        BackgroundTransparency=1, FontFace=fonts.regular, Text=label,
        TextColor3=rgb(170,170,170), TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
    })
    local valLbl = make("TextLabel", {
        Parent=wrap, Size=UDim2.new(0,46,0,20), Position=UDim2.new(1,-46,0,0),
        BackgroundTransparency=1, FontFace=fonts.regular, Text=tostring(val),
        TextColor3=rgb(80,80,80), TextSize=12, TextXAlignment=Enum.TextXAlignment.Right,
    })
    local track = make("Frame", {
        Parent=wrap, Position=UDim2.new(0,0,0,28), Size=UDim2.new(1,0,0,3),
        BackgroundColor3=rgb(28,28,28), BorderSizePixel=0,
    })
    make("UICorner", {Parent=track, CornerRadius=UDim.new(0,999)})
    local fill = make("Frame", {
        Parent=track, Size=UDim2.new((val-min_)/(max_-min_),0,1,0),
        BackgroundColor3=rgb(200,200,200), BorderSizePixel=0,
    })
    make("UICorner", {Parent=fill, CornerRadius=UDim.new(0,999)})

    local function setByValue(v)
        val = floor(clamp(v, min_, max_))
        local pct = (val - min_) / (max_ - min_)
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        if callback then callback(val) end
    end

    local function upd(px)
        local pct = clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        setByValue(min_ + (max_ - min_) * pct)
    end

    widgetState[label] = {
        get = function() return val end,
        set = setByValue,
    }

    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; upd(i.Position.X)
        end
    end)
    uis.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    uis.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then upd(i.Position.X) end
    end)
    return wrap
end

local function addColorPicker(parent, label, default, callback)
    local ch, cs, cv = 0, 0, 1
    if default then ch, cs, cv = Color3.toHSV(default) end

    local canvasH = 112
    local hueH    = 13
    local wrapH   = 18 + 6 + canvasH + 9 + hueH + 4

    local wrap = make("Frame", {Parent=parent, Size=UDim2.new(1,0,0,wrapH), BackgroundTransparency=1})
    make("TextLabel", {
        Parent=wrap, Size=UDim2.new(1,0,0,18),
        BackgroundTransparency=1, FontFace=fonts.regular, Text=label,
        TextColor3=rgb(170,170,170), TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
    })

    local sv = make("Frame", {
        Parent=wrap, Position=UDim2.new(0,0,0,24),
        Size=UDim2.new(0.62,-6,0,canvasH),
        BackgroundColor3=Color3.fromHSV(ch,1,1), BorderSizePixel=0,
    })
    make("UICorner", {Parent=sv, CornerRadius=UDim.new(0,5)})
    local wf = make("Frame", {Parent=sv, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, ZIndex=2})
    make("UICorner", {Parent=wf, CornerRadius=UDim.new(0,5)})
    local wg = Instance.new("UIGradient")
    wg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
    wg.Parent = wf
    local bf = make("Frame", {Parent=sv, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.new(0,0,0), BorderSizePixel=0, ZIndex=3})
    make("UICorner", {Parent=bf, CornerRadius=UDim.new(0,5)})
    local bg2 = Instance.new("UIGradient")
    bg2.Rotation = 90
    bg2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})
    bg2.Parent = bf

    local dot = make("Frame", {
        Parent=sv, Size=UDim2.new(0,10,0,10), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(cs,0,1-cv,0), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, ZIndex=10,
    })
    make("UICorner", {Parent=dot, CornerRadius=UDim.new(0,999)})
    make("UIStroke", {Parent=dot, Color=Color3.new(0,0,0), Thickness=1.5, ApplyStrokeMode=Enum.ApplyStrokeMode.Border})

    local preview = make("Frame", {
        Parent=wrap, Position=UDim2.new(0.62,0,0,24),
        Size=UDim2.new(0.38,0,0,canvasH),
        BackgroundColor3=Color3.fromHSV(ch,cs,cv), BorderSizePixel=0,
    })
    make("UICorner", {Parent=preview, CornerRadius=UDim.new(0,5)})

    local hueTrack = make("Frame", {
        Parent=wrap, Position=UDim2.new(0,0,0,24+canvasH+9),
        Size=UDim2.new(1,0,0,hueH), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0,
    })
    make("UICorner", {Parent=hueTrack, CornerRadius=UDim.new(0,999)})
    local hg = Instance.new("UIGradient")
    hg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHSV(0,   1,1)),
        ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1,1)),
        ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1,1)),
        ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1,1)),
        ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1,1)),
        ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1,1)),
        ColorSequenceKeypoint.new(1.0, Color3.fromHSV(1.0, 1,1)),
    })
    hg.Parent = hueTrack
    local hcursor = make("Frame", {
        Parent=hueTrack, Size=UDim2.new(0,6,1,4), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(ch,0,0.5,0), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, ZIndex=10,
    })
    make("UICorner", {Parent=hcursor, CornerRadius=UDim.new(0,3)})
    make("UIStroke", {Parent=hcursor, Color=Color3.new(0,0,0), Thickness=1})

    local function refresh()
        sv.BackgroundColor3      = Color3.fromHSV(ch, 1, 1)
        dot.Position             = UDim2.new(cs, 0, 1-cv, 0)
        preview.BackgroundColor3 = Color3.fromHSV(ch, cs, cv)
        hcursor.Position         = UDim2.new(ch, 0, 0.5, 0)
        if callback then callback(Color3.fromHSV(ch, cs, cv)) end
    end

    widgetState[label] = {
        get = function() return {ch, cs, cv} end,
        set = function(hsv) ch, cs, cv = hsv[1], hsv[2], hsv[3]; refresh() end,
    }

    local svDrag = false
    local function svUpdate(pos)
        cs = clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
        cv = 1 - clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
        refresh()
    end
    sv.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then svDrag=true; svUpdate(i.Position) end
    end)
    uis.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then svDrag=false end
    end)
    uis.InputChanged:Connect(function(i)
        if not svDrag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then svUpdate(i.Position) end
    end)
    local hueDrag = false
    local function hueUpdate(pos)
        ch = clamp((pos.X - hueTrack.AbsolutePosition.X) / hueTrack.AbsoluteSize.X, 0, 1)
        refresh()
    end
    hueTrack.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hueDrag=true; hueUpdate(i.Position) end
    end)
    uis.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hueDrag=false end
    end)
    uis.InputChanged:Connect(function(i)
        if not hueDrag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then hueUpdate(i.Position) end
    end)
    refresh()
    return wrap
end

local function addKeybind(parent, label, default, callback)
    local current  = default or Enum.KeyCode.RightShift
    local listening = false
    local row = make("Frame", {Parent=parent, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1})
    make("TextLabel", {
        Parent=row, Size=UDim2.new(1,-80,1,0),
        BackgroundTransparency=1, FontFace=fonts.regular, Text=label,
        TextColor3=rgb(170,170,170), TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
    })
    local btn = make("TextButton", {
        Parent=row, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
        Size=UDim2.new(0,70,0,24), BackgroundColor3=rgb(22,22,24), BorderSizePixel=0,
        FontFace=fonts.semi, TextSize=11, TextColor3=rgb(140,140,140), Text=current.Name, AutoButtonColor=false,
    })
    make("UICorner", {Parent=btn, CornerRadius=UDim.new(0,6)})
    btn.MouseButton1Click:Connect(function()
        if listening then return end; listening=true; btn.Text="..."
        tw(btn, {BackgroundColor3=rgb(30,30,32)}, nil, 0.1)
        local conn; conn = uis.InputBegan:Connect(function(input)
            if input.UserInputType~=Enum.UserInputType.Keyboard then return end
            conn:Disconnect(); listening=false
            current=input.KeyCode; btn.Text=current.Name
            tw(btn, {BackgroundColor3=rgb(22,22,24)}, nil, 0.1)
            if callback then callback(current) end
        end)
    end)
    return row
end

local function addTextBox(parent, label, placeholder)
    local row = make("Frame", {Parent=parent, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1})
    make("TextLabel", {
        Parent=row, Size=UDim2.new(0.35,0,1,0),
        BackgroundTransparency=1, FontFace=fonts.regular, Text=label,
        TextColor3=rgb(170,170,170), TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
    })
    local box = make("TextBox", {
        Parent=row, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
        Size=UDim2.new(0.6,0,0,24), BackgroundColor3=rgb(22,22,24), BorderSizePixel=0,
        FontFace=fonts.regular, TextSize=12, TextColor3=rgb(180,180,180),
        PlaceholderText=placeholder, PlaceholderColor3=rgb(60,60,60),
        Text="", TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false,
    })
    make("UICorner", {Parent=box, CornerRadius=UDim.new(0,6)})
    make("UIPadding", {Parent=box, PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8)})
    return row, box
end

local function ensureFolder()
    pcall(function() if not isfolder(cfgDir) then makefolder(cfgDir) end end)
end

local function saveConfig(name, data)
    ensureFolder()
    pcall(function() writefile(cfgDir.."/"..name..".json", http:JSONEncode(data)) end)
end

local function loadConfig(name)
    local ok, r = pcall(function()
        local p = cfgDir.."/"..name..".json"
        if isfile(p) then return http:JSONDecode(readfile(p)) end
    end)
    return ok and r or nil
end

local function deleteConfig(name)
    pcall(function()
        local p = cfgDir.."/"..name..".json"
        if isfile(p) then delfile(p) end
    end)
end

local function listConfigs()
    local names = {}
    pcall(function()
        ensureFolder()
        for _, f in ipairs(listfiles(cfgDir)) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(names, name) end
        end
    end)
    table.sort(names)
    return names
end

local function getState()
    local state = {
        acrylic = acrylicOn,
        accent  = {accent.R*255, accent.G*255, accent.B*255},
        keybind = toggleKey.Name,
        widgets = {},
    }
    for lbl, wg in next, widgetState do
        state.widgets[lbl] = wg.get()
    end
    return state
end

local function setState(data)
    if data.acrylic ~= nil then setAcrylic(data.acrylic) end
    if data.accent then setAccentColor(rgb(data.accent[1], data.accent[2], data.accent[3])) end
    if data.keybind then pcall(function() toggleKey = Enum.KeyCode[data.keybind] end) end
    if data.widgets then
        for lbl, value in next, data.widgets do
            if widgetState[lbl] then pcall(function() widgetState[lbl].set(value) end) end
        end
    end
end

local function addConfigList(parent, onLoad, onDelete)
    local container = make("Frame", {
        Parent=parent, Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y,
    })
    make("UIListLayout", {Parent=container, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4)})

    local function refresh()
        for _, ch in next, container:GetChildren() do
            if not ch:IsA("UIListLayout") then ch:Destroy() end
        end
        local configs = listConfigs()
        if #configs == 0 then
            make("TextLabel", {
                Parent=container, Size=UDim2.new(1,0,0,32), LayoutOrder=1,
                BackgroundTransparency=1, FontFace=fonts.regular,
                Text="No configs saved", TextColor3=rgb(55,55,62),
                TextSize=12, TextXAlignment=Enum.TextXAlignment.Center,
            })
        else
            for i, name in ipairs(configs) do
                local row = make("Frame", {
                    Parent=container, Size=UDim2.new(1,0,0,32),
                    BackgroundColor3=rgb(18,18,20), BorderSizePixel=0, LayoutOrder=i,
                })
                make("UICorner", {Parent=row, CornerRadius=UDim.new(0,7)})
                make("UIStroke", {Parent=row, Color=rgb(30,30,34), Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
                make("TextLabel", {
                    Parent=row, Size=UDim2.new(1,-82,1,0), Position=UDim2.new(0,12,0,0),
                    BackgroundTransparency=1, FontFace=fonts.semi,
                    Text=name, TextColor3=rgb(155,155,162), TextSize=12,
                    TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,
                })
                local loadBtn = make("TextButton", {
                    Parent=row, AnchorPoint=Vector2.new(1,0.5),
                    Position=UDim2.new(1,-40,0.5,0), Size=UDim2.new(0,34,0,22),
                    BackgroundColor3=rgb(24,24,27), BorderSizePixel=0,
                    Text="Load", FontFace=fonts.semi, TextSize=10,
                    TextColor3=rgb(110,110,120), AutoButtonColor=false,
                })
                make("UICorner", {Parent=loadBtn, CornerRadius=UDim.new(0,5)})
                make("UIStroke", {Parent=loadBtn, Color=rgb(36,36,40), Thickness=1})
                loadBtn.MouseEnter:Connect(function() tw(loadBtn,{TextColor3=rgb(210,210,220)},nil,0.1) end)
                loadBtn.MouseLeave:Connect(function() tw(loadBtn,{TextColor3=rgb(110,110,120)},nil,0.1) end)
                loadBtn.MouseButton1Click:Connect(function()
                    if onLoad then onLoad(name) end
                end)
                local delBtn = make("TextButton", {
                    Parent=row, AnchorPoint=Vector2.new(1,0.5),
                    Position=UDim2.new(1,-2,0.5,0), Size=UDim2.new(0,34,0,22),
                    BackgroundColor3=rgb(24,24,27), BorderSizePixel=0,
                    Text="Del", FontFace=fonts.semi, TextSize=10,
                    TextColor3=rgb(100,50,50), AutoButtonColor=false,
                })
                make("UICorner", {Parent=delBtn, CornerRadius=UDim.new(0,5)})
                make("UIStroke", {Parent=delBtn, Color=rgb(36,36,40), Thickness=1})
                delBtn.MouseEnter:Connect(function() tw(delBtn,{TextColor3=rgb(220,70,70)},nil,0.1) end)
                delBtn.MouseLeave:Connect(function() tw(delBtn,{TextColor3=rgb(100,50,50)},nil,0.1) end)
                delBtn.MouseButton1Click:Connect(function()
                    if onDelete then onDelete(name) end
                    refresh()
                end)
            end
        end
    end

    refresh()
    return refresh
end

uis.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == toggleKey then setMinimize() end
end)

return {
    addTab          = addTab,
    selectTab       = selectTab,
    addSectionLabel = addSectionLabel,
    addButton       = addButton,
    addToggle       = addToggle,
    addSlider       = addSlider,
    addColorPicker  = addColorPicker,
    addKeybind      = addKeybind,
    addTextBox      = addTextBox,
    addMiniTabBar   = addMiniTabBar,
    addConfigList   = addConfigList,
    Notify          = Notify,
    notifyAction    = notifyAction,
    setAcrylic      = setAcrylic,
    setAccentColor  = setAccentColor,
    getAccent       = function() return accent end,
    saveConfig      = saveConfig,
    loadConfig      = loadConfig,
    deleteConfig    = deleteConfig,
    listConfigs     = listConfigs,
    getState        = getState,
    setState        = setState,
    setShadow       = function(enabled)
        if shadow and shadow:IsDescendantOf(game) then
            ts:Create(shadow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                ImageTransparency = enabled and 0 or 1
            }):Play()
        end
    end,
    setShadowColor  = function(color)
        if shadow and shadow:IsDescendantOf(game) then
            shadow.ImageColor3 = color
        end
    end,
    setBlur         = function(enabled)
        if enabled then
            local blur = Instance.new("BlurEffect")
            blur.Name = "HittaBlur"
            blur.Size = 0
            blur.Parent = lighting
            ts:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Size = 20}):Play()
        else
            local blur = lighting:FindFirstChild("HittaBlur")
            if blur then
                local t = ts:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Size = 0})
                t:Play()
                t.Completed:Connect(function() blur:Destroy() end)
            end
        end
    end,
    setToggleKey    = function(key) toggleKey = key end,
    setTier         = function(tier)
        if tierLbl and tierLbl:IsDescendantOf(game) then
            tierLbl.Text = tier or ""
        end
    end,
}
