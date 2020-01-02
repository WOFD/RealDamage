RealDamage = { }

RealDamage.DatabaseMaxEntries = 500
RealDamage.TargetDatabaseMaxEntries = 350
RealDamage.Loaded = 0
RealDamage.currentCast = nil
RealDamage.completedCasts = {}
RealDamage.spellIsChannel = {}

local versionString = "|cffffff55RealDamage|r |cffff88880.1|r by |cff88ffffYoshana|r"

local function tableIdxExtremeCompute(table, idx, is_max, flag, flag_negate)
	local extreme = nil
	for i = 1, #table do
		if flag == nil or ((not flag_negate and table[i][flag]) or (flag_negate and not table[i][flag])) then
		    if extreme == nil or (is_max and table[i][idx] > extreme) or (not is_max and table[i][idx] < extreme) then
		    	extreme = table[i][idx]
		   	end
		end

	end
	return extreme
end

local function tableIdxAvgCompute(table, idx)
	local acc = 0
	for i = 1, #table do
	    acc = acc + table[i][idx]
	end
	if acc > 0 then
		return acc/#table
	end
	return nil
end

local function tableIdxCountFlagged(table, flag)
	local flagged = 0
	for i = 1, #table do
	    if table[i][flag] then
	    	flagged = flagged + 1
	    end
	end
	return flagged
end

function sum(t)
    local sum = 0
    for k,v in pairs(t) do
        sum = sum + v
    end

    return sum
end

function RealDamage:CreateSpellIdEntry( destTable, spellId )
	if destTable[spellId] == nil then
		destTable[spellId] = { }
		destTable[spellId]["name"] = spellName
		destTable[spellId]["SPELL_DAMAGE"] = { }
		destTable[spellId]["SPELL_PERIODIC_DAMAGE"] = { }
		destTable[spellId]["RANGE_DAMAGE"] = { }
		destTable[spellId]["SPELL_HEAL"] = {}
		destTable[spellId]["SPELL_PERIODIC_HEAL"] = {}
	end

	if destTable["MISS_TABLE"] == nil then
		destTable["MISS_TABLE"] = {}
	end

	if destTable["MISS_TABLE"][spellId] == nil then
		destTable["MISS_TABLE"][spellId] = {}
		destTable["MISS_TABLE"][spellId]["SPELL_MISSED"] = {}
		destTable["MISS_TABLE"][spellId]["SPELL_PERIODIC_MISSED"] = {}
		destTable["MISS_TABLE"][spellId]["RANGE_MISSED"] = {}
	end
end

function RealDamage:InsertSpellDamageLogEvent(destTable, maxEntries, spellId, amount, overkill, resisted, blocked, absorbed, critical, glancing, crushing, eventType)

	local spellName, _, _, castTime, minRange, maxRange, _ = GetSpellInfo(spellId)

	RealDamage:CreateSpellIdEntry(destTable, spellId)

	table.insert(destTable[spellId][eventType], {amount, overkill, resisted, blocked, absorbed, critical, glancing, crushing })
	if #destTable[spellId][eventType] > maxEntries then
		table.remove(destTable[spellId][eventType],1)
	end
end

function RealDamage:InsertLogMissEvent(destTable, maxEntries, spellId, eventType, miss)
	
	RealDamage:CreateSpellIdEntry(destTable, spellId)

	table.insert(destTable["MISS_TABLE"][spellId][eventType], miss)
	if #destTable["MISS_TABLE"][spellId][eventType] > maxEntries then
		table.remove(destTable["MISS_TABLE"][spellId][eventType], 1)
	end
end

function RealDamage:InsertSpellHealLogEvent(destTable, maxEntries, spellId, amount, critical, eventType)

	RealDamage:CreateSpellIdEntry(destTable, spellId)

	table.insert(destTable[spellId][eventType], {amount, critical })
	if #destTable[spellId][eventType] > maxEntries then
		table.remove(destTable[spellId][eventType],1)
	end
end

function RealDamage:UpdateMissTable(destTable, spellId, missType, prefix)
	if #destTable["MISS_TABLE"][spellId][missType] > 0 then
		local misses = sum(destTable['MISS_TABLE'][spellId][missType])
		local miss_table_count = #destTable['MISS_TABLE'][spellId][missType]

		destTable[spellId][prefix.."_miss_percentage"] = math.floor(misses / miss_table_count * 100 * 100) / 100
		destTable[spellId][prefix.."_miss_count"] = misses
		destTable[spellId][prefix.."_miss_table_count"] = miss_table_count
	end	
end

function RealDamage:UpdateDamage(destTable, spellId, damageType, amount_idx, crit_flag_idx, prefix)

	local spellName, _, _, castTime, minRange, maxRange, _ = GetSpellInfo(spellId)

	-- Assume GCD is 1.5
	if castTime == 0 then
		castTime = 1500
	end

	if #destTable[spellId][damageType] > 0 then

		local crits = tableIdxCountFlagged(destTable[spellId][damageType], crit_flag_idx)
		local hits = #destTable[spellId][damageType] - crits
		local crit_chance = math.floor(crits / (crits+hits) * 100 * 100) / 100
		local average = math.floor(tableIdxAvgCompute(destTable[spellId][damageType], amount_idx) + 0.5)
		destTable[spellId][prefix.."_crit_percentage"] = crit_chance
		destTable[spellId][prefix.."_hit_percentage"] = 100 - crit_chance
		destTable[spellId][prefix.."_average"] = average
		

		if RealDamage.spellIsChannel[spellId] == nil or not RealDamage.spellIsChannel[spellId] then
			destTable[spellId][prefix.."_average_per_second"] = math.floor(average/castTime*1000 + 0.5)
		else
			destTable[spellId][prefix.."_average_per_second"] = "N/A"
		end

		destTable[spellId][prefix.."_crit_high"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, true, crit_flag_idx, false)
		destTable[spellId][prefix.."_crit_low"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, false, crit_flag_idx, false)
		destTable[spellId][prefix.."_hit_high"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, true, crit_flag_idx, true)
		destTable[spellId][prefix.."_hit_low"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, false, crit_flag_idx, true)
	end
end

function RealDamage:UpdateStats(destTable, spellId)

	local spellName, _, _, castTime, minRange, maxRange, _ = GetSpellInfo(spellId)

	-- Assumes GCD is 1.5 secs
	if castTime == 0 then
		castTime = 1500
	end

	RealDamage:UpdateDamage(destTable, spellId, "SPELL_DAMAGE", 1, 6, "spell")
	RealDamage:UpdateDamage(destTable, spellId, "RANGE_DAMAGE", 1, 6, "range")
	RealDamage:UpdateDamage(destTable, spellId, "SPELL_HEAL", 1, 2, "heal")

	RealDamage:UpdateMissTable(destTable, spellId, "SPELL_MISSED", "spell")
	RealDamage:UpdateMissTable(destTable, spellId, "SPELL_PERIODIC_MISSED", "spell_periodic")
	RealDamage:UpdateMissTable(destTable, spellId, "RANGE_MISSED", "range")

	if #destTable[spellId]["SPELL_PERIODIC_DAMAGE"] > 0 then
		destTable[spellId]['spell_periodic_average'] = math.floor(tableIdxAvgCompute(destTable[spellId]["SPELL_PERIODIC_DAMAGE"], 1) + 0.5)
	end

	if #destTable[spellId]["SPELL_PERIODIC_HEAL"] > 0 then
		destTable[spellId]['heal_periodic_average'] = math.floor(tableIdxAvgCompute(destTable[spellId]["SPELL_PERIODIC_HEAL"], 1) + 0.5)
	end

end

function RealDamage:OnSpellcastSentEvent(src, castGUID )
	if src == "player" then
		self.currentCast = castGUID
	end
end

function RealDamage:OnSpellcastSuccededEvent(castGUID, spellId)
	if self.currentCast == castGUID then
		local name, _, _, castTime, minRange, maxRange, _ = GetSpellInfo(spellId)
		self.completedCasts[name] = spellId
	end
end

function RealDamage:OnSpellcastChannelStartEvent(spellId)
	local name, _, _, castTime, minRange, maxRange, _ = GetSpellInfo(spellId)
	self.spellIsChannel[spellId] = true
end

function RealDamage:OnAddonLoadedEvent()

	self:SetToolTipHook()

	if RealDamageDatabase == nil then
		RealDamageDatabase = {}
	end

	if RealDamageTargetDatabase == nil then
		RealDamageTargetDatabase = {}
	end

	SLASH_REALDAMAGE1 = "/realdamage"
	SLASH_REALDAMAGE2 = "/RealDamage"
	SlashCmdList["REALDAMAGE"] = function(msg)
		if msg == nil or msg == "" or msg == "help" or msg == "?" then
	  		print(versionString)
	  		print("|cff64ff3b/realdamage reset:|r Resets damage tracking database.")
	  	elseif msg == "reset" then
	  		RealDamageDatabase = {}
	  		RealDamageTargetDatabase = {}
	  		print("|cffffff00Realdamage:|r Database has been reset!")
	  	else
	  		print("|cffffff00Realdamage:|r Invalid command")
	  	end
	end 

	RealDamage.Loaded = 1
	print(versionString)
end

function RealDamage:OnPlayerLogout()

end

function RealDamage:Reset(  )
	RealDamageDatabase = {}
	RealDamageTargetDatabase = {}
end

function RealDamage:OnCombatLogEvent(event, ...)
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...

	--print(timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags)

	if RealDamage.Loaded and sourceGUID == UnitGUID("player") then

		--if subevent == "SWING_DAMAGE" then
		--	amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
		if subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "RANGE_DAMAGE" then
			local _, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
			if self.completedCasts[spellName] ~= nil then
				local spellId = self.completedCasts[spellName]

				local hit_table_key = "SPELL_MISSED"
				if subevent == "SPELL_PERIODIC_DAMAGE" then
					hit_table_key = "SPELL_PERIODIC_MISSED"
				elseif subevent == "RANGE_DAMAGE" then
					hit_table_key = "RANGE_MISSED"
				end

				RealDamage:InsertLogMissEvent(RealDamageDatabase, RealDamage.DatabaseMaxEntries, spellId, hit_table_key, 0)
				RealDamage:InsertSpellDamageLogEvent(RealDamageDatabase, RealDamage.DatabaseMaxEntries, spellId, amount, overkill, resisted, blocked, absorbed, critical, glancing, crushing, subevent)
				
				-- Track damage to non-player targets (mobs)
				if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == 0 then
					if RealDamageTargetDatabase[destName] == nil then
						RealDamageTargetDatabase[destName] = {}
					end
					RealDamage:InsertLogMissEvent(RealDamageTargetDatabase[destName], RealDamage.TargetDatabaseMaxEntries, spellId, hit_table_key, 0)
					RealDamage:InsertSpellDamageLogEvent(RealDamageTargetDatabase[destName], RealDamage.TargetDatabaseMaxEntries, spellId, amount, overkill, resisted, blocked, absorbed, critical, glancing, crushing, subevent)
				end
			end
		elseif subevent == "SPELL_MISSED" or subevent == "SPELL_PERIODIC_MISSED" or subevent == "RANGE_MISSED" then
			local _, spellName, spellSchool, missType = select(12, ...)			
			
			if self.completedCasts[spellName] ~= nil then
				spellId = self.completedCasts[spellName]
				RealDamage:InsertLogMissEvent(RealDamageDatabase, RealDamage.DatabaseMaxEntries, spellId, subevent, 1)

				if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == 0 then
					if RealDamageTargetDatabase[destName] == nil then
						RealDamageTargetDatabase[destName] = {}
					end
					RealDamage:InsertLogMissEvent(RealDamageTargetDatabase[destName], RealDamage.DatabaseMaxEntries, spellId, subevent, 1)
				end
			end
		elseif subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL" then
			local _, spellName, spellSchool, amount, overhealing, absorbed, critical = select(12, ...)			
			
			if self.completedCasts[spellName] ~= nil then	
				spellId = self.completedCasts[spellName]
				RealDamage:InsertSpellHealLogEvent(RealDamageDatabase, RealDamage.DatabaseMaxEntries, spellId, amount, critical, subevent)
				RealDamage:UpdateStats(RealDamageDatabase, spellId)
			end
		end
	end
end

function RealDamage:AddDamageTooltipLines(frame, db, spellId, data_prefix, text_prefix)
	local average = db[spellId][data_prefix.."_average"] or "N/A"
	local average_per_second = db[spellId][data_prefix.."_average_per_second"] or "N/A"
	local hit_low = db[spellId][data_prefix.."_hit_low"] or "N/A"
	local hit_high = db[spellId][data_prefix.."_hit_high"] or "N/A"
	local hit_percentage = db[spellId][data_prefix.."_hit_percentage"] or "N/A"
	local crit_percentage = db[spellId][data_prefix.."_crit_percentage"] or "N/A"
	local miss_percentage = db[spellId][data_prefix.."_miss_percentage"] or "N/A"

	if RealDamage.spellIsChannel[spellId] == nil or not RealDamage.spellIsChannel[spellId] then
		frame:AddDoubleLine(text_prefix.." Average", average.." ("..average_per_second.." DPS)", 0.5, 0.5, 1, 1, 1, 1)
	else
		frame:AddDoubleLine(text_prefix.." Average",average.." (channel)", 0.5, 0.5, 1, 1, 1, 1)
	end

	frame:AddDoubleLine(text_prefix.." Damage",hit_low.." to "..hit_high.." ("..hit_percentage.."%)", 0.5, 0.5, 1, 1, 1, 1)
	
	if crit_percentage ~= "N/A" and crit_percentage > 0 then
		local crit_low = db[spellId][data_prefix.."_crit_low"] or "N/A"
		local crit_high = db[spellId][data_prefix.."_crit_high"] or "N/A"
    	frame:AddDoubleLine(text_prefix.." Critical",crit_low.." to "..crit_high.." ("..crit_percentage.."%)", 0.5, 0.5, 1, 1, 1, 1)
    end
	
    if miss_percentage ~= "N/A" and miss_percentage > 0 then
    	local miss_count = db[spellId][data_prefix.."_miss_count"] or "N/A"
    	local miss_table_count = db[spellId][data_prefix.."_miss_table_count"] or "N/A"
    	frame:AddDoubleLine(text_prefix.." Miss", miss_percentage.."% ("..miss_count.." of "..miss_table_count..")", 0.5, 0.5, 1, 1, 1, 1)
    end
end

function RealDamage:SetToolTipHook()

    GameTooltip:HookScript("OnTooltipSetSpell", function(self)
        local name, spellId = self:GetSpell()
        if spellId and RealDamage.Loaded and RealDamageDatabase and RealDamageTargetDatabase then

        	local targetName = GetUnitName("target")
        	local db = RealDamageDatabase
        	local usingTarget = false
        	if targetName ~= nil and RealDamageTargetDatabase[targetName] ~= nil and RealDamageTargetDatabase[targetName][spellId] ~= nil then
        		db = RealDamageTargetDatabase[targetName]
        		usingTarget = true
        	elseif db[spellId] == nil then
        		return
        	end

        	RealDamage:UpdateStats(db, spellId)

        	local hasSpellDamage = #db[spellId]["SPELL_DAMAGE"] > 0
        	local hasSpellPeriodicDamage = #db[spellId]["SPELL_PERIODIC_DAMAGE"] > 0
        	local hasRangeDamage = #db[spellId]["RANGE_DAMAGE"] > 0
        	local hasSpellHeal = #db[spellId]["SPELL_HEAL"] > 0
        	local hasSpellPeriodicHeal = #db[spellId]["SPELL_PERIODIC_HEAL"] > 0

    		if hasSpellDamage then
    			self:AddLine(" ")
	        	if usingTarget then
	        		self:AddLine(targetName.." ("..#db[spellId]["SPELL_DAMAGE"].." hits)", 1, 0, 0)
	        	else
	        		self:AddLine("RealDamage ("..#db[spellId]["SPELL_DAMAGE"].." hits)", 1, 0, 0)
	        	end
	        elseif hasSpellHeal then
	        	self:AddLine(" ")
	        	self:AddLine("RealDamage ("..#db[spellId]["SPELL_HEAL"].." hits)", 1, 0, 0)
	        elseif hasRangeDamage then
    			self:AddLine(" ")
	        	if usingTarget then
	        		self:AddLine(targetName.." ("..#db[spellId]["RANGE_DAMAGE"].." hits)", 1, 0, 0)
	        	else
	        		self:AddLine("RealDamage ("..#db[spellId]["RANGE_DAMAGE"].." hits)", 1, 0, 0)
	        	end
	        elseif hasSpellPeriodicDamage then
	        	self:AddLine(" ")
	        	if usingTarget then
	        		self:AddLine(targetName.." ("..#db[spellId]["SPELL_PERIODIC_DAMAGE"].." procs)", 1, 0, 0)
	        	else
	        		self:AddLine("RealDamage ("..#db[spellId]["SPELL_PERIODIC_DAMAGE"].." procs)", 1, 0, 0)
	        	end
	        else
	        	return
	        end

	        if hasSpellDamage then
	        	RealDamage:AddDamageTooltipLines(self, db, spellId, "spell", "Magic")
	        end
	        if hasRangeDamage then
	        	RealDamage:AddDamageTooltipLines(self, db, spellId, "range", "Ranged")
	        end
	        if hasSpellHeal then
	        	RealDamage:AddDamageTooltipLines(self, db, spellId, "heal", "Heal")
	        end

	       	if hasSpellPeriodicDamage then
	       		local spell_periodic_average = db[spellId]["spell_periodic_average"] or "N/A"
	        	self:AddDoubleLine("Periodic Damage", spell_periodic_average, 0.5, 0.5, 1, 1, 1, 1)

	        	local spell_periodic_miss_percentage = db[spellId]["spell_periodic_miss_percentage"] or "N/A"
	        	if spell_periodic_miss_percentage ~= "N/A" and spell_periodic_miss_percentage > 0 then
        			local spell_periodic_miss_count = db[spellId]["spell_periodic_miss_count"] or "N/A"
        			local spell_periodic_miss_table_count = db[spellId]["spell_periodic_miss_table_count"] or "N/A"
        			self:AddDoubleLine("Miss",spell_periodic_miss_percentage.."% ("..spell_periodic_miss_count.." of "..spell_periodic_miss_table_count..")", 0.5, 0.5, 1, 1, 1, 1)
            	end
	       	end

            if hasSpellPeriodicHeal then
	       		local heal_periodic_average = db[spellId]["heal_periodic_average"] or "N/A"
	       		self:AddDoubleLine("Periodic Heal", heal_periodic_average, 0.5, 0.5, 1, 1, 1, 1)
	       	end
        end
    end)
end

local RealDamageFrame = CreateFrame("Frame")
	RealDamageFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	RealDamageFrame:RegisterEvent("ADDON_LOADED");
	RealDamageFrame:RegisterEvent("PLAYER_LOGOUT");
	RealDamageFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
	RealDamageFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	RealDamageFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");

	RealDamageFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
	--print(event, arg1, arg2, arg3, arg4)
	-- pass a variable number of arguments
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		RealDamage:OnCombatLogEvent(event, CombatLogGetCurrentEventInfo())
	elseif event == "ADDON_LOADED" and arg1 == "RealDamage" then
		RealDamage:OnAddonLoadedEvent()
	--elseif event == "PLAYER_LOGOUT" then
	--	RealDamage:OnPlayerLogout()
	elseif event == "UNIT_SPELLCAST_SENT" then
		RealDamage:OnSpellcastSentEvent(arg1, arg3)
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		RealDamage:OnSpellcastSuccededEvent(arg2, arg3)
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" and arg1 == "player" then
		RealDamage:OnSpellcastChannelStartEvent(arg3)
	end
end)
