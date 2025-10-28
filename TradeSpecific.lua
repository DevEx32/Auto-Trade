--// ADOPT ME AUTO-TRADE – HACKER UI + FIXED BATCHING
--// DevEx32/Auto-Trade | TradeSpecific.lua

if not getgenv().Config then error("Set getgenv().Config first!") end
local C = getgenv().Config
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- ===== DE-HASH (your original) =====
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

-- ===== WEBHOOK (all executors) =====
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

-- ===== HACKER UI (compact + gradient) =====
local SG = Instance.new("ScreenGui", CoreGui); SG.ResetOnSpawn = false
local Main = Instance.new("Frame", SG)
Main.Size = UDim2.new(0, 320, 0, 140)
Main.Position = UDim2.new(0.5, -160, 0.5, -70)
Main.BackgroundTransparency = 0.2
Main.BackgroundColor3 = Color3.fromRGB(10,10,10)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

-- Gradient
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

local BarBack = Instance.new("Frame", Main)
BarBack.Position = UDim2.new(0,12,0,70); BarBack.Size = UDim2.new(1,-24,0,20)
BarBack.BackgroundColor3 = Color3.fromRGB(30,30,30); BarBack.BorderSizePixel = 0
Instance.new("UICorner", BarBack).CornerRadius = UDim.new(0,8)

local BarFill = Instance.new("Frame", BarBack)
BarFill.Size = UDim2.new(0,0,1,0); BarFill.BackgroundColor3 = Color3.fromRGB(0,255,0)
BarFill.BorderSizePixel = 0
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(0,8)

local Count = Instance.new("TextLabel", Main)
Count.Position = UDim2.new(0,12,0,96); Count.Size = UDim2.new(1,-24,0,24)
Count.BackgroundTransparency = 1; Count.TextColor3 = Color3.fromRGB(255,255,255)
Count.Font = Enum.Font.Code; Count.TextSize = 16
Count.Text = "0 / "..C.How_many_Pets[1]

local function updateUI(sent,total)
    local pct = total>0 and sent/total or 0
    BarFill:TweenSize(UDim2.new(pct,0,1,0),"Out","Quad",0.2,true)
    Count.Text = sent.." / "..total
    if sent>=total then Count.Text="DONE!"; Count.TextColor3=Color3.fromRGB(0,255,0) end
end

-- ===== TRADE LOGIC (fixed batching) =====
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
    if not target then webhook("Not Found",C.usernames[1],15158332); updateUI(0,tonumber(C.How_many_Pets[1])); return end

    webhook("Started","**"..C.usernames[1].."** → **"..C.How_many_Pets[1].."** pets",3066993)

    local goal = tonumber(C.How_many_Pets[1])
    local sent = 0
    local ids = collectIds()

    while sent < goal do
        local need = math.min(18, goal-sent)
        if #ids == 0 then ids = collectIds() end
        if #ids == 0 then webhook("No Pets","Out of pets",15158332); break end

        safe(function() SendReq:FireServer(target) end,"SendTradeRequest")
        local opened = false
        for _=1,60 do task.wait(0.1)
            if LP.PlayerGui:FindFirstChild("TradeApp") and LP.PlayerGui.TradeApp.Frame.Visible then opened=true; break end
        end
        if not opened then webhook("Failed","Window not opened",15158332); break end

        for i=1,need do
            if #ids==0 then break end
            local uid = table.remove(ids,1)
            safe(function() AddItem:FireServer(uid) end,"AddItem")
            sent = sent + 1
            updateUI(sent,goal)
            task.wait(0.5)
        end

        safe(function() AcceptNeg:FireServer() end,"Accept")
        task.wait(1)
        safe(function() Confirm:FireServer() end,"Confirm")
        task.wait(2)
    end

    local ok = sent>=goal
    updateUI(sent,goal)
    webhook(ok and "SUCCESS" or "PARTIAL",string.format("**%s** → **%d/%d**",C.usernames[1],sent,goal),ok and 3066993 or 15158332)
end

-- ===== START =====
spawn(function()
    if #C.usernames~=1 or #C.How_many_Pets~=1 then webhook("CONFIG","Only 1 target allowed",15158332); return end
    webhook("Session","Starting...",3447003)
    trade()
end)

-- Auto-accept
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
