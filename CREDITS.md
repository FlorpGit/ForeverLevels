# Credits and sources

Pathwise contains no third-party code, libraries, fonts, images or sounds. Everything in
the addon folder was written for this project.

## Research sources

These were used to check facts. Nothing from them is copied into Pathwise except
individual game facts (IDs, names, quantities), which are not creative works.

- Blizzard Entertainment's UI source and API documentation for World of Warcraft:
  Forever, read through the Gethe/wow-ui-source mirror (forever branch). Used to check
  that every game function Pathwise calls exists, and with which arguments.
  https://github.com/Gethe/wow-ui-source/tree/forever
- Warcraft Wiki, for TOC format and patch API notes. https://warcraft.wiki.gg
- Wowhead's World of Warcraft: Forever database, for profession recipe IDs, reagents
  and trainer names. Each checked fact cites its page in the data files.
  https://www.wowhead.com/forever
- Polestar by fitzforge (GPL-3.0), for two facts from its README: the name of the
  Forever client folder and a gamepad issue with addon slash commands, and to confirm
  that the original Deathknell quest IDs exist on Forever. No Polestar code, text or
  guide data is included. https://github.com/fitzforge/polestar

## Development tools (not distributed)

Lua, luacheck, and the GitHub Actions actions/checkout, leafo/gh-actions-lua and
leafo/gh-actions-luarocks are used for tests and CI only and are not part of the addon.

## Game content

Quest, NPC, item and zone names and IDs belong to Blizzard Entertainment.
World of Warcraft is a trademark of Blizzard Entertainment, Inc. Pathwise is a fan
project and is not affiliated with or endorsed by Blizzard Entertainment.
