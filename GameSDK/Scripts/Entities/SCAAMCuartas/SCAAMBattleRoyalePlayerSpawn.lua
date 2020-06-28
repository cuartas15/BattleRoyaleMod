SCAAMBattleRoyalePlayerSpawn = {
    Properties = {
		bPickable = 0,
		eiPhysicsType = 2, -- not physicalized by default
		bMounted = 0,
		bUsable = 0,
		bSpecialSelect = 0,
		soclasses_SmartObjectClass = "",
        initialSetup = "",
        sSCAAMBRLocationName = "",
	},
	
	Client = {},
	Server = {},
	
	Editor = {
		Icon = "Item.bmp",
		IconOnTop = 1,
    },
}

function SCAAMBattleRoyalePlayerSpawn:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyalePlayerSpawn:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyalePlayerSpawn:OnReset()

end

function SCAAMBattleRoyalePlayerSpawn.Server:OnHit(hit)

end

function SCAAMBattleRoyalePlayerSpawn.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyalePlayerSpawn:IsActionable(user)
    return 0
end

function SCAAMBattleRoyalePlayerSpawn:GetActions(user)
    return {};
end

function SCAAMBattleRoyalePlayerSpawn:PerformAction(user, action)

end

function SCAAMBattleRoyalePlayerSpawn.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyalePlayerSpawn.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyalePlayerSpawn:CacheResources()

end

-- EI End

local function CreateSCAAMBattleRoyalePlayerSpawnTable()
    _G['SCAAMBattleRoyalePlayerSpawn'] = new(SCAAMBattleRoyalePlayerSpawn);
end

CreateSCAAMBattleRoyalePlayerSpawnTable();