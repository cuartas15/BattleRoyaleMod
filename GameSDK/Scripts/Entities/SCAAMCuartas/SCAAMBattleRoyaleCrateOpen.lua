SCAAMBattleRoyaleCrateOpen = {
    type = "SCAAMBattleRoyaleCrateOpen",

    Properties = {
        fileModel = "Objects/SCAAMCuartas/BattleRoyaleCrateOpen/battleroyalecrateopen.cgf",
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

function SCAAMBattleRoyaleCrateOpen:Expose()
    Net.Expose {
        Class = self,
        ClientMethods = {
            PlayOpenedSound = { RELIABLE_ORDERED, POST_ATTACH }
        },
        ServerMethods = {
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

function SCAAMBattleRoyaleCrateOpen:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleCrateOpen:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleCrateOpen:OnReset()
    local props = self.Properties;
    if (not EmptyString(props.fileModel)) then
        self:LoadSubObject(0, props.fileModel, props.ModelSubObject);
    end

    self:PhysicalizeThis(0);
end

function SCAAMBattleRoyaleCrateOpen:PhysicalizeThis(slot)
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

function SCAAMBattleRoyaleCrateOpen.Client:PlayOpenedSound()
    local soundTriggerID = AudioUtils.LookupTriggerID('Play_door_fridge_closed');

    if (soundTriggerID ~= nil) then
        self:ExecuteAudioTrigger(soundTriggerID, self:GetDefaultAuxAudioProxyID());
    end
end

function SCAAMBattleRoyaleCrateOpen:DelayBeforePlaySound()
    self.allClients:PlayOpenedSound();
end

function SCAAMBattleRoyaleCrateOpen.Server:OnHit(hit)

end

function SCAAMBattleRoyaleCrateOpen.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleCrateOpen:IsActionable(user)
    return 0;
end

function SCAAMBattleRoyaleCrateOpen:GetActions(user)
    local actions = {};
    return actions;
end

function SCAAMBattleRoyaleCrateOpen:PerformAction(user, action)

end

function SCAAMBattleRoyaleCrateOpen.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end

    Script.SetTimerForFunction(50, 'SCAAMBattleRoyaleCrateOpen.DelayBeforePlaySound', self);
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleCrateOpen.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleCrateOpen:CacheResources()

end

-- EI End
AddInteractLargeObjectProperty(SCAAMBattleRoyaleCrateOpen);
SCAAMBattleRoyaleCrateOpen:Expose();

local function CreateSCAAMBattleRoyaleCrateOpenTable()
    _G['SCAAMBattleRoyaleCrateOpen'] = new(SCAAMBattleRoyaleCrateOpen);
end

CreateSCAAMBattleRoyaleCrateOpenTable();