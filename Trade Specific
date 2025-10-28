--// AUTO TRADE MULTI – 1-CLICK + WEBHOOK
--// GitHub: https://github.com/diwserenityhub/other
--// File: auto_trade_multi.lua

if not getgenv().Config then
    error("Config missing! Set getgenv().Config before loading.")
end

local Config = getgenv().Config
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Webhook sender
local function sendWebhook(title, description, color)
    if not Config.Webhook or Config.Webhook == "" then return end
    spawn(function()
        local data = {
            embeds = {{
                title = title,
                description = description,
                color = color or 0x00ff00,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = { text = "PSX Auto Trade | " .. LocalPlayer.Name }
            }}
        }
        pcall(function()
            HttpService:PostAsync(Config.Webhook, HttpService:JSONEncode(data))
        end)
    end)
end

-- Dehash remotes
local function dehash()
    local router = require(ReplicatedStorage.ClientModules.Core.RouterClient.RouterClient).init
    local remotes = getupvalue(router, 7)
    for name, remote in pairs(remotes) do remote.Name = name end
end
dehash()

-- Remote shortcuts
local API           = ReplicatedStorage:WaitForChild("API")
local SendTrade     = API:WaitForChild("TradeAPI/SendTradeRequest")
local AddItem       = API:WaitForChild("TradeAPI/AddItemToOffer")
local AcceptNeg     = API:WaitForChild("TradeAPI/AcceptNegotiation")
local ConfirmTrade  = API:WaitForChild("TradeAPI/ConfirmTrade")

local function getInventory()
    return require(ReplicatedStorage.ClientModules.Core.ClientData).get_data()[LocalPlayer.Name].inventory.pets
end

-- Validate
if #Config.usernames ~= #Config["How_many_Pets"] then
    error("Config error: usernames & How_many_Pets must have same length!")
end

sendWebhook("Auto Trade Started", 
    string.format("**Executor:** %s\n**Targets:** %d\n**Pets:** %s", 
        LocalPlayer.Name, #Config.usernames, table.concat(Config.pets_to_trade, ", ")), 
    0x3498db)

-- Trade one player
local function tradePlayer(username, totalGoal)
    local target = Players:FindFirstChild(username)
    if not target then
        sendWebhook("Player Not Found", "**" .. username .. "**", 0xe74c3c)
        warn("Player not found:", username)
        return false
    end

    sendWebhook("Trading Started", "**" .. username .. "** – Goal: **" .. totalGoal .. "** pets", 0x2ecc71)
    print("Trading", username, "–", totalGoal, "pets")

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
        local send = math.min(18, want, totalGoal - sent)
        if send <= 0 then return false end

        print("   Round", round, "→", send, "pets")
        sendWebhook("Round " .. round, "Sending **" .. send .. "** pets", 0xf1c40f)

        SendTrade:FireServer(target)
        repeat task.wait() until LocalPlayer.PlayerGui.TradeApp.Frame.Visible or not target.Parent
        if not LocalPlayer.PlayerGui.TradeApp.Frame.Visible then return false end

        local ids = refill()
        for i = 1, send do
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

        sendWebhook("Round " .. round .. " Done", "**" .. sent .. " / " .. totalGoal .. "**", 0x2ecc71)
        return true
    end

    while sent < totalGoal do
        if not doRound(totalGoal - sent) then break end
        task.wait(2)
    end

    local ok = sent >= totalGoal
    sendWebhook(ok and "SUCCESS" or "PARTIAL", 
        string.format("**%s** → %d / %d pets", username, sent, totalGoal), 
        ok and 0x2ecc71 or 0xe67e22)
    return ok
end

-- Main loop
spawn(function()
    local success = 0
    for i, user in ipairs(Config.usernames) do
        local goal = tonumber(Config["How_many_Pets"][i])
        if goal and goal > 0 then
            if tradePlayer(user, goal) then success += 1 end
            task.wait(3)
        end
    end
    sendWebhook("Session Complete", 
        string.format("**%d / %d** successful", success, #Config.usernames), 
        0x9b59b6)
    print("ALL DONE")
end)

-- Auto-accept
spawn(function()
    while task.wait(1) do
        if LocalPlayer.PlayerGui:FindFirstChild("TradeApp") and LocalPlayer.PlayerGui.TradeApp.Frame.Visible then
            AcceptNeg:FireServer()
            task.wait(1)
            ConfirmTrade:FireServer()
        end
    end
end)
