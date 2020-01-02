# RealDamage
WoW Classic addon that tracks the amount dealt or healed by spells and abilities giving you useful real world benchmarks!

The addon assumes nothing and has no previous knowledge about spells and abilities in the game. Instead it learn what spells and abilities do by monitoring the combat log. This eliminates all bias and means that nothing will be added to spell tooltips before you start casting. Sweet :) 

## Global tracking!
By default the addon tracks the last 500 spellcasts against all mobs and compute statistics. The number is big enough that stats will be kept fairly accurate while also small enough that gear upgrades should impact the stats fairly quickly.

![Alt text](frostbolt.png?raw=true "Title")

## Tracking per mob !
It also keeps statistics for the last 350 casts against each mob you have ever engaged. If you hover over an ability or spell when a target is selected it will show the statistics gathered for that specific mob. Super useful for sanity checking if you are hit capped versus ragnaros!

## Also track heals !
Heals are tracked the same way.

![Alt text](heal.png?raw=true "Title")

## Installation
Install by extracting the folder RealDamage-0.1\RealDamage to the _classic_\Interface\AddOns folder in your world of warcraft installation directory.

Download [RealDamage-0.1](https://github.com/WOFD/RealDamage/archive/0.1.zip).

## Limitations
In classic Blizzard brought over the much improved addon API from retail but limited some functionality especially when it comes to spellranks etc. This mod does a fairly good job at detecting which rank is cast but might get confused if the player is using multiple ranks of a spell that has a DOT/HOT component at the same time. This mod will only show damage per tick for channelled spells and for the DOT/HOT component of spells. 

Note that this is an alpha version and have been tested on a mage. Some issues may come to light if other classes begin to use it.
