local T = ...

T.Test("TOC: both TOC files are identical", function()
	local a = assert(io.open(T.addonDir .. "/ForeverLevels.toc", "rb")):read("*a")
	local b = assert(io.open(T.addonDir .. "/ForeverLevels_Forever.toc", "rb")):read("*a")
	T.Equal(a, b, "ForeverLevels.toc must match ForeverLevels_Forever.toc")
end)

T.Test("TOC: interface 16001 and SavedVariables declared", function()
	local _, directives = T.ReadToc("ForeverLevels_Forever.toc")
	T.Equal(directives["Interface"], "16001", "Interface")
	T.Equal(directives["SavedVariables"], "ForeverLevelsDB", "SavedVariables")
	T.Equal(directives["SavedVariablesPerCharacter"], "ForeverLevelsCharDB", "SavedVariablesPerCharacter")
end)

T.Test("TOC: every listed file exists, Init first, Boot last", function()
	local files = T.ReadToc("ForeverLevels_Forever.toc")
	for _, file in ipairs(files) do
		local handle = io.open(T.addonDir .. "/" .. file, "r")
		T.True(handle, "missing file listed in TOC: " .. file)
		handle:close()
	end
	T.Equal(files[1], "Core/Init.lua", "Init.lua must load first")
	T.Equal(files[#files], "Core/Boot.lua", "Boot.lua must load last")
end)

T.Test("TOC: addon loads and boots on a Forever client", function()
	local FL = T.Boot()
	T.True(_G.ForeverLevels == FL, "global namespace exported")
	T.True(FL:IsForeverClient(), "detected Forever via WOW_PROJECT_CAMELOT")
	T.True(_G.SlashCmdList.FOREVERLEVELS, "slash command registered")
	T.Equal(T.Stub.Called("RegisterAddonMessagePrefix"), 1, "sync prefix registered once")
end)

T.Test("TOC: warns when not on a Forever client", function()
	T.Boot({ beforeLogin = function() _G.WOW_PROJECT_ID = 1 end })
	T.True(T.ChatContains("does not report itself as World of Warcraft: Forever"), "warning printed")
end)
