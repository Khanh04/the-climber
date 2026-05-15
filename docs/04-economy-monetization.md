# Module 4: Economy and Monetization

## Owner

Economy Balancer / UI and UX Programmer

## Goal

Create a progression and monetization layer that rewards risk, preserves fairness, and avoids intrusive ad patterns.

## MVP Scope

- Normal coins bank immediately on pickup.
- Special bonus coin stacks provide risk/reward physics chaos without threatening already-banked coins.
- Rewarded Continue, Post-run Coin Doubler, and Pre-run Vending Machine are the only MVP ad placements.
- Supporter subscription grants daily coins and removes future ad friction, but does not grant unlimited free rescues or boosters.

## Core Requirements

### Coins

- Coins spawn through the daily seed system.
- They should appear in high-risk spaces such as near crumbling ledges or close to the Chaser.
- Coins are physical objects.
- Normal coins are banked immediately on pickup.
- Special bonus coin stacks can be carried as high-risk objects.
- If the player collides with a ledge while carrying a special coin stack, the stack scatters.
- Scattered special-stack coins must be recoverable mid-air.

### Ads

- Only rewarded ads are allowed.
- No forced pop-up ads.
- No hard retry gate: players must always be able to start the next run without watching an ad.
- Rewarded Continue: after a fall, the player can watch an ad to trigger the same rescue mechanic used by the Mulligan Drone.
- Post-run option: watch an ad to double collected coins.
- Pre-run option: watch an ad for a free random consumable booster.

### Store

#### Real Money Offers

- Coin bundles.
- Supporter Pack subscription that grants players a free daily coin reward and removes any future non-reward ad friction.
- The subscription can also include premium cosmetics such as a VIP Crown.
- Supporter does not automatically convert every rewarded-ad placement into a free claim unless a specific reward is explicitly included in the subscription benefit table.

#### Permanent Cosmetic Sinks

- Ragdoll skins.
- Chaser themes.
- Audio / impact packs.
- Grab trails.
- Fall sprays.

#### Single-Run Consumables

- Cannonball Start: skip the first 50 meters.
- Chalk Bag: grant +20% stamina for the current run.
- Mulligan Drone: inventory version of the shared rescue mechanic; saves the player from one eligible fall per run.

## Implementation Notes

### Fairness Rules

- Permanent cosmetics must stay gameplay-neutral.
- Consumables affect convenience or survivability but should be balanced carefully to avoid pay-to-win perception.
- Rewarded ads should always be optional and clearly explained before activation.
- Subscription benefits must not provide gameplay stat advantages beyond economy acceleration.
- Ad rewards should convert frustration into optional recovery or bonuses, not block the core retry loop.
- There are no global leaderboards in MVP, so monetized boosts are balanced around fun, retention, and perceived fairness rather than competitive ranking.

### Economy Hooks

- Coin placement should reward route risk and player expression.
- Coin scatter should create recoverable chaos rather than pure loss.
- Normal pickup coins should bank immediately so players do not feel punished twice for failed runs.
- Track separate balances for hard currency and owned cosmetics if the system grows beyond coins.

### Store Structure

- Group catalog items by theme and function rather than only by price.
- Surface run-scoped consumables separately from permanent unlocks.
- Keep the Supporter Pack clearly distinct from consumables to avoid confusion.
- Define the Supporter Pack as a recurring subscription product, not a one-time unlock.
- The current Phase 10 store shell uses a typed `CosmeticItemCatalog` for permanent player body, hand, and Chaser theme unlocks.
- Coin cosmetic unlocks spend wallet coins through persistent purchase transactions, then persist owned cosmetic ids and equipped loadout fields in save schema v4.
- Store UI dispatches item selection, purchase, equip, and close signals; `RunScene` coordinates wallet, inventory, loadout, persistence, and visual application.

### Initial Balance Targets

- Rewarded Continue: maximum once per run, shared with Mulligan Drone.
- Post-run Coin Doubler: available once per completed run summary.
- Pre-run Vending Machine: maximum once before a run starts.
- Special coin stack scatter: cap active scattered coin bodies and despawn or magnetize leftovers quickly on mobile.
- Supporter daily coin reward: exact amount is still open, but should feel useful without replacing normal play.

### Rewarded Ad Placements

- Rewarded Continue appears only after a valid fall or run-ending mistake, and grants one immediate rescue for that run.
- Rewarded Continue and Mulligan Drone share the same rescue limit and should not stack in the same run unless explicitly rebalanced later.
- The current Phase 9 slice routes Rewarded Continue through the typed rewarded-ads adapter boundary and the shared `RunSession.consume_rescue()` flow.
- The current Rewarded Continue implementation restores full stamina, snaps the player back onto a valid handhold pair in the current loaded route window, and grants no coins.
- If a requested Rewarded Continue ad is unavailable, cancelled, or fails, the rescue prompt remains active and restart stays available.
- Post-run Coin Doubler appears on the run summary screen and doubles coins already banked from pickups.
- The current Post-run Coin Doubler implementation remains a separate once-per-summary ad reward and does not consume the shared rescue limit.
- Pre-run Vending Machine appears before starting a run and grants one random single-run consumable booster.
- Ad placements should be frequency-capped and suppressed after recent ad watches to avoid fatigue.

### Mobile Purchase Requirements

- Support restore purchases, receipt validation, subscription expiry, refund handling, and offline grace behavior before launch.
- Daily Supporter coin claims should reset on a defined server or UTC cadence, not local device clock alone.

## Post-MVP

- More consumables after the core climb remains fun without boosts.
- Additional cosmetic categories such as premium fall sprays and impact packs.
- More advanced subscription perks that stay cosmetic or economy-only.

## Open Questions

- What is the first-pass coin reward target per minute of play?
- What should the Supporter daily coin amount be?
- Should Cannonball Start ship in MVP, or wait until the first 50 meters become repetitive?
- Should special coin stacks bank only when collected, at run end, or after surviving a short carry timer?

## Risks

- Consumables can make the core climb feel boost-dependent if they are too strong or too frequent.
- Physics-based coin scatter may be fun but can become frustrating if pickup recovery is too punishing.
- A daily free-coin subscription reward must be tuned so it improves retention without destabilizing the coin economy.
- Rewarded Continue can reduce stakes if it is too common or stackable.

## Suggested First Tasks

1. Define economy data models for currency, cosmetics, and consumables.
2. Prototype seeded coin spawning and coin scatter behavior.
3. Design rewarded-ad entry points for Continue, Coin Doubler, and Pre-run Vending Machine.
4. Define the shared rescue mechanic used by Rewarded Continue and Mulligan Drone.
5. Draft the first store taxonomy and pricing framework.
