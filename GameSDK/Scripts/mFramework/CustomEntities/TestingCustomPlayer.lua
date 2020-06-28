local TestingCustomPlayer = {
    Methods = {
        Client = {
            PlaySound = function(self, soundName)
                local soundTriggerID = AudioUtils.LookupTriggerID(soundName);

                if (soundTriggerID ~= nil) then
                    self:ExecuteAudioTrigger(soundTriggerID, self:GetDefaultAuxAudioProxyID());
                end
            end,
            PlaySoundTwo = function(self)
                Log(">> Playing sound");
                local soundTriggerID = AudioUtils.LookupTriggerID('Play_crafting_move_item_fp');

                if (soundTriggerID ~= nil) then
                    Log(">> Found sound");
                    self:ExecuteAudioTrigger(soundTriggerID, self:GetDefaultAuxAudioProxyID());
                end
                Log(">> Finished playing sound");
            end,
            ShowElementUI = function(self, message)
                InitTheNoteUI(message);
            end,
            HideElementUI = function(self, UIName, UIInstance)
                UIAction.HideElement(UIName, tonumber(UIInstance));
            end,
            AssignKeyBinds = function(self)
                Log(">> Assigning keybinds");
                System.AddCCommand('GetKeybinds', 'DeliverMessageTwo(%1)', '');
                System.AddCCommand('GetKeybindsTwo', 'DeliverMessageThree(%1)', '');
                System.AddCCommand('GetKeybindsThree', 'DeliverMessageTwo(%1)', '');
                System.AddKeyBind('alt_k', 'GetKeybindsTwo alt_k');
                System.AddKeyBind('k', 'GetKeybinds k');
                System.AddKeyBind('y', 'GetKeybindsThree y');
                Log(">> Finished keybinds");
            end,
            TriggerLog = function(self, message)
                Log('Message from client %s', message);
                self.server:ServerLogMessage(message);
            end,
            PrintTheMessage = function(self)
                Log('Pre take');
                self:DeliverMessageTwo('Pre take');
            end
        },
        Server = {
            ServerLogMessage = function (self, message)
                Log("Is this a message to server? %s", message);
                local playerId = self.id;
                Log("PlayerId: " .. tostring(playerId));
                g_gameRules.game:SendTextMessage(0, 0, 'Message from client: ' .. message);
            end
        }
    },
    Expose = {
        ClientMethods = {
            PlaySound = { RELIABLE_ORDERED, POST_ATTACH, STRING },
            PlaySoundTwo = { RELIABLE_ORDERED, POST_ATTACH },
            ShowElementUI = { RELIABLE_ORDERED, POST_ATTACH, STRING },
            HideElementUI = { RELIABLE_ORDERED, POST_ATTACH, STRING, STRING },
            AssignKeyBinds = { RELIABLE_ORDERED, POST_ATTACH },
            TriggerLog = { RELIABLE_ORDERED, POST_ATTACH, STRING },
            PrintTheMessage = { RELIABLE_ORDERED, POST_ATTACH }
        },
        ServerMethods = {
            ServerLogMessage = { RELIABLE_ORDERED, POST_ATTACH, STRING }
        },
        ServerProperties = {}
    }
}

Log(">> Loading mFramework TestingCustomPlayer");
local _status, _result = mReExpose('Player', TestingCustomPlayer.Methods, TestingCustomPlayer.Expose);
Log(">> Result: " .. tostring(_status or "Failed") .. " " .. tostring(_result or "No Message"));