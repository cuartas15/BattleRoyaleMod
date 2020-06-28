SCAAMBattleRoyaleCrateSpawn = {
    Properties = {
		bPickable = 0,
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

function SCAAMBattleRoyaleCrateSpawn:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleCrateSpawn:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleCrateSpawn:OnReset()

end

function SCAAMBattleRoyaleCrateSpawn.Server:OnHit(hit)

end

function SCAAMBattleRoyaleCrateSpawn.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleCrateSpawn:IsActionable(user)
    return 0
end

function SCAAMBattleRoyaleCrateSpawn:GetActions(user)
    return {};
end

function SCAAMBattleRoyaleCrateSpawn:PerformAction(user, action)

end

function SCAAMBattleRoyaleCrateSpawn.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleCrateSpawn.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleCrateSpawn:CacheResources()

end

-- EI End

local function CreateSCAAMBattleRoyaleCrateSpawnTable()
    _G['SCAAMBattleRoyaleCrateSpawn'] = new(SCAAMBattleRoyaleCrateSpawn);
end

CreateSCAAMBattleRoyaleCrateSpawnTable();