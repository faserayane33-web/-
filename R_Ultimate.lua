--[[
    R | Instant Steal - Protected Edition
    Features: Single Press E + Strong Anti-Cheat System
--]]

-- ============================================
-- 1. الإعدادات
-- ============================================
local Config = {
    Enabled = true,
    PressDuration = 0.5,
    HoldInterval = 0.05,
    ProtectionEnabled = true,
}

-- ============================================
-- 2. نظام الحماية القوي (5 طبقات)
-- ============================================
local Protection = {}

-- 2.1 Property Spoofing: إخفاء WalkSpeed و CFrame
function Protection.SpoofProperties()
    pcall(function()
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        setreadonly(mt, false)
        mt.__index = newcclosure(function(self, key)
            if not checkcaller() then
                if key == "WalkSpeed" then
                    return 16 -- القيمة الأصلية
                end
                if key == "CFrame" and self:IsA("BasePart") then
                    return oldIndex(self, key)
                end
            end
            return oldIndex(self, key)
        end)
        setreadonly(mt, true)
    end)
    
    -- حماية إضافية: منع تعديل WalkSpeed من السيرفر
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNewIndex = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = newcclosure(function(self, key, value)
            if key == "WalkSpeed" and not checkcaller() then
                return
            end
            return oldNewIndex(self, key, value)
        end)
        setreadonly(mt, true)
    end)
end

-- 2.2 Debug Hooking: إخفاء السكريبت من الفحص
function Protection.HookDebug()
    pcall(function()
        local oldGetInfo = debug.getinfo
        debug.getinfo = newcclosure(function(thread, func, what)
            local info = oldGetInfo(thread, func, what)
            if info and info.source then
                if info.source:find("R_") or info.source:find("Instant") then
                    info.source = "=[C]"
                end
            end
            return info
        end)
    end)
    
    -- إخفاء الدوال
    pcall(function()
        local oldGetName = debug.getfenv
        if oldGetName then
            debug.getfenv = newcclosure(function(f)
                return nil
            end)
        end
    end)
end

-- 2.3 Remote Blocking: منع بلاغات الحماية
function Protection.BlockRemotes()
    pcall(function()
        local replicatedStorage = game:GetService("ReplicatedStorage")
        for _, remote in ipairs(replicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local name = remote.Name:lower()
                if name:find("report") or name:find("flag") or name:find("detect") 
                   or name:find("ban") or name:find("kick") then
                    local conns = getconnections(remote.OnClientEvent)
                    for _, c in ipairs(conns) do
                        pcall(function() c:Disconnect() end)
                    end
                end
            end
        end
    end)
end

-- 2.4 Anti-Cheat Detection: اكتشاف سكريبتات الحماية
function Protection.DetectAntiCheat()
    pcall(function()
        -- مراقبة السكريبتات الجديدة
        local connection = game:GetService("ScriptContext").ScriptAdded:Connect(function(script)
            if script.Name:lower():find("anticheat") or 
               script.Name:lower():find("ac") or
               script.Name:lower():find("guard") then
                pcall(function() script:Destroy() end)
            end
        end)
        
        -- تعطيل الاتصالات المشبوهة
        local char = game.Players.LocalPlayer.Character
        if char then
            for _, conn in ipairs(getconnections(char.Humanoid.Changed)) do
                pcall(function() conn:Disconnect() end)
            end
        end
    end)
end

-- 2.5 Safe Input: محاكاة إدخال آمن
function Protection.SimulateInput(key, press)
    pcall(function()
        local virtualUser = game:GetService("VirtualUser")
        virtualUser:CaptureController()
        if press then
            virtualUser:ButtonDown(key)
        else
            virtualUser:ButtonUp(key)
        end
    end)
end

-- تفعيل كل الطبقات
function Protection.Enable()
    Protection.SpoofProperties()
    Protection.HookDebug()
    Protection.BlockRemotes()
    Protection.DetectAntiCheat()
    print("[R] Protection: All layers enabled")
end

if Config.ProtectionEnabled then
    Protection.Enable()
end

-- ============================================
-- 3. نظام الضغط التلقائي (محمي)
-- ============================================
local UserInputService = game:GetService("UserInputService")

local isHolding = false
local holdTask = nil

local function startHolding()
    if isHolding then return end
    isHolding = true
    
    -- استخدام Safe Input
    Protection.SimulateInput(Enum.KeyCode.E, true)
    
    holdTask = task.spawn(function()
        while isHolding do
            Protection.SimulateInput(Enum.KeyCode.E, true)
            task.wait(Config.HoldInterval)
        end
    end)
end

local function stopHolding()
    if not isHolding then return end
    isHolding = false
    
    Protection.SimulateInput(Enum.KeyCode.E, false)
    
    if holdTask then
        task.cancel(holdTask)
        holdTask = nil
    end
end

-- مراقبة ضغط E
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not Config.Enabled then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        startHolding()
        task.delay(Config.PressDuration, function()
            stopHolding()
        end)
    end
end)

-- ============================================
-- 4. الواجهة الصغيرة (زر واحد)
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "R_InstantSteal"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 130, 0, 55)
Frame.Position = UDim2.new(0, 15, 0.5, -27)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 18)
Title.BackgroundTransparency = 1
Title.Text = "🐺 R | Instant E"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 10
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 28)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 22)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
ToggleBtn.Text = "✅ مفعل"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    Config.Enabled = not Config.Enabled
    
    if Config.Enabled then
        ToggleBtn.Text = "✅ مفعل"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    else
        ToggleBtn.Text = "❌ معطل"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    end
end)

print("[R] Protected Instant Steal Loaded!")
