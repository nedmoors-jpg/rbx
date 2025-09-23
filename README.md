# Crystal Rush

Crystal Rush is a fast-paced shard collecting adventure built for Roblox. Players sprint between procedurally generated crystal zones, scoop up energy orbs, and return to base to convert them into spendable Energy. Use Energy to upgrade backpack capacity, speed, converter multiplier, unlock new biomes, and rebirth for permanent multipliers.

## Core Features

- **Sculpted crystal biomes** – The procedural map now layers platforms, props, fountains, and teleporter portals tailored to each zone theme.
- **Crystal surge events** – Server-driven anomalies periodically supercharge a random zone with faster spawns, brighter lighting, and high-value burst crystals.
- **Combo mastery** – Chain shard pickups to earn temporary deposit bonuses; the HUD surfaces combo timers, rewards, and progress.
- **Intuitive progression loop** – Collect orbs, deposit for Energy, upgrade stats, and unlock harder zones with better shard payouts.
- **Responsive UI** – A refreshed HUD displays milestones, zone progress, active events, boosts, and monetization hooks in a single glance.

## Monetization Hooks

All gamepasses are wired to Roblox `MarketplaceService` IDs and include gameplay effects:

| Pass | ID | Benefit |
| --- | --- | --- |
| VIP | 1476014436 | VIP chat tag & color, +10% deposit bonus, access to the VIP Crystal Boutique |
| Hyper Sprint | 1475776403 | Toggleable +50% walk speed boost |
| Infinite Storage | 1476396573 | Removes backpack capacity limit |
| Lucky Aura | 1476674539 | +20% luck to upgrade shards into rare versions |
| Auto Collector | 1475412430 | Toggleable vacuum that picks up nearby shards |

- The shop UI can prompt both gamepass purchases and developer product sales (energy packs and boosts).
- VIP owners unlock an Energy-based VIP boutique that grants timed converter boosts.
- Hyper Sprint and Auto Collector include stylised HUD toggles with live ownership states.

## Dynamic Events & Combos

- **Crystal Surge** and **Prismatic Bloom** events rotate automatically, increasing orb density, value, and visuals for a highlighted zone.
- Event timers, zone names, and descriptions are broadcast through an animated banner so players can react instantly.
- Every shard pickup feeds a combo meter that rewards sustained runs with deposit multipliers; the meter expires if players slow down.

## Controls & Flow

1. Run across the active zone to gather glowing orbs.
2. Watch your inventory and deposit on the golden pad to bank Energy.
3. Spend Energy on upgrades or zone unlocks via the left-side HUD buttons.
4. Rebirth after clearing all zones for permanent multipliers and bonus starting Energy.
5. Purchase boosts or passes from the Crystal Shop (top right) to accelerate progression.

## Project Structure

The repository is Rojo-friendly and mirrors Roblox services:

```
src/
├── ReplicatedStorage
│   └── Shared
│       └── Config.lua
├── ServerScriptService
│   ├── GameInit.server.lua
│   └── Modules
│       ├── ChatEffects.lua
│       ├── MapBuilder.lua
│       ├── Monetization.lua
│       ├── OrbManager.lua
│       ├── Remotes.lua
│       ├── SessionService.lua
│       ├── UpgradeService.lua
│       └── EventService.lua
└── StarterPlayer
    └── StarterPlayerScripts
        └── ClientController.client.lua
```


