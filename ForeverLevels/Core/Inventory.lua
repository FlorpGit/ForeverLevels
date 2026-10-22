-- ForeverLevels: item counts for the material planner.
-- C_Item.GetItemCount(item, includeBank) is in Forever's ItemDocumentation.
-- Bags change in bursts, so BAG_UPDATE_DELAYED is merged into one INVENTORY_CHANGED.
-- This module only reads counts. It never moves, sells, destroys or disenchants items.

local _, FL = ...

local Inventory = {}
FL.Inventory = Inventory

function Inventory.Count(itemID)
	local includeBank = FL.db and FL.db.profile.professions.countBank or false
	return C_Item.GetItemCount(itemID, includeBank) or 0
end

FL:RegisterEvent("BAG_UPDATE_DELAYED", function()
	FL:Debounce("INVENTORY_CHANGED", 0.3, function() FL:Fire("INVENTORY_CHANGED") end)
end)
