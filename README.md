# Pathwise

**Every quest. Every craft. Every level.**

A free, open-source leveling and profession companion for World of Warcraft:
Forever. Created by leight_nn & florp. `_nn`

> Early development. What works today: the Pathwise Signature interface
> (guide window with full and compact modes) and the waypoint arrow. The
> guide engine, routes and profession planning come next.

## Try it

1. Set where your game's AddOns folder is (once), then reopen PowerShell:
   `setx WOW_FOREVER_ADDONS "G:\World of Warcraft\_classic_beta_\Interface\AddOns"`
2. Link the addon into the game: `npm run link`
3. In game:
   - `/pw` shows or hides the guide window
   - `/pw demo` previews it with a sample step
   - `/pw compact` switches full and compact mode
   - `/pw way 45 62 Inn` points the arrow at a spot on your current map (Shift-drag to move the arrow)
   - `/pw opacity 80` sets the window background opacity
   - `/pw help` lists everything

## Develop

Needs Lua 5.1 (`lua5.1`) and Node 24 or newer.

- `npm test` runs the tests (a stub of the game client; nothing here proves
  in-game behaviour)
- `npm run media` redraws the textures in `Pathwise/Media/`

## Licence

GPL-3.0. See `LICENSE` and `THIRD_PARTY.md`.
