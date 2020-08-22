local SCAAMBRCustomPlayer = {
    Methods = {
        Client = {
            -- SCAAMBRUIInit
            -- Inits the custom UI support for the players
            SCAAMBRUIInit = function(self)
                ReloadModUIOnlyOnce();
            end,

            -- SCAAMBRPlaySoundDat
            -- Plays a sound for the player
            SCAAMBRPlaySoundDat = function (self, soundName)
                local soundTriggerID = AudioUtils.LookupTriggerID(soundName);

                if (soundTriggerID ~= nil) then
                    self:ExecuteAudioTrigger(soundTriggerID, self:GetDefaultAuxAudioProxyID());
                end
            end,
                
            -- SCAAMBRInitThePlayer
            -- Initializes a player
            SCAAMBRInitThePlayer = function (self)
                -- Assigns the battle royale custom keys
                System.AddCCommand('SCAAMBRStimPack', 'SCAAMBRApplyStimPackByKey(%1)', '');
                System.AddCCommand('SCAAMBRArmor', 'SCAAMBRApplyArmorByKey(%1)', '');
                System.AddCCommand('SCAAMBRMenu', 'SCAAMBRManageMenu(%1)', '');
                System.AddKeyBind('7', 'SCAAMBRStimPack number7');
                System.AddKeyBind('8', 'SCAAMBRArmor number8');
                System.AddKeyBind('backspace', 'SCAAMBRMenu backspace');
                System.AddKeyBind('escape', 'SCAAMBRMenu escape');
                System.AddKeyBind('tilde', 'SCAAMBRMenu tilde');
                System.AddKeyBind('delete', 'SCAAMBRMenu delete');
                System.AddKeyBind('left', 'SCAAMBRMenu left');
                System.AddKeyBind('right', 'SCAAMBRMenu right');

                -- Sets the custom client variables
                self.SCAAMBRCurrentGun = nil;
                self.SCAAMBRStimPackCounter = 0;
                self.SCAAMBRArmorCounter = 0;
                self.SCAAMBRToggledUI = false;
                self.SCAAMBRToggledLobbyUI = true;
                self.SCAAMBRToggledMapUI = false;
                self.SCAAMBRToggledSpectatorUI = false;
                self.SCAAMBRFrozenPlayer = false;
                self.SCAAMBRMenuState = 'idle';
                self.SCAAMBRUIBuiltJSON = '';
                self.SCAAMBRUIBuiltChunkCounter = 0;
                self.SCAAMBRItemCheckCounter = 0;

                self.SCAAMBRSpectatedPlayerId = nil;
                -- Sets the player original model to return to it once it stops spectating
                self.SCAAMBROriginalCGF = nil;
                if (self:GetMaterial(0) == 'objects/characters/players/male/skeleton/skeleton_male') then
                    self.SCAAMBROriginalCGF = 'Objects/Characters/players/male/human_male.cdf';
                else
                    self.SCAAMBROriginalCGF = 'Objects/Characters/players/female/human_female.cdf';
                end

                self.SCAAMBRAntiButtonSpamCounter = 0;
                -- self.SCAAMBRSpectatedPlayer = nil;
                -- self.SCAAMBRToggledSpectateUI = false;
                -- self.SCAAMBRSavedOwnPosition = {};

                SCAAMBRStartPlayerGeneralUpdate();
            end,

            -- SCAAMBRBuildTheDataUI
            -- Builds the UI data based on small chunks, due to RMI limitations a string
            -- can't be greater than 1030 characters, so it needs to be constructed on multiple
            -- RMI calls
            SCAAMBRBuildTheDataUI = function (self, operation, stillHasChunks, insertedChunks, totalChunks, chunkOne, chunkTwo, chunkThree, chunkFour)
                local builtChunk = chunkOne .. chunkTwo .. chunkThree .. chunkFour;

                self.SCAAMBRUIBuiltJSON = self.SCAAMBRUIBuiltJSON .. builtChunk;
                self.SCAAMBRUIBuiltChunkCounter = self.SCAAMBRUIBuiltChunkCounter + insertedChunks;

                -- Checks if there's still chunks that need to be grabbed
                if (stillHasChunks == true) then
                    self.server:SCAAMBRRequestDat(self.id, totalChunks, operation);
                else
                    self:SCAAMBROpenTheMenuClient(operation, totalChunks);
                end
            end,

            -- SCAAMBROpenTheMenuDat
            -- Changes the state from idle to active on the menu and populates the sections with info
            SCAAMBROpenTheMenuDat = function (self, operation, chunkCount, chunkOne, chunkTwo, chunkThree, chunkFour)
                local totalChunk = chunkOne .. chunkTwo .. chunkThree .. chunkFour;

                -- Checks if all the chunks were added to the final built string, this to validate
                -- integrity of data because it may happen that some RMI call won't make it
                if (self.SCAAMBRUIBuiltChunkCounter == tonumber(chunkCount)) then

                    -- Parses the JSON data
                    local menuData = SCAAMBRJSON.parse(totalChunk);

                    if (operation == 'open') then
                        SCAAMBRUIFunctions:OpenMenu();
                        SCAAMBRUIFunctions:ActivateMenuAfterDelay(menuData);
                        UIAction.HideElement('mod_SCAAMBRStatsUI', 0);
                        self.SCAAMBRMenuState = 'active';
                    elseif (operation == 'updategamedata') then
                        SCAAMBRUIFunctions:UpdateGameData(menuData);
                    elseif (operation == 'updatemenudata' and self.SCAAMBRMenuState == 'active') then
                        SCAAMBRUIFunctions:UpdateMenuData(menuData);
                    end
                else
                    g_gameRules.game:SendTextMessage(0, g_localActorId, 'Failed opening menu, please try again');
                end
            end,

            -- SCAAMBRToggleUI
            -- Toggles on/off a specific BR UI or all, depending on the UIName
            SCAAMBRToggleUI = function (self, UIName, toggler)
                -- SCAAMBRUIFunctions:ReactivateInitFilters();
                self:SCAAMBRToggleUIClient(UIName, toggler);
            end,

            -- SCAAMBRChangeTheStates
            -- Upates the BR stats values for the UI, depending on the action
            SCAAMBRChangeTheStates = function (self, action, value)
                self:SCAAMBRChangeTheUIStateClient(action, value);
            end,

            -- SCAAMBRManageSpectatePlayer
            -- Manages all the spectator functions depending on what comes from the server
            SCAAMBRManageSpectatePlayer = function (self, spectatedPlayerId, action)
                self:SCAAMBRManageTheSpectatePlayer(spectatedPlayerId, action);
            end
        },
        Server = {
            -- SCAAMBRStimPackByKey
            -- Makes an attempt to apply a stim pack using the keys
            SCAAMBRStimPackByKey = function (self)
                SCAAMBRAttemptApplyStimPackByKeyInScript(self.id);
            end,
            
            -- SCAAMBRArmorPlateByKey
            -- Makes an attempt to apply armor using the keys
            SCAAMBRArmorPlateByKey = function (self)
                SCAAMBRAttemptApplyArmorByKeyInScript(self.id);
            end,

            -- SCAAMBRGetTheMenuDat
            -- Reaches to the server to grab the information needed for the menu to display
            SCAAMBRGetTheMenuDat = function (self, playerId, newData)
                SCAAMBRGetMenuData(playerId, newData);
            end,

            -- SCAAMBRRequestDat
            -- Checks the server for more JSON data remaining
            SCAAMBRRequestDat = function (self, playerId, totalChunks, operation)
                SCAAMBRAskForChunksData(playerId, totalChunks, operation);
            end,

            -- SCAAMBRALocationDat
            -- Checks the server for more JSON data remaining
            SCAAMBRALocationDat = function (self, playerId, location)
                SCAAMBRSetLocation(playerId, location);
            end,

            -- SCAAMBRManageSpectatePlayer
            -- Manages the spectator mode server side
            SCAAMBRManageSpectatePlayer = function (self, playerId, action, value)
                SCAAMBRManageSpectate(playerId, action, value);
            end
        },

        -- SCAAMBRToggleUIClient
        -- Toggles on/off a specific BR UI or all, depending on the UIName
        -- This is needed to get the correct value of self because apparently it's not giving it 
        -- correctly if called directly with Client instead of onClient
        SCAAMBRToggleUIClient = function (self, UIName, toggler)
            if (UIName == 'all') then
                if (toggler == true) then
                    UIAction.ShowElement('mod_SCAAMBRStatsUI', 0);
                    self.SCAAMBRToggledUI = true;
                else
                    self:SCAAMBRChangeTheUIStateClient('gotoidle', '');
                    self.SCAAMBRToggledUI = false;
                    UIAction.HideElement('mod_SCAAMBRStatsUI', 0);
                end
            elseif (UIName == 'initial') then
                if (toggler == true) then
                    UIAction.ShowElement('mod_SCAAMBRStatsUI', 0);
                    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'SetVersion', SCAAMBRVersion);
                    self.SCAAMBRToggledLobbyUI = true;
                    self.SCAAMBRToggledUI = true;
                else
                    UIAction.HideElement('mod_SCAAMBRStatsUI', 0);
                    self.SCAAMBRToggledLobbyUI = false;
                    self.SCAAMBRToggledUI = false;
                end
            elseif (UIName == 'menu') then
                if (toggler == true) then
                    SCAAMBRUIFunctions:OpenMenu();
                    self.SCAAMBRToggledLobbyUI = true;
                else
                    SCAAMBRUIFunctions:CloseMenu();
                    self.SCAAMBRToggledLobbyUI = false;
                end
            else
                if (toggler == true) then
                    UIAction.ShowElement(UIName, 0);
                else
                    UIAction.HideElement(UIName, 0);
                end
            end
        end,

        -- SCAAMBRChangeTheUIStateClient
        -- Updates the BR stats values for the UI, depending on the action
        -- This is needed to get the correct value of self because apparently it's not giving it 
        -- correctly if called directly with Client instead of onClient
        SCAAMBRChangeTheUIStateClient = function (self, action, value)

            -- Checks if the player has the UI opened so it can be updated
            if (self.SCAAMBRToggledUI == true) then
                if (action == 'setgunicon') then
                    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'SetGunIcon', value);
                elseif (action == 'setammocounter') then
                    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'SetAmmo', value);
                elseif (action == 'setarmor') then
                    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'SetArmor', value);
                elseif (action == 'setarmorcounter') then
                    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'SetArmorCounter', value);
                elseif (action == 'setstimpackcounter') then
                    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'SetStimPackCounter', value);
                elseif (action == 'setplayercounter') then
                    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'SetPlayerCounter', value);
                elseif (action == 'setkillcounter') then
                    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'SetKillCounter', value);
                elseif (action == 'gotogame') then
                    SCAAMBRUIFunctions:ReactivateFilters();
                    self.SCAAMBRFrozenPlayer = false;

                    if (self.SCAAMBRToggledLobbyUI == true) then

                        -- Closes the Menu UI if opened and switches the stats UI to show the Playing controls
                        if (self.SCAAMBRMenuState == 'active') then
                            SCAAMBRUIFunctions:CloseMenu();
                            UIAction.ShowElement('mod_SCAAMBRStatsUI', 0);
                        end

                        self.SCAAMBRMenuState = 'idle';
                        self.SCAAMBRToggledLobbyUI = false;
                        UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'GoToGame');
                        UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'ToggleMap', false);
                    end

                    -- Checks if the map UI in lobby is opened then closes it
                    if (self.SCAAMBRToggledMapUI == true) then
                        SCAAMBRUIFunctions:CloseMap();
                        self.SCAAMBRToggledMapUI = false;
                    end

                    -- Sets the necessary data for the map UI
                    SCAAMBRUIFunctions:InitMapGame(value);
                elseif (action == 'gotoidle') then
                    SCAAMBRUIFunctions:ReactivateFilters();
                    self.SCAAMBRFrozenPlayer = false;

                    if (self.SCAAMBRToggledLobbyUI == false) then
                        self.SCAAMBRToggledLobbyUI = true;
                        UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'GoToIdle');
                    end

                    -- Checks if the map UI in game is opened then closes it
                    SCAAMBRUIFunctions:CleanIndicatorsGame();

                    if (self.SCAAMBRToggledMapUI == true) then
                        SCAAMBRUIFunctions:CloseMapGame();
                        UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'ToggleMiniMap', false);
                        self.SCAAMBRToggledMapUI = false;
                    end
                elseif (action == 'freezeplayer') then
                    if (value == 'showloading') then
                        if (self.SCAAMBRToggledLobbyUI == true) then
        
                            -- Closes the Menu UI if opened
                            if (self.SCAAMBRMenuState == 'active') then
                                SCAAMBRUIFunctions:CloseTheMenu();
                                UIAction.ShowElement('mod_SCAAMBRStatsUI', 0);
                                self.SCAAMBRMenuState = 'idle';
                            end
                        end
        
                        UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'GoToLoadingScreen', false);
                    end
        
                    SCAAMBRUIFunctions:DeactivateFilters();
                    self.SCAAMBRFrozenPlayer = true;
                elseif (action == 'unfreezeplayer') then
                    SCAAMBRUIFunctions:ReactivateFilters();
                    self.SCAAMBRFrozenPlayer = false;
                elseif (action == 'restartvalues') then
                    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'RestartValues');
                end
            end
        end,

        -- SCAAMBROpenTheMenuClient
        -- Changes the state from idle to active on the menu and populates the sections with info
        SCAAMBROpenTheMenuClient = function (self, operation, totalChunks)

            -- Checks if all the chunks were added to the final built string, this to validate
            -- integrity of data because it may happen that some RMI call won't make it
            if (self.SCAAMBRUIBuiltChunkCounter == totalChunks) then

                -- Parses the JSON data
                local menuData = SCAAMBRJSON.parse(self.SCAAMBRUIBuiltJSON);

                if (operation == 'open') then
                    SCAAMBRUIFunctions:OpenMenu();
                    SCAAMBRUIFunctions:ActivateMenuAfterDelay(menuData);
                    UIAction.HideElement('mod_SCAAMBRStatsUI', 0);
                    self.SCAAMBRMenuState = 'active';
                elseif (operation == 'updategamedata') then
                    SCAAMBRUIFunctions:UpdateGameData(menuData);
                elseif (operation == 'updatemenudata' and self.SCAAMBRMenuState == 'active') then
                    SCAAMBRUIFunctions:UpdateMenuData(menuData);
                end
            else
                g_gameRules.game:SendTextMessage(0, g_localActorId, 'Failed opening menu, please try again');
            end

            self.SCAAMBRUIBuiltJSON = '';
            self.SCAAMBRUIBuiltChunkCounter = 0;
        end,

        -- SCAAMBRManageTheSpectatePlayer
        -- Manages all the spectator functions depending on what comes from the server
        SCAAMBRManageTheSpectatePlayer = function (self, spectatedPlayerId, action)
            if (action == 'spectate') then
                self.SCAAMBRSpectatedPlayerId = spectatedPlayerId;
                self.SCAAMBRToggledSpectatorUI = true;

                -- Gets the name of the player being spectated
                local spectatedPlayer = System.GetEntity(spectatedPlayerId);
                local spectatedPlayerName = spectatedPlayer:GetName();

                -- Opens the spectator mode UI
                SCAAMBRUIFunctions:OpenSpectatorMode();

                -- Sets in the UI the name of the player being spectated
                SCAAMBRUIFunctions:SetSpectatedNameAfterDelay(spectatedPlayerName);

                self:SCAAMBRStartSpectatePlayer();
            elseif (action == 'changespectate') then
                self.SCAAMBRSpectatedPlayerId = spectatedPlayerId;

                -- Gets the name of the player being spectated
                local spectatedPlayer = System.GetEntity(spectatedPlayerId);
                local spectatedPlayerName = spectatedPlayer:GetName();
                UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'SetSpectatedPlayerName', spectatedPlayerName);
            elseif (action == 'stopspectate') then
                SCAAMBRUIFunctions:CloseSpectatorMode();
                self.SCAAMBRSpectatedPlayerId = nil;
                self.SCAAMBRToggledSpectatorUI = false;
            elseif (action == 'hide') then
                self:EnablePhysics(false);
                self:LoadObject(0, 'Objects/SCAAMCuartas/BattleRoyaleSpectator/spectator.cgf');
            elseif (action == 'unhide') then
                self:EnablePhysics(true);
                self:LoadObject(0, self.SCAAMBROriginalCGF);
            end
        end,

        -- SCAAMBRStartSpectatePlayer
        -- Starts the timer to spectate a player
        SCAAMBRStartSpectatePlayer = function (self)
            Script.SetTimerForFunction(10, 'Player.SCAAMBRSpectateAfterDelay', self);
        end,

        -- SCAAMBRSpectateAfterDelay
        -- Updates the player's camera view to the position and rotation of the spectated player
        SCAAMBRSpectateAfterDelay = function (self)
            if (self.SCAAMBRSpectatedPlayerId ~= nil) then
                local spectatedPlayer = System.GetEntity(self.SCAAMBRSpectatedPlayerId);

                if (spectatedPlayer and spectatedPlayer.player) then
                    self:SetWorldPos(spectatedPlayer:GetWorldPos());

                    self:SCAAMBRStartSpectatePlayer();
                else
                    self:SCAAMBRStartSpectatePlayer();
                end
            end
        end
    },
    Expose = {
        ClientMethods = {
            SCAAMBRUIInit = { RELIABLE_ORDERED, POST_ATTACH },
            SCAAMBRInitThePlayer = { RELIABLE_ORDERED, POST_ATTACH },
            SCAAMBRPlaySoundDat = { RELIABLE_ORDERED, PRE_ATTACH, STRING },
            SCAAMBRToggleUI = { RELIABLE_ORDERED, POST_ATTACH, STRING, BOOL },
            SCAAMBRChangeTheStates = { RELIABLE_ORDERED, POST_ATTACH, STRING, STRING },
            SCAAMBRBuildTheDataUI = { RELIABLE_ORDERED, PRE_ATTACH, STRING, BOOL, INT16, INT16, STRING, STRING, STRING, STRING },
            SCAAMBRManageSpectatePlayer = { RELIABLE_ORDERED, PRE_ATTACH, ENTITYID, STRING }
        },
        ServerMethods = {
            SCAAMBRStimPackByKey = { RELIABLE_ORDERED, POST_ATTACH },
            SCAAMBRArmorPlateByKey = { RELIABLE_ORDERED, POST_ATTACH },
            SCAAMBRGetTheMenuDat = { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, STRING },
            SCAAMBRRequestDat = { RELIABLE_ORDERED, PRE_ATTACH, ENTITYID, INT16, STRING },
            SCAAMBRALocationDat = { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, STRING },
            SCAAMBRManageSpectatePlayer = { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, STRING, STRING }
        },
        ServerProperties = {}
    }
}

Log(">> Loading mFramework SCAAMBRCustomPlayer");
local _status, _result = mReExpose('Player', SCAAMBRCustomPlayer.Methods, SCAAMBRCustomPlayer.Expose);
Log(">> Result: " .. tostring(_status or "Failed") .. " " .. tostring(_result or "No Message"));