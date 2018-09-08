local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}


ESX                           = nil
local GUI      = {}
local PlayerData                = {}
local lastVehicle = nil
local lastOpen = false
GUI.Time                      = 0
local vehiclePlate = {}
local arrayWeight = Config.localWeight

function getItemyWeight(item)
  local weight = 0
  local itemWeight = 0

  if item ~= nil then
	   itemWeight = Config.DefaultWeight
	   if arrayWeight[item] ~= nil then
	        itemWeight = arrayWeight[item]
	   end
	end
  return itemWeight
end


Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  	PlayerData = xPlayer
    TriggerServerEvent("esx_truck_inventory:getOwnedVehicule")
end)

RegisterNetEvent('esx_truck_inventory:setOwnedVehicule')
AddEventHandler('esx_truck_inventory:setOwnedVehicule', function(vehicle)
    vehiclePlate = vehicle
end)

function VehicleInFront()
    local pos = GetEntityCoords(GetPlayerPed(-1))
    local entityWorld = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 4.0, 0.0)
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, GetPlayerPed(-1), 0)
    local a, b, c, d, result = GetRaycastResult(rayHandle)
    return result
end

function VehicleMaxSpeed(vehicle,weight,maxweight)
  local percent = (weight/maxweight)*100
  local hashk= GetEntityModel(vehicle)
  print('poid '..weight)
  print('max '..maxweight)
  print('perc'..percent)
  if percent > 80  then
    print('slow')
    SetEntityMaxSpeed(vehFront,GetVehicleModelMaxSpeed(hashk)/1.4)
  elseif percent > 50 then
    print('medium')
    SetEntityMaxSpeed(vehFront,GetVehicleModelMaxSpeed(hashk)/1.2)
  else
    print('full')
    SetEntityMaxSpeed(vehFront,GetVehicleModelMaxSpeed(hashk))
  end
end

-- Key controls
Citizen.CreateThread(function()
  while true do

    Wait(0)

    if IsControlPressed(0, Keys["L"]) then
		local vehFront = VehicleInFront()
		local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
		local closecar = GetClosestVehicle(x, y, z, 4.0, 0, 71)
		if vehFront > 0 and closecar ~= nil and GetPedInVehicleSeat(closecar, -1) ~= GetPlayerPed(-1) then
			local targa = GetVehicleNumberPlateText(vehFront)
			ESX.TriggerServerCallback('esx_truck_inventory:TrunkStatus', function(IsTrunkOpen)
				if (not IsTrunkOpen) then
					lastVehicle = vehFront
					local model = GetDisplayNameFromVehicleModel(GetEntityModel(closecar))
					local locked = GetVehicleDoorLockStatus(closecar)
					local class = GetVehicleClass(vehFront)
					TriggerServerEvent('esx_truck_inventory:OpenTrunk', targa)
					ESX.UI.Menu.CloseAll()
					if ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'inventory') then
						SetVehicleDoorShut(vehFront, 5, false)
					else
						if locked == 1 or class == 15 or class == 16 or class == 14 then
							SetVehicleDoorOpen(vehFront, 5, false, false)
							ESX.UI.Menu.CloseAll()
							TriggerServerEvent('esx_truck_inventory:getInventory', targa)
						else
							ESX.ShowNotification('This trunk is ~r~closed')
						end
					end
				else 
					ESX.ShowNotification('~r~This trunk is already opened by another person!')
				end
			end, targa)
		else
			ESX.ShowNotification('No ~r~vehicles~w~ nearby')
		end
		lastOpen = true
		GUI.Time  = GetGameTimer()
	elseif lastOpen and IsControlPressed(0, Keys["BACKSPACE"]) then
      lastOpen = false
      ESX.UI.Menu.CloseAll()
      if lastVehicle > 0 then
      	SetVehicleDoorShut(lastVehicle, 5, false)
		TriggerServerEvent("esx_truck_inventory:CloseTrunk", GetVehicleNumberPlateText(lastVehicle))
      	lastVehicle = 0
      end
      GUI.Time  = GetGameTimer()
    end
  end
end)

RegisterNetEvent('esx_truck_inventory:getInventoryLoaded')
AddEventHandler('esx_truck_inventory:getInventoryLoaded', function(inventory,weight)
	local elements = {}
  print(weight)
	local vehFrontBack = VehicleInFront()
  TriggerServerEvent("esx_truck_inventory:getOwnedVehicule")

	table.insert(elements, {
      label     = 'Deposit',
      count     = 0,
      value     = 'deposit',
    })

	if inventory ~= nil and #inventory > 0 then
		for i=1, #inventory, 1 do
		if inventory[i].type == 'item_standard' then
		      table.insert(elements, {
		        label     = inventory[i].label .. ' x' .. inventory[i].count,
		        count     = inventory[i].count,
		        value     = inventory[i].name,
				type	  = inventory[i].type
		      })			
			elseif inventory[i].type == 'item_weapon' then
			  table.insert(elements, {
				label     = inventory[i].label .. ' | munitions: ' .. inventory[i].count,
				count     = inventory[i].count,
				value     = inventory[i].name,
				type	  = inventory[i].type
			  })	
			elseif inventory[i].type == 'item_account' then
			  table.insert(elements, {
				label     = inventory[i].label .. ' [ $' .. inventory[i].count..' ]',
				count     = inventory[i].count,
				value     = inventory[i].name,
				type	  = inventory[i].type
			  })	
			end
		end
	end
	
	ESX.UI.Menu.Open(
	  'default', GetCurrentResourceName(), 'inventory_deposit',
	  {
	    title    = 'Trunk Inventory',
	    align    = 'bottom-right',
	    elements = elements,
	  },
	  function(data, menu)
	  	if data.current.value == 'deposit' then
	  		local elem = {}
	  		PlayerData = ESX.GetPlayerData()
			for i=1, #PlayerData.accounts, 1 do
				if PlayerData.accounts[i].name == 'black_money' then
				  -- if PlayerData.accounts[i].money > 0 then
				    table.insert(elem, {
				      label     = PlayerData.accounts[i].label .. ' [ $'.. math.floor(PlayerData.accounts[i].money+0.5) ..' ]',
				      count     = PlayerData.accounts[i].money,
				      value     = PlayerData.accounts[i].name,
				      name      = PlayerData.accounts[i].label,
					  limit     = PlayerData.accounts[i].limit,
					  type		= 'item_account',
				    })
				  -- end
				end
			end
			
			for i=1, #PlayerData.inventory, 1 do
				if PlayerData.inventory[i].count > 0 then
				    table.insert(elem, {
				      label     = PlayerData.inventory[i].label .. ' x' .. PlayerData.inventory[i].count,
				      count     = PlayerData.inventory[i].count,
				      value     = PlayerData.inventory[i].name,
				      name      = PlayerData.inventory[i].label,
					  limit     = PlayerData.inventory[i].limit,
					  type		= 'item_standard',
				    })
				end
			end
			
		local playerPed  = GetPlayerPed(-1)
		local weaponList = ESX.GetWeaponList()

		for i=1, #weaponList, 1 do

		  local weaponHash = GetHashKey(weaponList[i].name)

		  if HasPedGotWeapon(playerPed,  weaponHash,  false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
			local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
			table.insert(elem, {label = weaponList[i].label .. ' [' .. ammo .. ']',name = weaponList[i].label, type = 'item_weapon', value = weaponList[i].name, count = ammo})
		  end

		end

		ESX.UI.Menu.Open(
			  'default', GetCurrentResourceName(), 'inventory_player',
			  {
			    title    = 'Your Inventory',
			    align    = 'bottom-right',
			    elements = elem,
			  },function(data3, menu3)
				ESX.UI.Menu.Open(
				  'dialog', GetCurrentResourceName(), 'inventory_item_count_give',
				  {
				    title = 'Quantity'
				  },
				  function(data4, menu4)
            local quantity = tonumber(data4.value)
            local Itemweight =tonumber(getItemyWeight(data3.current.value)) * quantity
            local totalweight = tonumber(weight) + Itemweight
            vehFront = VehicleInFront()

            local typeVeh = GetVehicleClass(vehFront)

            if totalweight > Config.VehicleLimit[typeVeh] then
              max = true
            else
              max = false
            end



            --test
--[[
            local quantity = tonumber(data4.value)
            qte=0
            print (data3.current.value)
            if inventory ~= nil and #inventory > 0 then
              for i=1, #inventory, 1 do
                if inventory[i].name == data3.current.value then
                  qte = tonumber(inventory[i].count) + quantity
          		  end
          		end
          	end
            if qte==0 then
              qte = quantity
            end
            local typeVeh = GetVehicleClass(vehFront)
            print('type : '..typeVeh)
            if qte > (tonumber(data3.current.limit)*2) and data3.current.limit ~= -1 then
              max =true
            else
              max = false
            end
]]
            ownedV = 0
            while vehiclePlate == '' do
              Wait(1000)
            end
            for i=1, #vehiclePlate do
              if vehiclePlate[i].plate == GetVehicleNumberPlateText(vehFront) then
                ownedV = 1
                break
              else
                ownedV = 0
              end
            end

            --fin test

            if quantity > 0 and quantity <= tonumber(data3.current.count) and vehFront > 0  then
              local MaxVh =(tonumber(Config.VehicleLimit[typeVeh])/1000)
              local Kgweight =  totalweight/1000
              if not max then
              	local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
  				    	local closecar = GetClosestVehicle(x, y, z, 4.0, 0, 71)

              --  VehicleMaxSpeed(closecar,totalweight,Config.VehicleLimit[GetVehicleClass(closecar)])

  				    TriggerServerEvent('esx_truck_inventory:addInventoryItem', GetVehicleClass(closecar), GetDisplayNameFromVehicleModel(GetEntityModel(closecar)), GetVehicleNumberPlateText(vehFront), data3.current.value, quantity, data3.current.name, data3.current.type,ownedV)
                ESX.ShowNotification('Total Weight : ~g~'.. Kgweight .. ' Kg / '..MaxVh..' Kg')
              else
                ESX.ShowNotification('Max weight reached:  ~r~ '..MaxVh..' Kg')
              end
				    else
			      		ESX.ShowNotification('~r~ Invalid Quantity')
				    end

		                    TriggerServerEvent("esx_truck_inventory:CloseTrunk", GetVehicleNumberPlateText(vehFront))
				    ESX.UI.Menu.CloseAll()


				  end,
				  function(data4, menu4)
		            SetVehicleDoorShut(vehFrontBack, 5, false)
				    ESX.UI.Menu.CloseAll()
			            TriggerServerEvent("esx_truck_inventory:CloseTrunk", GetVehicleNumberPlateText(vehFront))
				  end
				)
			end)
	  	else
			ESX.UI.Menu.Open(
			  'dialog', GetCurrentResourceName(), 'inventory_item_count_give',
			  {
			    title = 'Quantity'
			  },
			  function(data2, menu2)

			    local quantity = tonumber(data2.value)
          PlayerData = ESX.GetPlayerData()
			    vehFront = VehicleInFront()

          --test
          local Itemweight =tonumber(getItemyWeight(data.current.value)) * quantity
          local poid = weight - Itemweight



          for i=1, #PlayerData.inventory, 1 do

            if PlayerData.inventory[i].name == data.current.value then
              if tonumber(PlayerData.inventory[i].limit) < tonumber(PlayerData.inventory[i].count) + quantity and PlayerData.inventory[i].limit ~= -1 then
                max = true
              else
                max = false
              end
            end
          end

          --fin test


			    if quantity > 0 and quantity <= tonumber(data.current.count) and vehFront > 0 then
            if not max then
              --  VehicleMaxSpeed(vehFront,poid,Config.VehicleLimit[GetVehicleClass(vehFront)])
               TriggerServerEvent('esx_truck_inventory:removeInventoryItem', GetVehicleNumberPlateText(vehFront), data.current.value, data.current.type, quantity)
			   local typeVeh = GetVehicleClass(vehFront)
			   local MaxVh =(tonumber(Config.VehicleLimit[typeVeh])/1000)
			   local Itemweight =tonumber(getItemyWeight(data.current.value)) * quantity
			   local totalweight = tonumber(weight) - Itemweight
			   local Kgweight =  totalweight/1000
			   ESX.ShowNotification('Total Weight : ~g~'.. Kgweight .. ' Kg / '..MaxVh..' Kg')

            else
              ESX.ShowNotification('~r~ Too much weight')
            end
			    else
			      ESX.ShowNotification('~r~ Invalid Quantity')
			    end

			    ESX.UI.Menu.CloseAll()
			    TriggerServerEvent("esx_truck_inventory:CloseTrunk", GetVehicleNumberPlateText(vehFront))

	        	local vehFront = VehicleInFront()
	          	if vehFront > 0 then
	          		ESX.SetTimeout(1500, function()
	              		TriggerServerEvent("esx_truck_inventory:getInventory", GetVehicleNumberPlateText(vehFront))
	          		end)
	            else
	              SetVehicleDoorShut(vehFrontBack, 5, false)
	            end
			  end,
			  function(data2, menu2)
		            TriggerServerEvent("esx_truck_inventory:CloseTrunk", GetVehicleNumberPlateText(vehFront))
	            SetVehicleDoorShut(vehFrontBack, 5, false)
			    ESX.UI.Menu.CloseAll()
			  end
			)
	  	end
	  end)
end)

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
