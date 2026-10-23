# Material planner

The planner (`Professions/Planner.lua`) puts numbers on a profession's next
step. The profession route is the plan; the planner works out how sure a
skill-up is, how many crafts a skill range takes, which materials those crafts
use, the next rank to train and recipes to learn. With no open craft in the
route, it recommends one from the recipes Pathwise knows. It only reads: it
never crafts, buys, sells, destroys or disenchants items.

## Skill-up chance

A craft does not always give a skill point. The planner uses the best it has,
in this order, and every result carries its basis so the panel can say how
sure it is:

| Basis | Source | Shown as |
|---|---|---|
| `client` | The colour the profession window showed at your current skill | from your profession window |
| `thresholds` | A pack's skill levels, marked checked | from checked skill levels |
| `thresholds-unverified` | A pack's skill levels kept as a fallback | from skill levels not yet checked on Forever |
| `client-stale` | A colour read at a lower skill | from a colour read at a lower skill |
| `unknown` | Nothing known | not known yet: open the profession window |

With skill levels `{ orange, yellow, green, grey }` the chance at skill `s` is
1 below yellow, 0 at grey and above, and `(grey - s) / (grey - yellow)` in
between: the usual estimate for the classic game, not checked for Forever.
With only a colour, rough values: orange 1, yellow 0.75, green 0.25, grey 0.

## Crafts to a target

For a skill range the planner adds `1 / chance` for each skill point. Bolt of
Linen Cloth from 25 to 27 is about 2.04 crafts, not 2. The route's craft goals
give the target (`untilSkill`) or a number of items to make (`count`); the
panel rounds up and says it is an estimate.

## Materials

For the crafts planned, per reagent: required, owned (bags, and the bank
unless turned off), missing. The reagents are the profession window's when it
has given them, else a pack's or the route's (Recipes.lua). A missing reagent
the same profession makes (Bolt of Linen Cloth from Linen Cloth) shows what it
is made from, one level deep. The panel also lists the materials the route
asks for the whole rank.

## Holding materials back

A plan of several recommendations holds back what the earlier ones use, so
later ones show what is really left (`Planner.Plan`, `Planner.Reserve`).

## Training and recipes to learn

The next rank is the route's next `train` goal above your cap, with what it
asks (character level from the step's `level` goal; skill 50, 125, 200 for
Journeyman, Expert, Artisan as the routes' notes give them) and the nearest
trainer for your side. Without a route, a pack's ranks. Recipes to learn are
the route's open `learn` goals in this rank and packs' trainer recipes the
window says you do not know yet.

## Recommendations without a route step

When the route has no open craft (or no route), the planner picks from every
recipe it knows for the profession: learned, or not known to be unlearned;
your skill allows it; it can still give skill. It prefers a sure skill-up,
then what the bags make, then recipes the window confirmed you know, and takes
a recipe until its chance drops below 50 percent, 10 points, or your cap.

## Reminders

With reminders on, Pathwise prints one line when your bags newly make a
profession's next craft, e.g. "Tailoring: you have materials for 23 Bolt of
Linen Cloth." Not at login, and not again until the craft changes or the
materials run out and come back.
