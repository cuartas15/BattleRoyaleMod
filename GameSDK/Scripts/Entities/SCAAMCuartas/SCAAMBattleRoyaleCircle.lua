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
            SCAAMSetPositionScale = { RELIABLE_ORDERED, POST_ATTACH, VEC3, STRING },
            SCAAMStartCircleShrink = { RELIABLE_ORDERED, POST_ATTACH, STRING, STRING, STRING, VEC3, VEC3, STRING, STRING },
            SCAAMFinishGame = { RELIABLE_ORDERED, POST_ATTACH }
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
    self:SetWorldScaleV({x = tonumber(self.circleScale), y = tonumber(self.circleScale), z = 500});

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
    self:SetWorldScaleV({x = tonumber(self.circleScale), y = tonumber(self.circleScale), z = 500});
end

function SCAAMBattleRoyaleCircle.Client:SCAAMStartCircleShrink(currentScale, currentScaleDelta, goalScale, currentPos, goalPos, distanceBetweenVectors, circleShrinkTime)
    self:DoCircleShrink(currentScale, currentScaleDelta, goalScale, currentPos, goalPos, distanceBetweenVectors, circleShrinkTime, true);
end

function SCAAMBattleRoyaleCircle:DoCircleShrink(currentScale, currentScaleDeltaF, goalScale, currentPos, goalPos, distanceBetweenVectors, circleShrinkTime, firstTime)

    -- Calculates the difference between current and new or target scale
    local scaleToShrink = tonumber(currentScale) - tonumber(goalScale);
                
    -- Calculates the distance the current circle is gonna move towards the new circle per function call, remember this is called 5 times a second so that's why the * 5,
    -- to make the calculation based on the function's call frequency. Same with the scale
    local distanceOfVectorsDelta = tonumber(distanceBetweenVectors) / (tonumber(circleShrinkTime) * 5);
    local scaleToShrinkDelta = scaleToShrink / (tonumber(circleShrinkTime) * 5);

    -- Starts to set the new scale to the circle
    local currentScaleDelta = 0;
    if (firstTime == true) then
        currentScaleDelta = tonumber(currentScaleDeltaF);
    else
        currentScaleDelta = tonumber(currentScaleDeltaF) - scaleToShrinkDelta;
    end

    -- Starts to set the new position to the circle
    local moveToDirection = {x=0, y=0, z=0};
    local sumVectors = {x=0, y=0, z=0};
    local moveToPosition = {x=0, y=0, z=0};

    SubVectors(moveToDirection, goalPos, currentPos);
    NormalizeVector(moveToDirection);
    FastScaleVector(sumVectors, moveToDirection, distanceOfVectorsDelta);
    FastSumVectors(moveToPosition, sumVectors, currentPos);

    -- Sets the new position and scale to the circle in both client and server
    self.targetPosition = moveToPosition;
    self.circleScale = currentScaleDelta;

    if (not self.GameFinished and self.circleScale >= tonumber(goalScale)) then
        local data = {
            ['currentScale'] = currentScale,
            ['currentScaleDeltaF'] = currentScaleDelta,
            ['goalScale'] = goalScale,
            ['currentPos'] = moveToPosition,
            ['goalPos'] = goalPos,
            ['distanceBetweenVectors'] = distanceBetweenVectors,
            ['circleShrinkTime'] = circleShrinkTime,
            ['firstTime'] = false
        };

        self.CircleData = data;

        Script.SetTimerForFunction(200, 'SCAAMBattleRoyaleCircle.RecallSetScaleAndPosAfterDelay', self);
    end

    self:SetPositionScaleAfterDelay();
end

function SCAAMBattleRoyaleCircle:RecallSetScaleAndPosAfterDelay()
    self:DoCircleShrink(self.CircleData.currentScale, self.CircleData.currentScaleDeltaF, self.CircleData.goalScale, self.CircleData.currentPos, self.CircleData.goalPos, self.CircleData.distanceBetweenVectors, self.CircleData.circleShrinkTime, self.CircleData.firstTime);
end

function SCAAMBattleRoyaleCircle.Client:SCAAMFinishGame()
    self.GameFinished = true;
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