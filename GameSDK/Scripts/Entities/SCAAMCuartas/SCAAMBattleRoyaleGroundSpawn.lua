SCAAMBattleRoyaleGroundSpawn = {
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

function SCAAMBattleRoyaleGroundSpawn:OnPropertyChange()
    self:OnReset();
end

function SCAAMBattleRoyaleGroundSpawn:OnEditorSetGameMode(gameMode)

end

function SCAAMBattleRoyaleGroundSpawn:OnReset()

end

function SCAAMBattleRoyaleGroundSpawn.Server:OnHit(hit)

end

function SCAAMBattleRoyaleGroundSpawn.Client:OnHit(hit, remote)

end

-- EI Begin

function SCAAMBattleRoyaleGroundSpawn:IsActionable(user)
    return 0
end

function SCAAMBattleRoyaleGroundSpawn:GetActions(user)
    return {};
end

function SCAAMBattleRoyaleGroundSpawn:PerformAction(user, action)

end

function SCAAMBattleRoyaleGroundSpawn.Server:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
end

----------------------------------------------------------------------------------------------------
function SCAAMBattleRoyaleGroundSpawn.Client:OnInit()
    if (not self.bInitialized) then
        self:OnReset();
        self.bInitialized = 1;
    end
    self:CacheResources();
end

----------------------------------------------------------------------------------
function SCAAMBattleRoyaleGroundSpawn:CacheResources()

end

-- EI End

local function CreateSCAAMBattleRoyaleGroundSpawnTable()
    _G['SCAAMBattleRoyaleGroundSpawn'] = new(SCAAMBattleRoyaleGroundSpawn);
end

CreateSCAAMBattleRoyaleGroundSpawnTable();