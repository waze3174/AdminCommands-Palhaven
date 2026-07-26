# Palworld Admin Commands Guides
> You can find Pals, NPC and Item asset names on my [Paldeck](https://paldeck.cc/)

## How to add admins?
The mod uses both `/adminpassword` as authentication and has its own admin whitelist.
1. Head in-game and hit escape. You will see the player's name on the `Player List`.
2. Right click that players's name and click `Copy PlayerID`.
3. Edit the `config.lua` and paste the player's PlayerID into the `config.adminUIDs` field;
```lua
config.adminUIDs = {
    "12345678000000000000000000000000",
    "43214234000000000000000000000000"
}
```

## How to make commands available to all players?
1. Navigate to the `AdminCommands/Scripts/libs` folder and open the `handler.lua`.
2. Find the desired command and change `admin = true` to `admin = false`.
That's it!

## How to spawn or capture pals?
> Pal asset names can be copied from the [Paldeck](https://paldeck.cc/pals)
Spawning pals requires utilizing their internal asset names. Just navigate the pals page and copy their asset name.

Example of spawning a level 10 Depresso:
```
!spawn NegativeKoala 10
```

Example of spawning a level 10 Shiny Depresso:
```
!spawn NegativeKoala 10 true
```

Example of auto catching level 15 Kingpaca Cryst:
```
!catch KingAlpaca_Ice 15
```

## How to give items to myself or others?
> Item asset names can be copied from the [Paldeck](https://paldeck.cc/items)
Spawning items uses the asset names provided on the website.

Example of giving a player Katana and 10 Mega Spheres.
```
!give Caffeine Katana:1 PalSphere_Mega:10
```

Example of giving yourself Advanced Shield and 10 Baked Berries.
```
!give Baked_Berries:10 Shield_SF:1
```