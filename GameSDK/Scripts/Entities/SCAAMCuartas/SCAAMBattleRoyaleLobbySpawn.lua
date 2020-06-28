SCAAMBattleRoyaleLobbySpawn = {
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

function SCAAMBattleRoyaleLobbySpawn:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleLobbySpawn:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleLobbySpawn:OnReset()

end

function SCAAMBattleRoyaleLobbySpawn.Server:OnHit(hit)

end

function SCAAMBattleRoyaleLobbySpawn.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleLobbySpawn:IsActionable(user)
    return 0
end

function SCAAMBattleRoyaleLobbySpawn:GetActions(user)
    return {};
end

function SCAAMBattleRoyaleLobbySpawn:PerformAction(user, action)

end

function SCAAMBattleRoyaleLobbySpawn.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleLobbySpawn.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleLobbySpawn:CacheResources()

end

-- EI End

local function CreateSCAAMBattleRoyaleLobbySpawnTable()
    _G['SCAAMBattleRoyaleLobbySpawn'] = new(SCAAMBattleRoyaleLobbySpawn);
end

CreateSCAAMBattleRoyaleLobbySpawnTable();