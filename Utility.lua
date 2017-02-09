------------------------------------------------------------------------
-- UTILITY
------------------------------------------------------------------------
-- This file contains utility methods used by the rest of thea ddon
------------------------------------------------------------------------

-- ================================
-- Helper method. Returns the id of the currently
-- selected table (if working with multiple dkp tables)
-- ================================
function WebDKP_GetTableid()
	local tableid = WebDKP_Frame.selectedTableid;
	if (tableid == nil ) then
		tableid = 1;
	end
	return tableid;
end





-- ================================
-- Helper method for should display. Returns true if the specified player
-- is in the current group
-- ================================
function WebDKP_PlayerInGroup(name)
	for key, entry in pairs(WebDKP_PlayersInGroup) do
		if ( type(entry) == "table" ) then
			if ( entry["name"] == name) then
				return true;
			end
		end
	end
	return false;
end


-- ================================
-- Returns the guild name of a specified player. This attempts this
-- in a few ways. First tries to get it via raid data. If not in a raid
-- it attempts to get it via party data. If all these fail, it returns
-- "Unknown" which is a marker for the webdkp.com site to try to get
-- the real guild name sometime in the future. 
-- ================================
function WebDKP_GetGuildName(playerName)
	-- this is a big pain - we can't just query a player for a guild, 
	-- we need to find their slot in the current raid / party and query
	-- that slot...
	
	-- First try running through all the people in the current raid...
	local numberInRaid = GetNumRaidMembers();
	local name, class;
	for i=1, numberInRaid do
		name, _, _, _, _, _, _, _ , _ = GetRaidRosterInfo(i);
		if ( name == playerName) then
			guild, _, _ = GetGuildInfo("raid"..i);
			return guild;
		end
	end
	
	-- No go, now try running through people in the current party --
	local numberInParty = GetNumPartyMembers();
	for i=1, numberInParty do
		playerHandle = "party"..i;
		name = UnitName(playerHandle);
		if( name == playerName ) then
			guild, _, _ = GetGuildInfo("raid"..i);
			return guild;
		end
	end
	
	-- no go, try the current player
	if( playerName == UnitName("player") ) then
		guild, _, _ = GetGuildInfo("player");
		return guild;
	end
	
	-- all failed, return unknown
	return "Unknown";

end

-- ================================
-- Helper method for awarding an item. 
-- Returns the name of the first selected player
-- If no one is selected returns 'NONE'
-- ================================
function WebDKP_GetFirstSelectedPlayer()
	for k, v in pairs(WebDKP_DkpTable) do
		if ( type(v) == "table" ) then
			if( v["Selected"] ) then
				name = k; 
				return name;
			end
		end
	end
	return "NONE";
end

-- ================================
-- Helper method. Returns the size
-- of the passed table. Returns 0 if
-- the passed variable is nil.
-- ================================
function WebDKP_GetTableSize(table)
	local count = 0;
	if( table == nil ) then
		return count;
	end
	for key, entry in pairs(table) do
		count = count + 1;
	end
	return count;
end

-- ================================
-- Prints a message to the console. Used for debugging
-- ================================
function WebDKP_Print(toPrint)
	DEFAULT_CHAT_FRAME:AddMessage(toPrint, 1, 1, 0);
end

-- ================================
-- Gets information on the specified item, where item is the item link
-- Returns: color, item name, itemLink
-- ================================
function WebDKP_GetItemInfo(sItem)
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, invTexture = GetItemInfo(sItem);
	if ( itemRarity and itemName and itemLink ) then
		return itemRarity, itemName, itemLink;
	else
		return 0, sItem, sItem;
	end
end


-- ================================
-- Selects a single specified player in the table. 
-- All other players are unselected. 
-- Causes this player to be shown in the table, even if
-- they do not pass filters
-- ================================
function WebDKP_SelectPlayerOnly(toHighlight)
	for k, v in pairs(WebDKP_DkpTable) do
		if ( type(v) == "table" ) then
			local playerName = k;
			if ( playerName == toHighlight ) then
				WebDKP_DkpTable[playerName]["Selected"] = true;
			else
				WebDKP_DkpTable[playerName]["Selected"] = false;
			end
		end
	end
	-- If the player is not currently shown in the table, add them (otherwise we can't see if they are highlighted)
	if( WebDKP_PlayerIsShown(toHighlight) == 0 ) then
		WebDKP_ShowPlayer(toHighlight);
	end
	WebDKP_UpdateTable();
end

-- ================================
-- Returns true if the specified player is currently 
-- shown in the table to the left
-- ================================
function WebDKP_PlayerIsShown(playerName)
	for k, v in pairs(WebDKP_DkpTableToShow) do
		if ( type(v) == "table" ) then
			local player = v[1];
			if ( player == playerName) then
				-- yes, they are being shown
				return 1;
			end
		end
	end
	--no, they arn't being shown
	return 0;
end

-- ================================
-- Shows a player on the table to the left
-- Used if they are not automattically shown via a filter
-- and to force them to be appended. 
-- ================================
function WebDKP_ShowPlayer(playerName)
	if ( WebDKP_DkpTable[playerName] == nil ) then
		return;
	end
	local tableid = WebDKP_GetTableid();
	local playerClass = WebDKP_DkpTable[playerName]["class"];
	local playerDkp = WebDKP_DkpTable[playerName]["dkp_"..tableid];
	if ( playerDkp == nil ) then 
		playerDkp = 0;
	end
	local playerTier = floor((playerDkp-1)/WebDKP_TierInterval);
	if( playerDkp == 0 ) then
		playerTier = 0;
	end
	tinsert(WebDKP_DkpTableToShow,{playerName,playerClass,playerDkp,playerTier});
end



-- ================================
-- Helper method. Rounds the given number to the specified number
-- of decimal places.
-- Example: Round(22.4242,2) returns 22.42
-- ================================
function WebDKP_ROUND( num, idp )
	return tonumber( string.format("%."..idp.."f", num ) )
end

-- ================================
-- Helper method. Gets the dkp of the passed player
-- in the currently active table
-- ================================
function WebDKP_GetDKP(playerName)
	local tableid = WebDKP_GetTableid();
	-- make sure the player exists in our table
	if(WebDKP_DkpTable[playerName] == nil ) then
		local class = WebDKP_GetPlayerClass(playerName);
		WebDKP_DkpTable[playerName] = {
			["dkp_"..tableid] = 0,
			["class"] = class,
		}
	end
	
	-- check what their dkp is in the current table
	if(WebDKP_DkpTable[playerName]["dkp_"..tableid] == nil ) then
		WebDKP_DkpTable[playerName]["dkp_"..tableid] = 0;
	end
	
	return WebDKP_DkpTable[playerName]["dkp_"..tableid];
end

-- ================================
-- Helper method. Returns the class name
-- of the given player. Player MUST
-- be in current dkp table
-- ================================
function WebDKP_GetPlayerClass(playerName)
	local playerClass = WebDKP_DkpTable[playerName]["class"];
	if(WebDKP_DkpTable[playerName]==nil) then
		playerClass = "Hunter";
	end
	return playerClass;
end

function WebDKP_GetCmd(msg)
 	if msg then
 		local a,b,c=strfind(msg, "(%S+)"); --contiguous string of non-space characters
 		if a then
 			return c, strsub(msg, b+2);
 		else	
 			return "";
 		end
 	end
end

function WebDKP_GetCommaCmd(msg)
 	if msg then
 		local a = strfind(msg, ",");
 		if a then
 			local first = strtrim(strsub(msg,0, a-1));
 			local second = strtrim(strsub(msg,a+1));
 			return first, second;
 		else	
 			return msg;
 		end
 	end
end

-- ================================
-- For whisper event hook - sends a whisper back
-- to the given person with a webdkp header so it 
-- will not be displayed in regular whisper chat
-- ================================
function WebDKP_SendWhisper(toPlayer, message)
	SendChatMessage("WebDKP: "..message, "WHISPER", nil, toPlayer)
end


-- ================================
-- Starts a bidding auction for ItemLink corresponding 
-- to the item the mouse is over in the loot frame
-- ================================

function WebDKP_MouseoverBidStart()
	local f=GetMouseFocus():GetName(); 
	if string.sub(f,1,10)=="LootButton" then 
		local slotID = GetMouseFocus():GetID();
		local i,n,_,r,l = GetLootSlotInfo(slotID);
		local link = GetLootSlotLink(slotID);
		local mQ=GetLootThreshold(); 
		if     i~=nil and r>=mQ then 
			SendChatMessage("?startbid "..link, "WHISPER", nil, GetUnitName("PLAYER"))
		end
	end
end

-- ================================
-- Mousing over an item in the loot window and 
-- invoking MasterlootItem, while being the master looter
-- will award the item to the player, provided it is below epic quality
-- Useful for BWL sands, lava cores etc
-- ================================

function MasterlootItem()
	for ci = 1, GetNumRaidMembers() do
		if (GetMasterLootCandidate(ci) == UnitName("player")) then
			local f=GetMouseFocus():GetName(); 
				if string.sub(f,1,10)=="LootButton" then 
					local slotID = GetMouseFocus():GetID();
					local i,n,_,r,l = GetLootSlotInfo(slotID);
					if r<=3 then
						GiveMasterLoot(slotID, ci);
					end
				end
		end
	end
end
