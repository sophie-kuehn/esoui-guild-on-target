--------------------------------------------------------------------------------------------------------------------
--
-- ESO GuildOnTarget
--
-- This Add-on is not created by, affiliated with or sponsored by ZeniMax Media Inc. or its affiliates. 
-- The Elder Scrolls® and related logos are registered trademarks or trademarks of ZeniMax Media Inc. in the United States and/or other countries. 
-- All rights reserved
--
--------------------------------------------------------------------------------------------------------------------

local AddonInfo = {
  addon = "GuildOnTarget",
  version = "1.0",
  author = "Sophie Kuehn",
  savename = "GuildOnTarget"
}

local GOT = {}
GOT.guild = {}

-- localize calls to ESO API
local GetUnitType = GetUnitType
local GetUnitName = GetUnitName
local GetGuildMemberInfo = GetGuildMemberInfo
local GetGuildMemberCharacterInfo = GetGuildMemberCharacterInfo
local GetGuildId = GetGuildId
local GetGuildName = GetGuildName
local GetNumGuildMembers = GetNumGuildMembers
local IsUnitIgnored = IsUnitIgnored

-- GUILD METHODS ---------------------------------------------------------------------------------------------------

local function getGuildMembership()	
	local guildnum = 0
		
	GOT.guild = {}
	GOT.guild.member = {}
	
	for guildnum = 1,5,1 do
		local id = GetGuildId(guildnum)
		
		if id then 
			local members = GetNumGuildMembers(id)
			local guildname = GetGuildName(id)
		
			-- update character history based on the member information
			local member = 0
			
			for member = 1,members,1 do
				local player, note, rank, status, activelast = GetGuildMemberInfo(id,member)
				local hasCharacter, characterName, zoneName, classid, alliance, level, championRank = GetGuildMemberCharacterInfo(id,member)

				if hasCharacter and members>1 then
					local caret = string.len(characterName) - 3
					local character = ""
					if caret>0 then
						character = string.sub(characterName,1,caret)
					end
					-- add player in database
					GOT.guild.member[player]={}
					GOT.guild.member[player].character = character
					GOT.guild.member[player].firstguild = GOT.guild.member[player].firstguild or { size = 0, name = "" }
					if GOT.guild.member[player].firstguild.size<members then
						GOT.guild.member[player].firstguild.name = guildname
						GOT.guild.member[player].firstguild.size = members
					end			
				end
			end
		end
	end
end   

local function clearGuildTable()
	local index
	for index in pairs (GOT.guild.member) do
		GOT.guild.member[index].character = nil
		GOT.guild.member[index].firstguild = { size = 0, name="" }
		GOT.guild.member[index].size = { }
		GOT.guild.member[index].guildlist = nil
		GOT.guild.member[index].guild = nil
		GOT.guild.member[index] = false
	end
end

local function IsUnitGuild(player)
	local guild = nil
	local maxrank = 0
	local inguild = player and GOT and GOT.guild and GOT.guild.member and GOT.guild.member[player]
	if inguild then
		guild = GOT.guild.member[player].firstguild.name
	end
	return inguild, guild
end

local function guildMemberAdded(eventCode, guildId, displayName)
	clearGuildTable()
	getGuildMembership()
end 

local function guildMemberRemoved(eventCode, guildId, displayName, characterName)
	clearGuildTable()
	getGuildMembership()
end   
   
local function guildSelfLeft(eventCode, guildId, guildName)
	clearGuildTable()
	getGuildMembership()
end   

local function guildSelfJoined(eventCode, guildId, guildName)
	clearGuildTable()
	getGuildMembership()
end 

-- TARGET CHANGE EVENT --------------------------------------------------------------------------------------------- 
-- this fires when the target changes, then sets everything up for the next UI update   

function OnTargetChange(eventCode)
	local unitTag = "reticleover"
	local type = GetUnitType(unitTag)
	local name = GetUnitName(unitTag)
	local player = GetUnitDisplayName(unitTag)
	
	if name == nil or name == "" or type ~= UNIT_TYPE_PLAYER or IsUnitIgnored(unitTag) then return end

    local inguild, guild = IsUnitGuild(player) 

  	if inguild then 
        local guildName = "<"..guild..">"
	    ZO_TargetUnitFramereticleoverCaption:SetText(ZO_TargetUnitFramereticleoverCaption:GetText() .. " " .. guildName)
    end
end

-- REGISTER AND INIT -----------------------------------------------------------------------------------------------

local function LoadAddon(eventCode, addOnName)
	if(addOnName ~= AddonInfo.addon) then return end

	getGuildMembership()

    if (LibNorthCastle) then LibNorthCastle:Register(AddonInfo.addon,AddonInfo.version) end
	
	EVENT_MANAGER:RegisterForEvent(AddonInfo.addon, EVENT_GUILD_MEMBER_CHARACTER_UPDATED, guildMemberAdded)
	EVENT_MANAGER:RegisterForEvent(AddonInfo.addon, EVENT_GUILD_MEMBER_ADDED, guildMemberAdded)
	EVENT_MANAGER:RegisterForEvent(AddonInfo.addon, EVENT_GUILD_MEMBER_REMOVED, guildMemberRemoved)
	EVENT_MANAGER:RegisterForEvent(AddonInfo.addon, EVENT_GUILD_SELF_JOINED_GUILD, guildSelfJoined)
	EVENT_MANAGER:RegisterForEvent(AddonInfo.addon, EVENT_GUILD_SELF_LEFT_GUILD, guildSelfLeft) 
	EVENT_MANAGER:RegisterForEvent(AddonInfo.addon, EVENT_RETICLE_TARGET_CHANGED, OnTargetChange)
	EVENT_MANAGER:UnregisterForEvent(AddonInfo.addon, EVENT_ADD_ON_LOADED)	
end
   
EVENT_MANAGER:RegisterForEvent(AddonInfo.addon, EVENT_ADD_ON_LOADED, LoadAddon)

