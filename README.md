# RealDamage
WoW Classic addon that tracks the amount dealt or healed by attacks, spells and abilities giving you useful real world benchmarks!

The addon assumes nothing and has no previous knowledge about spells and abilities in the game. Instead it learn what spells and abilities do by monitoring the combat log. This eliminates all bias and means that nothing will be added to spell tooltips before you start casting. Sweet :) 

## Global tracking!
By default the addon tracks the last 250 spells and abilities against all mobs and compute statistics. The number is big enough that stats will be kept fairly accurate while also small enough that gear upgrades and bufs should impact the stats fairly quickly.

![flamestike](flamestrike.png?raw=true "Flamestrike Damage Tracking")

## Tracking per mob !
It also keeps statistics for the last 125 spells and abilities against the last 250 mob types you have engaged. If you hover over an ability or spell when a target is selected it will show the statistics gathered for that specific mob. Super useful for sanity checking if you are hit capped versus ragnaros!

![fireball](fireball\_target.png?raw=true "Fireball Damage Tracking on target")

## Also track heals !
Heals are tracked the same way.

![heal](heal.png?raw=true "Title")

## Installation
Install by extracting the folder RealDamage inside RealDamage-0.3.zip to the _classic_\Interface\AddOns folder in your world of warcraft installation directory.

Download [RealDamage-0.3.zip](https://github.com/WOFD/RealDamage/releases/download/3.0b/RealDamage-0.3.zip).

Important: If you are upgrading from the alpha build you will need to type the following command in the gamechat to reset the addon since  that database is not backward compatible.

<code>/realdamage reset</code>

## Limitations
In classic Blizzard brought over the much improved addon API from retail but limited some functionality especially when it comes to spellranks etc. This mod does a fairly good job at detecting which rank is cast but might get confused if the player is using multiple ranks of a spell that has a DOT/HOT component at the same time. This mod will only show damage per tick for channelled spells and for the DOT/HOT component of spells. 

Note that this is an beta version and have been mostly tested on a mage. 

