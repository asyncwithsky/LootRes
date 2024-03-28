local LootRes = CreateFrame("Frame", "LootRes", GameTooltip)
LootRes:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
LootRes:RegisterEvent("CHAT_MSG_WHISPER")
LootRes:RegisterEvent("CHAT_MSG_SYSTEM")
LootRes:RegisterEvent("ADDON_LOADED")
LootRes:RegisterEvent("CHAT_MSG_LOOT")

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


LootRes:SetScript("OnShow", function()

    local reservedNumber = 0
    if GameTooltip.itemLink then
        local _, _, itemLink = string.find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)");

        if not itemLink then
            return false
        end

        local itemName, _, itemRarity = GetItemInfo(itemLink)

        for _, item in next, LOOTRES_RESERVES do
            if string.lower(itemName) == string.lower(item) then
                reservedNumber = reservedNumber + 1
            end
        end

        if itemRarity >= 3 then

            GameTooltip:AddLine("Soft-Reserved List (" .. reservedNumber .. ")")

            if (reservedNumber > 0) then
                for playerName, item in next, LOOTRES_RESERVES do
                    if (string.lower(itemName) == string.lower(item)) then
                        GameTooltip:AddLine(playerName, 1, 1, 1)
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

SLASH_LOOTRES1 = "/lootres"
SlashCmdList["LOOTRES"] = function(cmd)
    if cmd then
        if string.find(cmd, 'savelast', 1, true) then
            saveLast(cmd)
        end
        if cmd == 'print' then
            LootRes:PrintReserves()
        end
        if cmd == 'load' then
            getglobal('LootResLoadFromTextTextBox'):SetText("")
            getglobal('LootResLoadFromText'):Show()
        end
        if cmd == 'loadold' then
            LOOTRES_RESERVES = LootRes.RESERVES
            lrprint("Loaded from old way")
            for player, item in LOOTRES_RESERVES do
                lrprint("Player: " ..player .. ", item: " .. item)
            end
        end
        if cmd == 'check' then
            LootRes:CheckReserves()
        end
        if cmd == 'reset' then
            LOOT_RES_LOOT_HISTORY = {}
            lrprint('Looted History Reset.')
        end
        if string.find(cmd, 'view', 1, true) then
            local W = string.split(cmd, ' ')
            local player = W[2]
            if LOOTRES_RESERVES[player] then
                lrprint(player .. ' reserved ' .. LOOTRES_RESERVES[player])
            end
            if not LOOT_RES_LOOT_HISTORY[player] then
                lrprint(player .. ' - nothing looted ')
            else
                lrprint(player .. ' - looted ' .. LOOT_RES_LOOT_HISTORY[player])
            end
        end
        if string.find(cmd, 'clear', 1, true) then
            local W = string.split(cmd, ' ')
            local player = W[2]
            LOOT_RES_LOOT_HISTORY[player] = nil
            lrprint('Cleared ' .. player .. ' ')
        end
        if string.find(cmd, "search", 1, true) then
            LootRes:SearchPlayerOrItem(cmd)
        end
    end
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

    LOOTRES_RESERVES = {}

    data = LootRes.explode(data, "[")

    for i, d in data do
        if string.find(d, ']', 1, true) then
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
                    item = LootRes.trim(da)

                    item = LootResReplace(item, "Formula*dd*", "Formula:")
                    item = LootResReplace(item, "Plans*dd*", "Plans:")
                    item = LootResReplace(item, "Recipe*dd*", "Recipe:")
                    item = LootResReplace(item, "Guide*dd*", "Guide:")
                end
                if k == 3 then
                    item = LootRes.trim(playerData[2] .. "-" .. playerData[3])

                    item = LootResReplace(item, "Formula*dd*", "Formula:")
                    item = LootResReplace(item, "Plans*dd*", "Plans:")
                    item = LootResReplace(item, "Recipe*dd*", "Recipe:")
                    item = LootResReplace(item, "Guide*dd*", "Guide:")
                end
                if player and item then
                    if LOOTRES_RESERVES[player] ~= nill then
                        player = player.."s"
                    end
                    LOOTRES_RESERVES[player] = item
                end

            end
        end
    end

    lrprint("Loaded reserves:")

    for player, item in LOOTRES_RESERVES do
        lrprint("Player: " ..player .. ", item: " .. item)
    end
end

function LootRes:PrintReserves()

    for playerName, item in next, LOOTRES_RESERVES do
        lrprint(playerName .. ":" .. item)
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
    for n, i in next, LOOTRES_RESERVES do
        lrprint(" checking " .. i)
        local itemName = GetItemInfo(i)
        lrprint(itemName)
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
