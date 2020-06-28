SCAAMStimPack = {
    Properties = {
		bPickable = 1,
		eiPhysicsType = 2, -- not physicalized by default
		bMounted = 0,
		bUsable = 0,
		bSpecialSelect = 0,
		soclasses_SmartObjectClass = "",
        initialSetup = "",
	},
	
	Client = {},
	Server = {},
	
	Editor = {
		Icon = "Item.bmp",
		IconOnTop = 1,
    },
}

function SCAAMStimPack:Expose()
    Net.Expose {
        Class = self,
        ClientMethods = {
        },
        ServerMethods = {
            UseItem = { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, ENTITYID }
        },
        ServerProperties = {
		}
    };
end

function SCAAMStimPack.Server:UseItem(itemId, userId)
    SCAAMBRUseStimPack(itemId, userId);
end

function SCAAMStimPack:OnPropertyChange()
    self:OnReset();
end

function SCAAMStimPack:OnEditorSetGameMode(gameMode)

end

function SCAAMStimPack:OnReset()

end

function SCAAMStimPack.Server:OnHit(hit)

end

function SCAAMStimPack.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMStimPack:IsActionable(user)
    if (self.item:CanPickUp(user.id) or self.item:CanUse(user.id) or self.item:IsActionable(user.id)) then
		return 1;
	else
		return 0;
	end
end

function SCAAMStimPack:GetActions(user)
    local actions = {};
    actions = self.item:GetActions(user.id, actions);
    table.insert(actions, "Use item");

    return actions;
end

function SCAAMStimPack:PerformAction(user, action)
    if (action == "Use item") then
        self.server:UseItem(self.id, user.id);
    else
        return self.item:PerformAction(user.id, action);
    end
end

function SCAAMStimPack.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMStimPack.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMStimPack:CacheResources()

end

-- EI End
SCAAMStimPack:Expose();

local function CreateSCAAMStimPackTable()
    _G['SCAAMStimPack'] = new(SCAAMStimPack);
end

CreateSCAAMStimPackTable();