--// ADOPT ME AUTO-TRADE – MULTI-TARGET + WEBHOOK (NO UI)
--// DevEx32/Auto-Trade | TradeSpecific.lua

if not getgenv().Config then error("Set getgenv().Config first!") end
local C = getgenv().Config
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- ===== VALIDATE CONFIG =====
if #C.usernames ~= #C.How_many_Pets then
    error("usernames and How_many_Pets must have same length!")
end

-- ===== DE-HASH REMOTES =====
local function dehash()
    local rename = function(n,r) r.Name = n end
    table.foreach(getupvalue(require(RS.ClientModules.Core.RouterClient.RouterClient).init,7),rename)
end
dehash()

local API = RS:WaitForChild("API")
local SendReq   = API:WaitForChild("TradeAPI/SendTradeRequest")
local AddItem   = API:WaitForChild("TradeAPI/AddItemToOffer")
local AcceptNeg = API:WaitForChild("TradeAPI/AcceptNegotiation")
local Confirm   = API:WaitForChild("TradeAPI/ConfirmTrade")

-- ===== WEBHOOK =====
local function webhook(t,d,c)
    if not C.Webhook or C.Webhook == "" then return end
    spawn(function()
        local p = Http:JSONEncode({embeds={{title=t,description=d,color=c or 65280,
            timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ"),footer={text="Adopt Me | "..LP.Name}}}})
        pcall(function()
            (syn and syn.request or request or http_request or HttpPost)({
                Url=C.Webhook,Method="POST",
                Headers={["Content-Type"]="application/json"},Body=p
            })
        end)
    end)
end

-- ===== INVENTORY =====
local function getInv()
    return require(RS.ClientModules.Core.ClientData).get_data()[LP.Name].inventory.pets
end

local function collectIds()
    local ids = {}
    for _,p in pairs(getInv()) do
        for _,k in pairs(C.pets_to_trade) do
            if p.kind==k and (not C.Neon or p.neon) then
                table.insert(ids,p.unique); break
            end
        end
    end
    return ids
end

-- ===== SAFE PCALL + ERROR WEBHOOK =====
local function safe(f,msg)
    local ok,err = pcall(f)
    if not ok then
        local e = msg.."\n```lua\n"..tostring(err).."\n```"
        warn(e); webhook("ERROR",e,15158332)
        return false
    end
    return true
end

-- ===== WAIT FOR TRADE WINDOW =====
local function waitOpen()
    for _ = 1, 60 do
        task.wait(0.1)
        local app = LP.PlayerGui:FindFirstChild("TradeApp")
        if app and app.Frame.Visible then return true end
    end
    return false
end

local function waitClose()
    for _ = 1, 100 do
        task.wait(0.1)
        local app = LP.PlayerGui:FindFirstChild("TradeApp")
        if not app or not app.Frame.Visible then return true end
    end
    return false
end

-- ===== TRADE ONE PLAYER =====
local function tradePlayer(username, goal)
    local target = Players:FindFirstChild(username)
    if not target then
        webhook("Not Found", "**"..username.."**", 15158332)
        return false
    end

    local totalSent = 0
    webhook("Trading", "**"..username.."** → **"..goal.."** pets", 3066993)

    while totalSent < goal do
        local need = math.min(18, goal - totalSent)
        local ids = collectIds()
        if #ids == 0 then
            webhook("No Pets", "Out of pets for **"..username.."**", 15158332)
            break
        end

        -- Send request
        safe(function() SendReq:FireServer(target) end, "SendTradeRequest failed")
        if not waitOpen() then
            webhook("Trade Failed", "Window not opened for **"..username.."**", 15158332)
            break
        end

        -- Add pets
        local roundSent = 0
        for i = 1, need do
            if #ids == 0 then break end
            local uid = table.remove(ids, 1)
            safe(function() AddItem:FireServer(uid) end, "AddItem failed")
            roundSent += 1
            totalSent += 1
            task.wait(0.5)
        end

        webhook("Round", string.format("**%s**: **%d/18** → Total: **%d/%d**", username, roundSent, totalSent, goal), 15844367)

        -- Accept + Confirm
        safe(function() AcceptNeg:FireServer() end, "AcceptNegotiation failed")
        task.wait(1)
        safe(function() Confirm:FireServer() end, "ConfirmTrade failed")

        -- Wait for close
        if not waitClose() then
            webhook("Trade Stuck", "Window did not close for **"..username.."**", 15158332)
            break
        end

        task.wait(2)
    end

    local success = totalSent >= goal
    webhook(success and "SUCCESS" or "PARTIAL",
        string.format("**%s** → **%d/%d** pets", username, totalSent, goal),
        success and 3066993 or 15158332)
    return success
end

-- ===== MAIN LOOP =====
spawn(function()
    webhook("Session Started", "Executor: **"..LP.Name.."**\nTargets: **"..#C.usernames.."**", 3447003)

    local successCount = 0
    for i, user in ipairs(C.usernames) do
        local goal = tonumber(C.How_many_Pets[i])
        if goal and goal > 0 then
            if tradePlayer(user, goal) then successCount += 1 end
            task.wait(3) -- cooldown between players
        else
            webhook("Invalid Goal", "**"..user.."** → "..tostring(C.How_many_Pets[i]), 15158332)
        end
    end

    webhook("Session Complete", string.format("**%d/%d** players successful", successCount, #C.usernames), 10181046)
end)

-- ===== AUTO-ACCEPT (backup) =====
spawn(function()
    while task.wait(1) do
        local g = LP.PlayerGui:FindFirstChild("TradeApp")
        if g and g.Frame.Visible then
            pcall(AcceptNeg.FireServer, AcceptNeg)
            task.wait(1)
            pcall(Confirm.FireServer, Confirm)
        end
    end
end)
