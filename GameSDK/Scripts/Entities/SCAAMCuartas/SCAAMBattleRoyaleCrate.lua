SCAAMBattleRoyaleCrate = {
    type = "SCAAMBattleRoyaleCrate",

    Properties = {
        fileModel = "Objects/SCAAMCuartas/BattleRoyaleCrate/battleroyalecrate.cgf",
        ModelSubObject = "",
		bPickable = 1,
		bMounted = 0,
		bUsable = 0,
		bSpecialSelect = 0,
		soclasses_SmartObjectClass = "",
        initialSetup = "",

        Physics = {
            bRigidBody = 0,
            bRigidBodyActive = 0,
            bResting = 0,
            Density = -1,
            Mass = -1,
            Buoyancy = {
                water_density = 0,
                water_damping = 0,
                water_resistance = 0
            },
            bStaticInDX9Multiplayer = 1,
            MP = {bDontSyncPos = 0}
        }
    },
	
	Client = {},
	Server = {},
	
	Editor = {
		Icon = "Item.bmp",
		IconOnTop = 1,
    },
}

function SCAAMBattleRoyaleCrate:Expose()
    Net.Expose {
        Class = self,
        ClientMethods = {
        },
        ServerMethods = {
            OpenCrate = { RELIABLE_ORDERED, POST_ATTACH, ENTITYID }
        },
        ServerProperties = {
		}
    };
end

local Physics_DX9MP_Simple = {
    bPhysicalize = 1, -- True if object should be physicalized at all.
    bPushableByPlayers = 0,

    Density = -1,
    Mass = -1,
    bStaticInDX9Multiplayer = 1
}

function SCAAMBattleRoyaleCrate:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleCrate:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleCrate:OnReset()
    local props = self.Properties;
    if (not EmptyString(props.fileModel)) then
        self:LoadSubObject(0, props.fileModel, props.ModelSubObject);
    end

    self:PhysicalizeThis(0);
end

function SCAAMBattleRoyaleCrate:PhysicalizeThis(slot)
    if (self.Properties.Physics.MP.bDontSyncPos == 1) then
        CryAction.DontSyncPhysics(self.id);
    end

    local physics = self.Properties.Physics;
    if (CryAction.IsImmersivenessEnabled() == 0) then
        physics = Physics_DX9MP_Simple;
    end
    EntityCommon.PhysicalizeRigid(self, slot, physics, 1);

    if (physics.Buoyancy) then
        self:SetPhysicParams(PHYSICPARAM_BUOYANCY, physics.Buoyancy);
    end
end

function SCAAMBattleRoyaleCrate.Server:OpenCrate(crateId)
    SCAAMBROpenCrate(crateId);
end

function SCAAMBattleRoyaleCrate.Server:OnHit(hit)

end

function SCAAMBattleRoyaleCrate.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleCrate:IsActionable(user)
    if (self.item:CanPickUp(user.id) or self.item:CanUse(user.id) or self.item:IsActionable(user.id)) then
		return 1;
	else
		return 0;
	end
end

function SCAAMBattleRoyaleCrate:GetActions(user)
    local actions = {};
    table.insert(actions, 'Open crate');
    return actions;
end

function SCAAMBattleRoyaleCrate:PerformAction(user, action)
    if (action == 'Open crate') then
        self.server:OpenCrate(self.id);
    end
end

function SCAAMBattleRoyaleCrate.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleCrate.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleCrate:CacheResources()

end

-- EI End
AddInteractLargeObjectProperty(SCAAMBattleRoyaleCrate);
SCAAMBattleRoyaleCrate:Expose();

local function CreateSCAAMBattleRoyaleCrateTable()
    _G['SCAAMBattleRoyaleCrate'] = new(SCAAMBattleRoyaleCrate);
end

CreateSCAAMBattleRoyaleCrateTable();