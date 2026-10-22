-- ForeverLevels: startup. Loaded last so every module and bundled route is registered.

local addonName, FL = ...

FL:RegisterEvent("ADDON_LOADED", function(_, name)
	if name == addonName then
		FL:InitDatabase()
	end
end)

FL:RegisterEvent("PLAYER_LOGIN", function()
	-- All non-load-on-demand addons (including community route packs) are loaded now.
	FL:UpdatePlayer()
	FL.Sync:Init()
	FL.GuideFrame:Create()
	FL.Arrow:Create()
	FL.Options:Create()

	if not FL:IsForeverClient() then
		FL:Print("|cffffcc55warning:|r this client does not report itself as World of Warcraft: Forever. ForeverLevels targets Forever only.")
	end

	FL.Engine:AutoSelectRoute()
	FL.GuideFrame:Update()
end)
