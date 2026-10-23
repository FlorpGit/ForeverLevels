-- Pathwise UI: Pathwise's windows (the guide, its side panels and the
-- Feedback Center), the looks, the arrow, map and minimap pins, the minimap
-- buttons, key bindings, the page in the game's Settings window, and the
-- suite API the other Pathwise addons draw with. It ships in the same
-- download as Pathwise, as an addon of its own beside it.
--
-- This first file joins Pathwise's namespace: this addon's private table
-- reads and writes Pathwise's (Pathwise.Core), so every file here uses
-- ns.Engine, ns.Get, ns.On and the rest as Pathwise's own files do, and what
-- they add (ns.Theme, ns.Guide, ns.Panels ...) is where Pathwise looks for it.
--
-- Load order: Pathwise (a dependency) has loaded and fired its LOADED
-- message before this addon's files run, so nothing here listens for it;
-- UI_LOADED, fired when this addon has loaded, is the UI's own.

local ADDON, ui = ...
local core = assert(Pathwise and Pathwise.Core, "Pathwise UI needs Pathwise")

setmetatable(ui, { __index = core, __newindex = core })

core.UI = { addon = ADDON }

core.RegisterEvent("ADDON_LOADED", function(_, name)
	if name == ADDON then core.Fire("UI_LOADED") end
end)
