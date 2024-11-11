
local LootRes = CreateFrame("Frame", "LootRes", GameTooltip)
LootRes:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
LootRes:RegisterEvent("CHAT_MSG_WHISPER")
LootRes:RegisterEvent("CHAT_MSG_SYSTEM")
LootRes:RegisterEvent("ADDON_LOADED")
LootRes:RegisterEvent("CHAT_MSG_LOOT")
LootRes:RegisterEvent("CHAT_MSG_RAID")
LootRes:RegisterEvent("CHAT_MSG_RAID_LEADER")

local rollsOpen = false
local rollers = {}
local maxRoll = 0
local reservedNames = ""

local secondsToRoll = 12
local T = 1
local C = secondsToRoll
local lastRolledItem = ""
local offspecRoll = false

function lrprint(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('|cff69ccf0[LR]|cff0070de:' .. time() .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0[LR] |cffffffff" .. a)
end

LootRes.Player = ''
LootRes.Item = ''
LootRes.Name = ''
lastAnnounce = 0
if ANNOUNCE_FLAG == nil then
	ANNOUNCE_FLAG = 1
end

if LOOT_RES_LOOT_HISTORY == nil then
	LOOT_RES_LOOT_HISTORY = {}
end

if LOOTRES_RESERVES == nil then
	LOOTRES_RESERVES = {}
end


SLASH_LOOTRES1 = "/lootres"
SlashCmdList["LOOTRES"] = function(cmd)
    if cmd then
        if string.find(cmd, 'savelast', 1, true) then
            saveLast(cmd)
        end
        if cmd == 'print' then
            LootRes:PrintReserves()
		elseif cmd == 'raidprint' then
			lrprint('WTF')
			LootRes:PrintRaidReserves()
        elseif cmd == 'load' then
            getglobal('LootResLoadFromTextTextBox'):SetText("")
            getglobal('LootResLoadFromText'):Show()
		elseif cmd == 'raidlog' or cmd == 'log' then
			lrprint('Showing loot history log:')
			if not LOOT_RES_LOOT_HISTORY or next(LOOT_RES_LOOT_HISTORY) == nil then
				lrprint("History of loot is empty.")
				return
			end

			local lootHistoryMessage = ""

			for playerName, lootData in next, LOOT_RES_LOOT_HISTORY do
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
			
			lrprint(lootHistoryMessage)
			if cmd == 'raidlog' then
				SendChatSplitMessage(lootHistoryMessage, "RAID")
			end
		elseif cmd == 'excel' then
			if not LOOT_RES_LOOT_HISTORY or next(LOOT_RES_LOOT_HISTORY) == nil then
				lrprint("History of loot is empty.")
				return
			end

			local lootHistoryMessage = ""
			local playerLoot = ""
			for playerName, lootData in next, LOOT_RES_LOOT_HISTORY do
				if lootData and table.getn(lootData) > 0 then
					for i, lootInfo in ipairs(lootData) do
						local startPos, endPos, itemName = string.find(lootInfo.item, "%[(.-)%]")
						-- playerLoot = playerName .. "," .. itemName .. "," ..lootInfo.timestamp .. ' ' .. date("%d.%m.%Y") .. '\n'
						lootHistoryMessage = lootHistoryMessage .. playerName .. "," .. itemName .. "," ..lootInfo.timestamp .. "\n"
					end
				end
			end
			getglobal('LootResExcelTextBox'):SetText(lootHistoryMessage)
            getglobal('LootResExcel'):Show()
		elseif cmd == 'reset' then
            LOOT_RES_LOOT_HISTORY = {}
            lrprint('Looted History Reset.')
		elseif cmd == 'delete' then
            LOOTRES_RESERVES = {}
            lrprint('All reserves have been deleted.')
		elseif string.find(cmd, 'announce', 1, true) then
			local W = string.split(cmd, ' ')
			if string.len(W[2]) == 0 then
				lrprint('No value provided. Please write 1 or 0 as parametr.')
				return
			end
			local Num = tonumber(W[2])
			if Num == 0 then
				ANNOUNCE_FLAG = Num
				lrprint("There will be no announce for SR in the raid chat.")
			elseif Num == 1 then
				ANNOUNCE_FLAG = Num
				lrprint('SR list will be announced when someone type: "[ItemLink] SR" in the raid chat.')
			else
				lrprint("Provided wrong number: " .. Num .. ". Try 1 or 0")
			end
		elseif string.find(cmd, 'view', 1, true) then
			local W = string.split(cmd, ' ')
			local player = W[2]
			
			if LOOTRES_RESERVES[player] then
				local reservedItems = LOOTRES_RESERVES[player].items
				local comment = LOOTRES_RESERVES[player].comment
				if table.getn(reservedItems) > 0 then
					lrprint(player .. ' reserved: ' .. table.concat(reservedItems, ', ') .. (comment and ' (' .. comment .. ')' or ''))
				else
					lrprint(player .. ' has no reserved items.')
				end
			else
				lrprint(player .. ' has no reserved items.')
			end
			
			if not LOOT_RES_LOOT_HISTORY[player] then
				lrprint(player .. ' - nothing looted.')
			else
				local lootHistory = {}
				for _, lootEntry in ipairs(LOOT_RES_LOOT_HISTORY[player]) do
					table.insert(lootHistory, lootEntry.item .. ' ('.. lootEntry.timestamp .. ')')
				end
				lrprint(player .. ' - looted: ' .. table.concat(lootHistory, ', '))
			end
        elseif string.find(cmd, 'clear', 1, true) then
            local W = string.split(cmd, ' ')
            local player = W[2]
            LOOT_RES_LOOT_HISTORY[player] = nil
            lrprint('Cleared ' .. player .. ' ')
		else
			lrprint('Commands for LootRes:')
			lrprint('/lootres load - Load parsed data from https://raidres.fly.dev/')
			lrprint('/lootres delete - Delete all reserves from LootRes.')
			lrprint('/lootres print - Show reserved items.')
			lrprint('/lootres raidprint - Show reserved items for Raid.')
			lrprint('/lootres announce 1 or 0 - Enable/Disable announce SR feature for raid chat.')
			lrprint('/lootres log - View Loot History.')
			lrprint('/lootres raidlog - Show Loot History for Raid.')
			lrprint('/lootres excel - View textbox with Loot History.')
			lrprint('/lootres reset - Reset Loot History.')
			lrprint('/lootres view PlayerName - Check looted items for PlayerName.')
			lrprint('/lootres clear PlayerName - Delete looted history for PlayerName.')
        end
    end
end


LootRes:SetScript("OnEvent", function()
	-- if event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY" then
		-- printable = gsub(arg1, "\124", "\124\124");
		-- print(printable)
	-- end
	if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING") and (time() - lastAnnounce > 5) then
		LootRes:AnnounceSR(arg1)
	elseif event == "CHAT_MSG_LOOT" then
		LootRes:SaveLootLog(arg1)
	end
end)


LootRes:SetScript("OnShow", function()
    local reservedNumber = 0
    local reservedPlayers = {}

    if GameTooltip.itemLink then
        local _, _, itemLink = string.find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)")

        if not itemLink then
            return false
        end
		if LOOTRES_RESERVES == nil or LootRes.countTableEntries(LOOTRES_RESERVES) == 0 then
			return false
		end 
        local itemName, _, itemRarity = GetItemInfo(itemLink)

        for playerName, playerData in next, LOOTRES_RESERVES do
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
end)

LootRes:SetScript("OnHide", function()
    GameTooltip.itemLink = nil
end)

function modifyItemLink(itemLink, itemType)
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
	
	if firstOccurenceSR == nil and not containsCP(arg1) and UniqueOccurrenceSR == nil then
		return
	end

	local startPos, endPos, itemLink, restOfString = string.find(arg1, "("..itemPattern..")")
	if not itemLink then
		return
	end

	if ANNOUNCE_FLAG == nil or ANNOUNCE_FLAG == 0 then
		lrprint('Triggered, but LootRes announce feature not enabled, to enable that write "/lootres announce 1".')
		return
	end
	
	if LOOTRES_RESERVES == nil or LootRes.countTableEntries(LOOTRES_RESERVES) == 0 then
		lrprint('Triggered, but data isn\'t loaded into LootRes, please use "/lootres load" to load reserves.')
		return
	end 
	local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	local itemName, _, _, _, _, _, _, itemType = GetItemInfo(Id)
	
	local modifiedItemLink = ''
	if itemName and itemName == 'Warblade of the Hakkari' then
		modifiedItemLink = modifyItemLink(itemLink, itemType)
	else 
		modifiedItemLink = itemLink
	end 
	
	local startPos, endPos, modifieditemName, restOfString = string.find(modifiedItemLink, '%[(.*)%]')
	
	local playersInRaid = {}
	for i = 1, MAX_RAID_MEMBERS do
		local name = GetRaidRosterInfo(i)
		if name then
			playersInRaid[string.lower(name)] = true
		end
	end

	local actualPlayers = {}
	local fakePlayers = {}
	
	for playerNameSR, playerData in next, LOOTRES_RESERVES do
		if playerData and playerData.items then
			for _, playerItem in next, playerData.items do
				local lowerItemName = string.lower(modifieditemName)
				local lowerItem = string.lower(playerItem)

				if lowerItem == lowerItemName or string.find(lowerItem, lowerItemName) then
					local priority = nil
					if playerData.comment and string.sub(playerData.comment, 1, 1) == "+" then
						priority = tonumber(string.sub(playerData.comment, 2)) or 0
					end

					local playerEntry = {name = playerNameSR, priority = priority}

					if playersInRaid[string.lower(playerNameSR)] then
						table.insert(actualPlayers, playerEntry)
					else
						table.insert(fakePlayers, playerEntry)
					end
				end
			end
		end
	end
	
	-- actualPlayers = fakePlayers
	-- fakePlayers = {}

	table.sort(actualPlayers, function(a, b)
		if a.priority and b.priority then
			return a.priority > b.priority
		elseif a.priority then
			return true
		elseif b.priority then
			return false
		else
			return false
		end
	end)
	table.sort(fakePlayers, function(a, b)
		if a.priority and b.priority then
			return a.priority > b.priority
		elseif a.priority then
			return true
		elseif b.priority then
			return false
		else
			return false
		end
	end)

	local actualPlayerList = ""
	for _, player in ipairs(actualPlayers) do
		if player.priority and player.priority > 0 then
			actualPlayerList = actualPlayerList .. player.name .. " (+" .. player.priority .. "), "
		else
			actualPlayerList = actualPlayerList .. player.name .. ", "
		end
	end
	if string.len(actualPlayerList) > 0 then
		actualPlayerList = string.sub(actualPlayerList, 1, -3)
	end
	
	local fakePlayerList = ""
	for _, player in ipairs(fakePlayers) do
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
	
	lrprint("Announced SR's for " .. modifiedItemLink .. '. If you want to cancel this feature write /lootres announce 0')
	SendChatSplitMessage(msg, "RAID")
	lastAnnounce = time()
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

		for reservePlayerName, playerData in next, LOOTRES_RESERVES do
			for _, reservedItem in next, playerData.items do
				if string.lower(itemName) == string.lower(reservedItem) and string.lower(playerName) == string.lower(reservePlayerName) then
					isSR = true
					break
				end
			end
			if isSR then break end
		end

		if isSR then
			if not LOOT_RES_LOOT_HISTORY[playerName] then
				LOOT_RES_LOOT_HISTORY[playerName] = {}
			end
			
			table.insert(LOOT_RES_LOOT_HISTORY[playerName], {
				item = itemLink,
				timestamp = date("%H:%M:%S")
			})

			lrprint(playerName .. " got reserved item: " .. itemLink)
		end
	end
end

	
function containsCP(msg)
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

function SendChatSplitMessage(msg, chatType, n, delimeter)
    local maxMessageLength = n or 255
    local parts = {}

    -- Устанавливаем разделитель, по умолчанию запятая
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
        part = string.gsub(part, "^%s+", "")  -- Убираем пробелы в начале
        part = part .. delimeter .. " "       -- Добавляем разделитель

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
        -- Заменяем конечный разделитель на точку
        messagePart = string.gsub(messagePart, delimeter .. "[%s]*$", ".")
        SendChatMessage(messagePart, chatType)
    end
end

function LootRes:ScanUnit(target)
    if not UnitIsPlayer(target) then
        return nil
    end
    return 0, 0, 0, 0
end

local LootResHookSetBagItem = GameTooltip.SetBagItem
function GameTooltip.SetBagItem(self, container, slot)
    GameTooltip.itemLink = GetContainerItemLink(container, slot)
    _, GameTooltip.itemCount = GetContainerItemInfo(container, slot)
    return LootResHookSetBagItem(self, container, slot)
end

local LootResHookSetLootItem = GameTooltip.SetLootItem
function GameTooltip.SetLootItem(self, slot)
    GameTooltip.itemLink = GetLootSlotLink(slot)
    LootResHookSetLootItem(self, slot)
end


function LootResHideWindow()
	getglobal('LootResExcel'):Hide()
end

function LootResLoadText()
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

    LOOTRES_RESERVES = {}

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
				if not LOOTRES_RESERVES[player] then
					LOOTRES_RESERVES[player] = { items = {}, comment = comment }
				end
				item = LootRes.trim(item)
				table.insert(LOOTRES_RESERVES[player].items, item)
			end
        end
    end

    lrprint("Loaded reserves:")

    for player, data in pairs(LOOTRES_RESERVES) do
		if data.comment then
			lrprint("Player: " .. player .. " | items: " .. table.concat(data.items, ", ") .. " | comment: " .. data.comment)
		else
			lrprint("Player: " .. player .. " | items: " .. table.concat(data.items, ", "))
		end

    end
end



function LootRes:PrintReserves()
    for playerName, reserveData in next, LOOTRES_RESERVES do
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
            lrprint(playerName .. ": " .. itemList .. comment)
        end
    end
end

function LootRes:PrintRaidReserves()
	local raidMSG = ''
	local players = {}

	for playerName, _ in pairs(LOOTRES_RESERVES) do
		table.insert(players, playerName)
	end
	
	table.sort(players)

	for _, playerName in ipairs(players) do
		local reserveData = LOOTRES_RESERVES[playerName]
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
		SendChatSplitMessage(raidMSG, "RAID", 170, '||')
	else
		lrprint('No provided data to print, use </lootres load> to insert data in addon.')
	end
end

function LootRes:SearchPlayerOrItem(search)
    lrprint("*" .. LootResReplace(search, "search ", "") .. "*")
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


function LootRes:CheckReserves()
    for playerName, reserveData in next, LOOTRES_RESERVES do
        if reserveData.items then
            for _, item in ipairs(reserveData.items) do
                lrprint("Checking item for " .. playerName .. ": " .. item)
                
                local itemName = GetItemInfo(item)
		
                if itemName then
                    lrprint("Item name: " .. itemName)
                else
                    lrprint("Item not found for: " .. item)
                end
            end
        end
    end
end

function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, function(a, b)
        return a < b
    end)
    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

LootRes.RESERVES = {
    ['Er'] = 'test'
}


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
