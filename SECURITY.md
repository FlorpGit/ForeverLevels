# Security

Pathwise is a World of Warcraft addon: it runs inside the game client,
reads game state and shows guidance. It sends no network traffic. The only
messages it sends are party sync's addon messages to your group, and only
when you turn party sync on.

It acts for you only where you ask it to, at a window you opened:

- At a quest giver you talk to, it accepts and hands in the quests your
  route uses (on by default; hold Shift to skip it once, or turn it off in
  Settings). It never chooses a quest reward and never hands in a quest
  that costs gold.
- Pathwise Bags sells junk at a vendor when you click "Sell junk", or as
  the vendor window opens if you turn "Sell on its own" on. It never sells
  what you mark to keep, quest items you still need, profession materials
  your route needs, or upgrades.

It never buys, mails, trades, deletes or disenchants anything, and never
crafts for you.

If you find something that could harm players (for example a way for a route,
a data pack or a pasted text to run code, or to make the addon act without the
player asking), please report it privately:

- on GitHub, with **Security > Report a vulnerability** on this repository,
- by a direct message to leight_nn on Pathwise's Discord:
  https://discord.gg/hSDjBrG8EK, or
- by email to pathwise.nn@gmail.com.

Please do not open a public issue for it. We will reply as soon as we can
and credit you in the changelog unless you would rather not be named.
