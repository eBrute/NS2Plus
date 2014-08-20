// FEELIN' LAZY, JUST PUT ALL THIS CRAP IN A SINGLE FILE

Script.Load("lua/GUIInsight_Overhead.lua")
local originalInsightOverheadSendKeyEvent
originalInsightOverheadSendKeyEvent = Class_ReplaceMethod("GUIInsight_Overhead", "SendKeyEvent",
	function(self, key, down)
		// DO NOTHING, HEHEHE!
	end)

local lastPlayerId = Entity.invalidId
local originalInsightOverheadUpdate
originalInsightOverheadUpdate = Class_ReplaceMethod("GUIInsight_Overhead", "Update",
	function(self, deltaTime)
		originalInsightOverheadUpdate(self, deltaTime)
		
		local player = Client.GetLocalPlayer()
		if player == nil then
			return
		end
		
		local entityId = player.selectedId
		if entityId and entityId ~= Entity.invalidId then
			local entity = Shared.GetEntity(entityId)
			
			-- If we're not in relevancy range, get the position from the mapblips
			if not entity then
				for _, blip in ientitylist(Shared.GetEntitiesWithClassname("MapBlip")) do

					if blip.ownerEntityId == entityId then
					
						local blipOrig = blip:GetOrigin()
						player:SetWorldScrollPosition(blipOrig.x, blipOrig.z)
						
					end
				end
				-- Try to get the player again
				entity = Shared.GetEntity(entityId)
			end
			
			-- If the player is dead, or the entity is not a player, deselect
			if entity and entity:isa("Player") and entity:GetIsAlive() then
				local origin = entity:GetOrigin()
				player:SetWorldScrollPosition(origin.x, origin.z)
			else
				entityId = Entity.invalidId
			end
			
			if lastPlayerId ~= entityId then
				Client.SendNetworkMessage("SpectatePlayer", {entityId = entityId}, true)
				lastPlayerId = entityId
			end
		end
	end)
	
Script.Load("lua/GUIInsight_PlayerFrames.lua")
local originalInsightPlayerFramesInit
originalInsightPlayerFramesInit = Class_ReplaceMethod("GUIInsight_PlayerFrames", "Initialize",
	function(self)
		originalInsightPlayerFramesInit(self)
		self.prevKeyStatus = false
	end)
	
local originalInsightPlayerFramesSendKeyEvent
originalInsightPlayerFramesSendKeyEvent = Class_ReplaceMethod("GUIInsight_PlayerFrames", "SendKeyEvent",
	function(self, key, down)
		
		local isVisible = GetUpValue( originalInsightPlayerFramesSendKeyEvent, "isVisible", { LocateRecurse = true } )
		local kPlayersPanelSize = GetUpValue( originalInsightPlayerFramesSendKeyEvent, "kPlayersPanelSize", { LocateRecurse = true } )
		local kFrameYSpacing = GetUpValue( originalInsightPlayerFramesSendKeyEvent, "kFrameYSpacing", { LocateRecurse = true } )
		if isVisible and key == InputKey.MouseButton0 and self.prevKeyStatus ~= down and not down then
			
			local cursor = MouseTracker_GetCursorPos()
			
			for index, team in ipairs(self.teams) do

				local inside, posX, posY = GUIItemContainsPoint( team.Background, cursor.x, cursor.y )
				if inside then
					local player = Client.GetLocalPlayer()
					local index = math.floor( posY / (kPlayersPanelSize.y + kFrameYSpacing) ) + 1
					local entityId = team.PlayerList[index].EntityId
						   
					// When clicking the same player, deselect so it stops following
					if player.selectedId == entityId then
						entityId = Entity.invalidId
					end

					Client.SendNetworkMessage("SpectatePlayer", {entityId = entityId}, true)
					
				end
			end
			
		end
		
		if key == InputKey.MouseButton0 then
			self.prevKeyStatus = down
		end
		
		return false
	end)
	
local originalPlayerOnEntityChange
originalPlayerOnEntityChange = Class_ReplaceMethod("Player", "OnEntityChange",
	function(self, oldEntityId, newEntityId)
		originalPlayerOnEntityChange(self, oldEntityId, newEntityId)
		-- If this is a player changing classes that we're already following, update the id
		local player = Client.GetLocalPlayer()
		if player.selectedId == oldEntityId then
			Client.SendNetworkMessage("SpectatePlayer", {entityId = newEntityId}, true)
			player.selectedId = newEntityId
		end
	end)