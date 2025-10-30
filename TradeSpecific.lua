--// ADOPT ME AUTO-TRADE – FIXED LOOP + PET ADD + WEBHOOK TEST
--// DevEx32/Auto-Trade | TradeSpecific.lua

if not getgenv().Config then error("Set getgenv().Config first!") end
local C = getgenv().Config
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- ===== CONFIG VALIDATION =====
if #C.usernames ~= #C.How_many_Pets then
    error("usernames and How_many_Pets must match in length!")
end

-- ===== DE-HASH REMOTES =====
local function dehash()
    local rename = function(n,r) r.Name = n end
    table.foreach(getupvalue(require(RS.ClientModules.Core.RouterClient.RouterClient).init,7),rename)
end
dehash()

local API = RS:WaitForChild("API", 10)
local SendReq   = API:WaitForChild("TradeAPI/SendTradeRequest")
local AddItem   = API:WaitForChild("TradeAPI/AddItemToOffer")
local AcceptNeg = API:WaitForChild("TradeAPI/AcceptNegotiation")
local Confirm   = API:WaitForChild("TradeAPI/ConfirmTrade")

-- ===== WEBHOOK WITH TEST + FALLBACK =====
local function webhook(title, desc, color)
    print("[WEBHOOK] " .. title .. ": " .. desc) -- Console fallback
    if not C.Webhook or C.Webhook == "" then return end
    spawn(function()
        local payload = Http:JSONEncode({
            embeds = {{
                title = title,
                description = desc,
                color = color or 65280,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = {text = "Adopt Me Auto Trade • " .. LP.Name}
            }}
        })
        pcall(function()
            -- Try PostAsync first, then request
            Http:PostAsync(C.Webhook, payload, Enum.HttpContentType.ApplicationJson)
        end)
        pcall(function()
            (syn and syn.request or request or http_request or HttpPost)({
                Url = C.Webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = payload
            })
        end)
    end)
end

-- Test webhook at start
webhook("SCRIPT LOADED", "Starting auto-trade session. Check console if no webhook.", 3447003)

-- ===== INVENTORY =====
local function getInv()
    return require(RS.ClientModules.Core.ClientData).get_data()[LP.Name].inventory.pets
end

local function collectIds()
    local ids = {}
    for _, p in pairs(getInv()) do
        for _, k in pairs(C.pets_to_trade) do
            if p.kind == k and (not C.Neon or p.neon) then
                table.insert(ids, p.unique)
                break
            end
        end
    end
    print("[DEBUG] Collected " .. #ids .. " pet IDs")
    webhook("INVENTORY REFRESH", "Found **" .. #ids .. "** pets for trade", 3447003)
    return ids
end

-- ===== SAFE + ERROR =====
local function safe(f, msg)
    local ok, err = pcall(f)
    if not ok then
        local e = msg .. "\n```lua\n" .. tostring(err) .. "\n```"
        print("[ERROR] " .. e)
        webhook("ERROR", e, 15158332)
        return false
    end
    return true
end

-- ===== WAIT FOR WINDOW =====
local function waitOpen()
    print("[DEBUG] Waiting for trade window to open...")
    for i = 1, 80 do
        task.wait(0.1)
        local app = LP.PlayerGui:FindFirstChild("TradeApp")
        if app and app.Frame and app.Frame.Visible then
            print("[DEBUG] Trade window opened")
            return true
        end
    end
    print("[DEBUG] Trade window timed out")
    webhook("WAIT FAILED", "Trade window did not open", 15158332)
    return false
end

local function waitClose()
    print("[DEBUG] Waiting for trade window to close...")
    for i = 1, 120 do
        task.wait(0.1)
        local app = LP.PlayerGui:FindFirstChild("TradeApp")
        if not app or not app.Frame or not app.Frame.Visible then
            print("[DEBUG] Trade window closed")
            return true
        end
    end
    print("[DEBUG] Trade window close timed out")
    webhook("WAIT FAILED", "Trade window did not close", 15158332)
    return false
end

-- ===== TRADE ONE PLAYER =====
local function tradePlayer(username, goal)
    local target = Players:FindFirstChild(username)
    if not target then
        webhook("PLAYER NOT FOUND", "Target: **" .. username .. "**", 15158332)
        return false
    end

    local totalSent = 0
    webhook("TARGET STARTED", "Trading **" .. username .. "**\nGoal: **" .. goal .. "** pets", 3447003)

    while totalSent < goal do
        print("[DEBUG] Starting new round for " .. username .. " (need " .. (goal - totalSent) .. ")")
        local need = math.min(18, goal - totalSent)
        local ids = collectIds()
        if #ids == 0 then
            webhook("NO PETS LEFT", "Out of **" .. table.concat(C.pets_to_trade, ", ") .. "** for **" .. username .. "**", 15158332)
            break
        end

        -- SEND TRADE
        if not safe(function() SendReq:FireServer(target) end, "SendTradeRequest failed") then break end
        if not waitOpen() then break end

        -- ADD PETS
        local roundSent = 0
        for i = 1, need do
            if #ids == 0 then
                webhook("ROUND PARTIAL", "Ran out mid-round for **" .. username .. "**", 15158332)
                break
            end
            local uid = table.remove(ids, 1)
            local petName = getPetName(uid)

            local added = false
            for attempt = 1, 3 do
                if safe(function() AddItem:FireServer(uid) end, "AddItem failed (attempt "..attempt..")") then
                    added = true
                    break
                end
                task.wait(1) -- longer retry delay
            end

            if added then
                roundSent += 1
                totalSent += 1
                print("[DEBUG] Added pet " .. roundSent .. "/" .. need .. " (total " .. totalSent .. "/" .. goal .. ")")
                webhook("PET ADDED", string.format("**%s** → **%s** (`%s`)\nRound: **%d/%d** | Total: **%d/%d**", username, petName, uid, roundSent, need, totalSent, goal), 3066993)
            else
                webhook("ADD FAILED", "Could not add pet: **" .. petName .. "** (`" .. uid .. "`)", 15158332)
            end

            task.wait(0.8) -- stable add delay
        end

        -- ROUND SUMMARY
        webhook("ROUND COMPLETE", string.format("**%s** → **%d/%d** pets sent\n**Total Progress: %d/%d**", username, roundSent, need, totalSent, goal), 10181046)

        -- ACCEPT + CONFIRM
        safe(function() AcceptNeg:FireServer() end, "AcceptNegotiation failed")
        task.wait(1.5)
        safe(function() Confirm:FireServer() end, "ConfirmTrade failed")

        -- WAIT FOR CLOSE + REFRESH
        if not waitClose() then break end
        task.wait(10) -- CRITICAL: inventory update delay
    end

    local success = totalSent >= goal
    webhook(success and "TARGET SUCCESS" or "TARGET PARTIAL", string.format("**%s** → **%d/%d** pets delivered", username, totalSent, goal), success and 3066993 or 15158332)
    return success
end

-- ===== MAIN LOOP =====
spawn(function()
    local totalTargets = #C.usernames
    local successCount = 0

    webhook("SESSION STARTED", string.format("Executor: **%s**\nTargets: **%d**\nPets: **%s**", LP.Name, totalTargets, table.concat(C.pets_to_trade, ", ")), 3447003)

    for i, user in ipairs(C.usernames) do
        local goal = tonumber(C.How_many_Pets[i])
        if goal and goal > 0 then
            webhook("SWITCHING TARGET", "Moving to **" .. user .. "** → **" .. goal .. "** pets", 15844367)
            if tradePlayer(user, goal) then
                successCount += 1
            end
            task.wait(5) -- between players
        else
            webhook("INVALID GOAL", "**" .. user .. "** → `" .. tostring(C.How_many_Pets[i]) .. "`", 15158332)
        end
    end

    webhook("SESSION COMPLETE", string.format("**%d/%d** targets successful\n**All trades finished**", successCount, totalTargets), 3066993)
end)

-- ===== AUTO-ACCEPT =====
spawn(function()
    while task.wait(1) do
        local g = LP.PlayerGui:FindFirstChild("TradeApp")
        if g and g.Frame and g.Frame.Visible then
            pcall(AcceptNeg.FireServer, AcceptNeg)
            task.wait(1)
            pcall(Confirm.FireServer, Confirm)
        end
    end
end)
