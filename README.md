# Crystal Cavern Adventure

This repository contains a complete Rojo project for a small Roblox game called **Crystal Cavern Adventure**.
Players explore a procedurally-arranged cavern, collect crystals, and fight stone golems to earn the highest score before the round ends.

## Features

- Automatically generated cavern environment with glowing crystals and ambient effects.
- Round-based gameplay loop with lobby, active round, and post-round celebration phases.
- Dynamic crystal spawning with touch interactions that award score and respawn on timers.
- Stone golem enemies that path toward the nearest player and inflict damage on contact.
- Responsive HUD that shows the current game state, timer, announcements, and live scoreboard.
- Modular server architecture with services for game flow, crystals, and NPC management.

## Project Structure

- `default.project.json` – Rojo project file that maps the folders in `src` to Roblox services.
- `src/ReplicatedStorage/Modules` – Shared modules used by server and client scripts.
- `src/ReplicatedStorage/Assets` – Runtime-created assets such as map builders and templates.
- `src/ServerScriptService` – Server-side logic that orchestrates the game.
- `src/StarterPlayer/StarterPlayerScripts` – Client-side scripts for UI and effects.
- `src/Workspace` – Workspace content generated on the server when the game runs.

## Getting Started

1. Install [Rojo](https://rojo.space/) v7 or later.
2. Open Roblox Studio and start an empty place.
3. Run `rojo serve` from the root of this repository and connect Studio using the Rojo plugin.
4. Press play in Studio to experience the game.

## Customising

- Adjust timings, crystal counts, and spawn locations in `src/ReplicatedStorage/Modules/GameConfig.lua`.
- Tweak NPC speed and behaviour in `src/ServerScriptService/NpcService.lua`.
- Add additional decorations or hazards by editing `MapBuilder` in `src/ReplicatedStorage/Assets/MapBuilder.lua`.

Enjoy exploring the cavern!
