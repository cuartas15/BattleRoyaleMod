SCAAMBattleRoyaleMainSpawn = {
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

function SCAAMBattleRoyaleMainSpawn:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleMainSpawn:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleMainSpawn:OnReset()

end

function SCAAMBattleRoyaleMainSpawn.Server:OnHit(hit)

end

function SCAAMBattleRoyaleMainSpawn.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleMainSpawn:IsActionable(user)
    return 0
end

function SCAAMBattleRoyaleMainSpawn:GetActions(user)
    return {};
end

function SCAAMBattleRoyaleMainSpawn:PerformAction(user, action)

end

function SCAAMBattleRoyaleMainSpawn.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleMainSpawn.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleMainSpawn:CacheResources()

end

-- EI End

local function CreateSCAAMBattleRoyaleMainSpawnTable()
    _G['SCAAMBattleRoyaleMainSpawn'] = new(SCAAMBattleRoyaleMainSpawn);
end

CreateSCAAMBattleRoyaleMainSpawnTable();