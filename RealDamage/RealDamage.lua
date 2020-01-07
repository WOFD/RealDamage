RealDamage = { }
RealDamage.Loaded = 0
RealDamage.currentCast = nil
RealDamage.completedCasts = {}

local versionString = "|cffffff55RealDamage|r |cffff88880.1|r by |cff88ffffYoshana|r"

local function TablePrint(t, n)
    if n==nil then
        n = 0
    end
    local tabs = ""
    for i = 1, n do
      tabs = tabs.."  "
    end
     for k,v in pairs(t)  do
         if type(v)=="table" then
            print(tabs, k, " = [")
            TablePrint(v, n+1)
            print(tabs, "] end of ", k)
         else 
            print(tabs,k, " = ", v)
         end
     end      
end

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
        acc = acc + (table[i][idx] or 0)
    end
    if acc > 0 then
        return acc/#table
    end
    return 0
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
        destTable[spellId] = {}
        destTable[spellId]["name"] = spellName

        destTable[spellId]["SWING_DAMAGE_MH"] = {}
        destTable[spellId]["SPELL_DAMAGE_MH"] = {}
        destTable[spellId]["SPELL_PERIODIC_DAMAGE_MH"] = {}
        destTable[spellId]["RANGE_DAMAGE_MH"] = {}

        destTable[spellId]["SWING_DAMAGE_OH"] = {}
        destTable[spellId]["SPELL_DAMAGE_OH"] = {}
        destTable[spellId]["SPELL_PERIODIC_DAMAGE_OH"] = {}
        destTable[spellId]["RANGE_DAMAGE_OH"] = {}

        destTable[spellId]["SPELL_HEAL"] = {}
        destTable[spellId]["SPELL_PERIODIC_HEAL"] = {}
        
    end
end

function RealDamage:InsertSpellDamageLogEvent(destTable, maxEntries, spellId, amount, overkill, resisted, blocked, absorbed, critical, glancing, crushing, missType, isOffHand, eventType)

    local spellName, _, _, castTime, minRange, maxRange, _ = GetSpellInfo(spellId)

    RealDamage:CreateSpellIdEntry(destTable, spellId)

    key = eventType
    if isOffHand then
        key = eventType.."_OH"
    elseif isOffHand == false then
        key = eventType.."_MH"
    end

    table.insert(destTable[spellId][key], {amount, overkill, resisted, blocked, absorbed, critical, glancing, crushing, missType })
    while #destTable[spellId][key] > maxEntries do
        table.remove(destTable[spellId][key], 1)
    end
end

function RealDamage:UpdateDamage(destTable, spellId, damageType, amount_idx, crit_flag_idx, glancing_flag_idx, crushing_flag_idx, miss_flag_idx, isOffHand, prefix)

    local spellName, _, _, castTime, minRange, maxRange, _ = GetSpellInfo(spellId)

    if #destTable[spellId][damageType] == 0 then
        destTable[spellId][prefix.."_enabled"] = false
        destTable[spellId][prefix.."_table_count"] = 0
    else
        destTable[spellId][prefix.."_enabled"] = true

        -- Count types of hits e.g. normal, crit, glancing, crushing and compute percentages
        local entry_count = #destTable[spellId][damageType]
        local crits = tableIdxCountFlagged(destTable[spellId][damageType], crit_flag_idx)
        local glancing_blows = 0
        local crushing_blows = 0
        local misses = 0
        local crit_chance = math.floor(crits / entry_count * 100 * 100) / 100
        local glancing_chance = 0
        local crushing_chance = 0
        local miss_chance = 0

        if glancing_flag_idx then
            glancing_blows = tableIdxCountFlagged(destTable[spellId][damageType], glancing_flag_idx)
            glancing_chance = math.floor(glancing_blows / entry_count * 100 * 100) / 100
            destTable[spellId][prefix.."_glancing_high"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, true, glancing_flag_idx, false)
            destTable[spellId][prefix.."_glancing_low"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, false, glancing_flag_idx, false)
        end
        if crushing_flag_idx then
            crushing_blows = tableIdxCountFlagged(destTable[spellId][damageType], crushing_flag_idx)
            crushing_chance = math.floor(crushing_blows / entry_count * 100 * 100) / 100
            destTable[spellId][prefix.."_crushing_high"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, true, crushing_flag_idx, false)
            destTable[spellId][prefix.."_crushing_low"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, false, crushing_flag_idx, false)
        end
        if miss_flag_idx then
            misses = tableIdxCountFlagged(destTable[spellId][damageType], miss_flag_idx)
            miss_chance = math.floor(misses / entry_count * 100 * 100) / 100
        end

        local hits = #destTable[spellId][damageType] - crits - glancing_blows - crushing_blows - misses

        destTable[spellId][prefix.."_glancing_blows"] = glancing_blows
        destTable[spellId][prefix.."_crushing_blows"] = crushing_blows
        destTable[spellId][prefix.."_miss_count"] = misses

        destTable[spellId][prefix.."_crit_percentage"] = crit_chance
        destTable[spellId][prefix.."_glancing_percentage"] = glancing_chance
        destTable[spellId][prefix.."_crushing_percentage"] = crushing_chance

        destTable[spellId][prefix.."_hit_percentage"] = 100 - crit_chance - glancing_chance - crushing_chance - miss_chance

        destTable[spellId][prefix.."_miss_percentage"] = miss_chance
        
        destTable[spellId][prefix.."_table_count"] = entry_count

        -- Compute the true average damage per hit over all hit types and misses
        local average = math.floor(tableIdxAvgCompute(destTable[spellId][damageType], amount_idx) + 0.5)
        destTable[spellId][prefix.."_average"] = average
        
        -- If auto-attack compute DPS based on attack speed
        if spellId == 6603 then
            mainSpeed, offSpeed = UnitAttackSpeed("player")
            if isOffHand then
                destTable[spellId][prefix.."_average_per_second"] = math.floor(average/offSpeed + 0.5)
            else
                destTable[spellId][prefix.."_average_per_second"] = math.floor(average/mainSpeed + 0.5)
            end
        -- We dont compute DPS for instant and channeled spells
        elseif castTime == 0 or RealDamageSpellDB["IsChannel"][spellId] then
            destTable[spellId][prefix.."_average_per_second"] = "N/A"
        -- For all other spells we use cast time to compute DPS
        else
            destTable[spellId][prefix.."_average_per_second"] = math.floor(average/castTime*1000 + 0.5)
        end

        -- Determine damage range for normal hits (all flags off)
        local hit_low = nil
        local hit_high = nil
        for i = 1, #destTable[spellId][damageType] do
            if      (crit_flag_idx == nil or not destTable[spellId][damageType][i][crit_flag_idx])
                and (glancing_flag_idx == nil or not destTable[spellId][damageType][i][glancing_flag_idx])
                and (crushing_flag_idx == nil or not destTable[spellId][damageType][i][crushing_flag_idx])
            then
                if hit_low == nil or destTable[spellId][damageType][i][amount_idx] < hit_low then
                    hit_low = destTable[spellId][damageType][i][amount_idx]
                end
                if hit_high == nil or destTable[spellId][damageType][i][amount_idx] > hit_high then
                    hit_high = destTable[spellId][damageType][i][amount_idx]
                end
            end
        end

        destTable[spellId][prefix.."_hit_low"] = hit_low
        destTable[spellId][prefix.."_hit_high"] = hit_high
        
        -- Determine damage range for all other hit types
        destTable[spellId][prefix.."_crit_high"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, true, crit_flag_idx, false)
        destTable[spellId][prefix.."_crit_low"] = tableIdxExtremeCompute(destTable[spellId][damageType], amount_idx, false, crit_flag_idx, false)
        
    end
end


function RealDamage:UpdateMitigation(destTable, spellId, type, prefix)
    
    if #destTable[spellId][type] > 0 then
        local mitigationList = {resisted=3, blocked=4, absorbed=5}
        for mitigationType, mitigationIdx in pairs(mitigationList) do
            mitigated_average = math.floor(tableIdxAvgCompute(destTable[spellId][type], resist_idx) + 0.5)
            if mitigated_average >= 0 then
                destTable[spellId][prefix.."_mitigation_"..mitigationType] = math.floor(tableIdxAvgCompute(destTable[spellId][type], resist_idx) + 0.5)
                destTable[spellId][prefix.."_vulnerability_"..mitigationType] = 0
            else
                destTable[spellId][prefix.."_mitigation_"..mitigationType] = 0
                destTable[spellId][prefix.."_vulnerability_"..mitigationType] = math.floor(tableIdxAvgCompute(destTable[spellId][type], resist_idx) + 0.5)
            end
        end
    end
end

function RealDamage:UpdateDamageOnHand(destTable, spellId, isOffHand)
    local suffixUpper, suffixLower

    if isOffHand then
        suffixUpper = "OH"
        suffixLower = "oh"
    else
        suffixUpper = "MH"
        suffixLower = "mh"
    end 

    RealDamage:UpdateDamage(destTable, spellId, "SPELL_DAMAGE_"..suffixUpper, 1, 6, 7, 8, 9, isOffHand, "spell_"..suffixLower)
    RealDamage:UpdateDamage(destTable, spellId, "SWING_DAMAGE_"..suffixUpper, 1, 6, 7, 8, 9, isOffHand, "swing_"..suffixLower)
    RealDamage:UpdateDamage(destTable, spellId, "SPELL_PERIODIC_DAMAGE_"..suffixUpper, 1, 6, 7, 8, 9, isOffHand, "spell_periodic_"..suffixLower)
    RealDamage:UpdateDamage(destTable, spellId, "RANGE_DAMAGE_"..suffixUpper, 1, 6, 7, 8, 9, isOffHand, "range_"..suffixLower)

    destTable[spellId][suffixLower.."_enabled"] = destTable[spellId]["spell_"..suffixLower.."_enabled"] or destTable[spellId]["swing_"..suffixLower.."_enabled"] 
        or destTable[spellId]["spell_periodic_"..suffixLower.."_enabled"] or destTable[spellId]["range_"..suffixLower.."_enabled"]

    if destTable[spellId][suffixLower.."_enabled"] then
        RealDamage:UpdateMitigation(destTable, spellId, "SPELL_DAMAGE_"..suffixUpper, "spell_"..suffixLower)
        RealDamage:UpdateMitigation(destTable, spellId, "SPELL_PERIODIC_DAMAGE_"..suffixUpper, "spell_periodic_"..suffixLower)
        RealDamage:UpdateMitigation(destTable, spellId, "RANGE_DAMAGE_"..suffixUpper, "range_"..suffixLower)
        RealDamage:UpdateMitigation(destTable, spellId, "SWING_DAMAGE_"..suffixUpper, "swing_"..suffixLower)
    end
end


function RealDamage:UpdateAllStats(destTable, spellId)

    -- Update main and off hand
    RealDamage:UpdateDamageOnHand(destTable, spellId, true)
    RealDamage:UpdateDamageOnHand(destTable, spellId, false)

    -- Update Healing
    RealDamage:UpdateDamage(destTable, spellId, "SPELL_HEAL", 1, 6, nil, nil, nil, nil, "heal")
    RealDamage:UpdateDamage(destTable, spellId, "SPELL_PERIODIC_HEAL", 1, 6, nil, nil, nil, nil, "heal_periodic")

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
        if castTime == 0 then
            RealDamageSpellDB["IsInstant"][spellId] = true
        end
    end
end

function RealDamage:OnSpellcastChannelStartEvent(spellId)
    local name, _, _, castTime, minRange, maxRange, _ = GetSpellInfo(spellId)
    RealDamageSpellDB["IsChannel"][spellId] = true
end

function RealDamage:InstallSlashCommands()
    SLASH_REALDAMAGE1 = "/realdamage"
    SLASH_REALDAMAGE2 = "/RealDamage"
    SlashCmdList["REALDAMAGE"] = function(line)
        msg, arg = string.match(line, "([a-zA-Z]+) *([a-zA-Z0-9]*)")

        if msg == nil or msg == "" or msg == "help" or msg == "?" then
            print(versionString)
            print("|cff64ff3b/realdamage reset:|r Resets damage tracking database.")
            print("|cff64ff3b/realdamage config:|r Show current configured values.")
            print("|cff64ff3b/realdamage DatabaseMaxEntries <1-10000>:|r Sets number of entries to be kept globally (default 250).")
            print("|cff64ff3b/realdamage TargetDatabaseMaxEntries <1-10000>:|r Sets number of entries to be kept per mob (default 125).")
        elseif string.lower(msg) == "reset" then
            RealDamageDatabase = {}
            RealDamageTargetDatabase = {}
            RealDamageSpellDB = { IsChannel={}, IsInstant={} }
            print("|cffffff00Realdamage:|r Database has been reset!")
        elseif string.lower(msg) == "config" then
            print("|cffffff00Realdamage:|r DatabaseMaxEntries = "..RealDamageSettings["DatabaseMaxEntries"])
            print("|cffffff00Realdamage:|r TargetDatabaseMaxEntries = "..RealDamageSettings["TargetDatabaseMaxEntries"])
        elseif msg == "DatabaseMaxEntries" or msg == "TargetDatabaseMaxEntries" then
            local newMax = tonumber(arg)
            if newMax == nil then
                print("|cffffff00Realdamage:|r Invalid argument - must be number")
            elseif newMax < 1 or newMax > 10000 then
                print("|cffffff00Realdamage:|r Valid range is 1-10000")
            else
                RealDamageSettings[msg] = newMax
                print("|cffffff00Realdamage:|r "..msg.." set to "..newMax.." (enforced on next combat event update)")
            end
        else
            print("|cffffff00Realdamage:|r Invalid command")
        end
    end
end

function RealDamage:OnAddonLoadedEvent()

    self:SetToolTipHook()

    if RealDamageDatabase == nil then
        RealDamageDatabase = {}
    end

    if RealDamageTargetDatabase == nil then
        RealDamageTargetDatabase = {}
    end

    if RealDamageSpellDB == nil then
        RealDamageSpellDB = { IsChannel={}, IsInstant={} }
    end

    if RealDamageSettings == nil then
        RealDamageSettings = {
                DatabaseMaxEntries = 250,
                TargetDatabaseMaxEntries = 125
        }
    end

    RealDamageSettings["DatabaseMaxEntries"] = 250
    RealDamageSettings["TargetDatabaseMaxEntries"] = 125

    RealDamage:InstallSlashCommands()

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
    local playerGUID = UnitGUID("player")
    if RealDamage.Loaded and sourceGUID == playerGUID then
        
        if subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SWING_DAMAGE" then
            local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand

            if subevent == "SWING_DAMAGE" then
                amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
                spellId = 6603
                spellName = "Auto-Attack"
            else
                spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
                if self.completedCasts[spellName] ~= nil then
                    spellId = self.completedCasts[spellName]
                else
                    return
                end
            end

            RealDamage:InsertSpellDamageLogEvent(RealDamageDatabase, RealDamageSettings["DatabaseMaxEntries"], spellId, amount, overkill, resisted, blocked, absorbed, critical, glancing, crushing, nil, isOffHand, subevent)
            
            -- Track damage to non-player targets (mobs)
            if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == 0 then
                if RealDamageTargetDatabase[destName] == nil then
                    RealDamageTargetDatabase[destName] = {}
                end
                RealDamage:InsertSpellDamageLogEvent(RealDamageTargetDatabase[destName], RealDamageSettings["TargetDatabaseMaxEntries"], spellId, amount, overkill, resisted, blocked, absorbed, critical, glancing, crushing, nil, isOffHand, subevent)
            end
        
        elseif subevent == "SPELL_MISSED" or subevent == "SPELL_PERIODIC_MISSED" or subevent == "RANGE_MISSED" or subevent == "SWING_MISSED" then
            local spellId, spellName, spellSchool, missType, isOffHand

            if subevent == "SWING_MISSED" then
                spellId = 6603
                spellName = "Auto-Attack"
                missType, isOffHand = select(12, ...) 
            elseif self.completedCasts[spellName] ~= nil then
                _, spellName, spellSchool, missType, isOffHand = select(12, ...)
                spellId = self.completedCasts[spellName]
            else
                return
            end

            local hit_table_key = string.match(subevent, "(.*)_MISSED").."_DAMAGE"

            RealDamage:InsertSpellDamageLogEvent(RealDamageDatabase, RealDamageSettings["DatabaseMaxEntries"], spellId, 0, 0, 0, 0, 0, false, false, false, missType, isOffHand, hit_table_key)

            if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == 0 then
                if RealDamageTargetDatabase[destName] == nil then
                    RealDamageTargetDatabase[destName] = {}
                end
                RealDamage:InsertSpellDamageLogEvent(RealDamageTargetDatabase[destName], RealDamageSettings["DatabaseMaxEntries"], spellId, 0, 0, 0, 0, 0, false, false, false, missType, isOffHand, hit_table_key)
            end
        elseif subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL" then
            local _, spellName, spellSchool, amount, overHealing, absorbed, critical = select(12, ...)          
            
            if self.completedCasts[spellName] ~= nil then
                spellId = self.completedCasts[spellName]
                RealDamage:InsertSpellDamageLogEvent(RealDamageDatabase, RealDamageSettings["DatabaseMaxEntries"], spellId, amount, overHealing, 0, 0, absorbed, critical, false, false, nil, nil, subevent)
            end
        end
    end
end

function RealDamage:AddDamageTooltipLines(frame, db, spellId, data_prefix, text_prefix)
    local average = db[spellId][data_prefix.."_average"] or "N/A"
    local average_per_second = db[spellId][data_prefix.."_average_per_second"] or "N/A"
    local miss_percentage = db[spellId][data_prefix.."_miss_percentage"] or "N/A"

    if text_prefix == nil or text_prefix == "" then
        text_prefix = ""
    else
        text_prefix = text_prefix.." "
    end

    -- Always show average damage
    if RealDamageSpellDB["IsChannel"][spellId] then
        frame:AddDoubleLine(text_prefix.."Average",average.." (channel)", 0.5, 0.5, 1, 1, 1, 1)
    elseif RealDamageSpellDB["IsInstant"][spellId] then 
        frame:AddDoubleLine(text_prefix.."Average",average, 0.5, 0.5, 1, 1, 1, 1)
    else
        frame:AddDoubleLine(text_prefix.."Average", average.." ("..average_per_second.." DPS)", 0.5, 0.5, 1, 1, 1, 1)
    end

    local damageFlags = {
        Hit="hit",
        Critical="crit", 
        Glancing="glancing",
        Crushing="crushing"
    }

    local damageLines = {}

    for flagTitle, damageFlag in pairs(damageFlags) do
        
        local percentage = db[spellId][data_prefix.."_"..damageFlag.."_percentage"]
        if percentage ~= "N/A" and percentage > 0 then 
            local low = db[spellId][data_prefix.."_"..damageFlag.."_low"]
            local high = db[spellId][data_prefix.."_"..damageFlag.."_high"]
            if low and high and (low ~= high or (0 < percentage and percentage < 100)) then
                table.insert( damageLines, {title=text_prefix..flagTitle, low=low, high=high, percentage=percentage})
            end
        end
    end

    table.sort(damageLines, function(a,b) return a.percentage > b.percentage end)

    for i = 1, #damageLines do
         -- Only show range if there is any
        if damageLines[i].low ~= damageLines[i].high then
            frame:AddDoubleLine(damageLines[i].title, damageLines[i].low.." to "..damageLines[i].high.." ("..damageLines[i].percentage.."%)", 0.5, 0.5, 1, 1, 1, 1)
        else
            frame:AddDoubleLine(damageLines[i].title,damageLines[i].low.." ("..damageLines[i].percentage.."%)", 0.5, 0.5, 1, 1, 1, 1)
        end
    end
    
    -- Show miss percentage if any
    if miss_percentage ~= "N/A" and miss_percentage > 0 then
        local miss_count = db[spellId][data_prefix.."_miss_count"] or "N/A"
        local miss_table_count = db[spellId][data_prefix.."_table_count"] or "N/A"
        --frame:AddDoubleLine(text_prefix.."Miss", miss_percentage.."% ("..miss_count.." of "..miss_table_count..")", 0.5, 0.5, 1, 1, 1, 1)
        frame:AddDoubleLine(text_prefix.."Miss", miss_percentage.."%", 0.5, 0.5, 1, 1, 1, 1)
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

            RealDamage:UpdateAllStats(db, spellId)

            local hasSwingDamage = db[spellId]["swing_mh_enabled"] or db[spellId]["swing_oh_enabled"]
            local hasSpellDamage = db[spellId]["spell_mh_enabled"] or db[spellId]["spell_oh_enabled"]
            local hasSpellPeriodicDamage = db[spellId]["spell_periodic_mh_enabled"] or db[spellId]["spell_periodic_oh_enabled"]
            local hasRangeDamage = db[spellId]["range_mh_enabled"] or db[spellId]["range_oh_enabled"]
            local hasSpellHeal = RealDamageDatabase[spellId]["heal_enabled"]
            local hasSpellPeriodicHeal = RealDamageDatabase[spellId]["heal_periodic_enabled"]

            if hasSpellDamage then
                local entry_count = db[spellId]["spell_mh_table_count"] + db[spellId]["spell_oh_table_count"]
                self:AddLine(" ")
                if usingTarget then
                    self:AddLine(targetName.." (Last "..entry_count.." hits)", 1, 0, 0)
                else
                    self:AddLine("RealDamage (Last "..entry_count.." hits)", 1, 0, 0)
                end
            elseif hasRangeDamage then
                local entry_count = db[spellId]["range_mh_table_count"] + db[spellId]["range_oh_table_count"]
                self:AddLine(" ")
                if usingTarget then
                    self:AddLine(targetName.." (Last "..entry_count.." hits)", 1, 0, 0)
                else
                    self:AddLine("RealDamage (Last "..entry_count.." hits)", 1, 0, 0)
                end
            elseif hasSpellPeriodicDamage then
                local entry_count = db[spellId]["spell_periodic_mh_table_count"] + db[spellId]["spell_periodic_oh_table_count"]
                self:AddLine(" ")
                if usingTarget then
                    self:AddLine(targetName.." (Last "..entry_count.." procs)", 1, 0, 0)
                else
                    self:AddLine("RealDamage (Last "..entry_count.." procs)", 1, 0, 0)
                end
            elseif hasSpellHeal then
                self:AddLine(" ")
                self:AddLine("RealDamage (Last "..RealDamageDatabase[spellId]["heal_table_count"].." heals)", 1, 0, 0)
            elseif hasSpellPeriodicHeal then
                self:AddLine(" ")
                self:AddLine("RealDamage (Last "..RealDamageDatabase[spellId]["heal_periodic_table_count"].." procs)", 1, 0, 0)
            elseif hasSwingDamage then
                local entry_count = db[spellId]["swing_mh_table_count"] + db[spellId]["swing_oh_table_count"]
                self:AddLine(" ")
                if usingTarget then
                    self:AddLine(targetName.." (Last "..entry_count.." swings)", 1, 0, 0)
                else
                    self:AddLine("RealDamage (Last "..entry_count.." swings)", 1, 0, 0)
                end
            else
                return
            end

            if hasSpellHeal then
                RealDamage:AddDamageTooltipLines(self, RealDamageDatabase, spellId, "heal", "Heal")
            end
            if hasSpellPeriodicHeal then
                RealDamage:AddDamageTooltipLines(self, RealDamageDatabase, spellId, "heal_periodic", "Heal Periodic")
            end


            if db[spellId]["mh_enabled"] and db[spellId]["oh_enabled"] then
                self:AddLine(" ")
                self:AddLine("Mainhand:")
            end

            if db[spellId]["swing_mh_enabled"] then
                RealDamage:AddDamageTooltipLines(self, db, spellId, "swing_mh", "Swing")
            end

            if db[spellId]["spell_mh_enabled"] then
                RealDamage:AddDamageTooltipLines(self, db, spellId, "spell_mh", "")
            end

            if db[spellId]["range_mh_enabled"] then
                RealDamage:AddDamageTooltipLines(self, db, spellId, "range_mh", "Range")
            end

            if db[spellId]["spell_periodic_mh_enabled"] then
                RealDamage:AddDamageTooltipLines(self, db, spellId, "spell_periodic_mh", "Periodic")
            end

            if db[spellId]["mh_enabled"] and db[spellId]["oh_enabled"] then
                self:AddLine(" ")
                self:AddLine("Offhand:")
            end

            if db[spellId]["swing_oh_enabled"] then
                RealDamage:AddDamageTooltipLines(self, db, spellId, "swing_oh", "Swing")
            end

            if db[spellId]["spell_oh_enabled"] then
                RealDamage:AddDamageTooltipLines(self, db, spellId, "spell_oh", "")
            end

            if db[spellId]["range_oh_enabled"] then
                RealDamage:AddDamageTooltipLines(self, db, spellId, "range_oh", "Range")
            end

            if db[spellId]["spell_periodic_oh_enabled"] then
                RealDamage:AddDamageTooltipLines(self, db, spellId, "spell_periodic_oh", "Periodic")
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
    --  RealDamage:OnPlayerLogout()
    elseif event == "UNIT_SPELLCAST_SENT" then
        RealDamage:OnSpellcastSentEvent(arg1, arg3)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        RealDamage:OnSpellcastSuccededEvent(arg2, arg3)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" and arg1 == "player" then
        RealDamage:OnSpellcastChannelStartEvent(arg3)
    end
end)
