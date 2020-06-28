SCAAMArmor = {
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

function SCAAMArmor:Expose()
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

function SCAAMArmor.Server:UseItem(itemId, userId)
    SCAAMBRUseArmor(itemId, userId);
end

function SCAAMArmor:OnPropertyChange()
    self:OnReset();
end

function SCAAMArmor:OnEditorSetGameMode(gameMode)

end

function SCAAMArmor:OnReset()

end

function SCAAMArmor.Server:OnHit(hit)

end

function SCAAMArmor.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMArmor:IsActionable(user)
    if (self.item:CanPickUp(user.id) or self.item:CanUse(user.id) or self.item:IsActionable(user.id)) then
		return 1;
	else
		return 0;
	end
end

function SCAAMArmor:GetActions(user)
    local actions = {};
    actions = self.item:GetActions(user.id, actions);
    table.insert(actions, "Use item");

    return actions;
end

function SCAAMArmor:PerformAction(user, action)
    if (action == "Use item") then
        self.server:UseItem(self.id, user.id);
    else
        return self.item:PerformAction(user.id, action);
    end
end

function SCAAMArmor.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMArmor.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMArmor:CacheResources()

end

-- EI End
SCAAMArmor:Expose();

local function CreateSCAAMArmorTable()
    _G['SCAAMArmor'] = new(SCAAMArmor);
end

CreateSCAAMArmorTable();