# Material planner

The planner (`Core/Planner.lua`) picks the next craft for each tracked profession, counts
materials and estimates how many crafts a skill range takes. It only reads. It never
crafts, buys, sells, destroys or disenchants items.

## Skill-up chance

A craft does not always give a skill point. The planner uses the best information it
has, in this order, and every result carries its basis so the dashboard can say how sure
it is:

| Basis | Source | Shown as |
|---|---|---|
| `client` | Difficulty color the client reported at your current skill | chance from your client |
| `thresholds` | Recipe skill levels marked verified | chance from verified skill levels |
| `thresholds-unverified` | Recipe skill levels that are a fallback | estimate from unverified skill levels |
| `client-stale` | Difficulty read at a lower skill | rough |
| `unknown` | Nothing known | skill-up chance unknown until you open the profession window |

With skill levels `{ orange, yellow, green, grey }` the chance at skill `s` is 1 below
yellow, 0 at grey and above, and `(grey - s) / (grey - yellow)` in between. This is the
commonly used estimate for the classic game and is not verified for Forever.

With only a client color, the planner uses rough values: orange 1, yellow 0.75,
green 0.25, grey 0. With nothing known it suggests a batch of 5 crafts and asks you to
open the profession window so it can re-check.

## Expected crafts

For a skill range the planner adds `1 / chance` for each skill point. Example: Bolt of
Linen Cloth from 25 to 27 is about 2.04 crafts, not 2. The dashboard rounds up and the
estimate is labeled.

A recommendation takes a recipe until its chance drops below 50 percent, 10 points, or
your cap, whichever comes first.

## Choosing a recipe

Usable recipes are learned ones, or recipes the client has not reported as unlearned
yet, whose skill requirement you meet and which can still give skill. Among those the
planner prefers a sure skill-up, then recipes you can make now, then recipes the client
confirmed you know. Detours and reminders only consider recipes you can make right now.

## Materials

For each recommended recipe the planner lists, per reagent:

- required (quantity per craft x crafts)
- owned (bags, plus the bank when "Count bank items" is on)
- missing

Reagents come from the client when it has reported them for that recipe, otherwise from
the data pack, and the dashboard says which.

If a missing reagent is made by the same profession (Bolt of Linen Cloth from Linen
Cloth), the row shows what it takes to make the missing amount. That breakdown goes one
level deep.

## Reserving materials across steps

The dashboard shows a two-step plan. Materials promised to the first step count as used
for the second, so later steps show what is really left. This is the basis for reserving
materials for upcoming recipes.

## Reminders

With reminders on, Pathwise prints one line when you newly have materials for a craft
that still gives skill, for example "Tailoring: you have materials for 5 x Bolt of Linen
Cloth." It does not repeat until the recipe changes or you run out and get materials again.

## Planned, not built yet

- Disenchanting suitable equipment and reusing the resulting materials (Tailoring plus
  Enchanting).
- Comparing alternative crafting paths and material costs.
- Auction House prices.

These need verified data and will build on the same material rows and reservations.
