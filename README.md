

## Games Supported

| Game | Script | Lines |
|------|--------|-------|
| Rogue Lineage | `ROGUE/rogue_ui.lua` | ~27,000 |
| Rogue Lineage Battlegrounds | `ROGUE_BATTLEGROUNDS/rlb.lua` | ~14,000 |

---

## Rogue Lineage

The flagship module. Full-featured combat, automation, visuals, and botting system.

### Combat
- **Auto Parry** - Automatic perfect blocking with ping adjustment, custom delay, FOV angle, ability-specific parry (Viribus, Owlslash, Shadowrush, Verdien, Grapple), semi-blatant mode
- **Silent Aim** - Adjustable FOV, ignore blocking players, visibility checks
- **Combat Utilities** - No Stun, No Confusion, Perflora Teleport, Attach to Back, Better Mana Charge, Auto Misogi, Anti Backfire, Hold Block

### Visuals
- **Player ESP** - Name, Box, Health bars, Tags, Intent detection, Mana display, Racial identification, Fade with distance
- **Chams** - Player/Friendly/Low Health/Aimbot/Racial chams with pulse effects and occlusion
- **Trinket ESP** - Filterable by type with area labels and range control
- **World ESP** - Ore ESP (Mythril, Copper, Iron, Tin), Ingredient ESP, NPC ESP, Shrieker/Fallion detection
- **Mana Overlay** - Real-time mana visualization
- **Better Leaderboard** - Enhanced player list with additional info

### Automation
- **Trinket Bot** - Fully autonomous trinket farming with path recording, gate traversal, multi-server rotation, emergency escape (player detection, moderator avoidance), smart serverhop logic, loot tracking with Discord webhooks
- **Day Farm** - Automated day progression with player avoidance, moderator detection, dangerous item detection (Pebble/Perflora), configurable range, day goal targeting
- **Auto Pickup** - Auto Trinket, Auto Ingredient, Auto Weapon, Auto Bag (with range visualization), Auto Resurrection
- **Auto Craft** - Automated potion/weapon crafting with configurable delays
- **Macro System** - Record and replay custom action sequences with per-macro toggles
- **Artifact Stream** - Public Discord webhook feed of artifact spawns for community use, separate from personal logging

### Botting
- **Path System** - Record walk paths with gate points, save/load paths, visualize points
- **Smart Serverhop** - Join largest/smallest/oldest/newest servers, server history tracking, persistent configs across hops via MemStorageService
- **Emergency Systems** - Player proximity detection with configurable gate escape or path traversal, moderator detection with multi-encounter tracking, dangerous item detection, shrieker avoidance
- **Loot Tracking** - Per-session item collection with inventory value calculation, Discord webhook reporting on serverhop

### World
- **Freecam** - Detached camera with speed control
- **Environment** - Fullbright, No Fog, Time control, No Blindness/Blur/Sanity effects, Temperature Lock
- **Movement** - Flight, Noclip, Speed Boost, Better Flight, No Fall Damage, No Kill Bricks

### Exploits
- Anti-Globus, Fling, Force Field, Instant Mine, Inn Teleport, AA Bypass
- Character customization (face, clothing, skin, accessories, outfit presets)

---

## Rogue Lineage Battlegrounds

PvP-focused module inheriting Rogue Lineage's combat systems, optimized for arena gameplay.

### Combat
- Auto Parry with all parry settings (ping adjust, FOV, ability-specific, semi-blatant)
- Silent Aim with FOV control
- Full combat utilities (No Stun, No Confusion, Perflora Teleport, Hold Block, Anti Backfire)

### Visuals
- Player ESP with full suite (Name, Box, Health, Tags, Intent, Mana, Racial)
- All chams variants (Player, Friendly, Low Health, Aimbot, Racial)
- Mana Overlay, Better Leaderboard, Shrieker Chams, NPC ESP
- Legit Intent display

### World & Movement
- Freecam, Flight, Noclip, Better Flight
- Fullbright, No Fog, Time control, No Blindness/Blur/Sanity
- Fling, Invisible Cam

### Other
- Full macro system with save/load
- Auto Dialogue, Auto Bard, Anti AFK
- Config management with server join utilities

---
