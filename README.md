# RealDamage
WoW Classic addon that tracks the amount of damage dealt or healed by attacks, spells and abilities adding useful real world benchmarks to your tooltips!

## Learns on the job
The addon assumes nothing and has no previous knowledge about spells and abilities in the game. Instead it learn what spells and abilities do by monitoring the combat log. This eliminates all bias and means that nothing will be added to spell tooltips before you start casting. Sweet :) 

*In this screenshot Flamestike has only been cast twice. The first time it hit for 99 damage. The second time it critted for 156. The average damage per cast is thus 128 which with a 3 second cast yielding 43 DPS. Additionally it added DOT component dealing 17 damage per tick. More casts will add damage ranges and the accuracy of the critical percentage will increase.*

![flamestike](flamestrike.png?raw=true "Flamestrike Damage Tracking")

## Global tracking!
By default the addon tracks the last 250 spells and abilities against all mobs and compute statistics. The number is big enough that stats will be kept fairly accurate while also small enough that gear upgrades and bufs should impact the stats fairly quickly.

## Tracking per mob !
The addon also keeps statistics about how your last 125 spells and abilities impacted bosses and mobs. If you hover over an ability or spell when a target is selected it will show the statistics gathered for that specific mob. Super useful for sanity checking if you are hit capped versus ragnaros! 

![fireball](fireball\_target.png?raw=true "Fireball Damage Tracking on target")

## Also track heals !
The addon also compute statistics for healing spells.

![heal](heal.png?raw=true "Title")

## Installation
Install by extracting the folder RealDamage inside RealDamage-0.4.zip to the _classic_\Interface\AddOns folder in your world of warcraft installation directory.

Download [RealDamage-0.4.zip](https://github.com/WOFD/RealDamage/releases/download/0.4/RealDamage-0.4.zip).

## Advanced Configuration
To keep database size reasonable the addon is by default configured to limit per mob statistics to the last 250 mobs engaged. This limit along with other limits can be configured on a per character basis using the slash menu available ingame. Type the following command for a list of supported settings:

<code>/realdamage</code>

## Limitations
In World of Warcraft Classic Blizzard brought over the much improved addon API from retail but limited some functionality especially when it comes to spellranks etc. This mod does a fairly good job at detecting which rank is cast but might get confused if the player is using multiple ranks of a spell that has a DOT/HOT component at the same time. Addtionally, the mod does not attempt to calculate DPS/HPS for channelled and over time effects. 
