--[[ 
    TradeSpecific.lua
    Made for Adopt Me auto trading with specific pet amounts per target.

    ⚙️ Requires:
    getgenv().Config = {
        ["usernames"]     = {"Target1","Target2","Target3"},
        ["pets_to_trade"] = {"aztec_egg_2025_ehecatl"},
        ["How_many_Pets"] = {"24","40","60"},
        ["Neon"]          = false,
        ["Webhook"]       = "https://discord.com/api/webhooks/your_webhook_here"
    }

    loadstring(game:HttpGet("https://raw.githubusercontent.com/<YourUser>/<YourRepo>/main/TradeSpecific.lua"))()
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerName = player and player.Name or "Player"
local API = ReplicatedStorage:WaitForChild("API")
local TradeSend = API:WaitForChild("TradeAPI/SendTradeRequest")
local AddItem = API:WaitForChild("TradeAPI/AddItemToOffer")
local Accept = API:WaitForChild("TradeAPI/AcceptNegotiation")
local Confirm = API:WaitForChild("TradeAPI/ConfirmTrade")
local Data = require(ReplicatedStorage.ClientModules.Core.ClientData)
local RouterClient = require(ReplicatedStorage.ClientModules.Core.RouterClient.RouterClient)

-- 🔓 Dehash remotes (from original source)
local function dehash()
    local function rename(remotename, hashedremote)
        hashedremote.Name = remotename
    end
    local ok, uv = pcall(function()
        return getupvalue(RouterClient.init, 7)
    end)
    if ok and uv then
        pcall(function()
            for _, v in pairs(uv) do rename(_, v) end
        end)
    end
end
pcall(dehash)

-- ⚙️ Config
local cfg = getgenv().Config or {}
local usernames = cfg.usernames or {}
local pets_to_trade = cfg.pets_to_trade or {}
local how_many_raw = cfg.How_many_Pets or {}
local WEBHOOK_URL = cfg.Webhook or nil
local MAX_PER_TRADE = 18

-- 📦 Convert string numbers to real numbers
local how_many = {}
for i = 1, #usernames do
    local n = tonumber(how_many_raw[i] or how_many_raw[1]) or 0
    how_many[i] = n
end

-- 🌐 Universal webhook function (works on any executor)
local function send_webhook(content)
    if not WEBHOOK_URL or WEBHOOK_URL == "" then return end
    local payload = {
        embeds = {{
            title = "Auto Trade Logs",
            description = tostring(content),
            color = 3447003,
            footer = { text = "TradeSpecific.lua" }
        }}
    }
    local json = HttpService:JSONEncode(payload)
    local headers = {["Content-Type"] = "application/json"}

    local methods = {
        function() if syn and syn.request then return syn.request({Url=WEBHOOK_URL, Method="POST", Headers=headers, Body=json}) end end,
        function() if http_request then return http_request({Url=WEBHOOK_URL, Method="POST", Headers=headers, Body=json}) end end,
        function() if request then return request({Url=WEBHOOK_URL, Method="POST", Headers=headers, Body=json}) end end,
        function() pcall(function() HttpService:PostAsync(WEBHOOK_URL, json, Enum.HttpContentType.ApplicationJson) end) end
    }

    for _, m in ipairs(methods) do
        local ok = pcall(m)
        if ok then break end
    end
end

local function log(msg)
    print("[TradeSpecific] " .. tostring(msg))
    send_webhook(msg)
end

-- 🐾 Collect all pet uniques
local function get_all_matching_pets()
    local pets = {}
    local ok, inv = pcall(function()
        return Data.get_data()[playerName].inventory.pets
    end)
    if not ok or not inv then return pets end
    for _, pet in pairs(inv) do
        for _, kind in ipairs(pets_to_trade) do
            if pet.kind == kind then
                table.insert(pets, pet.unique)
            end
        end
    end
    return pets
end

-- 📨 Send trade
local function send_trade(target)
    local p = Players:FindFirstChild(target)
    if not p then log("❌ Target not found: " .. tostring(target)) return false end
    pcall(function() TradeSend:FireServer(p) end)
    log("📤 Trade request sent to " .. target)
    return true
end

-- 💰 Add items to trade
local function add_items(uniques)
    for _, u in ipairs(uniques) do
        pcall(function() AddItem:FireServer(u) end)
        task.wait(0.2)
    end
end

-- ✅ Accept & confirm
local function accept_confirm()
    pcall(function() Accept:FireServer() end)
    task.wait(1)
    pcall(function() Confirm:FireServer() end)
end

-- 👀 Wait for trade UI
local function wait_for_trade_ui(timeout)
    local t = 0
    timeout = timeout or 10
    while t < timeout do
        if player.PlayerGui:FindFirstChild("TradeApp") and player.PlayerGui.TradeApp.Frame.Visible then
            return true
        end
        task.wait(0.3)
        t += 0.3
    end
    return false
end

-- 🚀 Main process
local function trade_all_targets()
    local available = get_all_matching_pets()
    log("🔍 Found " .. #available .. " matching pets.")

    for i, target in ipairs(usernames) do
        local needed = how_many[i] or 0
        if needed <= 0 then log("Skipping " .. target) continue end

        log(("➡️ Moving Target %d: %s (Need %d pets)"):format(i, target, needed))

        while needed > 0 do
            if #available <= 0 then
                available = get_all_matching_pets()
                if #available <= 0 then log("No more pets available!") return end
            end

            local trade_count = math.min(needed, MAX_PER_TRADE, #available)
            local batch = {}
            for j = 1, trade_count do
                table.insert(batch, table.remove(available, 1))
            end

            send_trade(target)
            if not wait_for_trade_ui(8) then
                log("⚠️ Trade UI not open for " .. target)
                for _, u in ipairs(batch) do table.insert(available, u) end
                task.wait(2)
                continue
            end

            add_items(batch)
            log(("🧩 Added %d pets to trade with %s"):format(#batch, target))
            accept_confirm()

            task.wait(6)
            needed -= #batch
            log(("✅ Batch done for %s (%d left)"):format(target, needed))
        end

        log("🎯 Done trading " .. target)
        task.wait(1)
    end

    log("🏁 All targets completed.")
end

pcall(trade_all_targets)
