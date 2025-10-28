--// ADOPT ME AUTO-TRADE – UI ONLY MOVES ON ADD + TRADE DETECTION
--// DevEx32/Auto-Trade | TradeSpecific.lua

if not getgenv().Config then error("Set getgenv().Config!") end
local C = getgenv().Config
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

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

-- ===== HACKER UI (Round: 0/18, Total: X/30) =====
local SG = Instance.new("ScreenGui", CoreGui); SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG)
Main.Size = UDim2.new(0, 320, 0, 160)
Main.Position = UDim2.new(0.5, -160, 0.5, -80)
Main.BackgroundTransparency = 0.2
Main.BackgroundColor3 = Color3.fromRGB(10,10,10)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

local Grad = Instance.new("UIGradient", Main)
Grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,255,0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,100,255))
}
Grad.Rotation = 45

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,36); Title.BackgroundTransparency = 1
Title.Text = "AUTO TRADE"
Title.TextColor3 = Color3.fromRGB(0,255,0)
Title.Font = Enum.Font.Code; Title.TextSize = 20

local Target = Instance.new("TextLabel", Main)
Target.Position = UDim2.new(0,12,0,40); Target.Size = UDim2.new(1,-24,0,24)
Target.BackgroundTransparency = 1; Target.TextXAlignment = Enum.TextXAlignment.Left
Target.TextColor3 = Color3.fromRGB(200,255,200); Target.Font = Enum.Font.Code
Target.Text = "Target: "..C.usernames[1]

local RoundBar = Instance.new("Frame", Main)
RoundBar.Position = UDim2.new(0,12,0,70); RoundBar.Size = UDim2.new(1,-24,0,20)
RoundBar.BackgroundColor3 = Color3.fromRGB(30,30,30); RoundBar.BorderSizePixel = 0
Instance.new("UICorner", RoundBar).CornerRadius = UDim.new(0,8)

local RoundFill = Instance.new("Frame", RoundBar)
RoundFill.Size = UDim2.new(0,0,1,0); RoundFill.BackgroundColor3 = Color3.fromRGB(0,255,0)
RoundFill.BorderSizePixel = 0
Instance.new("UICorner", RoundFill).CornerRadius = UDim.new(0,8)

local RoundCount = Instance.new("TextLabel", Main)
RoundCount.Position = UDim2.new(0,12,0,96); RoundCount.Size = UDim2.new(1,-24,0,24)
RoundCount.BackgroundTransparency = 1; RoundCount.TextColor3 = Color3.fromRGB(255,255,255)
RoundCount.Font = Enum.Font.Code; RoundCount.TextSize = 16
RoundCount.Text = "0 / 18"

local TotalCount = Instance.new("TextLabel", Main)
TotalCount.Position = UDim2.new(0,12,0,122); TotalCount.Size = UDim2.new(1,-24,0,24)
TotalCount.BackgroundTransparency = 1; TotalCount.TextColor3 = Color3.fromRGB(150,255,150)
TotalCount.Font = Enum.Font.Code; TotalCount.TextSize = 14
TotalCount.Text = "Total: 0 / "..C.How_many_Pets[1]

local function updateRound(sent)
    local pct = sent/18
    RoundFill:TweenSize(UDim2.new(pct,0,1,0),"Out","Quad",0.2,true)
    RoundCount.Text = sent.." / 18"
end

local function updateTotal(sent, total)
    TotalCount.Text = "Total: "..sent.." / "..total
    if sent >= total then
        TotalCount.Text = "DONE!"
        TotalCount.TextColor3 = Color3.fromRGB(0,255,0)
    end
end

local function resetRound()
    updateRound(0)
end

-- ===== TRADE DETECTION + UI ONLY ON ADD =====
local function waitForTradeOpen()
    for _ = 1, 60 do
        task.wait(0.1)
        local app = LP.PlayerGui:FindFirstChild("TradeApp")
        if app and app.Frame.Visible then return true end
    end
    return false
end

local function waitForTradeClose()
    for _ = 1, 100 do
        task.wait(0.1)
        local app = LP.PlayerGui:FindFirstChild("TradeApp")
        if not app or not app.Frame.Visible then return true end
    end
    return false
end

local function safe(f,msg)
    local ok,err = pcall(f)
    if not ok then
        local e = msg.."\n```lua\n"..tostring(err).."\n```"
        warn(e); webhook("ERROR",e,15158332)
        return false
    end
    return true
end

local function trade()
    local target = Players:FindFirstChild(C.usernames[1])
    if not target then webhook("Not Found",C.usernames[1],15158332); return end

    local goal = tonumber(C.How_many_Pets[1])
    local totalSent = 0

    webhook("Started","**"..C.usernames[1].."** → **"..goal.."** pets",3066993)

    while totalSent < goal do
        local need = math.min(18, goal - totalSent)
        local ids = collectIds()
        if #ids == 0 then webhook("No Pets","Out of pets",15158332); break end

        resetRound()
        updateTotal(totalSent, goal)

        -- SEND REQUEST
        safe(function() SendReq:FireServer(target) end,"SendTradeRequest")
        if not waitForTradeOpen() then
            webhook("Failed","Trade window never opened",15158332)
            break
        end

        -- ADD PETS (UI ONLY MOVES HERE)
        local roundSent = 0
        for i = 1, need do
            if #ids == 0 then break end
            local uid = table.remove(ids, 1)
            safe(function() AddItem:FireServer(uid) end,"AddItem")
            roundSent = roundSent + 1
            totalSent = totalSent + 1
            updateRound(roundSent)           -- ONLY HERE
            updateTotal(totalSent, goal)     -- Update total
            task.wait(0.5)
        end

        -- ACCEPT + CONFIRM (NO UI CHANGE)
        safe(function() AcceptNeg:FireServer() end,"Accept")
        task.wait(1)
        safe(function() Confirm:FireServer() end,"Confirm")

        -- WAIT FOR TRADE TO CLOSE (DETECTED)
        if not waitForTradeClose() then
            webhook("Failed","Trade window stuck",15158332)
            break
        end

        task.wait(2)  -- cooldown
    end

    local ok = totalSent >= goal
    updateTotal(totalSent, goal)
    webhook(ok and "SUCCESS" or "PARTIAL",
        string.format("**%s** → **%d/%d**",C.usernames[1],totalSent,goal),
        ok and 3066993 or 15158332)
end

-- ===== START =====
spawn(function()
    if #C.usernames~=1 or #C.How_many_Pets~=1 then webhook("CONFIG","1 target only",15158332); return end
    webhook("Session","Starting...",3447003)
    trade()
end)

-- Auto-accept (backup)
spawn(function()
    while task.wait(1) do
        local g = LP.PlayerGui:FindFirstChild("TradeApp")
        if g and g.Frame.Visible then
            pcall(AcceptNeg.FireServer,AcceptNeg)
            task.wait(1)
            pcall(Confirm.FireServer,Confirm)
        end
    end
end)
