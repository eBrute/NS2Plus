local kTeamMessages = GetUpValue(OnCommandTeamMessage, "kTeamMessages", { LocateRecurse = true })

local function SetTeamMessage(messageType, messageData)
	local player = Client.GetLocalPlayer()
	if player and HasMixin(player, "TeamMessage") then
		local displayText = kTeamMessages[messageType].text[player:GetTeamType()]
		
		if displayText then
		
			if type(displayText) == "function" then
				displayText = displayText(messageData)
			else
				displayText = Locale.ResolveString(displayText)
			end
			
			assert(type(displayText) == "string")
			player:SetTeamMessage(string.UTF8Upper(displayText))
		end
	end
end

ReplaceUpValue(OnCommandTeamMessage, "SetTeamMessage", SetTeamMessage, { LocateRecurse = true, CopyUpValues = true })