--// PSX AUTO TRADE MULTI + GUI + NEON + WEBHOOK
--// DevEx32/Auto-Trade | TradeSpecific.lua

if not getgenv().Config then
    error("getgenv().Config is missing!")
end

local Config = getgenv().Config
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- ==================== CONFIG VALIDATION ====================
if #Config.usernames ~= #Config.How_many_Pets then
    error("usernames and How_many_Pets must match in count!")
end

-- Default neon
Config.Neon = Config.Neon == true

-- ==================== WEBHOOK (WORKS ON ALL EXECUTORS) ====================
local function sendWebhook(title, desc, color)
    if not Config.Webhook or Config.Webhook == "" then return end
    spawn(function()
        local payload = HttpService:JSONEncode({
            embeds = {{
                title = title,
                description = desc,
                color = color or 65280,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = { text = "PSX Auto Trade | " .. LocalPlayer.Name }
            }}
        })
        pcall(function()
            syn and syn.request or request or http_request or HttpPost({
                Url = Config.Webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = payload
            })
        end)
    end)
end

-- ==================== DEHASH REMOTES ====================
local function dehash()
    local router = require(ReplicatedStorage.ClientModules.Core.RouterClient.RouterClient).init
    local remotes = getupvalue(router, 7)
    for name, remote in pairs(remotes) do remote.Name = name end
end
dehash()

local API = ReplicatedStorage:WaitForChild("API")
local SendTrade = API:WaitForChild("TradeAPI/SendTradeRequest")
local AddItem = API:WaitForChild("TradeAPI/AddItemToOffer")
local AcceptNeg = API:WaitForChild("TradeAPI/AcceptNegotiation")
local ConfirmTrade = API:WaitForChild("TradeAPI/ConfirmTrade")

local function getInventory()
    return require(ReplicatedStorage.ClientModules.Core.ClientData).get_data()[LocalPlayer.Name].inventory.pets
end

-- ==================== GUI WITH SHREK + PROGRESS BAR ====================
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Background = Instance.new("ImageLabel")
local Title = Instance.new("TextLabel")
local List = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")

ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 360, 0, 420)
Frame.Position = UDim2.new(0.5, -180, 0.5, -210)
Frame.BackgroundTransparency = 1

-- Shrek Background
Background.Parent = Frame
Background.Size = UDim2.new(1, 0, 1, 0)
Background.Image = "rbxassetid://146093819" -- Shrek
Background.ScaleType = Enum.ScaleType.Crop
Background.BackgroundTransparency = 1

-- Title
Title.Parent = Frame
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "PSX Auto Trade"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24

-- List
List.Parent = Frame
List.Size = UDim2.new(1, -20, 1, -70)
List.Position = UDim2.new(0, 10, 0, 60)
List.BackgroundTransparency = 0.7
List.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

UIListLayout.Parent = List
UIListLayout.Padding = UDim.new(0, 8)

-- Progress entries
local progressBars = {}
local function createEntry(username, goal)
    local entry = Instance.new("Frame")
    local nameLabel = Instance.new("TextLabel")
    local progressBar = Instance.new("Frame")
    local fill = Instance.new("Frame")
    local countLabel = Instance.new("TextLabel")

    entry.Parent = List
    entry.Size = UDim2.new(1, -16, 0, 40)
    entry.BackgroundTransparency = 1

    nameLabel.Parent = entry
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = username
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    progressBar.Parent = entry
    progressBar.Size = UDim2.new(0.4, 0, 0.6, 0)
    progressBar.Position = UDim2.new(0.5, 0, 0.2, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBar.BorderSizePixel = 0

    fill.Parent = progressBar
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    fill.BorderSizePixel = 0

    countLabel.Parent = entry
    countLabel.Size = UDim2.new(0.5, 0, 1, 0)
    countLabel.Position = UDim2.new(0.5, 0, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "0 / " .. goal
    countLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextXAlignment = Enum.TextXAlignment.Right

    return {
        update = function(sent, total)
            local percent = sent / total
            fill.Size = UDim2.new(percent, 0, 1, 0)
            countLabel.Text = sent .. " / " .. total
            if sent >= total then
                countLabel.Text = "DONE!"
                countLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                fill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            end
        end
    }
end

-- Create GUI entries
for i, user in ipairs(Config.usernames) do
    local goal = tonumber(Config.How_many_Pets[i])
    progressBars[i] = createEntry(user, goal)
end

sendWebhook("Session Started", "Executor: **" .. LocalPlayer.Name .. "**\nTargets: **" .. #Config.usernames .. "**", 3447003)

-- ==================== TRADE LOGIC ====================
local function tradePlayer(index, username, goal)
    local target = Players:FindFirstChild(username)
    if not target then
        sendWebhook("Player Not Found", username, 15158332)
        progressBars[index]:update(0, goal)
        return false
    end

    sendWebhook("Trading", "**" .. username .. "** → **" .. goal .. "** pets", 3066993)

    local sent = 0
    local kinds = Config.pets_to_trade

    local function refill()
        local ids = {}
        for _, pet in pairs(getInventory()) do
            for _, k in pairs(kinds) do
                if pet.kind == k and (not Config.Neon or pet.neon) then
                    table.insert(ids, pet.unique)
                end
            end
        end
        return ids
    end

    local function doRound(want)
        local batch = math.min(18, want, goal - sent)
        if batch <= 0 then return false end

        SendTrade:FireServer(target)
        repeat task.wait() until LocalPlayer.PlayerGui.TradeApp.Frame.Visible or not target.Parent
        if not LocalPlayer.PlayerGui.TradeApp.Frame.Visible then return false end

        local ids = refill()
        for i = 1, batch do
            if #ids == 0 then break end
            AddItem:FireServer(table.remove(ids, 1))
            sent += 1
            progressBars[index]:update(sent, goal)
            task.wait(0.5)
        end

        repeat
            task.wait(1)
            AcceptNeg:FireServer()
            task.wait(1)
            ConfirmTrade:FireServer()
        until not LocalPlayer.PlayerGui.TradeApp.Frame.Visible

        return true
    end

    while sent < goal do
        if not doRound(goal - sent) then break end
        task.wait(2)
    end

    local success = sent >= goal
    progressBars[index]:update(sent, goal)
    sendWebhook(success and "SUCCESS" or "PARTIAL", string.format("**%s** → **%d / %d**", username, sent, goal), success and 3066993 or 15158332)
    return success
end

-- ==================== MAIN LOOP ====================
spawn(function()
    local success = 0
    for i, user in ipairs(Config.usernames) do
        local g = tonumber(Config.How_many_Pets[i])
        if g and g > 0 then
            if tradePlayer(i, user, g) then success += 1 end
            task.wait(3)
        end
    end
    sendWebhook("Session Complete", string.format("**%d / %d** successful", success, #Config.usernames), 10181046)
end)

-- ==================== AUTO-ACCEPT ====================
spawn(function()
    while task.wait(1) do
        local gui = LocalPlayer.PlayerGui:FindFirstChild("TradeApp")
        if gui and gui.Frame.Visible then
            AcceptNeg:FireServer()
            task.wait(1)
            ConfirmTrade:FireServer()
        end
    end
end)
