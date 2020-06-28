-- Item.Client = {};

-- local SCAAMBRCustomItem = {
--     Methods = {
--         Client = {},
--         Server = {
--             -- Checks it this item exist on the cleanup table and will remove it ONLY if the game being played
--             -- is different than the current game
--             OnInit = function (self)
--                 Log('Initializing this item');
--                 if (SCAAMBRGameNumber ~= nil) then
--                     if (SCAAMBRCleanupPositions['Game' .. tostring(SCAAMBRGameNumber - 1)] ~= nil) then
--                         for key, value in pairs(SCAAMBRCleanupPositions['Game' .. tostring(SCAAMBRGameNumber - 1)]) do
--                             if (DistanceVectors(self:GetWorldPos(), value.Position) <= 0.1 and self.class == value.ClassName) then
--                                 System.RemoveEntity(self.id);
--                                 table.remove(SCAAMBRCleanupPositions['Game' .. tostring(SCAAMBRGameNumber - 1)], key);
--                                 break;
--                             end
--                         end
--                     end
--                 end
--             end
--         },
--         OnDestroy = function(self)
--             -- Checks if this is called through server
--             if (CryAction.IsServer()) then
--                 Log('Destroying this item');
--                 -- Checks if a game is taking place so this is not saving coordinates from removed entities
--                 -- that are not part of the relevance system
--                 if (SCAAMBattleRoyaleProperties ~= nil) then
--                     if (SCAAMBattleRoyaleProperties.GameState == 'Active') then

--                         -- Checks if the destroyed item has no owner, meaning it was on ground, unfortunatelly
--                         -- this is gonna catch items that probably were legitimately destroyed by damage or by beign used in the case of
--                         -- stim packs but I hope these false positives are minimal
--                         if (tostring(self.item:GetOwnerId()) == 'userdata: 0000000000000000') then
--                             local removedEntityData = {
--                                 Position = self:GetWorldPos(),
--                                 -- A random direction, just to have it there, it won't affect anything
--                                 Direction = self:GetDirectionVector(),
--                                 ClassName = self.class
--                             };

--                             -- Checks if the entity was already added so there's no duplicates
--                             local hasValue = false;

--                             -- Checks if the table for the current game hasn't been created so it's defined
--                             if (SCAAMBRCleanupPositions['Game' .. tostring(SCAAMBRGameNumber)] == nil) then
--                                 SCAAMBRCleanupPositions['Game' .. tostring(SCAAMBRGameNumber)] = {};
--                             end

--                             for key, value in pairs(SCAAMBRCleanupPositions['Game' .. tostring(SCAAMBRGameNumber)]) do
--                                 if (DistanceVectors(removedEntityData.Position, value.Position) <= 0.1 and removedEntityData.ClassName == value.ClassName) then
--                                     hasValue = true;
--                                     break;
--                                 end
--                             end
                
--                             if (hasValue == false) then
--                                 table.insert(SCAAMBRCleanupPositions['Game' .. tostring(SCAAMBRGameNumber)], removedEntityData);
--                             end
--                         end
--                     end
--                 end
--             end
--         end
--     },
--     Expose = {
--         ClientMethods = {},
--         ServerMethods = {},
--         ServerProperties = {}
--     }
-- }

-- Log(">> Loading mFramework SCAAMBRCustomItem");
-- local _status, _result = mReExpose('Item', SCAAMBRCustomItem.Methods, SCAAMBRCustomItem.Expose);
-- Log(">> Result: " .. tostring(_status or "Failed") .. " " .. tostring(_result or "No Message"));