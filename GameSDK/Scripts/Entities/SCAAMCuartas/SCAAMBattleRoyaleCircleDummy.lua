SCAAMBattleRoyaleCircleDummy = {
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

function SCAAMBattleRoyaleCircleDummy:Expose()
    Net.Expose {
        Class = self,
        ClientMethods = {
            SCAAMSetScale = { RELIABLE_ORDERED, POST_ATTACH, STRING }
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

function SCAAMBattleRoyaleCircleDummy:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleCircleDummy:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleCircleDummy:OnReset()

end

function SCAAMBattleRoyaleCircleDummy:PhysicalizeThis(slot)
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

function SCAAMBattleRoyaleCircleDummy.Client:SCAAMSetScale(scale)
    self.circleScale = scale;
    Script.SetTimerForFunction(50, 'SCAAMBattleRoyaleCircleDummy.SetScaleAfterDelay', self);
end

function SCAAMBattleRoyaleCircleDummy:SetScaleAfterDelay()
    self:SetWorldScale(tonumber(self.circleScale));

    local safeZoneData = {
        Position = self:GetWorldPos(),
        Scale = tonumber(self.circleScale)
    };

    SCAAMBRUIFunctions:UpdateSafeZonePosAndScaleGame(safeZoneData);
end

function SCAAMBattleRoyaleCircleDummy.Server:OnHit(hit)

end

function SCAAMBattleRoyaleCircleDummy.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleCircleDummy:IsActionable(user)
    return 0;
end

function SCAAMBattleRoyaleCircleDummy:GetActions(user)
    local actions = {};
    return actions;
end

function SCAAMBattleRoyaleCircleDummy:PerformAction(user, action)

end

function SCAAMBattleRoyaleCircleDummy.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleCircleDummy.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleCircleDummy:CacheResources()

end

-- EI End
AddInteractLargeObjectProperty(SCAAMBattleRoyaleCircleDummy);
SCAAMBattleRoyaleCircleDummy:Expose();

local function CreateSCAAMBattleRoyaleCircleDummyTable()
    _G['SCAAMBattleRoyaleCircleDummy'] = new(SCAAMBattleRoyaleCircleDummy);
end

CreateSCAAMBattleRoyaleCircleDummyTable();