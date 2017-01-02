------------------------------------------------------------------------
-- AUTO FILL Tasks
------------------------------------------------------------------------
-- This file contains methods related to auto filling in information in your dkp
-- form when items drop
------------------------------------------------------------------------


StaticPopupDialogs["WEBDKP_AUTOAWARD_MOREINFO"] = {
	text = "Award ", --%s %s
	button1 = "Yes",
	button2 = "No",
	--OnShow = function()
		-- getglobal(this:GetName().."EditBox"):SetText("");
		-- notice: "this" is the StaticPopup, normaly its "StaticPopup1"
	--end,
	--OnAccept = function()
		-- local cost = getglobal(this:GetParent():GetName().."EditBox"):GetText();
		--WebDKP_AutoAward(cost);
	--end,
	timeout = 30,
	whileDead = 1,
	hideOnEscape = 1,
	hasEditBox = 1
};

-- ================================
-- Helper structure that maps rarity of an item back to its rank
-- ================================
WebDKP_RarityTable = {
	[0] = -1,
	[1] = 0,
	[2] = 1,
	[3] = 2,
	[4] = 3,
	[5] = 4
};

-- ================================
-- An event that is triggered when loot is taken. If auto fill 
-- is enabled, this must check to see:
-- 1 - what item dropped and fill it in the item input
-- 2 - see what player got the item and select them
-- 3 - see if the item is in the loot table, and enter the cost if it is
-- 4 - if auto award is enabled it should award the item
-- ================================
function WebDKP_Loot_Taken()
	if ( WebDKP_Options["AutofillEnabled"] == 0 ) then
		return;
	end
	local sPlayer, sLink;
	local iStart, iEnd, sPlayerName, sItem = string.find(arg1, "([^%s]+) receives loot: (.+)%.");
	if ( sPlayerName ) then
		sPlayer = sPlayerName;
		sLink = sItem;
	else
		local iStart, iEnd, sItem = string.find(arg1, "You receive loot: (.+)%.");
		if ( sItem ) then
			sPlayer = UnitName("player");
			sLink = sItem;
		end
	end
	if ( sLink and sPlayer ) then
		local sRarity, sName, sItem = WebDKP_GetItemInfo(sLink);
		local rarity = WebDKP_RarityTable[sRarity];
		local cost = nil; 
		if( rarity < WebDKP_Options["AutofillThreshold"] ) then
			return;
		end
		WebDKP_AwardItem_FrameItemName:SetText(sName);
		-- see if we can determine the cost while we are at it...
		if ( WebDKP_Loot ~= nil ) then
			cost = WebDKP_Loot[sName];
			if ( cost ~= nil ) then 
				WebDKP_AwardItem_FrameItemCost:SetText(cost);
			else
				WebDKP_AwardItem_FrameItemCost:SetText("");
			end
		end
		WebDKP_SelectPlayerOnly(sPlayer);
		
		-- if we are set to auto award items, go ahead and attempt it
		-- we'll need to make sure we have all the data
		if (WebDKP_Options["AutoAwardEnabled"] == 1) then
			--PlaySound("QUESTADDED");
			if ( cost ~= nil ) then
				WebDKP_ShowAwardFrame("Award "..sPlayer.." "..sLink.." for "..cost.." DKP? \r\n (Enter DKP below, positive numbers only)",cost);
				WebDKP_AwardFrameCost:SetText(cost);
			else
				WebDKP_ShowAwardFrame("Award "..sPlayer.." "..sLink.."? \r\n (Enter DKP below, positive numbers only)",nil);
				--PlaySound("igQuestFailed");
			end
		end
	end
end


function WebDKP_ShowAwardFrame(title, cost)
	PlaySound("igMainMenuOpen");
	WebDKP_AwardFrame:Show();
	
	WebDKP_AwardFrameTitle:SetText(title);
	if(cost ~= nil) then
		WebDKP_AwardFrameCost:SetText(cost);
	else
		WebDKP_AwardFrameCost:SetText("");
	end
end

-- ================================
-- Callback function from clicking 'yes' on the autoaward dialog box
-- ================================
function WebDKP_AutoAward(cost)
	WebDKP_AwardItem_FrameItemCost:SetText(cost);
	WebDKP_AwardItem_Event();
end

-- ================================
-- Event handler for entering a name in the award item field
-- Will automattically fill in the cost if the cost is available in the players toot table
-- ================================
function WebDKP_AutoFillCost()
	if ( WebDKP_Options["AutofillEnabled"] == 0 ) then
		return;
	end
	local sName = WebDKP_AwardItem_FrameItemName:GetText();
	
	-- see if we can determine the cost while we are at it...
	if ( WebDKP_Loot ~= nil and sName ~= nil) then
		local cost = WebDKP_Loot[sName];
		if ( cost ~= nil ) then 
			WebDKP_AwardItem_FrameItemCost:SetText(cost);
		end
	end
end


-- ================================
-- Event handler for entering a name in the award dkp reason field
-- Will automattically fill in the cost if the cost is available in the players toot table
-- ================================
function WebDKP_AutoFillDKP()
	if ( WebDKP_Options["AutofillEnabled"] == 0 ) then
		return;
	end
	local sName = WebDKP_AwardDKP_FrameReason:GetText();
	
	-- see if we can determine the cost while we are at it...
	if ( WebDKP_Loot ~= nil and sName ~= nil) then
		local cost = WebDKP_Loot[sName];
		if ( cost ~= nil ) then 
			WebDKP_AwardDKP_FramePoints:SetText(cost);
		end
	end
end

-- ================================
-- Toggles whether or not autofill is enabled
-- ================================
function WebDKP_ToggleAutofill()
	-- is enabled, disable it
	if ( WebDKP_Options["AutofillEnabled"] == 1 ) then
		WebDKP_Options_FrameToggleAutofill:SetChecked(0);
		WebDKP_Options["AutofillEnabled"] = 0;
		WebDKP_Options_FrameAutofillDropDown:Hide();
		WebDKP_Options_FrameToggleAutoAward:Hide();
	-- is disabled, enable it
	else
		WebDKP_Options_FrameToggleAutofill:SetChecked(1);
		WebDKP_Options["AutofillEnabled"] = 1;
		WebDKP_Options_FrameAutofillDropDown:Show();
		WebDKP_Options_FrameToggleAutoAward:Show();
	end
end

-- ================================
-- Toggles autoaward. When enabled item awards will be done automattically for you
-- if all information can be auto filled. 
-- ================================
function WebDKP_ToggleAutoAward()
	-- is enabled, disable it
	if ( WebDKP_Options["AutoAwardEnabled"] == 1 ) then
		WebDKP_Options["AutoAwardEnabled"] = 0;
	-- is disabled, enable it
	else
		WebDKP_Options["AutoAwardEnabled"] = 1;
	end
end

-- ================================
-- Invoked when the gui loads up the drop down list of the autofill threshold
-- ================================
function WebDKP_Options_Autofill_DropDown_OnLoad()
	UIDropDownMenu_Initialize(WebDKP_Options_FrameAutofillDropDown, WebDKP_Options_Autofill_DropDown_Init);
end
-- ================================
-- Invoked when the drop down list for the autofill option  is loaded
-- ================================
function WebDKP_Options_Autofill_DropDown_Init()
	local info;
	local selected = "";
	WebDKP_AddAutofillChoice("Gray Items",-1);
	WebDKP_AddAutofillChoice("White Items",0);
	WebDKP_AddAutofillChoice("Green Items",1);
	WebDKP_AddAutofillChoice("Blue Items",2);
	WebDKP_AddAutofillChoice("Purple Items",3);
	WebDKP_AddAutofillChoice("Orange Items",4);
	
	UIDropDownMenu_SetWidth(130, WebDKP_Options_FrameAutofillDropDown);
end
-- ================================
-- Helper method that adds a choice to the Autofill dropdown
-- ================================
function WebDKP_AddAutofillChoice(text, value)
	info = { };
	info.text = text;
	info.value = value; 
	info.func = WebDKP_Options_Autofill_DropDown_OnClick;
	if ( value == WebDKP_Options["AutofillThreshold"] ) then
		info.checked = ( 1 == 1 );
		UIDropDownMenu_SetSelectedName(WebDKP_Options_FrameAutofillDropDown, info.text );
	end
	UIDropDownMenu_AddButton(info);
end

-- ================================
-- Called when the user switches between different autofill threshholds
-- ================================
function WebDKP_Options_Autofill_DropDown_OnClick()
	WebDKP_Options["AutofillThreshold"] = this.value; 
	WebDKP_Options_Autofill_DropDown_Init();
end

