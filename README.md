# Crystal Rush

Crystal Rush is a fast-paced shard collecting adventure built for Roblox. Players sprint between procedurally generated crystal zones, scoop up energy orbs, and return to base to convert them into spendable Energy. Use Energy to upgrade backpack capacity, speed, converter multiplier, unlock new biomes, and rebirth for permanent multipliers.

## Core Features

- **Dynamic world building** – The map is generated at runtime with teleport pads, return portals, and orb spawners for every zone.
- **Intuitive progression loop** – Collect orbs, deposit for Energy, upgrade stats, and unlock harder zones with better shard payouts.
- **Orb rarity system** – Every zone has a chance to spawn rare shards worth significantly more Energy.
- **Boost & rebirth support** – Time-limited converter boosts and repeatable rebirth prestige keep progression lively.
- **Responsive UI** – Live stats, upgrade buttons, tutorial prompts, notifications, and an in-game shop are all rendered entirely with scripts.

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
- Hyper Sprint and Auto Collector include toggle buttons in the HUD for quick control.

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
│       └── UpgradeService.lua
└── StarterPlayer
    └── StarterPlayerScripts
        └── ClientController.client.lua
```

Deploy with Rojo or sync directly into Studio and publish to make Crystal Rush playable.
