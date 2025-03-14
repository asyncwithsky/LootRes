
LootRes:RegisterDefaults("profile", {
	reserves = {},
	loot_history = {},
	announce_flag = 1,
	roll_formula_flag = 1,
	rank_flag = 1,
	colorize_rank = 1,
})

local announceOptions = {
	["guildranks"] = {
		type = "toggle",
		name = "Display Rank",
		desc = "Announce with Guild Ranks",
		order = 1,
		get = function()
			return LootRes.db.profile.rank_flag == 1
		end,
		set = function(v)
			if v == true then
				LootRes.db.profile.rank_flag  = 1
			else
				LootRes.db.profile.rank_flag  = 0
			end
		end,
	}, 
	["rankformula"] = {
		type = "toggle",
		name = "Display Formula",
		desc = "Enable feature to announce SR with formulas for bonuses like /roll 70-169",
		order = 2,
		get = function()
			return LootRes.db.profile.roll_formula_flag == 1
		end,
		set = function(v)
			if v == true then
				LootRes.db.profile.roll_formula_flag = 1
			else
				LootRes.db.profile.roll_formula_flag = 0
			end
		end,
	},
	["colorizeranks"] = {
		type = "toggle",
		name = "Display Color for Ranks",
		desc = "Enable feature to display ranks in the raid chat",
		order = 2,
		get = function()
			return LootRes.db.profile.colorize_rank == 1
		end,
		set = function(v)
			if v == true then
				LootRes.db.profile.colorize_rank = 1
			else
				LootRes.db.profile.colorize_rank = 0
			end
		end,
	},
}

local raidprints = {
	["raidprint1"] = {
		type = "execute",
		name = "Print <Player:Items> data",
		desc = "Printing player and his items data without rank, all players are accounted",
		order = 1,
		func = LootRes.PrintRaidReserves,
	},
	["raidprint2"] = {
		type = "execute",
		name = "Print <Item:Players> data (All Players)",
		desc = "Printing item and players data with Ranks, all players are accounted",
		order = 2,
		func = LootRes.PrintRaidReserves2,
	},
	["raidprint3"] = {
		type = "execute",
		name = "Print <Item:Players> data (Only In-Raid Players)",
		desc = "Printing item and players data with Ranks, only account players in raid",
		order = 3,
		func = LootRes.PrintRaidReserves3,
	},
}


LootRes.cmdtable = {
	type = "group",
	handler = LootRes,
	args = {
		["loadsr"] = {
			type = "execute",
			name = "Load SR",
			desc = "Open textbox for entering SR parse data in Lootres",
			order = 1,
			func = LootRes.InsertSRData,
		},
		["announce"] = {
			type = "toggle",
			name = "Enable Announcements",
			desc = "Announce SR in the raidchat if SR list loaded in LootRes",
			order = 2,
			get = function()
				return LootRes.db.profile.announce_flag == 1
			end,
			set = function(v)
				if v == true then
					LootRes.db.profile.announce_flag = 1
				else
					LootRes.db.profile.announce_flag = 0
				end
			end,
		},
		["testsr"] = {
			type = "execute",
			name = "Test Announce",
			desc = "Try to get a random item from item pool and tests it for announcement.",
			order = 3,
			func = LootRes.TestAnnounceSR,
		},
		["announce_options"] = {
			type = "group",
			name = "Announcements options",
			desc = "Announcements options",
			order = 3,
			args = announceOptions
		},
		["srprints"] = {
			type = "group",
			name = "SR print options",
			desc = "Various functions for printing data for the raid",
			order = 4,
			args = raidprints
		},

		["spacer1"] = {
			type = "header",
			name = " ",
			order = 5,
		},
		["spacer2"] = {
			type = "header",
			name = "Miscellaneous",
			order = 6,
		},
		["excel"] = {
			type = "execute",
			name = "Show loot history",
			desc = "Prepare excel data for SR looted history",
			order = 7,
			func = LootRes.PrepareExcelTextbox
		},
		["guildinfo"] = {
			type = "execute",
			name = "Load Guild Info",
			desc = "Check SavedVariables/LootRes.lua for GUILD_INFO table for players and their ranks.",
			order = 8,
			func = LootRes.GetGuildInfo,
		},
		["resethistory"] = {
			type = "execute",
			name = "Reset loot history",
			desc = "Reset SR loot history for commands \n/lootres excel \n/lootres log",
			order = 9,
			func = LootRes.ResetLootHistory,
		},
		["deletesr"] = {
			type = "execute",
			name = "Delete SR",
			desc = "Clear all loaded SR data from LootRes.",
			order = 10,
			func = LootRes.DeleteSRData,
		},
	},
}

local deuce = LootRes:NewModule("LootRes Options Menu")
deuce.hasFuBar = IsAddOnLoaded("FuBar") and FuBar
deuce.consoleCmd = not deuce.hasFuBar


LootResOptions = AceLibrary("AceAddon-2.0"):new("AceDB-2.0", "FuBarPlugin-2.0")
local tablet = AceLibrary("Tablet-2.0")
LootResOptions.name = "FuBar - LootRes"
LootResOptions:RegisterDB("LootResDB")
LootResOptions.hasIcon = "Interface\\Icons\\inv_misc_bag_10_black"
LootResOptions.defaultMinimapPosition = 200
LootResOptions.independentProfile = true
LootResOptions.hideWithoutStandby = false

LootResOptions.OnMenuRequest = LootRes.cmdtable

local args = AceLibrary("FuBarPlugin-2.0"):GetAceOptionsDataTable(LootResOptions)
for k, v in pairs(args) do
	if LootResOptions.OnMenuRequest.args[k] == nil then
		LootResOptions.OnMenuRequest.args[k] = v
	end
end

function LootResOptions:OnTooltipUpdate()
	if LootResOptions:IsActive() then
		tablet:SetHint("\n|cffeda55fLeft Click|r to load SR data.\n|cffeda55fRight Click|r to open menu.")
	end
end

function LootResOptions:OnMouseDown(button)
	if (button == "LeftButton") then
	   LootRes:InsertSRData()
	end
end
 
