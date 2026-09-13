--[[
    R | Steal an Egg - Ultimate Edition
    Features: ESP Eggs, Egg Predictor, Auto Steal, Speed Compensator
    Built for Angels vs Demons Update
--]]

-- ============================================
-- 1. الإعدادات
-- ============================================
local Config = {
    TargetSpeed = 20e9,
    CurrentSpeed = 2e9,
    TeleportDelay = 0.1,
    AutoReturn = true,
    ReturnPosition = nil,
    MinEggSize = 1.0,
    MinRarity = "Legendary",
    StealSpeed = 0.1,
    AutoSteal = false,
    EggPredictor = true,
    ShowAnimalNames = true,
}

-- ============================================
-- 2. قاعدة بيانات الحيوانات (من التحديث الجديد)
-- ============================================
local AnimalDatabase = {
    -- Angels (Light)
    ["Angel Egg"] = {
        ["Legendary"] = "Light Dove",
        ["Mythic"] = "Winged Lamb",
        ["Cosmic"] = "Sacred Moth",
        ["Secret"] = "Pure Jellyfish",
        ["Eternal"] = "Pegasus",
        ["Divine"] = "ArchAngel",
    },
    -- Demons (Darkness)
    ["Demon Egg"] = {
        ["Legendary"] = "Flame Sprite",
        ["Mythic"] = "Toro",
        ["Cosmic"] = "Imp",
        ["Secret"] = "Gargoyle",
        ["Eternal"] = "Skeleton Horse",
        ["Divine"] = "World Burner",
    },
    -- بيضات عادية (أمثلة)
    ["Common Egg"] = { ["Common"] = "Dog", ["Uncommon"] = "Cat" },
    ["Rare Egg"] = { ["Rare"] = "Dragon", ["Legendary"] = "Phoenix" },
}

-- ============================================
-- 3. نظام الحماية
-- ============================================
local Protection = {}

function Protection.Enable()
    pcall(function()
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        setreadonly(mt, false)
        mt.__index = newcclosure(function(self, key)
            if key == "CFrame" and checkcaller() == false then
                return oldIndex(self, key)
            end
            return oldIndex(self, key)
        end)
        setreadonly(mt, true)
    end)
    
    -- تعطيل الإبلاغ
    pcall(function()
        for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local name = remote.Name:lower()
                if name:find("report") or name:find("flag") then
                    local conns = getconnections(remote.OnClientEvent)
                    for _, c in ipairs(conns) do
                        pcall(function() c:Disconnect() end)
                    end
                end
            end
        end
    end)
    print("[R] Protection Enabled")
end

Protection.Enable()

-- ============================================
-- 4. نظام ESP Eggs (محدث مع Egg Predictor)
-- ============================================
local ESP = {
    Enabled = false,
    Drawings = {},
    Connections = {},
}

local function getEggInfo(eggName)
    -- البحث في قاعدة البيانات
    for eggPattern, animals in pairs(AnimalDatabase) do
        if eggName:find(eggPattern) or eggPattern:find(eggName) then
            local info = ""
            for rarity, animal in pairs(animals) do
                info = info .. animal .. " (" .. rarity .. ")\n"
            end
            return info
        end
    end
    return "حيوان غير معروف"
end

local function createEggESP(egg)
    local ok, billboard = pcall(function()
        local primary = egg:IsA("Model") and egg.PrimaryPart or egg
        if not primary then return nil end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "R_EggESP"
        billboard.Size = UDim2.new(0, 220, 0, 80)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = primary
        billboard.Parent = primary

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = billboard

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        -- اسم البيضة
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 22)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "🥚 " .. egg.Name
        nameLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.Parent = frame

        -- Egg Predictor: الحيوان المتوقع
        local predictLabel = Instance.new("TextLabel")
        predictLabel.Size = UDim2.new(1, 0, 0, 40)
        predictLabel.Position = UDim2.new(0, 0, 0, 22)
        predictLabel.BackgroundTransparency = 1
        predictLabel.Text = Config.EggPredictor and getEggInfo(egg.Name) or "؟"
        predictLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        predictLabel.Font = Enum.Font.GothamMedium
        predictLabel.TextSize = 10
        predictLabel.TextWrapped = true
        predictLabel.Parent = frame

        -- معلومات الحجم
        local sizeLabel = Instance.new("TextLabel")
        sizeLabel.Size = UDim2.new(1, 0, 0, 16)
        sizeLabel.Position = UDim2.new(0, 0, 0, 62)
        sizeLabel.BackgroundTransparency = 1
        sizeLabel.Text = "📏 الحجم: " .. tostring(math.floor((primary.Size.Magnitude or 1) * 10) / 10)
        sizeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        sizeLabel.Font = Enum.Font.Gotham
        sizeLabel.TextSize = 9
        sizeLabel.Parent = frame

        return billboard
    end)
    return ok and billboard or nil
end

function ESP.Enable()
    ESP.Enabled = true
    
    -- البحث عن كل البيض
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Model") and obj.Name:find("Egg") then
                if not ESP.Drawings[obj] then
                    local bb = createEggESP(obj)
                    if bb then ESP.Drawings[obj] = bb end
                end
            end
        end)
    end
    
    -- مراقبة البيض الجديد
    local conn = workspace.DescendantAdded:Connect(function(obj)
        if ESP.Enabled and obj:IsA("Model") and obj.Name:find("Egg") then
            task.wait(0.3)
            if not ESP.Drawings[obj] then
                local bb = createEggESP(obj)
                if bb then ESP.Drawings[obj] = bb end
            end
        end
    end)
    table.insert(ESP.Connections, conn)
    print("[R] ESP Eggs Enabled")
end

function ESP.Disable()
    ESP.Enabled = false
    for obj, bb in pairs(ESP.Drawings) do
        pcall(function() bb:Destroy() end)
    end
    ESP.Drawings = {}
    for _, c in ipairs(ESP.Connections) do
        pcall(function() c:Disconnect() end)
    end
    ESP.Connections = {}
    print("[R] ESP Eggs Disabled")
end

-- ============================================
-- 5. نظام Teleport (بديل السرعة)
-- ============================================
local Teleport = {}

function Teleport.SaveReturnPosition()
    pcall(function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            Config.ReturnPosition = char.HumanoidRootPart.CFrame
        end
    end)
end

function Teleport.To(position)
    pcall(function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(position)
        end
    end)
end

function Teleport.Return()
    if Config.AutoReturn and Config.ReturnPosition then
        Teleport.To(Config.ReturnPosition.Position)
    end
end

function Teleport.FindBestEgg()
    local ok, bestEgg, bestScore = pcall(function()
        local char = game.Players.LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
        local root = char.HumanoidRootPart
        
        local best, bestScore = nil, 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Egg") then
                local primary = obj.PrimaryPart
                if primary then
                    local dist = (primary.Position - root.Position).Magnitude
                    local size = primary.Size.Magnitude or 1
                    local score = size * 100 - dist -- كل ما كبر وحدة، كل ما زاد التقييم
                    if score > bestScore then
                        best, bestScore = obj, score
                    end
                end
            end
        end
        return best
    end)
    return ok and bestEgg or nil
end

-- ============================================
-- 6. الواجهة (UI)
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "R_Ultimate"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 270, 0, 400)
Frame.Position = UDim2.new(0.5, -135, 0.5, -200)
Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 14)
UICorner.Parent = Frame

-- العنوان
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
Title.Text = "🐺 R | Ultimate"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 14)
TitleCorner.Parent = Title

-- عرض السرعة
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0.9, 0, 0, 28)
SpeedLabel.Position = UDim2.new(0.05, 0, 0, 55)
SpeedLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
SpeedLabel.Text = "⚡ Speed: 2B / 20B"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
SpeedLabel.Font = Enum.Font.GothamMedium
SpeedLabel.TextSize = 12
SpeedLabel.Parent = Frame

local SpeedCorner = Instance.new("UICorner")
SpeedCorner.CornerRadius = UDim.new(0, 6)
SpeedCorner.Parent = SpeedLabel

-- زر ESP
local ESPBtn = Instance.new("TextButton")
ESPBtn.Size = UDim2.new(0.9, 0, 0, 38)
ESPBtn.Position = UDim2.new(0.05, 0, 0, 95)
ESPBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
ESPBtn.Text = "👁️ ESP Eggs (عرض البيض)"
ESPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPBtn.Font = Enum.Font.GothamBold
ESPBtn.TextSize = 12
ESPBtn.Parent = Frame

local ESPCorner = Instance.new("UICorner")
ESPCorner.CornerRadius = UDim.new(0, 8)
ESPCorner.Parent = ESPBtn

-- زر Auto Steal
local AutoStealBtn = Instance.new("TextButton")
AutoStealBtn.Size = UDim2.new(0.9, 0, 0, 38)
AutoStealBtn.Position = UDim2.new(0.05, 0, 0, 140)
AutoStealBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
AutoStealBtn.Text = "🥚 Auto Steal (سرقة تلقائية)"
AutoStealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoStealBtn.Font = Enum.Font.GothamBold
AutoStealBtn.TextSize = 12
AutoStealBtn.Parent = Frame

local AutoStealCorner = Instance.new("UICorner")
AutoStealCorner.CornerRadius = UDim.new(0, 8)
AutoStealCorner.Parent = AutoStealBtn

-- زر Egg Predictor
local PredictorBtn = Instance.new("TextButton")
PredictorBtn.Size = UDim2.new(0.9, 0, 0, 38)
PredictorBtn.Position = UDim2.new(0.05, 0, 0, 185)
PredictorBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 100)
PredictorBtn.Text = "🔮 Egg Predictor (توقع البيض)"
PredictorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PredictorBtn.Font = Enum.Font.GothamBold
PredictorBtn.TextSize = 12
PredictorBtn.Parent = Frame

local PredictorCorner = Instance.new("UICorner")
PredictorCorner.CornerRadius = UDim.new(0, 8)
PredictorCorner.Parent = PredictorBtn

-- زر Teleport Best Egg
local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Size = UDim2.new(0.9, 0, 0, 38)
TeleportBtn.Position = UDim2.new(0.05, 0, 0, 230)
TeleportBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
TeleportBtn.Text = "📍 Teleport لأفضل بيضة"
TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportBtn.Font = Enum.Font.GothamBold
TeleportBtn.TextSize = 12
TeleportBtn.Parent = Frame

local TeleportCorner = Instance.new("UICorner")
TeleportCorner.CornerRadius = UDim.new(0, 8)
TeleportCorner.Parent = TeleportBtn

-- زر Return
local ReturnBtn = Instance.new("TextButton")
ReturnBtn.Size = UDim2.new(0.9, 0, 0, 38)
ReturnBtn.Position = UDim2.new(0.05, 0, 0, 275)
ReturnBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
ReturnBtn.Text = "🔙 العودة للموقع"
ReturnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ReturnBtn.Font = Enum.Font.GothamBold
ReturnBtn.TextSize = 12
ReturnBtn.Parent = Frame

local ReturnCorner = Instance.new("UICorner")
ReturnCorner.CornerRadius = UDim.new(0, 8)
ReturnCorner.Parent = ReturnBtn

-- حالة الحماية
local ProtectionLabel = Instance.new("TextLabel")
ProtectionLabel.Size = UDim2.new(0.9, 0, 0, 25)
ProtectionLabel.Position = UDim2.new(0.05, 0, 0, 325)
ProtectionLabel.BackgroundTransparency = 1
ProtectionLabel.Text = "🛡️ الحماية: مفعلة | ESP: مغلق"
ProtectionLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
ProtectionLabel.Font = Enum.Font.GothamMedium
ProtectionLabel.TextSize = 10
ProtectionLabel.Parent = Frame

-- ============================================
-- 7. منطق الأزرار
-- ============================================
local espOn = false
local autoStealOn = false
local predictorOn = true
local autoStealConn = nil

ESPBtn.MouseButton1Click:Connect(function()
    espOn = not espOn
    if espOn then
        ESP.Enable()
        ESPBtn.Text = "✅ ESP مفعل"
        ESPBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    else
        ESP.Disable()
        ESPBtn.Text = "👁️ ESP Eggs (عرض البيض)"
        ESPBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
    end
    ProtectionLabel.Text = "🛡️ الحماية: مفعلة | ESP: " .. (espOn and "مفعل" or "مغلق")
end)

AutoStealBtn.MouseButton1Click:Connect(function()
    autoStealOn = not autoStealOn
    if autoStealOn then
        AutoStealBtn.Text = "✅ Auto Steal مفعل"
        AutoStealBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
        Teleport.SaveReturnPosition()
        
        autoStealConn = game:GetService("RunService").Heartbeat:Connect(function()
            if not autoStealOn then return end
            local egg = Teleport.FindBestEgg()
            if egg and egg.PrimaryPart then
                Teleport.To(egg.PrimaryPart.Position)
                task.wait(Config.StealSpeed)
                if Config.AutoReturn then
                    Teleport.Return()
                end
                task.wait(0.5)
            end
        end)
    else
        AutoStealBtn.Text = "🥚 Auto Steal (سرقة تلقائية)"
        AutoStealBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
        if autoStealConn then
            autoStealConn:Disconnect()
            autoStealConn = nil
        end
    end
end)

PredictorBtn.MouseButton1Click:Connect(function()
    predictorOn = not predictorOn
    Config.EggPredictor = predictorOn
    if predictorOn then
        PredictorBtn.Text = "✅ Egg Predictor مفعل"
        PredictorBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    else
        PredictorBtn.Text = "🔮 Egg Predictor (توقع البيض)"
        PredictorBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 100)
    end
end)

TeleportBtn.MouseButton1Click:Connect(function()
    Teleport.SaveReturnPosition()
    local egg = Teleport.FindBestEgg()
    if egg and egg.PrimaryPart then
        Teleport.To(egg.PrimaryPart.Position)
        task.wait(0.3)
    end
end)

ReturnBtn.MouseButton1Click:Connect(function()
    Teleport.Return()
end)

print("[R] Ultimate Script Loaded!")
print("[R] Features: ESP, Egg Predictor, Auto Steal, Teleport, Protection")
