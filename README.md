# RealDamage
WoW Classic addon that tracks the amount dealt or healed by spells and abilities. This is an alpha version and have been tested on a mage. Some issues may come to light if other classes begin to use it.

By default the addon tracks the last 500 spellcasts and collect statistics. The number is big enough that stats will be kept fairly accurate while also small enough that gear upgrades should impact the stats fairly quickly.

![Alt text](frostbolt.png?raw=true "Title")


Heals are tracked the same way

![Alt text](heal.png?raw=true "Title")

In classic Blizzard brought over the much improved addon API from retail but limited some functionality especially when it comes to spellranks etc. This mod does a fairly good job at detecting which rank is cast but might get slightly confused if the player is using different rank of spells with a DOT component. This mod will only show damage per tick for channelled spells and for the DOT component of spells. 
