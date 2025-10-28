--// ADOPT ME AUTO-TRADE – DEHASH + GUI + WEBHOOK
--// DevEx32/Auto-Trade | TradeSpecific.lua

if not getgenv().Config then
    error("Set getgenv().Config before loading!")
end

local Config = getgenv().Config
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------
-- 1. DE-HASH REMOTES (your exact code)
--------------------------------------------------------------------
local function dehash()
    local function rename(name, remote) remote.Name = name end
    table.foreach(
        getupvalue(require(ReplicatedStorage.ClientModules.Core.RouterClient.RouterClient).init, 7),
        rename
    )
end
dehash()

local API = ReplicatedStorage:WaitForChild("API")
local SendTradeRequest   = API:WaitForChild("TradeAPI/SendTradeRequest")
local AddItemToOffer     = API:WaitForChild("TradeAPI/AddItemToOffer")
local AcceptNegotiation  = API:WaitForChild("TradeAPI/AcceptNegotiation")
local ConfirmTrade       = API:WaitForChild("TradeAPI/ConfirmTrade")

--------------------------------------------------------------------
-- 2. SAFE WEBHOOK (all executors)
--------------------------------------------------------------------
local function sendWebhook(title, desc, color)
    if not Config.Webhook or Config.Webhook == "" then return end
    spawn(function()
        local payload = HttpService:JSONEncode({
            embeds = {{title = title, description = desc, color = color or 65280,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = {text = "Adopt Me Auto Trade | "..LocalPlayer.Name}}}
        })
        pcall(function()
            (syn and syn.request or request or http_request or HttpPost)({
                Url = Config.Webhook,
                Method = "POST",
                Headers = {["Content-Type"]="application/json"},
                Body = payload
            })
        end)
    end)
end

--------------------------------------------------------------------
-- 3. INVENTORY + PET IDS
--------------------------------------------------------------------
local function getInventory()
    return require(ReplicatedStorage.ClientModules.Core.ClientData).get_data()[LocalPlayer.Name].inventory.pets
end

local function collectPetIds()
    local ids = {}
    for _, pet in pairs(getInventory()) do
        for _, kind in pairs(Config.pets_to_trade) do
            if pet.kind == kind and (not Config.Neon or pet.neon) then
                table.insert(ids, pet.unique)
                break
            end
        end
    end
    return ids
end

--------------------------------------------------------------------
-- 4. SHREK GUI + PROGRESS BARS
--------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 380, 0, 480)
Frame.Position = UDim2.new(0.5, -190, 0.5, -240)
Frame.BackgroundTransparency = 1

local Shrek = Instance.new("ImageLabel", Frame)
Shrek.Size = UDim2.new(1,0,1,0)
Shrek.Image = "rbxassetid://146093819"
Shrek.ScaleType = Enum.ScaleType.Crop

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,50)
Title.BackgroundTransparency = 1
Title.Text = "Adopt Me Auto Trade"
Title.TextColor3 = Color3.fromRGB(0,255,0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24

local List = Instance.new("Frame", Frame)
List.Size = UDim2.new(1,-20,1,-70)
List.Position = UDim2.new(0,10,0,60)
List.BackgroundTransparency = 0.7
List.BackgroundColor3 = Color3.fromRGB(0,0,0)

local UIList = Instance.new("UIListLayout", List)
UIList.Padding = UDim.new(0,10)

local progressBars = {}
local function createEntry(user, goal)
    local entry = Instance.new("Frame")
    local nameLbl = Instance.new("TextLabel")
    local barBack = Instance.new("Frame")
    local barFill = Instance.new("Frame")
    local countLbl = Instance.new("TextLabel")

    entry.Parent = List
    entry.Size = UDim2.new(1,-16,0,45)
    entry.BackgroundTransparency = 1

    nameLbl.Parent = entry
    nameLbl.Size = UDim2.new(0.45,0,1,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = user
    nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
    nameLbl.Font = Enum.Font.Gotham

    barBack.Parent = entry
    barBack.Size = UDim2.new(0.35,0,0.5,0)
    barBack.Position = UDim2.new(0.48,0,0.25,0)
    barBack.BackgroundColor3 = Color3.fromRGB(50,50,50)

    barFill.Parent = barBack
    barFill.Size = UDim2.new(0,0,1,0)
    barFill.BackgroundColor3 = Color3.fromRGB(0,255,0)

    countLbl.Parent = entry
    countLbl.Size = UDim2.new(0.5,0,1,0)
    countLbl.Position = UDim2.new(0.5,0,0,0)
    countLbl.BackgroundTransparency = 1
    countLbl.Text = "0 / "..goal
    countLbl.TextColor3 = Color3.fromRGB(200,200,200)
    countLbl.Font = Enum.Font.Gotham
    countLbl.TextXAlignment = Enum.TextXAlignment.Right

    return {
        update = function(sent,total)
            local pct = total>0 and sent/total or 0
            barFill:TweenSize(UDim2.new(pct,0,1,0),"Out","Quad",0.2,true)
            countLbl.Text = sent.." / "..total
            if sent>=total then
                countLbl.Text = "DONE!"
                countLbl.TextColor3 = Color3.fromRGB(0,255,0)
            end
        end
    }
end

--------------------------------------------------------------------
-- 5. TRADE ONE PLAYER (full pcall + error webhook)
--------------------------------------------------------------------
local function safeCall(func, msg)
    local ok, err = pcall(func)
    if not ok then
        local txt = msg.."\n```lua\n"..tostring(err).."\n```"
        warn(txt)
        sendWebhook("ERROR", txt, 15158332)
        return false
    end
    return true
end

local function tradePlayer(idx, username, goal)
    local target = Players:FindFirstChild(username)
    if not target then
        sendWebhook("Not Found", username, 15158332)
        progressBars[idx]:update(0, goal)
        return false
    end

    sendWebhook("Trading", "**"..username.."** → **"..goal.."** pets", 3066993)

    local sent = 0
    local allIds = collectPetIds()

    while sent < goal do
        local need = math.min(18, goal - sent)
        if #allIds == 0 then allIds = collectPetIds() end
        if #allIds == 0 then
            sendWebhook("No Pets", "Ran out for **"..username.."**", 15158332)
            break
        end

        -- send request
        if not safeCall(function() SendTradeRequest:FireServer(target) end,
            "SendTradeRequest failed for **"..username.."**") then break end

        -- wait for window
        local opened = false
        for _ = 1,60 do
            task.wait(0.1)
            if LocalPlayer.PlayerGui:FindFirstChild("TradeApp") and LocalPlayer.PlayerGui.TradeApp.Frame.Visible then
                opened = true; break
            end
        end
        if not opened then
            sendWebhook("Trade Failed", "Window never opened for **"..username.."**", 15158332)
            break
        end

        -- add pets
        for i = 1,need do
            if #allIds == 0 then break end
            local uid = table.remove(allIds,1)
            if not safeCall(function() AddItemToOffer:FireServer(uid) end,
                "AddItemToOffer failed (uid: "..tostring(uid)..")") then break end
            sent = sent + 1
            progressBars[idx]:update(sent, goal)
            task.wait(0.5)
        end

        -- accept + confirm
        safeCall(function() AcceptNegotiation:FireServer() end, "AcceptNegotiation failed")
        task.wait(1)
        safeCall(function() ConfirmTrade:FireServer() end, "ConfirmTrade failed")
        task.wait(2)
    end

    local ok = sent >= goal
    progressBars[idx]:update(sent, goal)
    sendWebhook(ok and "SUCCESS" or "PARTIAL",
        string.format("**%s** → **%d/%d**", username, sent, goal),
        ok and 3066993 or 15158332)
    return ok
end

--------------------------------------------------------------------
-- 6. MAIN LOOP
--------------------------------------------------------------------
spawn(function()
    if #Config.usernames ~= #Config.How_many_Pets then
        sendWebhook("CONFIG ERROR", "usernames ≠ How_many_Pets", 15158332)
        return
    end

    sendWebhook("Session Started",
        "Executor: **"..LocalPlayer.Name.."**\nTargets: **"..#Config.usernames.."**", 3447003)

    for i, user in ipairs(Config.usernames) do
        local goal = tonumber(Config.How_many_Pets[i])
        if goal and goal > 0 then
            progressBars[i] = createEntry(user, goal)
            tradePlayer(i, user, goal)
            task.wait(3)
        end
    end

    sendWebhook("Session Complete",
        "All players processed.", 10181046)
end)

--------------------------------------------------------------------
-- 7. AUTO-ACCEPT (safety)
--------------------------------------------------------------------
spawn(function()
    while task.wait(1) do
        local gui = LocalPlayer.PlayerGui:FindFirstChild("TradeApp")
        if gui and gui.Frame.Visible then
            pcall(AcceptNegotiation.FireServer, AcceptNegotiation)
            task.wait(1)
            pcall(ConfirmTrade.FireServer, ConfirmTrade)
        end
    end
end)
