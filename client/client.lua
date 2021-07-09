ESX = nil
local isPedLoaded
local PlayerPedPreview
local shouldUpdateSkin = false
local pedSkin = {}
local lastSkin = nil
local equipped = {}

local slots = {
	[0] = {'none', false, ''},
	[1] = {'none', false, ''},
	[2] = {'none', false, ''},
	[3] = {'none', false, ''}
}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

RegisterNUICallback('close', function()
	isSlotsOpened = false
	deletePedScreen()
	SetNuiFocus(false, false)
end) 

RegisterNUICallback("useItem", function(data, cb)
	TriggerServerEvent("esx:useItem", data.item)
	cb("ok")
end)

RegisterNUICallback('changeSlot', function(data)
	slots[data.key] = data.value
end)

RegisterNUICallback("dropItem", function(data, cb)
    if IsPedSittingInAnyVehicle(playerPed) then
        return
    end
	local ped = PlayerPedId()
	if (IsPedInAnyVehicle(ped, true) == false) then
    	if type(data.number) == "number" and math.floor(data.number) == data.number then
			Citizen.CreateThread(function()
				local pid = PlayerPedId()
				RequestAnimDict("mp_weapon_drop")
				while (not HasAnimDictLoaded("mp_weapon_drop")) do Citizen.Wait(0) end
				TaskPlayAnim(ped, "mp_weapon_drop", "drop_bh", 8.0, 2.0, 0.5, 0, 2.0, 0, 0, 0 )
			end)
			if (data.item.type ~= 'item_money') then
    	    	TriggerServerEvent("esx:removeInventoryItem", data.item.type, data.item.name, data.number)
			else
				TriggerServerEvent('panama_inventar:removeMoney', GetPlayerServerId(PlayerId()), data.item.name, data.number)
			end
    	end
		refreshInventory()
    	cb("ok")
	else
		TriggerEvent('panama_notifikacije:sendNotification', 'fas fa-user', 'Ne mozete bacati u autu', 3000)
	end
end)

RegisterNUICallback("giveItem", function(data, cb)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	print(GetPlayerServerId(closestPlayer))
    if closestPlayer ~= -1 and closestDistance < 3.0 then
        local count = data.number
        if data.item.type == "item_weapon" then
            count = GetAmmoInPedWeapon(PlayerPedId(), GetHashKey(data.item.name))
        end
        canPlayAnim = false
        ClearPedSecondaryTask(PlayerPedId())
        RequestAnimDict("mp_common")
        while (not HasAnimDictLoaded("mp_common")) do 
            Citizen.Wait(10) 
        end
        TaskPlayAnim(PlayerPedId(),"mp_common","givetake1_a",100.0, 200.0, 0.3, 120, 0.2, 0, 0, 0)
        SetCurrentPedWeapon(PlayerPedId(), 0xA2719263) 
        --if (Config.PropList[data.item.name] ~= nil) then 
        --    attachModel = GetHashKey(Config.PropList[data.item.name].model)
        --    local bone = GetPedBoneIndex(PlayerPedId(), Config.PropList[data.item.name].bone)
        --    RequestModel(attachModel)
        --    while not HasModelLoaded(attachModel) do
        --        Citizen.Wait(10)
        --    end
        --    closestEntity = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
        --    AttachEntityToEntity(closestEntity, PlayerPedId(), bone, Config.PropList[data.item.name].x, Config.PropList[data.item.name].y, Config.PropList[data.item.name].z,
        --    Config.PropList[data.item.name].xR, Config.PropList[data.item.name].yR, Config.PropList[data.item.name].zR, 1, 1, 0, true, 2, 1)
        --    Citizen.Wait(1500)
        --    if DoesEntityExist(closestEntity) then
        --        DeleteEntity(closestEntity)
        --    end
        --end
        SetCurrentPedWeapon(PlayerPedId(), GetHashKey("weapon_unarmed"), 1)
        canPlayAnim = true
		if data.item.type == "item_money" then
				TriggerServerEvent("esx:dajItem", GetPlayerServerId(closestPlayer), "item_account", "money", count)
		else
        	TriggerServerEvent("esx:dajItem", GetPlayerServerId(closestPlayer), data.item.type, data.item.name, count)
		end
        Wait(0)
        refreshInventory()
	else
		TriggerEvent('panama_notifikacije:sendNotification', 'fas fa-user', 'Covek nije u blizini', 3000)
    end
    cb("ok")
end)

refreshInventory = function()
	ESX.TriggerServerCallback('panama_inventar:getPlayerInventory', function(data)
		local items = {}
		if data.money ~= nil then
			table.insert(items, {
				label = 'Pare', 
				name = 'money',
				type = 'item_money',
				count = data.money,
				usable = false,
				rare = false,
				canRemove = true,
				desc = 'Sluzi za kupovinu'
			})
		end
		if data.inventory ~= nil then
			for k,v in pairs(data.inventory) do
				if data.inventory[k].count <= 0 then
					data.inventory[k] = nil
				else
					data.inventory[k].type = 'item_standard'
					table.insert(items, data.inventory[k])
				end
			end
		end
		if data.weapons ~= nil then
			for k,v in pairs(data.weapons) do
				if data.weapons[k].name ~= 'WEAPON_UNARMED' then
					local found = false
					if found == false then
						local ammo = GetAmmoInPedWeapon(PlayerPedId(), GetHashKey(data.weapons[k].name))
						table.insert(items, {
							label = data.weapons[k].label,
							count = ammo,
							limit = 250,
							type = 'item_weapon',
							name = data.weapons[k].name,
							usable = false,
							rare = false,
							canRemove = true
						})
					end
				end
			end
		end
		SendNUIMessage({action = 'refreshInventory', items = items, slots = slots})
	end, GetPlayerServerId(PlayerId()))
end

function createPedScreen() 
	CreateThread(function()
		heading = GetEntityHeading(PlayerPedId())
		upaljeno = true
		SetFrontendActive(true)
		ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_EMPTY_NO_BACKGROUND"), true, -1)
		Citizen.Wait(100)
		N_0x98215325a695e78a(false)

 		PlayerPedPreview = ClonePed(PlayerPedId(), heading, true, false)
 		local x,y,z = table.unpack(GetEntityCoords(PlayerPedPreview))
 		SetEntityCoords(PlayerPedPreview, x,y,z-10)
 		FreezeEntityPosition(PlayerPedPreview, true)
		SetEntityVisible(PlayerPedPreview, false, false)
		NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)
		Wait(200)
		SetPedAsNoLongerNeeded(PlayerPedPreview)
		GivePedToPauseMenu(PlayerPedPreview, 2)
		SetPauseMenuPedLighting(true)
		SetPauseMenuPedSleepState(true)
	end)
end

function deletePedScreen()
	 DeleteEntity(PlayerPedPreview)
	SetFrontendActive(false)
	PlayerPedPreview = nil
end

function refreshPedScreen()
	deletePedScreen()
	Wait(200)
	createPedScreen()
end


RegisterCommand('+inventar', function()
	saveCurrentSkin()
	ESX.TriggerServerCallback('panama_inventar:getPlayerInventory', function(data)
		local items = {}
		if data.money ~= nil then
			table.insert(items, {
				label = 'Pare', 
				name = 'money',
				type = 'item_money',
				count = data.money,
				usable = false,
				rare = false,
				canRemove = true,
				desc = 'Sluzi za kupovinu'
			})
		end
		if data.inventory ~= nil then
			for k,v in pairs(data.inventory) do
				if data.inventory[k].count <= 0 then
					data.inventory[k] = nil
				else
					data.inventory[k].type = 'item_standard'
					table.insert(items, data.inventory[k])
				end
			end
		end
		if data.weapons ~= nil then
			for k,v in pairs(data.weapons) do
				if data.weapons[k].name ~= 'WEAPON_UNARMED' then
					local found = false
					if found == false then
						local ammo = GetAmmoInPedWeapon(PlayerPedId(), GetHashKey(data.weapons[k].name))
						table.insert(items, {
							label = data.weapons[k].label,
							count = ammo,
							limit = 250,
							type = 'item_weapon',
							name = data.weapons[k].name,
							usable = false,
							rare = false,
							canRemove = true
						})
					end
				end
			end
		end
		createPedScreen()
		SendNUIMessage({action = 'show', items = items, slots = slots, equipped = equipped})
		SetNuiFocus(true, true)
	end, GetPlayerServerId(PlayerId()))
end, false)


---Slotovi i holster animacija
local holstered = true
local blocked = false

function loadAnimDict(dict)
	while ( not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Citizen.Wait(0)
	end
end

function CheckWeapon(ped)
	if IsEntityDead(ped) then
		blocked = false
			return false
	else
		for i = 1, #Config.Weapons do
			if GetHashKey(Config.Weapons[i]) == GetSelectedPedWeapon(ped) then
				return true
			end
		end
		return false
	end
end

function gangstaHolsterAnim(ped)
	loadAnimDict("reaction@intimidation@1h")
	if not IsPedInAnyVehicle(ped, false) then
		if GetVehiclePedIsTryingToEnter (ped) == 0 and (GetPedParachuteState(ped) == -1 or GetPedParachuteState(ped) == 0) and not IsPedInParachuteFreeFall(ped) then
			if CheckWeapon(ped) then
				if holstered then
					blocked   = true
					SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
					TaskPlayAnim(ped, "reaction@intimidation@1h", "intro", 5.0, 1.0, -1, 50, 0, 0, 0, 0 )
					Wait(1250)
					SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
					Wait(1700)
					ClearPedTasks(ped)
					holstered = false
					Wait(1000)
					blocked = false
				end
			else
				if not holstered then
					TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", 8.0, 3.0, -1, 50, 0, 0, 0.125, 0 ) -- Change 50 to 30 if you want to stand still when holstering weapon
					Wait(1700)
					ClearPedTasks(ped)
					holstered = true
				end
			end
		else
			SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
		end
	else
		holstered = true
	end
end

function holsterAnim(ped)
	loadAnimDict("rcmjosh4")
	loadAnimDict("reaction@intimidation@cop@unarmed")
	if not IsPedInAnyVehicle(ped, false) then
		if GetVehiclePedIsTryingToEnter (ped) == 0 and (GetPedParachuteState(ped) == -1 or GetPedParachuteState(ped) == 0) and not IsPedInParachuteFreeFall(ped) then
			if CheckWeapon(ped) then
				if holstered then
					blocked = true
					SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
					TaskPlayAnim(ped, "reaction@intimidation@cop@unarmed", "intro", 8.0, 2.0, -1, 50, 2.0, 0, 0, 0 ) -- Change 50 to 30 if you want to stand still when removing weapon
					Wait(200)
					SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
					TaskPlayAnim(ped, "rcmjosh4", "josh_leadout_cop2", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
					Wait(400)
					ClearPedTasks(ped)
					holstered = false
					blocked = false
				end
			else
				if not holstered then
					TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", 8.0, 3.0, -1, 50, 0, 0, 0.125, 0 ) -- Change 50 to 30 if you want to stand still when holstering weapon
					ClearPedTasks(ped)
					holstered = true
				end
			end
		else
			SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
		end
	else
		holstered = true
	end
end

RegisterNUICallback('setSlot', function(data)
	setSlot(data.slot, data.item.name, data.item.type)
end)

function setSlot(slot, item, type) 
	slots[slot][1] = item
	slots[slot][2] = false
	slots[slot][3] = type
end

function useSlotItem(slot)
	if slots[slot][1] == 'none' then return end;
	if slots[slot][3] == 'item_standard' then
		SendNUIMessage({action = 'slotAnimation',id = slot, name = slots[slot][1]})
		TriggerServerEvent("esx:useItem", slots[slot][1])
	elseif slots[slot][3] == 'item_weapon' then
		if slots[slot][2] == false and blocked == false then
			if GetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_UNARMED')) == false then
				SendNUIMessage({action = 'slotAnimation',id = slot, name = slots[slot][1]})
				SetCurrentPedWeapon(PlayerPedId(), GetHashKey(slots[slot][1]), true)
				if PlayerData.job.name == 'police' then
					holsterAnim(PlayerPedId())
				else
					gangstaHolsterAnim(PlayerPedId())
				end
				slots[slot][2] = true
			else
				TriggerEvent('panama_notifikacije:sendNotification', 'fas fa-user', 'Ne mozete vaditi vise od jednog pistolja/pusku.', 5000)
			end
		elseif slots[slot][2] == true then
			--SendNUIMessage({action = 'slotAnimation',id = slot, name = slots[slot][1]})
			SetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_UNARMED'), true)
			if PlayerData.job.name == 'police' then
				holsterAnim(PlayerPedId())
			else
				gangstaHolsterAnim(PlayerPedId())
			end
			slots[slot][2] = false
		end
	end
end

RegisterKeyMapping('+inventar', 'Inventar', 'keyboard', 'f2')
--Slotovi keymaping
RegisterCommand('+slot1', function()
	useSlotItem(0)
end,false)
RegisterKeyMapping('+slot1', 'Slot1', 'keyboard', '1')

RegisterCommand('+slot2', function()
	useSlotItem(1)
end,false)
RegisterKeyMapping('+slot2', 'Slot2', 'keyboard', '2')

RegisterCommand('+slot3', function()
	useSlotItem(2)
end,false)
RegisterKeyMapping('+slot3', 'Slot3', 'keyboard', '3')

RegisterCommand('+slot4', function()
	useSlotItem(3)
end,false)
RegisterKeyMapping('+slot4', 'Slot4', 'keyboard', '4')

--Resource Manifest------------------------------
AddEventHandler('onResourceStop', function()
	if (GetCurrentResourceName() ~= 'panama_inventar') then
	  return
	end
	SetFrontendActive(false)
	SetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_UNARMED'), true)
	SetNuiFocus(false, false)
end)


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		DisableControlAction(0, 37 , true)
		if blocked then
			DisablePlayerFiring(PlayerPedId(), true)
		end
	end
end)

RegisterCommand('+weapon_selection', function()
	if isSlotsOpened == false then
		SendNUIMessage({
			action = 'weapon_selection'
		})
		isSlotsOpened = true
	else
		SendNUIMessage({
			action = 'weapon_selection_close'
		})	
		isSlotsOpened = false
	end
end, false)

RegisterKeyMapping('+weapon_selection', 'Weapon Selection', 'keyboard', 'TAB')

--clothings

RegisterNUICallback('toggleClothing', function(data)
	loadClothes(data.type, data.type2, data.status, Config.Clothing[data.type].skin)
end)

RegisterNUICallback('resetClothing', function()
	resetClothes()
end)

RegisterNetEvent('panama_skin:updateStatus')
AddEventHandler('panama_skin:updateStatus', function(current)
	lastSkin = current
	getEquippedStatus()
end)

function saveCurrentSkin()
	TriggerEvent('skinchanger:getSkin', function(current)
		lastSkin = current
		getEquippedStatus()
	end)
end

function loadClothes(type, type2, status, table)
	local skin = lastSkin
	if equipped[type] then
		playEmote(Config.Clothing[type]['emote'])
		local st = nil
		TriggerEvent('skinchanger:getSkin', function(current)
			TriggerEvent('skinchanger:loadClothes', current, table)
		end)
		equipped[type] = false
		SendNUIMessage({action = 'refreshClothing', equipped = equipped})
		refreshPedScreen()
	else
		if lastSkin[type] == Config.Clothing[type]['min'] then 
			TriggerEvent('panama_notifikacije:sendNotification', 'fas fa-user', 'Nemate ovaj item', 3000)
		else 
			playEmote(Config.Clothing[type]['emote'])
			local newSkin = {}
			newSkin[type], newSkin[type2] = skin[type], skin[type2]
			TriggerEvent('skinchanger:getSkin', function(current)
				TriggerEvent('skinchanger:loadClothes', current, newSkin)
			end)
			equipped[type] = true
			SendNUIMessage({action = 'refreshClothing', equipped = equipped})
			refreshPedScreen()
			Wait()
		end
	end
end

function resetClothes()
	playEmote(Config.Clothing['reset']['emote'])
	TriggerEvent('skinchanger:loadClothes', lastSkin, lastSkin)
	getEquippedStatus()
	SendNUIMessage({action = 'refreshClothing', equipped = equipped})
	refreshPedScreen()
end

function getEquippedStatus()
	if lastSkin == nil then return end
	for k,v in pairs(lastSkin) do
		if Config.Clothing[k] then
			if lastSkin[k] == Config.Clothing[k]['min'] then
				equipped[k] = false
			else
				equipped[k] = true
			end
		end
	end
	SendNUIMessage({action = 'refreshClothing', equipped = equipped})
end

local isEmoted = true

function playEmote(e)
	if isEmoted then
		isEmoted = false
		local Ped = PlayerPedId()
		while not HasAnimDictLoaded(e.dict) do RequestAnimDict(e.dict) Wait(100) end
		if IsPedInAnyVehicle(Ped) then e.move = 51 end
		TaskPlayAnim(Ped, e.dict, e.anim, 3.0, 3.0, e.dur, e.move, 0, false, false, false)
		local Pause = e.dur-500 if Pause < 500 then Pause = 500 end
		Wait(Pause) 
		isEmoted = true
	end
end