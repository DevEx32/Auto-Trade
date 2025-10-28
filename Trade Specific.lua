--// AUTO TRADE MULTI – 1-CLICK + WEBHOOK
--// Repo: DevEx32/Auto-Trade
--// File: Trade Specific.lua

if not getgenv().Config then
    error("Set getgenv().Config before loading the script!")
end

local Config = getgenv().Config
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ==================== DISCORD WEBHOOK ====================
local function sendWebhook(title, description, color)
    if not Config.Webhook or Config.Webhook == "" then return end
    spawn(function()
        local payload = {
            embeds = {{
                title = title,
                description = description,
                color = color or 65280,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = { text = "PSX Auto Trade | " .. LocalPlayer.Name }
            }}
        }
        pcall(function()
            HttpService:PostAsync(Config.Webhook, HttpService:JSONEncode(payload))
        end)
    end)
end

-- ==================== DEHASH REMOTES ====================
local function dehash()
    local router = require(ReplicatedStorage.ClientModules.Core.RouterClient.RouterClient).init
    local remotes = getupvalue(router, 7)
    for name, remote in pairs(remotes) do
        remote.Name = name
    end
end
dehash()

-- ==================== REMOTE SHORTCUTS ====================
local API           = ReplicatedStorage:WaitForChild("API")
local SendTrade     = API:WaitForChild("TradeAPI/SendTradeRequest")
local AddItem       = API:WaitForChild("TradeAPI/AddItemToOffer")
local AcceptNeg     = API:WaitForChild("TradeAPI/AcceptNegotiation")
local ConfirmTrade  = API:WaitForChild("TradeAPI/ConfirmTrade")

local function getInventory()
    return require(ReplicatedStorage.ClientModules.Core.ClientData).get_data()[LocalPlayer.Name].inventory.pets
end

-- ==================== VALIDATE CONFIG ====================
if #Config.usernames ~= #Config["How_many_Pets"] then
    error("Config error: #usernames must equal #How_many_Pets")
end

sendWebhook(
    "Auto-Trade Session Started",
    string.format("**Executor:** %s\n**Targets:** %d\n**Pets:** %s", LocalPlayer.Name, #Config.usernames, table.concat(Config.pets_to_trade, ", ")),
    3447003
)

-- ==================== TRADE ONE PLAYER ====================
local function tradePlayer(username, goal)
    local target = Players:FindFirstChild(username)
    if not target then
        sendWebhook("Player Not Found", "**" .. username .. "**", 15158332)
        warn("[!] Player not found:", username)
        return false
    end

    sendWebhook("Trading Started", string.format("**%s** → **%d** pets", username, goal), 3066993)
    print("Trading", username, "– goal:", goal)

    local sent = 0
    local round = 0
    local kinds = Config.pets_to_trade

    local function refill()
        local ids = {}
        for _, pet in pairs(getInventory()) do
            for _, k in pairs(kinds) do
                if pet.kind == k then
                    table.insert(ids, pet.unique)
                end
            end
        end
        return ids
    end

    local function doRound(want)
        round += 1
        local batch = math.min(18, want, goal - sent)
        if batch <= 0 then return false end

        print(string.format("   Round %d → %d pets", round, batch))
        sendWebhook("Round " .. round, "Sending **" .. batch .. "** pets", 15844367)

        SendTrade:FireServer(target)
        repeat task.wait() until LocalPlayer.PlayerGui.TradeApp.Frame.Visible or not target.Parent
        if not LocalPlayer.PlayerGui.TradeApp.Frame.Visible then
            sendWebhook("Trade Failed", "Window didn't open.", 15158332)
            return false
        end

        local ids = refill()
        for i = 1, batch do
            if #ids == 0 then break end
            AddItem:FireServer(table.remove(ids, 1))
            sent += 1
            task.wait(0.5)
        end

        repeat
            task.wait(1)
            AcceptNeg:FireServer()
            task.wait(1)
            ConfirmTrade:FireServer()
        until not LocalPlayer.PlayerGui.TradeApp.Frame.Visible

        sendWebhook("Round " .. round .. " Done", string.format("**%d / %d** total", sent, goal), 3066993)
        return true
    end

    while sent < goal do
        if not doRound(goal - sent) then break end
        task.wait(2)
    end

    local success = sent >= goal
    sendWebhook(success and "SUCCESS" or "PARTIAL", 
        string.format("**%s** → **%d / %d** pets", username, sent, goal), 
        success and 3066993 or 15158332)
    print(username, success and "SUCCESS" or "PARTIAL", sent .. "/" .. goal)
    return success
end

-- ==================== MAIN LOOP ====================
spawn(function()
    local successCount = 0
    for i, user in ipairs(Config.usernames) do
        local g = tonumber(Config["How_many_Pets"][i])
        if g and g > 0 then
            if tradePlayer(user, g) then successCount += 1 end
            task.wait(3)
        else
            sendWebhook("Invalid Goal", user .. " → " .. tostring(Config["How_many_Pets"][i]), 15158332)
        end
    end
    sendWebhook("Session Complete", 
        string.format("**%d / %d** players successful", successCount, #Config.usernames), 
        10181046)
    print("ALL TRADES DONE")
end)

-- ==================== AUTO-ACCEPT BACKGROUND ====================
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