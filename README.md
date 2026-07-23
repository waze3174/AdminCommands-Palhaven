# Palworld Admin Commands
This is an admin mod for Palworld dedicated servers. Its still in early development and coded to be cleaner than the original obfuscated mod.

## Commands

All commands use the `!` prefix in-game. This can be changed in the `config/config.lua`.

### Admin Commands
| Command | Usage | Description |
|---------|-------|-------------|
| `!ban` | `!ban <player> [reason]` | Bans a player from the server and disconnects them. |
| `!unban` | `!unban <UID>` | Removes a player UID from the ban list. |
| `!kick` | `!kick <player> [reason]` | Kicks a player from the server. |
| `!fly` | `!fly enable` / `!fly disable` | Toggles fly mode for yourself. |
| `!goto` | `!goto <x> <y> <z>` or `!goto <player>` | Teleports you to coordinates or to another player. |
| `!getpos` | `!getpos` or `!getpos <player>` | Shows your current position or another player's position. |
| `!bring` | `!bring <player>` | Teleports a player to your location. |
| `!bringall` | `!bringall` | Teleports all other players to your location. |
| `!spawn` | `!spawn <PalName> <level> [shiny]` | Spawns a Pal near you at the given level. Pass `true` for shiny. |
| `!catch` | `!catch <PalName> <level> [shiny]` | Spawns a Pal and automatically captures it. Pass `true` for shiny. |
| `!give` | `!give <player> <item>:<amount> <item2>:<amount>` | Gives items to a target player. If no player name is given, gives to yourself. |
| `!giveme` | `!giveme <item>:<amount> <item2>:<amount>` | Gives items directly to yourself. |
| `!freeze` | `!freeze <player>` | Freezes a player in place, preventing all movement. |
| `!unfreeze` | `!unfreeze <player>` | Unfreezes a previously frozen player. |
| `!settime` | `!settime <hour>` | Sets the in-game time (0–23). |
| `!announce` | `!announce <message>` | Broadcasts a server-wide announcement to all players. |

### Player Commands
| Command | Usage | Description |
|---------|-------|-------------|
| `!unstuck` | `!unstuck` | Teleports yourself to a safe point. |
| `!time` | `!time` | Displays the current in-game time. |

## Licensing
If you wish to use the code in your projects just provide credit, that's all I ask.

## Pull Requests
This project is open to pull requests and code contributions.

### Contributing AI Code
I do not mind you utilizing AI to implement code to this project. Just make sure it respects the code structure, code implementation and that the code is functional and tested.

## Credits
> People who have helped me with various aspects of this project in the past.
- Okaetsu
- Sharkey
- Mathayus