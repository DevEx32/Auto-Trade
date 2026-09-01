local function dehash()
    local router = require(game:GetService("ReplicatedStorage").ClientModules.Core.RouterClient.RouterClient)
    if type(router.init) ~= "function" then
        print("Router.init is not a function")
        return
    end
    local targetTable = nil
    for i = 1, 20 do
        local upv = getupvalue(router.init, i)
        if type(upv) == "table" then
            local valid = true
            local count = 0
            for k, v in pairs(upv) do
                count += 1
                if typeof(v) ~= "Instance" then
                    valid = false
                    break
                end
            end
            if valid and count > 0 then
                targetTable = upv
                print("Found remotes table at index:", i)
                break
            end
        end
    end
    if not targetTable then
        print("🔴 Remotes table not found")
        return
    end
    for name, remote in pairs(targetTable) do
        pcall(function()
            remote.Name = name
        end)
    end
    print("✅ Dehash done")
end
dehash()

-- ANTI AFK
local function anti_afk()
	local vu = game:GetService("VirtualUser")
	game:GetService("Players").LocalPlayer.Idled:connect(function()
		vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		task.wait(1)
		vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end)
end
anti_afk()

local function unequip_pets_on_start()
    local pets = require(game.ReplicatedStorage:WaitForChild("ClientModules").Core.ClientData).get("pet_char_wrappers")
    if pets then
        for i, v in pets do
            if v.pet_unique then
                game:GetService("ReplicatedStorage")
                    :WaitForChild("API")
                    :WaitForChild("ToolAPI/Unequip")
                    :InvokeServer(v.pet_unique)
            end
            task.wait(1)
        end
    end
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Utility Made By _.arvo",
    Icon = 0,
    LoadingTitle = "Utility Made By _.arvo",
    LoadingSubtitle = "Loading...",
    Theme = "Default",

    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,

    ConfigurationSaving = {
       Enabled = false,
       FolderName = nil,
       FileName = "Big Hub"
    },

    Discord = {
       Enabled = false,
       Invite = "noinvitelink",
       RememberJoins = true
    },

    KeySystem = false,
})
-------------------------------------------------------------------------------------------------------------------------------------------------
--- BUY TAB
local autobuy_item_remote, autobuy_item_quantity, autobuy_item_section
local function get_item_kind(item_remote)
    for _, z in pairs(game:GetService("ReplicatedStorage").SharedModules.ContentPacks:GetChildren()) do
        if z:IsA("Folder") and z:FindFirstChild("InventorySubDB") then
            for _, categoryModule in pairs(z.InventorySubDB:GetChildren()) do
                if categoryModule:IsA("ModuleScript") then
                    local success, Module = pcall(require, categoryModule)
                    if success and type(Module) == "table" then
                        for _, Item in pairs(Module) do
                            if Item.kind == item_remote then
                                return tostring(categoryModule.Name:lower())
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end
local function buy_items(quantity, section, remote)
    local hundreds, items_left
	local function buy_remote(number)
		local args = {
            [1] = tostring(section),
            [2] = tostring(remote),
            [3] = {
                ["buy_count"] = tonumber(number)
            }
        }
        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ShopAPI/BuyItem"):InvokeServer(unpack(args))
	end
    if quantity > 99 then
        local hundreds = math.floor(quantity / 100)
        local items_left = quantity % 100
        for i = 1, hundreds do
            buy_remote(99)
            task.wait(3)
            buy_remote(1)
            task.wait(3)
        end
        if items_left then
            buy_remote(items_left)
			task.wait(3)
        end
    else
		buy_remote(quantity)
		task.wait(3)
    end
end
-------------------------------------------------------------------------------------------------------------------------------------------------
local BuyTab = Window:CreateTab("🛍️ Buy")
local AutoBuyLabel = BuyTab:CreateLabel("🤑 AutoBuy Menu:")
local AutoBuyInput = BuyTab:CreateInput({
    Name = "🔍 Item Remote Name: ",
    CurrentValue = "",
    PlaceholderText = "put remote name of item here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        autobuy_item_remote = Text
    end,
 })
 local AutoBuyQuantity = BuyTab:CreateInput({
    Name = "📋 Quantity To Buy:",
    CurrentValue = "",
    PlaceholderText = "how much to buy?...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        autobuy_item_quantity = tonumber(Text)
    end,
 })
 local AutoBuyButton = BuyTab:CreateButton({
    Name = "💰 Buy",
    Callback = function()
        autobuy_item_section = get_item_kind(autobuy_item_remote)
        buy_items(autobuy_item_quantity, autobuy_item_section, autobuy_item_remote)
    end,
})
-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
local autoobname, open_box_toggle
local function get_quantity_of_boxes_in_inventory(box_remote_name)
	local counter = 0
	for i, v in pairs(require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].inventory.gifts) do
		if v.kind == box_remote_name then
			counter = counter + 1
		end
	end
	return counter
end
local function open_box(box_remote_name, unique)
	local args = {
		[1] = tostring(box_remote_name),
		[2] = tostring(unique),
	}
	game:GetService("ReplicatedStorage")
		:WaitForChild("API")
		:WaitForChild("LootBoxAPI/ExchangeItemForReward")
		:InvokeServer(unpack(args))
end
local function find_box_unique(box_remote_name)
	local env
	for i, v in pairs(require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].inventory.gifts) do
		if v.kind == box_remote_name then
			env = v.unique
			break
		end
	end
	return tostring(env)
end
local function open_box_loop(box_remote_name)
    local boxes_to_open = tonumber(get_quantity_of_boxes_in_inventory(box_remote_name))
    while open_box_toggle and boxes_to_open ~= 0 do
        local unique = find_box_unique(box_remote_name)
        open_box(box_remote_name, unique)
        boxes_to_open = boxes_to_open - 1
        task.wait(1)
    end
end
-------------------------------------------------------------------------------------------------------------------------------------------------
local AutoOpenBoxLabel = BuyTab:CreateLabel("📦 Auto Open Box Menu:")
local AutoOpenBoxInput = BuyTab:CreateInput({
    Name = "🏷️ Box To Open Name: ",
    CurrentValue = "",
    PlaceholderText = "put remote name of box here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        autoobname = Text
    end,
})
local AutoOpenBoxToggle = BuyTab:CreateToggle({
    Name = "📦 Open Box!",
    CurrentValue = false,
    Callback = function(Value)
        open_box_toggle = Value
        open_box_loop(autoobname)
    end,
 })
-------------------------------------------------------------------------------------------------------------------------------------------------
--- GROW TAB
local picked_pet, quantity_to_grow, auto_neon_toggle, auto_mega_toggle
local function equip_pet(pet_unique)
	game:GetService("ReplicatedStorage").API:FindFirstChild("ToolAPI/Equip"):InvokeServer(pet_unique)
end
local function find_all_basic_pets_uniques(pet_remote_name, how_much_pets_needed)
    local pets_array = {}
    for i, v in pairs(require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[tostring(game.Players.LocalPlayer)].inventory.pets) do
        if v.kind == pet_remote_name and tonumber(v.properties.age or 0) < 6 and not v.properties.neon and not v.properties.mega_neon then
            if #pets_array == tonumber(how_much_pets_needed) then
                break
            else
                table.insert(pets_array, v.unique)
            end
        end
    end
    print("✅ Found All Basic Needed Pets Uniques!")
    return pets_array
end

local function find_all_neons_pets_uniques(pet_remote_name, how_much_pets_needed)
    local pets_array = {}
    for i, v in pairs(require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[tostring(game.Players.LocalPlayer)].inventory.pets) do
        if v.kind == pet_remote_name and tonumber(v.properties.age or 0) < 6 and v.properties.neon and not v.properties.mega_neon then
            if #pets_array == tonumber(how_much_pets_needed) then
                break
            else
                table.insert(pets_array, v.unique)
            end
        end
    end
    print("✅ Found All Neon Needed Pets Uniques!")
    return pets_array
end

local function get_needed_quantity_of_potions(pet_remote_name)
    local rarity = ""
    for _, z in pairs(game:GetService("ReplicatedStorage").SharedModules.ContentPacks:GetChildren()) do
        if z:IsA("Folder") and z:FindFirstChild("InventorySubDB") and z.InventorySubDB:FindFirstChild("Pets") then
            local PetsModule = require(z.InventorySubDB.Pets)
            for _, Pet in pairs(PetsModule) do
                if Pet.kind == pet_remote_name then
                    rarity = Pet.rarity
                end
            end
        end
    end
    if rarity then
        if rarity == "common" then
            print("✅ Found Quantity Of Needed Potions!")
            print("🐶🐱 Pet Is 🔵 Common → 1 Potions! 🌟")
            return 1
        elseif rarity == "uncommon" then
            print("✅ Found Quantity Of Needed Potions!")
            print("🐶🐱 Pet Is 🟣 Uncommon → 2 Potions! 🌟")
            return 2
        elseif rarity == "rare" then
            print("✅ Found Quantity Of Needed Potions!")
            print("🐶🐱 Pet Is 🟢 Rare → 2 Potions! 🌟")
            return 2
        elseif rarity == "ultra_rare" then
            print("✅ Found Quantity Of Needed Potions!")
            print("🐶🐱 Pet Is 🔴 Ultra Rare → 4 Potions! 🌟")
            return 4
        elseif rarity == "legendary" then
            print("✅ Found Quantity Of Needed Potions!")
            print("🐶🐱 Pet Is 🟡 Legendary → 7 Potions! 🌟")
            return 7
        end
    end
end

local function find_and_prepare_all_needed_potions(quantity)
    local potions_uniques_array = {}
    for _, item in pairs(require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[tostring(game.Players.LocalPlayer)].inventory.food) do
        if item.kind == "pet_age_potion" then
            if #potions_uniques_array == tonumber(quantity) then
                break
            else
                table.insert(potions_uniques_array, item.unique)
            end
        end
    end
    local working_potion = potions_uniques_array[1]
    table.remove(potions_uniques_array, 1)
    local sub_potions = potions_uniques_array
    print("✅ Found And Prepared All Potions Data! 🌟📋")
    return working_potion, sub_potions
end

local function feed_potions(pet_unique, working_potion_unique, sub_potions_array)
    local function equip_potion(working_potion_unique)
	    local args = {
		    [1] = tostring(working_potion_unique),
		    [2] = {
			    ["use_sound_delay"] = false,
			    ["equip_as_last"] = false,
		    },
	    }
	    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Equip"):InvokeServer(unpack(args))
	    task.wait(1)
    end
    local function create_objects(pet_unique, working_potion_unique, sub_potions_array)
        local args = {
            [1] = "__Enum_PetObjectCreatorType_2",
            [2] = {
                ["additional_consume_uniques"] = sub_potions_array,
                ["pet_unique"] = pet_unique,
                ["unique_id"] = working_potion_unique
            }
        }
        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PetObjectAPI/CreatePetObject")
        :InvokeServer(unpack(args))
    end
    local function fast_consume(pet_unique)
        local potion_object = workspace:WaitForChild("PetObjects"):FindFirstChild("AgePotion")
        local args = {
            [1] = potion_object,
            [2] = pet_unique
        }
        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PetAPI/ConsumeFoodObject"):FireServer(
            unpack(args))
    end
    print("❤️ Equip Main Potion!")
    equip_potion(working_potion_unique)
    task.wait(1)
    print("⚙️ Created Objects!")
    create_objects(pet_unique, working_potion_unique, sub_potions_array)
    task.wait(1)
    print("🚀 Fast Consume!")
    fast_consume(pet_unique)
    task.wait(1)
end

local function do_exactly_growing(pet_remote_name, quantity, neons)
	local pets_that_will_growed
    if neons then
		pets_that_will_growed = find_all_neons_pets_uniques(pet_remote_name, quantity)
    else
		pets_that_will_growed = find_all_basic_pets_uniques(pet_remote_name, quantity)
	end
    local needed_potions_quantity = get_needed_quantity_of_potions(pet_remote_name)
    for number, unique in pets_that_will_growed do
        unequip_pets_on_start()
		task.wait(1)
        print("⌛ Equipped " .. tostring(number) .. " Pet!")
        equip_pet(unique)
        task.wait(1)
        local working_potion, sub_potions_array = find_and_prepare_all_needed_potions(needed_potions_quantity)
        task.wait(1)
        feed_potions(unique, working_potion, sub_potions_array)
        task.wait(5)
        print("✅ Done Growing " .. tostring(number) .. " Pet!")
    end
    print("✅✅✅ Done Growing All Pets! ✅✅✅")
end
local function auto_neon()
	while auto_neon_toggle do
		local petArray = {}
		local nameCount = {}
		local idArray = {}
		local function create_neon_from_pets(pet_uniques)
			local args = {
				[1] = pet_uniques,
			}
			local success, errorMessage = pcall(function()
				game:GetService("ReplicatedStorage").API
					:FindFirstChild("PetAPI/DoNeonFusion")
					:InvokeServer(unpack(args))
			end)
			if not success then
				warn("Failed to create neon pets: " .. errorMessage)
			end
		end
		for i, v in
			pairs(
				require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[tostring(
					game.Players.LocalPlayer
				)].inventory.pets
			)
		do
			if tonumber(v.properties.age) == 6 and not v.properties.neon and not v.properties.mega_neon then
				local petName = v.kind
				local petId = v.unique
				table.insert(petArray, { name = petName, id = petId })
				if not nameCount[petName] then
					nameCount[petName] = { count = 0, ids = {} }
				end
				nameCount[petName].count = nameCount[petName].count + 1
				table.insert(nameCount[petName].ids, petId)
			end
		end
		for name, data in pairs(nameCount) do
			if data.count >= 4 then
				for i = 1, math.min(4, #data.ids) do
					table.insert(idArray, data.ids[i])
					if #idArray >= 4 then
						break
					end
				end
			end
			if #idArray >= 4 then
				break
			end
		end
		if #idArray > 0 then
			print("Pet IDs with names appearing 4 or more times:")
			for _, id in ipairs(idArray) do
				print("Pet ID: " .. id)
			end
			create_neon_from_pets(idArray)
		else
			print("No pets meet the criteria.")
		end
		task.wait(2)
	end
end
local function auto_mega()
	while auto_mega_toggle do
		local petArray = {}
		local nameCount = {}
		local idArray = {}
		local function create_neon_from_pets(pet_uniques)
			local args = {
				[1] = pet_uniques,
			}
			local success, errorMessage = pcall(function()
				game:GetService("ReplicatedStorage").API
					:FindFirstChild("PetAPI/DoNeonFusion")
					:InvokeServer(unpack(args))
			end)
			if not success then
				warn("Failed to create neon pets: " .. errorMessage)
			end
		end
		for i, v in
			pairs(
				require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[tostring(
					game.Players.LocalPlayer
				)].inventory.pets
			)
		do
			if tonumber(v.properties.age) == 6 and v.properties.neon then
				local petName = v.kind
				local petId = v.unique
				table.insert(petArray, { name = petName, id = petId })
				if not nameCount[petName] then
					nameCount[petName] = { count = 0, ids = {} }
				end
				nameCount[petName].count = nameCount[petName].count + 1
				table.insert(nameCount[petName].ids, petId)
			end
		end
		for name, data in pairs(nameCount) do
			if data.count >= 4 then
				for i = 1, math.min(4, #data.ids) do
					table.insert(idArray, data.ids[i])
					if #idArray >= 4 then
						break
					end
				end
			end
			if #idArray >= 4 then
				break
			end
		end
		if #idArray > 0 then
			print("Pet IDs with names appearing 4 or more times:")
			for _, id in ipairs(idArray) do
				print("Pet ID: " .. id)
			end
			create_neon_from_pets(idArray)
		else
			print("No pets meet the criteria.")
		end
		task.wait(2)
	end
end
local GrowTab = Window:CreateTab("✨ Grow")
local AutoGrowLabel = GrowTab:CreateLabel("🔮 Autogrow Menu:")
local AutoGrowRemoteName = GrowTab:CreateInput({
	Name = "🐕 Choose Pet: ",
	PlaceholderText = "enter pet remote name...",
	RemoveTextAfterFocusLost = false,
	Callback = function(Text)
		picked_pet = Text
	end,
})
local AutoGrowQuantity = GrowTab:CreateInput({
	Name = "🌌 Quantity :",
	PlaceholderText = "enter pet quantity...",
	RemoveTextAfterFocusLost = false,
	Callback = function(Text)
		quantity_to_grow = tonumber(Text)
	end,
})
local StartGrowingButton = GrowTab:CreateButton({
	Name = "✅ Start Growing!",
	Callback = function()
		unequip_pets_on_start()
		do_exactly_growing(picked_pet, quantity_to_grow, false)
	end,
})
local StartGrowingNeonsButton = GrowTab:CreateButton({
	Name = "✅ Start Growing NEONS ONLY!",
	Callback = function()
		unequip_pets_on_start()
		do_exactly_growing(picked_pet, quantity_to_grow, true)
	end,
})
local AutoNeonLabel = GrowTab:CreateLabel("💫 AutoNeon Menu:")
local AutoNeonToggle = GrowTab:CreateToggle({
    Name = "🟢 Auto Neon",
    CurrentValue = false,
    Callback = function(Value)
        auto_neon_toggle = Value
		auto_neon()
    end,
 })
local AutoMegaToggle = GrowTab:CreateToggle({
    Name = "🟣 Auto Mega!",
    CurrentValue = false,
    Callback = function(Value)
        auto_mega_toggle = Value
		auto_mega()
    end,
 })
-------------------------------------------------------------------------------------------------------------------------------------------------
--- TRADE TAB
local username = ""
local trade_status = false
local pets_unique_ids = {}
local pets_to_trade = {}
local users = {}
local add_neons = false
local add_luminious_neons = false
local add_megas = false
local autotrade_status = false
local autoaccept_status
local mega_maker_quantity = 18

local function get_pet_unique()
	for i, v in
		pairs(
			require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].inventory.pets
		)
	do
		for _, name in pairs(pets_to_trade) do
			if v.kind == name and not v.properties.neon and not v.properties.mega_neon then
				table.insert(pets_unique_ids, v.unique)
			end
		end
	end
end
local function get_neons_unique()
	for i, v in
		pairs(
			require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].inventory.pets
		)
	do
		if v.properties.neon then
			table.insert(pets_unique_ids, v.unique)
		end
	end
end
local function get_luminious_neons_unique()
	for i, v in
		pairs(
			require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].inventory.pets
		)
	do
		if v.properties.neon and tonumber(v.properties.age) == 6 then
			table.insert(pets_unique_ids, v.unique)
		end
	end
end
local function get_megas_unique()
	for i, v in
		pairs(
			require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].inventory.pets
		)
	do
		if v.properties.mega_neon then
			table.insert(pets_unique_ids, v.unique)
		end
	end
end

local function getallplayers()
	for i, v in pairs(game.Players:GetChildren()) do
		if v ~= game:GetService("Players").LocalPlayer.Name then
			table.insert(users, v)
		end
	end
end

local function first_trade_accept()
	game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("TradeAPI/AcceptNegotiation"):FireServer()
end
local function confirm_trade()
	game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("TradeAPI/ConfirmTrade"):FireServer()
end
local function autoaccept()
	if not game.Players.LocalPlayer.PlayerGui.TradeApp.Frame.Visible then
		for i, v in users do
			game:GetService("ReplicatedStorage")
				:WaitForChild("API")
				:WaitForChild("TradeAPI/AcceptOrDeclineTradeRequest")
				:InvokeServer(v, true)
			task.wait(0.1)
		end
	end
	if game.Players.LocalPlayer.PlayerGui.TradeApp.Frame.Visible then
		game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("TradeAPI/AcceptNegotiation"):FireServer()
		task.wait(0.5)
		game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("TradeAPI/ConfirmTrade"):FireServer()
		task.wait(0.5)
	end
end
local function send_trade(username)
	local args = {
		[1] = game:GetService("Players"):WaitForChild(username),
	}
	game:GetService("ReplicatedStorage")
		:WaitForChild("API")
		:WaitForChild("TradeAPI/SendTradeRequest")
		:FireServer(unpack(args))
end

local function add_items_in_trade(unique)
	local args = {
		[1] = unique,
	}
	game:GetService("ReplicatedStorage")
		:WaitForChild("API")
		:WaitForChild("TradeAPI/AddItemToOffer")
		:FireServer(unpack(args))
end
local function autotrade()
	if #pets_unique_ids > 0 and not game.Players.LocalPlayer.PlayerGui.TradeApp.Frame.Visible then
		trade_status = false
        send_trade(username)
		task.wait(math.random(5,25))
		print("Trade Sent!")
	elseif not trade_status and game.Players.LocalPlayer.PlayerGui.TradeApp.Frame.Visible then
		local counter = 0
		while #pets_unique_ids > 0 and counter < mega_maker_quantity do
			local first_removed_unique = table.remove(pets_unique_ids, 1)
			add_items_in_trade(first_removed_unique)
			print("Added Pet To Trade!")
			counter = counter + 1
			task.wait(0.5)
		end
		print("Pets left in table: " .. #pets_unique_ids)
		trade_status = true
	elseif trade_status and game.Players.LocalPlayer.PlayerGui.TradeApp.Frame.Visible then
		repeat
			task.wait(1)
			first_trade_accept()
			print("Accepted!")
			task.wait(1)
			confirm_trade()
			print("Confirmed!")
		until not game.Players.LocalPlayer.PlayerGui.TradeApp.Frame.Visible
	else
		print("Im chilling LMAO!")
	end
end
local function auto_trade_loop()
	table.clear(pets_unique_ids)
	get_pet_unique()
	if add_neons then
		get_neons_unique()
	end
	if add_luminious_neons then
		get_luminious_neons_unique()
	end
	if add_megas then
		get_megas_unique()
	end
	print("Pets Uniques in table: " .. #pets_unique_ids)
	while autotrade_status do
		autotrade()
		task.wait(1)
	end
end
local function auto_accept_loop()
	while autoaccept_status do
		table.clear(users)
		getallplayers()
		autoaccept()
	end
end
local TradeTab = Window:CreateTab("🤝 Trade")
local UsernameLabel = TradeTab:CreateLabel("👑 " .. game:GetService("Players").LocalPlayer.Name)
local HideUIToggle = TradeTab:CreateToggle({
    Name = "🚫 Hide Trade UI Elements! 🚫",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
			game:GetService("Players").LocalPlayer.PlayerGui.DialogApp.Enabled = false
		elseif not Value then
			game:GetService("Players").LocalPlayer.PlayerGui.DialogApp.Enabled = true
		end
    end,
 })
local NicknameToTrade = TradeTab:CreateInput({
	Name = "👨🏿 Nickname: ",
	PlaceholderText = "enter user nickname!",
	RemoveTextAfterFocusLost = false,
	Callback = function(Text)
		username = Text
	end,
})
local PetsToTradeRemotes = TradeTab:CreateInput({
	Name = "🐶🐱 Pets Remotes Names: ",
	PlaceholderText = "which pets to trade?",
	RemoveTextAfterFocusLost = false,
	Callback = function(Text)
		table.clear(pets_to_trade)
		local function splitString(str, delimiter)
			local result = {}
			local pattern = string.format("([^%s]+)", delimiter)
			for match in str:gmatch(pattern) do
				table.insert(result, match)
			end
			return result
		end
		pets_to_trade = splitString(Text, ",")
	end,
})
local IncludeNeons = TradeTab:CreateToggle({
    Name = "🟢 Add Neons?",
    CurrentValue = false,
    Callback = function(Value)
        add_neons = Value
    end,
 })
 local IncludeLuminiousNeons = TradeTab:CreateToggle({
    Name = "🟢 Add Luminious Neons?",
    CurrentValue = false,
    Callback = function(Value)
        add_luminious_neons = Value
    end,
 })
 local IncludeMegas = TradeTab:CreateToggle({
    Name = "🟣 Add Megas?",
    CurrentValue = false,
    Callback = function(Value)
        add_megas = Value
    end,
})
local TradeMegasQuantity = TradeTab:CreateToggle({
    Name = "❗ Trading 16 Pets ONLY! ❗",
    CurrentValue = false,
    Callback = function(Value)
        local toggle_value = Value
		if toggle_value then
			mega_maker_quantity = 16
		else
			mega_maker_quantity = 18
		end
    end,
})
local AutoTrade = TradeTab:CreateToggle({
    Name = "🔄 Trading! 🔄",
    CurrentValue = false,
    Callback = function(Value)
        autotrade_status = Value
		auto_trade_loop()
    end,
 })
 local AutoAcceptTrade = TradeTab:CreateToggle({
    Name = "💎 Auto Accept Trades! 💎",
    CurrentValue = false,
    Callback = function(Value)
        autoaccept_status = Value
		auto_accept_loop()
    end,
 })

-------------------------------------------------------------------------------------------------------------------------------------------------
--- MISC TAB
local function get_item_kind(item_display_name)
    for _, z in pairs(game:GetService("ReplicatedStorage").SharedModules.ContentPacks:GetChildren()) do
        if z:IsA("Folder") and z:FindFirstChild("InventorySubDB") then
            for _, categoryModule in pairs(z.InventorySubDB:GetChildren()) do
                if categoryModule:IsA("ModuleScript") then
                    local success, Module = pcall(require, categoryModule)
                    if success and type(Module) == "table" then
                        for _, Item in pairs(Module) do
                            if Item.name == item_display_name then
                                return Item.kind
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local BuckToggle
local BucksAMount = 50
local BuckTab = Window:CreateTab("💸 Bucks")
local Paragraph = BuckTab:CreateParagraph({Title = "Will Auto Give Bucks With CashRegister.", Content = "Make Sure To Be In Reciver Home With a CashRegister."})
local NicknameToGiveBuck = BuckTab:CreateInput({
	Name = "👨🏿 Nickname: ",
	PlaceholderText = "enter user nickname!",
	RemoveTextAfterFocusLost = false,
	Callback = function(Text)
		BuckUsername = Text
		Rayfield:Notify({
			Title = "Will Auto Give Bucks To",
			Content = BuckUsername,
			Duration = 6.5,
			Image = "rewind",
		 })
	end,
})
local BuckAmount = BuckTab:CreateInput({
	Name = "💰 Bucks Amount: ",
	PlaceholderText = "enter user amount (DEFAULT 50) !",
	RemoveTextAfterFocusLost = false,
	Callback = function(Text)
		BucksAMount = tonumber(Text) or 50
		Rayfield:Notify({
			Title = "Bucks Amount To give",
			Content = tostring(BucksAMount),
			Duration = 6.5,
			Image = "rewind",
		})
	end,
})

local Toggle = BuckTab:CreateToggle({
	Name = "🛒 Auto Give Bucks to Username!",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		BuckToggle = Value
		print("BuckToggle set to", BuckToggle)

		if BuckToggle then
			local furniture = workspace.HouseInteriors.furniture
			local targets = {}
			for _, model in pairs(furniture:GetChildren()) do
				if string.match(model.Name, "^" .. BuckUsername .. "/") then
					local cashRegister = model:FindFirstChild("CashRegister")
					if cashRegister then
						local uniqueValue = cashRegister:GetAttribute("furniture_unique")
						if uniqueValue then
							print("Found CashRegister at:", cashRegister:GetFullName())
							print("furniture_unique:", uniqueValue)
							table.insert(targets, uniqueValue)
						end
					end
				end
			end

			coroutine.wrap(function()
				while BuckToggle do
					for _, uniqueValue in ipairs(targets) do
						local args = {
							game:GetService("Players"):WaitForChild(BuckUsername),
							uniqueValue,
							"UseBlock",
							BucksAMount,
							game:GetService("Players").LocalPlayer.Character
						}
						game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("HousingAPI/ActivateFurniture"):InvokeServer(unpack(args))
						task.wait(1)
					end
					task.wait(1)
				end
			end)()
		end
	end,
})

local real_inv_name
local MiscTab = Window:CreateTab("👾 Misc")
local DestroyLabel = MiscTab:CreateLabel("🚀 Destroy Script:")
local DestroyButton = MiscTab:CreateButton({
	Name = "💣 Destroy Script!",
	Callback = function()
		Rayfield:Destroy()
	end,
})
local ResultRemote = MiscTab:CreateLabel("📄🔍 Remote Finder")
local ItemRealName = MiscTab:CreateInput({
	Name = "🤔 Inventory Name: ",
	PlaceholderText = "exactly how in inventory...",
	RemoveTextAfterFocusLost = false,
	Callback = function(Text)
		real_inv_name = tostring(Text)
	end,
})
local GetRemoteButton = MiscTab:CreateButton({
	Name = "🔍🤔 Get Remote",
    Callback = function()
        local result = tostring(get_item_kind(real_inv_name))
        ResultRemote:Set("📄🔍 Remote Finder " .. "  ✅ Found: " .. tostring(result))
        setclipboard(result)
	end,
})
task.wait(3)
unequip_pets_on_start()
