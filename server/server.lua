ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback("panama_inventar:getPlayerInventory", function(source, cb, target)
		local targetXPlayer = ESX.GetPlayerFromId(target)

		if targetXPlayer ~= nil then
			cb({inventory = targetXPlayer.inventory, money = targetXPlayer.getMoney(), accounts = targetXPlayer.accounts, weapons = targetXPlayer.loadout})
		else
			cb(nil)
		end
	end
)

RegisterServerEvent('panama_inventar:removeMoney')
AddEventHandler('panama_inventar:removeMoney', function(source, account, num) 
	local _source = source
	if account == 'money' then
		local _source = source
		local targetXPlayer = ESX.GetPlayerFromId(_source)
		if targetXPlayer.getMoney() - num >= 0 then
			targetXPlayer.removeAccountMoney(account, num)
		else 
			TriggerClientEvent('panama_notifikacije:sendNotification', _source, 'fas fa-user', 'Nemate dovoljno novca', 3000)
		end
	elseif account == 'black_money' then
		local _source = source
		local targetXPlayer = ESX.GetPlayerFromId(_source)
		if targetXPlayer.getMoney() - num >= 0 then
			targetXPlayer.removeAccountMoney(account, num)
		else 
			TriggerClientEvent('panama_notifikacije:sendNotification', _source, 'fas fa-user', 'Nemate dovoljno novca', 3000)
		end
	end
end)
