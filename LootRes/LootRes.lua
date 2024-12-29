
LootRes = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDebug-2.0", "AceModuleCore-2.0", "AceConsole-2.0", "AceDB-2.0", "AceHook-2.1")
LootRes:RegisterDB("LootResDB")
LootRes.frame = CreateFrame("Frame", "LootRes", GameTooltip)

function LootRes:OnEnable()
	LootRes.frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	LootRes.frame:RegisterEvent("CHAT_MSG_WHISPER")
	LootRes.frame:RegisterEvent("CHAT_MSG_SYSTEM")
	LootRes.frame:RegisterEvent("ADDON_LOADED")
	LootRes.frame:RegisterEvent("CHAT_MSG_LOOT")
	LootRes.frame:RegisterEvent("CHAT_MSG_RAID")
	LootRes.frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
	LootRes.frame:RegisterEvent("CHAT_MSG_RAID_WARNING")
	LootRes.frame:SetScript("OnEvent", LootRes.OnEvent)
	LootRes.frame:SetScript("OnShow", LootRes.OnShow)
	LootRes.frame:SetScript("OnHide", LootRes.OnHide)
	LootRes.lastAnnounce = 0
	LootRes.guildName = 'CuHuu TpakTop'
	
	SLASH_LOOTRES1 = "/lootres"
	SlashCmdList["LOOTRES"] = function(cmd)
		if cmd then
			if string.find(cmd, 'savelast', 1, true) then
				saveLast(cmd)
			end
			if cmd == 'print' then
				LootRes:PrintReserves()
			elseif cmd == 'raidprint' then
				LootRes:PrintRaidReserves()
			elseif cmd == 'raidprint2' then
				LootRes:PrintRaidReserves2()
			elseif cmd == 'raidprint3' then
				LootRes:PrintRaidReserves3()
			elseif cmd == 'load' then
				LootRes:InsertSRData()
			elseif cmd == 'delete' then
				LootRes:DeleteSRData()
			elseif cmd == 'raidlog' or cmd == 'log' then
				LootRes:ShowHistoryLog(cmd)
			elseif cmd == 'excel' then
				LootRes:PrepareExcelTextbox()
			elseif cmd == 'guildinfo' then
				LootRes:GetGuildInfo()
			elseif cmd == 'reset' then
				LootRes:ResetLootHistory()
			elseif cmd == 'test' then
				LootRes:TestAnnounceSR()
			elseif string.find(cmd, 'announce', 1, true) then
				LootRes:SetAnnounceOption(cmd)
			elseif string.find(cmd, 'view', 1, true) then
				LootRes:ViewSRForPlayer(cmd)
			elseif string.find(cmd, 'clear', 1, true) then
				LootRes:ClearSRForPlayer(cmd)
			else
				LootRes:Print('Commands for LootRes:')
				LootRes:Print('/lootres load - Load parsed data from https://raidres.fly.dev/')
				LootRes:Print('/lootres delete - Delete all reserves from LootRes.')
				LootRes:Print('/lootres print - Show reserved items.')
				LootRes:Print('/lootres raidprint - Show reserved items for Raid.')
				LootRes:Print('/lootres raidprint2 - Show reserved items for Raid. (reversed function)')
				LootRes:Print('/lootres raidprint3 - Show reserved items for Raid. (with current players only, reversed function)')
				LootRes:Print('/lootres announce 1 or 0 - Enable/Disable announce SR feature for raid chat.')
				LootRes:Print('/lootres announce + - Enable/Disable announce SR with roll formulas feature for raid chat.')
				LootRes:Print('/lootres log - View Loot History.')
				LootRes:Print('/lootres raidlog - Show Loot History for Raid.')
				LootRes:Print('/lootres excel - View textbox with Loot History.')
				LootRes:Print('/lootres reset - Reset Loot History.')
				LootRes:Print('/lootres view PlayerName - Check looted items for PlayerName.')
				LootRes:Print('/lootres clear PlayerName - Delete looted history for PlayerName.')
			end
		end
	end

	LootRes:Print('LootRes loaded. View Minimap Icon to access the UI features.')
end

if GUILD_TABLE == nil or GUILD_TABLE then
	GUILD_TABLE = {}
end


function LootRes:OnEvent()
	-- if event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY" then
		-- printable = gsub(arg1, "\124", "\124\124");
		-- print(printable)
	-- end
	if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING") and (time() - LootRes.lastAnnounce> 5) then
		LootRes:AnnounceSR(arg1)
	elseif event == "CHAT_MSG_LOOT" then
		LootRes:SaveLootLog(arg1)
	end
end

function LootRes:OnShow()
    local reservedNumber = 0
    local reservedPlayers = {}

    if GameTooltip.itemLink then
        local _, _, itemLink = string.find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)")

        if not itemLink then
            return false
        end
		if LootRes.db.profile.reserves == nil or LootRes.countTableEntries(LootRes.db.profile.reserves) == 0 then
			return false
		end 
        local itemName, _, itemRarity = GetItemInfo(itemLink)

        for playerName, playerData in next, LootRes.db.profile.reserves do
            for _, item in next, playerData.items do
                if string.lower(itemName) == string.lower(item) then
                    reservedNumber = reservedNumber + 1
                    table.insert(reservedPlayers, { playerName = playerName, comment = playerData.comment or '', item = item })
                end
            end
        end

        table.sort(reservedPlayers, function(a, b)
            local priorityA = -1
            local priorityB = -1

            if a.comment and string.sub(a.comment, 1, 1) == "+" then
                priorityA = tonumber(string.sub(a.comment, 2)) or -1
            end

            if b.comment and string.sub(b.comment, 1, 1) == "+" then
                priorityB = tonumber(string.sub(b.comment, 2)) or -1
            end

            return priorityA > priorityB
        end)

        if itemRarity >= 1 then
            GameTooltip:AddLine("Soft-Reserved List (" .. reservedNumber .. ")")
            if reservedNumber > 0 then
                for _, playerData in ipairs(reservedPlayers) do
                    if playerData.comment and string.len(playerData.comment) > 0 then
                        GameTooltip:AddLine(playerData.playerName .. " (" .. playerData.comment .. ")", 1, 1, 1)
                    else
                        GameTooltip:AddLine(playerData.playerName, 1, 1, 1)
                    end
                end
            end
        end

        GameTooltip:Show()
    end
end

function LootRes:OnHide()
    GameTooltip.itemLink = nil
end

function LootRes:InsertSRData()
	if getglobal('LootResLoadFromText'):IsShown() then
		LootRes:HideWindow()
		return
	end
	-- getglobal('LootResLoadFromTextTextBox'):SetText("")
	getglobal('LootResLoadFromText'):Show()
end

function LootRes:DeleteSRData()
	LootRes.db.profile.reserves = {}
	LootRes:Print('SR data has been removed.')
end

function LootRes:ResetLootHistory()
	LootRes.db.profile.loot_history = {}
	LootRes:Print('Looted History Reset.')
end

function LootRes:TestAnnounceSR()
	if LootRes.countTableEntries(LootRes.db.profile.reserves) == 0 then
		LootRes:Print("No SR data is provided for testing.")
		return
	end
	local items = {}
	local i = 0
    for playerName, reserveData in pairs(LootRes.db.profile.reserves) do
        if reserveData.items then
            for _, item in ipairs(reserveData.items) do
                if not items[item] then
                    items[item] = i
					i = i + 1
                end
            end
        end
    end
	
	rand = random(1, i)
	j = 1
	local itemPattrern = ''
	for item, _ in next, items do
		if rand == j then
			ritem = '|cff8fce00|Hitem:19019:::::::::::::::|h['..item..']|h|r'
			break
		end
		j = j + 1
	end
	arg1 = "SR "..ritem
	LootRes:Print('Testing SR announcement for "'..arg1..'" scenario!')
	LootRes:AnnounceSR(arg1)
end

function LootRes:SetAnnounceOption(cmd)
	local W = string.split(cmd, ' ')
	if string.len(W[2]) == 0 then
		LootRes:Print('No value provided. Please write 1 or 0 as parametr.')
		return
	end
	local Num = tonumber(W[2])
	if Num == 0 then
		LootRes.db.profile.announce_flag = Num
		LootRes:Print("There will be no announce for SR in the raid chat.")
	elseif Num == 1 then
		LootRes.db.profile.announce_flag = Num
		LootRes:Print('SR list will be announced when someone type: "[ItemLink] SR" in the raid chat.')
	elseif W[2] == '+' then
		LootRes.db.profile.roll_formula_flag = 1-LootRes.db.profile.roll_formula_flag
		if LootRes.db.profile.roll_formula_flag == 1 then
			LootRes:Print('SR list will be announced with formula according to Rank of the player.')
		else 
			LootRes:Print('SR list will be not announced with formula according to Rank of the player.')
		end
	else
		LootRes:Print("Provided wrong number: " .. Num .. ". Try 1 or 0 or +")
	end
end

function LootRes:PrepareExcelTextbox()
	if getglobal('LootResExcel'):IsShown() then
		LootRes:HideWindow()
		return
	end
		
	if not LootRes.db.profile.loot_history or next(LootRes.db.profile.loot_history) == nil then
		LootRes:Print("History of loot is empty.")
		return
	end
	local historyData = {}
	for playerName, lootData in next, LootRes.db.profile.loot_history do
		if lootData and table.getn(lootData) > 0 then
			for i, lootInfo in ipairs(lootData) do
				local startPos, endPos, itemName = string.find(lootInfo.item, "%[(.-)%]")
				table.insert(historyData, {playerName=playerName, itemName=itemName, timestamp=lootInfo.timestamp, time=lootInfo.time})
				-- playerLoot = playerName .. "," .. itemName .. "," ..lootInfo.timestamp .. ' ' .. date("%d.%m.%Y") .. '\n'
				-- lootHistoryMessage = lootHistoryMessage .. playerName .. "," .. itemName .. "," ..lootInfo.timestamp .. "\n"
			end
		end
	end
	table.sort(historyData, function(a, b)
        return a.time < b.time
	end)
	local lootHistoryMessage = ""
	for _, lootData in next, historyData do
		-- playerLoot = playerName .. "," .. itemName .. "," ..lootInfo.timestamp .. ' ' .. date("%d.%m.%Y") .. '\n'
		lootHistoryMessage = lootHistoryMessage .. LootRes:stringjoin(",", {lootData.playerName, lootData.itemName, lootData.timestamp}) .. "\n"
	end
	getglobal('LootResExcelTextBox'):SetText(lootHistoryMessage)
	getglobal('LootResExcel'):Show()

end

function LootRes:ShowHistoryLog(cmd)
	LootRes:Print('Showing loot history log:')
	if not LootRes.db.profile.loot_history or next(LootRes.db.profile.loot_history) == nil then
		LootRes:Print("History of loot is empty.")
		return
	end

	local lootHistoryMessage = ""

	for playerName, lootData in next, LootRes.db.profile.loot_history do
		if lootData and table.getn(lootData) > 0 then
			local playerLoot = playerName .. ": "

			for i, lootInfo in ipairs(lootData) do
				local itemLink = lootInfo.item

				if string.sub(itemLink, -1) == "." then
					itemLink = string.sub(itemLink, 1, -2)
				end

				playerLoot = playerLoot .. itemLink .. ' (' .. lootInfo.timestamp .. ')'

				if i < table.getn(lootData) then
					playerLoot = playerLoot .. ", "
				end
			end

			lootHistoryMessage = lootHistoryMessage .. playerLoot .. " & "
		end
	end

	lootHistoryMessage = string.sub(lootHistoryMessage, 1, -4)
	
	LootRes:Print(lootHistoryMessage)
	if cmd == 'raidlog' then
		LootRes:SendChatSplitMessage(lootHistoryMessage, "RAID")
	end
end

function LootRes:GetGuildInfo()
	GUILD_TABLE = {}
	for i=0,10000 do
		name, rankName, rankIndex, level, class, zone, note, 
		officernote, online, status, classFileName, 
		achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
		if name then
			if rankIndex == 0 or rankIndex == 1 or rankIndex == 2 then
				rank = 4
			elseif rankIndex == 3 then
				rank = 3
			elseif rankIndex == 4 then
				rank = 2
			elseif rankIndex == 5 or rankIndex == 6 or rankIndex == 7 or rankIndex == 8 or rankIndex == 9 then
				rank = 1
			end
			table.insert(GUILD_TABLE, LootRes:stringjoin(",", {name, class, rankName}))
		end
	end
	LootRes:Print('Total players loaded in GUILD_TABLE: '..table.getn(GUILD_TABLE)) 
end

function LootRes:ViewSRForPlayer(cmd)
	local W = string.split(cmd, ' ')
	local player = W[2]
	
	if LootRes.db.profile.reserves[player] then
		local reservedItems = LootRes.db.profile.reserves[player].items
		local comment = LootRes.db.profile.reserves[player].comment
		if table.getn(reservedItems) > 0 then
			LootRes:Print(player .. ' reserved: ' .. table.concat(reservedItems, ', ') .. (comment and ' (' .. comment .. ')' or ''))
		else
			LootRes:Print(player .. ' has no reserved items.')
		end
	else
		LootRes:Print(player .. ' has no reserved items.')
	end
	
	if not LootRes.db.profile.loot_history[player] then
		LootRes:Print(player .. ' - nothing looted.')
	else
		local lootHistory = {}
		for _, lootEntry in ipairs(LootRes.db.profile.loot_history[player]) do
			table.insert(lootHistory, lootEntry.item .. ' ('.. lootEntry.timestamp .. ')')
		end
		LootRes:Print(player .. ' - looted: ' .. table.concat(lootHistory, ', '))
	end
end

function LootRes:ClearSRForPlayer(cmd)
	local W = string.split(cmd, ' ')
	local player = W[2]
	LootRes.db.profile.loot_history[player] = nil
	LootRes:Print('Cleared ' .. player .. ' ')
end

function LootRes:Print(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('|cff69ccf0[LR]|cff0070de:' .. time() .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0[LR] |cffffffff" .. a)
end

function LootRes:modifyItemLink(itemLink, itemType)
    local modifier = ""
    if itemType == 'INVTYPE_WEAPONMAINHAND' then
        modifier = " (MH)"
    elseif itemType == 'INVTYPE_WEAPONOFFHAND' then
        modifier = " (OH)"
    end

    local modifiedLink = string.gsub(itemLink, "|h%[(.-)%]|h", "|h[%1" .. modifier .. "]|h")
    return modifiedLink
end

function LootRes:AnnounceSR(arg1)
	local lowerArg = string.lower(arg1)
	local firstOccurenceSR = strfind(lowerArg, '%f[%a][Ss][Rr]%f[^%a\']')
	local itemPattern = "|c.-|h%[.-%]|h|r"
	local UniqueOccurrenceSR = strfind(lowerArg, itemPattern .. "sr") or strfind(lowerArg, "sr" .. itemPattern)
	
	if firstOccurenceSR == nil and not LootRes:containsCP(arg1) and UniqueOccurrenceSR == nil then
		return
	end

	local startPos, endPos, itemLink, restOfString = string.find(arg1, "("..itemPattern..")")
	if not itemLink then
		return
	end

	if LootRes.db.profile.announce_flag == nil or LootRes.db.profile.announce_flag == 0 then
		LootRes:Print('Triggered, but LootRes announce feature not enabled, to enable that write "/lootres announce 1".')
		return
	end
	
	if LootRes.db.profile.reserves == nil or LootRes.countTableEntries(LootRes.db.profile.reserves) == 0 then
		LootRes:Print('Triggered, but data isn\'t loaded into LootRes, please use "/lootres load" to load reserves.')
		return
	end 
	local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	local itemName, _, _, _, _, _, _, itemType = GetItemInfo(Id)
	
	local modifiedItemLink = ''
	if itemName and itemName == 'Warblade of the Hakkari' then
		modifiedItemLink = LootRes:modifyItemLink(itemLink, itemType)
	else 
		modifiedItemLink = itemLink
	end 
	
	local startPos, endPos, modifieditemName, restOfString = string.find(modifiedItemLink, '%[(.*)%]')
	
	local playersInRaid = {}
	for i = 1, MAX_RAID_MEMBERS do
		local name = GetRaidRosterInfo(i)
		local guildName, guildRankName, guildRankIndex = GetGuildInfo('raid'..i)
		if name then
			local rank = 0
			if guildName == LootRes.guildName then
				if guildRankIndex == 0 or guildRankIndex == 1 or guildRankIndex == 2 then
					rank = 4
				elseif guildRankIndex == 3 then
					rank = 3
				elseif guildRankIndex == 4 then
					rank = 2
				elseif guildRankIndex == 5 or guildRankIndex == 6 or guildRankIndex == 7 or guildRankIndex == 8 or guildRankIndex == 9 then
					rank = 1
				end
			end
			playersInRaid[string.lower(name)] = rank
		end
	end

	local actualPlayers = {}
	local fakePlayers = {}
	
	for playerNameSR, playerData in next, LootRes.db.profile.reserves do
		if playerData and playerData.items then
			for _, playerItem in next, playerData.items do
				local lowerItemName = string.lower(modifieditemName)
				local lowerItem = string.lower(playerItem)

				if lowerItem == lowerItemName or string.find(lowerItem, lowerItemName) then
					local priority = nil
					if playerData.comment and string.sub(playerData.comment, 1, 1) == "+" then
						priority = tonumber(string.sub(playerData.comment, 2)) or 0
					end

					local playerEntry = {name = playerNameSR, priority = priority, rank = nil}
					-- local playerEntry = {name = playerNameSR, priority = priority}
					-- print(playersInRaid[string.lower(playerNameSR)])
					local playerInRaid = playersInRaid[string.lower(playerNameSR)]
					if playerInRaid ~= nil then
						playerEntry.rank = playerInRaid
						table.insert(actualPlayers, playerEntry)
					else
						table.insert(fakePlayers, playerEntry)
					end
				end
			end
		end
	end
	

	table.sort(actualPlayers, LootRes.RankSort)
	table.sort(fakePlayers, LootRes.RankSort)

	local actualPlayerList = ""
	for _, player in ipairs(actualPlayers) do
		if LootRes.db.profile.rank_flag == 1 then
			player.name = player.name .. LootRes.IntRank2StrRank(player.rank)
		end
		if player.priority and player.priority > 0 then
			if not LootRes.db.profile.roll_formula_flag == 1 then
				actualPlayerList = actualPlayerList .. player.name .. " (+" .. player.priority .. "), "
			else
				formula = ''
			    if player.rank == 4 then
					roll = 13*player.priority
					formula = '/roll '..tostring(roll+1)..'-'..tostring(roll+100)
				elseif player.rank == 3 then
					roll = 10*player.priority
					formula = '/roll '..tostring(roll+1)..'-'..tostring(roll+100)
				end
				if string.len(formula) > 0 then
					actualPlayerList = actualPlayerList .. player.name .. " (+" .. player.priority .. ", " .. formula .. "), "
				else
					actualPlayerList = actualPlayerList .. player.name .. " (+" .. player.priority .. "), "
				end
			end
		else
			actualPlayerList = actualPlayerList .. player.name .. ", "
		end
	end
	if string.len(actualPlayerList) > 0 then
		actualPlayerList = string.sub(actualPlayerList, 1, -3)
	end
	
	local fakePlayerList = ""
	for _, player in ipairs(fakePlayers) do
		if LootRes.db.profile.rank_flag == 1 then
			player.name = player.name .. LootRes.IntRank2StrRank(player.rank)
		end
		if player.priority and player.priority > 0 then
			fakePlayerList = fakePlayerList .. player.name .. " (+" .. player.priority .. "), "
		else
			fakePlayerList = fakePlayerList .. player.name .. ", "
		end
	end
	if string.len(fakePlayerList) > 0 then
		fakePlayerList = string.sub(fakePlayerList, 1, -3)
	end

	local msg = ""
	if string.len(actualPlayerList) > 0 then
		msg = "SR's for " .. modifiedItemLink .. ": " .. actualPlayerList
		if string.len(fakePlayerList) > 0 then
			msg = msg .. ". <Players who aren't in the raid>: " .. fakePlayerList
		end
	elseif string.len(fakePlayerList) > 0 then
		msg = "No actual SR's for " .. modifiedItemLink .. ", because these players aren't in the raid: " .. fakePlayerList
	else
		msg = "No one has SR'ed that item: " .. modifiedItemLink
	end
	
	LootRes:Print("Announced SR's for " .. modifiedItemLink .. '. If you want to cancel this feature write /lootres announce 0')
	LootRes:SendChatSplitMessage(msg, "RAID")
	LootRes.lastAnnounce= time()
end

function LootRes:SaveLootLog(arg)
	local lootMessage = arg1
	local playerName, itemLink = nil, nil

	local youLootPattern = "You receive loot: "
	local otherLootPattern = " receives loot: "

	local youLootPos = string.find(lootMessage, youLootPattern)
	local otherLootPos = string.find(lootMessage, otherLootPattern)

	if youLootPos then
		playerName = UnitName("player")
		itemLink = string.sub(lootMessage, youLootPos + string.len(youLootPattern))
		
	elseif otherLootPos then
		playerName = string.sub(lootMessage, 1, otherLootPos - 1)
		itemLink = string.sub(lootMessage, otherLootPos + string.len(otherLootPattern))
	end
	if itemLink then
		local xPos = string.find(itemLink, "x%d+") 
		if xPos then
			itemLink = string.sub(itemLink, 1, xPos - 1)
		else
			itemLink = string.sub(itemLink, 1, string.len(itemLink)-1)
		end
	end
	if playerName and itemLink then
		local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
		local itemName, _, _, _, _, _, _, itemType = GetItemInfo(Id)
	
		local isSR = false

		for reservePlayerName, playerData in next, LootRes.db.profile.reserves do
			for _, reservedItem in next, playerData.items do
				if string.lower(itemName) == string.lower(reservedItem) and string.lower(playerName) == string.lower(reservePlayerName) then
					isSR = true
					break
				end
			end
			if isSR then break end
		end

		if isSR then
			if not LootRes.db.profile.loot_history[playerName] then
				LootRes.db.profile.loot_history[playerName] = {}
			end
			
			table.insert(LootRes.db.profile.loot_history[playerName], {
				item = itemLink,
				timestamp = date("%H:%M:%S %d/%m/%y"),
				time = time()
			})

			LootRes:Print(playerName .. " got reserved item: " .. itemLink)
		end
	end
end

	
function LootRes:containsCP(msg)
    for i = 1, string.len(msg) - 3 do
        local firstByte = string.byte(msg, i)
        local secondByte = string.byte(msg, i + 1)

        if (firstByte == 208 and secondByte == 161) or (firstByte == 209 and secondByte == 129) then
            local thirdByte = string.byte(msg, i + 2)
            local fourthByte = string.byte(msg, i + 3)

            if (thirdByte == 208 and fourthByte == 160) or (thirdByte == 209 and fourthByte == 128) then

                local prevChar = string.byte(msg, i - 1)
                local nextChar = string.byte(msg, i + 4)

                local isPrevBoundary = (not prevChar or prevChar == 32)
                local isNextBoundary = (not nextChar or nextChar == 32 or nextChar == 46 or nextChar == 44) 

                if isPrevBoundary and isNextBoundary then
                    return true
                end
            end
        end
    end

    return false
end

function LootRes:SendChatSplitMessage(msg, chatType, n, delimeter)
    local maxMessageLength = n or 255
    local parts = {}

    delimeter = delimeter or ","

    local startPos = 1
    while true do
        local endPos = string.find(msg, delimeter, startPos, true)
        if not endPos then
            table.insert(parts, string.sub(msg, startPos))
            break
        else
            table.insert(parts, string.sub(msg, startPos, endPos - 1))
            startPos = endPos + string.len(delimeter)
        end
    end

    local messagePart = ""

    for i, part in ipairs(parts) do
        part = string.gsub(part, "^%s+", "")
        part = part .. delimeter .. " "

        if string.len(messagePart) + string.len(part) > maxMessageLength then
            messagePart = string.gsub(messagePart, delimeter .. "%s*$", " ->")
            SendChatMessage(messagePart, chatType)
            messagePart = ""
        end

        if string.len(messagePart) > 0 then
            messagePart = messagePart .. part
        else
            messagePart = part
        end
    end

    if string.len(messagePart) > 0 then
        messagePart = string.gsub(messagePart, delimeter .. "[%s]*$", ".")
        SendChatMessage(messagePart, chatType)
    end
end

function LootRes:HideWindow()
	getglobal('LootResLoadFromText'):Hide()
	getglobal('LootResExcel'):Hide()
end

function LootRes:LoadText()
    local data = getglobal('LootResLoadFromTextTextBox'):GetText()

    getglobal('LootResLoadFromText'):Hide()

    if data == '' then
        return false
    end

    data = LootResReplace(data, "Formula:", "Formula*dd*")
    data = LootResReplace(data, "Plans:", "Plans*dd*")
    data = LootResReplace(data, "Recipe:", "Recipe*dd*")
    data = LootResReplace(data, "Guide:", "Guide*dd*")
	data = LootResReplace(data, "Schematic:", "Schematic*dd*")

    LootRes.db.profile.reserves = {}

    data = LootRes.explode(data, "[")

    for i, d in data do
        if string.find(d, ']', 1, true) then
            local comment = LootRes.trim(string.sub(d, 1, string.find(d, ']') - 1))
            if comment == '00:00' then
				comment = nil
			end
            local pl = LootRes.explode(d, ']')
            local pl2 = LootRes.explode(pl[2], ':')
            local playerData = LootRes.explode(pl2[2], '-')
            local player = nil
            local item = nil
            for k, da in playerData do
				
                if k == 1 then
                    player = LootRes.trim(da)
                end
                if k == 2 then
                    item = da
                    item = LootResReplace(item, "Formula*dd*", "Formula:")
                    item = LootResReplace(item, "Plans*dd*", "Plans:")
                    item = LootResReplace(item, "Recipe*dd*", "Recipe:")
                    item = LootResReplace(item, "Guide*dd*", "Guide:")
					item = LootResReplace(item, "Schematic*dd*", "Schematic:")
                end
				if k == 3 then
					item = item .. '-' .. da
				end
            end
			if player and item then
				if not LootRes.db.profile.reserves[player] then
					LootRes.db.profile.reserves[player] = { items = {}, comment = comment }
				end
				item = LootRes.trim(item)
				table.insert(LootRes.db.profile.reserves[player].items, item)
			end
        end
    end

    LootRes:Print("Loaded reserves:")

    for player, data in pairs(LootRes.db.profile.reserves) do
		if data.comment then
			LootRes:Print("Player: " .. player .. " | items: " .. table.concat(data.items, ", ") .. " | comment: " .. data.comment)
		else
			LootRes:Print("Player: " .. player .. " | items: " .. table.concat(data.items, ", "))
		end

    end
end


function LootRes:PrintReserves()
    for playerName, reserveData in next, LootRes.db.profile.reserves do
        if reserveData.items then
            local itemList = ""
            for _, item in ipairs(reserveData.items) do
                itemList = itemList .. item .. ", "
            end
            if string.len(itemList) > 0 then
                itemList = string.sub(itemList, 1, -3)
            end

            local comment = ""
            if reserveData.comment and string.sub(reserveData.comment, 1, 1) == "+" then
                comment = " (" .. reserveData.comment .. ")"
            end
            LootRes:Print(playerName .. ": " .. itemList .. comment)
        end
    end
end

function LootRes:PrintRaidReserves()
	local raidMSG = ''
	local players = {}

	for playerName, _ in pairs(LootRes.db.profile.reserves) do
		table.insert(players, playerName)
	end
	
	table.sort(players)

	for _, playerName in ipairs(players) do
		local reserveData = LootRes.db.profile.reserves[playerName]
		if reserveData.items then
			local itemList = ""
			for _, item in ipairs(reserveData.items) do
				itemList = itemList .. '[' .. item .. ']' .. ", "
			end

			if string.len(itemList) > 0 then
				itemList = string.sub(itemList, 1, -3)
			end

			local comment = ""
			if reserveData.comment and string.sub(reserveData.comment, 1, 1) == "+" then
				local priority = tonumber(string.sub(reserveData.comment, 2)) or 0
				if priority > 0 then
					comment = " (+" .. priority .. ")"
				end
			end

			raidMSG = raidMSG .. playerName .. ": " .. itemList .. comment .. ' || '
		end
	end

	if string.len(raidMSG) > 0 then
		raidMSG = string.sub(raidMSG, 1, -5)
		LootRes:SendChatSplitMessage(raidMSG, "RAID", 170, '||')
	else
		LootRes:Print('No provided data to print, use </lootRes load> to insert data in addon.')
	end
end


function LootRes:PrintRaidReserves2()
	local guildTable = {}
	for i=0,1500 do
		name, rankName, rankIndex, level, class, zone, note, 
		officernote, online, status, classFileName, 
		achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
		if name then
			if rankIndex == 0 or rankIndex == 1 or rankIndex == 2 then
				rank = 4
			elseif rankIndex == 3 then
				rank = 3
			elseif rankIndex == 4 then
				rank = 2
			elseif rankIndex == 5 or rankIndex == 6 or rankIndex == 7 or rankIndex == 8 or rankIndex == 9 then
				rank = 1
			end
			guildTable[string.lower(name)] = rank
		end
	end

    local itemsToPlayers = {}
    for playerName, reserveData in pairs(LootRes.db.profile.reserves) do
        if reserveData.items then
            for _, item in ipairs(reserveData.items) do
                if not itemsToPlayers[item] then
                    itemsToPlayers[item] = {}
                end
                table.insert(itemsToPlayers[item], {
                    name = playerName,
                    rank = guildTable[string.lower(playerName)] or 0,
                    priority = tonumber(string.sub(reserveData.comment or "", 2)) or 0
                })
            end
        end
    end

    for _, players in pairs(itemsToPlayers) do
        table.sort(players, function(a, b)
            if a.rank ~= b.rank then
                return a.rank > b.rank
            else
                return a.priority > b.priority
            end
        end)
    end

    local raidMSG = ""
    for item, players in pairs(itemsToPlayers) do
        local playerList = ""
        for _, playerData in ipairs(players) do
            local comment = ""
            if playerData.priority > 0 then
                comment = " (+" .. playerData.priority .. ")"
            end
			if LootRes.db.profile.rank_flag == 1 then
				playerName = playerData.name .. LootRes.IntRank2StrRank(playerData.rank)
			else
				playerName = playerData.name
			end
			
            playerList = playerList .. playerName .. comment .. ", "
        end

        if string.len(playerList) > 0 then
            playerList = string.sub(playerList, 1, -3)
        end

        raidMSG = raidMSG .. "[" .. item .. "]: " .. playerList .. " || "
    end

    if string.len(raidMSG) > 0 then
        raidMSG = string.sub(raidMSG, 1, -5)
        LootRes:SendChatSplitMessage(raidMSG, "RAID", 170, '||')
    else
        LootRes:Print('No provided data to print, use </lootres load> to insert data in addon.')
    end
end

function LootRes:PrintRaidReserves3()
	local guildTable = {}
	for i=0,1500 do
		name, rankName, rankIndex, level, class, zone, note, 
		officernote, online, status, classFileName, 
		achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
		if name then
			if rankIndex == 0 or rankIndex == 1 or rankIndex == 2 then
				rank = 4
			elseif rankIndex == 3 then
				rank = 3
			elseif rankIndex == 4 then
				rank = 2
			elseif rankIndex == 5 or rankIndex == 6 or rankIndex == 7 or rankIndex == 8 or rankIndex == 9 then
				rank = 1
			end
			guildTable[string.lower(name)] = rank
		end
	end
	
    local playersInRaid = {}
    for i = 1, MAX_RAID_MEMBERS do
        local name = GetRaidRosterInfo(i)
		if name then
			name = string.lower(name)
			playersInRaid[name] = guildTable[name]
		end
    end

    local itemsToPlayers = {}
    for playerName, reserveData in pairs(LootRes.db.profile.reserves) do
        if reserveData.items and playersInRaid[string.lower(playerName)] then
            for _, item in ipairs(reserveData.items) do
                if not itemsToPlayers[item] then
                    itemsToPlayers[item] = {}
                end
					table.insert(itemsToPlayers[item], {
						name = playerName,
						rank = guildTable[string.lower(playerName)] or 0,
						priority = tonumber(string.sub(reserveData.comment or "", 2)) or 0
					})
            end
        end
    end

    for _, players in pairs(itemsToPlayers) do
        table.sort(players, function(a, b)
            if a.rank ~= b.rank then
                return a.rank > b.rank
            else
                return a.priority > b.priority
            end
        end)
    end

    local raidMSG = ""
    for item, players in pairs(itemsToPlayers) do
        local playerList = ""
        for _, playerData in ipairs(players) do
            local comment = ""
            if playerData.priority > 0 then
                comment = " (+" .. playerData.priority .. ")"
            end
			if LootRes.db.profile.rank_flag == 1 then
				playerName = playerData.name .. LootRes.IntRank2StrRank(playerData.rank)
			else
				playerName = playerData.name
			end
			
            playerList = playerList .. playerName .. comment .. ", "
        end

        if string.len(playerList) > 0 then
            playerList = string.sub(playerList, 1, -3)
        end

        raidMSG = raidMSG .. "[" .. item .. "]: " .. playerList .. " || "
    end

    if string.len(raidMSG) > 0 then
        raidMSG = string.sub(raidMSG, 1, -5)
        LootRes:SendChatSplitMessage(raidMSG, "RAID", 170, '||')
    else
        LootRes:Print('No provided data to print, use </lootres load> to insert data in addon.')
    end
end


function LootRes:SearchPlayerOrItem(search)
    LootRes:Print("*" .. LootResReplace(search, "search ", "") .. "*")
end
function LootResReplace(text, search, replace)
    if search == replace then
        return text
    end
    local searchedtext = ""
    local textleft = text
    while string.find(textleft, search, 1, true) do
        searchedtext = searchedtext .. string.sub(textleft, 1, string.find(textleft, search, 1, true) - 1) .. replace
        textleft = string.sub(textleft, string.find(textleft, search, 1, true) + string.len(search))
    end
    if string.len(textleft) > 0 then
        searchedtext = searchedtext .. textleft
    end
    return searchedtext
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
    end
    table.insert(result, string.sub(self, from))
    return result
end

function LootRes:stringjoin(delimiter, list)
    if type(list) ~= "table" then
        error("Second argument must be a table")
    end

    local result = {}
    for _, value in ipairs(list) do
        table.insert(result, tostring(value))
    end

    return table.concat(result, delimiter)
end

function LootRes:CheckReserves()
    for playerName, reserveData in next, LootRes.db.profile.reserves do
        if reserveData.items then
            for _, item in ipairs(reserveData.items) do
                LootRes:Print("Checking item for " .. playerName .. ": " .. item)
                
                local itemName = GetItemInfo(item)
		
                if itemName then
                    LootRes:Print("Item name: " .. itemName)
                else
                    LootRes:Print("Item not found for: " .. item)
                end
            end
        end
    end
end


function LootRes.trim(s)
    if not s then
        return false
    end
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

function LootRes.explode(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from, 1, true)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from, true)
    end
    table.insert(result, string.sub(str, from))
    return result
end

function LootRes.countTableEntries(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end


function LootRes.IntRank2StrRank(num)
    local romanNumerals = {
		[0] = "",
        [1] = " [I]",
        [2] = " [II]",
        [3] = " [III]",
        [4] = " [IV]",
        [5] = " [V]",
        [6] = " [VI]",
        [7] = " [VII]",
        [8] = " [VIII]",
        [9] = " [IX]"
    }
    return romanNumerals[num] or ''
end

function LootRes.RankSort(a, b)
	if a.rank and b.rank then
        if a.rank ~= b.rank then
            return a.rank > b.rank
        end
    elseif a.rank then
        return true
    elseif b.rank then
        return false
    end

    if a.priority and b.priority then
        return a.priority > b.priority
    elseif a.priority then
        return true
    elseif b.priority then
        return false
    else
        return false
    end
end

function LootRes.PriorSort(a, b)
    if a.priority and b.priority then
        return a.priority > b.priority
    elseif a.priority then
        return true
    elseif b.priority then
        return false
    else
        return false
    end
end
