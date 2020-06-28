SCAAMBattleRoyaleCircle = {
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

function SCAAMBattleRoyaleCircle:Expose()
    Net.Expose {
        Class = self,
        ClientMethods = {
            SCAAMSetScale = { RELIABLE_ORDERED, POST_ATTACH, STRING },
            SCAAMSetPositionScale = { RELIABLE_ORDERED, POST_ATTACH, VEC3, STRING }
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

function SCAAMBattleRoyaleCircle:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleCircle:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleCircle:OnReset()

end

function SCAAMBattleRoyaleCircle:PhysicalizeThis(slot)
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

function SCAAMBattleRoyaleCircle.Client:SCAAMSetPositionScale(targetPosition, scale)
    self.circleScale = scale;
    self.targetPosition = targetPosition;
    Script.SetTimerForFunction(50, 'SCAAMBattleRoyaleCircle.SetPositionScaleAfterDelay', self);
end

function SCAAMBattleRoyaleCircle:SetPositionScaleAfterDelay()
    self:SetWorldPos(self.targetPosition);
    self:SetWorldScale(tonumber(self.circleScale));

    local circleData = {
        Position = self.targetPosition,
        Scale = tonumber(self.circleScale)
    };

    SCAAMBRUIFunctions:UpdateCirclePosAndScaleGame(circleData);
end

function SCAAMBattleRoyaleCircle.Client:SCAAMSetScale(scale)
    self.circleScale = scale;
    Script.SetTimerForFunction(50, 'SCAAMBattleRoyaleCircle.SetScaleAfterDelay', self);
end

function SCAAMBattleRoyaleCircle:SetScaleAfterDelay()
    self:SetWorldScale(tonumber(self.circleScale));
end

function SCAAMBattleRoyaleCircle.Server:OnHit(hit)

end

function SCAAMBattleRoyaleCircle.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleCircle:IsActionable(user)
    return 0;
end

function SCAAMBattleRoyaleCircle:GetActions(user)
    local actions = {};
    return actions;
end

function SCAAMBattleRoyaleCircle:PerformAction(user, action)

end

function SCAAMBattleRoyaleCircle.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end

    SCAAMBRInitGame(self.id);
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleCircle.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleCircle:CacheResources()

end

-- EI End
AddInteractLargeObjectProperty(SCAAMBattleRoyaleCircle);
SCAAMBattleRoyaleCircle:Expose();

local function CreateSCAAMBattleRoyaleCircleTable()
    _G['SCAAMBattleRoyaleCircle'] = new(SCAAMBattleRoyaleCircle);
end

CreateSCAAMBattleRoyaleCircleTable();