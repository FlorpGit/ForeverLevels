-- SPDX-License-Identifier: GPL-3.0-only
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

local function ReadAll(path)
	local handle = assert(io.open(path, "rb"))
	local text = handle:read("*a")
	handle:close()
	return text
end

T.Test("License: GPL-3.0 text, notice and addon copy stay in sync", function()
	local gpl = ReadAll(T.root .. "/LICENSE")
	T.True(gpl:find("GNU GENERAL PUBLIC LICENSE", 1, true) and gpl:find("Version 3, 29 June 2007", 1, true), "root LICENSE is GPL-3.0")
	T.True(gpl:find("END OF TERMS AND CONDITIONS", 1, true), "full license text")
	local notice = ReadAll(T.root .. "/NOTICE.md")
	T.True(notice:find("Copyright (C) 2026 The Pathwise Authors", 1, true), "copyright notice")
	T.True(notice:find("Additional permission for data packs", 1, true), "data pack permission")
	T.True(notice:find("section 7(e)", 1, true), "trademark term")
	local shipped = ReadAll(T.addonDir .. "/LICENSE.txt")
	T.Equal(shipped, notice .. "\n\n" .. gpl, "addon LICENSE.txt is NOTICE.md followed by LICENSE")
	local _, directives = T.ReadToc("ForeverLevels_Forever.toc")
	T.Equal(directives["X-License"], "GPL-3.0-only (code), CC BY-SA 4.0 (bundled guide data)", "TOC license line")
end)

T.Test("License: every addon Lua file declares its license", function()
	local files = T.ReadToc("ForeverLevels_Forever.toc")
	for _, file in ipairs(files) do
		local first = ReadAll(T.addonDir .. "/" .. file):match("^[^\n]*")
		local expected = file:find("^Guides/") and "CC%-BY%-SA%-4%.0" or "GPL%-3%.0%-only"
		T.True(first:find("SPDX%-License%-Identifier: " .. expected), file .. ": " .. first)
	end
end)
