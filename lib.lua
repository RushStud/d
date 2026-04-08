local lib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/RushStud/d/refs/heads/main/lib.lua"
))()

local addTab          = lib.addTab
local selectTab       = lib.selectTab
local addSectionLabel = lib.addSectionLabel
local addButton       = lib.addButton
local addToggle       = lib.addToggle
local addSlider       = lib.addSlider
local addColorPicker  = lib.addColorPicker
local addKeybind      = lib.addKeybind
local addTextBox      = lib.addTextBox
local addMiniTabBar   = lib.addMiniTabBar
local addConfigList   = lib.addConfigList
local Notify          = lib.Notify
local rgb             = Color3.fromRGB

local lp          = game.Players.LocalPlayer
local rs          = game:GetService("RunService")
local http        = game:GetService("HttpService")
local players     = game:GetService("Players")
local TS          = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local uis         = game:GetService("UserInputService")

local function httpRequest(options)
    if syn and syn.request then return syn.request(options) end
    if http_request then return http_request(options) end
    if request then return request(options) end
    return nil
end

local apiUrl = "https://d-u0rx.onrender.com"
local apiActive = true
local closed = false

local function apiPost(path, data)
    if not apiActive or closed then return end
    local ok, err = pcall(function()
        local res = httpRequest({
            Url = apiUrl .. path,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = http:JSONEncode(data),
        })
        if not res then error("httpRequest returned nil") end
        local code = res.StatusCode or res.status_code or res.Status
        if code and code >= 400 then error("HTTP " .. tostring(code)) end
    end)
    if not ok then
        Notify("Hitta Hub", "POST error: " .. tostring(err), 6, "right")
    end
end

local function apiGet(path)
    if not apiActive or closed then return nil end
    local ok, res = pcall(function()
        return httpRequest({
            Url = apiUrl .. path,
            Method = "GET",
        })
    end)
    if not ok then
        Notify("Hitta Hub", "GET error: " .. tostring(res), 6, "right")
        return nil
    end
    if not res then return nil end
    local body = res.Body or res.body
    if not body then return nil end
    local ok2, data = pcall(function() return http:JSONDecode(body) end)
    if not ok2 then return nil end
    return data
end

local tagTitles = {"Hitta Admin", "Hitta Staff", "Hitta Owner"}

local function tween(obj, props, dur, style)
    if not obj or not obj:IsDescendantOf(game) then return end
    TS:Create(obj,
        TweenInfo.new(dur or 0.45, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        props
    ):Play()
end

local function measureText(text, size)
    local ok, sz = pcall(function()
        return TextService:GetTextSize(text, size, Enum.Font.GothamBold, Vector2.new(4000, 100))
    end)
    if ok and sz then return sz.X end
    return #text * size * 0.55
end

local function addCustomCheckbox(parent, label, default, callback)
    local on = default or false

    local row = Instance.new("Frame")
    row.Parent = parent
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel")
    lbl.Parent = row
    lbl.Size = UDim2.new(1, -28, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = rgb(170, 170, 170)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextButton")
    box.Parent = row
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.Position = UDim2.new(1, -2, 0.5, 0)
    box.Size = UDim2.new(0, 16, 0, 16)
    box.BackgroundColor3 = rgb(14, 14, 16)
    box.BorderSizePixel = 0
    box.AutoButtonColor = false
    box.Text = ""

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = rgb(110, 110, 120)
    boxStroke.Thickness = 1.4
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Parent = box

    local function setVal(v, silent)
        on = v
        TS:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            BackgroundColor3 = on and rgb(255, 255, 255) or rgb(14, 14, 16),
        }):Play()
        TS:Create(boxStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Color = on and rgb(255, 255, 255) or rgb(110, 110, 120),
        }):Play()
        if callback and not silent then callback(on) end
    end

    setVal(on, true)
    box.MouseButton1Click:Connect(function() setVal(not on) end)

    return row, setVal
end

local function addToggleSlider(parent, label, min_, max_, default_, onToggle, onSlide)
    local val = default_ or min_
    local on = false
    local dragging = false

    local row = Instance.new("Frame")
    row.Parent = parent
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundTransparency = 1

    local box = Instance.new("TextButton")
    box.Parent = row
    box.AnchorPoint = Vector2.new(0, 0)
    box.Position = UDim2.new(0, 0, 0, 4)
    box.Size = UDim2.new(0, 16, 0, 16)
    box.BackgroundColor3 = rgb(14, 14, 16)
    box.BorderSizePixel = 0
    box.AutoButtonColor = false
    box.Text = ""

    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 4) bc.Parent = box
    local bs = Instance.new("UIStroke")
    bs.Color = rgb(110, 110, 120) bs.Thickness = 1.4
    bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border bs.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Parent = row
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.Size = UDim2.new(1, -70, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = rgb(170, 170, 170)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel")
    valLbl.Parent = row
    valLbl.AnchorPoint = Vector2.new(1, 0)
    valLbl.Position = UDim2.new(1, 0, 0, 0)
    valLbl.Size = UDim2.new(0, 46, 0, 22)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(val)
    valLbl.Font = Enum.Font.Gotham
    valLbl.TextSize = 12
    valLbl.TextColor3 = rgb(80, 80, 80)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame")
    track.Parent = row
    track.Position = UDim2.new(0, 24, 0, 28)
    track.Size = UDim2.new(1, -24, 0, 3)
    track.BackgroundColor3 = rgb(28, 28, 28)
    track.BorderSizePixel = 0
    local tc = Instance.new("UICorner") tc.CornerRadius = UDim.new(0, 999) tc.Parent = track

    local fill = Instance.new("Frame")
    fill.Parent = track
    fill.Size = UDim2.new((val - min_) / (max_ - min_), 0, 1, 0)
    fill.BackgroundColor3 = rgb(200, 200, 200)
    fill.BorderSizePixel = 0
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 999) fc.Parent = fill

    local function setVal(v)
        val = math.floor(math.clamp(v, min_, max_))
        local pct = (val - min_) / (max_ - min_)
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        if onSlide then onSlide(val) end
    end

    local function upd(px)
        local pct = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        setVal(min_ + (max_ - min_) * pct)
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; upd(i.Position.X)
        end
    end)
    uis.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    uis.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then upd(i.Position.X) end
    end)

    local function setCheck(v)
        on = v
        TS:Create(box, TweenInfo.new(0.18), {
            BackgroundColor3 = on and rgb(255, 255, 255) or rgb(14, 14, 16),
        }):Play()
        TS:Create(bs, TweenInfo.new(0.18), {
            Color = on and rgb(255, 255, 255) or rgb(110, 110, 120),
        }):Play()
        if onToggle then onToggle(on, val) end
    end

    box.MouseButton1Click:Connect(function() setCheck(not on) end)

    return row, setVal, setCheck, function() return val, on end
end

local Features = {}
local function newFeature(setup)
    local f = {enabled = false, connections = {}, cleanup = nil}
    function f:enable()
        if self.enabled then return end
        self.enabled = true
        local ok, result = pcall(setup, self)
        if ok then self.cleanup = result end
    end
    function f:disable()
        if not self.enabled then return end
        self.enabled = false
        for _, c in ipairs(self.connections) do
            pcall(function() c:Disconnect() end)
        end
        self.connections = {}
        if self.cleanup then pcall(self.cleanup) end
        self.cleanup = nil
    end
    function f:set(v) if v then self:enable() else self:disable() end end
    return f
end

Features.wallComboTilt = newFeature(function(self)
    local ids = {17325537719,10469643643,13294471966,13295936866,13378708199,
                 14136436157,15162694192,16552234590,17889290569}
    local sun = {}
    for _, id in pairs(ids) do sun["rbxassetid://" .. tostring(id)] = true end

    local activeTilts = {}
    local function processChar(char)
        if not self.enabled then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        local conn = animator.AnimationPlayed:Connect(function(track)
            if not self.enabled or not track.Animation then return end
            if sun[track.Animation.AnimationId] then
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local original = root.CFrame
                local startTime = os.clock()
                local tiltConn
                tiltConn = rs.Heartbeat:Connect(function()
                    if not self.enabled then tiltConn:Disconnect(); return end
                    local elapsed = os.clock() - startTime
                    if elapsed < 0.3 then
                        root.CFrame = original * CFrame.Angles(math.rad(-25), 0, 0)
                    else
                        root.CFrame = original
                        tiltConn:Disconnect()
                    end
                end)
                table.insert(activeTilts, tiltConn)
            end
        end)
        table.insert(self.connections, conn)
    end
    if lp.Character then task.spawn(processChar, lp.Character) end
    table.insert(self.connections, lp.CharacterAdded:Connect(function(char)
        task.wait(1); processChar(char)
    end))
    return function()
        for _, c in ipairs(activeTilts) do pcall(function() c:Disconnect() end) end
    end
end)

Features.autoWallCombo = newFeature(function(self)
    local lastCombo = 0
    local cooldown = 1
    table.insert(self.connections, rs.Heartbeat:Connect(function()
        if not self.enabled then return end
        if tick() - lastCombo < cooldown then return end
        lastCombo = tick()
        local char = lp.Character
        if not char then return end
        local communicate = char:FindFirstChild("Communicate")
        if not communicate then return end
        pcall(function() communicate:FireServer({Goal = "Wall Combo"}) end)
    end))
end)

Features.extraSlots = newFeature(function(self)
    pcall(function()
        lp:SetAttribute("ExtraSlots", true)
        lp:SetAttribute("EmoteSearchBar", true)
    end)
    return function()
        pcall(function()
            lp:SetAttribute("ExtraSlots", false)
            lp:SetAttribute("EmoteSearchBar", false)
        end)
    end
end)

local customFovValue = 120
Features.customFov = newFeature(function(self)
    table.insert(self.connections, rs.RenderStepped:Connect(function()
        if not self.enabled then return end
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = customFovValue
        end
    end))
    return function()
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = 70
        end
    end
end)

Features.invisibility = newFeature(function(self)
    local invisAnimationId = "rbxassetid://136370737633649"
    local animationTime = 4.56
    local currentAnimation
    local trackedChar

    local function setTransparency(character, value)
        if not character then return end
        for _, n in ipairs({"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}) do
            local part = character:FindFirstChild(n)
            if part and part:IsA("BasePart") then
                pcall(function() part.Transparency = value end)
            end
        end
    end

    local function playInvis(humanoid)
        if not self.enabled or not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end
        if currentAnimation and currentAnimation.IsPlaying then currentAnimation:Stop() end
        local anim = Instance.new("Animation")
        anim.AnimationId = invisAnimationId
        currentAnimation = animator:LoadAnimation(anim)
        currentAnimation:Play()
        currentAnimation.TimePosition = animationTime
        currentAnimation:AdjustSpeed(0)
    end

    local function setup(char)
        if not self.enabled then return end
        trackedChar = char
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        setTransparency(char, 0.5)
        playInvis(hum)
        table.insert(self.connections, rs.Heartbeat:Connect(function()
            if self.enabled and hum and hum.Parent then playInvis(hum) end
        end))
    end

    if lp.Character then task.spawn(setup, lp.Character) end
    table.insert(self.connections, lp.CharacterAdded:Connect(function(char)
        task.wait(1); setup(char)
    end))

    return function()
        if currentAnimation and currentAnimation.IsPlaying then
            pcall(function() currentAnimation:Stop() end)
        end
        currentAnimation = nil
        if trackedChar then setTransparency(trackedChar, 0) end
    end
end)

Features.noclip = newFeature(function(self)
    table.insert(self.connections, rs.Stepped:Connect(function()
        if not self.enabled or not lp.Character then return end
        for _, part in pairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end))
end)

Features.noDashCooldown = newFeature(function(self)
    pcall(function()
        workspace:SetAttribute("NoDashCooldown", true)
    end)
    return function()
        pcall(function()
            workspace:SetAttribute("NoDashCooldown", false)
        end)
    end
end)

Features.antiFreeze = newFeature(function(self)
    local function hookChar(char)
        if not char then return end
        local conn = char.ChildAdded:Connect(function(c)
            if not self.enabled then return end
            if c.Name == "Freeze" or c.Name == "ComboStun" then
                task.wait()
                pcall(function() c:Destroy() end)
            end
        end)
        table.insert(self.connections, conn)
    end
    if lp.Character then hookChar(lp.Character) end
    table.insert(self.connections, lp.CharacterAdded:Connect(hookChar))
end)

local safeModeHpThreshold = 25
Features.safeMode = newFeature(function(self)
    local safeModeLoc = CFrame.new(9, 653, -363)
    local lastTeleport = 0
    local cooldown = 3
    local distanceThreshold = 20
    table.insert(self.connections, rs.Heartbeat:Connect(function()
        if not self.enabled then return end
        local liveFolder = workspace:FindFirstChild("Live")
        if not liveFolder then return end
        local char = liveFolder:FindFirstChild(lp.Name)
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local health = humanoid.Health
        local distance = (hrp.Position - safeModeLoc.Position).Magnitude
        if health > 0 and health <= safeModeHpThreshold then
            if tick() - lastTeleport >= cooldown and distance > distanceThreshold then
                hrp.CFrame = safeModeLoc
                lastTeleport = tick()
            end
        end
    end))
end)

Features.antiDeath = newFeature(function(self)
    local teleportPosition = Vector3.new(240.31468200683594, -491.9150390625, -183.96755981445312)
    local loopDuration = 5
    local teleportInterval = 0.05
    local savedPosition = nil
    local looping = false

    local function loopTeleport(char)
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        looping = true
        local startTime = tick()
        while tick() - startTime < loopDuration and looping and self.enabled do
            pcall(function() rootPart.CFrame = CFrame.new(teleportPosition) end)
            task.wait(teleportInterval)
        end
        if savedPosition and rootPart and rootPart.Parent then
            pcall(function() rootPart.CFrame = savedPosition end)
        end
        looping = false
    end

    local function hookChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        local conn = hum.AnimationPlayed:Connect(function(track)
            if not self.enabled then return end
            if track.Animation and track.Animation.AnimationId == "rbxassetid://11343250001" then
                task.wait(0.2)
                local pgui = lp:FindFirstChild("PlayerGui")
                if pgui then
                    for _, v in pairs(pgui:GetDescendants()) do
                        if v:IsA("ScreenGui") and v.Name == "Death" then
                            pcall(function() v:Destroy() end)
                        end
                    end
                end
                if not looping and char:FindFirstChild("HumanoidRootPart") then
                    savedPosition = char.HumanoidRootPart.CFrame
                    task.spawn(loopTeleport, char)
                end
            end
        end)
        table.insert(self.connections, conn)
    end

    if lp.Character then hookChar(lp.Character) end
    table.insert(self.connections, lp.CharacterAdded:Connect(function(char)
        task.wait(1); hookChar(char)
    end))

    return function() looping = false end
end)

Features.dashTimer = newFeature(function(self)
    local frontDuration = 5
    local sideDuration  = 2
    local flickerCount  = 2
    local flickerSpeed  = 0.1
    local lastDash      = 0
    local dashCooldown  = 0.1
    local bars          = nil

    local function createGui(character)
        local pgui = lp:WaitForChild("PlayerGui")
        local existing = pgui:FindFirstChild("HittaDashTimer")
        if existing then existing:Destroy() end
        local head = character:WaitForChild("Head", 5)
        if not head then return nil end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HittaDashTimer"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 240, 0, 44)
        billboard.StudsOffset = Vector3.new(0, 4.6, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = pgui

        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = billboard

        local function createBar(label, c1, c2, posx)
            local bc = Instance.new("Frame")
            bc.Size = UDim2.new(0, 110, 0, 40)
            bc.Position = UDim2.new(0, posx, 0, 0)
            bc.BackgroundTransparency = 1
            bc.Parent = container

            local lbl = Instance.new("TextLabel")
            lbl.Text = label
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.TextColor3 = rgb(240, 240, 240)
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, 0, 0, 14)
            lbl.TextStrokeTransparency = 0.5
            lbl.Parent = bc

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 0, 16)
            bg.Position = UDim2.new(0, 0, 0, 18)
            bg.BackgroundColor3 = rgb(20, 20, 22)
            bg.BackgroundTransparency = 0.2
            bg.BorderSizePixel = 0
            bg.Parent = bc
            local bgc = Instance.new("UICorner") bgc.CornerRadius = UDim.new(0, 4) bgc.Parent = bg
            local bgs = Instance.new("UIStroke") bgs.Color = rgb(60,60,68) bgs.Thickness = 1 bgs.Parent = bg

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(1, 0, 1, 0)
            fill.BackgroundColor3 = c1
            fill.BorderSizePixel = 0
            fill.Parent = bg
            local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 4) fc.Parent = fill

            local grad = Instance.new("UIGradient")
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, c1),
                ColorSequenceKeypoint.new(1, c2),
            })
            grad.Rotation = 90
            grad.Parent = fill

            return {fill = fill, timer = 0, active = false, animating = false, duration = 5}
        end

        local fb = createBar("Front/Back Dash", rgb(0,170,255), rgb(0,85,170), 0)
        fb.duration = frontDuration
        local sd = createBar("Side Dash", rgb(255,120,0), rgb(170,60,0), 130)
        sd.duration = sideDuration

        return {frontback = fb, side = sd, gui = billboard}
    end

    if lp.Character then bars = createGui(lp.Character) end

    local function startTimer(bar)
        if not bar or bar.active then return end
        bar.timer = bar.duration
        bar.active = true
        bar.animating = false
        bar.fill.Visible = true
        bar.fill.Size = UDim2.new(1, 0, 1, 0)
    end

    local function animateBar(bar)
        if bar.animating then return end
        bar.animating = true
        task.spawn(function()
            for _ = 1, flickerCount * 2 do
                if not self.enabled then return end
                bar.fill.Visible = not bar.fill.Visible
                task.wait(flickerSpeed)
            end
            bar.fill.Visible = false
            bar.animating = false
        end)
    end

    local function doDash()
        if not bars then return end
        local now = tick()
        if now - lastDash < dashCooldown then return end
        lastDash = now
        local w = uis:IsKeyDown(Enum.KeyCode.W)
        local a = uis:IsKeyDown(Enum.KeyCode.A)
        local s = uis:IsKeyDown(Enum.KeyCode.S)
        local d = uis:IsKeyDown(Enum.KeyCode.D)
        if w or s then
            startTimer(bars.frontback)
        elseif a or d then
            startTimer(bars.side)
        else
            startTimer(bars.frontback)
        end
    end

    table.insert(self.connections, rs.RenderStepped:Connect(function(dt)
        if not self.enabled or not bars then return end
        for _, bar in pairs({bars.frontback, bars.side}) do
            if bar.active then
                bar.timer = math.max(0, bar.timer - dt)
                local pct = bar.timer / bar.duration
                bar.fill.Size = UDim2.new(pct, 0, 1, 0)
                if bar.timer <= 0 then
                    bar.active = false
                    animateBar(bar)
                end
            end
        end
    end))

    table.insert(self.connections, uis.InputBegan:Connect(function(input, processed)
        if processed or not self.enabled then return end
        if input.KeyCode == Enum.KeyCode.Q then doDash() end
    end))

    table.insert(self.connections, lp.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if self.enabled then bars = createGui(char) end
    end))

    return function()
        local pgui = lp:FindFirstChild("PlayerGui")
        if pgui then
            local g = pgui:FindFirstChild("HittaDashTimer")
            if g then g:Destroy() end
        end
        bars = nil
    end
end)

local effectColors = {
    shield = nil,
    palm   = nil,
    redPalm = nil,
    aura   = nil,
    beam   = nil,
}
local redPalmList = {}

Features.effectColors = newFeature(function(self)
    local function applyPalm()
        if not effectColors.palm then return end
        local char = lp.Character
        if not char then return end
        for _, side in ipairs({"Left Arm","Right Arm"}) do
            local limb = char:FindFirstChild(side)
            if limb then
                for _, pp in pairs(limb:GetChildren()) do
                    if pp.Name == "WaterPalm" then
                        local emit = pp:FindFirstChild("ConstantEmit")
                        if emit then
                            for _, v in pairs(emit:GetChildren()) do
                                if v:IsA("ParticleEmitter") then
                                    v.Color = ColorSequence.new(effectColors.palm)
                                end
                            end
                        end
                        local trail = pp:FindFirstChild("WaterTrail")
                        if trail and trail:IsA("Trail") then
                            trail.Color = ColorSequence.new(effectColors.palm)
                        end
                    end
                end
            end
        end
    end

    local function applyShield()
        if not effectColors.shield then return end
        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local shield = hrp:FindFirstChild("EsperShield")
        if shield then
            for _, v in pairs(shield:GetChildren()) do
                if v:IsA("ParticleEmitter") then
                    v.Color = ColorSequence.new(effectColors.shield)
                end
            end
        end
    end

    local function applyRedPalm()
        if not effectColors.redPalm then return end
        local seq = ColorSequence.new(effectColors.redPalm)
        for _, rp in pairs(redPalmList) do
            if rp and rp.Parent then
                for _, e in pairs(rp:GetDescendants()) do
                    if e:IsA("ParticleEmitter") or e:IsA("Trail") then
                        e.Color = seq
                    end
                end
            end
        end
    end

    local function applyAura()
        if not effectColors.aura then return end
        local live = workspace:FindFirstChild("Live")
        if not live then return end
        local char = live:FindFirstChild(lp.Name)
        if not char then return end
        for _, d in pairs(char:GetDescendants()) do
            if d:IsA("ParticleEmitter") then
                local p = d.Parent
                local pn = p and p.Name or ""
                local an = p and p.Parent and p.Parent.Name or ""
                if pn ~= "WaterPalm" and pn ~= "RedPalm" and pn ~= "EsperShield"
                and an ~= "WaterPalm" and an ~= "RedPalm" then
                    d.Color = ColorSequence.new(effectColors.aura)
                end
            end
        end
    end

    local function applyBeam()
        if not effectColors.beam then return end
        local live = workspace:FindFirstChild("Live")
        if not live then return end
        local char = live:FindFirstChild(lp.Name)
        if not char then return end
        for _, d in pairs(char:GetDescendants()) do
            if d:IsA("Beam") then
                local p = d.Parent
                if p and p.Name ~= "WaterPalm" then
                    d.Color = ColorSequence.new(effectColors.beam)
                end
            end
        end
    end

    local function setupRedPalmTracking(char)
        for _, side in ipairs({"Left Arm","Right Arm"}) do
            local limb = char:FindFirstChild(side)
            if limb then
                local conn = limb.ChildAdded:Connect(function(c)
                    if c.Name == "RedPalm" then
                        table.insert(redPalmList, c)
                    end
                end)
                table.insert(self.connections, conn)
                for _, c in pairs(limb:GetChildren()) do
                    if c.Name == "RedPalm" then
                        table.insert(redPalmList, c)
                    end
                end
            end
        end
    end

    if lp.Character then setupRedPalmTracking(lp.Character) end
    table.insert(self.connections, lp.CharacterAdded:Connect(function(char)
        task.wait(1)
        if self.enabled then
            redPalmList = {}
            setupRedPalmTracking(char)
        end
    end))

    table.insert(self.connections, rs.RenderStepped:Connect(function()
        if not self.enabled then return end
        applyPalm(); applyShield(); applyRedPalm(); applyAura(); applyBeam()
    end))
end)

local function addCompactColorPicker(parent, label, default, callback)
    local ch, cs, cv = Color3.toHSV(default)

    local row = Instance.new("Frame")
    row.Parent = parent
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel")
    lbl.Parent = row
    lbl.Size = UDim2.new(1, -32, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = rgb(170, 170, 170)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local swatch = Instance.new("TextButton")
    swatch.Parent = row
    swatch.AnchorPoint = Vector2.new(1, 0.5)
    swatch.Position = UDim2.new(1, -2, 0.5, 0)
    swatch.Size = UDim2.new(0, 22, 0, 22)
    swatch.BackgroundColor3 = default
    swatch.BorderSizePixel = 0
    swatch.AutoButtonColor = false
    swatch.Text = ""

    local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 5) sc.Parent = swatch
    local ss = Instance.new("UIStroke")
    ss.Color = rgb(60, 60, 68) ss.Thickness = 1
    ss.ApplyStrokeMode = Enum.ApplyStrokeMode.Border ss.Parent = swatch

    local popup
    local function closePopup()
        if popup and popup.Parent then
            popup:Destroy()
        end
        popup = nil
    end

    swatch.MouseButton1Click:Connect(function()
        if popup then closePopup() return end

        local screenGui = swatch:FindFirstAncestorOfClass("ScreenGui")
        if not screenGui then return end

        local popW, popH = 180, 160
        local sa = swatch.AbsolutePosition
        local ss2 = swatch.AbsoluteSize
        local px = sa.X + ss2.X - popW
        local py = sa.Y + ss2.Y + 6
        local vp = workspace.CurrentCamera.ViewportSize
        if py + popH > vp.Y - 10 then py = sa.Y - popH - 6 end
        if px < 10 then px = 10 end

        popup = Instance.new("Frame")
        popup.Name = "HittaCompactPicker"
        popup.Parent = screenGui
        popup.Size = UDim2.new(0, popW, 0, popH)
        popup.Position = UDim2.new(0, px, 0, py)
        popup.BackgroundColor3 = rgb(14, 14, 16)
        popup.BorderSizePixel = 0
        popup.ZIndex = 500

        local pc = Instance.new("UICorner") pc.CornerRadius = UDim.new(0, 8) pc.Parent = popup
        local ps = Instance.new("UIStroke")
        ps.Color = rgb(40, 40, 46) ps.Thickness = 1 ps.Parent = popup
        local pp = Instance.new("UIPadding")
        pp.PaddingTop = UDim.new(0, 10) pp.PaddingBottom = UDim.new(0, 10)
        pp.PaddingLeft = UDim.new(0, 10) pp.PaddingRight = UDim.new(0, 10)
        pp.Parent = popup

        local svH  = 110
        local hueH = 10

        local sv = Instance.new("Frame")
        sv.Parent = popup
        sv.Size = UDim2.new(1, 0, 0, svH)
        sv.BackgroundColor3 = Color3.fromHSV(ch, 1, 1)
        sv.BorderSizePixel = 0
        sv.ZIndex = 501
        local svc = Instance.new("UICorner") svc.CornerRadius = UDim.new(0, 5) svc.Parent = sv

        local wf = Instance.new("Frame")
        wf.Parent = sv
        wf.Size = UDim2.new(1, 0, 1, 0)
        wf.BackgroundColor3 = Color3.new(1, 1, 1)
        wf.BorderSizePixel = 0
        wf.ZIndex = 502
        local wfc = Instance.new("UICorner") wfc.CornerRadius = UDim.new(0, 5) wfc.Parent = wf
        local wg = Instance.new("UIGradient")
        wg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        wg.Parent = wf

        local bf = Instance.new("Frame")
        bf.Parent = sv
        bf.Size = UDim2.new(1, 0, 1, 0)
        bf.BackgroundColor3 = Color3.new(0, 0, 0)
        bf.BorderSizePixel = 0
        bf.ZIndex = 503
        local bfc = Instance.new("UICorner") bfc.CornerRadius = UDim.new(0, 5) bfc.Parent = bf
        local bg2 = Instance.new("UIGradient")
        bg2.Rotation = 90
        bg2.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })
        bg2.Parent = bf

        local dot = Instance.new("Frame")
        dot.Parent = sv
        dot.Size = UDim2.new(0, 9, 0, 9)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(cs, 0, 1 - cv, 0)
        dot.BackgroundColor3 = Color3.new(1, 1, 1)
        dot.BorderSizePixel = 0
        dot.ZIndex = 510
        local dc = Instance.new("UICorner") dc.CornerRadius = UDim.new(1, 0) dc.Parent = dot
        local ds = Instance.new("UIStroke")
        ds.Color = Color3.new(0, 0, 0) ds.Thickness = 1.4 ds.Parent = dot

        local hueTrack = Instance.new("Frame")
        hueTrack.Parent = popup
        hueTrack.Position = UDim2.new(0, 0, 0, svH + 10)
        hueTrack.Size = UDim2.new(1, 0, 0, hueH)
        hueTrack.BackgroundColor3 = Color3.new(1, 1, 1)
        hueTrack.BorderSizePixel = 0
        hueTrack.ZIndex = 501
        local htc = Instance.new("UICorner") htc.CornerRadius = UDim.new(0, 999) htc.Parent = hueTrack
        local hg = Instance.new("UIGradient")
        hg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,    1, 1)),
            ColorSequenceKeypoint.new(1/6,  Color3.fromHSV(1/6,  1, 1)),
            ColorSequenceKeypoint.new(2/6,  Color3.fromHSV(2/6,  1, 1)),
            ColorSequenceKeypoint.new(3/6,  Color3.fromHSV(3/6,  1, 1)),
            ColorSequenceKeypoint.new(4/6,  Color3.fromHSV(4/6,  1, 1)),
            ColorSequenceKeypoint.new(5/6,  Color3.fromHSV(5/6,  1, 1)),
            ColorSequenceKeypoint.new(1.0,  Color3.fromHSV(1.0,  1, 1)),
        })
        hg.Parent = hueTrack

        local hCursor = Instance.new("Frame")
        hCursor.Parent = hueTrack
        hCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        hCursor.Position = UDim2.new(ch, 0, 0.5, 0)
        hCursor.Size = UDim2.new(0, 5, 1, 4)
        hCursor.BackgroundColor3 = Color3.new(1, 1, 1)
        hCursor.BorderSizePixel = 0
        hCursor.ZIndex = 510
        local hcc = Instance.new("UICorner") hcc.CornerRadius = UDim.new(0, 3) hcc.Parent = hCursor
        local hcs = Instance.new("UIStroke")
        hcs.Color = Color3.new(0, 0, 0) hcs.Thickness = 1 hcs.Parent = hCursor

        local function refresh()
            local color = Color3.fromHSV(ch, cs, cv)
            sv.BackgroundColor3 = Color3.fromHSV(ch, 1, 1)
            dot.Position = UDim2.new(cs, 0, 1 - cv, 0)
            hCursor.Position = UDim2.new(ch, 0, 0.5, 0)
            swatch.BackgroundColor3 = color
            if callback then callback(color) end
        end

        local svDrag = false
        local function svUpdate(pos)
            cs = math.clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            cv = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
            refresh()
        end
        sv.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                svDrag = true; svUpdate(i.Position)
            end
        end)

        local hueDrag = false
        local function hueUpdate(pos)
            ch = math.clamp((pos.X - hueTrack.AbsolutePosition.X) / hueTrack.AbsoluteSize.X, 0, 1)
            refresh()
        end
        hueTrack.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                hueDrag = true; hueUpdate(i.Position)
            end
        end)

        local moveConn, endConn
        moveConn = uis.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch then
                if svDrag then svUpdate(i.Position) end
                if hueDrag then hueUpdate(i.Position) end
            end
        end)
        endConn = uis.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                svDrag = false; hueDrag = false
            end
        end)

        local outsideConn
        outsideConn = uis.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1
            and i.UserInputType ~= Enum.UserInputType.Touch then return end
            if not popup or not popup.Parent then return end
            local mp = i.Position
            local pa = popup.AbsolutePosition
            local psz = popup.AbsoluteSize
            local sa2 = swatch.AbsolutePosition
            local sz2 = swatch.AbsoluteSize
            local inPopup  = mp.X >= pa.X  and mp.X <= pa.X  + psz.X and mp.Y >= pa.Y  and mp.Y <= pa.Y  + psz.Y
            local inSwatch = mp.X >= sa2.X and mp.X <= sa2.X + sz2.X and mp.Y >= sa2.Y and mp.Y <= sa2.Y + sz2.Y
            if not inPopup and not inSwatch then
                if moveConn    then moveConn:Disconnect()    end
                if endConn     then endConn:Disconnect()     end
                if outsideConn then outsideConn:Disconnect() end
                closePopup()
            end
        end)

        popup.AncestryChanged:Connect(function(_, parent)
            if not parent then
                if moveConn    then moveConn:Disconnect()    end
                if endConn     then endConn:Disconnect()     end
                if outsideConn then outsideConn:Disconnect() end
            end
        end)

        refresh()
    end)

    return row
end

local function makeTag(head, playerName, onLogoClick)
    if not head or head:FindFirstChild("HittaTagLocal") then return end

    local ok, err = pcall(function()
        local accentColor = rgb(235, 235, 235)
        pcall(function() accentColor = lib.getAccent() end)

        local pillH        = 44
        local logoSize     = 32
        local padL         = 10
        local padR         = 16
        local titleSize    = 12
        local nameSize     = 10
        local cornerRadius = 12
        local glowPadding  = 18

        local cycle = {"HITTA ADMIN", "HITTA STAFF", "HITTA OWNER"}
        local maxTitleW = 0
        for _, t in ipairs(cycle) do
            local w = measureText(t .. "|", titleSize)
            if w > maxTitleW then maxTitleW = w end
        end

        local nameText = "@" .. playerName
        local nameW = measureText(nameText, nameSize)

        local textBlockW = math.max(maxTitleW, nameW)
        local pillTextW  = math.ceil(textBlockW + 4)
        local pillW      = math.ceil(4 + logoSize + padL + pillTextW + padR)

        local boardW  = pillW + glowPadding * 2
        local boardH  = pillH + glowPadding * 2
        local farSize = 36

        local function makeGradient(parent, rot)
            local startRot = rot or 0
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, rgb(200, 200, 200)),
                ColorSequenceKeypoint.new(0.50, rgb(255, 255, 255)),
                ColorSequenceKeypoint.new(1.00, rgb(20, 20, 20)),
            })
            g.Rotation = startRot
            g.Offset = Vector2.new(-1, 0)
            g.Parent = parent

            task.spawn(function()
                task.wait(0.1)
                if not g.Parent then return end

                -- Entrance (one-shot): gradient sweeps in from the left.
                local entranceTI = TweenInfo.new(
                    0.9, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out
                )
                local entrance = TS:Create(g, entranceTI, {Offset = Vector2.new(0, 0)})
                entrance:Play()
                entrance.Completed:Wait()
                if not g.Parent then return end

                -- Continuous seamless rotation: 0 -> 360 is visually identical
                -- so Linear infinite repeat loops without any visible jump.
                -- No in/out easing, no ping-pong — just the bright band slowly
                -- rotating around the element forever.
                local rotTI = TweenInfo.new(
                    6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false, 0
                )
                TS:Create(g, rotTI, {Rotation = startRot + 360}):Play()
            end)

            return g
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HittaTagLocal"
        billboard.StudsOffset = Vector3.new(0, 2.6, 0)
        billboard.AlwaysOnTop = true
        billboard.ResetOnSpawn = false
        billboard.Size = UDim2.new(0, boardW, 0, boardH)
        billboard.Parent = head

        local glow = Instance.new("ImageLabel")
        glow.Name = "Glow"
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.Size = UDim2.new(1, 0, 1, 0)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://6014261993"
        glow.ImageColor3 = rgb(255, 255, 255)
        glow.ImageTransparency = 0.6
        glow.ScaleType = Enum.ScaleType.Slice
        glow.SliceCenter = Rect.new(49, 49, 450, 450)
        glow.ZIndex = 1
        glow.Parent = billboard

        local pill = Instance.new("Frame")
        pill.AnchorPoint = Vector2.new(0.5, 0.5)
        pill.Position = UDim2.new(0.5, 0, 0.5, 0)
        pill.Size = UDim2.new(0, pillW, 0, pillH)
        pill.BackgroundColor3 = rgb(14, 14, 16)
        pill.BorderSizePixel = 0
        pill.ZIndex = 2
        pill.Parent = billboard

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(0, cornerRadius)
        pillCorner.Parent = pill

        local pillStroke = Instance.new("UIStroke")
        pillStroke.Color = rgb(255, 255, 255)
        pillStroke.Thickness = 1.4
        pillStroke.Transparency = 0
        pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        pillStroke.Parent = pill
        makeGradient(pillStroke, 45)

        local logoCircle = Instance.new("Frame")
        logoCircle.AnchorPoint = Vector2.new(0, 0.5)
        logoCircle.Size = UDim2.new(0, logoSize, 0, logoSize)
        logoCircle.Position = UDim2.new(0, 4, 0.5, 0)
        logoCircle.BackgroundColor3 = rgb(22, 22, 26)
        logoCircle.BorderSizePixel = 0
        logoCircle.ZIndex = 3
        logoCircle.Parent = pill

        local lcCorner = Instance.new("UICorner")
        lcCorner.CornerRadius = UDim.new(1, 0)
        lcCorner.Parent = logoCircle

        local lcStroke = Instance.new("UIStroke")
        lcStroke.Color = rgb(255, 255, 255)
        lcStroke.Thickness = 1.4
        lcStroke.Transparency = 0
        lcStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        lcStroke.Parent = logoCircle
        makeGradient(lcStroke, 45)

        local logoImg = Instance.new(onLogoClick and "ImageButton" or "ImageLabel")
        logoImg.Size = UDim2.new(0.62, 0, 0.62, 0)
        logoImg.AnchorPoint = Vector2.new(0.5, 0.5)
        logoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        logoImg.BackgroundTransparency = 1
        logoImg.Image = "rbxassetid://110745379320861"
        logoImg.ImageColor3 = accentColor
        logoImg.ScaleType = Enum.ScaleType.Fit
        logoImg.ZIndex = 4
        logoImg.Parent = logoCircle

        if onLogoClick then
            logoImg.AutoButtonColor = false
            logoImg.MouseButton1Click:Connect(onLogoClick)
            logoImg.MouseEnter:Connect(function() logoImg.ImageTransparency = 0.4 end)
            logoImg.MouseLeave:Connect(function() logoImg.ImageTransparency = 0 end)
        end

        local textHolder = Instance.new("Frame")
        textHolder.BackgroundTransparency = 1
        textHolder.BorderSizePixel = 0
        textHolder.AnchorPoint = Vector2.new(0, 0.5)
        textHolder.Position = UDim2.new(0, 4 + logoSize + padL, 0.5, 0)
        textHolder.Size = UDim2.new(0, pillTextW, 1, 0)
        textHolder.ZIndex = 3
        textHolder.Parent = pill

        local titleLabel = Instance.new("TextLabel")
        titleLabel.AnchorPoint = Vector2.new(0, 0)
        titleLabel.Position = UDim2.new(0, 0, 0, 7)
        titleLabel.Size = UDim2.new(1, 0, 0, titleSize + 3)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextColor3 = rgb(255, 255, 255)
        titleLabel.TextSize = titleSize
        titleLabel.Text = "|"
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Center
        titleLabel.ZIndex = 4
        titleLabel.Parent = textHolder
        makeGradient(titleLabel, 0)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.AnchorPoint = Vector2.new(0, 1)
        nameLabel.Position = UDim2.new(0, 0, 1, -6)
        nameLabel.Size = UDim2.new(1, 0, 0, nameSize + 2)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextColor3 = rgb(180, 180, 188)
        nameLabel.TextSize = nameSize
        nameLabel.Text = nameText
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.ZIndex = 4
        nameLabel.Parent = textHolder

        local typing      = false
        local cursorOn    = true
        local currentText = ""

        local function render()
            titleLabel.Text = currentText .. (cursorOn and "|" or " ")
        end

        task.spawn(function()
            while titleLabel.Parent do
                if not typing then
                    cursorOn = not cursorOn
                    render()
                end
                task.wait(0.5)
            end
        end)

        task.spawn(function()
            local typeSpeed  = 0.06
            local eraseSpeed = 0.035
            local holdTime   = 10
            local pauseAfter = 0.45
            local idx        = 0
            while titleLabel.Parent do
                idx = (idx % #cycle) + 1
                local target = cycle[idx]

                typing   = true
                cursorOn = true
                for i = 1, #target do
                    if not titleLabel.Parent then return end
                    currentText = target:sub(1, i)
                    render()
                    task.wait(typeSpeed)
                end
                typing = false

                local held = 0
                while held < holdTime do
                    if not titleLabel.Parent then return end
                    task.wait(0.1)
                    held = held + 0.1
                end

                typing   = true
                cursorOn = true
                for i = #target - 1, 0, -1 do
                    if not titleLabel.Parent then return end
                    currentText = target:sub(1, i)
                    render()
                    task.wait(eraseSpeed)
                end
                typing = false

                currentText = ""
                task.wait(pauseAfter)
            end
        end)

        local farMode  = false
        local morphing = false

        local function applyMorph(toFar)
            morphing = true
            local d = 0.4
            if toFar then
                tween(billboard, {Size = UDim2.new(0, farSize, 0, farSize)}, d)
                tween(titleLabel, {TextTransparency = 1}, d * 0.5)
                tween(nameLabel,  {TextTransparency = 1}, d * 0.5)
                tween(glow, {ImageTransparency = 1}, d * 0.5)
                tween(pill, {
                    Size = UDim2.new(0, farSize, 0, farSize),
                }, d)
                tween(logoCircle, {
                    Size     = UDim2.new(1, -6, 1, -6),
                    Position = UDim2.new(0, 3, 0.5, 0),
                }, d)
            else
                tween(billboard, {Size = UDim2.new(0, boardW, 0, boardH)}, d)
                tween(titleLabel, {TextTransparency = 0}, d)
                tween(nameLabel,  {TextTransparency = 0}, d)
                tween(glow, {ImageTransparency = 0.6}, d)
                tween(pill, {
                    Size = UDim2.new(0, pillW, 0, pillH),
                }, d)
                tween(logoCircle, {
                    Size     = UDim2.new(0, logoSize, 0, logoSize),
                    Position = UDim2.new(0, 4, 0.5, 0),
                }, d)
            end
            task.delay(d + 0.05, function() morphing = false end)
        end

        rs.RenderStepped:Connect(function()
            if not head or not head:IsDescendantOf(workspace) then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            local dist = (cam.CFrame.Position - head.Position).Magnitude
            local wantFar = dist > 55
            if not morphing and wantFar ~= farMode then
                farMode = wantFar
                applyMorph(wantFar)
            end
        end)
    end)

    if not ok then
        Notify("Hitta Hub", "Tag error: " .. tostring(err), 5, "right")
    end
end

local function setupOwnTag(char)
    task.spawn(function()
        pcall(function()
            local oldOwn = game:GetService("CoreGui"):FindFirstChild("HittaOwnTag")
            if oldOwn then oldOwn:Destroy() end
        end)
        local head = char:WaitForChild("Head", 10)
        if not head then return end
        makeTag(head, lp.Name)
    end)
end

if lp.Character then setupOwnTag(lp.Character) end
lp.CharacterAdded:Connect(setupOwnTag)

local function teleportTo(player)
    local char = player.Character
    local myChar = lp.Character
    if not char or not myChar then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if hrp and myHrp then
        myHrp.CFrame = hrp.CFrame * CFrame.new(3, 0, 3)
    end
end

local detected = {}
local placeId = tostring(game.PlaceId)
local serverId = tostring(game.JobId)

local function onHittaUser(userId, playerName)
    if closed or detected[userId] then return end
    detected[userId] = true

    local player = players:GetPlayerByUserId(userId)
    if not player then return end

    local function tagChar(char)
        if not char then return end
        local head = char:WaitForChild("Head", 5)
        if not head then return end
        makeTag(head, playerName, function() teleportTo(player) end)
    end

    if player.Character then tagChar(player.Character) end
    player.CharacterAdded:Connect(tagChar)

    lib.notifyAction(
        playerName .. " is using Hitta Hub",
        "Teleport to this player?",
        "Teleport",
        function() teleportTo(player) end,
        10,
        "right"
    )
end

if apiActive then
    local hasHttp = (syn and syn.request) or http_request or request
    if not hasHttp then
        Notify("Hitta Hub", "No HTTP wrapper found on this executor", 8, "right")
    end

    task.spawn(function()
        local cg = game:GetService("CoreGui")
        while task.wait(0.5) do
            if cg:FindFirstChild("HittaHub") then break end
        end
        while task.wait(0.5) do
            if not cg:FindFirstChild("HittaHub") then
                closed = true
                for _, plr in next, players:GetPlayers() do
                    local char = plr.Character
                    if char then
                        local head = char:FindFirstChild("Head")
                        if head then
                            local existing = head:FindFirstChild("HittaTagLocal")
                            if existing then existing:Destroy() end
                        end
                    end
                end
                break
            end
        end
    end)

    task.delay(2, function()
        apiPost("/register", {
            userId = lp.UserId,
            name = lp.Name,
            placeId = placeId,
            serverId = serverId,
        })
    end)

    task.spawn(function()
        while task.wait(10) do
            if closed then break end
            apiPost("/register", {
                userId = lp.UserId,
                name = lp.Name,
                placeId = placeId,
                serverId = serverId,
            })
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            if closed then break end
            local data = apiGet("/users?placeId=" .. placeId .. "&serverId=" .. serverId)
            if data and type(data) == "table" then
                for _, entry in next, data do
                    if entry.userId ~= lp.UserId then
                        onHittaUser(entry.userId, entry.name)
                    end
                end
            end
        end
    end)
end

local home       = addTab("Home", "rbxassetid://131793828675026")
local addMiniTab = addMiniTabBar(home)

local movementPane = addMiniTab("Movement")
addSectionLabel(movementPane, "MOVEMENT")

local walkSpeedEnabled = false
local walkSpeedValue   = 16
local jumpEnabled      = false
local jumpValue        = 50

local function getHumanoid()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function applyWalkSpeed()
    local h = getHumanoid()
    if not h then return end
    h.WalkSpeed = walkSpeedEnabled and walkSpeedValue or 16
end

local function applyJump()
    local h = getHumanoid()
    if not h then return end
    if h.UseJumpPower then
        h.JumpPower = jumpEnabled and jumpValue or 50
    else
        h.JumpHeight = jumpEnabled and (jumpValue / 7) or 7.2
    end
end

lp.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.1)
    applyWalkSpeed()
    applyJump()
end)

addToggleSlider(movementPane, "Speed", 16, 300, 16,
    function(v) walkSpeedEnabled = v; applyWalkSpeed() end,
    function(v) walkSpeedValue   = v; if walkSpeedEnabled then applyWalkSpeed() end end
)

addToggleSlider(movementPane, "Jump", 50, 500, 50,
    function(v) jumpEnabled = v; applyJump() end,
    function(v) jumpValue   = v; if jumpEnabled then applyJump() end end
)

addToggleSlider(movementPane, "FOV", 30, 150, 120,
    function(v) Features.customFov:set(v) end,
    function(v) customFovValue = v end
)

addCustomCheckbox(movementPane, "No Clip", false, function(v)
    Features.noclip:set(v)
    Notify("No Clip", v and "Enabled" or "Disabled", 2, "left")
end)

addCustomCheckbox(movementPane, "Dash Timer", false, function(v)
    Features.dashTimer:set(v)
    Notify("Dash Timer", v and "Enabled" or "Disabled", 2, "left")
end)

local combatPane = addMiniTab("Combat")
addSectionLabel(combatPane, "COMBAT")

addCustomCheckbox(combatPane, "Auto Wall Combo", false, function(v)
    Features.autoWallCombo:set(v)
    Notify("Auto Wall Combo", v and "Enabled" or "Disabled", 2, "left")
end)

addCustomCheckbox(combatPane, "Wall Combo Anywhere", false, function(v)
    Features.wallComboTilt:set(v)
    Notify("Wall Combo Anywhere", v and "Enabled" or "Disabled", 2, "left")
end)

addCustomCheckbox(combatPane, "Invisibility", false, function(v)
    Features.invisibility:set(v)
    Notify("Invisibility", v and "Enabled" or "Disabled", 2, "left")
end)

addCustomCheckbox(combatPane, "Anti Stun", false, function(v)
    Features.antiFreeze:set(v)
    Notify("Anti Stun", v and "Enabled" or "Disabled", 2, "left")
end)

addCustomCheckbox(combatPane, "Anti Death Counter", false, function(v)
    Features.antiDeath:set(v)
    Notify("Anti Death Counter", v and "Enabled" or "Disabled", 2, "left")
end)

addSectionLabel(combatPane, "SAFE MODE")
addToggleSlider(combatPane, "Safe Mode HP", 1, 100, 25,
    function(v) Features.safeMode:set(v); Notify("Safe Mode", v and "Enabled" or "Disabled", 2, "left") end,
    function(v) safeModeHpThreshold = v end
)

local miscPane = addMiniTab("Misc")
addSectionLabel(miscPane, "UTILITY")

addCustomCheckbox(miscPane, "Extra Slots", false, function(v)
    Features.extraSlots:set(v)
    Notify("Extra Slots", v and "Enabled" or "Disabled", 2, "left")
end)

addCustomCheckbox(miscPane, "No Dash Cooldown", false, function(v)
    Features.noDashCooldown:set(v)
    Notify("No Dash Cooldown", v and "Enabled" or "Disabled", 2, "left")
end)

local fun = addTab("Fun", "rbxassetid://113891180779762")
addSectionLabel(fun, "EFFECT COLORS")

Features.effectColors:enable()

addCompactColorPicker(fun, "Tatsumaki Shield", rgb(85, 170, 0), function(c)
    effectColors.shield = c
end)
addCompactColorPicker(fun, "Garou Palm", rgb(57, 115, 172), function(c)
    effectColors.palm = c
end)
addCompactColorPicker(fun, "Monster Palm", rgb(255, 0, 0), function(c)
    effectColors.redPalm = c
end)
addCompactColorPicker(fun, "Garou Ult Aura", rgb(255, 255, 255), function(c)
    effectColors.aura = c
end)
addCompactColorPicker(fun, "Garou Palm 2", rgb(85, 85, 255), function(c)
    effectColors.beam = c
end)

local scripts = addTab("Universal", "rbxassetid://120815364903510")
addSectionLabel(scripts, "UNIVERSAL ADMIN")
addButton(scripts, "Infinite Yield", function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
    if ok then
        Notify("Scripts", "Infinite Yield loaded", 3, "right")
    else
        Notify("Scripts", "Failed: " .. tostring(err), 5, "right")
    end
end)
addButton(scripts, "Nameless Admin", function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua"))()
    end)
    if ok then
        Notify("Scripts", "Nameless Admin loaded", 3, "right")
    else
        Notify("Scripts", "Failed: " .. tostring(err), 5, "right")
    end
end)

local updates = addTab("Updates", "rbxassetid://90020042637462")
do
    local logFrame = Instance.new("Frame")
    logFrame.Parent = updates
    logFrame.Size = UDim2.new(1, 0, 0, 180)
    logFrame.BackgroundColor3 = rgb(16, 16, 18)
    logFrame.BorderSizePixel = 0
    local lfc = Instance.new("UICorner") lfc.CornerRadius = UDim.new(0, 8) lfc.Parent = logFrame
    local lfs = Instance.new("UIStroke") lfs.Color = rgb(30, 30, 34) lfs.Thickness = 1 lfs.Parent = logFrame
    local lfp = Instance.new("UIPadding")
    lfp.PaddingTop = UDim.new(0, 16) lfp.PaddingBottom = UDim.new(0, 16)
    lfp.PaddingLeft = UDim.new(0, 16) lfp.PaddingRight = UDim.new(0, 16)
    lfp.Parent = logFrame

    local title = Instance.new("TextLabel")
    title.Parent = logFrame
    title.Size = UDim2.new(1, 0, 0, 22)
    title.BackgroundTransparency = 1
    title.Text = "Huge Rework 1.0"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = rgb(235, 235, 235)
    title.TextXAlignment = Enum.TextXAlignment.Left

    local body = Instance.new("TextLabel")
    body.Parent = logFrame
    body.Position = UDim2.new(0, 0, 0, 32)
    body.Size = UDim2.new(1, 0, 1, -32)
    body.BackgroundTransparency = 1
    body.Text = "+ New UI\n+ New features"
    body.Font = Enum.Font.Gotham
    body.TextSize = 13
    body.TextColor3 = rgb(150, 150, 158)
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
end

-- ============================================================
-- CHAT TAB (Firebase Realtime DB)
-- ============================================================
local chat = addTab("Chat", "rbxassetid://74038842302780")
do
    local FIREBASE_URL   = "https://hubchat777-default-rtdb.europe-west1.firebasedatabase.app/messages.json"
    local POLL_INTERVAL  = 5    -- seconds between auto-refresh
    local MAX_LEN        = 200  -- max chars per message
    local SEND_COOLDOWN  = 5    -- seconds between sends per client
    local MAX_DISPLAY    = 50   -- only render last N messages

    local httpReq = (syn and syn.request) or http_request or request
        or (fluxus and fluxus.request)
    local HTTP    = game:GetService("HttpService")
    local player  = game:GetService("Players").LocalPlayer

    -- Remove default list layout of the tab scrolling frame so we can build a custom layout
    for _, ch in next, chat:GetChildren() do
        if ch:IsA("UIListLayout") or ch:IsA("UIPadding") then ch:Destroy() end
    end
    chat.ScrollingEnabled    = false
    chat.AutomaticCanvasSize = Enum.AutomaticSize.None
    chat.CanvasSize          = UDim2.new(0, 0, 0, 0)

    -- Messages scrolling area
    local msgScroll = Instance.new("ScrollingFrame")
    msgScroll.Parent                = chat
    msgScroll.Size                  = UDim2.new(1, -28, 1, -72)
    msgScroll.Position              = UDim2.new(0, 14, 0, 14)
    msgScroll.BackgroundTransparency = 1
    msgScroll.BorderSizePixel       = 0
    msgScroll.ScrollBarThickness    = 2
    msgScroll.ScrollBarImageColor3  = rgb(60, 60, 60)
    msgScroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
    msgScroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    msgScroll.ScrollingDirection    = Enum.ScrollingDirection.Y

    local msgList = Instance.new("UIListLayout")
    msgList.Parent     = msgScroll
    msgList.SortOrder  = Enum.SortOrder.LayoutOrder
    msgList.Padding    = UDim.new(0, 6)

    -- Input row at the bottom
    local inputRow = Instance.new("Frame")
    inputRow.Parent              = chat
    inputRow.Size                = UDim2.new(1, -28, 0, 42)
    inputRow.Position            = UDim2.new(0, 14, 1, -54)
    inputRow.BackgroundTransparency = 1

    local inputBg = Instance.new("Frame")
    inputBg.Parent          = inputRow
    inputBg.Size            = UDim2.new(1, -88, 1, 0)
    inputBg.BackgroundColor3 = rgb(22, 22, 24)
    inputBg.BorderSizePixel = 0
    local ibc = Instance.new("UICorner") ibc.CornerRadius = UDim.new(0, 10) ibc.Parent = inputBg
    local ibs = Instance.new("UIStroke") ibs.Color = rgb(35, 35, 38) ibs.Thickness = 1 ibs.Parent = inputBg

    local inputBox = Instance.new("TextBox")
    inputBox.Parent             = inputBg
    inputBox.Size               = UDim2.new(1, -24, 1, 0)
    inputBox.Position           = UDim2.new(0, 12, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Text               = ""
    inputBox.PlaceholderText    = "Type a message..."
    inputBox.PlaceholderColor3  = rgb(85, 85, 90)
    inputBox.TextColor3         = rgb(220, 220, 220)
    inputBox.Font               = Enum.Font.Gotham
    inputBox.TextSize           = 13
    inputBox.TextXAlignment     = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus   = false
    inputBox.ClipsDescendants   = true

    local sendBtn = Instance.new("TextButton")
    sendBtn.Parent         = inputRow
    sendBtn.Size           = UDim2.new(0, 78, 1, 0)
    sendBtn.Position       = UDim2.new(1, -78, 0, 0)
    sendBtn.BackgroundColor3 = rgb(235, 235, 235)
    sendBtn.BorderSizePixel = 0
    sendBtn.Text           = "Send"
    sendBtn.TextColor3     = rgb(15, 15, 18)
    sendBtn.Font           = Enum.Font.GothamBold
    sendBtn.TextSize       = 13
    sendBtn.AutoButtonColor = false
    local sbc = Instance.new("UICorner") sbc.CornerRadius = UDim.new(0, 10) sbc.Parent = sendBtn

    sendBtn.MouseEnter:Connect(function() sendBtn.BackgroundColor3 = rgb(255,255,255) end)
    sendBtn.MouseLeave:Connect(function() sendBtn.BackgroundColor3 = rgb(235,235,235) end)

    -- HTTP helpers
    local function httpGet()
        if not httpReq then return nil end
        local ok, res = pcall(httpReq, { Url = FIREBASE_URL, Method = "GET" })
        if not ok or not res then return nil end
        local code = res.StatusCode or res.Status or 0
        if code ~= 200 then return nil end
        local body = res.Body
        if not body or body == "null" or body == "" then return {} end
        local parsed
        pcall(function() parsed = HTTP:JSONDecode(body) end)
        return parsed or {}
    end

    local function httpPost(payload)
        if not httpReq then return false end
        local ok, res = pcall(httpReq, {
            Url     = FIREBASE_URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HTTP:JSONEncode(payload),
        })
        if not ok or not res then return false end
        local code = res.StatusCode or res.Status or 0
        return code == 200 or code == 201
    end

    -- Rendering
    local rendered = {}  -- [firebaseKey] = true
    local orderN   = 0

    local function renderMessage(key, msg)
        if rendered[key] then return end
        rendered[key] = true
        orderN = orderN + 1

        local bubble = Instance.new("Frame")
        bubble.Parent           = msgScroll
        bubble.Size             = UDim2.new(1, -8, 0, 0)
        bubble.AutomaticSize    = Enum.AutomaticSize.Y
        bubble.BackgroundColor3 = rgb(18, 18, 20)
        bubble.BorderSizePixel  = 0
        bubble.LayoutOrder      = orderN

        local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 10) bc.Parent = bubble
        local bp = Instance.new("UIPadding")
        bp.PaddingTop    = UDim.new(0, 8)
        bp.PaddingBottom = UDim.new(0, 8)
        bp.PaddingLeft   = UDim.new(0, 12)
        bp.PaddingRight  = UDim.new(0, 12)
        bp.Parent        = bubble

        local timeStr = ""
        if msg.time then
            local ok, t = pcall(os.date, "%H:%M", msg.time)
            if ok then timeStr = t end
        end

        local header = Instance.new("TextLabel")
        header.Parent              = bubble
        header.Size                = UDim2.new(1, 0, 0, 16)
        header.BackgroundTransparency = 1
        header.Text                = "@" .. tostring(msg.user or "unknown") .. "   " .. timeStr
        header.TextColor3          = rgb(240, 240, 240)
        header.Font                = Enum.Font.GothamBold
        header.TextSize            = 13
        header.TextXAlignment      = Enum.TextXAlignment.Left

        local content = Instance.new("TextLabel")
        content.Parent              = bubble
        content.Size                = UDim2.new(1, 0, 0, 0)
        content.AutomaticSize       = Enum.AutomaticSize.Y
        content.Position            = UDim2.new(0, 0, 0, 20)
        content.BackgroundTransparency = 1
        content.Text                = tostring(msg.text or "")
        content.TextColor3          = rgb(195, 195, 200)
        content.Font                = Enum.Font.Gotham
        content.TextSize            = 13
        content.TextXAlignment      = Enum.TextXAlignment.Left
        content.TextYAlignment      = Enum.TextYAlignment.Top
        content.TextWrapped         = true

        task.defer(function()
            if msgScroll and msgScroll.Parent then
                msgScroll.CanvasPosition = Vector2.new(0, msgScroll.AbsoluteCanvasSize.Y)
            end
        end)
    end

    -- Refresh: fetch and render new messages
    local function refresh()
        local data = httpGet()
        if not data then return end
        local list = {}
        for k, m in pairs(data) do
            if type(m) == "table" then
                table.insert(list, { key = k, msg = m })
            end
        end
        table.sort(list, function(a, b)
            return (a.msg.time or 0) < (b.msg.time or 0)
        end)
        while #list > MAX_DISPLAY do
            table.remove(list, 1)
        end
        for _, e in ipairs(list) do
            renderMessage(e.key, e.msg)
        end
    end

    -- Poll loop
    task.spawn(function()
        task.wait(0.5)
        refresh()
        while task.wait(POLL_INTERVAL) do
            refresh()
        end
    end)

    -- Send handler
    local lastSend = 0
    local function trySend()
        local text = inputBox.Text or ""
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if #text == 0 then return end
        if #text > MAX_LEN then
            Notify("Chat", "Message too long (max " .. MAX_LEN .. " chars)", 3, "left")
            return
        end
        local now = tick()
        if now - lastSend < SEND_COOLDOWN then
            Notify("Chat", "Slow down! Wait " .. math.ceil(SEND_COOLDOWN - (now - lastSend)) .. "s", 2, "left")
            return
        end
        lastSend = now
        inputBox.Text = ""

        task.spawn(function()
            local ok = httpPost({
                user    = player.Name,
                display = player.DisplayName,
                text    = text,
                time    = os.time(),
            })
            if not ok then
                Notify("Chat", "Failed to send message", 3, "left")
            else
                task.wait(0.3)
                refresh()
            end
        end)
    end

    sendBtn.MouseButton1Click:Connect(trySend)
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then trySend() end
    end)
end

local settings       = addTab("Settings", "rbxassetid://91396599856764")
local addSettingsTab = addMiniTabBar(settings)

local effectsPane = addSettingsTab("Effects")
addSectionLabel(effectsPane, "EFFECTS")
addToggle(effectsPane, "Transparent", false, function(v)
    lib.setAcrylic(v)
    Notify("Transparent", v and "Enabled" or "Disabled", 2, "left")
end)
addSectionLabel(effectsPane, "ACCENT COLOR")
addColorPicker(effectsPane, "Color", rgb(235,235,235), function(color)
    lib.setAccentColor(color)
end)

local keybindPane = addSettingsTab("Keybind")
addSectionLabel(keybindPane, "KEYBIND")
addKeybind(keybindPane, "Toggle UI", Enum.KeyCode.RightShift, function(key)
    lib.setToggleKey(key)
    Notify("Keybind", "Set to " .. key.Name, 2, "left")
end)

local configPane = addSettingsTab("Config")
addSectionLabel(configPane, "CONFIGURATION")
local _, configBox = addTextBox(configPane, "Config Name", "my_config")

local refreshList

addButton(configPane, "Save Config", function()
    local name = configBox.Text
    if name == "" then Notify("Config", "Enter a config name first", 2, "right"); return end
    lib.saveConfig(name, lib.getState())
    Notify("Config Saved", "Saved as '" .. name .. "'", 3, "right")
    if refreshList then refreshList() end
end)

addSectionLabel(configPane, "SAVED CONFIGS")

refreshList = addConfigList(configPane,
    function(name)
        local data = lib.loadConfig(name)
        if not data then Notify("Config", "'" .. name .. "' not found", 2, "right"); return end
        lib.setState(data)
        Notify("Config Loaded", "Loaded '" .. name .. "'", 3, "right")
    end,
    function(name)
        lib.deleteConfig(name)
        Notify("Config Deleted", "Deleted '" .. name .. "'", 3, "right")
    end
)

selectTab("Home")

task.delay(0.5, function()
    Notify("Hitta Hub  v2.0", "Loaded successfully", 4, "right")
end)

getgenv().Notify = Notify
