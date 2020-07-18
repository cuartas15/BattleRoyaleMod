SCAAMBattleRoyaleCarSpawn = {
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

function SCAAMBattleRoyaleCarSpawn:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleCarSpawn:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleCarSpawn:OnReset()

end

function SCAAMBattleRoyaleCarSpawn.Server:OnHit(hit)

end

function SCAAMBattleRoyaleCarSpawn.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleCarSpawn:IsActionable(user)
    return 0
end

function SCAAMBattleRoyaleCarSpawn:GetActions(user)
    return {};
end

function SCAAMBattleRoyaleCarSpawn:PerformAction(user, action)

end

function SCAAMBattleRoyaleCarSpawn.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleCarSpawn.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleCarSpawn:CacheResources()

end

-- EI End

local function CreateSCAAMBattleRoyaleCarSpawnTable()
    _G['SCAAMBattleRoyaleCarSpawn'] = new(SCAAMBattleRoyaleCarSpawn);
end

CreateSCAAMBattleRoyaleCarSpawnTable();