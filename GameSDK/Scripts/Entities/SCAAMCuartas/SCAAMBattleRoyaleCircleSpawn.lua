SCAAMBattleRoyaleCircleSpawn = {
    Properties = {
		bPickable = 0,
		eiPhysicsType = 2, -- not physicalized by default
		bMounted = 0,
		bUsable = 0,
		bSpecialSelect = 0,
		soclasses_SmartObjectClass = "",
        initialSetup = "",
        fSCAAMBRMinX = 0,
        fSCAAMBRMaxX = 0,
        fSCAAMBRMinY = 0,
        fSCAAMBRMaxY = 0
	},
	
	Client = {},
	Server = {},
	
	Editor = {
		Icon = "Item.bmp",
		IconOnTop = 1,
    },
}

function SCAAMBattleRoyaleCircleSpawn:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleCircleSpawn:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleCircleSpawn:OnReset()

end

function SCAAMBattleRoyaleCircleSpawn.Server:OnHit(hit)

end

function SCAAMBattleRoyaleCircleSpawn.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleCircleSpawn:IsActionable(user)
    return 0
end

function SCAAMBattleRoyaleCircleSpawn:GetActions(user)
    return {};
end

function SCAAMBattleRoyaleCircleSpawn:PerformAction(user, action)

end

function SCAAMBattleRoyaleCircleSpawn.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleCircleSpawn.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleCircleSpawn:CacheResources()

end

-- EI End

local function CreateSCAAMBattleRoyaleCircleSpawnTable()
    _G['SCAAMBattleRoyaleCircleSpawn'] = new(SCAAMBattleRoyaleCircleSpawn);
end

CreateSCAAMBattleRoyaleCircleSpawnTable();