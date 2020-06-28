-- SCAAM Battle Royale Mod v1.0
-- Created by Cuartas

-- Dear Modder: Almost everything was commented step by step for you to easily understand what
-- everything is doing and why.
-- Hope the new potential mechanics and code practices used here have some use for your future
-- mods or more customized battle royale for your servers.
-- Don't hesitate to provide feedback or bug reports in case you encounter an issue.
-- Happy modding!

-- Loading all the custom entities
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleCircle.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleCircleDummy.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleCrate.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleCrateOpen.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMStimPack.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMArmor.lua');

-- The debug spawners
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleConfigSpawn.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleCircleSpawn.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleGroundSpawn.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleLobbySpawn.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleMainSpawn.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyalePlayerSpawn.lua');
Script.LoadScript('Scripts/Entities/SCAAMCuartas/SCAAMBattleRoyaleCrateSpawn.lua');

-- Redefines the Miscreated.Server.OnInit function to get rid of the event timer which
-- spawns the aircrashes and default airdrops
function Miscreated.Server:OnInit()
    -- Do nothing
end

-- Battle Royale database config
SCAAMBRDatabase = nil;
SCAAMBRPlayerDatabase = nil;

-- Top 15 data
SCAAMBRTopFifteen = {};

-- Adding custom functions to all the items
for key, item in pairs(_G) do

    -- Checks if the entity is an item
    if (type(item) == 'table' and item.Properties and item.Properties.bPickable and item.Properties.bPickable == 1) then

        -- Saves the current game so it can be removed next game when it enters the relevant area of a player, this only for picked up items
        -- because that's how items make part of the relevance system
        item.SaveValue = function(self)
            if (self.SCAAMBRGame) then
                return self.SCAAMBRGame;
            else
                return 'Game' .. tostring(SCAAMBRGameNumber);
            end
        end

        -- Restores the value saved to compare against the current game and decide if it can be removed or not
        item.RestoreValue = function(self, value)
            if (value ~= ('Game' .. tostring(SCAAMBRGameNumber))) then
                System.RemoveEntity(self.id);
            else
                self.SCAAMBRGame = 'Game' .. tostring(SCAAMBRGameNumber);
            end
        end
    end
end

-- SCAAMBRSplitToTable
-- Generates a table from a string, based on a separator
function SCAAMBRSplitToTable(inputStr, separator)
    if (separator == nil) then
        separator = '%s';
    end

    local t = {};

    for str in string.gmatch(inputStr, '([^' .. separator .. ']+)') do
        table.insert(t, str);
    end

    return t;
end

-- SCAAMBRSpecialMerge
-- Copies the mergef method adding support for non keyed tables
function SCAAMBRSpecialMerge(dst, src, recursive)
	for i, v in pairs(src) do
		if (recursive) then
			if ((type(v) == 'table') and (v ~= src)) then  -- avoid recursing into itself
				if (type(i) == 'number') then
                    table.insert(dst, v);
                elseif (dst[i] == nil) then
                    dst[i] = {};
				end
				SCAAMBRSpecialMerge(dst[i], v, recursive);
			end
		elseif (dst[i] == nil) then
			dst[i] = v;
		end
	end
	
	return dst;
end

-- SCAAMBRShallowCopy
-- Returns a copied table so the copy is not pointing to the same memory reference, this wont work
-- for nested tables, better use the new() function included with the engine
function SCAAMBRShallowCopy(originalTable)
    local copy;

    if (type(originalTable) == 'table') then
        copy = {};

        for orig_key, orig_value in pairs(originalTable) do
            copy[orig_key] = orig_value;
        end
    else
        copy = originalTable;
    end

    return copy;
end

-- round
-- Rounds a given real number to the closest integer
local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n);
end

-- The BR game counter, necessary for cleanup functions
SCAAMBRGameNumber = 0;

-- Battle royale game properties
SCAAMBattleRoyaleProperties = {
    circleId = nil, -- Spawned circle entity id
    CurrentTimer = 0, -- Time elapsed per phase
    TotalTime = 0, -- Total game time elapsed
    CurrentPhase = 1, -- Current phase of the game, max 6
    GamePhases = 6, -- Game phases limit, this is not hardcoded in case more or less phases are supported in the future
    GameState = 'InLobby', -- The state of the game, can be InLobby or Active
    CheckForSecondPassed = 0, -- A variable that increments in a way it gets a value of 1000 each 1 second, used to do game updates per second
    CoolSoundTimer = 3000, -- Used for playing the 'counting' sound on circle closing it does it 3 times, once every value / 1000
    CurrentPlayers = 0, -- The player counter, only players that are part of the game and not InLobby
    ['Airdrops'] = {
    },
    ['Phase1'] = {
        DummyCircleId = nil, -- EntityId of the dummy circle spawned for this phase
        Position = {}, -- Position of the dummy circle
        DistanceBetweenVectors = 0, -- Distance between the circle at the end of the previous phase and the dummy circle
        DisplayedMessage = false -- Checking if the 'Circle is closing in' message was displayed so it does it only once
    },
    ['Phase2'] = {
        DummyCircleId = nil,
        Position = {},
        DistanceBetweenVectors = 0,
        DisplayedMessage = false
    },
    ['Phase3'] = {
        DummyCircleId = nil,
        Position = {},
        DistanceBetweenVectors = 0,
        DisplayedMessage = false
    },
    ['Phase4'] = {
        DummyCircleId = nil,
        Position = {},
        DistanceBetweenVectors = 0,
        DisplayedMessage = false
    },
    ['Phase5'] = {
        DummyCircleId = nil,
        Position = {},
        DistanceBetweenVectors = 0,
        DisplayedMessage = false
    },
    ['Phase6'] = {
        DummyCircleId = nil,
        Position = {},
        DistanceBetweenVectors = 0,
        DisplayedMessage = false
    }
};

-- Editor or server specific actions or values, this is setting the proper values to the game
-- properties depending on the environment. Have in mind, the editor values were made for the
-- _empty level provided for modding
if (System.IsEditor()) then

    -- The map size, eg: a 4x4 map tends to be 4096
    SCAAMBattleRoyaleProperties.MapSize = 1024;

    -- The minimum players required to start a game
    SCAAMBattleRoyaleProperties.MinPlayers = 1;

    -- The minimum players to win, the logical value should be 1, last man standing, but for testing
    -- purposes where there's only 1 player this should be 2
    SCAAMBattleRoyaleProperties.MinToWin = 2;

    -- The lobby spawn position for newly joined and revived players
    SCAAMBattleRoyaleProperties.LobbySpawnPosition = {x = 342.2567, y = 646.7623, z = 19.4484};
    
    -- The circle spawn position, it has to be at the center of the map
    SCAAMBattleRoyaleProperties.CircleSpawnPosition = {x = 368.652, y = 609.336, z = 17};
    
    -- The initial scale of the circle, this is set on all the different params used
    SCAAMBattleRoyaleProperties.InitialScale = 30;
    SCAAMBattleRoyaleProperties.CurrentScale = 30;
    SCAAMBattleRoyaleProperties.CurrentScaleDelta = 30;

    -- The cooldown for each phase, this is the time before the circle starts to shrink
    SCAAMBattleRoyaleProperties['Phase1'].CooldownTime = 30;
    SCAAMBattleRoyaleProperties['Phase2'].CooldownTime = 30;
    SCAAMBattleRoyaleProperties['Phase3'].CooldownTime = 30;
    SCAAMBattleRoyaleProperties['Phase4'].CooldownTime = 30;
    SCAAMBattleRoyaleProperties['Phase5'].CooldownTime = 30;
    SCAAMBattleRoyaleProperties['Phase6'].CooldownTime = 30;

    -- The circle shrinking time for each phase, this is the tame it takes for the circle to shrink
    -- to the desired scale
    SCAAMBattleRoyaleProperties['Phase1'].CircleShrinkTime = 30;
    SCAAMBattleRoyaleProperties['Phase2'].CircleShrinkTime = 30;
    SCAAMBattleRoyaleProperties['Phase3'].CircleShrinkTime = 30;
    SCAAMBattleRoyaleProperties['Phase4'].CircleShrinkTime = 30;
    SCAAMBattleRoyaleProperties['Phase5'].CircleShrinkTime = 30;
    SCAAMBattleRoyaleProperties['Phase6'].CircleShrinkTime = 30;

    -- The new scale is the target or desired scale the circle is going to have for each phase
    SCAAMBattleRoyaleProperties['Phase1'].NewScale = 25;
    SCAAMBattleRoyaleProperties['Phase2'].NewScale = 20;
    SCAAMBattleRoyaleProperties['Phase3'].NewScale = 12;
    SCAAMBattleRoyaleProperties['Phase4'].NewScale = 8;
    SCAAMBattleRoyaleProperties['Phase5'].NewScale = 4;
    SCAAMBattleRoyaleProperties['Phase6'].NewScale = 0.5;

    -- Gets the map boundaries
    SCAAMBattleRoyaleProperties.boundaryMinX = 350;
    SCAAMBattleRoyaleProperties.boundaryMinY = 590;
    SCAAMBattleRoyaleProperties.boundaryMaxX = 410;
    SCAAMBattleRoyaleProperties.boundaryMaxY = 650;
else

    -- The map size, eg: a 4x4 map tends to be 2048
    SCAAMBattleRoyaleProperties.MapSize = 2048;

    -- The minimum players required to start a game
    SCAAMBattleRoyaleProperties.MinPlayers = 2;

    -- The minimum players to win, the logical value should be 1, last man standing, but for testing
    -- purposes where there's only 1 player this should be 2
    SCAAMBattleRoyaleProperties.MinToWin = 1;

    -- The lobby spawn position for newly joined and revived players
    SCAAMBattleRoyaleProperties.LobbySpawnPosition = {x = 1032.94, y = 1446.02, z = 30.523};

    -- The circle spawn position, it has to be at the center of the map
    SCAAMBattleRoyaleProperties.CircleSpawnPosition = {x = 1078, y = 1045, z = 93.75};

    -- The initial scale of the circle, this is set on all the different params used
    SCAAMBattleRoyaleProperties.InitialScale = round(949 * math.sqrt(2)); -- TODO: Set to 200
    SCAAMBattleRoyaleProperties.CurrentScale = round(949 * math.sqrt(2)); -- TODO: Set to 200
    SCAAMBattleRoyaleProperties.CurrentScaleDelta = round(949 * math.sqrt(2)); -- TODO: Set to 200

    -- The cooldown for each phase, this is the time before the circle starts to shrink
    SCAAMBattleRoyaleProperties['Phase1'].CooldownTime = 150; -- TODO: Set to 150
    SCAAMBattleRoyaleProperties['Phase2'].CooldownTime = 120; -- TODO: Set to 120
    SCAAMBattleRoyaleProperties['Phase3'].CooldownTime = 100; -- TODO: Set to 100
    SCAAMBattleRoyaleProperties['Phase4'].CooldownTime = 70; -- TODO: Set to 70
    SCAAMBattleRoyaleProperties['Phase5'].CooldownTime = 60; -- TODO: Set to 60
    SCAAMBattleRoyaleProperties['Phase6'].CooldownTime = 30; -- TODO: Set to 30

    -- The circle shrinking time for each phase, this is the tame it takes for the circle to shrink
    -- to the desired scale
    SCAAMBattleRoyaleProperties['Phase1'].CircleShrinkTime = 100; -- TODO: Set to 100
    SCAAMBattleRoyaleProperties['Phase2'].CircleShrinkTime = 80; -- TODO: Set to 80
    SCAAMBattleRoyaleProperties['Phase3'].CircleShrinkTime = 65; -- TODO: Set to 65
    SCAAMBattleRoyaleProperties['Phase4'].CircleShrinkTime = 50; -- TODO: Set to 50
    SCAAMBattleRoyaleProperties['Phase5'].CircleShrinkTime = 45; -- TODO: Set to 45
    SCAAMBattleRoyaleProperties['Phase6'].CircleShrinkTime = 40; -- TODO: Set to 40

    -- The new scale is the target or desired scale the circle is going to have for each phase
    SCAAMBattleRoyaleProperties['Phase1'].NewScale = SCAAMBattleRoyaleProperties.InitialScale * 0.5;
    SCAAMBattleRoyaleProperties['Phase2'].NewScale = SCAAMBattleRoyaleProperties.InitialScale * 0.4;
    SCAAMBattleRoyaleProperties['Phase3'].NewScale = SCAAMBattleRoyaleProperties.InitialScale * 0.3;
    SCAAMBattleRoyaleProperties['Phase4'].NewScale = SCAAMBattleRoyaleProperties.InitialScale * 0.2;
    SCAAMBattleRoyaleProperties['Phase5'].NewScale = SCAAMBattleRoyaleProperties.InitialScale * 0.1;
    SCAAMBattleRoyaleProperties['Phase6'].NewScale = 10;

    -- Gets the map boundaries
    SCAAMBattleRoyaleProperties.boundaryMinX = 156;
    SCAAMBattleRoyaleProperties.boundaryMinY = 96;
    SCAAMBattleRoyaleProperties.boundaryMaxX = 2000;
    SCAAMBattleRoyaleProperties.boundaryMaxY = 1993;
end

-- Copy the original Battle royale properties for each fresh game
SCAAMBattleRoyalePropertiesBackup = SCAAMBRShallowCopy(SCAAMBattleRoyaleProperties);

-- Player and game properties, for now it controls if the BR script was initialized 
SCAAMBattleRoyalePlayerManagement = {
    HasTheScriptInitialized = false,
    WaitingTimer = 7000
};

-- Player properties, including spawn positions for now

-- Editor or server specific actions
if (System.IsEditor()) then
    SCAAMBRPlayerProperties = {
        Positions = {
            ['Pussylands'] = {
                Main = {x = 331.239, y = 602.122, z = 17},
                Positions = {
                    {Position = {x = 331.239, y = 602.122, z = 17}, Direction = {x = -0.987442, y = -0.157982, z = 0}},
                    {Position = {x = 326.8, y = 596.337, z = 17}, Direction = {x = -0.340729, y = -0.940162, z = 0}},
                    {Position = {x = 332.249, y = 588.639, z = 17}, Direction = {x = 0.674835, y = -0.737969, z = 0}},
                }
            },
            ['Centrallands'] = {
                Main = {x = 362.609, y = 629.685, z = 17},
                Positions = {
                    {Position = {x = 362.609, y = 629.685, z = 17}, Direction = {x = 0.31628, y = 0.948666, z = 0}},
                    {Position = {x = 369.587, y = 632.701, z = 17}, Direction = {x = 0.936562, y = 0.350503, z = 0}},
                    {Position = {x = 364.918, y = 639.389, z = 17}, Direction = {x = -0.803702, y = 0.595033, z = 0}},
                }
            },
            ['Forestlands'] = {
                Main = {x = 389.64, y = 623.552, z = 17},
                Positions = {
                    {Position = {x = 389.64, y = 623.552, z = 17}, Direction = {x = 0.367507, y = -0.930021, z = 0}},
                    {Position = {x = 389.702, y = 627.986, z = 17}, Direction = {x = -0.43956, y = -0.898213, z = 0}},
                    {Position = {x = 385.326, y = 626.956, z = 17}, Direction = {x = -0.978934, y = -0.204177, z = 0}},
                }
            }
        }
    };
else
    SCAAMBRPlayerProperties = {
        Positions = {
            ['Refugee'] = {
                Main = {x = 1032.88, y = 1709.5, z = 50.95},
                Positions = {
                    {Position = {x = 1103.38, y = 1681.38, z = 50.1813}},
                    {Position = {x = 989.75, y = 1616, z = 52.275}},
                    {Position = {x = 1042.38, y = 1680.25, z = 51.4}},
                    {Position = {x = 1164.88, y = 1656.63, z = 52.1437}},
                    {Position = {x = 1103.63, y = 1665.13, z = 50.85}},
                    {Position = {x = 1090.63, y = 1673.38, z = 50.05}},
                    {Position = {x = 888.125, y = 1793, z = 51.15}},
                    {Position = {x = 1010.13, y = 1673.13, z = 51.725}},
                    {Position = {x = 1005.88, y = 1627.25, z = 52.225}},
                    {Position = {x = 1095, y = 1650.75, z = 51.325}},
                    {Position = {x = 1215.88, y = 1650.75, z = 52.925}},
                    {Position = {x = 1063, y = 1681.88, z = 51.6437}},
                    {Position = {x = 1193.25, y = 1681.88, z = 51.275}},
                    {Position = {x = 1191, y = 1662.25, z = 52.9125}},
                    {Position = {x = 915, y = 1805.25, z = 51.575}},
                    {Position = {x = 1082.75, y = 1662.75, z = 51}},
                    {Position = {x = 985.125, y = 1630.38, z = 52.4938}},
                    {Position = {x = 1167.63, y = 1607.38, z = 69.1438}},
                    {Position = {x = 1021, y = 1623.75, z = 52.225}},
                    {Position = {x = 1046, y = 1659.25, z = 51.2375}},
                    {Position = {x = 973.375, y = 1790.88, z = 51.2437}},
                    {Position = {x = 1029.38, y = 1608.88, z = 52.2625}},
                    {Position = {x = 1199.63, y = 1640.88, z = 53.1063}},
                    {Position = {x = 1068.75, y = 1586.5, z = 52.9375}},
                    {Position = {x = 936.75, y = 1851.5, z = 53.7875}},
                    {Position = {x = 958.25, y = 1818.13, z = 52.2125}},
                    {Position = {x = 1061.38, y = 1647, z = 51.3}},
                    {Position = {x = 1177.5, y = 1663.5, z = 52.275}},
                    {Position = {x = 1008.13, y = 1734, z = 51.575}},
                    {Position = {x = 1008, y = 1652, z = 52.075}},
                    {Position = {x = 1099.38, y = 1600, z = 54.3625}},
                    {Position = {x = 1172.88, y = 1680.38, z = 50.875}},
                    {Position = {x = 1011.63, y = 1605.63, z = 52.225}},
                    {Position = {x = 1062.88, y = 1710.88, z = 50.325}},
                    {Position = {x = 1077.25, y = 1623.88, z = 52.1937}},
                    {Position = {x = 1176.5, y = 1693.75, z = 50.95}},
                    {Position = {x = 888.875, y = 1765.75, z = 50.4813}},
                    {Position = {x = 995.125, y = 1636.25, z = 52.225}},
                    {Position = {x = 987.375, y = 1687.38, z = 51.675}},
                    {Position = {x = 1032.63, y = 1598.75, z = 52.325}},
                    {Position = {x = 1024.75, y = 1642.63, z = 51.7563}},
                    {Position = {x = 1077.5, y = 1606.25, z = 52.6125}},
                    {Position = {x = 1047.5, y = 1601.88, z = 52.2312}},
                    {Position = {x = 1175.38, y = 1650.25, z = 52.7875}},
                    {Position = {x = 925.375, y = 1823.75, z = 52.175}},
                    {Position = {x = 955.375, y = 1854.88, z = 52.725}},
                    {Position = {x = 953.5, y = 1774.13, z = 51.5}},
                    {Position = {x = 1179, y = 1637.5, z = 54.775}},
                    {Position = {x = 1127.88, y = 1590.13, z = 60.5875}},
                    {Position = {x = 1021, y = 1687, z = 51.625}}
                }
            },
            ['Chernogorsk'] = {
                Main = {x = 1198.38, y = 538.625, z = 46.625},
                Positions = {
                    {Position = {x = 1288.75, y = 576, z = 49.6563}},
                    {Position = {x = 1080.13, y = 604, z = 51.1625}},
                    {Position = {x = 1256.5, y = 443.125, z = 50.3375}},
                    {Position = {x = 1258.5, y = 454.375, z = 48.5687}},
                    {Position = {x = 1053, y = 572.75, z = 44.1688}},
                    {Position = {x = 1108.75, y = 647.375, z = 51.7562}},
                    {Position = {x = 1105.88, y = 485.5, z = 51.2813}},
                    {Position = {x = 1132.75, y = 606, z = 50.3438}},
                    {Position = {x = 1237.25, y = 434, z = 49.2062}},
                    {Position = {x = 1161.54, y = 603.452, z = 47.6389}},
                    {Position = {x = 1108.75, y = 497.75, z = 51.1063}},
                    {Position = {x = 1321.63, y = 532.25, z = 40.2813}},
                    {Position = {x = 1271.5, y = 517.75, z = 45.2188}},
                    {Position = {x = 1238.75, y = 561.25, z = 47.3188}},
                    {Position = {x = 1128.63, y = 447, z = 50.325}},
                    {Position = {x = 1312.88, y = 505.125, z = 44.6875}},
                    {Position = {x = 1187, y = 641.75, z = 48.8188}},
                    {Position = {x = 1315.38, y = 542.375, z = 43.3375}},
                    {Position = {x = 1288, y = 543, z = 45.8563}},
                    {Position = {x = 1228.38, y = 689.25, z = 52.95}},
                    {Position = {x = 1111.75, y = 549.375, z = 51.5062}},
                    {Position = {x = 1172.63, y = 498.75, z = 47.2687}},
                    {Position = {x = 1223.75, y = 422.875, z = 49.1563}},
                    {Position = {x = 1111.38, y = 576.125, z = 51.3625}},
                    {Position = {x = 1238.25, y = 622.5, z = 49.9688}},
                    {Position = {x = 1270.13, y = 679.75, z = 53.6313}},
                    {Position = {x = 1115.63, y = 522.125, z = 51.3188}},
                    {Position = {x = 1128.5, y = 520.625, z = 51.2562}},
                    {Position = {x = 1190.25, y = 511.875, z = 46.6688}},
                    {Position = {x = 1249.38, y = 574, z = 47.6375}},
                    {Position = {x = 1162.88, y = 429.75, z = 49.3125}},
                    {Position = {x = 1107.38, y = 414.25, z = 51.75}},
                    {Position = {x = 1227.75, y = 619, z = 49.1438}},
                    {Position = {x = 1158.88, y = 613, z = 47.8688}},
                    {Position = {x = 1278.5, y = 650.125, z = 62.4063}},
                    {Position = {x = 1093.38, y = 681, z = 52.225}},
                    {Position = {x = 1313.25, y = 472.875, z = 48.7687}},
                    {Position = {x = 1141.88, y = 576, z = 48.6937}},
                    {Position = {x = 1062.88, y = 490.25, z = 51.3438}},
                    {Position = {x = 1202.38, y = 596.125, z = 47.6937}},
                    {Position = {x = 1239.88, y = 484.5, z = 47.0187}},
                    {Position = {x = 1179.38, y = 437.875, z = 48.5938}},
                    {Position = {x = 1283.25, y = 538.875, z = 45.4312}},
                    {Position = {x = 1095.88, y = 446.25, z = 51.5063}},
                    {Position = {x = 1079, y = 557.875, z = 50.0375}},
                    {Position = {x = 1166.25, y = 542.25, z = 47.1188}},
                    {Position = {x = 1155.38, y = 689.75, z = 52.4875}},
                    {Position = {x = 1198.25, y = 552.375, z = 46.75}},
                    {Position = {x = 1291.5, y = 588.875, z = 63.4625}},
                    {Position = {x = 1067.88, y = 523.625, z = 51.325}}
                }
            },
            ['Bad Neighborhood'] = {
                Main = {x = 1744, y = 1612.38, z = 47.125},
                Positions = {
                    {Position = {x = 1754.13, y = 1538.88, z = 49.7937}},
                    {Position = {x = 1665.38, y = 1736.88, z = 33}},
                    {Position = {x = 1791.63, y = 1559.75, z = 49.7937}},
                    {Position = {x = 1829.38, y = 1593.25, z = 45.3375}},
                    {Position = {x = 1701.13, y = 1685.5, z = 39.6812}},
                    {Position = {x = 1710.63, y = 1657.75, z = 42.9562}},
                    {Position = {x = 1768, y = 1538.63, z = 49.7937}},
                    {Position = {x = 1680.13, y = 1661.88, z = 45.1687}},
                    {Position = {x = 1671.88, y = 1601.88, z = 51.2937}},
                    {Position = {x = 1660.5, y = 1520, z = 54.3937}},
                    {Position = {x = 1687.5, y = 1573.38, z = 51.7437}},
                    {Position = {x = 1669.75, y = 1611.75, z = 51.3812}},
                    {Position = {x = 1788.88, y = 1543.5, z = 49.7937}},
                    {Position = {x = 1670.75, y = 1776.25, z = 26.1437}},
                    {Position = {x = 1676.75, y = 1759.63, z = 27.375}},
                    {Position = {x = 1656.5, y = 1713.13, z = 36.4437}},
                    {Position = {x = 1655.88, y = 1691.88, z = 40.3687}},
                    {Position = {x = 1637.25, y = 1629.5, z = 52.2312}},
                    {Position = {x = 1730.38, y = 1543.13, z = 50.2875}},
                    {Position = {x = 1686.88, y = 1778.5, z = 26.1}},
                    {Position = {x = 1776.38, y = 1578.25, z = 49.1875}},
                    {Position = {x = 1667.13, y = 1543, z = 53.325}},
                    {Position = {x = 1666.38, y = 1767.25, z = 26.2437}},
                    {Position = {x = 1762, y = 1597.5, z = 45.9437}},
                    {Position = {x = 1716.5, y = 1533, z = 50.8187}},
                    {Position = {x = 1651, y = 1553, z = 54.1437}},
                    {Position = {x = 1638.25, y = 1622.13, z = 52.1437}},
                    {Position = {x = 1652, y = 1673.88, z = 44.8062}},
                    {Position = {x = 1768.25, y = 1607.38, z = 44.25}},
                    {Position = {x = 1771.75, y = 1522.38, z = 49.9313}},
                    {Position = {x = 1768.75, y = 1558.88, z = 49.7937}},
                    {Position = {x = 1782.13, y = 1565.38, z = 49.7937}},
                    {Position = {x = 1717.25, y = 1643.13, z = 45.725}},
                    {Position = {x = 1678.13, y = 1543.25, z = 52.6812}},
                    {Position = {x = 1620.88, y = 1618.38, z = 52.575}},
                    {Position = {x = 1684, y = 1605.88, z = 50.8562}},
                    {Position = {x = 1672.63, y = 1527.75, z = 53.1625}},
                    {Position = {x = 1684.63, y = 1753.63, z = 28.8812}},
                    {Position = {x = 1692.38, y = 1736.88, z = 33.5687}},
                    {Position = {x = 1819.75, y = 1618.5, z = 42.1187}},
                    {Position = {x = 1660.38, y = 1563.63, z = 52.9437}},
                    {Position = {x = 1650.25, y = 1595, z = 52.3312}},
                    {Position = {x = 1689.88, y = 1703.25, z = 37.3187}},
                    {Position = {x = 1688, y = 1629.63, z = 49.6687}},
                    {Position = {x = 1689.13, y = 1649.75, z = 47.3062}},
                    {Position = {x = 1698.25, y = 1764.13, z = 26.3375}},
                    {Position = {x = 1682.25, y = 1532.88, z = 52.9313}},
                    {Position = {x = 1701.75, y = 1629.25, z = 47.4562}},
                    {Position = {x = 1787.75, y = 1581.13, z = 48.5312}},
                    {Position = {x = 1648, y = 1610.88, z = 51.95}}
                }
            },
            ['Hunger Forest'] = {
                Main = {x = 1132, y = 967.75, z = 102.25},
                Positions = {
                    {Position = {x = 1163.25, y = 841, z = 112.95}},
                    {Position = {x = 1105.88, y = 873.625, z = 115.669}},
                    {Position = {x = 1173.88, y = 955.25, z = 102.25}},
                    {Position = {x = 1145.88, y = 1061.88, z = 99.575}},
                    {Position = {x = 1093.38, y = 961.75, z = 102.219}},
                    {Position = {x = 1071.5, y = 959.75, z = 98.525}},
                    {Position = {x = 1126.38, y = 1049.88, z = 104.887}},
                    {Position = {x = 1062.38, y = 1001.75, z = 90.0875}},
                    {Position = {x = 1068.88, y = 885.625, z = 118.887}},
                    {Position = {x = 1089.13, y = 904.75, z = 111.588}},
                    {Position = {x = 1170.13, y = 845.625, z = 114.825}},
                    {Position = {x = 1080.63, y = 902.625, z = 113.706}},
                    {Position = {x = 1219.63, y = 1027, z = 94.35}},
                    {Position = {x = 1129.63, y = 985.125, z = 102.25}},
                    {Position = {x = 1130, y = 1007, z = 102.25}},
                    {Position = {x = 1231.13, y = 889.375, z = 114.162}},
                    {Position = {x = 1137.13, y = 932.375, z = 102.25}},
                    {Position = {x = 1200.38, y = 991.25, z = 102.406}},
                    {Position = {x = 1113.5, y = 915.875, z = 104.212}},
                    {Position = {x = 1094.38, y = 941.75, z = 102.294}},
                    {Position = {x = 1156.88, y = 996.625, z = 102.25}},
                    {Position = {x = 1042.75, y = 1028, z = 91.1}},
                    {Position = {x = 1095, y = 936, z = 103.05}},
                    {Position = {x = 1141.13, y = 972.875, z = 102.25}},
                    {Position = {x = 1085, y = 1054.13, z = 108.012}},
                    {Position = {x = 1101.5, y = 894.25, z = 113.875}},
                    {Position = {x = 1211.63, y = 1054.25, z = 91.9625}},
                    {Position = {x = 1158.88, y = 939.375, z = 102.25}},
                    {Position = {x = 1205.5, y = 935.5, z = 112.725}},
                    {Position = {x = 1193.13, y = 948, z = 110.631}},
                    {Position = {x = 1181.13, y = 899.25, z = 112.781}},
                    {Position = {x = 1046.75, y = 949.375, z = 98.5125}},
                    {Position = {x = 1094.75, y = 867.875, z = 112.894}},
                    {Position = {x = 1169, y = 974.5, z = 102.25}},
                    {Position = {x = 1090.38, y = 1025.38, z = 102.306}},
                    {Position = {x = 1148, y = 877.5, z = 116.675}},
                    {Position = {x = 1218.5, y = 970.875, z = 104.081}},
                    {Position = {x = 1055.75, y = 1049.88, z = 97.3937}},
                    {Position = {x = 1111.25, y = 987.625, z = 102.25}},
                    {Position = {x = 1190.88, y = 1066.38, z = 92.9812}},
                    {Position = {x = 1128.25, y = 888.25, z = 114.525}},
                    {Position = {x = 1117.38, y = 962.625, z = 102.25}},
                    {Position = {x = 1204, y = 925.75, z = 114.512}},
                    {Position = {x = 1065.63, y = 1060.38, z = 103.744}},
                    {Position = {x = 1176.13, y = 917.75, z = 109.938}},
                    {Position = {x = 1216, y = 890, z = 114.25}},
                    {Position = {x = 1159.75, y = 905.25, z = 110.6}},
                    {Position = {x = 1039.25, y = 903.5, z = 116.1}},
                    {Position = {x = 1172.25, y = 1062.38, z = 95.275}},
                    {Position = {x = 1060.38, y = 904, z = 116.063}}
                }
            },
            ['Kamishovo'] = {
                Main = {x = 825.875, y = 1527, z = 51.375},
                Positions = {
                    {Position = {x = 802.25, y = 1526.75, z = 51.3937}},
                    {Position = {x = 930.75, y = 1499.5, z = 52.0938}},
                    {Position = {x = 784.375, y = 1616.75, z = 51.8312}},
                    {Position = {x = 910.625, y = 1578.88, z = 52.4062}},
                    {Position = {x = 935.125, y = 1515.13, z = 52.5188}},
                    {Position = {x = 831, y = 1440.63, z = 51.5562}},
                    {Position = {x = 802.875, y = 1609.75, z = 51.6313}},
                    {Position = {x = 746.875, y = 1586.75, z = 51.4562}},
                    {Position = {x = 803.125, y = 1456.5, z = 51.5562}},
                    {Position = {x = 890.25, y = 1447.38, z = 51.6062}},
                    {Position = {x = 794.25, y = 1585.75, z = 51.7313}},
                    {Position = {x = 956, y = 1500.38, z = 51.2875}},
                    {Position = {x = 882.875, y = 1419.38, z = 51.3062}},
                    {Position = {x = 839.75, y = 1466.13, z = 51.65}},
                    {Position = {x = 851.25, y = 1611.13, z = 50.9062}},
                    {Position = {x = 898.25, y = 1478.88, z = 51.6562}},
                    {Position = {x = 856.875, y = 1566.38, z = 51.6219}},
                    {Position = {x = 770.5, y = 1470.88, z = 47.6562}},
                    {Position = {x = 775.75, y = 1632.13, z = 51.65}},
                    {Position = {x = 822.5, y = 1540.5, z = 51.5812}},
                    {Position = {x = 821, y = 1569.63, z = 51.4562}},
                    {Position = {x = 780.5, y = 1440, z = 48.5562}},
                    {Position = {x = 863.5, y = 1478.88, z = 51.65}},
                    {Position = {x = 834.125, y = 1414.63, z = 51.7062}},
                    {Position = {x = 905.125, y = 1568.63, z = 52.4062}},
                    {Position = {x = 869, y = 1407, z = 51.3062}},
                    {Position = {x = 776.125, y = 1627, z = 51.8312}},
                    {Position = {x = 934.125, y = 1555.5, z = 54.0562}},
                    {Position = {x = 809.625, y = 1633.5, z = 51.3562}},
                    {Position = {x = 823.25, y = 1530.25, z = 51.375}},
                    {Position = {x = 833.5, y = 1582.5, z = 51.3312}},
                    {Position = {x = 963.75, y = 1485.63, z = 48.9562}},
                    {Position = {x = 794.125, y = 1488, z = 51.65}},
                    {Position = {x = 748.5, y = 1602.5, z = 51.4562}},
                    {Position = {x = 836.625, y = 1563.75, z = 51.3312}},
                    {Position = {x = 821.25, y = 1553.75, z = 51.4562}},
                    {Position = {x = 973.625, y = 1510.5, z = 51.8625}},
                    {Position = {x = 724.875, y = 1602.13, z = 49.5625}},
                    {Position = {x = 750, y = 1627.25, z = 51.5062}},
                    {Position = {x = 806.625, y = 1421.63, z = 51.5562}},
                    {Position = {x = 781.875, y = 1594.25, z = 51.7813}},
                    {Position = {x = 850.5, y = 1590.75, z = 51.3063}},
                    {Position = {x = 768.25, y = 1506, z = 46.3875}},
                    {Position = {x = 850.75, y = 1501.25, z = 51.65}},
                    {Position = {x = 912, y = 1525.38, z = 51.4562}},
                    {Position = {x = 888, y = 1461.38, z = 51.6062}},
                    {Position = {x = 905.125, y = 1495.63, z = 51.7562}},
                    {Position = {x = 737.125, y = 1577.38, z = 49.3875}},
                    {Position = {x = 863.875, y = 1537.5, z = 51.7313}},
                    {Position = {x = 887.125, y = 1560.63, z = 51.6562}}
                }
            },
            ['Dinner Area'] = {
                Main = {x = 879.75, y = 317.875, z = 45},
                Positions = {
                    {Position = {x = 900, y = 310.25, z = 46.0688}},
                    {Position = {x = 788.5, y = 241, z = 50.7313}},
                    {Position = {x = 793.125, y = 242.625, z = 49.975}},
                    {Position = {x = 992, y = 232.625, z = 51.8375}},
                    {Position = {x = 936.125, y = 280.25, z = 52.8188}},
                    {Position = {x = 903.375, y = 376.75, z = 37.5}},
                    {Position = {x = 989, y = 346.25, z = 52.8188}},
                    {Position = {x = 836.75, y = 296.125, z = 50.275}},
                    {Position = {x = 954.5, y = 285.125, z = 51.3313}},
                    {Position = {x = 890.125, y = 255.625, z = 50.2813}},
                    {Position = {x = 871.125, y = 348.625, z = 43.725}},
                    {Position = {x = 886, y = 324.25, z = 43.8188}},
                    {Position = {x = 914.5, y = 384.125, z = 36.5438}},
                    {Position = {x = 987.75, y = 252.5, z = 51.9938}},
                    {Position = {x = 955.75, y = 350.125, z = 50.875}},
                    {Position = {x = 793.625, y = 254.375, z = 50.475}},
                    {Position = {x = 908.25, y = 403.375, z = 35.7188}},
                    {Position = {x = 885.5, y = 316.5, z = 44.75}},
                    {Position = {x = 867.875, y = 263.25, z = 50.1688}},
                    {Position = {x = 848.875, y = 244.125, z = 49.2375}},
                    {Position = {x = 867.625, y = 285.625, z = 50.4813}},
                    {Position = {x = 995, y = 329.25, z = 52.9688}},
                    {Position = {x = 868.75, y = 316, z = 46.6312}},
                    {Position = {x = 934.75, y = 329.125, z = 48.325}},
                    {Position = {x = 1025.88, y = 274.5, z = 52.8438}},
                    {Position = {x = 877.5, y = 310.375, z = 45.8781}},
                    {Position = {x = 802.375, y = 244.25, z = 50.1313}},
                    {Position = {x = 1009.88, y = 354.5, z = 53.1188}},
                    {Position = {x = 928.125, y = 288.75, z = 52.8313}},
                    {Position = {x = 934.875, y = 307.125, z = 51.7188}},
                    {Position = {x = 998.5, y = 361, z = 52.8938}},
                    {Position = {x = 883.125, y = 372.75, z = 40.0188}},
                    {Position = {x = 996.875, y = 272.75, z = 51.6563}},
                    {Position = {x = 917.25, y = 263.25, z = 51.1813}},
                    {Position = {x = 896, y = 393, z = 36.3438}},
                    {Position = {x = 944.5, y = 261, z = 51.4813}},
                    {Position = {x = 903.5, y = 320.625, z = 44.65}},
                    {Position = {x = 813.625, y = 281.875, z = 50.0313}},
                    {Position = {x = 841, y = 257.875, z = 49.975}},
                    {Position = {x = 910.375, y = 337.375, z = 42.6563}},
                    {Position = {x = 1030.25, y = 292.875, z = 54.4125}},
                    {Position = {x = 909.75, y = 413.875, z = 35.7188}},
                    {Position = {x = 973.25, y = 257.25, z = 51.6438}},
                    {Position = {x = 954.375, y = 269.625, z = 51.3563}},
                    {Position = {x = 874.375, y = 328, z = 44.6875}},
                    {Position = {x = 889.25, y = 407.25, z = 37.4813}},
                    {Position = {x = 830.375, y = 252.75, z = 50.1125}},
                    {Position = {x = 1002.88, y = 261.75, z = 52.3563}},
                    {Position = {x = 815.5, y = 242.25, z = 50.1313}},
                    {Position = {x = 933.375, y = 269.25, z = 51.2938}}
                }
            },
            ['Trailer Zone'] = {
                Main = {x = 324.75, y = 452.75, z = 45.25},
                Positions = {
                    {Position = {x = 258.375, y = 475, z = 47.9063}},
                    {Position = {x = 312.5, y = 443.125, z = 45.3}},
                    {Position = {x = 330.625, y = 431.25, z = 45.1563}},
                    {Position = {x = 326.375, y = 474.875, z = 45.6563}},
                    {Position = {x = 374.75, y = 484.5, z = 47.475}},
                    {Position = {x = 266.625, y = 377.5, z = 40.0812}},
                    {Position = {x = 269.625, y = 458.625, z = 48.2}},
                    {Position = {x = 358.625, y = 443.25, z = 45.0938}},
                    {Position = {x = 351, y = 464.875, z = 45.5438}},
                    {Position = {x = 325.125, y = 459.625, z = 45.35}},
                    {Position = {x = 301.875, y = 503.875, z = 46.9875}},
                    {Position = {x = 290, y = 359.375, z = 38.8563}},
                    {Position = {x = 299.25, y = 514.625, z = 46.7313}},
                    {Position = {x = 313.625, y = 519.375, z = 47.9562}},
                    {Position = {x = 264.125, y = 491, z = 47.3813}},
                    {Position = {x = 386.125, y = 378.5, z = 40.2875}},
                    {Position = {x = 325.5, y = 523.25, z = 49.05}},
                    {Position = {x = 418.5, y = 495.125, z = 47.5875}},
                    {Position = {x = 330.375, y = 451.125, z = 45.225}},
                    {Position = {x = 396.5, y = 497.375, z = 49.0875}},
                    {Position = {x = 418.375, y = 433.375, z = 44.0375}},
                    {Position = {x = 321.125, y = 444.625, z = 45.25}},
                    {Position = {x = 400.375, y = 450, z = 45.25}},
                    {Position = {x = 333.25, y = 441.5, z = 45.05}},
                    {Position = {x = 428.375, y = 468.25, z = 46.625}},
                    {Position = {x = 362.5, y = 498.5, z = 49.05}},
                    {Position = {x = 313.125, y = 454.375, z = 45.3687}},
                    {Position = {x = 335.125, y = 456.875, z = 45.2437}},
                    {Position = {x = 357.75, y = 376.875, z = 42.1375}},
                    {Position = {x = 260.5, y = 529.625, z = 39.3}},
                    {Position = {x = 340.375, y = 490.125, z = 47.0438}},
                    {Position = {x = 410.25, y = 394.75, z = 40.9875}},
                    {Position = {x = 435.875, y = 448.5, z = 45.175}},
                    {Position = {x = 328.5, y = 447.75, z = 45.25}},
                    {Position = {x = 319.875, y = 406.25, z = 44.6938}},
                    {Position = {x = 289.5, y = 491.25, z = 46.65}},
                    {Position = {x = 340.625, y = 447.375, z = 45.05}},
                    {Position = {x = 252, y = 485.125, z = 45.9125}},
                    {Position = {x = 320, y = 437.125, z = 45.3}},
                    {Position = {x = 282.375, y = 514.125, z = 45.6813}},
                    {Position = {x = 276.625, y = 499.875, z = 47.1437}},
                    {Position = {x = 341.375, y = 434.875, z = 45.1625}},
                    {Position = {x = 248.5, y = 447.125, z = 49.2563}},
                    {Position = {x = 429.25, y = 414.625, z = 42.6313}},
                    {Position = {x = 260.25, y = 513.625, z = 42.3937}},
                    {Position = {x = 390.75, y = 418.125, z = 42.8625}},
                    {Position = {x = 244, y = 405.125, z = 44.2125}},
                    {Position = {x = 364.875, y = 468.5, z = 45.9438}},
                    {Position = {x = 316, y = 374.75, z = 39.725}},
                    {Position = {x = 394.875, y = 402.125, z = 41.55}}
                }
            },
            ['Church'] = {
                Main = {x = 621.793, y = 732.816, z = 97.15},
                Positions = {
                    {Position = {x = 643.679, y = 696.936, z = 97.1}},
                    {Position = {x = 614.144, y = 697.107, z = 96.7981}},
                    {Position = {x = 537.653, y = 740.893, z = 97.952}},
                    {Position = {x = 625.549, y = 702.83, z = 97.1415}},
                    {Position = {x = 627.185, y = 786.184, z = 98.2185}},
                    {Position = {x = 584.221, y = 790.406, z = 103.18}},
                    {Position = {x = 632.109, y = 794.927, z = 98.7609}},
                    {Position = {x = 586.175, y = 720.505, z = 97.1}},
                    {Position = {x = 681.581, y = 756.827, z = 103.29}},
                    {Position = {x = 642.26, y = 689.488, z = 97.0244}},
                    {Position = {x = 574.239, y = 728.57, z = 97.1}},
                    {Position = {x = 659.568, y = 756.536, z = 97.15}},
                    {Position = {x = 569.651, y = 758.204, z = 97.3}},
                    {Position = {x = 596.893, y = 780.534, z = 98.5408}},
                    {Position = {x = 630.877, y = 689.45, z = 96.8663}},
                    {Position = {x = 590.169, y = 693.589, z = 96.85}},
                    {Position = {x = 571.46, y = 721.726, z = 97.1}},
                    {Position = {x = 558.224, y = 709.749, z = 99.7292}},
                    {Position = {x = 591.323, y = 810.844, z = 101.778}},
                    {Position = {x = 687.692, y = 726.514, z = 106.664}},
                    {Position = {x = 603.461, y = 690.788, z = 96.6664}},
                    {Position = {x = 679.96, y = 767.933, z = 105.822}},
                    {Position = {x = 578.58, y = 790.761, z = 104.917}},
                    {Position = {x = 640.813, y = 727.228, z = 97.1}},
                    {Position = {x = 625.898, y = 736.673, z = 97.15}},
                    {Position = {x = 680.774, y = 740.709, z = 102.421}},
                    {Position = {x = 616.031, y = 711.413, z = 97.15}},
                    {Position = {x = 560.158, y = 734.66, z = 97.05}},
                    {Position = {x = 685.149, y = 749.771, z = 103.145}},
                    {Position = {x = 623.84, y = 728.669, z = 97.15}},
                    {Position = {x = 581.375, y = 813.564, z = 101.544}},
                    {Position = {x = 625.854, y = 719.872, z = 97.15}},
                    {Position = {x = 645.342, y = 767.165, z = 97.15}},
                    {Position = {x = 658.839, y = 698.154, z = 98.0017}},
                    {Position = {x = 665.27, y = 732.463, z = 98.4849}},
                    {Position = {x = 537.984, y = 728.448, z = 99.2632}},
                    {Position = {x = 563.374, y = 780.933, z = 99.7435}},
                    {Position = {x = 584.513, y = 711.419, z = 97.1}},
                    {Position = {x = 594.678, y = 725.333, z = 97.2}},
                    {Position = {x = 667.962, y = 714.608, z = 99.7688}},
                    {Position = {x = 634.636, y = 753.085, z = 97.15}},
                    {Position = {x = 576.195, y = 695.724, z = 98.0846}},
                    {Position = {x = 608.842, y = 786.948, z = 98.2579}},
                    {Position = {x = 667.221, y = 777.495, z = 102.07}},
                    {Position = {x = 621.194, y = 767.752, z = 97.5182}},
                    {Position = {x = 683.132, y = 713.104, z = 107.09}},
                    {Position = {x = 561.471, y = 766.926, z = 97.2228}},
                    {Position = {x = 610.525, y = 793.322, z = 98.7873}},
                    {Position = {x = 614.38, y = 801.036, z = 98.912}},
                    {Position = {x = 556.241, y = 751.771, z = 97.0879}}
                }
            },
            ['Hotel'] = {
                Main = {x = 1816.75, y = 645.375, z = 51.75},
                Positions = {
                    {Position = {x = 1827, y = 729.125, z = 53.05}},
                    {Position = {x = 1827.88, y = 570, z = 51.75}},
                    {Position = {x = 1846.13, y = 731.75, z = 53.9625}},
                    {Position = {x = 1746.13, y = 669.625, z = 49.425}},
                    {Position = {x = 1729.63, y = 551.125, z = 48.8062}},
                    {Position = {x = 1840.5, y = 621.625, z = 51.75}},
                    {Position = {x = 1783.5, y = 607.625, z = 51.8563}},
                    {Position = {x = 1821.25, y = 637.125, z = 51.75}},
                    {Position = {x = 1701.25, y = 574.375, z = 40.7688}},
                    {Position = {x = 1717, y = 610.25, z = 48.7375}},
                    {Position = {x = 1851.63, y = 631.5, z = 54.3188}},
                    {Position = {x = 1833.5, y = 640.5, z = 51.75}},
                    {Position = {x = 1782.25, y = 714.625, z = 51.3812}},
                    {Position = {x = 1865.38, y = 641.125, z = 55.6688}},
                    {Position = {x = 1682.88, y = 562.375, z = 37.8625}},
                    {Position = {x = 1812.38, y = 702.75, z = 51.75}},
                    {Position = {x = 1852.5, y = 659, z = 53.725}},
                    {Position = {x = 1675.63, y = 551.75, z = 37.9188}},
                    {Position = {x = 1869.75, y = 625.375, z = 56.175}},
                    {Position = {x = 1851.38, y = 598.25, z = 54.4813}},
                    {Position = {x = 1839.5, y = 647, z = 51.75}},
                    {Position = {x = 1850, y = 617.25, z = 54.0625}},
                    {Position = {x = 1811.38, y = 614.875, z = 51.75}},
                    {Position = {x = 1779.38, y = 676.5, z = 51.5438}},
                    {Position = {x = 1756.13, y = 573.875, z = 49.8062}},
                    {Position = {x = 1827.75, y = 603, z = 51.75}},
                    {Position = {x = 1709.25, y = 527.5, z = 46.575}},
                    {Position = {x = 1761.88, y = 716.25, z = 51.2813}},
                    {Position = {x = 1712.5, y = 650.75, z = 49.7375}},
                    {Position = {x = 1815.88, y = 627.875, z = 51.75}},
                    {Position = {x = 1653.63, y = 529.75, z = 37.9813}},
                    {Position = {x = 1842.63, y = 679.5, z = 51.75}},
                    {Position = {x = 1821, y = 718.5, z = 51.925}},
                    {Position = {x = 1831.38, y = 616.375, z = 51.75}},
                    {Position = {x = 1690.75, y = 625, z = 39.1875}},
                    {Position = {x = 1733.38, y = 642.5, z = 50.825}},
                    {Position = {x = 1809, y = 597.25, z = 51.75}},
                    {Position = {x = 1723.63, y = 570.125, z = 44.6813}},
                    {Position = {x = 1707.38, y = 572.125, z = 41.8563}},
                    {Position = {x = 1659.63, y = 513.25, z = 41.2062}},
                    {Position = {x = 1806.25, y = 635.625, z = 51.75}},
                    {Position = {x = 1810, y = 689.25, z = 51.75}},
                    {Position = {x = 1844.13, y = 710.75, z = 51.75}},
                    {Position = {x = 1769.13, y = 704.75, z = 49.9625}},
                    {Position = {x = 1795.75, y = 696.5, z = 51.75}},
                    {Position = {x = 1774.13, y = 730.625, z = 51.325}},
                    {Position = {x = 1789.88, y = 598, z = 51.7}},
                    {Position = {x = 1807.88, y = 663.875, z = 51.8062}},
                    {Position = {x = 1838.75, y = 598.25, z = 51.75}},
                    {Position = {x = 1797.88, y = 574.375, z = 52.1}}
                }
            },
            ['Route 88'] = {
                Main = {x = 305.125, y = 1503, z = 51.125},
                Positions = {
                    {Position = {x = 316.375, y = 1619.88, z = 38.2875}},
                    {Position = {x = 278.125, y = 1487.38, z = 51.125}},
                    {Position = {x = 319.875, y = 1526.38, z = 51.125}},
                    {Position = {x = 311, y = 1494.13, z = 51.125}},
                    {Position = {x = 291.5, y = 1497.5, z = 51.125}},
                    {Position = {x = 262.875, y = 1564.88, z = 39.7062}},
                    {Position = {x = 248, y = 1514.25, z = 44.9875}},
                    {Position = {x = 341.75, y = 1494, z = 50.925}},
                    {Position = {x = 266.5, y = 1506.63, z = 49.1625}},
                    {Position = {x = 384.5, y = 1499.88, z = 51.3062}},
                    {Position = {x = 304.875, y = 1534, z = 51.1625}},
                    {Position = {x = 398.625, y = 1482.13, z = 52.4312}},
                    {Position = {x = 321.25, y = 1444.5, z = 52.8125}},
                    {Position = {x = 352.75, y = 1559.5, z = 44.7}},
                    {Position = {x = 273.875, y = 1519.38, z = 51.3625}},
                    {Position = {x = 324.875, y = 1485, z = 51.075}},
                    {Position = {x = 369.125, y = 1410.13, z = 66.9}},
                    {Position = {x = 242.375, y = 1482.13, z = 45.0688}},
                    {Position = {x = 379.25, y = 1423.5, z = 61.5875}},
                    {Position = {x = 386.5, y = 1528.38, z = 48.5437}},
                    {Position = {x = 361.625, y = 1490.25, z = 51.2437}},
                    {Position = {x = 362.75, y = 1507.63, z = 50.825}},
                    {Position = {x = 271.625, y = 1460.63, z = 50.2437}},
                    {Position = {x = 250.625, y = 1461.25, z = 49.7062}},
                    {Position = {x = 362.5, y = 1399.25, z = 69.7625}},
                    {Position = {x = 284.875, y = 1440.5, z = 51.025}},
                    {Position = {x = 294.625, y = 1555.38, z = 48.55}},
                    {Position = {x = 353.875, y = 1459.38, z = 53.2875}},
                    {Position = {x = 295.25, y = 1587.13, z = 43.8937}},
                    {Position = {x = 361.125, y = 1531.5, z = 49.1062}},
                    {Position = {x = 317.125, y = 1510.75, z = 51.125}},
                    {Position = {x = 325.5, y = 1558.63, z = 48.0187}},
                    {Position = {x = 282.375, y = 1535.75, z = 50.8875}},
                    {Position = {x = 324.375, y = 1608.38, z = 43.4313}},
                    {Position = {x = 335.875, y = 1508.13, z = 51.125}},
                    {Position = {x = 303.375, y = 1450.5, z = 51.7687}},
                    {Position = {x = 295.5, y = 1422.63, z = 51.6062}},
                    {Position = {x = 329.5, y = 1542.88, z = 50.0063}},
                    {Position = {x = 296.625, y = 1462.38, z = 51.3562}},
                    {Position = {x = 349.25, y = 1439.13, z = 55.4875}},
                    {Position = {x = 260.125, y = 1477.88, z = 47.7625}},
                    {Position = {x = 252, y = 1534.63, z = 43.3}},
                    {Position = {x = 382.75, y = 1512.25, z = 50.975}},
                    {Position = {x = 350.75, y = 1534.13, z = 47.3875}},
                    {Position = {x = 325.75, y = 1572.13, z = 47.3687}},
                    {Position = {x = 347.625, y = 1400.88, z = 68.0062}},
                    {Position = {x = 345.25, y = 1583.63, z = 43.0062}},
                    {Position = {x = 333.375, y = 1412.5, z = 62.0125}},
                    {Position = {x = 398.625, y = 1448, z = 55.6437}},
                    {Position = {x = 297.5, y = 1475, z = 51.075}}
                }
            },
            ['Royal Shore'] = {
                Main = {x = 355.875, y = 892.5, z = 53.75},
                Positions = {
                    {Position = {x = 459, y = 907.5, z = 65.1375}},
                    {Position = {x = 333.75, y = 917, z = 53.7438}},
                    {Position = {x = 347.75, y = 886.625, z = 53.5063}},
                    {Position = {x = 378.625, y = 875.375, z = 55.2563}},
                    {Position = {x = 357.875, y = 913.625, z = 55.525}},
                    {Position = {x = 263.5, y = 940.625, z = 51.8812}},
                    {Position = {x = 353.75, y = 877, z = 55.0438}},
                    {Position = {x = 339.25, y = 864.25, z = 54.1}},
                    {Position = {x = 317.875, y = 929.875, z = 53.4}},
                    {Position = {x = 391.625, y = 956, z = 62.8688}},
                    {Position = {x = 434.5, y = 875.75, z = 60.6625}},
                    {Position = {x = 360, y = 892.25, z = 53.7563}},
                    {Position = {x = 361.25, y = 805.25, z = 55.3125}},
                    {Position = {x = 330.375, y = 850.75, z = 53.1813}},
                    {Position = {x = 309.25, y = 890, z = 53.1625}},
                    {Position = {x = 390.5, y = 875.25, z = 56.9688}},
                    {Position = {x = 373.25, y = 884, z = 55.4313}},
                    {Position = {x = 367.75, y = 914.375, z = 56.275}},
                    {Position = {x = 433.375, y = 897, z = 60.9125}},
                    {Position = {x = 311.5, y = 865.875, z = 53.3562}},
                    {Position = {x = 365.625, y = 900.75, z = 55.5375}},
                    {Position = {x = 309.125, y = 950.875, z = 53.2625}},
                    {Position = {x = 355, y = 895, z = 53.5563}},
                    {Position = {x = 334.75, y = 828.375, z = 52.95}},
                    {Position = {x = 353.125, y = 864.625, z = 55.4313}},
                    {Position = {x = 353.875, y = 887.625, z = 53.7125}},
                    {Position = {x = 398.875, y = 798.125, z = 61.8688}},
                    {Position = {x = 364, y = 884, z = 55.0563}},
                    {Position = {x = 292.875, y = 938.25, z = 52.525}},
                    {Position = {x = 337.875, y = 944.875, z = 54.35}},
                    {Position = {x = 351, y = 902.625, z = 53.7563}},
                    {Position = {x = 292, y = 903.125, z = 52.7063}},
                    {Position = {x = 351.625, y = 932.25, z = 54.1063}},
                    {Position = {x = 411.875, y = 858.375, z = 59.9688}},
                    {Position = {x = 390.75, y = 862, z = 57.3375}},
                    {Position = {x = 474.5, y = 883.625, z = 66.6062}},
                    {Position = {x = 322, y = 996.25, z = 55.8625}},
                    {Position = {x = 361.875, y = 836, z = 55.55}},
                    {Position = {x = 348.625, y = 969.75, z = 55.925}},
                    {Position = {x = 317.625, y = 913.625, z = 53.7438}},
                    {Position = {x = 369.625, y = 953.625, z = 58.8188}},
                    {Position = {x = 484, y = 891.25, z = 68.3125}},
                    {Position = {x = 447.5, y = 931, z = 66.9375}},
                    {Position = {x = 323.75, y = 914.375, z = 53.6063}},
                    {Position = {x = 343.5, y = 979.125, z = 57.3438}},
                    {Position = {x = 361, y = 874.5, z = 55.1813}},
                    {Position = {x = 429.75, y = 916, z = 62.925}},
                    {Position = {x = 337, y = 934.625, z = 53.9063}},
                    {Position = {x = 377, y = 832.5, z = 56.6625}},
                    {Position = {x = 380.125, y = 805.5, z = 56.6063}}
                }
            }
        }
    };
end

-- The list of positions, to be able to randomize them

-- Editor or server specific actions
if (System.IsEditor()) then
    SCAAMBRSpawnLocations = {
        'Pussylands',
        'Centrallands',
        'Forestlands'
    };
else
    SCAAMBRSpawnLocations = {
        'Refugee',
        'Chernogorsk',
        'Bad Neighborhood',
        'Hunger Forest',
        'Kamishovo',
        'Dinner Area',
        'Trailer Zone',
        'Church',
        'Hotel',
        'Route 88',
        'Royal Shore'
    };
end

-- The list of lobby positions, so player will gather on that area

-- Editor or server specific actions
if (System.IsEditor()) then
    SCAAMBRLobbyProperties = {
        Positions = {
            {Position = {x = 342.2567, y = 646.7623, z = 19.4484}}
        };
    };
else
    SCAAMBRLobbyProperties = {
        Positions = {
            {Position = {x = 1322.45, y = 35.9851, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1330.18, y = 36.6821, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1337.2, y = 37.2974, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1326.03, y = 36.1468, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1333.77, y = 37.0091, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1319.18, y = 35.5702, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1340.17, y = 37.3381, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1343.66, y = 37.3445, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1343.86, y = 40.6852, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1340.29, y = 40.4847, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1337.11, y = 40.0397, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1333.79, y = 39.9638, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1330.19, y = 39.5956, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1326.36, y = 39.1837, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1322.81, y = 38.5277, z = 25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1319.48, y = 38.4509, z = 25}, Direction = {x = 0, y = 1, z = 0}}
        };
    };
end

-- Crate properties, including position, direction and item sets per phase

-- Editor or server specific actions
if (System.IsEditor()) then
    SCAAMBRCrateProperties = {
        Positions = {
            {Position = {x = 381.821, y = 615.893, z = 17}, Direction = {x = -0.329044, y = -0.944314, z = 0}},
            {Position = {x = 381.611, y = 603.031, z = 17}, Direction = {x = -0.784435, y = 0.620211, z = 0}},
            {Position = {x = 380.088, y = 627.883, z = 17}, Direction = {x = 0.761321, y = -0.648375, z = 0}},
            {Position = {x = 370.857, y = 631.601, z = 17}, Direction = {x = -0.998254, y = 0.0590653, z = 0}},
            {Position = {x = 358.824, y = 640.083, z = 17}, Direction = {x = 0.999918, y = 0.0128257, z = 0}},
            {Position = {x = 347.584, y = 611.453, z = 17.5408}, Direction = {x = -0.078198, y = -0.996938, z = 0}}
        }
    };
else
    SCAAMBRCrateProperties = {
        Positions = {
            {Position = {x = 416.749, y = 888.769, z = 65.2027}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 941.14, y = 292.533, z = 56.0812}, Direction = {x = 0.052336, y = 0.99863, z = 0}},
            {Position = {x = 828.25, y = 1569.88, z = 51.7672}, Direction = {x = -0.999391, y = -0.0348996, z = 0}},
            {Position = {x = 1412.81, y = 1740.24, z = 32.7004}, Direction = {x = -0.978148, y = 0.207912, z = 0}},
            {Position = {x = 814.241, y = 1497.97, z = 52.5126}, Direction = {x = 0.999848, y = 0.0174521, z = 0}},
            {Position = {x = 1194.08, y = 508.224, z = 47.4843}, Direction = {x = 0.819152, y = -0.573576, z = 0}},
            {Position = {x = 298.636, y = 1520.55, z = 51.2442}, Direction = {x = 0.601815, y = -0.798636, z = 0}},
            {Position = {x = 602.158, y = 247.398, z = 51.45}, Direction = {x = 0.978148, y = 0.207912, z = 0}},
            {Position = {x = 1222.7, y = 561.447, z = 46.8849}, Direction = {x = -0.809017, y = 0.587785, z = 0}},
            {Position = {x = 1421.82, y = 1150.83, z = 59}, Direction = {x = -0.999848, y = -0.0174525, z = 0}},
            {Position = {x = 1398.2, y = 953.794, z = 75.27}, Direction = {x = 0.93358, y = 0.358368, z = 0}},
            {Position = {x = 1008.75, y = 1260.87, z = 49.0125}, Direction = {x = -0.857167, y = -0.515038, z = 0}},
            {Position = {x = 700.024, y = 314.289, z = 52.1}, Direction = {x = 0.241922, y = 0.970296, z = 0}},
            {Position = {x = 1740.6, y = 1667.34, z = 45.6442}, Direction = {x = 0.529919, y = 0.848048, z = 0}},
            {Position = {x = 1682.6, y = 1770.34, z = 26.9284}, Direction = {x = -0.0697565, y = -0.997564, z = 0}},
            {Position = {x = 833.375, y = 1571.63, z = 51.7672}, Direction = {x = -0.0697565, y = 0.997564, z = 0}},
            {Position = {x = 827.343, y = 1468.28, z = 51.6837}, Direction = {x = 0.0348992, y = -0.999391, z = 0}},
            {Position = {x = 1221.1, y = 539.227, z = 47.7037}, Direction = {x = -0.573576, y = -0.819152, z = 0}},
            {Position = {x = 290.095, y = 1529.68, z = 51.2558}, Direction = {x = 0.544639, y = -0.838671, z = 0}},
            {Position = {x = 1396.31, y = 962.673, z = 75.256}, Direction = {x = 0.939693, y = 0.34202, z = 0}},
            {Position = {x = 344.141, y = 455.973, z = 45.1}, Direction = {x = -0.275637, y = 0.961262, z = 0}},
            {Position = {x = 875.433, y = 1495.04, z = 51.6967}, Direction = {x = -0.0348988, y = 0.999391, z = 0}},
            {Position = {x = 1147.39, y = 553.067, z = 46.75}, Direction = {x = 0.809017, y = -0.587785, z = 0}},
            {Position = {x = 1204.41, y = 1305.11, z = 54.2443}, Direction = {x = -0.990268, y = -0.139173, z = 0}},
            {Position = {x = 1806.84, y = 691.574, z = 51.7}, Direction = {x = 0.999391, y = -0.0348995, z = 0}},
            {Position = {x = 603.566, y = 1200.09, z = 102.121}, Direction = {x = -0.809017, y = -0.587785, z = 0}},
            {Position = {x = 1116.15, y = 559.669, z = 51.6688}, Direction = {x = 1, y = 1.78814e-007, z = 0}},
            {Position = {x = 1131.96, y = 1234.76, z = 57.9362}, Direction = {x = 0.422618, y = -0.906308, z = 0}},
            {Position = {x = 874.212, y = 1490.52, z = 58.9256}, Direction = {x = -0.999391, y = -0.0348986, z = 0}},
            {Position = {x = 1230.35, y = 535.583, z = 46.7}, Direction = {x = -0.573576, y = -0.819152, z = 0}},
            {Position = {x = 751.47, y = 1601.9, z = 51.49}, Direction = {x = -0.999848, y = -0.0174526, z = 0}},
            {Position = {x = 592.407, y = 757.19, z = 93.8751}, Direction = {x = 0.406737, y = 0.913545, z = 0}},
            {Position = {x = 880.96, y = 995.888, z = 106.696}, Direction = {x = 0.104528, y = -0.994522, z = 0}},
            {Position = {x = 939.514, y = 298.959, z = 55.1052}, Direction = {x = -0.052336, y = -0.99863, z = 0}},
            {Position = {x = 1406.91, y = 955.179, z = 75.27}, Direction = {x = -0.34202, y = 0.939693, z = 0}},
            {Position = {x = 696.637, y = 1245.34, z = 56.4832}, Direction = {x = -0.052336, y = -0.99863, z = 0}},
            {Position = {x = 583.905, y = 751.917, z = 97.9742}, Direction = {x = 0.906308, y = -0.422618, z = 0}},
            {Position = {x = 857.08, y = 1442.31, z = 55.6183}, Direction = {x = 0.342021, y = 0.939692, z = 0}},
            {Position = {x = 1731.99, y = 1667.85, z = 42.0671}, Direction = {x = 0.838671, y = -0.544639, z = 0}},
            {Position = {x = 584.214, y = 1007.99, z = 80.5187}, Direction = {x = 0.62932, y = 0.777146, z = 0}},
            {Position = {x = 760.29, y = 1607.71, z = 52.0222}, Direction = {x = 0.0523359, y = -0.99863, z = 0}},
            {Position = {x = 1708.35, y = 1031.34, z = 51.6375}, Direction = {x = -0.5, y = -0.866025, z = 0}},
            {Position = {x = 1042.29, y = 884.433, z = 120.02}, Direction = {x = 0.374607, y = 0.927184, z = 0}},
            {Position = {x = 1193.46, y = 1656.25, z = 52.9768}, Direction = {x = 0.891007, y = -0.453991, z = 0}},
            {Position = {x = 833.481, y = 1567.08, z = 55.7672}, Direction = {x = -0.0697567, y = 0.997564, z = 0}},
            {Position = {x = 766.369, y = 1613.05, z = 51.4924}, Direction = {x = -0.999848, y = -0.0174526, z = 0}},
            {Position = {x = 814.174, y = 1465.77, z = 51.6837}, Direction = {x = 0.997564, y = 0.069756, z = 0}},
            {Position = {x = 852.297, y = 1163.25, z = 41.6123}, Direction = {x = -0.681998, y = 0.731354, z = 0}},
            {Position = {x = 1227.06, y = 572.43, z = 47.0127}, Direction = {x = -0.809017, y = 0.587785, z = 0}},
            {Position = {x = 864.562, y = 1577.18, z = 51.3573}, Direction = {x = -0.997564, y = -0.0697565, z = 0}},
            {Position = {x = 1237.52, y = 1437.86, z = 52.9932}, Direction = {x = 0.945519, y = 0.325568, z = 0}},
            {Position = {x = 1747.38, y = 802.927, z = 51.2154}, Direction = {x = -0.0348995, y = -0.999391, z = 0}},
            {Position = {x = 1730.76, y = 1670.26, z = 40.95}, Direction = {x = -0.838671, y = 0.544639, z = 0}},
            {Position = {x = 860.817, y = 1491.08, z = 55.6324}, Direction = {x = 0.999391, y = 0.0348984, z = 0}},
            {Position = {x = 1608.28, y = 375.152, z = 51.956}, Direction = {x = -0.0174524, y = 0.999848, z = 0}},
            {Position = {x = 1212.25, y = 1195.42, z = 98.234}, Direction = {x = 0.819152, y = -0.573576, z = 0}},
            {Position = {x = 1537.87, y = 1679.51, z = 51.6753}, Direction = {x = -0.241922, y = -0.970296, z = 0}},
            {Position = {x = 1179.14, y = 1565.88, z = 75.531}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 722.444, y = 933.55, z = 116.435}, Direction = {x = 0.656059, y = 0.75471, z = 0}},
            {Position = {x = 1740.65, y = 1676.78, z = 40.95}, Direction = {x = 0.544639, y = 0.838671, z = 0}},
            {Position = {x = 1847.12, y = 707.759, z = 51.7}, Direction = {x = -0.99863, y = 0.0523359, z = 0}},
            {Position = {x = 804.292, y = 248.482, z = 54.4527}, Direction = {x = 0.970296, y = -0.241922, z = 0}},
            {Position = {x = 1774.81, y = 1555.1, z = 49.9338}, Direction = {x = 0.984808, y = 0.173648, z = 0}},
            {Position = {x = 914.166, y = 1561.05, z = 56.9812}, Direction = {x = -0.0348989, y = 0.999391, z = 0}},
            {Position = {x = 890.811, y = 1904.16, z = 51.3608}, Direction = {x = 0.374606, y = -0.927184, z = 0}},
            {Position = {x = 917.637, y = 1553.62, z = 52.4}, Direction = {x = -0.0174518, y = 0.999848, z = 0}},
            {Position = {x = 1676.47, y = 1531.97, z = 52.9767}, Direction = {x = -0.990268, y = -0.139173, z = 0}},
            {Position = {x = 638.46, y = 736.214, z = 97.15}, Direction = {x = 0.913545, y = -0.406738, z = 0}},
            {Position = {x = 594.678, y = 752.118, z = 93.8751}, Direction = {x = -0.906308, y = 0.422618, z = 0}},
            {Position = {x = 899.001, y = 1797.93, z = 51.4473}, Direction = {x = 0.906308, y = 0.422618, z = 0}},
            {Position = {x = 830.916, y = 1470.7, z = 51.6837}, Direction = {x = -0.99863, y = -0.0523359, z = 0}},
            {Position = {x = 295.742, y = 435.946, z = 46.7953}, Direction = {x = 0.999848, y = -0.0174525, z = 0}},
            {Position = {x = 353.003, y = 434.303, z = 45.15}, Direction = {x = 0.275637, y = -0.961262, z = 0}},
            {Position = {x = 1776.96, y = 1561.86, z = 49.8637}, Direction = {x = 0.139173, y = -0.990268, z = 0}},
            {Position = {x = 1300.35, y = 1221.77, z = 72.223}, Direction = {x = -0.139173, y = -0.990268, z = 0}},
            {Position = {x = 830.525, y = 1548.14, z = 51.7809}, Direction = {x = 1, y = 5.96046e-008, z = 0}},
            {Position = {x = 1144.32, y = 345.168, z = 59.3474}, Direction = {x = 0.0871558, y = -0.996195, z = 0}},
            {Position = {x = 299.164, y = 1533.16, z = 51.2527}, Direction = {x = -0.829038, y = -0.559193, z = 0}},
            {Position = {x = 374.43, y = 870.655, z = 55.3345}, Direction = {x = 0.707107, y = 0.707107, z = 0}},
            {Position = {x = 474.915, y = 897.286, z = 66.9244}, Direction = {x = -0.997564, y = 0.0697564, z = 0}},
            {Position = {x = 1806.55, y = 679.812, z = 51.75}, Direction = {x = 0.999391, y = -0.0348995, z = 0}},
            {Position = {x = 1148.93, y = 473.056, z = 51.4887}, Direction = {x = -0.809017, y = 0.587785, z = 0}},
            {Position = {x = 313.438, y = 139.033, z = 15.5693}, Direction = {x = 0.601815, y = 0.798636, z = 0}},
            {Position = {x = 420.092, y = 893.792, z = 60.6723}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1199.91, y = 506.159, z = 47.4337}, Direction = {x = -0.544639, y = -0.83867, z = 0}},
            {Position = {x = 709.585, y = 1480.88, z = 43.0848}, Direction = {x = 0.325568, y = -0.945519, z = 0}},
            {Position = {x = 282.528, y = 1521.66, z = 51.2362}, Direction = {x = 0.838671, y = 0.544639, z = 0}},
            {Position = {x = 1185.85, y = 1646.07, z = 57.3431}, Direction = {x = -0.898794, y = 0.438371, z = 0}},
            {Position = {x = 1123.94, y = 560.406, z = 51.6688}, Direction = {x = -0.999848, y = -0.0174525, z = 0}},
            {Position = {x = 925.9, y = 1527.93, z = 53.4237}, Direction = {x = 0.719339, y = -0.694659, z = 0}},
            {Position = {x = 1803.74, y = 605.727, z = 51.7}, Direction = {x = 0.999391, y = -0.0348995, z = 0}},
            {Position = {x = 1688.18, y = 1037.59, z = 51.6375}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1598.04, y = 379.298, z = 46.916}, Direction = {x = 1, y = -1.19209e-007, z = 0}},
            {Position = {x = 1841.51, y = 1588.87, z = 46.758}, Direction = {x = -0.0523359, y = -0.99863, z = 0}},
            {Position = {x = 930.974, y = 1526.94, z = 57.0525}, Direction = {x = 0.99863, y = 0.0523352, z = 0}},
            {Position = {x = 1240.98, y = 550.822, z = 47.0177}, Direction = {x = -0.573576, y = -0.819152, z = 0}},
            {Position = {x = 1240.04, y = 1375.14, z = 52.55}, Direction = {x = 0.529919, y = -0.848048, z = 0}},
            {Position = {x = 295.889, y = 445.697, z = 46.7953}, Direction = {x = 1, y = 1.78814e-007, z = 0}},
            {Position = {x = 288.809, y = 1481.54, z = 51.0771}, Direction = {x = 0.819152, y = 0.573576, z = 0}},
            {Position = {x = 1201.45, y = 322.591, z = 51.95}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1768.93, y = 1553.1, z = 49.75}, Direction = {x = -0.984808, y = -0.173648, z = 0}},
            {Position = {x = 1111.35, y = 1001.36, z = 102.25}, Direction = {x = 0.544639, y = -0.838671, z = 0}},
            {Position = {x = 860.614, y = 1440.01, z = 51.9883}, Direction = {x = -0.358368, y = -0.93358, z = 0}},
            {Position = {x = 1551.88, y = 1503.13, z = 86.0116}, Direction = {x = -0.731354, y = 0.681998, z = 0}},
            {Position = {x = 1227.41, y = 545.531, z = 47.6742}, Direction = {x = -0.819152, y = 0.573576, z = 0}},
            {Position = {x = 1407.02, y = 1752.24, z = 33.1788}, Direction = {x = 0.139173, y = 0.990268, z = 0}},
            {Position = {x = 862.376, y = 1490.79, z = 58.9415}, Direction = {x = 0.999391, y = 0.0348984, z = 0}},
            {Position = {x = 759.55, y = 1592.64, z = 52.0222}, Direction = {x = 0.99863, y = 0.0523357, z = 0}},
            {Position = {x = 768.368, y = 1601.23, z = 51.9521}, Direction = {x = 0.99863, y = 0.0523357, z = 0}},
            {Position = {x = 834.24, y = 1555.77, z = 51.7744}, Direction = {x = 0.0348995, y = 0.999391, z = 0}},
            {Position = {x = 364.525, y = 865.92, z = 59.7827}, Direction = {x = -0.707107, y = -0.707107, z = 0}},
            {Position = {x = 481.782, y = 901.485, z = 67.5376}, Direction = {x = 0.891006, y = -0.45399, z = 0}},
            {Position = {x = 337.039, y = 962.168, z = 54.9034}, Direction = {x = -0.87462, y = -0.48481, z = 0}},
            {Position = {x = 953.718, y = 295.484, z = 51.25}, Direction = {x = 0.997564, y = -0.0697565, z = 0}},
            {Position = {x = 1193.08, y = 453.493, z = 53.221}, Direction = {x = -0.573576, y = -0.819152, z = 0}},
            {Position = {x = 315.783, y = 1525.56, z = 51.1}, Direction = {x = 0.573576, y = -0.819152, z = 0}},
            {Position = {x = 1613.61, y = 384.137, z = 51.956}, Direction = {x = 1, y = -1.19209e-007, z = 0}},
            {Position = {x = 321.393, y = 441.457, z = 45.25}, Direction = {x = 0.87462, y = -0.48481, z = 0}},
            {Position = {x = 332.01, y = 963.87, z = 58.4679}, Direction = {x = -0.052336, y = -0.99863, z = 0}},
            {Position = {x = 1168.24, y = 595.192, z = 47.4433}, Direction = {x = -0.809017, y = 0.587785, z = 0}},
            {Position = {x = 1822.29, y = 608.012, z = 51.7}, Direction = {x = -0.999848, y = -0.0174525, z = 0}},
            {Position = {x = 738.462, y = 1621.21, z = 51.1379}, Direction = {x = -0.309017, y = 0.951057, z = 0}},
            {Position = {x = 1190.64, y = 1471.13, z = 53.1322}, Direction = {x = -0.258819, y = -0.965926, z = 0}},
            {Position = {x = 1227.44, y = 545.499, z = 51.3277}, Direction = {x = -0.829037, y = 0.559193, z = 0}},
            {Position = {x = 433.028, y = 885.903, z = 60.6375}, Direction = {x = 1, y = -1.19209e-007, z = 0}},
            {Position = {x = 1686.98, y = 1771.89, z = 26.1}, Direction = {x = 0.0174524, y = 0.999848, z = 0}},
            {Position = {x = 353.482, y = 437.351, z = 45.7835}, Direction = {x = -0.927184, y = -0.374607, z = 0}},
            {Position = {x = 1830.61, y = 641.808, z = 51.7}, Direction = {x = 0.999391, y = -0.0348995, z = 0}},
            {Position = {x = 930.613, y = 317.632, z = 48.41}, Direction = {x = 0.998629, y = -0.0523357, z = 0}},
            {Position = {x = 871.287, y = 1440.24, z = 52.3076}, Direction = {x = -0.358368, y = -0.93358, z = 0}},
            {Position = {x = 560.041, y = 1586.64, z = 51.2}, Direction = {x = 1, y = -1.19209e-007, z = 0}},
            {Position = {x = 1145.39, y = 479.287, z = 51.5588}, Direction = {x = -0.601815, y = -0.798636, z = 0}},
            {Position = {x = 1785.44, y = 1550.74, z = 49.75}, Direction = {x = 0.156434, y = -0.987688, z = 0}},
            {Position = {x = 566.282, y = 1593.87, z = 51.05}, Direction = {x = -0.48481, y = 0.87462, z = 0}},
            {Position = {x = 856.758, y = 1644.52, z = 51.6997}, Direction = {x = -0.743145, y = 0.669131, z = 0}},
            {Position = {x = 1383.96, y = 535.94, z = 37.285}, Direction = {x = -0.453991, y = -0.891006, z = 0}},
            {Position = {x = 1094.12, y = 510.795, z = 51.3}, Direction = {x = -0.996195, y = 0.0871556, z = 0}},
            {Position = {x = 833.664, y = 1460.68, z = 51.6049}, Direction = {x = 0.0348993, y = -0.999391, z = 0}},
            {Position = {x = 905.979, y = 406, z = 35.7304}, Direction = {x = 0.990268, y = -0.139174, z = 0}},
            {Position = {x = 344.141, y = 1181.52, z = 53.7055}, Direction = {x = -0.927184, y = -0.374607, z = 0}},
            {Position = {x = 534.173, y = 1385.66, z = 82.2522}, Direction = {x = 0.0348995, y = -0.999391, z = 0}},
            {Position = {x = 1101.1, y = 937.654, z = 102.262}, Direction = {x = 0.777146, y = 0.629321, z = 0}},
            {Position = {x = 644.04, y = 717.332, z = 97.15}, Direction = {x = 0.422618, y = 0.906308, z = 0}},
            {Position = {x = 1009.62, y = 1633.83, z = 63.5249}, Direction = {x = -0.422618, y = -0.906308, z = 0}},
            {Position = {x = 318.872, y = 1486.27, z = 51}, Direction = {x = 0.601815, y = -0.798636, z = 0}},
            {Position = {x = 422.773, y = 890.139, z = 65.2027}, Direction = {x = -1, y = -1.19209e-007, z = 0}},
            {Position = {x = 1747.47, y = 798.127, z = 51.15}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1245.47, y = 1744.85, z = 48.894}, Direction = {x = -0.469471, y = 0.882948, z = 0}},
            {Position = {x = 1205.49, y = 1316.1, z = 54.0587}, Direction = {x = -0.515038, y = -0.857167, z = 0}},
            {Position = {x = 959.705, y = 1787.21, z = 52.4539}, Direction = {x = -0.406736, y = 0.913546, z = 0}},
            {Position = {x = 1217.46, y = 546.421, z = 47.6742}, Direction = {x = 0.819152, y = -0.573576, z = 0}},
            {Position = {x = 866.957, y = 1443.39, z = 55.6172}, Direction = {x = -0.358368, y = -0.93358, z = 0}},
            {Position = {x = 1399.3, y = 967.957, z = 75.15}, Direction = {x = -0.358368, y = 0.93358, z = 0}},
            {Position = {x = 286.033, y = 1529.98, z = 51.4}, Direction = {x = -0.559193, y = 0.829038, z = 0}},
            {Position = {x = 824.163, y = 1496.52, z = 51.391}, Direction = {x = 0.999848, y = 0.0174521, z = 0}},
            {Position = {x = 1449.67, y = 1413.09, z = 90.6881}, Direction = {x = -0.325568, y = 0.945519, z = 0}},
            {Position = {x = 1298.43, y = 1792.61, z = 31.25}, Direction = {x = 0.241922, y = 0.970296, z = 0}},
            {Position = {x = 1008.63, y = 1633.34, z = 52.0533}, Direction = {x = 0.920505, y = -0.390731, z = 0}},
            {Position = {x = 583.611, y = 985.34, z = 81.2475}, Direction = {x = 0.743145, y = 0.669131, z = 0}},
            {Position = {x = 727.132, y = 937.122, z = 116.486}, Direction = {x = 0.838671, y = -0.544639, z = 0}},
            {Position = {x = 1209.02, y = 1309.51, z = 54.1769}, Direction = {x = -0.819152, y = 0.573576, z = 0}},
            {Position = {x = 356.351, y = 874.596, z = 55.0845}, Direction = {x = 0.694658, y = 0.71934, z = 0}},
            {Position = {x = 1217.66, y = 547.175, z = 51.3277}, Direction = {x = 0.819152, y = -0.573576, z = 0}},
            {Position = {x = 293.507, y = 1513.21, z = 51.2592}, Direction = {x = -0.829038, y = -0.559193, z = 0}},
            {Position = {x = 942.688, y = 294.881, z = 51.705}, Direction = {x = -0.052336, y = -0.99863, z = 0}},
            {Position = {x = 1185.34, y = 523.108, z = 47.1315}, Direction = {x = -0.819152, y = 0.573577, z = 0}},
            {Position = {x = 1341.43, y = 429.423, z = 49.7}, Direction = {x = -0.469472, y = 0.882948, z = 0}},
            {Position = {x = 731.598, y = 1346.05, z = 50.4579}, Direction = {x = 0.309017, y = 0.951057, z = 0}},
            {Position = {x = 1172.23, y = 529.405, z = 46.7452}, Direction = {x = 0.829038, y = -0.559193, z = 0}},
            {Position = {x = 992.531, y = 1625.39, z = 52.0497}, Direction = {x = -0.913545, y = 0.406737, z = 0}},
            {Position = {x = 960.68, y = 1800.06, z = 52.4539}, Direction = {x = 0.406736, y = -0.913546, z = 0}},
            {Position = {x = 288.447, y = 1522.81, z = 51.247}, Direction = {x = 0.829037, y = 0.559193, z = 0}},
            {Position = {x = 363.081, y = 858.56, z = 56.1587}, Direction = {x = 0.694658, y = 0.71934, z = 0}},
            {Position = {x = 1201.75, y = 457.411, z = 53.221}, Direction = {x = -0.71934, y = 0.694658, z = 0}},
            {Position = {x = 574.604, y = 739.019, z = 97.65}, Direction = {x = -0.052336, y = -0.99863, z = 0}},
            {Position = {x = 961.221, y = 1835.02, z = 57.3236}, Direction = {x = -0.927184, y = -0.374606, z = 0}},
            {Position = {x = 1007.33, y = 1630.92, z = 63.5249}, Direction = {x = 0.438371, y = 0.898794, z = 0}},
            {Position = {x = 1204.27, y = 1578.76, z = 78.617}, Direction = {x = -0.819152, y = -0.573576, z = 0}},
            {Position = {x = 1415.74, y = 1758.11, z = 33.1788}, Direction = {x = -0.156434, y = -0.987688, z = 0}},
            {Position = {x = 1064.04, y = 1695.65, z = 50.4664}, Direction = {x = -0.52992, y = -0.848048, z = 0}},
            {Position = {x = 803.254, y = 1623.51, z = 51.5635}, Direction = {x = -0.121869, y = 0.992546, z = 0}},
            {Position = {x = 826.093, y = 1570.32, z = 55.7672}, Direction = {x = 0.0523361, y = -0.99863, z = 0}},
            {Position = {x = 734.757, y = 932.428, z = 116.426}, Direction = {x = -0.838671, y = 0.544639, z = 0}},
            {Position = {x = 1019.37, y = 1253.12, z = 48.4058}, Direction = {x = 0.93358, y = -0.358368, z = 0}},
            {Position = {x = 1207.19, y = 489.973, z = 47.1349}, Direction = {x = -0.573576, y = -0.819152, z = 0}},
            {Position = {x = 924.053, y = 1505.61, z = 52.6771}, Direction = {x = -0.0174518, y = 0.999848, z = 0}},
            {Position = {x = 786.251, y = 1598.57, z = 51.5035}, Direction = {x = -0.994522, y = -0.104529, z = 0}},
            {Position = {x = 829.495, y = 1555.88, z = 51.7809}, Direction = {x = 0.0348995, y = 0.999391, z = 0}},
            {Position = {x = 865.643, y = 1557.85, z = 51.4947}, Direction = {x = -0.997564, y = -0.0697565, z = 0}},
            {Position = {x = 734.022, y = 1357.73, z = 49.6256}, Direction = {x = -0.207912, y = -0.978148, z = 0}},
            {Position = {x = 575.011, y = 992.755, z = 80.65}, Direction = {x = 0.656059, y = -0.75471, z = 0}},
            {Position = {x = 1212.14, y = 1328.59, z = 53.8576}, Direction = {x = 0.819152, y = -0.573576, z = 0}},
            {Position = {x = 1119.27, y = 553.823, z = 51.35}, Direction = {x = 8.74228e-008, y = -1, z = 0}},
            {Position = {x = 1675.55, y = 1603.99, z = 51.25}, Direction = {x = -0.809017, y = -0.587785, z = 0}},
            {Position = {x = 1562.8, y = 782.074, z = 54.5713}, Direction = {x = 0.882948, y = 0.469472, z = 0}},
            {Position = {x = 1136.24, y = 963.775, z = 102.25}, Direction = {x = 0.999848, y = -0.0174525, z = 0}},
            {Position = {x = 1410.95, y = 1749.64, z = 33.1087}, Direction = {x = -0.156434, y = -0.987688, z = 0}},
            {Position = {x = 820.589, y = 1494.35, z = 52.5126}, Direction = {x = -0.999391, y = -0.0348992, z = 0}},
            {Position = {x = 876.281, y = 1397.73, z = 51.0069}, Direction = {x = -0.438372, y = -0.898794, z = 0}},
            {Position = {x = 1664.5, y = 1049.16, z = 51.7267}, Direction = {x = -0.999848, y = 0.0174521, z = 0}},
            {Position = {x = 871.457, y = 1487.96, z = 55.6244}, Direction = {x = 0.999391, y = 0.0348984, z = 0}},
            {Position = {x = 335.062, y = 887.763, z = 53.5787}, Direction = {x = 0.681998, y = 0.731354, z = 0}},
            {Position = {x = 930.996, y = 1362.04, z = 48.55}, Direction = {x = 0.777146, y = -0.62932, z = 0}},
            {Position = {x = 1214.14, y = 570.035, z = 46.9337}, Direction = {x = -0.829037, y = 0.559193, z = 0}},
            {Position = {x = 596.084, y = 755.191, z = 97.9741}, Direction = {x = -0.913545, y = 0.406737, z = 0}},
            {Position = {x = 961.411, y = 1831.82, z = 52.3547}, Direction = {x = 0.422617, y = -0.906308, z = 0}},
            {Position = {x = 985.322, y = 1135.75, z = 48.95}, Direction = {x = 0.615661, y = -0.788011, z = 0}},
            {Position = {x = 944.109, y = 1786.53, z = 51.539}, Direction = {x = -0.325568, y = 0.945519, z = 0}},
            {Position = {x = 904.945, y = 1791.31, z = 55.9613}, Direction = {x = -0.406736, y = 0.913546, z = 0}},
            {Position = {x = 1607.42, y = 382.955, z = 47.3363}, Direction = {x = 0.99863, y = 0.0523357, z = 0}},
            {Position = {x = 347.472, y = 437.157, z = 45.05}, Direction = {x = -0.965926, y = -0.25882, z = 0}},
            {Position = {x = 1013.06, y = 1158.92, z = 47.85}, Direction = {x = 0.190809, y = -0.981627, z = 0}},
            {Position = {x = 1183.72, y = 457.384, z = 53.221}, Direction = {x = 0.559193, y = 0.829038, z = 0}},
            {Position = {x = 957.885, y = 1842.89, z = 53.7069}, Direction = {x = 0.422617, y = -0.906308, z = 0}},
            {Position = {x = 529.175, y = 1380.74, z = 82.1821}, Direction = {x = 0.99863, y = 0.0523359, z = 0}},
            {Position = {x = 535.809, y = 1377.91, z = 82.2542}, Direction = {x = -0.0697565, y = 0.997564, z = 0}},
            {Position = {x = 1603.26, y = 1053.83, z = 56.6827}, Direction = {x = 0.5, y = 0.866025, z = 0}},
            {Position = {x = 1549.9, y = 1340.18, z = 98.1679}, Direction = {x = -0.559193, y = 0.829038, z = 0}},
            {Position = {x = 911.26, y = 1564.4, z = 53.3045}, Direction = {x = -0.999391, y = -0.0348991, z = 0}},
            {Position = {x = 1176.14, y = 591.481, z = 47.5231}, Direction = {x = -0.829037, y = 0.559193, z = 0}},
            {Position = {x = 667.477, y = 1049.93, z = 77.3297}, Direction = {x = -0.87462, y = -0.48481, z = 0}},
            {Position = {x = 901.263, y = 1783.48, z = 52.3078}, Direction = {x = 0.906308, y = 0.422617, z = 0}},
            {Position = {x = 1397.2, y = 953.575, z = 75.2544}, Direction = {x = -0.93358, y = -0.358367, z = 0}},
            {Position = {x = 867.153, y = 1444.8, z = 52.3146}, Direction = {x = -0.93358, y = 0.358368, z = 0}},
            {Position = {x = 540.057, y = 1568.09, z = 51.7927}, Direction = {x = -0.707107, y = -0.707107, z = 0}},
            {Position = {x = 393.267, y = 602.013, z = 53.3767}, Direction = {x = -0.406737, y = -0.913546, z = 0}},
            {Position = {x = 343.577, y = 897.598, z = 53.7}, Direction = {x = -0.681999, y = -0.731354, z = 0}},
            {Position = {x = 1671.66, y = 1768.82, z = 26.9284}, Direction = {x = 0.999391, y = -0.0348995, z = 0}},
            {Position = {x = 1176.15, y = 597.546, z = 47.3732}, Direction = {x = -0.573576, y = -0.819152, z = 0}},
            {Position = {x = 1636.55, y = 797.855, z = 53.15}, Direction = {x = 0.978148, y = 0.207912, z = 0}},
            {Position = {x = 829.872, y = 1460.48, z = 51.6049}, Direction = {x = 0.0348993, y = -0.999391, z = 0}},
            {Position = {x = 1481.11, y = 308.635, z = 47.8036}, Direction = {x = 0.882948, y = 0.469471, z = 0}},
            {Position = {x = 1402.34, y = 963.372, z = 75.256}, Direction = {x = -0.309017, y = 0.951057, z = 0}},
            {Position = {x = 471.369, y = 1093.46, z = 109.977}, Direction = {x = -0.406737, y = -0.913546, z = 0}},
            {Position = {x = 1603.77, y = 386.732, z = 51.956}, Direction = {x = 0.999848, y = 0.0174521, z = 0}},
            {Position = {x = 1221.67, y = 547.801, z = 51.3277}, Direction = {x = 0.573576, y = 0.819152, z = 0}},
            {Position = {x = 913.494, y = 1567.77, z = 53.323}, Direction = {x = -0.0348989, y = 0.999391, z = 0}},
            {Position = {x = 1188.34, y = 529.382, z = 47.1117}, Direction = {x = -0.809017, y = 0.587785, z = 0}},
            {Position = {x = 337.626, y = 961.006, z = 58.5685}, Direction = {x = -0.052336, y = -0.99863, z = 0}},
            {Position = {x = 1245.61, y = 1625.97, z = 53.3516}, Direction = {x = 0.707107, y = 0.707107, z = 0}},
            {Position = {x = 1739.61, y = 1670.26, z = 41.9643}, Direction = {x = 0.838671, y = -0.544639, z = 0}},
            {Position = {x = 829.335, y = 253.853, z = 50.13}, Direction = {x = -0.970296, y = 0.241922, z = 0}},
            {Position = {x = 658.536, y = 742.44, z = 97.15}, Direction = {x = -0.906308, y = 0.422618, z = 0}},
            {Position = {x = 1788.36, y = 713.707, z = 51.75}, Direction = {x = -1, y = 5.96046e-008, z = 0}},
            {Position = {x = 805.413, y = 245.928, z = 50.7992}, Direction = {x = 0.241922, y = 0.970296, z = 0}},
            {Position = {x = 1683.93, y = 680.497, z = 39.1213}, Direction = {x = 0.992546, y = 0.121869, z = 0}},
            {Position = {x = 1175.81, y = 976.262, z = 102.25}, Direction = {x = -0.961262, y = -0.275638, z = 0}},
            {Position = {x = 1688.96, y = 460.439, z = 51.6698}, Direction = {x = -0.0174524, y = 0.999848, z = 0}},
            {Position = {x = 835.449, y = 1573.63, z = 55.7672}, Direction = {x = -0.99863, y = -0.0523361, z = 0}},
            {Position = {x = 1190.04, y = 1645.39, z = 53.6742}, Direction = {x = 0.438371, y = 0.898794, z = 0}},
            {Position = {x = 909.851, y = 1787.87, z = 52.3078}, Direction = {x = -0.920505, y = -0.39073, z = 0}},
            {Position = {x = 866.656, y = 1537.42, z = 51.4491}, Direction = {x = -0.997564, y = -0.0697565, z = 0}},
            {Position = {x = 868.425, y = 1499.54, z = 51.7217}, Direction = {x = -6.4075e-007, y = -1, z = 0}},
            {Position = {x = 1824.6, y = 608.088, z = 51.7}, Direction = {x = 1, y = 1.78814e-007, z = 0}},
            {Position = {x = 952.521, y = 1624.35, z = 68.1921}, Direction = {x = 0.642788, y = -0.766045, z = 0}},
            {Position = {x = 1537.92, y = 445.739, z = 41.5918}, Direction = {x = 0.0174523, y = -0.999848, z = 0}},
            {Position = {x = 1673.73, y = 1041.21, z = 51.645}, Direction = {x = 0.48481, y = 0.87462, z = 0}},
            {Position = {x = 1165.73, y = 935.713, z = 102.25}, Direction = {x = -0.731354, y = 0.681998, z = 0}},
            {Position = {x = 329.763, y = 961.618, z = 54.7769}, Direction = {x = 0.999391, y = -0.0348995, z = 0}},
            {Position = {x = 812.99, y = 255.28, z = 49.95}, Direction = {x = 0.224951, y = 0.97437, z = 0}},
            {Position = {x = 868.562, y = 1441.18, z = 58.9365}, Direction = {x = -0.913545, y = 0.406737, z = 0}},
            {Position = {x = 329.855, y = 953.553, z = 58.4385}, Direction = {x = 0.0348995, y = 0.999391, z = 0}},
            {Position = {x = 1931.05, y = 767.531, z = 42.0169}, Direction = {x = -0.999391, y = 0.0348994, z = 0}},
            {Position = {x = 1805.62, y = 657.586, z = 51.819}, Direction = {x = 0.999391, y = -0.0348995, z = 0}},
            {Position = {x = 1192.26, y = 1650.66, z = 57.3298}, Direction = {x = 0.469472, y = 0.882948, z = 0}},
            {Position = {x = 896.198, y = 405.656, z = 35.7304}, Direction = {x = -0.990268, y = 0.139173, z = 0}},
            {Position = {x = 954.624, y = 1832.66, z = 53.6686}, Direction = {x = 0.906308, y = 0.422617, z = 0}},
            {Position = {x = 335.571, y = 954.799, z = 58.554}, Direction = {x = 0.0348995, y = 0.999391, z = 0}},
            {Position = {x = 1534.52, y = 767.058, z = 54.8}, Direction = {x = -0.882948, y = -0.469473, z = 0}},
            {Position = {x = 350.994, y = 440.336, z = 45.7811}, Direction = {x = -0.292372, y = 0.956305, z = 0}},
            {Position = {x = 1181.89, y = 522.384, z = 46.7}, Direction = {x = -0.573576, y = -0.819152, z = 0}},
            {Position = {x = 589.383, y = 748.967, z = 97.9742}, Direction = {x = -0.906308, y = 0.422618, z = 0}},
            {Position = {x = 331.431, y = 883.029, z = 53.6345}, Direction = {x = -0.694658, y = -0.71934, z = 0}},
            {Position = {x = 860.898, y = 1488.38, z = 52.3393}, Direction = {x = 0.999391, y = 0.0348984, z = 0}},
            {Position = {x = 920.158, y = 1562.9, z = 53.433}, Direction = {x = -0.0348989, y = 0.999391, z = 0}},
            {Position = {x = 749.513, y = 1094.52, z = 60.7487}, Direction = {x = -0.241922, y = -0.970296, z = 0}},
            {Position = {x = 807.846, y = 246.715, z = 50.7992}, Direction = {x = 0.970296, y = -0.241922, z = 0}},
            {Position = {x = 303.737, y = 1526.39, z = 51.276}, Direction = {x = -0.829037, y = -0.559193, z = 0}},
            {Position = {x = 588.12, y = 738.583, z = 97.65}, Direction = {x = 8.74228e-008, y = -1, z = 0}},
            {Position = {x = 1207.93, y = 571.284, z = 46.9337}, Direction = {x = -0.544639, y = -0.83867, z = 0}},
            {Position = {x = 957.712, y = 1840.14, z = 57.319}, Direction = {x = -0.422617, y = 0.906308, z = 0}},
            {Position = {x = 1188.5, y = 459.309, z = 48.6013}, Direction = {x = -0.559193, y = -0.829037, z = 0}},
            {Position = {x = 947.202, y = 268.147, z = 51.35}, Direction = {x = -0.731354, y = -0.681998, z = 0}},
            {Position = {x = 418.9, y = 891.259, z = 61.5492}, Direction = {x = -1, y = 5.96046e-008, z = 0}},
            {Position = {x = 1075.5, y = 1533.11, z = 56.4697}, Direction = {x = 0.422618, y = 0.906308, z = 0}},
            {Position = {x = 941.244, y = 301.765, z = 51.41}, Direction = {x = 0.0348995, y = 0.999391, z = 0}},
            {Position = {x = 817.887, y = 1469.51, z = 51.6837}, Direction = {x = 0.996195, y = 0.0871552, z = 0}},
            {Position = {x = 873.2, y = 1487.01, z = 52.3206}, Direction = {x = -0.0174517, y = 0.999848, z = 0}},
            {Position = {x = 944.002, y = 290.2, z = 51.25}, Direction = {x = -0.052336, y = -0.99863, z = 0}},
            {Position = {x = 1386.29, y = 1438.69, z = 90.2737}, Direction = {x = 0.777146, y = -0.62932, z = 0}},
            {Position = {x = 565.687, y = 997.799, z = 80.925}, Direction = {x = 0.656059, y = -0.754709, z = 0}},
            {Position = {x = 1408.9, y = 1741.17, z = 32.64}, Direction = {x = 0.981627, y = -0.190809, z = 0}},
            {Position = {x = 1152.07, y = 549.997, z = 57.9899}, Direction = {x = 0.829038, y = -0.559193, z = 0}},
            {Position = {x = 1204.43, y = 564.176, z = 46.9337}, Direction = {x = 0.559193, y = 0.829038, z = 0}},
            {Position = {x = 604.038, y = 254.743, z = 51.45}, Direction = {x = 0.694658, y = -0.71934, z = 0}},
            {Position = {x = 1414.94, y = 951.723, z = 75.2544}, Direction = {x = 0.809017, y = -0.587785, z = 0}},
            {Position = {x = 1055.09, y = 1696.89, z = 50.4672}, Direction = {x = 0.587786, y = 0.809017, z = 0}},
            {Position = {x = 733.98, y = 944.11, z = 115.815}, Direction = {x = 0.544639, y = 0.838671, z = 0}},
            {Position = {x = 1231.84, y = 467.044, z = 47.3478}, Direction = {x = 0.809017, y = -0.587785, z = 0}},
            {Position = {x = 1734.44, y = 719.27, z = 49.6842}, Direction = {x = 0.052336, y = -0.99863, z = 0}},
            {Position = {x = 1816.79, y = 1068.12, z = 48.3929}, Direction = {x = 0.601815, y = -0.798636, z = 0}},
            {Position = {x = 644.287, y = 752.411, z = 97.15}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1111.16, y = 192.148, z = 50.7724}, Direction = {x = -0.515038, y = 0.857167, z = 0}},
            {Position = {x = 1132.19, y = 963.443, z = 102.25}, Direction = {x = -1, y = 5.96046e-008, z = 0}},
            {Position = {x = 812.332, y = 254.397, z = 50.7992}, Direction = {x = -0.241922, y = -0.970296, z = 0}},
            {Position = {x = 1206.6, y = 510.479, z = 47.4337}, Direction = {x = 0.819152, y = -0.573576, z = 0}},
            {Position = {x = 874.208, y = 1494.03, z = 52.3186}, Direction = {x = 0.0348987, y = -0.999391, z = 0}},
            {Position = {x = 559.079, y = 1690.76, z = 40.3061}, Direction = {x = -0.920505, y = -0.390731, z = 0}},
            {Position = {x = 1773.38, y = 387.965, z = 44.9005}, Direction = {x = -0.573576, y = 0.819152, z = 0}},
            {Position = {x = 902.907, y = 410.833, z = 36.6937}, Direction = {x = 0.121869, y = -0.992546, z = 0}},
            {Position = {x = 1824.01, y = 707.41, z = 51.9347}, Direction = {x = -0.999391, y = 0.0348994, z = 0}},
            {Position = {x = 1845.67, y = 667.49, z = 51.7337}, Direction = {x = -0.99863, y = 0.0523359, z = 0}},
            {Position = {x = 592.897, y = 762.447, z = 93.8751}, Direction = {x = -0.390731, y = -0.920505, z = 0}},
            {Position = {x = 1197.33, y = 501.2, z = 50.7807}, Direction = {x = 0.601815, y = 0.798636, z = 0}},
            {Position = {x = 898.119, y = 405.105, z = 36.6761}, Direction = {x = 0.139173, y = 0.990268, z = 0}},
            {Position = {x = 1746.31, y = 921.896, z = 53.05}, Direction = {x = -0.978148, y = -0.207912, z = 0}},
            {Position = {x = 1832.9, y = 596.264, z = 51.779}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 277.756, y = 140.426, z = 17.4575}, Direction = {x = 0.809017, y = -0.587785, z = 0}},
            {Position = {x = 1405.47, y = 1756.55, z = 33.1788}, Direction = {x = 0.156434, y = 0.987688, z = 0}},
            {Position = {x = 696.683, y = 1292.41, z = 54.5113}, Direction = {x = 0.0348995, y = -0.999391, z = 0}},
            {Position = {x = 1560.19, y = 958.321, z = 104.266}, Direction = {x = -0.731354, y = 0.681998, z = 0}},
            {Position = {x = 802.048, y = 250.055, z = 50.13}, Direction = {x = -0.97437, y = 0.224951, z = 0}},
            {Position = {x = 420.604, y = 878.392, z = 61.5787}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 825.742, y = 1470.33, z = 51.6837}, Direction = {x = -0.999391, y = -0.0348991, z = 0}},
            {Position = {x = 861.793, y = 1455.79, z = 51.51}, Direction = {x = 0.945518, y = -0.325569, z = 0}},
            {Position = {x = 1870.52, y = 503.502, z = 54.4835}, Direction = {x = -0.882948, y = -0.469473, z = 0}},
            {Position = {x = 890.411, y = 1513.21, z = 51.6059}, Direction = {x = 0.819152, y = 0.573576, z = 0}},
            {Position = {x = 415.558, y = 886.117, z = 65.2027}, Direction = {x = -1, y = 1.78814e-007, z = 0}},
            {Position = {x = 302.737, y = 442.989, z = 46.1}, Direction = {x = 0.999848, y = -0.0174526, z = 0}},
            {Position = {x = 339.829, y = 894.109, z = 53.5788}, Direction = {x = -0.707107, y = -0.707107, z = 0}},
            {Position = {x = 329.712, y = 942.715, z = 54.0591}, Direction = {x = -0.99863, y = 0.0523359, z = 0}},
            {Position = {x = 1192.13, y = 496.013, z = 47.0099}, Direction = {x = 0.819152, y = -0.573576, z = 0}},
            {Position = {x = 840.875, y = 1540.63, z = 51.5957}, Direction = {x = 0.997564, y = 0.0697564, z = 0}},
            {Position = {x = 1813.99, y = 619.413, z = 51.779}, Direction = {x = 8.74228e-008, y = -1, z = 0}},
            {Position = {x = 589.508, y = 754.122, z = 93.8751}, Direction = {x = 0.913545, y = -0.406737, z = 0}},
            {Position = {x = 318.551, y = 442.557, z = 45.25}, Direction = {x = -0.87462, y = 0.48481, z = 0}},
            {Position = {x = 1197.06, y = 1329.31, z = 47.5936}, Direction = {x = -0.406737, y = 0.913545, z = 0}},
            {Position = {x = 1584.98, y = 1046.1, z = 58.1011}, Direction = {x = -0.0174524, y = 0.999848, z = 0}},
            {Position = {x = 716.653, y = 936.782, z = 115.777}, Direction = {x = -0.999848, y = 0.0174521, z = 0}},
            {Position = {x = 1194.7, y = 1652.18, z = 53.6502}, Direction = {x = -0.469472, y = -0.882948, z = 0}},
            {Position = {x = 1017.69, y = 1626.17, z = 52.0436}, Direction = {x = 0.241922, y = -0.970296, z = 0}},
            {Position = {x = 733.914, y = 939.656, z = 116.435}, Direction = {x = -0.559193, y = -0.829037, z = 0}},
            {Position = {x = 461.179, y = 707.842, z = 89.7363}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1098.42, y = 242.492, z = 52.15}, Direction = {x = 0.0348994, y = -0.999391, z = 0}},
            {Position = {x = 951.2, y = 1845.1, z = 52.9688}, Direction = {x = -0.406736, y = 0.913546, z = 0}},
            {Position = {x = 1781.14, y = 1557.47, z = 50.0136}, Direction = {x = -0.981627, y = -0.190809, z = 0}},
            {Position = {x = 367.581, y = 869.203, z = 59.7827}, Direction = {x = 0.694658, y = 0.71934, z = 0}},
            {Position = {x = 1295.66, y = 1783.85, z = 32.1735}, Direction = {x = -0.965926, y = 0.258819, z = 0}},
            {Position = {x = 1240.15, y = 1007.49, z = 99.4914}, Direction = {x = -0.829038, y = -0.559193, z = 0}},
            {Position = {x = 591.212, y = 763.932, z = 97.9742}, Direction = {x = -0.406737, y = -0.913545, z = 0}},
            {Position = {x = 1155.07, y = 548.11, z = 57.9884}, Direction = {x = -0.819152, y = 0.573577, z = 0}},
            {Position = {x = 1141.74, y = 472.108, z = 51.5588}, Direction = {x = 0.573576, y = 0.819152, z = 0}},
            {Position = {x = 1736.95, y = 1665.02, z = 45.7157}, Direction = {x = -0.529919, y = -0.848048, z = 0}},
            {Position = {x = 927.38, y = 1529.7, z = 57.0714}, Direction = {x = 0.0348989, y = -0.999391, z = 0}},
            {Position = {x = 1587.47, y = 791.028, z = 53.15}, Direction = {x = -0.965926, y = -0.258819, z = 0}},
            {Position = {x = 923.424, y = 1527.81, z = 52.4927}, Direction = {x = -0.99863, y = -0.0523357, z = 0}},
            {Position = {x = 338.005, y = 1021.17, z = 59.2}, Direction = {x = -0.997564, y = -0.0697572, z = 0}},
            {Position = {x = 838.696, y = 1550.79, z = 51.7809}, Direction = {x = -0.99863, y = -0.0523357, z = 0}},
            {Position = {x = 1036.52, y = 1234.32, z = 48.4942}, Direction = {x = 0.694658, y = -0.71934, z = 0}},
            {Position = {x = 960.42, y = 1835.14, z = 53.6742}, Direction = {x = -0.422617, y = 0.906308, z = 0}},
            {Position = {x = 632.857, y = 739.218, z = 97.15}, Direction = {x = -0.913545, y = 0.406737, z = 0}},
            {Position = {x = 1111.32, y = 565.837, z = 51.6688}, Direction = {x = -0.0174525, y = -0.999848, z = 0}},
            {Position = {x = 1136.1, y = 474.245, z = 51.5588}, Direction = {x = 0.809017, y = -0.587785, z = 0}},
            {Position = {x = 369.174, y = 860.21, z = 59.7827}, Direction = {x = -0.71934, y = 0.694658, z = 0}},
            {Position = {x = 1093.61, y = 978.966, z = 102.18}, Direction = {x = 0.961262, y = -0.275637, z = 0}},
            {Position = {x = 859.902, y = 1443.01, z = 52.3287}, Direction = {x = 0.325569, y = 0.945518, z = 0}},
            {Position = {x = 997.503, y = 1620.49, z = 52.2211}, Direction = {x = 0.920505, y = -0.390731, z = 0}},
            {Position = {x = 610.044, y = 254.294, z = 51.45}, Direction = {x = -0.731354, y = -0.681998, z = 0}},
            {Position = {x = 1030.85, y = 375.966, z = 52}, Direction = {x = 0.707107, y = -0.707107, z = 0}},
            {Position = {x = 1611.45, y = 377.55, z = 47.3363}, Direction = {x = 1, y = 1.78814e-007, z = 0}},
            {Position = {x = 1337.78, y = 725.34, z = 56.7}, Direction = {x = 1, y = 1.78814e-007, z = 0}},
            {Position = {x = 869.858, y = 269.869, z = 50.1}, Direction = {x = -0.99863, y = 0.0523359, z = 0}},
            {Position = {x = 911.213, y = 1787.29, z = 51.3389}, Direction = {x = 0.913546, y = 0.406736, z = 0}},
            {Position = {x = 1193.08, y = 462.182, z = 48.6013}, Direction = {x = 0.829038, y = -0.559193, z = 0}},
            {Position = {x = 950.231, y = 1798.91, z = 52.4567}, Direction = {x = 0.406736, y = -0.913546, z = 0}},
            {Position = {x = 620.203, y = 714.512, z = 97.15}, Direction = {x = 0.406737, y = 0.913545, z = 0}},
            {Position = {x = 810.284, y = 248.209, z = 54.4527}, Direction = {x = -0.224951, y = -0.97437, z = 0}},
            {Position = {x = 908.305, y = 1784.21, z = 55.9613}, Direction = {x = -0.406736, y = 0.913546, z = 0}},
            {Position = {x = 1612.17, y = 393.639, z = 46.6585}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1201.33, y = 457.244, z = 48.6013}, Direction = {x = -0.838671, y = 0.544639, z = 0}},
            {Position = {x = 836.75, y = 1569, z = 51.3922}, Direction = {x = 0.997564, y = 0.0697564, z = 0}},
            {Position = {x = 1297.98, y = 1790.61, z = 32.1735}, Direction = {x = 0.0174524, y = -0.999848, z = 0}},
            {Position = {x = 904.489, y = 403.05, z = 36.7088}, Direction = {x = -0.984808, y = 0.173648, z = 0}},
            {Position = {x = 840.625, y = 1545.5, z = 51.5604}, Direction = {x = 0.997564, y = 0.0697564, z = 0}},
            {Position = {x = 559.214, y = 409.903, z = 52.4}, Direction = {x = 0.970296, y = 0.241922, z = 0}},
            {Position = {x = 1846.08, y = 678.869, z = 51.7}, Direction = {x = -0.99863, y = 0.0523359, z = 0}},
            {Position = {x = 764.306, y = 1601.08, z = 52.0222}, Direction = {x = -0.0348994, y = 0.999391, z = 0}},
            {Position = {x = 279.476, y = 1375.55, z = 50.8225}, Direction = {x = 1, y = -1.19209e-007, z = 0}},
            {Position = {x = 1175.39, y = 1658.73, z = 52.9051}, Direction = {x = -0.891006, y = 0.453991, z = 0}},
            {Position = {x = 730.769, y = 929.067, z = 116.435}, Direction = {x = -0.559193, y = -0.829037, z = 0}},
            {Position = {x = 785.291, y = 1400.31, z = 51.2645}, Direction = {x = 0.970296, y = -0.241922, z = 0}},
            {Position = {x = 1159.3, y = 999.971, z = 102.25}, Direction = {x = -0.573576, y = -0.819152, z = 0}},
            {Position = {x = 597.803, y = 766.28, z = 97.9741}, Direction = {x = -0.422618, y = -0.906308, z = 0}},
            {Position = {x = 1681.09, y = 1764.34, z = 26.632}, Direction = {x = -0.0697565, y = -0.997564, z = 0}},
            {Position = {x = 952.461, y = 1791.32, z = 52.4444}, Direction = {x = 0.920505, y = 0.390731, z = 0}},
            {Position = {x = 1134.25, y = 968.595, z = 102.25}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 548.004, y = 1581.41, z = 51.4}, Direction = {x = 0.694658, y = 0.71934, z = 0}},
            {Position = {x = 584.003, y = 761.567, z = 98.4072}, Direction = {x = 0.913546, y = -0.406736, z = 0}},
            {Position = {x = 813.916, y = 250.524, z = 54.4527}, Direction = {x = -0.970296, y = 0.241922, z = 0}},
            {Position = {x = 765.258, y = 1595.99, z = 52.0222}, Direction = {x = -0.0174523, y = 0.999848, z = 0}},
            {Position = {x = 608.713, y = 247.063, z = 51.45}, Direction = {x = -0.694658, y = 0.71934, z = 0}},
            {Position = {x = 573.592, y = 1008.76, z = 80.65}, Direction = {x = 0.99863, y = 0.0523359, z = 0}},
            {Position = {x = 299.768, y = 1516.97, z = 51.2508}, Direction = {x = 0.559193, y = -0.829038, z = 0}},
            {Position = {x = 839.015, y = 1543.67, z = 51.7809}, Direction = {x = -0.99863, y = -0.0523357, z = 0}},
            {Position = {x = 821.187, y = 1497.66, z = 52.5126}, Direction = {x = 0.0348993, y = -0.999391, z = 0}}
        }
    };
end

SCAAMBRCrateProperties.RandomContent = {};

-- DEPRECATED CODE
-- SCAAMBRCrateProperties.RandomContent = {
--     ['Phase1'] = {
--         {'AKM', '762x30', 'Rags', 'Machete', 'SCAAMStimPack'},
--         {'R90', '57x50', 'Cleaver', 'SCAAMStimPack'},
--         {'KrissV', '10mm_magazine', 'GrenadePickup', 'Bandage', 'SCAAMArmor'},
--         {'AA12', '12Gaugex8_Slug_AA12', 'AdvancedBandage', 'PoliceBaton'},
--         {'CX4Storm', 'acp_45_magazine', 'acp_45_magazine', 'acp_45_magazine', 'AntibioticBandage', 'GrenadeMolotovPickup'},
--         {'M16', '556x45_magazine', 'GrenadePickup', 'SCAAMStimPack', 'SCAAMArmor'},
--         {'AUMP45', 'acp_45_ext_magazine', 'Rags', 'Machete', 'SCAAMArmor'},
--         {'AK74U', '545x30', '545x30', 'GrenadeSmokeGreenPickup', 'Rags', 'Hatchet'},
--         {'ACAW', '762x5', '762x5', 'PipebombPickup', 'SCAAMStimPack'},
--     },
--     ['Phase2'] = {
--         {'AKM', '762x30', 'Rags', 'Machete', 'SCAAMStimPack'},
--         {'R90', '57x50', 'Cleaver', 'SCAAMStimPack'},
--         {'KrissV', '10mm_magazine', 'GrenadePickup', 'Bandage', 'SCAAMArmor'},
--         {'AA12', '12Gaugex8_Slug_AA12', 'AdvancedBandage', 'PoliceBaton'},
--         {'CX4Storm', 'acp_45_magazine', 'acp_45_magazine', 'acp_45_magazine', 'AntibioticBandage', 'GrenadeMolotovPickup'},
--         {'M16', '556x45_magazine', 'GrenadePickup', 'SCAAMStimPack', 'SCAAMArmor'},
--         {'AUMP45', 'acp_45_ext_magazine', 'Rags', 'Machete', 'SCAAMArmor'},
--         {'AK74U', '545x30', '545x30', 'GrenadeSmokeGreenPickup', 'Rags', 'Hatchet'},
--         {'ACAW', '762x5', '762x5', 'PipebombPickup', 'SCAAMStimPack'},
--     },
--     ['Phase3'] = {
--         {'AKM', '762x30', 'Rags', 'Machete', 'SCAAMStimPack'},
--         {'R90', '57x50', 'Cleaver', 'SCAAMStimPack'},
--         {'KrissV', '10mm_magazine', 'GrenadePickup', 'Bandage', 'SCAAMArmor'},
--         {'AA12', '12Gaugex8_Slug_AA12', 'AdvancedBandage', 'PoliceBaton'},
--         {'CX4Storm', 'acp_45_magazine', 'acp_45_magazine', 'acp_45_magazine', 'AntibioticBandage', 'GrenadeMolotovPickup'},
--         {'M16', '556x45_magazine', 'GrenadePickup', 'SCAAMStimPack', 'SCAAMArmor'},
--         {'AUMP45', 'acp_45_ext_magazine', 'Rags', 'Machete', 'SCAAMArmor'},
--         {'AK74U', '545x30', '545x30', 'GrenadeSmokeGreenPickup', 'Rags', 'Hatchet'},
--         {'ACAW', '762x5', '762x5', 'PipebombPickup', 'SCAAMStimPack'},
--     },
--     ['Phase4'] = {
--         {'AKM', '762x30', 'Rags', 'Machete', 'SCAAMStimPack'},
--         {'R90', '57x50', 'Cleaver', 'SCAAMStimPack'},
--         {'KrissV', '10mm_magazine', 'GrenadePickup', 'Bandage', 'SCAAMArmor'},
--         {'AA12', '12Gaugex8_Slug_AA12', 'AdvancedBandage', 'PoliceBaton'},
--         {'CX4Storm', 'acp_45_magazine', 'acp_45_magazine', 'acp_45_magazine', 'AntibioticBandage', 'GrenadeMolotovPickup'},
--         {'M16', '556x45_magazine', 'GrenadePickup', 'SCAAMStimPack', 'SCAAMArmor'},
--         {'AUMP45', 'acp_45_ext_magazine', 'Rags', 'Machete', 'SCAAMArmor'},
--         {'AK74U', '545x30', '545x30', 'GrenadeSmokeGreenPickup', 'Rags', 'Hatchet'},
--         {'ACAW', '762x5', '762x5', 'PipebombPickup', 'SCAAMStimPack'},
--     },
--     ['Phase5'] = {
--         {'AKM', '762x30', 'Rags', 'Machete', 'SCAAMStimPack'},
--         {'R90', '57x50', 'Cleaver', 'SCAAMStimPack'},
--         {'KrissV', '10mm_magazine', 'GrenadePickup', 'Bandage', 'SCAAMArmor'},
--         {'AA12', '12Gaugex8_Slug_AA12', 'AdvancedBandage', 'PoliceBaton'},
--         {'CX4Storm', 'acp_45_magazine', 'acp_45_magazine', 'acp_45_magazine', 'AntibioticBandage', 'GrenadeMolotovPickup'},
--         {'M16', '556x45_magazine', 'GrenadePickup', 'SCAAMStimPack', 'SCAAMArmor'},
--         {'AUMP45', 'acp_45_ext_magazine', 'Rags', 'Machete', 'SCAAMArmor'},
--         {'AK74U', '545x30', '545x30', 'GrenadeSmokeGreenPickup', 'Rags', 'Hatchet'},
--         {'ACAW', '762x5', '762x5', 'PipebombPickup', 'SCAAMStimPack'},
--     },
--     ['Phase6'] = {
--         {'AKM', '762x30', 'Rags', 'Machete', 'SCAAMStimPack'},
--         {'R90', '57x50', 'Cleaver', 'SCAAMStimPack'},
--         {'KrissV', '10mm_magazine', 'GrenadePickup', 'Bandage', 'SCAAMArmor'},
--         {'AA12', '12Gaugex8_Slug_AA12', 'AdvancedBandage', 'PoliceBaton'},
--         {'CX4Storm', 'acp_45_magazine', 'acp_45_magazine', 'acp_45_magazine', 'AntibioticBandage', 'GrenadeMolotovPickup'},
--         {'M16', '556x45_magazine', 'GrenadePickup', 'SCAAMStimPack', 'SCAAMArmor'},
--         {'AUMP45', 'acp_45_ext_magazine', 'Rags', 'Machete', 'SCAAMArmor'},
--         {'AK74U', '545x30', '545x30', 'GrenadeSmokeGreenPickup', 'Rags', 'Hatchet'},
--         {'ACAW', '762x5', '762x5', 'PipebombPickup', 'SCAAMStimPack'},
--     }
-- };

-- Low tier on ground items properties, including position, direction and extra options per item (like a mag beside a gun)

-- Editor or server specific actions
if (System.IsEditor()) then
    SCAAMBRGroundItemsProperties = {
        Positions = {
            {Position = {x = 358.45, y = 607.983, z = 17}, Direction = {x = 0.987521, y = 0.157486, z = 0}},
            {Position = {x = 364.557, y = 613.226, z = 17}, Direction = {x = 0.697612, y = 0.716476, z = 0}},
            {Position = {x = 363.661, y = 623.377, z = 17}, Direction = {x = -0.245743, y = 0.969335, z = 0}},
            {Position = {x = 352.807, y = 637.037, z = 17}, Direction = {x = -0.806817, y = 0.590801, z = 0}},
            {Position = {x = 346.919, y = 622.456, z = 17.4195}, Direction = {x = -0.980533, y = 0.196354, z = 0}},
            {Position = {x = 338.094, y = 624.647, z = 17}, Direction = {x = -0.999993, y = -0.00374615, z = 0}},
            {Position = {x = 327.988, y = 616.78, z = 17}, Direction = {x = -0.883709, y = -0.468037, z = 0}},
            {Position = {x = 331.602, y = 604.959, z = 17}, Direction = {x = 0.519719, y = -0.854337, z = 0}},
            {Position = {x = 344.675, y = 596.572, z = 17}, Direction = {x = 0.411203, y = -0.911544, z = 0}},
            {Position = {x = 354.521, y = 585.366, z = 17}, Direction = {x = 0.683612, y = -0.729846, z = 0}},
            {Position = {x = 367.08, y = 588.551, z = 17}, Direction = {x = 0.953889, y = 0.30016, z = 0}},
            {Position = {x = 383.278, y = 602.216, z = 17}, Direction = {x = 0.711905, y = 0.702276, z = 0}},
            {Position = {x = 390.964, y = 614.937, z = 17}, Direction = {x = 0.148191, y = 0.988959, z = 0}},
            {Position = {x = 390.182, y = 622.394, z = 17}, Direction = {x = -0.052623, y = 0.998614, z = 0}},
            {Position = {x = 381.675, y = 628.448, z = 17}, Direction = {x = -0.785939, y = 0.618303, z = 0}},
            {Position = {x = 380.341, y = 636.107, z = 17}, Direction = {x = -0.105194, y = 0.994452, z = 0}},
            {Position = {x = 361.137, y = 642.527, z = 17.9512}, Direction = {x = -0.580548, y = 0.814226, z = 0}},
            {Position = {x = 357.505, y = 639.559, z = 18.09}, Direction = {x = -0.683749, y = -0.729717, z = 0}},
            {Position = {x = 350.175, y = 634.277, z = 18.14}, Direction = {x = 0.958381, y = 0.285493, z = 0}}
        }
    };
else
    SCAAMBRGroundItemsProperties = {
        Positions = {
            {Position = {x = 827.054, y = 1470.31, z = 52.3078}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1782.67, y = 799.419, z = 52.6861}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 345.264, y = 844.653, z = 55.2259}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 328.269, y = 954.031, z = 58.4103}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1194.69, y = 1328.51, z = 47.3529}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 874.447, y = 274.028, z = 50.6798}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1825.48, y = 656.925, z = 52.5909}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1793.53, y = 629.515, z = 52.6815}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 895.981, y = 1468.73, z = 53.4266}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 949.047, y = 268.234, z = 53.2659}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 819.143, y = 252.991, z = 51.1081}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 828.878, y = 1568.9, z = 52.7994}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1199.99, y = 450.813, z = 48.6404}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 541.411, y = 1569.9, z = 52.6012}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 620.441, y = 1091.7, z = 82.0994}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1779.83, y = 815.752, z = 52.7344}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 303.367, y = 923.042, z = 54.2974}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 985.9, y = 1510.25, z = 53.1349}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 370.12, y = 871.586, z = 60.6586}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1227.89, y = 571.905, z = 48.3623}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1232.94, y = 471.379, z = 47.6897}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 339.202, y = 896.632, z = 53.5787}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1785.84, y = 784.057, z = 52.2699}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1171.46, y = 526.696, z = 46.7452}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 290.998, y = 920.311, z = 52.6875}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1824.02, y = 616.756, z = 52.2723}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1814.31, y = 706.97, z = 51.65}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 929.386, y = 278.04, z = 52.1411}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1781.51, y = 801.406, z = 53.2736}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1599.22, y = 1053.79, z = 57.5001}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1109.58, y = 475.207, z = 52.3739}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1677.97, y = 1534.4, z = 53.2954}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 588.555, y = 759.489, z = 93.8751}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1813.57, y = 683.579, z = 53.5628}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 731.712, y = 944.51, z = 117.279}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 758.91, y = 1626.25, z = 52.4675}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1210.03, y = 564.285, z = 48.0119}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 862.796, y = 1492.3, z = 55.6293}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1550.56, y = 1341.96, z = 98.1679}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 350.972, y = 443.446, z = 46.4068}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1434.01, y = 1074.73, z = 60.0541}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 871.273, y = 269.727, z = 51.0744}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1150.67, y = 549.381, z = 58.8292}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 903.072, y = 411.561, z = 37.1818}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1154.31, y = 525.952, z = 49.1092}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1146.44, y = 1007.41, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1435.62, y = 1073.97, z = 60.5196}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 330.841, y = 957.16, z = 58.5183}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1144.64, y = 484.127, z = 52.4364}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 835.429, y = 1543.18, z = 52.8773}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 870.355, y = 1487.69, z = 52.3251}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1512.99, y = 1055.56, z = 59.346}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1705.58, y = 1026.08, z = 52.489}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 360.952, y = 505.601, z = 50.8188}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1392.58, y = 530.277, z = 37.285}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1577.24, y = 1259.09, z = 58.56}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1791.23, y = 716.953, z = 52.8391}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 889.488, y = 1590.42, z = 52.593}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 340.656, y = 855.468, z = 54.405}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 578.732, y = 1003.6, z = 81.6651}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 682.161, y = 1059.92, z = 75.384}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1143.39, y = 1482.39, z = 52.9193}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 893.372, y = 1516.54, z = 52.5956}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 344.897, y = 892.174, z = 53.5787}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 862.519, y = 1444.99, z = 58.9368}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 934.99, y = 659.756, z = 34.3261}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 826.998, y = 1539.26, z = 52.7839}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 902.433, y = 1791.06, z = 52.3078}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1403.56, y = 954.031, z = 75.7132}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 766.152, y = 1610.07, z = 52.7099}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1758.01, y = 1537.31, z = 50.9659}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1190.93, y = 1676.68, z = 52.577}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1199.18, y = 455.783, z = 53.392}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 352.781, y = 870.779, z = 55.958}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1212.32, y = 1322.46, z = 55.4051}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 760.543, y = 307.271, z = 51.7914}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 557.203, y = 1692.26, z = 40.3177}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1209.08, y = 528.766, z = 47.9503}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1396.18, y = 960.87, z = 75.7132}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 590.156, y = 763.091, z = 93.8751}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 826.327, y = 1571.45, z = 55.7801}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1221.3, y = 540.886, z = 51.3277}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1601.42, y = 375.596, z = 47.8559}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1835.09, y = 677.989, z = 52.5909}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 696.645, y = 1246.84, z = 57.2574}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1135.37, y = 966.458, z = 103.413}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1209.23, y = 572.038, z = 47.5578}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 367.383, y = 863.168, z = 59.9157}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 766.752, y = 1606.96, z = 52.8479}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1122.99, y = 563.609, z = 52.2385}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 336.691, y = 959.031, z = 55.3184}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 828.902, y = 1549.39, z = 52.4481}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 481.555, y = 905.419, z = 67.7987}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 931.924, y = 672.016, z = 36.6372}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1689.89, y = 1765.08, z = 27.9128}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 912.803, y = 1564.97, z = 56.9604}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 555.195, y = 1582.59, z = 52.2125}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1177.2, y = 588.655, z = 47.4433}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 298.988, y = 1517.5, z = 51.9508}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 319.763, y = 441.686, z = 46.071}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 568.221, y = 1008.43, z = 83.2307}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 280.074, y = 1520.08, z = 51.3367}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 834.461, y = 1561.45, z = 53.2956}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 901.495, y = 1554.37, z = 53.013}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1822.93, y = 598.484, z = 52.2723}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 565.753, y = 717.941, z = 97.2564}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 361.623, y = 866.145, z = 56.1292}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1747.22, y = 923.905, z = 54.5578}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1227.14, y = 464.013, z = 47.8317}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1036.89, y = 1227.28, z = 50.0373}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 841.014, y = 1591.47, z = 51.9117}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1760.96, y = 896.341, z = 53.9155}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1659.47, y = 450.516, z = 52.375}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1134.39, y = 1471.76, z = 48.7207}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1239.98, y = 1628.7, z = 53.1991}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 914.413, y = 1566.68, z = 57.5403}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 364.076, y = 863.149, z = 60.6958}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1203.56, y = 512.325, z = 47.9989}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1204.04, y = 563.511, z = 47.7962}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 344.684, y = 1185.95, z = 53.7217}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1437.84, y = 1072.95, z = 59.9333}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 887.017, y = 1515.04, z = 53.1913}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1609.76, y = 376.869, z = 48.2503}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1816.16, y = 633.212, z = 51.7}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1743.47, y = 895.894, z = 54.1148}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1204.95, y = 486.211, z = 47.1349}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 814.939, y = 1472.33, z = 52.5062}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 877.605, y = 1593.76, z = 52.3972}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1226.02, y = 540.943, z = 52.1758}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 334.174, y = 883.836, z = 53.5787}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1158.6, y = 600.283, z = 48.2446}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1292, y = 1786.12, z = 32.1735}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1199.51, y = 458.336, z = 49.0585}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 735.153, y = 935.51, z = 116.426}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 329.931, y = 1204.7, z = 53.294}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1827.32, y = 681.698, z = 52.8062}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 696.653, y = 1294.89, z = 55.8625}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1406.23, y = 954.253, z = 76.117}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1190.42, y = 469.437, z = 48.9259}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 801.658, y = 1574.22, z = 52.0485}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 960.072, y = 1785.31, z = 52.8608}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 933.1, y = 1527.64, z = 54.2658}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 813.9, y = 1419.76, z = 52.3431}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 818.231, y = 1493.57, z = 53.579}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1535.9, y = 447.12, z = 42.3456}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1193.41, y = 460.8, z = 53.425}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1037.51, y = 1180.17, z = 50.734}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 300.202, y = 453.854, z = 46.7953}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 864.25, y = 1403.44, z = 52.9758}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1816.57, y = 1066.58, z = 48.3904}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 823.442, y = 1516.42, z = 52.971}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 963.202, y = 1796.75, z = 52.4539}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1215.74, y = 1323.58, z = 55.0443}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 696.76, y = 1251.15, z = 57.1983}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 292.614, y = 920.731, z = 53.1977}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 880.521, y = 1498.8, z = 52.5372}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 312.206, y = 1500.14, z = 51.265}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1825.99, y = 693.519, z = 52.4453}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1174.69, y = 947.409, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 831.838, y = 1538.3, z = 52.4453}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 783.801, y = 1400.7, z = 51.8341}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 568.172, y = 1593.35, z = 51.9437}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 301.184, y = 1525.1, z = 52.6241}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1181.42, y = 530.008, z = 47.6949}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1227.09, y = 575.967, z = 47.0127}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1834.18, y = 682.924, z = 52.8312}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 349.241, y = 737.52, z = 56.3794}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1194.93, y = 503.867, z = 47.4337}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1195.7, y = 461.547, z = 48.8}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 869.886, y = 1444.06, z = 56.1465}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1407.79, y = 1751.4, z = 33.8726}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1016.09, y = 1251.3, z = 49.9279}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1051.46, y = 1697.92, z = 50.6801}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 725.416, y = 936.664, z = 116.435}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 899.61, y = 411.912, z = 36.6372}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 714.253, y = 924.589, z = 115.535}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 867.636, y = 1402.13, z = 52.8789}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 367.31, y = 810.226, z = 57.5654}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 683.929, y = 1622.67, z = 50.9178}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1039.58, y = 1675.5, z = 52.5772}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1189.62, y = 1654.03, z = 53.6874}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 860.104, y = 273.077, z = 50.7427}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 314.737, y = 439.586, z = 45.3903}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1014.72, y = 1614.28, z = 52.9399}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1813.16, y = 662.579, z = 52.4436}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1830.57, y = 660.073, z = 52.8085}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 957.506, y = 1789.78, z = 53.5716}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1730.51, y = 1665.07, z = 42.9866}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1461.98, y = 1212.97, z = 59.838}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1836.18, y = 698.579, z = 52.5917}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1057.63, y = 1692.37, z = 51.4731}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1221.67, y = 551.716, z = 51.9708}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1598.04, y = 372.449, z = 47.8154}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 950.469, y = 1838.91, z = 57.3277}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 296.027, y = 449.349, z = 46.8857}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 333.315, y = 955.332, z = 54.8433}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1665.92, y = 1048.79, z = 53.0699}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 367.227, y = 868.604, z = 60.6619}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 339.405, y = 1021.09, z = 60.6348}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 570.46, y = 728.893, z = 97.2947}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1614.79, y = 386.423, z = 51.956}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1536.23, y = 1681.22, z = 52.9707}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1212.59, y = 1460.64, z = 54.3144}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 654.799, y = 1136.2, z = 76.4763}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1588.51, y = 1048.06, z = 58.8432}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1100.42, y = 243.953, z = 53.2289}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1337.3, y = 425.756, z = 51.3696}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1413.78, y = 952.59, z = 76.1105}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1817.62, y = 697.582, z = 52.8094}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1169.13, y = 594.493, z = 48.3416}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1182.76, y = 459.751, z = 49.4243}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 869.756, y = 1444.88, z = 53.2256}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1223.94, y = 551.109, z = 52.2516}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1219.1, y = 543.204, z = 48.4341}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 812.269, y = 246.18, z = 50.7992}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1136.95, y = 1229.34, z = 59.0449}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1189.24, y = 463.681, z = 49.5153}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 300.138, y = 1532.85, z = 52.3457}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1015.83, y = 1616.54, z = 52.2989}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 568.185, y = 999.298, z = 81.4263}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 853.453, y = 1162.14, z = 42.551}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 532.038, y = 1386.83, z = 82.2522}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1402.46, y = 957.27, z = 76.6028}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 831.41, y = 1567.34, z = 55.7801}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 289.179, y = 1486.21, z = 51.5138}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 967.482, y = 1787.96, z = 52.4539}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1592.68, y = 1048.26, z = 58.5054}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1170.09, y = 1686.75, z = 52.423}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 696.585, y = 1249.35, z = 57.7475}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 834.346, y = 1570.42, z = 56.2432}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1809.96, y = 629.025, z = 52.324}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 861.521, y = 1445.29, z = 52.7286}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 869.113, y = 1495.72, z = 52.442}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 278.131, y = 1373.36, z = 51.8386}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 328.171, y = 960.092, z = 58.6429}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 414.503, y = 889.732, z = 65.2027}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 825.617, y = 1538.84, z = 51.7809}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1026.62, y = 375.354, z = 53.0968}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 300.265, y = 1457.3, z = 52.8146}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 828.867, y = 1574.77, z = 55.7801}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 344.935, y = 449.693, z = 45.8779}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1464.23, y = 1213.97, z = 59.1607}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1035.79, y = 1178.48, z = 51.0987}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1746.57, y = 928.474, z = 54.483}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1539.87, y = 447.27, z = 42.7583}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 941.618, y = 299.528, z = 51.705}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 562.733, y = 1593.58, z = 52.1025}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 862.89, y = 1487.68, z = 55.6205}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 827.396, y = 1566.59, z = 53.3687}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 535.764, y = 1377.19, z = 83.1143}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1741.45, y = 1669.76, z = 45.8351}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1133.22, y = 966.119, z = 103.413}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 414.482, y = 882.941, z = 62.1149}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 925.45, y = 1522.54, z = 57.0527}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 826.306, y = 1574.94, z = 52.9261}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1831.39, y = 678.328, z = 52.1557}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1678.97, y = 1765.56, z = 26.9284}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1191.65, y = 471.459, z = 49.5221}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 560.114, y = 415.442, z = 52.8779}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1822.9, y = 608.125, z = 52.2723}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 322.657, y = 433.303, z = 46.519}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 622.067, y = 1616.33, z = 48.5054}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1814.02, y = 713.576, z = 53.1802}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 363.218, y = 860.553, z = 56.1587}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 369.223, y = 870.39, z = 57.1879}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1737.84, y = 1670.14, z = 46.1798}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 892.723, y = 1558.98, z = 53.1309}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 427.232, y = 855.525, z = 61.5622}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 595.063, y = 749.778, z = 93.7435}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1199.75, y = 509.009, z = 47.8406}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 724.668, y = 929.203, z = 116.435}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 865.923, y = 1528.92, z = 51.4539}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1748.43, y = 919.341, z = 54.7729}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1143.68, y = 482.671, z = 52.4364}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 944.515, y = 292.474, z = 52.5699}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 370.8, y = 861.724, z = 60.6255}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1756.87, y = 1536.54, z = 51.6533}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1032.66, y = 1237.96, z = 48.992}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.95, y = 560.746, z = 47.393}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1829.16, y = 656.258, z = 52.1557}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 535.181, y = 857.46, z = 81.7493}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1777.23, y = 878.342, z = 53.175}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1043.17, y = 1674.99, z = 51.9722}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 278.069, y = 1377.47, z = 51.6594}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1130.45, y = 1235.64, z = 59.306}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 283.879, y = 1515.38, z = 51.3367}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1121, y = 558.332, z = 51.6688}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1835.12, y = 660.762, z = 51.9347}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 628.212, y = 761.623, z = 98.0335}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 949.216, y = 291.936, z = 51.705}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 898.829, y = 1787.53, z = 55.9613}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 958.771, y = 1798.61, z = 53.3699}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1826.11, y = 690.126, z = 52.6363}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1671.11, y = 1540.24, z = 53.652}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1817.24, y = 1066.24, z = 50.1301}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 809.303, y = 258.15, z = 50.8287}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 415.204, y = 892.918, z = 66.1274}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1043.96, y = 1601.81, z = 53.005}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1706.8, y = 1023.51, z = 52.8195}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 811.132, y = 243.755, z = 55.3774}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 302.97, y = 1528.75, z = 52.5762}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 962.771, y = 1786.27, z = 52.9119}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1023.12, y = 1244.44, z = 49.2724}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 939.788, y = 288.889, z = 52.0786}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 875.453, y = 269.638, z = 51.3551}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 862.351, y = 271.989, z = 50.4186}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1184.36, y = 522.023, z = 47.1117}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 744.121, y = 1098.08, z = 61.6801}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1605.63, y = 389.827, z = 52.4056}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 946.826, y = 286.575, z = 51.7288}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1146.09, y = 553.633, z = 49.3766}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1094.14, y = 561.511, z = 52.3877}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 790.472, y = 1505.53, z = 52.4959}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1611, y = 387.413, z = 52.8328}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 549.497, y = 1586.51, z = 52.4579}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1224.13, y = 538.89, z = 51.3277}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 903.345, y = 1797.31, z = 52.7805}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 906.409, y = 1786.66, z = 56.7407}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 505.358, y = 961.695, z = 75.2497}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 606.368, y = 258.241, z = 51.45}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1092.52, y = 979.487, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1177.57, y = 590.51, z = 48.0804}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 553.551, y = 1580.92, z = 52.8203}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1008.75, y = 1629.58, z = 63.8241}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1831.81, y = 697.365, z = 52.8262}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 892.646, y = 1561.11, z = 52.5136}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 844.92, y = 1399.32, z = 52.2318}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1066.32, y = 1658.37, z = 52.1171}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1411.8, y = 1754.17, z = 34.1142}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1068.13, y = 435.435, z = 51.7638}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 983.236, y = 1509.38, z = 53.5761}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 334.091, y = 960.503, z = 59.5611}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1679.5, y = 1599.6, z = 51.3}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 606.683, y = 250.872, z = 51.45}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1112.16, y = 572.097, z = 52.2326}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1790.24, y = 714.045, z = 52.1756}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1605.76, y = 390.052, z = 48.0887}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1066.64, y = 434.564, z = 52.2226}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 917.644, y = 1790.3, z = 52.0013}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 659.539, y = 746.846, z = 98.0405}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 785.46, y = 1631, z = 52.5473}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1111.58, y = 647.776, z = 53.4031}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1188.94, y = 457.179, z = 54.0978}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 364.539, y = 863.423, z = 56.6205}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 302.846, y = 1518.5, z = 51.3367}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1133.14, y = 963.022, z = 103.413}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1223.04, y = 542.8, z = 51.4661}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1793.68, y = 633.784, z = 52.5607}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1198.31, y = 472.082, z = 48.7283}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1830.66, y = 692.653, z = 52.8529}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 890.111, y = 1519.23, z = 52.4819}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 829.009, y = 1469.48, z = 51.6837}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1154.47, y = 546.149, z = 58.8222}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 931.42, y = 658.172, z = 34.2672}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1780.45, y = 788.688, z = 52.799}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1482.64, y = 308.023, z = 47.8205}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1148.23, y = 556.487, z = 48.1266}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 354.488, y = 872.481, z = 56.5902}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1001.02, y = 1625.25, z = 52.2211}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1607.39, y = 380.422, z = 52.16}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 334.298, y = 887.455, z = 54.4376}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 847.477, y = 1410.58, z = 52.4282}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.35, y = 567.992, z = 47.5243}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 902.327, y = 1487.21, z = 52.6778}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1780.62, y = 803.072, z = 52.8261}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 705.518, y = 1268.18, z = 56.2312}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 858.073, y = 1445.69, z = 58.9369}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 505.294, y = 964.171, z = 74.9892}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1189.36, y = 1677.81, z = 52.0569}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1058.54, y = 435.257, z = 52.9334}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1795.77, y = 682.794, z = 52.8846}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1238.02, y = 1430.43, z = 54.2181}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1828.72, y = 641.503, z = 52.1156}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1291.72, y = 1783.95, z = 32.876}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1189.55, y = 1654.01, z = 57.3277}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 290.138, y = 1487.35, z = 51.9881}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1044.77, y = 245.385, z = 52.7488}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 354.578, y = 623.456, z = 53.4115}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1017.74, y = 1258.76, z = 49.5267}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1195.68, y = 1651.18, z = 53.6742}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 339.266, y = 1023.18, z = 60.0229}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1660.08, y = 1316.06, z = 54.7221}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 863.157, y = 1487.39, z = 58.9406}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 567.181, y = 722.199, z = 97.3}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 634.231, y = 815.5, z = 100.533}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 877.016, y = 1492.53, z = 52.3267}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 818.844, y = 1462.71, z = 51.6827}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 644.55, y = 751.141, z = 98.5888}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 674.579, y = 1056.69, z = 76.3727}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 490.276, y = 914.467, z = 69.9186}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 372.567, y = 866.229, z = 56.1292}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 824.943, y = 1560.03, z = 51.7809}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1677.35, y = 1402.96, z = 56.9772}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 961.537, y = 1846.8, z = 53.6237}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 929.794, y = 672.445, z = 36.6937}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 885.901, y = 1431.21, z = 52.4403}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 286.758, y = 1511.84, z = 51.3367}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1057.14, y = 433.841, z = 52.5282}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1537.88, y = 447.167, z = 43.0639}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 946.843, y = 270.525, z = 52.4235}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 595.647, y = 766.759, z = 97.9742}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1066.13, y = 1691.62, z = 50.45}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 946.896, y = 288.923, z = 52.1482}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1469.12, y = 1213.21, z = 59.2613}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 877.033, y = 1135.84, z = 45.8278}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 928.639, y = 273.94, z = 52.1742}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 830.309, y = 1533.1, z = 52.5597}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1692.62, y = 1769.49, z = 26.9284}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1606.85, y = 387.143, z = 52.8328}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 488.911, y = 968.184, z = 76.2689}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 872.228, y = 1492.89, z = 52.3218}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1417.5, y = 1753.71, z = 34.1452}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1260.23, y = 394.331, z = 51.8459}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 635.143, y = 815.594, z = 101.6}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 722.769, y = 930.881, z = 116.598}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1111.55, y = 927.141, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 545.972, y = 1579.62, z = 52.9142}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1829.68, y = 667.212, z = 52.8262}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1771.48, y = 1557.56, z = 50.7693}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 783.438, y = 1630.89, z = 53.0012}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1055.8, y = 1705.27, z = 50.6301}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1064.17, y = 1654.74, z = 52.3198}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1723.93, y = 1539.56, z = 51.3857}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 414.345, y = 892.11, z = 61.5492}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 981.539, y = 1134.67, z = 49.1}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1733.39, y = 1664.32, z = 46.6495}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1459.49, y = 1659.63, z = 57.2327}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 587.893, y = 746.531, z = 97.9741}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 818.907, y = 1558.32, z = 52.6196}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1206.06, y = 1657.82, z = 53.6555}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 487.329, y = 917.47, z = 69.8462}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1094.69, y = 563.966, z = 51.8043}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 595.867, y = 363.049, z = 53.8396}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1199.27, y = 503.743, z = 48.3107}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1738.78, y = 1662.84, z = 45.7303}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 582.818, y = 749.066, z = 97.9742}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 316.595, y = 449.552, z = 45.4674}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1615.24, y = 373.514, z = 51.956}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 979.309, y = 1298.4, z = 50.953}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 325.583, y = 957.917, z = 54.7361}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 816.277, y = 1559.71, z = 52.2918}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 905.078, y = 410.051, z = 37.1734}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 765.356, y = 1600.16, z = 52.616}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 873.927, y = 269.401, z = 50.7452}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1613.13, y = 379.912, z = 52.9954}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 355.901, y = 873.768, z = 56.1524}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1826.33, y = 696.282, z = 52.5853}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1812.52, y = 656.786, z = 52.6088}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1787.8, y = 584.029, z = 52.9264}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1202.26, y = 317.823, z = 52}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 867.84, y = 1444.62, z = 56.2877}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 951.18, y = 293.501, z = 54.9157}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1687.6, y = 1770.81, z = 27.0676}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 994.151, y = 256.228, z = 53.1804}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1461, y = 1659.22, z = 56.8034}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1225.77, y = 548.626, z = 52.235}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1191.2, y = 465.708, z = 48.6013}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 928.602, y = 1361.54, z = 49.6027}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 834.989, y = 1570.85, z = 53.1183}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1661.66, y = 451.967, z = 51.9194}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1787.59, y = 1554.07, z = 49.9338}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1785.51, y = 783.83, z = 53.2576}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 923.095, y = 648.82, z = 34.0771}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 297.79, y = 1517.72, z = 51.9508}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 863.06, y = 1643.88, z = 51.694}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1596.01, y = 381.295, z = 48.0245}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1781.96, y = 819.246, z = 52.8522}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1094.17, y = 563.207, z = 52.8688}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 881.013, y = 1134.45, z = 45.7568}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1127.76, y = 557.784, z = 52.5743}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1195.67, y = 472.619, z = 49.7637}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 314.667, y = 1298.09, z = 52.4226}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 696.772, y = 1297.6, z = 55.1765}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1065.02, y = 1656.29, z = 52.7471}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1191.44, y = 1653.11, z = 54.1655}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1573.37, y = 434.881, z = 45.3272}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1830.77, y = 698.339, z = 52.802}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1035.4, y = 1178.76, z = 50.077}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 772.939, y = 1361.43, z = 52.4743}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 290.222, y = 920.759, z = 53.7278}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 883.114, y = 1498.35, z = 52.9044}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 883.114, y = 1576.68, z = 52.6452}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 890.094, y = 1509.78, z = 53.3299}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1100.31, y = 532.202, z = 52.3589}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1202.25, y = 456.87, z = 53.6706}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 303.686, y = 921.31, z = 53.8407}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 834.576, y = 1554.95, z = 52.8693}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 300.483, y = 440.267, z = 46.7953}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1840.05, y = 1587.76, z = 46.7731}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.11, y = 571.162, z = 47.822}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1207.93, y = 491.368, z = 49.014}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 558.516, y = 1588.68, z = 52.0851}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 593.524, y = 759.199, z = 97.9742}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 767.42, y = 1597.67, z = 52.9138}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 515.401, y = 863.107, z = 77.3102}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 578.12, y = 369.474, z = 53.4422}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 930.52, y = 1529.34, z = 58.5989}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1008.6, y = 1265.09, z = 49.6297}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1035.7, y = 1234.94, z = 49.4357}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 296.081, y = 1519.71, z = 51.9508}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1397.32, y = 964.988, z = 75.7132}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1473.17, y = 1213.07, z = 59.5684}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1743.11, y = 891.763, z = 54.2212}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 754.884, y = 1626.93, z = 52.3383}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1152.74, y = 547.747, z = 57.9899}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 697.564, y = 1285.61, z = 54.6218}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 289.72, y = 1530.67, z = 51.763}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 804.52, y = 286.647, z = 51.4004}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 997.018, y = 253.231, z = 53.2947}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 581.075, y = 1000.03, z = 81.559}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1348.25, y = 430.55, z = 50.4089}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 580.651, y = 994.81, z = 81.7273}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1275.92, y = 414.176, z = 52.1277}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1785.92, y = 580.728, z = 52.386}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1460.71, y = 1212.11, z = 59.482}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 875.939, y = 273.303, z = 51.1704}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1100.24, y = 936.931, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 806.015, y = 1586.38, z = 52.3068}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 767.299, y = 1592.03, z = 52.0222}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 814.049, y = 253.424, z = 54.4527}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 922.848, y = 680.128, z = 36.7743}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 414.395, y = 888.594, z = 65.8701}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1196.89, y = 457.049, z = 53.221}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1043.49, y = 1600.06, z = 53.5529}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 900.831, y = 402.775, z = 36.6937}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1830.15, y = 679.667, z = 52.8062}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 352.847, y = 439.611, z = 45.7811}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1829.31, y = 677.248, z = 52.0828}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1206.15, y = 1659.36, z = 52.9055}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1211.48, y = 1464.05, z = 54.6899}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 816.202, y = 1465.85, z = 52.143}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 534.282, y = 1381.5, z = 82.846}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 965.993, y = 1790.12, z = 53.1846}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 797.958, y = 1444.28, z = 52.5364}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 828.756, y = 1555.22, z = 52.8693}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1816.81, y = 709.605, z = 52.8082}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 328.545, y = 963.693, z = 54.7542}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 369.691, y = 1510.92, z = 51.7975}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1193, y = 454.306, z = 49.4529}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 904.156, y = 1785.61, z = 56.8726}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1677.72, y = 1397.85, z = 55.2989}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1795.29, y = 684.604, z = 52.5704}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1186.79, y = 1655.5, z = 57.3277}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1812.29, y = 674.55, z = 52.5535}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 612.191, y = 722.709, z = 98.1283}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 645.253, y = 714.578, z = 98.2642}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1183.46, y = 1645.9, z = 54.5753}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 810.249, y = 254.731, z = 55.3658}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 992.484, y = 1622.19, z = 52.302}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1046.52, y = 245.267, z = 53.2022}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 292.075, y = 1525.51, z = 51.9508}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1200.19, y = 563.656, z = 47.7562}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 853.603, y = 1641.32, z = 51.6963}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1170.36, y = 990.128, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1684.94, y = 1769.55, z = 27.4342}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 597.447, y = 361.305, z = 54.4236}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 731.284, y = 929.596, z = 116.932}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 367.67, y = 872.588, z = 60.4204}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1202.61, y = 1651.16, z = 54.5042}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 826.355, y = 1532.76, z = 52.4259}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 507.577, y = 1031.97, z = 88.8273}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 734.226, y = 1099.99, z = 63.0305}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1631.69, y = 1626.02, z = 54.0267}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 544.432, y = 1578, z = 52.4051}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 940.012, y = 286.314, z = 52.7065}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 845.9, y = 1514.47, z = 52.4773}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1188.67, y = 1652.42, z = 57.4607}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 584.033, y = 994.834, z = 82.8943}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 626.865, y = 763.991, z = 98.6108}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 833.606, y = 1527.09, z = 52.5887}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 583.001, y = 758.945, z = 98.4072}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 764.854, y = 1594.58, z = 52.6495}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 614.622, y = 774.305, z = 99.6299}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 884.613, y = 1516.99, z = 53.1913}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 352.941, y = 626.548, z = 54.0275}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1510.27, y = 1235.22, z = 59.2451}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1011.87, y = 1257.84, z = 49.9067}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 931.251, y = 1364.52, z = 49.2716}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 800.105, y = 1550.5, z = 52.2039}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 912.664, y = 1561.42, z = 56.9553}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1828.55, y = 637.75, z = 52.1156}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 832.904, y = 1570.77, z = 53.1183}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 339.333, y = 1018.85, z = 60.2}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 349.077, y = 456.137, z = 45.7811}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 954.221, y = 1838.68, z = 57.4607}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1816.41, y = 714.197, z = 52.5849}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1099.48, y = 992.611, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 862.337, y = 1545.75, z = 51.9312}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1163.94, y = 555.717, z = 47.6114}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 505.305, y = 959.973, z = 74.5659}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 935.121, y = 292.679, z = 51.705}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 839.254, y = 1532.57, z = 52.2916}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 328.689, y = 963.621, z = 58.4108}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 908.651, y = 1565.43, z = 54.0333}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1138.74, y = 468.803, z = 51.5588}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 882.419, y = 271.977, z = 51.5103}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1613.52, y = 388.537, z = 47.7934}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 371.327, y = 1510.99, z = 52.2517}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 300.719, y = 437.348, z = 46.7953}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1675.71, y = 1766.26, z = 26.9284}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 824.118, y = 1572.91, z = 55.7801}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 934.988, y = 1528.81, z = 57.9774}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 799.043, y = 1573.76, z = 52.5903}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 824.583, y = 1515.32, z = 52.5245}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 963.63, y = 1787.27, z = 52.4539}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1782.89, y = 1557.76, z = 50.5709}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 759.401, y = 1600.07, z = 53.1036}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1018.27, y = 1627.93, z = 52.876}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1200.51, y = 506.699, z = 48.0535}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1217, y = 1330.23, z = 55.2986}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 541.564, y = 1569.27, z = 53.6903}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1202.46, y = 1579.23, z = 78.787}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 864.356, y = 1440.12, z = 55.6256}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 930.332, y = 1521.13, z = 53.3992}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 638.29, y = 708.302, z = 97.15}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 911.105, y = 419.093, z = 35.72}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 824.965, y = 1566.95, z = 55.7801}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1118.58, y = 562.797, z = 52.7411}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 752.365, y = 1095.94, z = 60.9983}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1511.71, y = 1054.38, z = 58.7811}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 296.119, y = 437.735, z = 46.8883}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 872.396, y = 275.787, z = 51.2344}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1405.14, y = 958.352, z = 75.5204}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 873.393, y = 1593.71, z = 52.2281}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 421.116, y = 892.912, z = 62.438}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1195.17, y = 459.021, z = 54.1293}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1234.01, y = 515.142, z = 47.6286}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1070.31, y = 1533.08, z = 56.6836}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1402, y = 1757.91, z = 33.1788}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 863.635, y = 1498.85, z = 51.7217}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 340.301, y = 883.889, z = 53.5777}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1816.4, y = 675.694, z = 52.67}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 825.748, y = 1566.46, z = 52.4837}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 900.681, y = 1782.77, z = 53.1724}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 425.578, y = 855.223, z = 61.8849}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1135.92, y = 470.397, z = 51.5588}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 959.657, y = 1344.28, z = 49.0549}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1738.72, y = 1671.97, z = 45.5971}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1294.97, y = 1791.84, z = 32.117}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 717.874, y = 936.859, z = 116.646}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1211.47, y = 527.138, z = 48.6666}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1127.15, y = 562.634, z = 52.2468}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 897.469, y = 403.583, z = 37.3962}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 821.622, y = 1470.7, z = 52.2743}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1689.93, y = 1770.07, z = 27.4393}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1727.47, y = 1537.67, z = 51.4372}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 910.629, y = 1785.56, z = 55.9613}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 784.953, y = 1365.29, z = 52.9587}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 365.188, y = 870.194, z = 56.1292}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 921.948, y = 1523.03, z = 53.4287}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 312.845, y = 1300.12, z = 51.9077}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 959.035, y = 1843.03, z = 57.3277}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 430.833, y = 587.24, z = 56.618}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1238.48, y = 1008.24, z = 99.485}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1201.47, y = 1648.83, z = 53.9341}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 486.303, y = 970.511, z = 77.3461}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1146.58, y = 296.147, z = 53.2267}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 329.787, y = 1212.26, z = 52.7365}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1743.19, y = 893.553, z = 54.6896}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 534.428, y = 1386.9, z = 82.8795}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1414.92, y = 954.243, z = 75.2544}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 568.504, y = 725.676, z = 97.3}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1761.42, y = 893.853, z = 53.2358}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1135.2, y = 962.914, z = 103.413}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 824.674, y = 1574.61, z = 52.0087}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 775.231, y = 1357.93, z = 52.3574}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1227.87, y = 548.594, z = 48.5753}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 832.405, y = 1566.88, z = 52.7267}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1816.47, y = 684.821, z = 52.8693}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 817.313, y = 1469.05, z = 52.5462}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1687.43, y = 1765.07, z = 27.7462}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1298.05, y = 1781.61, z = 32.1735}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1192.76, y = 1646.23, z = 57.9951}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 479.813, y = 541.9, z = 55.5167}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1832.57, y = 699.379, z = 52.1028}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 584.946, y = 763.818, z = 98.4072}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1219.95, y = 542.113, z = 48.1709}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 900.125, y = 1786.72, z = 57.0392}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 936.638, y = 288.256, z = 52.6802}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 834.729, y = 1549.3, z = 52.8838}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 328.632, y = 957.333, z = 58.4142}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1828.85, y = 665.162, z = 52.1028}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 579.315, y = 1001.95, z = 81.133}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1687.21, y = 1035.73, z = 52.3391}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1139.73, y = 1484.14, z = 53.049}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 572.734, y = 1050.62, z = 82.4054}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 293.919, y = 1479.98, z = 52.5796}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 915.477, y = 1506.45, z = 53.3081}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 337.797, y = 962.428, z = 55.3475}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 547.064, y = 1575.18, z = 51.9877}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1192.9, y = 468.47, z = 49.1209}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 347.687, y = 1178.3, z = 54.6857}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 652.674, y = 740.241, z = 98.2323}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.68, y = 502.194, z = 47.4327}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1783.42, y = 783.873, z = 52.622}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1411.19, y = 454.293, z = 45.1971}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1201.24, y = 507.567, z = 48.3759}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 591.082, y = 748.822, z = 97.9741}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 330.757, y = 887.884, z = 54.4012}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 696.598, y = 1293.41, z = 55.4499}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1028.89, y = 376.321, z = 52.9493}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 365.945, y = 871.169, z = 59.7827}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 934.726, y = 1525.29, z = 53.3992}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 771.469, y = 1628.38, z = 52.5564}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 539.168, y = 1376.21, z = 82.7147}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 889.941, y = 1507.19, z = 52.5807}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1572.33, y = 436.576, z = 44.7895}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 562.022, y = 413.422, z = 53.2244}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 935.695, y = 300.036, z = 51.705}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1677.97, y = 1603.32, z = 52.1116}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1126.24, y = 583.754, z = 51.3802}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 940.429, y = 300.045, z = 56.3576}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1194.34, y = 451.179, z = 49.0583}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 346.108, y = 1182.25, z = 54.1854}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1111.97, y = 649.399, z = 52.8117}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 434.324, y = 585.162, z = 56.8783}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1454.27, y = 434.094, z = 38.1621}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1173.61, y = 1685.34, z = 51.5483}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1092.77, y = 1518.83, z = 57.3489}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 921.703, y = 1567.22, z = 53.4633}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 319.907, y = 434.536, z = 47.2215}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 839.398, y = 1546.28, z = 52.8784}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 569, y = 999.955, z = 81.3495}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 961.162, y = 1797.44, z = 52.9606}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 864.377, y = 1530.26, z = 52.7832}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 867.278, y = 1519.59, z = 52.5299}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 598.807, y = 360.019, z = 53.9716}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1606.04, y = 386.93, z = 47.7932}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1690.11, y = 1036.1, z = 52.8845}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 827.363, y = 1574.71, z = 56.7227}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1277.02, y = 416.266, z = 51.507}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 759.808, y = 305.788, z = 51.3188}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 834.529, y = 1575.08, z = 51.776}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 642.316, y = 716.471, z = 97.8881}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 304.912, y = 1525.75, z = 51.9755}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 933.093, y = 676.428, z = 37.276}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 681.072, y = 1622.51, z = 49.7946}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.21, y = 414.989, z = 49.699}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 798.648, y = 1589.35, z = 52.0479}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 365.559, y = 867.039, z = 60.4204}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1166.3, y = 592.423, z = 47.9156}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1197.46, y = 323.033, z = 52}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 952.382, y = 1794.71, z = 52.9656}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 946.971, y = 300.348, z = 52.855}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1506.8, y = 1232.93, z = 59.327}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1189.68, y = 456.468, z = 54.2604}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1774.03, y = 830.188, z = 53.3146}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 294.486, y = 1531.05, z = 51.3367}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 534.718, y = 1390.16, z = 82.2522}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 581.768, y = 996.163, z = 82.1518}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 576.583, y = 1049.3, z = 82.56}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1579.05, y = 1260.5, z = 59.8698}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 960.167, y = 1833.88, z = 54.7328}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1840.48, y = 1587.11, z = 48.5128}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1746.2, y = 986.903, z = 53.5187}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 911.062, y = 1792.18, z = 52.3373}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1144.31, y = 551.084, z = 48.6266}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 813.72, y = 1493.48, z = 52.456}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1097.47, y = 244.005, z = 54.1082}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1186.48, y = 1646.07, z = 54.5726}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1748.7, y = 985.302, z = 52.765}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 863.952, y = 1493.01, z = 58.9394}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 365.474, y = 870.342, z = 60.9196}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 329.414, y = 1202, z = 52.9973}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 821.657, y = 1464.82, z = 52.7619}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1814.47, y = 668.712, z = 52.5414}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 860.907, y = 1448.34, z = 53.1177}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 947.609, y = 295.513, z = 52.86}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 922.829, y = 1563.66, z = 54.3471}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 850.723, y = 1637.4, z = 51.65}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 660.003, y = 751.37, z = 97.15}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 393.155, y = 604.039, z = 54.1844}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 916.688, y = 1683.72, z = 52.5595}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 586.751, y = 996.141, z = 82.149}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1665.9, y = 1046.1, z = 52.4347}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1401.21, y = 1752.94, z = 33.4166}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1678.81, y = 1529.03, z = 53.4671}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1794.04, y = 632.187, z = 52.0988}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1136.95, y = 1231.68, z = 57.95}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 826.961, y = 1473.03, z = 51.6837}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 865.34, y = 1440.55, z = 52.3195}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1740.23, y = 1664.79, z = 42.0596}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 762.763, y = 1611.09, z = 52.4803}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 908.72, y = 1789.23, z = 52.3078}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 296.969, y = 451.566, z = 47.051}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 742.184, y = 1618.21, z = 51.2592}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 952.544, y = 1843.21, z = 53.7037}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1031.89, y = 1554.74, z = 54.3742}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 727.88, y = 943.513, z = 117.166}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 294.322, y = 1528.24, z = 51.4759}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 291.657, y = 1526.31, z = 51.9508}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 924.885, y = 1528.89, z = 53.9649}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 982.576, y = 327.538, z = 51.5386}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 900.989, y = 1786.03, z = 52.8994}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 343.858, y = 846.763, z = 54.5927}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1398.48, y = 961.6, z = 76.7832}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1166.58, y = 934.939, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1176.89, y = 976.859, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1192.25, y = 1646.08, z = 53.6742}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 693.358, y = 316.196, z = 53.8113}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 821.896, y = 1518.25, z = 52.3821}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 927.552, y = 1522.84, z = 57.2257}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 422.85, y = 882.766, z = 65.2027}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1176.84, y = 1657.53, z = 53.7311}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 926.164, y = 680.969, z = 36.6937}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 332.445, y = 960.846, z = 59.1496}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 299.269, y = 434.895, z = 47.0129}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 958.102, y = 1832.42, z = 58.235}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 901.374, y = 1796.54, z = 52.3798}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1606.02, y = 1050.15, z = 56.9556}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 767.407, y = 1594.55, z = 52.0222}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1595.53, y = 377.958, z = 47.4633}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 371.404, y = 868.592, z = 57.0276}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1672.07, y = 1765.57, z = 27.9093}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 349.287, y = 741.081, z = 56.6665}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1828.94, y = 646.7, z = 52.1186}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 872.851, y = 1488.98, z = 58.9314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 601.49, y = 1199.85, z = 103.901}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 422.525, y = 888.092, z = 61.5492}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1140.37, y = 921.257, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 949.415, y = 299.248, z = 51.705}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 473.491, y = 892.06, z = 66.4806}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1263.07, y = 397.257, z = 51.2841}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1419.21, y = 1756.17, z = 33.6977}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 373.805, y = 1511.07, z = 51.6821}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 322.643, y = 448.276, z = 45.4396}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1203.66, y = 1652.67, z = 54.0219}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 601.545, y = 1200.76, z = 102.162}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1049.24, y = 1220.17, z = 52.3338}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 933.073, y = 680.428, z = 37.3962}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 894.847, y = 1798.08, z = 52.3007}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1413.57, y = 454.241, z = 45.3777}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.86, y = 513.834, z = 47.4337}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 337.399, y = 957.62, z = 55.8037}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 545.13, y = 856.239, z = 84.9964}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1238.08, y = 1007.41, z = 101.225}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1133.26, y = 1236.86, z = 58.7134}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1406.53, y = 959.401, z = 75.27}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1790.12, y = 709.007, z = 52.1786}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1206.15, y = 410.984, z = 50.0761}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 558.512, y = 1586.38, z = 52.6943}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 361.321, y = 866.141, z = 59.7827}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 337.795, y = 961.88, z = 59.1949}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 980.89, y = 325.441, z = 52.1312}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 395.426, y = 602.564, z = 54.7056}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 928.521, y = 1853.1, z = 55.2683}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 956.381, y = 1800.36, z = 52.4539}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1455.8, y = 434.416, z = 37.6235}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 617.729, y = 1089.54, z = 81.4036}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 418.417, y = 883.331, z = 62.1408}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1177.97, y = 583.95, z = 47.4433}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 897.954, y = 407.408, z = 36.7912}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 511.975, y = 865.462, z = 76.4642}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.78, y = 1305.68, z = 55.6913}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1825.92, y = 678.159, z = 52.5717}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 884.095, y = 1590.16, z = 52.5484}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 393.682, y = 603.381, z = 55.3789}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 793.233, y = 1466.15, z = 52.2913}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1196.59, y = 451.101, z = 49.0584}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1683.64, y = 1765.35, z = 27.8415}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1244.99, y = 1620.74, z = 53.4628}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 366.585, y = 811.885, z = 57.1184}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1192.29, y = 472.993, z = 49.0823}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 344.407, y = 845.622, z = 55.6579}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 864.829, y = 1544.89, z = 52.3106}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1042.25, y = 246.703, z = 53.3192}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 921.846, y = 1570.49, z = 57.7179}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1014.1, y = 1626.79, z = 53.0182}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 886.448, y = 1569.01, z = 52.3477}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 655.72, y = 747.801, z = 98.1528}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1191.73, y = 1653.51, z = 58.2408}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 278.085, y = 1374.81, z = 52.2728}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 855.574, y = 1160.75, z = 42.1129}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 735.083, y = 940.987, z = 116.85}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 293.509, y = 1523.26, z = 52.8358}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 368.193, y = 808.161, z = 56.9729}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1760.61, y = 897.851, z = 53.5303}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 418.099, y = 892.714, z = 61.5492}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1828.85, y = 653.886, z = 51.9347}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1772.84, y = 1560.16, z = 49.8637}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1779.12, y = 1558.68, z = 49.9338}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 806.267, y = 287.026, z = 50.8905}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 362.063, y = 506.555, z = 51.4713}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 813.915, y = 253.364, z = 51.3649}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 929.019, y = 276.2, z = 52.6701}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 299.23, y = 1456.2, z = 52.3477}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 620.137, y = 1614, z = 49.2226}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1831.29, y = 685.125, z = 52.8312}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1048.18, y = 1221.34, z = 52.5307}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 339.854, y = 856.892, z = 54.9553}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1216.22, y = 544.359, z = 51.3277}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 478.562, y = 543.128, z = 56.0016}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 342.692, y = 853.901, z = 54.8573}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 705.43, y = 1264.3, z = 56.3699}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 785.996, y = 1461.41, z = 51.6876}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 807.356, y = 252.542, z = 54.6257}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 571.814, y = 1008.61, z = 83.2242}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1214.16, y = 572.846, z = 46.9337}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 315.629, y = 1297.04, z = 51.9375}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 768.236, y = 1625.78, z = 52.4378}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1740.84, y = 1666.14, z = 43.0608}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 884.756, y = 1578.39, z = 53.072}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1208.94, y = 1315.67, z = 55.0143}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 845.88, y = 1397.32, z = 51.404}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1786.93, y = 1557.81, z = 49.9338}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 283.613, y = 146.383, z = 17.4575}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 903.584, y = 1554.43, z = 53.7125}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 785.476, y = 1095.93, z = 60.1944}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1233.09, y = 539.504, z = 48.0166}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1784.32, y = 1556.12, z = 49.9338}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1739.19, y = 1671.14, z = 42.4335}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 812.179, y = 246.727, z = 54.4527}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 282.399, y = 1518.23, z = 51.3367}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 730.151, y = 941.214, z = 117.442}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 757.229, y = 1626.35, z = 52.9196}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 642.33, y = 750.975, z = 98.0325}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 723.891, y = 938.205, z = 116.605}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 904.264, y = 401.791, z = 36.6937}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1726.28, y = 1538.34, z = 51.9095}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 936.254, y = 285.406, z = 52.1017}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 915.279, y = 1563.08, z = 57.0022}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1778.65, y = 879.172, z = 52.598}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1295, y = 1782.23, z = 32.1735}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 955.105, y = 1841.54, z = 58.2408}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 888.598, y = 1433.77, z = 52.1359}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 286.91, y = 1485.02, z = 52.1115}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1142.65, y = 470.434, z = 51.5588}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1247.85, y = 1624.75, z = 53.4426}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 794.778, y = 1533.43, z = 52.747}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 730.81, y = 1099.74, z = 63.794}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 780.306, y = 1401.47, z = 51.5332}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 802.912, y = 1547.71, z = 52.2982}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1189.31, y = 460.809, z = 49.5151}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 838.947, y = 1538.66, z = 52.8754}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 552.3, y = 1579.6, z = 52.392}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 328.712, y = 1214.62, z = 53.2967}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1192.41, y = 504.173, z = 47.504}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 866.081, y = 1590.96, z = 52.1758}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 929.471, y = 680.89, z = 36.6937}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1188.67, y = 460.162, z = 49.5581}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 548.086, y = 854.853, z = 85.3934}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1399.83, y = 965.661, z = 76.5828}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1232.96, y = 1440.18, z = 53.9966}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 982.976, y = 328.859, z = 52.0427}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 888.501, y = 1547.86, z = 52.4485}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 547.222, y = 1580.87, z = 52.4115}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 298.806, y = 1534.83, z = 52.3457}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1658.13, y = 449.984, z = 51.8594}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1211.51, y = 1316.23, z = 54.5301}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 336.453, y = 961.987, z = 59.0035}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1208.3, y = 1320.42, z = 54.8782}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1037.86, y = 1225.98, z = 50.779}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 892.743, y = 1534.87, z = 52.5208}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 812.725, y = 247.842, z = 55.5896}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1110.07, y = 558.687, z = 51.6944}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1238.14, y = 1375.69, z = 53.6636}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 959.951, y = 1801.7, z = 52.6079}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 886.68, y = 1593.07, z = 52.4239}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 805.09, y = 250.433, z = 50.7992}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1218.47, y = 538.184, z = 47.7037}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 870.295, y = 1487.47, z = 55.6293}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 340.959, y = 894.81, z = 54.2028}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1605.78, y = 384.024, z = 47.5562}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1214.94, y = 1329.37, z = 54.8426}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 784.846, y = 1363.64, z = 52.5017}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 334.647, y = 890.804, z = 53.5787}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1225.73, y = 548.248, z = 48.5726}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1092.76, y = 949.778, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 953.387, y = 1840.26, z = 57.3277}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1612.98, y = 383.651, z = 48.1879}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1010.7, y = 1261.78, z = 49.4363}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 985.567, y = 1137.99, z = 49.9702}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 816.196, y = 1419.08, z = 52.9196}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1114.58, y = 559.792, z = 52.2925}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1399.52, y = 956.056, z = 76.8032}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 781.298, y = 1630.87, z = 52.4177}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 295.055, y = 1533.9, z = 51.3309}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 826.771, y = 1560.99, z = 52.8655}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 929.886, y = 1362.9, z = 49.9483}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 721.225, y = 932.313, z = 116.58}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 303.224, y = 148.27, z = 17.4956}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 899.432, y = 1788.41, z = 52.3078}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1184.9, y = 459.809, z = 53.8501}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1149.56, y = 296.188, z = 53.7417}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1019.02, y = 1256.33, z = 50.2118}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 884.219, y = 271.59, z = 52.0077}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 414.415, y = 888.579, z = 66.7489}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 958.14, y = 1838.68, z = 57.9654}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 794.89, y = 1530.59, z = 52.2232}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 633.07, y = 814.262, z = 100.969}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 924.662, y = 1524.92, z = 57.9658}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 866.578, y = 1493.08, z = 52.3307}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 919.432, y = 1569.14, z = 54.508}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1154.63, y = 925.796, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 830.163, y = 1526.79, z = 52.1349}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1831.43, y = 663.373, z = 52.0449}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1097.2, y = 529.419, z = 52.2562}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 614.271, y = 774.981, z = 98.5515}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1055.12, y = 1695.15, z = 51.5855}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 905.861, y = 1486.3, z = 52.3047}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 619.79, y = 738.893, z = 98.6066}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1192.66, y = 1471.79, z = 54.4356}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 414.064, y = 570.414, z = 54.1241}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 871.971, y = 1442.58, z = 52.3304}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 586.768, y = 753.75, z = 93.8751}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1219.72, y = 549.026, z = 52.8792}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 472.67, y = 901.891, z = 67.9529}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1242.27, y = 546.944, z = 48.7238}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 694.278, y = 313.198, z = 52.2}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 510.089, y = 1031.04, z = 87.6665}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1633.18, y = 1625.16, z = 53.3967}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1673.62, y = 1543.84, z = 53.6808}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 861.616, y = 1446.4, z = 55.8216}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1090.03, y = 1519.27, z = 58.1055}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 912.921, y = 1566.84, z = 53.7941}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1510.82, y = 1051.91, z = 59.2306}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 959.244, y = 1836.75, z = 58.2069}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 830.59, y = 1466.04, z = 51.6837}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1780.43, y = 790.45, z = 53.2414}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1811.82, y = 629.842, z = 53.5152}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1240.65, y = 1376.83, z = 53.3973}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 937.98, y = 296.109, z = 52.86}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 728.259, y = 927.237, z = 116.932}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 757.841, y = 304.142, z = 51.9057}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1114.21, y = 557.809, z = 51.6688}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1674.04, y = 1771.5, z = 27.8415}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 980.825, y = 1296.78, z = 50.4175}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 828.786, y = 1543.95, z = 52.4481}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 349.745, y = 435.839, z = 46.197}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1734.38, y = 1673.88, z = 45.6102}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 953.628, y = 1799.52, z = 53.2187}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1129.08, y = 1235.05, z = 58.8345}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1107.75, y = 475.187, z = 52.8396}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1774.62, y = 830.991, z = 52.2638}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 793.058, y = 1470.44, z = 52.3936}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 336.71, y = 891.427, z = 54.1693}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 861.971, y = 1589.78, z = 52.2265}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1340.54, y = 427.151, z = 51.3094}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1613.09, y = 378.78, z = 52.8328}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1118.21, y = 555.906, z = 52.4149}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1409.41, y = 1751.38, z = 33.1788}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 851.764, y = 1410.54, z = 52.5696}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 732.394, y = 930.942, z = 116.947}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1611.88, y = 383.972, z = 52.3148}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1074.1, y = 1531.64, z = 56.9325}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 732.67, y = 936.499, z = 117.553}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1832.17, y = 687.461, z = 52.1078}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 998.801, y = 1622.72, z = 52.7044}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1220.47, y = 545.896, z = 51.9708}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 627.024, y = 762.716, z = 97.5328}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 830.529, y = 1561.16, z = 52.8745}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 873.107, y = 1488.43, z = 55.6176}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1164.56, y = 592.749, z = 47.4433}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 865.708, y = 1500.23, z = 52.7783}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1222.6, y = 550.712, z = 48.7382}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1580.48, y = 1261.45, z = 59.3279}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 937.7, y = 299.1, z = 51.705}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 365.421, y = 870.316, z = 60.0202}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 342.234, y = 897.549, z = 53.6643}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1232.35, y = 516.687, z = 48.1992}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 822.887, y = 1497.44, z = 52.5126}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 914.671, y = 1788.27, z = 52.45}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 824.394, y = 1570.02, z = 55.7801}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1093.16, y = 506.72, z = 51.3}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1608.25, y = 387.887, z = 52.127}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1445.18, y = 1410.74, z = 90.5056}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 912.761, y = 1683.44, z = 52.6413}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 301.264, y = 1528.08, z = 51.3367}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 552.86, y = 1585.56, z = 52.05}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 857.815, y = 1444.97, z = 52.3331}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1780.5, y = 792.944, z = 52.6185}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1672.55, y = 1542.32, z = 54.1873}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 567.466, y = 1000.29, z = 81.5055}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 420.403, y = 882.894, z = 65.2027}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1300.09, y = 1789.42, z = 32.6532}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1508.32, y = 1233.99, z = 59.8061}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 948.468, y = 299.321, z = 55.1052}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1590.48, y = 1048.22, z = 59.1957}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1829.82, y = 695.198, z = 52.0383}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1112.06, y = 569.687, z = 52.8146}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1110.08, y = 564.124, z = 51.6688}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 807.95, y = 254.614, z = 54.4527}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1119.28, y = 558.067, z = 52.7567}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 935.26, y = 1522.85, z = 54.288}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1110.73, y = 1002.49, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 814.437, y = 1500.25, z = 52.9922}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1417.48, y = 1751.35, z = 33.1788}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1831.87, y = 675.405, z = 52.1028}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 582.474, y = 998.291, z = 81.4897}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1737.07, y = 1664.67, z = 43.1475}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 696.963, y = 313.448, z = 53.9499}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 930.738, y = 1525.32, z = 58.1374}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 994.807, y = 1627.02, z = 52.2989}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1746.54, y = 986.944, z = 52.429}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 803.763, y = 1586.12, z = 52.9176}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1779.03, y = 1550.96, z = 51.0249}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 916.7, y = 1570.83, z = 57.58}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1740.43, y = 1665.75, z = 46.2195}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1225.07, y = 542.722, z = 48.9233}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1814.14, y = 710.928, z = 53.6471}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 879.302, y = 1135.13, z = 46.2967}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1020.95, y = 1246.78, z = 50.1037}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 310.794, y = 142.596, z = 15.5929}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 889.766, y = 1551.75, z = 52.5531}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 415.07, y = 573.727, z = 54.0171}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 615.59, y = 777.366, z = 98.9034}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 805.741, y = 245.041, z = 51.688}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1192.84, y = 1675.79, z = 52.0925}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 925.458, y = 1525.02, z = 53.9908}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 513.927, y = 998.561, z = 81.4762}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 414.529, y = 572, z = 54.9788}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1188.9, y = 1473.09, z = 53.6697}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1191.89, y = 1656.93, z = 53.7037}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 597.333, y = 759.853, z = 93.8751}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1043.15, y = 1597.72, z = 53.0833}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1143.56, y = 476.247, z = 52.5009}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 420.75, y = 885.029, z = 65.3757}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 676.585, y = 1052.57, z = 76.435}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 995.748, y = 254.457, z = 53.7596}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 620.983, y = 737.503, z = 98.1692}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1276.63, y = 414.632, z = 51.0647}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 828.957, y = 1547.73, z = 52.8773}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 559.714, y = 1590.89, z = 52.0563}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1394.89, y = 963.986, z = 76.5828}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1144.24, y = 477.209, z = 52.1785}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1131.6, y = 1009.11, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 342.672, y = 847.82, z = 55.0426}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 863.284, y = 1445.98, z = 55.6181}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 794.966, y = 1589.75, z = 52.7176}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 907.582, y = 1791.46, z = 55.9613}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1740.49, y = 1675.47, z = 42.6728}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 929.649, y = 1529.2, z = 57.0527}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 353.945, y = 438.14, z = 46.2616}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 530.075, y = 1376.74, z = 82.1821}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 912.613, y = 1506.13, z = 53.8599}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1141.89, y = 1483.13, z = 53.4816}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 590.888, y = 756.539, z = 93.8751}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1423.27, y = 1148.95, z = 60.0405}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1537.92, y = 1681.26, z = 52.5847}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 927.134, y = 1852.07, z = 54.5225}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 476.914, y = 544.969, z = 55.4647}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1471.6, y = 1213.65, z = 58.8554}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 427.991, y = 855.021, z = 62.6622}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1835.75, y = 686.389, z = 52.5967}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 537.755, y = 1374.12, z = 82.2522}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 605.016, y = 245.002, z = 51.45}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1665.86, y = 1525.13, z = 54.6809}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1146.01, y = 480.928, z = 52.4386}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1665.89, y = 1050.47, z = 52.6229}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 922.262, y = 1568.5, z = 57.1281}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 947.346, y = 293.324, z = 56.0812}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 532.763, y = 1374.62, z = 83.0779}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 303.974, y = 1527.23, z = 53.1788}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1220.24, y = 549.624, z = 47.6742}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 932.12, y = 1529.3, z = 57.0527}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 329.979, y = 1201.48, z = 54.0853}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1077.77, y = 1530.12, z = 57.186}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 745.528, y = 1621.29, z = 52.1557}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1145.04, y = 474.795, z = 51.9656}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 654.741, y = 738.464, z = 97.942}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1181.69, y = 524.179, z = 47.1117}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 655.443, y = 1140.37, z = 76.0926}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 834.995, y = 1570.41, z = 51.776}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 961.154, y = 1344.55, z = 49.6119}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 896.941, y = 1471.78, z = 52.6973}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 328.092, y = 1216.12, z = 52.8134}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 901.742, y = 1782.96, z = 56.1333}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1816.49, y = 662.842, z = 52.8354}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1155.16, y = 527.211, z = 49.6458}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 654.582, y = 1137.75, z = 75.8774}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 910.324, y = 1785.65, z = 52.3078}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1607.4, y = 375.17, z = 48.2503}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1197.42, y = 462.074, z = 54.0978}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1344.26, y = 428.862, z = 51.3781}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 841.599, y = 1514.49, z = 52.5935}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1456.98, y = 1660.35, z = 56.5865}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 866.675, y = 1491.16, z = 55.6233}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 531.973, y = 1390.35, z = 82.2522}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 760.43, y = 1605.54, z = 52.4847}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1163.86, y = 560.204, z = 47.7252}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 513.117, y = 997.414, z = 81.7326}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.87, y = 412.512, z = 50.4439}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 938.188, y = 294.074, z = 56.0812}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 791.246, y = 1501.45, z = 52.3993}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1191.45, y = 1649.23, z = 57.9654}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 956.068, y = 1830.27, z = 54.5753}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 301.593, y = 443.114, z = 47.7668}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1218.78, y = 1330.97, z = 54.7314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1229.62, y = 573.84, z = 47.5504}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1060.28, y = 436.792, z = 52.2716}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1604.69, y = 375.495, z = 47.3363}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 810.062, y = 253.882, z = 51.3908}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 847.94, y = 1576.09, z = 52.3082}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1197.13, y = 453.8, z = 54.0978}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 832.572, y = 1574.72, z = 51.776}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 863.496, y = 1487.41, z = 52.3359}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1008.94, y = 1634.71, z = 64.3642}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1402.02, y = 966.503, z = 76.7932}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 805.926, y = 255.289, z = 54.4527}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 418.345, y = 882.515, z = 66.1158}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1200.19, y = 499.928, z = 48.3114}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1737.14, y = 1661.79, z = 46.3574}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1039.55, y = 1224.07, z = 50.6188}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1835.38, y = 674.517, z = 52.5917}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1238.28, y = 546.481, z = 46.893}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 338.285, y = 959.496, z = 58.5811}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1105.31, y = 475.356, z = 52.2473}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1097.7, y = 244.318, z = 52.9703}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1831.06, y = 673.41, z = 52.8262}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 893.134, y = 1532.57, z = 53.1113}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 925.327, y = 1520.4, z = 57.0527}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1219.75, y = 549.131, z = 52.0005}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1160.08, y = 599.335, z = 48.7096}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1814.35, y = 697.728, z = 52.4215}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 917.919, y = 1569.14, z = 58.0569}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 926.384, y = 672.773, z = 37.1734}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 297.134, y = 451.752, z = 48.4566}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 714.254, y = 1628.69, z = 51.1272}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1172.78, y = 595.538, z = 47.4433}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 944.731, y = 1784.72, z = 53.3405}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1831.6, y = 680.909, z = 51.9347}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 488.951, y = 915.774, z = 70.4025}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 787.104, y = 1095.67, z = 60.5216}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1093.81, y = 502.092, z = 51.3}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1136.59, y = 1468.29, z = 47.8009}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 915.078, y = 1571.18, z = 53.3508}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1125.6, y = 921.693, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 977.967, y = 1299.75, z = 50.4634}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1088.63, y = 1519.56, z = 57.7436}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1046.48, y = 1222.97, z = 51.5741}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 866.505, y = 1530.5, z = 52.7832}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1206.05, y = 1303.5, z = 55.1103}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1202.4, y = 514.436, z = 48.507}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1034.6, y = 1554.89, z = 54.0769}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1705.13, y = 1026.07, z = 53.5787}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 872.968, y = 1493.16, z = 55.6135}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1232.12, y = 538.387, z = 48.6465}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1178.29, y = 961.74, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1613.21, y = 373.954, z = 52.5851}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 915.431, y = 1683.18, z = 52.0588}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 807.938, y = 244.915, z = 50.7992}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1774.99, y = 877.14, z = 52.7608}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 574.889, y = 1050.01, z = 83.0045}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1179.23, y = 526.889, z = 47.8142}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1128.83, y = 586.302, z = 51.5906}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 646.317, y = 750.674, z = 98.1406}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1212.06, y = 1324.14, z = 54.9094}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1687.18, y = 458.971, z = 52.5322}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 423.273, y = 879.457, z = 61.5787}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1219.53, y = 541.666, z = 52.2461}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1184.77, y = 533.195, z = 47.0552}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1012.64, y = 1160.31, z = 49.3307}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 543.672, y = 1571.49, z = 52.8713}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 344.889, y = 452.07, z = 46.0164}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1230.02, y = 467.652, z = 47.7599}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 347.204, y = 455.234, z = 45.9722}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 790.325, y = 1601.39, z = 51.7048}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 962.696, y = 1834.74, z = 57.9654}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 599.635, y = 764.827, z = 97.9741}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1090.12, y = 964.618, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 302.085, y = 924.999, z = 53.7502}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.34, y = 1307.62, z = 55.2222}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 291.756, y = 1510.03, z = 52.3594}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1206.85, y = 1318.45, z = 55.4626}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1207.13, y = 573.461, z = 46.9337}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 289.761, y = 1506.79, z = 51.3367}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 749.01, y = 1096.77, z = 61.2735}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 540.245, y = 1381.53, z = 83.3336}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1191.43, y = 1472.37, z = 54.9975}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1603.91, y = 382.852, z = 52.8328}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 271.818, y = 130.092, z = 17.4575}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 321.516, y = 434.216, z = 46.1559}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1423.22, y = 1150.59, z = 60.5013}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 764.49, y = 1606.97, z = 52.0222}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 732.446, y = 1099.98, z = 64.3258}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1218.51, y = 1325.95, z = 54.6404}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 871.605, y = 1401.06, z = 52.907}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 959.869, y = 1849.98, z = 53.996}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1773.41, y = 1551.36, z = 50.4061}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 293.888, y = 159.992, z = 17.4679}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 871.65, y = 1519.73, z = 52.6601}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 515.956, y = 999.969, z = 82.546}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1574.42, y = 432.886, z = 44.8102}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 812.285, y = 252.019, z = 50.7992}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 558.574, y = 416.055, z = 53.4287}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 689.927, y = 319.566, z = 53.8113}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1159.94, y = 1000.73, z = 103.314}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 819.124, y = 250.014, z = 51.8441}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 870.528, y = 1438.31, z = 52.3076}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 961.482, y = 1837.64, z = 58.4646}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 838.193, y = 1594.31, z = 52.005}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 705.548, y = 1266.11, z = 56.8055}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1166.67, y = 588.23, z = 47.4422}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1207.48, y = 1661.72, z = 53.0302}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1814.75, y = 656.966, z = 53.1813}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1825.39, y = 666.169, z = 52.5917}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 869.682, y = 1492.5, z = 52.3259}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1868.4, y = 504.609, z = 54.5135}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 549.064, y = 1576.88, z = 52.3416}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1773.94, y = 832.41, z = 52.7522}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1188.86, y = 1644.82, z = 54.7328}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1812.33, y = 670.523, z = 52.1235}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1213.09, y = 1316.02, z = 55.0507}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1200.69, y = 469.678, z = 49.2895}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1829.71, y = 689.297, z = 52.0893}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1677.62, y = 1399.9, z = 57.5263}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1208.41, y = 513.707, z = 47.4337}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 956.983, y = 1344.71, z = 49.4082}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 856.433, y = 1159.4, z = 42.6538}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 732.951, y = 942.935, z = 116.893}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1677.88, y = 1538.39, z = 53.1722}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1400.74, y = 953.21, z = 76.8032}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1657.23, y = 1314.67, z = 55.226}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1187.77, y = 526.705, z = 48.0181}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1235.78, y = 1436.33, z = 54.5109}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1006.53, y = 1632.91, z = 63.5249}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1205.86, y = 505.4, z = 48.5684}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1691.14, y = 459.1, z = 52.6895}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 785.312, y = 1367.92, z = 52.3687}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 839.207, y = 1551.62, z = 53.3034}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 835.057, y = 1538.57, z = 52.8725}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 787.058, y = 1095.93, z = 59.5203}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1209.91, y = 494.257, z = 48.2732}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1423.16, y = 1153.12, z = 59.9271}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1458.53, y = 433.91, z = 38.0415}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1015.52, y = 1247.79, z = 49.8413}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 711.057, y = 1628.76, z = 51.4084}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1010.34, y = 1159.78, z = 48.7895}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 346.672, y = 445.406, z = 45.9779}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1599.84, y = 372.713, z = 48.2572}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 514.751, y = 999.262, z = 81.736}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 906.272, y = 1794.25, z = 55.9613}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 858.669, y = 1442.76, z = 55.6112}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1235.12, y = 1439.41, z = 54.7949}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1210.33, y = 574.685, z = 46.9337}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 558.28, y = 1586.83, z = 51.6429}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1603.35, y = 1051.47, z = 57.1704}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1014.42, y = 1160.68, z = 48.8343}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 547.485, y = 1575.11, z = 52.9989}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 955.246, y = 1840.97, z = 54.1655}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1228.96, y = 1360.56, z = 53.6027}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1180.1, y = 587.521, z = 47.4433}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 887.096, y = 1566.37, z = 52.6376}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1733.09, y = 1668.97, z = 42.0404}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1405.72, y = 1754.97, z = 33.7588}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 945.781, y = 1781.78, z = 52.6027}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 292.161, y = 1478.68, z = 52.0127}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1149.94, y = 479.929, z = 51.5588}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 588.464, y = 755.356, z = 93.8751}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 957.773, y = 1832.65, z = 54.5726}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 347.146, y = 442.24, z = 45.7811}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 618.146, y = 740.444, z = 97.9985}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1188.92, y = 529.114, z = 47.5914}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 822.083, y = 1493.82, z = 53.215}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 296.685, y = 1521.27, z = 51.9508}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1774.05, y = 1554.85, z = 50.8321}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 886.655, y = 270.955, z = 51.4581}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 773.974, y = 1359.97, z = 52.9396}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 862.602, y = 272.384, z = 51.4124}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1168.99, y = 598.437, z = 48.2788}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 566.208, y = 1592.27, z = 52.5594}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 306.93, y = 1519.83, z = 51.8808}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 802.178, y = 285.926, z = 50.8848}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 300.465, y = 1491.93, z = 51.265}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1193.95, y = 454.783, z = 53.5798}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 858.965, y = 1447.99, z = 56.2793}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 822.562, y = 1500.66, z = 52.5126}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 886.416, y = 1586.83, z = 52.4586}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1781.04, y = 817.81, z = 53.3096}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 1228.77, y = 1358.76, z = 54.2627}, Direction = {x = 0, y = 1, z = 0}},
            {Position = {x = 302.155, y = 1459.3, z = 52.2257}, Direction = {x = 0, y = 1, z = 0}}
        }
    };
end

-- The content spawned on ground, it aims for low tier guns like the crafted ones, medical items or mags,
-- the good loot should only spawn on crates or airdrops
SCAAMBRGroundItemsProperties.RandomContent = {};

-- DEPRECATED CODE
-- SCAAMBRGroundItemsProperties.RandomContent = {
--     {'Makarov', '9mmx10_makarov'},
--     {'Rags'},
--     {'GrenadePickup'},
--     {'762x30', 'AntibioticBandage'},
--     {'9mmx10_makarov', 'Axe'},
--     {'Peacemaker', 'Pile_357'},
--     {'AUMP45', 'acp_45_ext_magazine'},
--     {'acp_45_ext_magazine'},
--     {'12Gaugex8_Slug_AA12', 'Hatchet'},
--     {'PoliceBaton'},
--     {'R90', '57x50'},
--     {'57x50'},
--     {'10mm_magazine', '10mm_magazine'},
--     {'556x45_magazine'},
--     {'762x5'},
--     {'545x30'},
--     {'Katana', '22x10_ruger'},
--     {'ruger22', '22x10_ruger'},
--     {'M9A1', '9mmx15_m9a1'},
--     {'Machete'},
--     {'P350', '357x14'},
--     {'Hammer'},
--     {'SawedShotgun', 'Pile_12GaugeSlug'},
--     {'SCAAMStimPack'},
--     {'SCAAMArmor'}
-- };

-- Custom category and classes table
SCAAMBRItemCategories = {
    RandomPrimaryWeapon = {
        RandomRifle = {
            {Item = 'AK5D_jack_green', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'AK5D_jack_blue', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'T1Micro,ReflexSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'AK5D_jack_gold', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'T1Micro,ReflexSight', Spawner = 'Phase5,Phase6'},
            {Item = 'AK74U_jack_green', Ammo = '545x39_magazine,545x39_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'AK74U_jack_blue', Ammo = '545x39_magazine,545x39_ext_magazine', Attachment1 = 'ReddotSight,T1Micro,OPKSight,R3Sight,ReflexSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'AK74U_jack_gold', Ammo = '545x39_magazine,545x39_ext_magazine', Attachment1 = 'ReddotSight,T1Micro,OPKSight,R3Sight,ReflexSight,OpticScope', Attachment2 = 'ForegripVertical,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'AKM_jack_green', Ammo = '762x39_magazine,762x39_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'AKM_jack_blue', Ammo = '762x39_magazine,762x39_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'AKM_jack_gold', Ammo = '762x39_magazine,762x39_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight,OpticScope', Attachment2 = 'RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'AKMGold_jack_green', Ammo = '762x39_magazine,762x39_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'AKMGold_jack_blue', Ammo = '762x39_magazine,762x39_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'AKMGold_jack_gold', Ammo = '762x39_magazine,762x39_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight', Attachment2 = 'LaserSight', Spawner = 'Phase5,Phase6'},
            {Item = 'AKVal_jack_green', Ammo = '762x39_magazine,762x39_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'AKVal_jack_blue', Ammo = '762x39_magazine,762x39_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'AKVal_jack_gold', Ammo = '762x39_magazine,762x39_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight,OpticScope', Spawner = 'Phase5,Phase6'},
            {Item = 'AT15_jack_green', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'AT15_jack_blue', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'AT15_jack_gold', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight,OpticScope', Attachment2 = 'ForegripVertical,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'Bulldog_jack_green', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'Bulldog_jack_blue', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'Bulldog_jack_gold', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase5,Phase6'},
            {Item = 'M4A1_jack_green', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'M4A1_jack_blue', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'M4A1_jack_gold', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'M4V5_jack_green', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'M4V5_jack_blue', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'M4V5_jack_gold', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight,OpticScope', Attachment2 = 'ForegripVertical,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'M16_jack_green', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'M16_jack_blue', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'M16_jack_gold', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,OpticScope,HuntingScope,ReddotSight', Attachment2 = 'ForegripVertical,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'M16Vietnam_jack_green', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'M16Vietnam_jack_blue', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'M16Vietnam_jack_gold', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'BayonetRifle,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'M249_jack_green', Ammo = '556x45_extplus_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'M249_jack_blue', Ammo = '556x45_extplus_magazine', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'M249_jack_gold', Ammo = '556x45_extplus_magazine', Attachment1 = 'BayonetRifle,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'Mk18_jack_green', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'Mk18_jack_blue', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'Mk18_jack_gold', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,OpticScope,ReddotSight', Attachment2 = 'LaserSight,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'Mk18Reaver_jack_green', Ammo = '556x45_magazine,556x45_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'Mk18Reaver_jack_blue', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'T1Micro,ReflexSight,OpticScope,OPKSight,R3Sight,ReddotSight', Spawner = 'Phase2,Phase3,Phase4Phase5'},
            {Item = 'Mk18Reaver_jack_gold', Ammo = '556x45_magazine,556x45_ext_magazine', Attachment1 = 'T1Micro,ReflexSight,OpticScope,OPKSight,R3Sight,ReddotSight', Attachment2 = 'LaserSight,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'RPK_jack_green', Ammo = '762x39_magazine,762x39_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'RPK_jack_blue', Ammo = '762x39_magazine,762x39_ext_magazine', Attachment1 = 'PSOScope', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'RPK_jack_gold', Ammo = '762x39_magazine,762x39_ext_magazine', Attachment1 = 'PSOScope', Attachment2 = 'RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'VSS_jack_green', Ammo = '762x39_magazine,762x39_small_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'VSS_jack_blue', Ammo = '762x39_magazine,762x39_small_magazine', Attachment1 = 'PSOScope', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'VSS_jack_gold', Ammo = '762x39_magazine,762x39_small_magazine', Attachment1 = 'PSOScope', Spawner = 'Phase5,Phase6'},
            {Item = 'CraftedRifleLong_jack', Ammo = '556x45_magazine', Spawner = 'Ground'},
            {Item = 'CraftedShortRifle556_jack', Ammo = '556x45_magazine', Spawner = 'Ground'}
        },
        RandomShotgun = {
            -- {Item = 'AA12_jack_green', Ammo = 'Slug_12gauge_magazine', Spawner = 'Ground,Phase1,Phase2'},
            -- {Item = 'AA12_jack_blue', Ammo = 'Slug_12gauge_magazine', Spawner = 'Phase1,Phase2,Phase3'},
            -- {Item = 'AA12_jack_gold', Ammo = 'Slug_12gauge_magazine', Spawner = 'Phase2,Phase3'},
            {Item = 'Rem870_jack_green', Ammo = 'Pile_12GaugeSlug', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'Rem870_jack_blue', Ammo = 'Pile_12GaugeSlug', Spawner = 'Phase1,Phase2,Phase3'},
            {Item = 'Rem870_jack_gold', Ammo = 'Pile_12GaugeSlug', Spawner = 'Phase2,Phase3'},
            {Item = 'SAS12_jack_green', Ammo = 'Pile_12GaugeSlug', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'SAS12_jack_blue', Ammo = 'Pile_12GaugeSlug', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight', Spawner = 'Phase1,Phase2,Phase3'},
            {Item = 'SAS12_jack_gold', Ammo = 'Pile_12GaugeSlug', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight', Attachment2 = 'RifleSilencer', Spawner = 'Phase2,Phase3'},
            {Item = 'Shotgun870Tactical_jack_green', Ammo = 'Pile_12GaugeSlug', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'Shotgun870Tactical_jack_blue', Ammo = 'Pile_12GaugeSlug', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight', Spawner = 'Phase1,Phase2,Phase3'},
            {Item = 'Shotgun870Tactical_jack_gold', Ammo = 'Pile_12GaugeSlug', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight', Attachment2 = 'RifleSilencer', Spawner = 'Phase2,Phase3'},
            {Item = 'CraftedShotgun_jack', Ammo = 'Pile_12GaugeSlug', Spawner = 'Ground'}
        },
        RandomBoltAction = {
            {Item = 'ACAW_jack_green', Ammo = '762x51_magazine', Spawner = 'Phase2,Phase3'},
            {Item = 'ACAW_jack_blue', Ammo = '762x51_magazine', Attachment1 = 'OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'ACAW_jack_gold', Ammo = '762x51_magazine', Attachment1 = 'OpticScope,HuntingScope,OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Attachment2 = 'RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'M40A5_jack_green', Ammo = '762x51_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'M40A5_jack_blue', Ammo = '762x51_magazine', Attachment1 = 'OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Attachment2 = 'RifleSilencer', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'M40A5_jack_gold', Ammo = '762x51_magazine', Attachment1 = 'OpticScope,HuntingScope,OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Attachment2 = 'RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'Model70_jack_green', Ammo = 'Pile_223', Spawner = 'Phase1,Phase2'},
            {Item = 'Model70_jack_blue', Ammo = 'Pile_223', Attachment1 = 'OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'Model70_jack_gold', Ammo = 'Pile_223', Attachment1 = 'OpticScope,HuntingScope,OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Attachment2 = 'RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'Model1873_jack_green', Ammo = 'Pile_357', Spawner = 'Phase1,Phase2'},
            {Item = 'Model1873_jack_blue', Ammo = 'Pile_357', Spawner = 'Phase2,Phase3,Phase4,Phase6'},
            {Item = 'Model1873_jack_gold', Ammo = 'Pile_357', Spawner = 'Phase5,Phase6'},
            {Item = 'Rem700_jack_green', Ammo = 'Pile_308', Spawner = 'Phase1,Phase2'},
            {Item = 'Rem700_jack_blue', Ammo = 'Pile_308', Attachment1 = 'OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Attachment2 = 'RifleSilencer', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'Rem700_jack_gold', Ammo = 'Pile_308', Attachment1 = 'OpticScope,HuntingScope,OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Attachment2 = 'RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'Sako_85_jack_green', Ammo = 'Pile_308', Spawner = 'Phase1,Phase2'},
            {Item = 'Sako_85_jack_blue', Ammo = 'Pile_308', Attachment1 = 'OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'Sako_85_jack_gold', Ammo = 'Pile_308', Attachment1 = 'OpticScope,HuntingScope,OPKSight,R3Sight,ReddotSight,ReflexSight,T1Micro', Attachment2 = 'RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'Wasteland22_jack_green', Ammo = 'Pile_22', Spawner = 'Ground,Phase1'},
            {Item = 'Wasteland22_jack_blue', Ammo = 'Pile_22', Spawner = 'Phase1,Phase2'},
            {Item = 'Wasteland22_jack_gold', Ammo = 'Pile_22', Spawner = 'Phase2,Phase3'},
            {Item = 'CraftedRifle9mm_jack', Ammo = '9mm_small_magazine,9mm_magazine,9mm_ext_magazine', Spawner = 'Ground'}
        },
        RandomSMG = {
            {Item = 'AUMP45_jack_green', Ammo = 'acp_45_ext_magazine', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'AUMP45_jack_blue', Ammo = 'acp_45_ext_magazine', Attachment1 = 'T1Micro,ReflexSight,OPKSight,R3Sight,ReddotSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'AUMP45_jack_gold', Ammo = 'acp_45_ext_magazine', Attachment1 = 'T1Micro,ReflexSight,OPKSight,R3Sight,OpticScope,ReddotSight', Attachment2 = 'LaserSight,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'CX4Storm_jack_green', Ammo = 'acp_45_magazine', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'CX4Storm_jack_blue', Ammo = 'acp_45_magazine', Attachment1 = 'T1Micro,ReflexSight,OPKSight,R3Sight,ReddotSight', Spawner = 'Phase2,Phase3,Phase4'},
            {Item = 'CX4Storm_jack_gold', Ammo = 'acp_45_magazine', Attachment1 = 'T1Micro,ReflexSight,OPKSight,R3Sight,OpticScope,ReddotSight', Attachment2 = 'ForegripVertical,RifleSilencer', Spawner = 'Phase4,Phase5'},
            {Item = 'KrissV_jack_green', Ammo = '10mm_magazine', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'KrissV_jack_blue', Ammo = '10mm_magazine', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight', Spawner = 'Phase2,Phase3,Phase4'},
            {Item = 'KrissV_jack_gold', Ammo = '10mm_magazine', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight,OpticScope', Attachment2 = 'ForegripVertical,RifleSilencer', Spawner = 'Phase4,Phase5'},
            {Item = 'MAK10_jack_green', Ammo = '9mm_magazine', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'MAK10_jack_blue', Ammo = '9mm_magazine', Spawner = 'Phase2,Phase3,Phase4'},
            {Item = 'MAK10_jack_gold', Ammo = '9mm_magazine', Attachment1 = 'PistolSilencer', Spawner = 'Phase4,Phase5'},
            {Item = 'MP5_jack_green', Ammo = '10mm_ext_magazine,10mm_magazine', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'MP5_jack_blue', Ammo = '10mm_ext_magazine,10mm_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'MP5_jack_gold', Ammo = '10mm_ext_magazine,10mm_magazine', Attachment1 = 'ReddotSight,OPKSight,R3Sight,T1Micro,ReflexSight,OpticScope', Attachment2 = 'RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'R90_jack_green', Ammo = '57x50_magazine', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'R90_jack_blue', Ammo = '57x50_magazine', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight', Spawner = 'Phase2,Phase3,Phase4,Phase5'},
            {Item = 'R90_jack_gold', Ammo = '57x50_magazine', Attachment1 = 'T1Micro,OPKSight,R3Sight,ReflexSight,ReddotSight,OpticScope', Attachment2 = 'LaserSight,RifleSilencer', Spawner = 'Phase5,Phase6'},
            {Item = 'CraftedSMG_jack', Ammo = '9mm_small_magazine,9mm_magazine,9mm_ext_magazine', Spawner = 'Ground'}
        }
    },
    RandomSecondaryWeapon = {
        RandomShotgun = {
            {Item = 'SawedShotgun_jack_green', Ammo = 'Pile_12GaugeSlug', Spawner = 'Ground'},
            {Item = 'SawedShotgun_jack_blue', Ammo = 'Pile_12GaugeSlug', Spawner = 'Phase1'},
            {Item = 'SawedShotgun_jack_gold', Ammo = 'Pile_12GaugeSlug', Spawner = 'Phase2'},
            {Item = 'CraftedShortShotgun_jack', Ammo = 'Pile_12GaugeSlug', Spawner = 'Ground'}
        },
        RandomPistol = {
            {Item = 'AP85_jack_green', Ammo = '9mm_magazine', Spawner = 'Ground,Phase1'},
            {Item = 'AP85_jack_blue', Ammo = '9mm_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'AP85_jack_gold', Ammo = '9mm_magazine', Spawner = 'Phase2,Phase3'},
            {Item = 'ColtPython_jack_green', Ammo = 'Pile_357', Spawner = 'Ground,Phase1'},
            {Item = 'ColtPython_jack_blue', Ammo = 'Pile_357', Spawner = 'Phase1,Phase2'},
            {Item = 'ColtPython_jack_gold', Ammo = 'Pile_357', Spawner = 'Phase2,Phase3'},
            {Item = 'ColtPythonGrimeyRick_jack_green', Ammo = 'Pile_357', Spawner = 'Ground,Phase1'},
            {Item = 'ColtPythonGrimeyRick_jack_blue', Ammo = 'Pile_357', Spawner = 'Phase1,Phase2'},
            {Item = 'ColtPythonGrimeyRick_jack_gold', Ammo = 'Pile_357', Spawner = 'Phase2,Phase3'},
            {Item = 'G18Pistol_jack_green', Ammo = '9mm_small_magazine,9mm_magazine,9mm_ext_magazine', Spawner = 'Ground,Phase1'},
            {Item = 'G18Pistol_jack_blue', Ammo = '9mm_small_magazine,9mm_magazine,9mm_ext_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'G18Pistol_jack_gold', Ammo = '9mm_small_magazine,9mm_magazine,9mm_ext_magazine', Attachment1 = 'PistolSilencer', Spawner = 'Phase2,Phase3'},
            {Item = 'hk45_jack_green', Ammo = 'acp_45_small_magazine,acp_45_smaller_magazine', Attachment1 = 'PistolSilencer', Spawner = 'Ground,Phase1'},
            {Item = 'hk45_jack_blue', Ammo = 'acp_45_small_magazine,acp_45_smaller_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'hk45_jack_gold', Ammo = 'acp_45_small_magazine,acp_45_smaller_magazine', Spawner = 'Phase2,Phase3'},
            {Item = 'M9A1_jack_green', Ammo = '9mm_magazine,9mm_small_magazine', Spawner = 'Ground,Phase1'},
            {Item = 'M9A1_jack_blue', Ammo = '9mm_magazine,9mm_small_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'M9A1_jack_gold', Ammo = '9mm_magazine,9mm_small_magazine', Attachment1 = 'PistolSilencer', Spawner = 'Phase2,Phase3'},
            {Item = 'm1911a1_jack_green', Ammo = 'acp_45_smaller_magazine', Spawner = 'Ground,Phase1'},
            {Item = 'm1911a1_jack_blue', Ammo = 'acp_45_smaller_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'm1911a1_jack_gold', Ammo = 'acp_45_smaller_magazine', Attachment1 = 'PistolSilencer', Spawner = 'Phase2,Phase3'},
            {Item = 'Makarov_jack_green', Ammo = '9mm_magazine', Spawner = 'Ground,Phase1'},
            {Item = 'Makarov_jack_blue', Ammo = '9mm_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'Makarov_jack_gold', Ammo = '9mm_magazine', Attachment1 = 'PistolSilencer', Spawner = 'Phase2,Phase3'},
            {Item = 'P350_jack_green', Ammo = '357_magazine', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'P350_jack_blue', Ammo = '357_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'P350_jack_gold', Ammo = '357_magazine', Attachment1 = 'PistolSilencer', Spawner = 'Phase2,Phase3,Phase4'},
            {Item = 'Peacemaker_jack_green', Ammo = 'Pile_357', Spawner = 'Ground,Phase1'},
            {Item = 'Peacemaker_jack_blue', Ammo = 'Pile_357', Spawner = 'Phase1,Phase2'},
            {Item = 'Peacemaker_jack_gold', Ammo = 'Pile_357', Spawner = 'Phase2,Phase3'},
            {Item = 'PX4_jack_green', Ammo = 'acp_45_small_magazine', Spawner = 'Ground,Phase1'},
            {Item = 'PX4_jack_blue', Ammo = 'acp_45_small_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'PX4_jack_gold', Ammo = 'acp_45_small_magazine', Attachment1 = 'PistolSilencer', Spawner = 'Phase2,Phase3'},
            {Item = 'ruger22_jack_green', Ammo = '22_magazine', Spawner = 'Ground'},
            {Item = 'ruger22_jack_blue', Ammo = '22_magazine', Spawner = 'Ground,Phase1'},
            {Item = 'ruger22_jack_gold', Ammo = '22_magazine', Spawner = 'Phase1,Phase2'},
            {Item = 'CraftedLongPistol_jack', Ammo = '9mm_small_magazine,9mm_magazine,9mm_ext_magazine', Spawner = 'Ground'},
            {Item = 'CraftedPistol_jack', Ammo = '9mm_small_magazine,9mm_magazine,9mm_ext_magazine', Spawner = 'Ground'},
            {Item = 'CraftedPistol556_jack', Ammo = '556x45_magazine', Spawner = 'Ground'}
        },
        RandomMelee = {
            {Item = 'Axe', Spawner = 'Ground'},
            {Item = 'AxePatrick', Spawner = 'Ground,Phase4,Phase5,Phase6'},
            {Item = 'BaseballBat', Spawner = 'Ground'},
            {Item = 'BaseballBatHerMajesty', Spawner = 'Ground,Phase4,Phase5,Phase6'},
            {Item = 'BaseballBatNails', Spawner = 'Ground,Phase2,Phase3'},
            {Item = 'BaseballBatSawBlade', Spawner = 'Ground,Phase2,Phase3'},
            {Item = 'BaseballBatSawBladeNails', Spawner = 'Ground,Phase2,Phase3'},
            {Item = 'BaseballBatScrapNails', Spawner = 'Ground,Phase2,Phase3'},
            {Item = 'Crowbar', Spawner = 'Ground'},
            {Item = 'Katana', Spawner = 'Ground,Phase2,Phase3'},
            {Item = 'KatanaBlackWidow', Spawner = 'Ground,Phase4,Phase5,Phase6'},
            {Item = 'Sledgehammer', Spawner = 'Ground,Phase3,Phase4'},
            {Item = 'FahQPaddle', Spawner = 'Ground,Phase1'},
            {Item = 'Cleaver', Spawner = 'Ground,Phase1'},
            {Item = 'Hatchet', Spawner = 'Ground'},
            {Item = 'HuntingKnife', Spawner = 'Ground'},
            {Item = 'LugWrench', Spawner = 'Ground'},
            {Item = 'Machete', Spawner = 'Ground,Phase1'},
            {Item = 'NailKnuckles', Spawner = 'Ground'},
            {Item = 'NailsPaddle', Spawner = 'Ground'},
            {Item = 'PipeWrench', Spawner = 'Ground'},
            {Item = 'PoliceBaton', Spawner = 'Ground'},
            {Item = 'SurvivalKnife', Spawner = 'Ground'}
        }
    },
    RandomUtilitary = {
        RandomExplosive = {
            {Item = 'FlashbangPickup', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5,Phase6'},
            {Item = 'GrenadeGasNervePickup', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5,Phase6'},
            {Item = 'GrenadeGasSleepPickup', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5,Phase6'},
            {Item = 'GrenadeGasTearPickup', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5,Phase6'},
            {Item = 'GrenadePickup', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5,Phase6'},
            {Item = 'GrenadeSmokeWhitePickup', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5,Phase6'},
            {Item = 'PipebombPickup', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5,Phase6'},
        },
        RandomMedical = {
            {Item = 'Rags', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4'},
            {Item = 'Bandage', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5'},
            {Item = 'AntibioticBandage', Spawner = 'Phase3,Phase4,Phase5,Phase6'},
            {Item = 'AdvancedBandage', Spawner = 'Phase4,Phase5,Phase6'}
        },
        RandomSpecial = {
            {Item = 'SCAAMStimPack', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5,Phase6'},
            {Item = 'SCAAMArmor', Spawner = 'Ground,Phase1,Phase2,Phase3,Phase4,Phase5,Phase6'},
        }
    },
    RandomAmmo = {
        {Item = '9mm_ext_magazine', Spawner = 'Ground'},
        {Item = '9mm_magazine', Spawner = 'Ground'},
        {Item = '9mm_small_magazine', Spawner = 'Ground'},
        {Item = '10mm_ext_magazine', Spawner = 'Ground'},
        {Item = '10mm_magazine', Spawner = 'Ground'},
        {Item = '22_magazine', Spawner = 'Ground'},
        {Item = '57x50_magazine', Spawner = 'Ground'},
        {Item = '357_magazine', Spawner = 'Ground'},
        {Item = '545x39_ext_magazine', Spawner = 'Ground'},
        {Item = '556x45_ext_magazine', Spawner = 'Ground'},
        {Item = '556x45_extplus_magazine', Spawner = 'Ground'},
        {Item = '556x45_magazine', Spawner = 'Ground'},
        {Item = '762x39_ext_magazine', Spawner = 'Ground'},
        {Item = '762x39_magazine', Spawner = 'Ground'},
        {Item = '762x39_small_magazine', Spawner = 'Ground'},
        {Item = '762x51_magazine', Spawner = 'Ground'},
        {Item = 'acp_45_ext_magazine', Spawner = 'Ground'},
        {Item = 'acp_45_magazine', Spawner = 'Ground'},
        {Item = 'acp_45_small_magazine', Spawner = 'Ground'},
        {Item = 'acp_45_smaller_magazine', Spawner = 'Ground'},
        {Item = 'Slug_12gauge_magazine', Spawner = 'Ground'},
        {Item = 'Pile_22', Spawner = 'Ground'},
        {Item = 'Pile_223', Spawner = 'Ground'},
        {Item = 'Pile_308', Spawner = 'Ground'},
        {Item = 'Pile_357', Spawner = 'Ground'},
        {Item = 'Pile_12GaugeSlug', Spawner = 'Ground'}
    },
    RandomStorage = {
        {Item = 'StowPackBlack', Spawner = 'Ground,Phase1,Phase2,Phase3'},
        {Item = 'RuggedPack', Spawner = 'Phase3,Phase4,Phase5,Phase6'},
        {Item = 'FannyPackBlack', Spawner = 'Ground,Phase1,Phase2'}
    },
    RandomProtection = {
        RandomChest = {
            {Item = 'FlakVestTan', Spawner = 'Phase4,Phase5,Phase6'},
            {Item = 'PoliceVestBlack', Spawner = 'Phase3,Phase4,Phase5,Phase6'},
            {Item = 'TacticalVestBlack', Spawner = 'Ground,Phase1,Phase2,Phase3'},
        },
        RandomHead = {
            {Item = 'SpaceHelmet', Spawner = 'Phase5,Phase6'},
            {Item = 'SwatHelmet', Spawner = 'Phase4,Phase5,Phase6'},
            {Item = 'ScavengerHelmet', Spawner = 'Phase1,Phase2,Phase3'},
            {Item = 'MotorcycleHelmetCarbon', Spawner = 'Ground,Phase1,Phase2'},
            {Item = 'MilitaryHelmetTan', Spawner = 'Phase1,Phase2,Phase3,Phase4'}
        }
    }
};

-- SCAAMBRFillSpawners
-- Gets The content dropped by the crates and on ground, for crates it gets higher tier loot as the game progresses to make it interesting
function SCAAMBRFillSpawners(originalTable)
    local generatedCrateTable = {};

    -- The content spawned on ground, it aims for low tier guns like the crafted ones, medical items or mags,
    -- the good loot should only spawn on crates or airdrops
    local generatedGroundTable = {
        RandomPrimaryWeapon = {},
        RandomSecondaryWeapon = {},
        RandomUtilitary = {},
        RandomAmmo = {},
        RandomStorage = {},
        RandomProtection = {}
    };

    for i = 1, SCAAMBattleRoyaleProperties.GamePhases, 1 do

        -- Creates the table for each phase
        generatedCrateTable['Phase' .. tostring(i)] = {
            RandomPrimaryWeapon = {},
            RandomSecondaryWeapon = {},
            RandomUtilitary = {},
            RandomAmmo = {},
            RandomStorage = {},
            RandomProtection = {}
        };

        -- Loops through all the item category types so add them to their respective phase
        -- Primary weapon
        for key, value in pairs(originalTable.RandomPrimaryWeapon.RandomRifle) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomPrimaryWeapon, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomPrimaryWeapon, value);
            end
        end

        for key, value in pairs(originalTable.RandomPrimaryWeapon.RandomShotgun) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomPrimaryWeapon, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomPrimaryWeapon, value);
            end
        end

        for key, value in pairs(originalTable.RandomPrimaryWeapon.RandomBoltAction) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomPrimaryWeapon, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomPrimaryWeapon, value);
            end
        end

        for key, value in pairs(originalTable.RandomPrimaryWeapon.RandomSMG) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomPrimaryWeapon, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomPrimaryWeapon, value);
            end
        end

        -- Secondary weapon
        for key, value in pairs(originalTable.RandomSecondaryWeapon.RandomShotgun) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomSecondaryWeapon, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomSecondaryWeapon, value);
            end
        end

        for key, value in pairs(originalTable.RandomSecondaryWeapon.RandomPistol) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomSecondaryWeapon, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomSecondaryWeapon, value);
            end
        end

        for key, value in pairs(originalTable.RandomSecondaryWeapon.RandomMelee) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomSecondaryWeapon, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomSecondaryWeapon, value);
            end
        end

        -- Utilitary equipment
        for key, value in pairs(originalTable.RandomUtilitary.RandomExplosive) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomUtilitary, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomUtilitary, value);
            end
        end

        for key, value in pairs(originalTable.RandomUtilitary.RandomMedical) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomUtilitary, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomUtilitary, value);
            end
        end

        for key, value in pairs(originalTable.RandomUtilitary.RandomSpecial) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomUtilitary, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomUtilitary, value);
            end
        end

        -- Ammo equipment
        for key, value in pairs(originalTable.RandomAmmo) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomAmmo, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomAmmo, value);
            end
        end

        -- Storage equipment
        for key, value in pairs(originalTable.RandomStorage) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomStorage, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomStorage, value);
            end
        end

        -- Protection equipment
        for key, value in pairs(originalTable.RandomProtection.RandomChest) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomProtection, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomProtection, value);
            end
        end

        for key, value in pairs(originalTable.RandomProtection.RandomHead) do
            if (value.Spawner and string.match(value.Spawner, ('Phase' .. tostring(i)))) then
                table.insert(generatedCrateTable['Phase' .. tostring(i)].RandomProtection, value);
            end

            if (value.Spawner and string.match(value.Spawner, 'Ground')) then
                InsertIntoTable(generatedGroundTable.RandomProtection, value);
            end
        end
    end

    return {generatedCrateTable, generatedGroundTable};
end

-- Fills the random content with the generated tables
local generatedSpawnTables = SCAAMBRFillSpawners(SCAAMBRItemCategories);
SCAAMBRCrateProperties.RandomContent = generatedSpawnTables[1];
SCAAMBRGroundItemsProperties.RandomContent = generatedSpawnTables[2];

-- All the spawnable classnames for cleanup use
SCAAMBREntityClasses = {
    -- Crates
    'SCAAMBattleRoyaleCrate',
    'SCAAMBattleRoyaleCrateOpen',
    'SCAAMBRAirDropCrate',

    -- Bodies
    'PlayerCorpse'
}

SCAAMBRItemClasses = {};

-- SCAAMBRFillCleanupTable
-- Adds all the possible spawned items to the cleanup table
function SCAAMBRFillCleanupTable()

    -- Loops through the list of ground items to include them in the table
    for key, table in pairs(SCAAMBRGroundItemsProperties.RandomContent) do
        for key2, item in pairs(table) do
            InsertIntoTable(SCAAMBRItemClasses, item.Item);

            -- Checks if the item has an Ammo property, melee weapons won't have this for example
            if (item.Ammo and item.Ammo ~= '') then
                for key3, ammo in pairs(SCAAMBRSplitToTable(item.Ammo, ',')) do
                    InsertIntoTable(SCAAMBRItemClasses, ammo);
                end
            end

            -- Checks if the item has an Attachment1 property, melee weapons won't have this for example
            if (item.Attachment1 and item.Attachment1 ~= '') then
                for key3, attachment in pairs(SCAAMBRSplitToTable(item.Attachment1, ',')) do
                    InsertIntoTable(SCAAMBRItemClasses, attachment);
                end
            end

            -- Checks if the item has an Attachment2 property, melee weapons won't have this for example
            if (item.Attachment2 and item.Attachment2 ~= '') then
                for key3, attachment in pairs(SCAAMBRSplitToTable(item.Attachment2, ',')) do
                    InsertIntoTable(SCAAMBRItemClasses, attachment);
                end
            end
        end
    end

    local currentPhase = 1;

    while (currentPhase <= SCAAMBattleRoyaleProperties.GamePhases) do

        -- Loops through the list of crate items to include them in the table
        for key, table in pairs(SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(currentPhase)]) do
            for key2, item in pairs(table) do
                InsertIntoTable(SCAAMBRItemClasses, item.Item);

                -- Checks if the item has an Ammo property, melee weapons won't have this for example
                if (item.Ammo and item.Ammo ~= '') then
                    for key3, ammo in pairs(SCAAMBRSplitToTable(item.Ammo, ',')) do
                        InsertIntoTable(SCAAMBRItemClasses, ammo);
                    end
                end

                -- Checks if the item has an Attachment1 property, melee weapons won't have this for example
                if (item.Attachment1 and item.Attachment1 ~= '') then
                    for key3, attachment in pairs(SCAAMBRSplitToTable(item.Attachment1, ',')) do
                        InsertIntoTable(SCAAMBRItemClasses, attachment);
                    end
                end

                -- Checks if the item has an Attachment2 property, melee weapons won't have this for example
                if (item.Attachment2 and item.Attachment2 ~= '') then
                    for key3, attachment in pairs(SCAAMBRSplitToTable(item.Attachment2, ',')) do
                        InsertIntoTable(SCAAMBRItemClasses, attachment);
                    end
                end
            end
        end

        currentPhase = currentPhase + 1;
    end
end

SCAAMBRFillCleanupTable();

-- Stats and kill feed tables
SCAAMBRGameStats = {};

-- SCAAMNotesInitLoading
-- Manage storage stuff (Based on Theros' mFramework)
function SCAAMBRInitModules()
    SCAAMBRJSON = require('JSON');
    SCAAMBRDatabase = mFramework.PersistantStorage:Collection('SCAAMBattleRoyaleCollection');
    SCAAMBRPlayerDatabase = mFramework.PersistantStorage:Collection('SCAAMBattleRoyalePlayerCollection');

    -- Gets the top 15 data
    SCAAMBRTopFifteen = SCAAMBRGetTopFifteen();
end

-- SCAAMBRGetSpawners
-- Grabs all the custom spawner entities scattered around the map to get their positions and directions
function SCAAMBRGetSpawners()
    local cratePositions = {};
    local groundPositions = {};
    local lobbyPositions = {};
    local mainPositions = {};
    local playerPositions = {};
    local mapConfig = System.GetEntitiesByClass('SCAAMBattleRoyaleConfigSpawn');
    local mapCircle = System.GetEntitiesByClass('SCAAMBattleRoyaleCircleSpawn');
    local listOfCrates = System.GetEntitiesByClass('SCAAMBattleRoyaleCrateSpawn');
    local listOfGround = System.GetEntitiesByClass('SCAAMBattleRoyaleGroundSpawn');
    local listOfLobby = System.GetEntitiesByClass('SCAAMBattleRoyaleLobbySpawn');
    local listOfMainPos = System.GetEntitiesByClass('SCAAMBattleRoyaleMainSpawn');
    local listOfPlayerPos = System.GetEntitiesByClass('SCAAMBattleRoyalePlayerSpawn');

    -- Finds the config spawn then it despawns it
    if (mapConfig ~= nil and type(mapConfig) == 'table' and table.getn(mapConfig) > 0) then
        for key, item in pairs(mapConfig) do

            -- Sets the map size
            SCAAMBattleRoyalePropertiesBackup.MapSize = item.Properties.iSCAAMBRMapSize;

            -- Sets the min players required to start a game
            SCAAMBattleRoyalePropertiesBackup.MinPlayers = item.Properties.iSCAAMBRMinPlayers;

            -- Sets the initial scale of the circle
            SCAAMBattleRoyalePropertiesBackup.InitialScale = round(item.Properties.iSCAAMBRInitialScale * math.sqrt(2));
            SCAAMBattleRoyalePropertiesBackup.CurrentScale = round(item.Properties.iSCAAMBRInitialScale * math.sqrt(2));
            SCAAMBattleRoyalePropertiesBackup.CurrentScaleDelta = round(item.Properties.iSCAAMBRInitialScale * math.sqrt(2));

            -- Sets the % the scale of the circle is being reduced per phase, phase 6 always have a fixed scale
            SCAAMBattleRoyalePropertiesBackup['Phase1'].NewScale = SCAAMBattleRoyalePropertiesBackup.InitialScale * item.Properties.SCAAMBRScaleReduction.fPhase1;
            SCAAMBattleRoyalePropertiesBackup['Phase2'].NewScale = SCAAMBattleRoyalePropertiesBackup.InitialScale * item.Properties.SCAAMBRScaleReduction.fPhase2;
            SCAAMBattleRoyalePropertiesBackup['Phase3'].NewScale = SCAAMBattleRoyalePropertiesBackup.InitialScale * item.Properties.SCAAMBRScaleReduction.fPhase3;
            SCAAMBattleRoyalePropertiesBackup['Phase4'].NewScale = SCAAMBattleRoyalePropertiesBackup.InitialScale * item.Properties.SCAAMBRScaleReduction.fPhase4;
            SCAAMBattleRoyalePropertiesBackup['Phase5'].NewScale = SCAAMBattleRoyalePropertiesBackup.InitialScale * item.Properties.SCAAMBRScaleReduction.fPhase5;
            SCAAMBattleRoyalePropertiesBackup['Phase6'].NewScale = 10;

            -- Sets the cooldown for each phase, this is the time before the circle starts to shrink
            SCAAMBattleRoyalePropertiesBackup['Phase1'].CooldownTime = item.Properties.SCAAMBRCooldownTime.iPhase1;
            SCAAMBattleRoyalePropertiesBackup['Phase2'].CooldownTime = item.Properties.SCAAMBRCooldownTime.iPhase2;
            SCAAMBattleRoyalePropertiesBackup['Phase3'].CooldownTime = item.Properties.SCAAMBRCooldownTime.iPhase3;
            SCAAMBattleRoyalePropertiesBackup['Phase4'].CooldownTime = item.Properties.SCAAMBRCooldownTime.iPhase4;
            SCAAMBattleRoyalePropertiesBackup['Phase5'].CooldownTime = item.Properties.SCAAMBRCooldownTime.iPhase5;
            SCAAMBattleRoyalePropertiesBackup['Phase6'].CooldownTime = item.Properties.SCAAMBRCooldownTime.iPhase6;

            -- Sets the circle shrinking time for each phase, this is the time it takes for the circle to shrink
            -- to the desired scale
            SCAAMBattleRoyalePropertiesBackup['Phase1'].CircleShrinkTime = item.Properties.SCAAMBRCircleShrinkTime.iPhase1;
            SCAAMBattleRoyalePropertiesBackup['Phase2'].CircleShrinkTime = item.Properties.SCAAMBRCircleShrinkTime.iPhase2;
            SCAAMBattleRoyalePropertiesBackup['Phase3'].CircleShrinkTime = item.Properties.SCAAMBRCircleShrinkTime.iPhase3;
            SCAAMBattleRoyalePropertiesBackup['Phase4'].CircleShrinkTime = item.Properties.SCAAMBRCircleShrinkTime.iPhase4;
            SCAAMBattleRoyalePropertiesBackup['Phase5'].CircleShrinkTime = item.Properties.SCAAMBRCircleShrinkTime.iPhase5;
            SCAAMBattleRoyalePropertiesBackup['Phase6'].CircleShrinkTime = item.Properties.SCAAMBRCircleShrinkTime.iPhase6;

            -- Gets the generated tables from the properties entity and merges the info to the original data
            local generatedSpawnTables = SCAAMBRFillSpawners(item.Properties.SCAAMBRItemCategories);
            local generatedCrateProperties = generatedSpawnTables[1];
            local generatedGroundProperties = generatedSpawnTables[2];
            SCAAMBRSpecialMerge(SCAAMBRCrateProperties.RandomContent, generatedCrateProperties, true);
            SCAAMBRSpecialMerge(SCAAMBRGroundItemsProperties.RandomContent, generatedGroundProperties, true);

            -- Calls the cleanup function to fill the cleanup table
            SCAAMBRFillCleanupTable();

            System.RemoveEntity(item.id);
            break;
        end
    end

    -- Finds the circle spawn then it despawns it
    if (mapCircle ~= nil and type(mapCircle) == 'table' and table.getn(mapCircle) > 0) then
        for key, item in pairs(mapCircle) do

            -- Sets the circle spawn position in the map, generally at the center of it
            SCAAMBattleRoyalePropertiesBackup.CircleSpawnPosition = item:GetWorldPos();

            -- Gets the map boundaries
            SCAAMBattleRoyalePropertiesBackup.boundaryMinX = item.Properties.fSCAAMBRMinX;
            SCAAMBattleRoyalePropertiesBackup.boundaryMinY = item.Properties.fSCAAMBRMinY;
            SCAAMBattleRoyalePropertiesBackup.boundaryMaxX = item.Properties.fSCAAMBRMaxX;
            SCAAMBattleRoyalePropertiesBackup.boundaryMaxY = item.Properties.fSCAAMBRMaxY;

            System.RemoveEntity(item.id);
            break;
        end
    end

    -- Loops through the list of all the crates to get their position and direction, then despawn them
    if (listOfCrates ~= nil and type(listOfCrates) == 'table' and table.getn(listOfCrates) > 0) then
        for key, item in pairs(listOfCrates) do
            local crateData = {
                Position = item:GetWorldPos(),
                Direction = item:GetDirectionVector()
            };
            table.insert(cratePositions, crateData);
            System.RemoveEntity(item.id);
        end
        
        -- Checks if the table has something, otherwise just use the default spawner values
        if (table.getn(cratePositions) > 0) then
            SCAAMBRCrateProperties.Positions = cratePositions;
        end
    end
    
    -- Loops through the list of all the ground spawns to get their position and direction, then despawn them
    if (listOfGround ~= nil and type(listOfGround) == 'table' and table.getn(listOfGround) > 0) then
        for key, item in pairs(listOfGround) do
            local groundData = {
                Position = item:GetWorldPos()
            };
            table.insert(groundPositions, groundData)
            System.RemoveEntity(item.id);
        end
    
        -- Checks if the table has something, otherwise just use the default spawner values
        if (table.getn(groundPositions) > 0) then
            SCAAMBRGroundItemsProperties.Positions = groundPositions;
        end
    end

    -- Loops through the list of all the lobby spawns to get their position, then despawn them
    if (listOfLobby ~= nil and type(listOfLobby) == 'table' and table.getn(listOfLobby) > 0) then
        for key, item in pairs(listOfLobby) do
            local lobbyData = {
                Position = item:GetWorldPos()
            };
            table.insert(lobbyPositions, lobbyData);
            System.RemoveEntity(item.id);
        end
        
        -- Checks if the table has something, otherwise just use the default spawner values
        if (table.getn(lobbyPositions) > 0) then
            SCAAMBRLobbyProperties.Positions = lobbyPositions;
        end
    end

    -- Loops through the list of all the main spawns to get their position for the UI map, then despawn them
    if (listOfMainPos ~= nil and type(listOfMainPos) == 'table' and table.getn(listOfMainPos) > 0) then
        for key, item in pairs(listOfMainPos) do

            -- Checks if the location property was set, , otherwise it won't use this spawner location at all
            if (item.Properties.sSCAAMBRLocationName and item.Properties.sSCAAMBRLocationName ~= '') then
                mainPositions[item.Properties.sSCAAMBRLocationName] = {
                    Main = item:GetWorldPos(),
                    Positions = {}
                };
            end

            System.RemoveEntity(item.id);
        end
        
        -- Checks if the table has something, otherwise just use the default spawner values
        if (mainPositions ~= {}) then
            SCAAMBRPlayerProperties.Positions = mainPositions;
            SCAAMBRSpawnLocations = {};
            
            for key, mainLocation in pairs(mainPositions) do
                table.insert(SCAAMBRSpawnLocations, key);
            end
        end
    end

    -- Loops through the list of all the player spawns to get their position, then despawn them
    if (listOfPlayerPos ~= nil and type(listOfPlayerPos) == 'table' and table.getn(listOfPlayerPos) > 0) then
        if (table.getn(listOfPlayerPos) > 0) then
            for key, item in pairs(listOfPlayerPos) do

                -- Checks if the location property was set, otherwise it won't use this spawner's position
                if (item.Properties.sSCAAMBRLocationName and item.Properties.sSCAAMBRLocationName ~= '') then
                    local playerPosPosition = {
                        Position = item:GetWorldPos()
                    };

                    -- Checks if the location exists, it should if it was set with the main spawners
                    if (SCAAMBRPlayerProperties.Positions[item.Properties.sSCAAMBRLocationName]) then
                        table.insert(SCAAMBRPlayerProperties.Positions[item.Properties.sSCAAMBRLocationName].Positions, playerPosPosition);
                    end
                end

                System.RemoveEntity(item.id);
            end
        end
    end

    SCAAMBattleRoyaleProperties = SCAAMBRShallowCopy(SCAAMBattleRoyalePropertiesBackup);
end

-- SCAAMBRInitGame
-- Initializes a battle royale game
function SCAAMBRInitGame(circleId)

    -- Init or resets the game properties for the next game
    SCAAMBattleRoyaleProperties = SCAAMBRShallowCopy(SCAAMBattleRoyalePropertiesBackup);
    SCAAMBattleRoyaleProperties.circleId = circleId;

    -- Prepare the circle entity for the initial phase
    circle = System.GetEntity(circleId);
    Script.SetTimerForFunction(500, 'SCAAMBRSetInitialCircleScale', circle);

    -- Set the random circle posisions per phase
    SCAAMBRDecidePhasePositions(circle);

    -- Set the parameters for the airdrops
    SCAAMBRDecideAirdropTimers();

    -- Increases the game counter by 1
    SCAAMBRGameNumber = SCAAMBRGameNumber + 1;

    -- Spawn the dummy circle to indicate the safe zone for the first phase
    local spawnedDummy = ISM.SpawnItem('SCAAMBattleRoyaleCircleDummy', SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].Position);
    spawnedDummy.allClients:SCAAMSetScale(tostring(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].NewScale));
    SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].DummyCircleId = spawnedDummy.id;

    -- Sets the map locations in a simplified tables
    local mapLocations = {};

    for key, location in pairs(SCAAMBRPlayerProperties.Positions) do
        local mapLocation = {};
        table.insert(mapLocation, key);
        table.insert(mapLocation, {Position = location.Main});

        -- Inserts the data in the simplified table
        table.insert(mapLocations, mapLocation);
    end
    
    -- Gets all the position data to initialize the map UI
    local indicatorsData = {
        Circle = {
            Position = circle:GetWorldPos(),
            Scale = SCAAMBattleRoyaleProperties.CurrentScale
        },
        SafeZone = {
            Position = spawnedDummy:GetWorldPos(),
            Scale = SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].NewScale
        },
        MapScale = SCAAMBattleRoyaleProperties.MapSize,
        MapLocations = mapLocations
    };

    -- Gives all the players the state of Ready
    local listOfPlayers = CryAction.GetPlayerList();
    local playersPlaying = 0;
    local playerPositionsCopy = new(SCAAMBRPlayerProperties.Positions);
    local playingPlayerEntities = {};

    for key, player in pairs(listOfPlayers) do
        table.insert(playingPlayerEntities, player);

        -- Checks if the player has the Ready state meaning it is prepared to play
        -- This to prevent including players that just joined and didn't have enough time to be initialized
        if (player.SCAAMBRState == 'Ready') then
            playersPlaying = playersPlaying + 1;
            player.SCAAMBRState = 'Playing'
            player.SCAAMBRArmor = 0;
            player.SCAAMBRKills = 0;
            player.SCAAMBRDamageDealt = 0;
            player.player:SetFood(1500);
            player.player:SetWater(1750);
            player.actor:SetMaxHealth(100);
            player.player:SetHealth(100);
            player.player:SetBleedingLevel(0);
            player.player:SetTorpidity(0);
            player.player:SetRadiation(0);
            player.player:SetPoisonType('');

            -- Sets the player basic equipment
            SCAAMBRGivePlayerInitialEquipment(player.id);

            -- Teleports the player to the location selected, if no location was set it's gonna be a random one around the entire map
            if (player.SCAAMBRSpawnPoint ~= nil) then
                local spawnLocations = playerPositionsCopy[player.SCAAMBRSpawnPoint].Positions;
                local randomLocationPosition = table.remove(spawnLocations, math.random(table.getn(spawnLocations)));
                player.player:TeleportTo(randomLocationPosition.Position);
            else
                local spawnLocations = playerPositionsCopy[SCAAMBRSpawnLocations[math.random(table.getn(SCAAMBRSpawnLocations))]].Positions;
                local randomLocationPosition = table.remove(spawnLocations, math.random(table.getn(spawnLocations)));
                player.player:TeleportTo(randomLocationPosition.Position);
            end

            -- Sets the player initial position on the table
            -- Gets all the position data to initialize the map UI
            local playerAngles = player:GetAngles();

            indicatorsData.Player = {
                Position = player:GetWorldPos(),
                Rotation = playerAngles.z * 180/g_Pi
            };

            -- Toggles on the BR UI
            local playerChannel = player.actor:GetChannel();
            player.onClient:SCAAMBRChangeTheStates(playerChannel, 'gotogame', SCAAMBRJSON.stringify(indicatorsData));
        end
    end

    -- Creates the stats table for this game
    SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)] = {
        Winner = '',
        PlayerCount = playersPlaying,
        TotalTime = 0,
        Scoreboard = {}
    };

    -- Sets the player counter to the amount of players joining this game
    SCAAMBattleRoyaleProperties.CurrentPlayers = playersPlaying;

    -- Updates the player count on all players after a delay+
    local UIData = {
        PlayingPlayerEntities = playingPlayerEntities,
        PlayersPlaying = playersPlaying
    };

    Script.SetTimerForFunction(1000, 'SCAAMBRUpdateStatsUIAfterDelay', UIData);

    -- Starts the game updater
    SCAAMBattleRoyaleProperties.GameState = 'Active';
    SCAAMBRStartCircleCounter(circle);

    -- Editor or server specific actions
    if (System.IsEditor()) then
        g_gameRules.game:SendTextMessage(0, g_localActorId, 'Circle will start closing in ' .. tostring(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CooldownTime) .. ' seconds');
    else
        g_gameRules.game:SendTextMessage(0, 0, 'Circle will start closing in ' .. tostring(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CooldownTime) .. ' seconds');
    end
end

-- SCAAMBRUpdateStatsUIAfterDelay
-- Updates the player count after a delay, this to ensure the UI is in the frame before the function
-- gets called
function SCAAMBRUpdateStatsUIAfterDelay(data)
    for key, player in pairs(data.PlayingPlayerEntities) do
        local playerChannel = player.actor:GetChannel();
        player.onClient:SCAAMBRChangeTheStates(playerChannel, 'setplayercounter', tostring(data.PlayersPlaying));
    end
end

-- SCAAMBRSetInitialCircleScale
-- Sets the initial circle scale after a delay
function SCAAMBRSetInitialCircleScale(circle)
    circle:SetWorldScale(SCAAMBattleRoyaleProperties.CurrentScale);
    circle.allClients:SCAAMSetScale(tostring(SCAAMBattleRoyaleProperties.CurrentScale));
end

-- SCAAMBRGivePlayerInitialEquipment
-- Gives the initial basic equipment to players
function SCAAMBRGivePlayerInitialEquipment(playerId)
    local player = System.GetEntity(playerId);

    -- Gets the player position and changes the z coord so the items spawn below them
    local playerPos = player:GetWorldPos();
    playerPos.z = playerPos.z - 20;
    local currentItemClass = '';
    
    -- Default clothing, you can notice this is a copy and paste from the BattleRoyale.lua file lul
    local rnd = random(3);

    -- Feet
    if (rnd == 1) then
        currentItemClass = 'TennisShoes';
    elseif (rnd == 2) then
        currentItemClass = 'Sneakers';
    else
        currentItemClass = 'CanvasShoes';
    end

    -- Method to potentially fix the naked issue
    local item = ISM.SpawnItem(currentItemClass, playerPos);
    player.actor:PickUpItem(item.id);

    -- Legs
    rnd = random(4);

    if (rnd == 1) then
        currentItemClass = 'BlueJeans';
    elseif (rnd == 2) then
        currentItemClass = 'BlueJeans2';
    elseif (rnd == 3) then
        currentItemClass = 'BlueJeans2Brown';
    else
        currentItemClass = 'BlueJeans2Green';
    end

    item = ISM.SpawnItem(currentItemClass, playerPos);
    player.actor:PickUpItem(item.id);

    -- Torso
    rnd = random(6);

    if (rnd == 1) then
        currentItemClass = 'TshirtNoImageBlack';
    elseif (rnd == 2) then
        currentItemClass = 'TshirtNoImageBlue';
    elseif (rnd == 3) then
        currentItemClass = 'TshirtNoImageGreen';
    elseif (rnd == 4) then
        currentItemClass = 'TshirtNoImageGrey';
    elseif (rnd == 5) then
        currentItemClass = 'TshirtNoImagePink';
    else
        currentItemClass = 'TshirtNoImageRed';
    end

    item = ISM.SpawnItem(currentItemClass, playerPos);
    player.actor:PickUpItem(item.id);

    -- Bandages
    local bandage = ISM.GiveItem(playerId, 'Bandage');
    bandage.item:SetStackCount(15);
end

-- SCAAMBRDecidePhasePositions
-- Set the position for the safe zone per phase
function SCAAMBRDecidePhasePositions(circle)
    local currentPhase = 1;
    local currentCirclePosition = SCAAMBRShallowCopy(circle:GetWorldPos());
    local currentScaleToShrink = SCAAMBattleRoyaleProperties.CurrentScale;

    -- Gets the map boundaries giving a little bit of headroom (5%)
    local minX = SCAAMBattleRoyaleProperties.boundaryMinX * 1.05;
    local minY = SCAAMBattleRoyaleProperties.boundaryMinY * 1.05;
    local maxX = SCAAMBattleRoyaleProperties.boundaryMaxX * 0.95;
    local maxY = SCAAMBattleRoyaleProperties.boundaryMaxY * 0.95;

    while (currentPhase <= SCAAMBattleRoyaleProperties.GamePhases) do

        -- Gets the calculation of the current scale minus the next scale so the difference is used to position the safe zone in an area inside it's previous bigger safe zone
        local scaleToShrink = currentScaleToShrink - SCAAMBattleRoyaleProperties['Phase' .. tostring(currentPhase)].NewScale;

        -- Copies the current circle position to perform the operations for the next circle
        local circlePositionToEdit = SCAAMBRShallowCopy(currentCirclePosition);
        local randomChangeX = randomF((scaleToShrink * -1), scaleToShrink);
        local randomChangeY = randomF((scaleToShrink * -1), scaleToShrink);

        -- Sets the position based on the boundaries so the circle doesn't go outside the map
        circlePositionToEdit.x = circlePositionToEdit.x + randomChangeX;
        circlePositionToEdit.y = circlePositionToEdit.y + randomChangeY;

        if (circlePositionToEdit.x < minX) then
            circlePositionToEdit.x = minX;
        end

        if (circlePositionToEdit.x > maxX) then
            circlePositionToEdit.x = maxX;
        end

        if (circlePositionToEdit.y < minY) then
            circlePositionToEdit.y = minY;
        end

        if (circlePositionToEdit.y > maxY) then
            circlePositionToEdit.y = maxY;
        end
        
        -- Starts to set the new position to the circle
        local moveToDirection = {x=0, y=0, z=0};
        local sumVectors = {x=0, y=0, z=0};
        local moveToPosition = {x=0, y=0, z=0};

        SubVectors(moveToDirection, circlePositionToEdit, currentCirclePosition);
        NormalizeVector(moveToDirection);
        FastScaleVector(sumVectors, moveToDirection, randomF(0.0, scaleToShrink));
        FastSumVectors(moveToPosition, sumVectors, currentCirclePosition);

        -- Gets the distance between vectors for further calculations between phases (like the rate the circle is shrinking)
        local distanceBetweenVectors = DistanceVectors(currentCirclePosition, moveToPosition);
        SCAAMBattleRoyaleProperties['Phase' .. tostring(currentPhase)].Position = moveToPosition;
        SCAAMBattleRoyaleProperties['Phase' .. tostring(currentPhase)].DistanceBetweenVectors = distanceBetweenVectors;

        -- Prepares for the next loop
        currentCirclePosition = moveToPosition;
        currentScaleToShrink = SCAAMBattleRoyaleProperties['Phase' .. tostring(currentPhase)].NewScale;
        currentPhase = currentPhase + 1;
    end
end

-- SCAAMBRDecideAirdropTimers
-- Set the timers for the airdrops, it's going to be 3 airdrops total per game
function SCAAMBRDecideAirdropTimers()

    -- Getting almost a total game time, last phase doesn't count to prevent the change of spawning
    -- a crate right when the last phase is about to end
    local timersSum = 0

    for currentPhase = 1, (SCAAMBattleRoyaleProperties.GamePhases - 1), 1 do
        timersSum = timersSum + SCAAMBattleRoyaleProperties['Phase' .. tostring(currentPhase)].CooldownTime + SCAAMBattleRoyaleProperties['Phase' .. tostring(currentPhase)].CircleShrinkTime;
    end

    local invertedTime = 1;
    local previousTime = 0;

    -- Sets random timers in 3 different key times obtained by dividing the total time by half the game phases
    for currentTime = (math.ceil(SCAAMBattleRoyaleProperties.GamePhases / 2)), 1, -1 do
        local airdropPhaseMaxTime = math.floor(timersSum / currentTime);

        -- If it's the first airdrop try to get as far from the first moments of the game, otherwise
        -- it's gonna possibly spawn it right after the previous airdrop
        if (invertedTime == 1) then
            SCAAMBattleRoyaleProperties.Airdrops['Airdrop' .. tostring(invertedTime)] = math.random(math.ceil(airdropPhaseMaxTime / 2), airdropPhaseMaxTime);
        else
            SCAAMBattleRoyaleProperties.Airdrops['Airdrop' .. tostring(invertedTime)] = math.random(previousTime, airdropPhaseMaxTime);
        end

        previousTime = airdropPhaseMaxTime;
        invertedTime = invertedTime + 1;
    end
end

-- SCAAMBRSpawnGameItems
-- Spawns the items for the game in random selected positions
function SCAAMBRSpawnGameItems()
  
    -- Gets the count of the 50% of the total possible positions, so there's gonna be places that will have spawns
    -- and some places that don't in a random behaviour
    local cratePositionsFractionCount = math.floor(table.getn(SCAAMBRCrateProperties.Positions) * randomF(0.5, 0.6));
    local groundPositionsFractionCount = math.floor(table.getn(SCAAMBRGroundItemsProperties.Positions) * randomF(0.3, 0.5));
    
    -- Makes a copy of the positions of the item tables
    local cratePositionsCopy = SCAAMBRShallowCopy(SCAAMBRCrateProperties.Positions);
    local groundItemsPositionsCopy = SCAAMBRShallowCopy(SCAAMBRGroundItemsProperties.Positions);

    -- Loops through the crate count to spawn a crate
    while (cratePositionsFractionCount > 0) do
        local spawner = table.remove(cratePositionsCopy, math.random(table.getn(cratePositionsCopy)));
        local crate = ISM.SpawnItem('SCAAMBattleRoyaleCrate', spawner.Position);
        crate:SetDirectionVector(spawner.Direction);
        cratePositionsFractionCount = cratePositionsFractionCount - 1;
    end

    local randomTableOriginal = {'RandomPrimaryWeapon', 'RandomProtection', 'RandomAmmo', 'RandomSecondaryWeapon', 'RandomUtilitary', 'RandomAmmo', 'RandomStorage', 'RandomSecondaryWeapon', 'RandomProtection', 'RandomSecondaryWeapon', 'RandomAmmo'};
    local randomTables = SCAAMBRShallowCopy(randomTableOriginal);

    -- Loops through the ground items count to spawn low tier items
    while (groundPositionsFractionCount > 0) do
        local spawner = table.remove(groundItemsPositionsCopy, math.random(table.getn(groundItemsPositionsCopy)));
        local randomItemsPerLocation = math.random(2);

        -- extraRandom exists because the chance of getting Armor or Stim packs may be too low to this adds an 'extra' category to get them in an equal chance
        local extraRandom = 1;
        local totalContent = {};

        -- Loops through the random item classes to fill the spawner
        while (randomItemsPerLocation > 0) do
            local randomContent = math.random(table.getn(randomTables) + extraRandom);

            if (randomTables[randomContent] ~= nil) then
                local removedContent = table.remove(randomTables, randomContent);
                local removeOtherContent = '';

                -- If the random content is a primary weapon it removes the secondary weapon content and viceversa so the ground
                -- doesn't suddenly spawns 2 guns
                -- if (removedContent == 'RandomPrimaryWeapon') then
                --     removeOtherContent = 'RandomSecondaryWeapon';
                -- elseif (removedContent == 'RandomSecondaryWeapon') then
                --     removeOtherContent = 'RandomPrimaryWeapon';
                -- end

                -- Loops through the content table to remove one
                if (removeOtherContent ~= '') then
                    for key, content in pairs(randomTables) do
                        if (content == removeOtherContent) then
                            table.remove(randomTables, key);
                            break;
                        end
                    end
                end

                local returnedContent = SCAAMBRGetRandomGroundContent(removedContent, randomItemsPerLocation);

                for key, item in pairs(returnedContent) do
                    table.insert(totalContent, item);

                    randomItemsPerLocation = randomItemsPerLocation - 1;
                end

                -- Checks if the random table cloned has ran out of categories so it's cloned once again
                if (table.getn(randomTables) == 0) then
                    randomTables = SCAAMBRShallowCopy(randomTableOriginal);
                end
            else

                -- Adds a special item
                local randomSpecial = math.random(100);
                if (randomSpecial < 50) then
                    table.insert(totalContent, 'SCAAMArmor');
                else
                    table.insert(totalContent, 'SCAAMStimPack');
                end

                randomItemsPerLocation = randomItemsPerLocation - 1;
                extraRandom = 0;
            end
        end

        -- If the content is just 1 item it just spawns it in the position, otherwise it's gonna spawn
        -- the items around the position
        -- this is prepared to spawn a max of 5 items only, if higher this content is ignored
        if (table.getn(totalContent) == 1) then

            -- Correcting the z position of the crate so the items don't spawn sinking on the ground
            local correctedZCratePos = SCAAMBRShallowCopy(spawner.Position);
            correctedZCratePos.z = correctedZCratePos.z + 0.1;

            ISM.SpawnItem(totalContent[1], correctedZCratePos);
        elseif (table.getn(totalContent) <= 5) then
            local contentCycle = 1;
            local itemPosition = {x=0, y=0, z=0};
            local itemRotation = {x=0, y=0, z=0};

            for key, item in pairs(totalContent) do

                -- Checks if it's spawning the first item to spawn it to the position, otherwise
                -- spawns the content to the left of the most recent spawned item
                if (contentCycle == 1) then

                    -- Correcting the z position of the crate so the items don't spawn sinking on the ground
                    itemPosition = SCAAMBRShallowCopy(spawner.Position);
                    itemPosition.z = itemPosition.z + 0.1;
                    
                    local spawnedItem = ISM.SpawnItem(item, itemPosition);
                    itemRotation = spawnedItem:GetDirectionVector();
                else
                    local vForwardOffset = {x=0, y=0, z=0};
                    local vSpawnPos = {x=0, y=0, z=0};
                    VecRotateMinus90_Z(itemRotation);

                    -- Gets the position of the first spawned item, then rotates it's direction -90 degrees, then
                    -- moves it 0.25 units
                    FastScaleVector(vForwardOffset, itemRotation, 0.25);
                    FastSumVectors(vSpawnPos, vForwardOffset, itemPosition);
                    
                    ISM.SpawnItem(item, vSpawnPos);
                end

                contentCycle = contentCycle + 1;
            end
        end
        
        groundPositionsFractionCount = groundPositionsFractionCount - 1;
    end
end

-- SCAAMBRGetRandomGroundContent
-- Returns content depending on the type of content required
function SCAAMBRGetRandomGroundContent(randomTable, remainingSlots)
    local totalContent = {};

    if (randomTable == 'RandomPrimaryWeapon' and remainingSlots > 1) then

        -- Grabs a random primary item from the ground spawners table
        local contentPrimary = SCAAMBRGroundItemsProperties.RandomContent.RandomPrimaryWeapon[math.random(table.getn(SCAAMBRGroundItemsProperties.RandomContent.RandomPrimaryWeapon))];
        table.insert(totalContent, contentPrimary.Item);
        remainingSlots = remainingSlots - 1;

        -- Checks if the item is a gun that requires ammo to add it to the content
        if (contentPrimary.Ammo and contentPrimary.Ammo ~= '') then
            local ammoList = SCAAMBRSplitToTable(contentPrimary.Ammo, ',');
            local randomAmmo = math.random(table.getn(ammoList));

            -- Checks is the random index obtained returns an element
            if (ammoList[randomAmmo] ~= nil) then
                table.insert(totalContent, ammoList[randomAmmo]);
            end
        end
        remainingSlots = remainingSlots - 1;

        -- Checks if there's still slots to add attachments
        if (remainingSlots > 0) then

            -- Checks if there's still slots to add items
            -- Checks if the item has attachments and decides if spawning one or not
            if (contentPrimary.Attachment1 and contentPrimary.Attachment1 ~= '') then
                local attachmentList = SCAAMBRSplitToTable(contentPrimary.Attachment1, ',');
                local randomAttachment = math.random(table.getn(attachmentList) + math.ceil(table.getn(attachmentList) / 2));

                -- Checks is the random index obtained returns an element
                if (attachmentList[randomAttachment] ~= nil) then
                    table.insert(totalContent, attachmentList[randomAttachment]);
                end
            end
        end
        remainingSlots = remainingSlots - 1;

        if (remainingSlots > 0) then
            if (contentPrimary.Attachment2 and contentPrimary.Attachment2 ~= '') then
                local attachmentList = SCAAMBRSplitToTable(contentPrimary.Attachment2, ',');
                local randomAttachment = math.random(table.getn(attachmentList) + math.ceil(table.getn(attachmentList) / 2));

                -- Checks is the random index obtained returns an element
                if (attachmentList[randomAttachment] ~= nil) then
                    table.insert(totalContent, attachmentList[randomAttachment]);
                end
            end
        end
    elseif (randomTable == 'RandomSecondaryWeapon' and remainingSlots > 1) then

        -- Grabs a random secondary item from the ground spawners table
        local contentSecondary = SCAAMBRGroundItemsProperties.RandomContent.RandomSecondaryWeapon[math.random(table.getn(SCAAMBRGroundItemsProperties.RandomContent.RandomSecondaryWeapon))];
        table.insert(totalContent, contentSecondary.Item);
        remainingSlots = remainingSlots - 1;

        -- Checks if the item is a gun that requires ammo to add it to the content
        if (contentSecondary.Ammo and contentSecondary.Ammo ~= '') then
            local ammoList = SCAAMBRSplitToTable(contentSecondary.Ammo, ',');
            local randomAmmo = math.random(table.getn(ammoList));

            -- Checks is the random index obtained returns an element
            if (ammoList[randomAmmo] ~= nil) then
                table.insert(totalContent, ammoList[randomAmmo]);
            end
        end
        remainingSlots = remainingSlots - 1;

        -- Checks if there's still slots to add attachments
        if (remainingSlots > 0) then
            -- Checks if the item has attachments and decides if spawning one or not
            if (contentSecondary.Attachment1 and contentSecondary.Attachment1 ~= '') then
                local attachmentList = SCAAMBRSplitToTable(contentSecondary.Attachment1, ',');
                local randomAttachment = math.random(table.getn(attachmentList) + math.ceil(table.getn(attachmentList) / 2));

                -- Checks is the random index obtained returns an element
                if (attachmentList[randomAttachment] ~= nil) then
                    table.insert(totalContent, attachmentList[randomAttachment]);
                end
            end
        end
        remainingSlots = remainingSlots - 1;

        if (remainingSlots > 0) then
            if (contentSecondary.Attachment2 and contentSecondary.Attachment2 ~= '') then
                local attachmentList = SCAAMBRSplitToTable(contentSecondary.Attachment2, ',');
                local randomAttachment = math.random(table.getn(attachmentList) + math.ceil(table.getn(attachmentList) / 2));
        
                -- Checks is the random index obtained returns an element
                if (attachmentList[randomAttachment] ~= nil) then
                    table.insert(totalContent, attachmentList[randomAttachment]);
                end
            end
        end
    elseif (randomTable == 'RandomUtilitary') then

        -- Grabs a random ammo item from the ground spawners table
        local contentAmmo = SCAAMBRGroundItemsProperties.RandomContent.RandomAmmo[math.random(table.getn(SCAAMBRGroundItemsProperties.RandomContent.RandomAmmo))];
        table.insert(totalContent, contentAmmo.Item);
    elseif (randomTable == 'RandomUtilitary') then

        -- Grabs a random utilitary item from the ground spawners table
        local contentUtilitary = SCAAMBRGroundItemsProperties.RandomContent.RandomUtilitary[math.random(table.getn(SCAAMBRGroundItemsProperties.RandomContent.RandomUtilitary))];
        table.insert(totalContent, contentUtilitary.Item);
    elseif (randomTable == 'RandomStorage') then

        -- Grabs a random storage item from the ground spawners table
        local contentStorage = SCAAMBRGroundItemsProperties.RandomContent.RandomStorage[math.random(table.getn(SCAAMBRGroundItemsProperties.RandomContent.RandomStorage))];
        table.insert(totalContent, contentStorage.Item);
    elseif (randomTable == 'RandomProtection') then

        -- Grabs a random protection item from the ground spawners table
        local contentProtection = SCAAMBRGroundItemsProperties.RandomContent.RandomProtection[math.random(table.getn(SCAAMBRGroundItemsProperties.RandomContent.RandomProtection))];
        table.insert(totalContent, contentProtection.Item);
    end

    return totalContent;
end


-- SCAAMBRCleanGameMap
-- Removes all the items and crates spawned in this game, even the ones equipped by the winner
function SCAAMBRCleanGameMap()

    -- Loops through the list of all potential item classnames to remove them
    for key, item in pairs(SCAAMBRItemClasses) do
        local listOfItems = System.GetEntitiesByClass(item);

        if (listOfItems ~= nil) then
            for key2, item2 in pairs(listOfItems) do
                System.RemoveEntity(item2.id);
            end
        end
    end

    -- Loops through the list of all potential entity classnames to remove them
    for key, entity in pairs(SCAAMBREntityClasses) do
        local listOfEntities = System.GetEntitiesByClass(entity);

        for key2, entity2 in pairs(listOfEntities) do
            System.RemoveEntity(entity2.id);
        end
    end
end

-- SCAAMBRCleanPlayer
-- Removes all the items the player may potentially have
function SCAAMBRCleanPlayer(playerId)
    local player = System.GetEntity(playerId);

    -- Sets the max health to an unkillable value, this to prevent players getting
    -- killed in the lobby area
    player.actor:SetMaxHealth(9000);
    player.player:SetHealth(9000);

    -- Resets all the vanilla stat values
    player.player:SetFood(1500);
    player.player:SetWater(1750);
    player.player:SetBleedingLevel(0);
    player.player:SetTorpidity(0);
    player.player:SetRadiation(0);
    player.player:SetPoisonType('');

    local listOfPlayerItems = g_gameRules.game:GetStorageContent(playerId, '');

    -- Loops through the list of all potential item classnames to remove them
    for key, item in pairs(listOfPlayerItems) do
        local itemEntity = System.GetEntity(item);

        -- This check is done because apparently the function returns a NoWeapon entity which is basically
        -- the fists to be able to punch and kick, you don't want to remove that
        if (itemEntity.class and itemEntity.class ~= 'NoWeapon') then
            System.RemoveEntity(item);
        end
    end

    -- Toggles on the BR UI
    local playerChannel = player.actor:GetChannel();
    player.onClient:SCAAMBRToggleUI(playerChannel, 'initial', true);

    -- Teleports the player to the lobby zone
    player.player:TeleportTo(SCAAMBRLobbyProperties.Positions[math.random(table.getn(SCAAMBRLobbyProperties.Positions))].Position);
end

-- SCAAMBRCleanPlayerAfterDelay
-- Calls the clean player function after a delay of 15 seconds, this to ensure the player
-- was fully loaded so the inventory can be reached
function SCAAMBRCleanPlayerAfterDelay(playerData)
    SCAAMBRCleanPlayer(playerData.PlayerId);
end

-- SCAAMBROpenCrate
-- Opens a crate to spawn it's content and replace the model with an opened crate
function SCAAMBROpenCrate(crateId)
    local crate = System.GetEntity(crateId);
    local totalContent = {};
    
    -- Grabs a random primary item from the crate spawners table
    local contentPrimary = SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomPrimaryWeapon[math.random(table.getn(SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomPrimaryWeapon))];
    table.insert(totalContent, contentPrimary.Item);

    -- Checks if the item is a gun that requires ammo to add it to the content
    if (contentPrimary.Ammo and contentPrimary.Ammo ~= '') then
        local ammoList = SCAAMBRSplitToTable(contentPrimary.Ammo, ',');
        local randomAmmo = math.random(table.getn(ammoList));

        -- Checks is the random index obtained returns an element
        if (ammoList[randomAmmo] ~= nil) then
            table.insert(totalContent, ammoList[randomAmmo]);
        end
    end

    -- Checks if the item has attachments and decides if spawning one or not
    if (contentPrimary.Attachment1 and contentPrimary.Attachment1 ~= '') then
        local attachmentList = SCAAMBRSplitToTable(contentPrimary.Attachment1, ',');
        local randomAttachment = math.random(table.getn(attachmentList) + 2 + SCAAMBattleRoyaleProperties.GamePhases - SCAAMBattleRoyaleProperties.CurrentPhase);

        -- Checks is the random index obtained returns an element
        if (attachmentList[randomAttachment] ~= nil) then
            table.insert(totalContent, attachmentList[randomAttachment]);
        end
    end

    if (contentPrimary.Attachment2 and contentPrimary.Attachment2 ~= '') then
        local attachmentList = SCAAMBRSplitToTable(contentPrimary.Attachment2, ',');
        local randomAttachment = math.random(table.getn(attachmentList) + 2 + SCAAMBattleRoyaleProperties.GamePhases - SCAAMBattleRoyaleProperties.CurrentPhase);

        -- Checks is the random index obtained returns an element
        if (attachmentList[randomAttachment] ~= nil) then
            table.insert(totalContent, attachmentList[randomAttachment]);
        end
    end

    -- Checks if the content is less than 4 items so it compensates by adding another mag
    if (table.getn(totalContent) < 4) then
        if (contentPrimary.Ammo and contentPrimary.Ammo ~= '') then
            local ammoList = SCAAMBRSplitToTable(contentPrimary.Ammo, ',');
            local randomAmmo = math.random(table.getn(ammoList));

            -- Checks is the random index obtained returns an element
            if (ammoList[randomAmmo] ~= nil) then
                table.insert(totalContent, 2, ammoList[randomAmmo]);
            end
        end
    end

    -- Adds a random utilitary item
    local contentUtilitary = SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomUtilitary[math.random(table.getn(SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomUtilitary))];
    table.insert(totalContent, contentUtilitary.Item);

    -- Adds a special item, it doesn't matter if the utilitary item was a special one
    local randomSpecial = math.random(100);
    if (randomSpecial < 50) then
        table.insert(totalContent, 'SCAAMArmor');
    else
        table.insert(totalContent, 'SCAAMStimPack');
    end

    -- Decides if it wants to add a storage item
    local randomStorage = math.random(table.getn(SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomStorage) + 1 + SCAAMBattleRoyaleProperties.GamePhases - SCAAMBattleRoyaleProperties.CurrentPhase);
    if (SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomStorage[randomStorage] ~= nil) then
        table.insert(totalContent, SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomStorage[randomStorage].item);
    end

    -- Decides if it wants to add a protection item
    local randomProtection = math.random(table.getn(SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomProtection) + 1 + SCAAMBattleRoyaleProperties.GamePhases - SCAAMBattleRoyaleProperties.CurrentPhase);
    if (SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomProtection[randomProtection] ~= nil) then
        table.insert(totalContent, SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomProtection[randomProtection].item);
    end

    -- If after adding everything, the content has less than 8 items, it would be a good idea to add a secondary weapon
    if (table.getn(totalContent) < 8) then

        -- Grabs a random secondary item from the crate spawners table
        local contentSecondary = SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomSecondaryWeapon[math.random(table.getn(SCAAMBRCrateProperties.RandomContent['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].RandomSecondaryWeapon))];
        table.insert(totalContent, contentSecondary.Item);

        -- Checks if the item is a gun that requires ammo to add it to the content
        if (contentSecondary.Ammo and contentSecondary.Ammo ~= '') then
            local ammoList = SCAAMBRSplitToTable(contentSecondary.Ammo, ',');
            local randomAmmo = math.random(table.getn(ammoList));

            -- Checks is the random index obtained returns an element
            if (ammoList[randomAmmo] ~= nil) then
                table.insert(totalContent, ammoList[randomAmmo]);
            end
        end

        -- Checks if the item has attachments and decides if spawning one or not
        if (contentSecondary.Attachment1 and contentSecondary.Attachment1 ~= '') then
            local attachmentList = SCAAMBRSplitToTable(contentSecondary.Attachment1, ',');
            local randomAttachment = math.random(table.getn(attachmentList) + 2 + SCAAMBattleRoyaleProperties.GamePhases - SCAAMBattleRoyaleProperties.CurrentPhase);

            -- Checks is the random index obtained returns an element
            if (attachmentList[randomAttachment] ~= nil) then
                table.insert(totalContent, attachmentList[randomAttachment]);
            end
        end

        if (contentSecondary.Attachment2 and contentSecondary.Attachment2 ~= '') then
            local attachmentList = SCAAMBRSplitToTable(contentSecondary.Attachment2, ',');
            local randomAttachment = math.random(table.getn(attachmentList) + 2 + SCAAMBattleRoyaleProperties.GamePhases - SCAAMBattleRoyaleProperties.CurrentPhase);
    
            -- Checks is the random index obtained returns an element
            if (attachmentList[randomAttachment] ~= nil) then
                table.insert(totalContent, attachmentList[randomAttachment]);
            end
        end
    end

    -- Calculates the space that it'll take to spawn all the items around the front of the crate
    local itemsAmount = table.getn(totalContent);
    local evenDistance = (itemsAmount / 2) * 0.25;

    local contentCycle = 1;
    local itemPosition = {x=0, y=0, z=0};
    local itemRotation = {x=0, y=0, z=0};

    -- Cycles through the content to spawn it in front of the crate
    for key, item in pairs(totalContent) do

        -- Checks if it's spawning the first item to spawn it to the leaning to the front-rignt of the crate
        -- otherwise is gonna spawn the content to the left of the most recent spawned item
        if (contentCycle == 1) then

            -- Correcting the z position of the crate so the items don't spawn sinking on the ground
            local correctedZCratePos = crate:GetWorldPos();
            correctedZCratePos.z = correctedZCratePos.z + 0.1;

            local vForwardOffset = {x=0, y=0, z=0};
            local vPreRotationPos = {x=0, y=0, z=0};
            local vRotatedPos = {x=0, y=0, z=0};
            local vRotatedDir = crate:GetDirectionVector();
            VecRotate90_Z(vRotatedDir);
            local vSpawnPos = {x=0, y=0, z=0};
            
            -- Gets the position in front of the crate, then rotates that position 90 degrees, then moves it
            -- to evenDistance calculated, that's the position for the first item
            FastScaleVector(vForwardOffset, crate:GetDirectionVector(), 0.8);
            FastSumVectors(vPreRotationPos, vForwardOffset, correctedZCratePos);
            FastScaleVector(vRotatedPos, vRotatedDir, evenDistance);
            FastSumVectors(vSpawnPos, vRotatedPos, vPreRotationPos);
            itemPosition = vSpawnPos;
            itemRotation = crate:GetDirectionVector();
        else
            local vForwardOffset = {x=0, y=0, z=0};
            local vPreviousItemPos = SCAAMBRShallowCopy(itemPosition);
            local vRotatedDir = SCAAMBRShallowCopy(itemRotation);
            VecRotateMinus90_Z(vRotatedDir);
            local vSpawnPos = {x=0, y=0, z=0};
            
            -- Gets the position of the latest spawned item, then rotates it's direction -90 degrees, then
            -- moves it 0.25 units
            FastScaleVector(vForwardOffset, vRotatedDir, 0.25);
            FastSumVectors(vSpawnPos, vForwardOffset, vPreviousItemPos);
            itemPosition = vSpawnPos;
        end

        local spawnedItem = ISM.SpawnItem(item, itemPosition);
        spawnedItem:SetDirectionVector(itemRotation);

        contentCycle = contentCycle + 1;
    end

    -- Spawns an opened crate in the same position and rotation of the unopened one
    local spawnedOpenCrate = ISM.SpawnItem('SCAAMBattleRoyaleCrateOpen', crate:GetWorldPos());
    spawnedOpenCrate:SetDirectionVector(crate:GetDirectionVector());

    -- Removes the unopened crate
    System.RemoveEntity(crateId);
end

-- SCAAMBRPreRegisterHit
-- Calculates potential damage before is applied taking into account the armor the player has
function SCAAMBRPreRegisterHit(hit)

    -- Checks if it's not autodamage so the armor prevent damage
    if (hit.shooterId ~= hit.targetId) then
        local playerKilled = hit.target;
        local playerKiller = hit.shooter;

        -- Checks if the entities involved in the hit are players, and the player is not the InLobby state
        -- if the player is InLobby it's going do deny the hit and get the player back to 100% hp, this to
        -- prevent players from killing each other in the lobby area
        if (playerKiller and playerKiller.player and playerKilled and playerKilled.player and playerKilled.SCAAMBRState == 'Playing') then
            local playerChannel = playerKilled.actor:GetChannel();
            local newHealth = 0;
            local damageDealt = hit.damage;

            -- Checks if the damage is lower than the health + armor otherwise it takes these values because it doesnt
            -- make sense to count damage over the health + armor, those are values that the player hit doesn't have
            if (damageDealt > (playerKilled.player:GetHealth() + playerKilled.SCAAMBRArmor)) then
                damageDealt = playerKilled.player:GetHealth() + playerKilled.SCAAMBRArmor;
            end

            -- Updates the damage dealt sum for the attacker
            playerKiller.SCAAMBRDamageDealt = playerKiller.SCAAMBRDamageDealt + damageDealt;

            -- If the player has armor, reduce that armor by the value of the damage instead of reducing the HP
            if (playerKilled.SCAAMBRArmor > 0) then
                local hitDamage = hit.damage;
                local damageDifference = playerKilled.SCAAMBRArmor - hitDamage;
                local damageDealt = hitDamage - playerKilled.SCAAMBRArmor;

                if (damageDifference >= 0) then
                    newHealth = playerKilled.player:GetHealth();

                    -- Sets the max health and health to a ridiculous high value so the player can't die from the hit
                    playerKilled.actor:SetMaxHealth(9000);
                    playerKilled.player:SetHealth(9000);
                    playerKilled.SCAAMBRArmor = damageDifference;
                else
                    local healthChange = math.abs(damageDifference);
                    newHealth = playerKilled.lastHealth - healthChange;

                    -- If the calculation of the damage - the armor is enough to save the player from dying, use that value as the new health
                    if (newHealth > 0) then
                        playerKilled.actor:SetMaxHealth(9000);
                        playerKilled.player:SetHealth(9000);
                    end

                    playerKilled.SCAAMBRArmor = 0;
                end

                -- Updates the BR UI with the new armor
                playerKilled.onClient:SCAAMBRChangeTheStates(playerChannel, 'setarmor', tostring(playerKilled.SCAAMBRArmor));
            end

            playerKilled.SCAAMBRNewHealth = newHealth;
        end
    end
end

-- SCAAMBRRegisterHit
-- Register a hit on a player to determine if it's dead or not then proceed with the necessary actions
function SCAAMBRRegisterHit(hit)
    local playerKilled = hit.target;
    local playerKiller = hit.shooter;

    -- Checks if the entities involved in the hit are players, and the player is not the InLobby state
    -- if the player is InLobby it's going do deny the hit and get the player back to 100% hp, this to
    -- prevent players from killing each other in the lobby area
    if (playerKiller and playerKiller.player and playerKilled and playerKilled.player and playerKilled.SCAAMBRState == 'Playing') then

        -- If the player's new health parameter is greater than 0 it means the player survived the hit and that the health resulting of the calcularions with the armor
        -- set the max health values back to normal and set the health to the new health
        if (playerKilled.SCAAMBRNewHealth and playerKilled.SCAAMBRNewHealth > 0) then
            playerKilled.actor:SetMaxHealth(100);
            playerKilled.player:SetHealth(playerKilled.SCAAMBRNewHealth);
            playerKilled.lastHealth = playerKilled.SCAAMBRNewHealth;
        end

        -- If the player still has remaining armor prevent bleeding
        if (playerKilled.SCAAMBRArmor > 0) then
            playerKilled.player:SetBleedingLevel(0);
        end

        if (playerKilled.lastHealth <= 0) then
            if (hit.shooterId ~= hit.targetId) then

                -- Updates the kill count on the kill player
                playerKiller.SCAAMBRKills = playerKiller.SCAAMBRKills + 1;
                local playerKillerChannel = playerKiller.actor:GetChannel();
                playerKiller.onClient:SCAAMBRChangeTheStates(playerKillerChannel, 'setkillcounter', tostring(playerKiller.SCAAMBRKills));
                
                -- Setting the headshot or regular kill message
                local message = '';

                if (hit.material_type == 'head') then
                    message = playerKiller:GetName() .. ' headshotted ' .. playerKilled:GetName();
                else
                    message = playerKiller:GetName() .. ' killed ' .. playerKilled:GetName();
                end

                -- Editor or server specific actions
                if (System.IsEditor()) then
                    g_gameRules.game:SendTextMessage(0, g_localActorId, message);
                else
                    g_gameRules.game:SendTextMessage(0, 0, message);
                end
            else

                -- Editor or server specific actions
                if (System.IsEditor()) then
                    g_gameRules.game:SendTextMessage(0, g_localActorId, playerKilled:GetName() .. ' just committed suicide');
                else
                    g_gameRules.game:SendTextMessage(0, 0, playerKilled:GetName() .. ' just committed suicide');
                end
            end
        end

        -- Calls the process damage function
        SCAAMBRProcessDamage(playerKilled, false);
    elseif (playerKiller and playerKiller.player and playerKilled and playerKilled.player and (playerKilled.SCAAMBRState == 'InLobby' or playerKilled.SCAAMBRState == 'Ready')) then
        playerKilled.player:SetHealth(9000);
    end
end

-- SCAAMBRProcessDamage
-- Process the player damage, that being by circle or a hit and determines if the player died and takes the proper measures
function SCAAMBRProcessDamage(player, processFromCircle)
    if (player.player:GetHealth() <= 0 and player.SCAAMBRState == 'Playing') then

        -- Sets the dead player state to Dead so it doesn't get affected by this game anymore
        player.SCAAMBRState = 'Dead';

        -- If this function was called from the circle update, it'll display this message when the player dies
        if (processFromCircle == true) then
            
            -- Forces a kill on the player
            player.player:SetHealth(0.01);
            player.player:SetWater(0);

            -- Editor or server specific actions
            if (System.IsEditor()) then
                g_gameRules.game:SendTextMessage(0, g_localActorId, 'Circle killed you');
            else
                g_gameRules.game:SendTextMessage(0, player.id, 'Circle killed you');
            end
        end

        -- Hides the BR UI on death
        local playerChannel = player.actor:GetChannel();
        player.onClient:SCAAMBRToggleUI(playerChannel, 'all', false);        
        
        -- Updates the player count on all players
        local playersPlaying = 0;
        local listOfPlayers = CryAction.GetPlayerList();
        local playingPlayerEntities = {};

        for key, player2 in pairs(listOfPlayers) do

            -- Checks if the player has the Playing state
            if (player2.SCAAMBRState == 'Playing') then
                playersPlaying = playersPlaying + 1;
                table.insert(playingPlayerEntities, player2);
            end
        end

        SCAAMBattleRoyaleProperties.CurrentPlayers = playersPlaying;

        -- Submits the score to the stats table
        local stats = {
            Name = player:GetName(),
            SteamId = player.player:GetSteam64Id();
            Kills = player.SCAAMBRKills,
            Damage = round(player.SCAAMBRDamageDealt),
            Time = round(SCAAMBattleRoyaleProperties.TotalTime),
            Position = (playersPlaying + 1)
        };

        table.insert(SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].Scoreboard, 1, stats);

        -- Updates the player stats with the game's data
        local killedSteamID = player.player:GetSteam64Id();
        local playerPersistentData = SCAAMBRPlayerDatabase:GetPage(killedSteamID);

        if (playerPersistentData == nil) then
            playerPersistentData = {
                Name = stats.Name,
                Kills = stats.Kills,
                Deaths = 1,
                SoloGames = 1,
                SquadGames = 0,
                SoloWins = 0,
                SquadWins = 0,
                Damage = stats.Damage
            };
        else
            playerPersistentData.Kills = playerPersistentData.Kills + stats.Kills;
            playerPersistentData.Deaths = playerPersistentData.Deaths + 1;
            playerPersistentData.SoloGames = playerPersistentData.SoloGames + 1;
            playerPersistentData.Damage = playerPersistentData.Damage + stats.Damage;
        end

        SCAAMBRPlayerDatabase:SetPage(killedSteamID, playerPersistentData);

        -- Updates the player count on all players
        for key, player2 in pairs(playingPlayerEntities) do
            local playerChannel = player2.actor:GetChannel();
            player2.onClient:SCAAMBRChangeTheStates(playerChannel, 'setplayercounter', tostring(playersPlaying));
        end
    end
end

-- SCAAMBRStartCircleCounter
-- A simple caller for updates so the functions based on time are managed properly
function SCAAMBRStartCircleCounter(circle)
    Script.SetTimerForFunction(100, 'SCAAMBRCircleLoop', circle);
end

-- SCAAMBRCircleLoop
-- Manages the circle and safe zone properties across all the phases
function SCAAMBRCircleLoop(circle)

    -- Checks if the current phase is valid, otherwise that'll mean the game has no circle and people is about
    -- to die by the circle anyways
    if (SCAAMBattleRoyaleProperties.CurrentPhase <= SCAAMBattleRoyaleProperties.GamePhases) then

        -- This function is called 10 times per second so the timer increments by a 100ms for each function call
        SCAAMBattleRoyaleProperties.CurrentTimer = SCAAMBattleRoyaleProperties.CurrentTimer + 0.1;
        SCAAMBattleRoyaleProperties.TotalTime = SCAAMBattleRoyaleProperties.TotalTime + 0.1;

        -- Calculates the total time of the phase (cooldown time and circle closing in time)
        local totalPhaseTimeSum = SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CooldownTime + SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CircleShrinkTime;

        -- Determines if it plays the cool timer sound on all players
        local cooldownTimeSub = SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CooldownTime - SCAAMBattleRoyaleProperties.CurrentTimer;
        local circleShrinkTimeSub = totalPhaseTimeSum - SCAAMBattleRoyaleProperties.CurrentTimer;

        if ((cooldownTimeSub >= 0 and cooldownTimeSub <= 3) or (circleShrinkTimeSub >= 0 and circleShrinkTimeSub <= 3)) then

            -- Asks if the timer has 3 specific values so it's making sure to play it 3 times and every second
            if (SCAAMBattleRoyaleProperties.CoolSoundTimer == 3000 or SCAAMBattleRoyaleProperties.CoolSoundTimer == 2000 or SCAAMBattleRoyaleProperties.CoolSoundTimer == 1000) then
                SCAAMBRPlayGlobalSound('Play_menu_back', nil);

                if (cooldownTimeSub >= 0 and cooldownTimeSub <= 3) then

                    -- Editor or server specific actions
                    if (System.IsEditor()) then
                        g_gameRules.game:SendTextMessage(0, g_localActorId, 'Circle closes in ' .. tostring(round(SCAAMBattleRoyaleProperties.CoolSoundTimer / 1000)) .. ' seconds');
                    else
                        g_gameRules.game:SendTextMessage(0, 0, 'Circle closes in ' .. tostring(round(SCAAMBattleRoyaleProperties.CoolSoundTimer / 1000)) .. ' seconds');
                    end
                elseif (circleShrinkTimeSub >= 0 and circleShrinkTimeSub <= 3) then

                    -- Editor or server specific actions
                    if (System.IsEditor()) then
                        g_gameRules.game:SendTextMessage(0, g_localActorId, 'Circle is closing in ' .. tostring(round(SCAAMBattleRoyaleProperties.CoolSoundTimer / 1000)) .. ' seconds');
                    else
                        g_gameRules.game:SendTextMessage(0, 0, 'Circle is closing in ' .. tostring(round(SCAAMBattleRoyaleProperties.CoolSoundTimer / 1000)) .. ' seconds');
                    end
                end
            end

            SCAAMBattleRoyaleProperties.CoolSoundTimer = SCAAMBattleRoyaleProperties.CoolSoundTimer - 100;
        end

        -- If the timer surpasses the cooldown time, the circle starts to shrink among other things
        if (SCAAMBattleRoyaleProperties.CurrentTimer >= SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CooldownTime) then

            -- Resets the cool sound timer for the second part of the timer when the circle is about to shrink
            if (SCAAMBattleRoyaleProperties.CoolSoundTimer <= 0) then
                SCAAMBattleRoyaleProperties.CoolSoundTimer = 3000;
            end

            -- Just displays the corresponding circle is closing warning message, it does it only once
            if (SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].DisplayedMessage == false) then
                SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].DisplayedMessage = true;

                -- Editor or server specific actions
                if (System.IsEditor()) then
                    g_gameRules.game:SendTextMessage(0, g_localActorId, 'Circle is closing in, you have ' .. tostring(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CircleShrinkTime) .. ' seconds');
                else
                    g_gameRules.game:SendTextMessage(0, 0, 'Circle is closing in, you have ' .. tostring(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CircleShrinkTime) .. ' seconds');
                end
            end
            
            -- Determines if the phase ended and goes to the next one
            if (totalPhaseTimeSum > SCAAMBattleRoyaleProperties.CurrentTimer) then

                -- Calculates the difference between current and new or target scale
                local scaleToShrink = SCAAMBattleRoyaleProperties.CurrentScale - SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].NewScale;
                
                -- Calculates the distance the current circle is gonna move towards the new circle per function call, remember this is called 10 times a second so that's why the * 10, to make the calculation
                -- based on the function's call frequency
                -- Same with the scale
                local distanceOfVectorsDelta = SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].DistanceBetweenVectors / (SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CircleShrinkTime * 10);
                local scaleToShrinkDelta = scaleToShrink / (SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CircleShrinkTime * 10);

                -- Starts to set the new scale to the circle
                SCAAMBattleRoyaleProperties.CurrentScaleDelta = SCAAMBattleRoyaleProperties.CurrentScaleDelta - scaleToShrinkDelta;

                -- Starts to set the new position to the circle
                local moveToDirection = {x=0, y=0, z=0};
                local sumVectors = {x=0, y=0, z=0};
                local moveToPosition = {x=0, y=0, z=0};

                SubVectors(moveToDirection, SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].Position, circle:GetWorldPos());
                NormalizeVector(moveToDirection);
                FastScaleVector(sumVectors, moveToDirection, distanceOfVectorsDelta);
                FastSumVectors(moveToPosition, sumVectors, circle:GetWorldPos());

                -- Sets the new position and scale to the circle in both client and server
                circle:SetWorldPos(moveToPosition);
                circle:SetWorldScale(SCAAMBattleRoyaleProperties.CurrentScaleDelta);
                circle.allClients:SCAAMSetPositionScale(moveToPosition, tostring(SCAAMBattleRoyaleProperties.CurrentScaleDelta));
            else
                
                -- It gets here when the total phase time is ended so it goes to the next phase
                -- Removes the current safe zone circle
                System.RemoveEntity(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].DummyCircleId);

                -- Resets the timers and sets properties for the new phase
                SCAAMBattleRoyaleProperties.CurrentScale = SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].NewScale;
                SCAAMBattleRoyaleProperties.CurrentPhase = SCAAMBattleRoyaleProperties.CurrentPhase + 1;
                SCAAMBattleRoyaleProperties.CurrentTimer = 0;

                -- Asks if the next phase is not the last phase, otherwise it does nothing
                if (SCAAMBattleRoyaleProperties.CurrentPhase <= SCAAMBattleRoyaleProperties.GamePhases) then
                    local spawnedDummy = ISM.SpawnItem('SCAAMBattleRoyaleCircleDummy', SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].Position);
                    
                    spawnedDummy:SetWorldScale(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].NewScale);
                    spawnedDummy.allClients:SCAAMSetScale(tostring(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].NewScale));
                    SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].DummyCircleId = spawnedDummy.id;
                    SCAAMBattleRoyaleProperties.CoolSoundTimer = 3000;

                    -- Editor or server specific actions
                    if (System.IsEditor()) then
                        g_gameRules.game:SendTextMessage(0, g_localActorId, 'Circle will start closing in ' .. tostring(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CooldownTime) .. ' seconds');
                    else
                        g_gameRules.game:SendTextMessage(0, 0, 'Circle will start closing in ' .. tostring(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase)].CooldownTime) .. ' seconds');
                    end
                else
                    System.RemoveEntity(SCAAMBattleRoyaleProperties['Phase' .. tostring(SCAAMBattleRoyaleProperties.CurrentPhase - 1)].DummyCircleId);
                    
                    -- Editor or server specific actions
                    if (System.IsEditor()) then
                        g_gameRules.game:SendTextMessage(0, g_localActorId, "It's time to have a winner, don't you think folks?");
                    else
                        g_gameRules.game:SendTextMessage(0, 0, "It's time to have a winner, don't you think folks?");
                    end
                end
            end
        end
    end

    -- Calculates a second so it checks things each second, like if the player is in the circle
    SCAAMBattleRoyaleProperties.CheckForSecondPassed = SCAAMBattleRoyaleProperties.CheckForSecondPassed + 100;
    if (SCAAMBattleRoyaleProperties.CheckForSecondPassed >= 1000) then
        SCAAMBattleRoyaleProperties.CheckForSecondPassed = 0;

        if (SCAAMBattleRoyaleProperties.GameState == 'Active') then
            SCAAMBRCheckPlayers(circle, SCAAMBattleRoyaleProperties.CurrentScaleDelta);
            SCAAMBRCheckAirdrop(SCAAMBattleRoyaleProperties.TotalTime);
        end
    end

    -- Determines if a new update should be called, it's going to stop if the game's state is not Active
    if (SCAAMBattleRoyaleProperties.GameState == 'Active') then
        SCAAMBRStartCircleCounter(circle);
    end
end

-- SCAAMBRCheckPlayers
-- Checks if the participating players of the current game are in the circle, otherwise will damage them
function SCAAMBRCheckPlayers(circle, radius)

    -- Cycle through the entire list of players in the server
    local listOfPlayers = CryAction.GetPlayerList();
    local listOfPlayingPlayers = {};
    local playersPlaying = 0;

    -- Checks if there's enough players to continue the game or just declare a winner or end it
    for key, player in pairs(listOfPlayers) do
        if (player.SCAAMBRState == 'Playing') then
            playersPlaying = playersPlaying + 1;
            listOfPlayingPlayers[playersPlaying] = player;
        end
    end
    
    if (playersPlaying == 0) then

        -- There's no players playing so the game ends and it returns to lobby
        SCAAMBattleRoyaleProperties.GameState = 'InLobby';
        SCAAMBRPlayGlobalSound('Play_terminal_error', nil);

        -- Calls the lobby function after a delay
        Script.SetTimerForFunction(5000, 'SCAAMBRDeclareWinner', {});

        -- Re-sorts the table to fix the positions in case a player left the server or crashed
        for key, position in pairs(SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].Scoreboard) do
            position.Position = key;
        end

        -- Submits the final data to the stats table
        SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].Winner = 'No winner';
        SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].TotalTime = round(SCAAMBattleRoyaleProperties.TotalTime);

        -- Gets the games played on the server and updates it
        local gameNumber = SCAAMBRDatabase:GetPage('GameNumber');
        
        if (gameNumber == nil) then
            gameNumber = 0;
        end

        gameNumber = gameNumber + 1;
        SCAAMBRDatabase:SetPage('GameNumber', gameNumber);

        SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].GameNum = gameNumber;

        SCAAMBRDatabase:SetPage('Game' .. tostring(gameNumber), SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)]);

        -- Removes the 100th game data to save space
        if (SCAAMBRDatabase:GetPage('Game' .. (gameNumber - 100)) ~= nil) then
            SCAAMBRDatabase:PurgePage('Game' .. (gameNumber - 100));
            SCAAMBRDatabase:SetPage('GameNumberMin', gameNumber - 99);
            SCAAMBRDatabase.parent.db:save();
        else
            SCAAMBRDatabase:SetPage('GameNumberMin', 1);
        end

        -- Updates the top 15 data
        SCAAMBRTopFifteen = SCAAMBRGetTopFifteen();

        -- Updates the menu UI data on all players
        SCAAMBRUpdateMenuDataGlobally();

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, 'Every player disconnected, returning to lobby');
            g_gameRules.game:SendTextMessage(4, g_localActorId, 'Every player disconnected, returning to lobby');
        else
            g_gameRules.game:SendTextMessage(0, 0, 'Every player disconnected, returning to lobby');
            g_gameRules.game:SendTextMessage(4, 0, 'Every player disconnected, returning to lobby');
        end
    elseif (playersPlaying == SCAAMBattleRoyalePropertiesBackup.MinToWin) then

        -- There's only 1 player left, everyone else disconected so it's declared as winner and game returns to lobby
        SCAAMBattleRoyaleProperties.GameState = 'InLobby';
        local playerName = listOfPlayingPlayers[1]:GetName();

        SCAAMBRPlayGlobalSound('Play_terminal_recieve', listOfPlayers);

        -- Gives the player the status of InLobby to prevent any game function affecting it
        listOfPlayingPlayers[1].SCAAMBRState = 'InLobby';

        -- Submits the score to the stats table
        local stats = {
            Name = listOfPlayingPlayers[1]:GetName(),
            SteamId = listOfPlayingPlayers[1].player:GetSteam64Id();
            Kills = listOfPlayingPlayers[1].SCAAMBRKills,
            Damage = round(listOfPlayingPlayers[1].SCAAMBRDamageDealt),
            Time = round(SCAAMBattleRoyaleProperties.TotalTime),
            Position = 1
        };

        table.insert(SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].Scoreboard, 1, stats);

        -- Re-sorts the table to fix the positions in case a player left the server or crashed
        for key, position in pairs(SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].Scoreboard) do
            position.Position = key;
        end
        
        -- Submits the final data to the stats table
        SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].Winner = listOfPlayingPlayers[1]:GetName();
        SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].TotalTime = round(SCAAMBattleRoyaleProperties.TotalTime);

        -- Gets the games played on the server and updates it
        local gameNumber = SCAAMBRDatabase:GetPage('GameNumber');
            
        if (gameNumber == nil) then
            gameNumber = 0;
        end

        gameNumber = gameNumber + 1;
        SCAAMBRDatabase:SetPage('GameNumber', gameNumber);

        SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)].GameNum = gameNumber;

        SCAAMBRDatabase:SetPage('Game' .. tostring(gameNumber), SCAAMBRGameStats['Game' .. tostring(SCAAMBRGameNumber)]);

        -- Removes the 100th game data to save space
        if (SCAAMBRDatabase:GetPage('Game' .. (gameNumber - 100)) ~= nil) then
            SCAAMBRDatabase:PurgePage('Game' .. (gameNumber - 100));
            SCAAMBRDatabase:SetPage('GameNumberMin', gameNumber - 99);
            SCAAMBRDatabase.parent.db:save();
        else
            SCAAMBRDatabase:SetPage('GameNumberMin', 1);
        end

        -- Updates the top 15 data
        SCAAMBRTopFifteen = SCAAMBRGetTopFifteen();

        -- Updates the player stats with the game's data
        local playerSteamID = listOfPlayingPlayers[1].player:GetSteam64Id();
        local playerPersistentData = SCAAMBRPlayerDatabase:GetPage(playerSteamID);

        if (playerPersistentData == nil) then
            playerPersistentData = {
                Name = stats.Name,
                Kills = stats.Kills,
                Deaths = 0,
                SoloGames = 1,
                SquadGames = 0,
                SoloWins = 1,
                SquadWins = 0,
                Damage = stats.Damage
            };
        else
            playerPersistentData.Kills = playerPersistentData.Kills + stats.Kills;
            playerPersistentData.SoloGames = playerPersistentData.SoloGames + 1;
            playerPersistentData.SoloWins = playerPersistentData.SoloWins + 1;
            playerPersistentData.Damage = playerPersistentData.Damage + stats.Damage;
        end

        SCAAMBRPlayerDatabase:SetPage(playerSteamID, playerPersistentData);

        -- Updates the menu UI data on all players
        SCAAMBRUpdateMenuDataGlobally();

        -- Freezes the winner player so it prevents desync issues
        local playerChannel = listOfPlayingPlayers[1].actor:GetChannel();
        listOfPlayingPlayers[1].onClient:SCAAMBRChangeTheStates(playerChannel, 'freezeplayer', '');
        
        -- Calls the lobby function after a delay
        Script.SetTimerForFunction(5000, 'SCAAMBRDeclareWinner', listOfPlayingPlayers[1]);

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, playerName .. " is the winner!!!");
            g_gameRules.game:SendTextMessage(4, g_localActorId, playerName .. " is the winner!!!");
        else
            g_gameRules.game:SendTextMessage(0, 0, playerName .. " is the winner!!!");
            g_gameRules.game:SendTextMessage(4, 0, playerName .. " is the winner!!!");
        end
    else

        -- There's more than 1 player so the function can proceed
        for key, player in pairs(listOfPlayingPlayers) do

            -- Checks if the player is in the current game session to perform the circle check
            if (player.SCAAMBRState == 'Playing') then

                -- Calculates the distance between circle and player
                local playerPos = SCAAMBRShallowCopy(player:GetWorldPos());
                local circlePos = SCAAMBRShallowCopy(circle:GetWorldPos());
                playerPos.z = circlePos.z;
                local distance = DistanceVectors(circlePos, playerPos);
                local playerChannel = player.actor:GetChannel();

                -- Checks if there's any changes in the player numbers, generally because someone disconnected
                if (playersPlaying ~= SCAAMBattleRoyaleProperties.CurrentPlayers) then
                    player.onClient:SCAAMBRChangeTheStates(playerChannel, 'setplayercounter', tostring(playersPlaying));
                end
                
                -- If the distance is greater than the radius AKA the circle's scale, then the player is outside
                if (distance > radius) then
                    local playerCurrentHealth = player.player:GetHealth();
                    player.player:SetHealth(playerCurrentHealth - (1.5 * SCAAMBattleRoyaleProperties.CurrentPhase));

                    -- Plays a hurt sound on that specific player
                    player.onClient:SCAAMBRPlaySoundDat(playerChannel, 'Play_torch_melee_fp');
                
                    -- Calls the process damage function
                    SCAAMBRProcessDamage(player, true);
                end
            end
        end
    end
end

-- SCAAMBRCheckAirdrop
-- Checks if it's time for an airdrop then spawns it
function SCAAMBRCheckAirdrop(totalTime)

    -- Loops through all the airdrop timers
    for key, airdrop in pairs(SCAAMBattleRoyaleProperties.Airdrops) do
        if (round(totalTime) == airdrop) then
            local circle = System.GetEntity(SCAAMBattleRoyaleProperties.circleId);
            local currentCirclePosition = SCAAMBRShallowCopy(circle:GetWorldPos());
            local circleScale = circle:GetWorldScale();

            -- Starts to set the new position to the Airdrop
            local moveToDirection = {};
            local sumVectors = {};
            local moveToPosition = {};

            -- Gets the water elevation
            local waterElevation = System.GetCVar('e_OceanLevelOffset2');

            local isValidPosition = false;

            -- Checks if the position for the airdrop is valid (there's no entities, bulidings, etc in the way)
            while (isValidPosition == false) do

                -- Starts to set the new position to the Airdrop
                moveToDirection = {x=0, y=0, z=0};
                sumVectors = {x=0, y=0, z=0};
                moveToPosition = {x=0, y=0, z=0};

                local circlePositionToEdit = SCAAMBRShallowCopy(currentCirclePosition);

                local randomChangeX = randomF((circleScale * -1), circleScale);
                local randomChangeY = randomF((circleScale * -1), circleScale);
        
                circlePositionToEdit.x = circlePositionToEdit.x + randomChangeX;
                circlePositionToEdit.y = circlePositionToEdit.y + randomChangeY;

                SubVectors(moveToDirection, circlePositionToEdit, currentCirclePosition);
                NormalizeVector(moveToDirection);
                FastScaleVector(sumVectors, moveToDirection, randomF(0.0, (circleScale * 0.85)));
                FastSumVectors(moveToPosition, sumVectors, currentCirclePosition);

                -- Gets the terrain elevation to check if the ground elevation in the potential position is higher than the ocean
                local terrainElevation = System.GetTerrainElevation(moveToPosition);

                if (terrainElevation > waterElevation) then

                    -- Adds the z coord to the potential position based on the ground elevation + 250 meters
                    moveToPosition.z = terrainElevation + 250;

                    -- Checks if there's a world intersection with something in the distance established, if not, the airdrop can be placed in that position
                    Physics.RayWorldIntersection(moveToPosition, {x = 0, y = 0, z = (-1 * 260)}, 1, ent_all, nil, nil, g_HitTable);

                    if (g_HitTable[1].dist >= 119) then
                        isValidPosition = true;
                    end
                end
            end

            ISM.SpawnItem('SCAAMBRAirDropCrate', moveToPosition);
        
            -- Editor or server specific actions
            if (System.IsEditor()) then
                g_gameRules.game:SendTextMessage(0, g_localActorId, 'Airdrop incoming, look up');
            else
                g_gameRules.game:SendTextMessage(0, 0, 'Airdrop incoming, look up');
            end
        end
    end
end

-- SCAAMBRValidateStart
-- Validates if there's enough players to start a game
function SCAAMBRValidateStart(dummyVar)
    if (SCAAMBattleRoyaleProperties.GameState == 'InLobby') then

        -- Counts the players in the server that are InLobby
        local listOfPlayers = CryAction.GetPlayerList();
        local playersInLobby = 0;

        for key, player in pairs(listOfPlayers) do
            if (player.SCAAMBRState == 'InLobby') then
                playersInLobby = playersInLobby + 1;
            end
        end

        -- If there's enough players the game can start
        if (playersInLobby >= SCAAMBattleRoyalePropertiesBackup.MinPlayers) then

            -- Sets the state of Ready to the CURRENT players and starts a timer of 15 seconds to let them load properly
            for key, player in pairs(listOfPlayers) do
                player.SCAAMBRState = 'Ready';

                -- Freezes the player so it can't do any action
                local playerChannel = player.actor:GetChannel();
                player.onClient:SCAAMBRChangeTheStates(playerChannel, 'freezeplayer', '');
            end

            Script.SetTimerForFunction(15000, 'SCAAMBRStartGameAfterDelay', {});

            -- Editor or server specific actions
            if (System.IsEditor()) then
                g_gameRules.game:SendTextMessage(0, g_localActorId, 'Starting game in 15 seconds, ' .. tostring(table.getn(listOfPlayers)) .. ' players will join the game');
            else
                g_gameRules.game:SendTextMessage(0, 0, 'Starting game in 15 seconds, ' .. tostring(table.getn(listOfPlayers)) .. ' players will join the game');
            end
        else
            SCAAMBRValidateStartLoop();

            -- Editor or server specific actions
            if (System.IsEditor()) then
                g_gameRules.game:SendTextMessage(0, g_localActorId, 'Not enough players, checking again in 60 seconds');
            else
                g_gameRules.game:SendTextMessage(0, 0, 'Not enough players, checking again in 60 seconds');
            end
        end
    end
end

-- SCAAMBRStartGameAfterDelay
-- After a delay of 15 seconds it'll start the game This to prevent including players
-- that just joined and didn't have enough time to be initialized
function SCAAMBRStartGameAfterDelay(dummyVar)
    local circleSpawnPos = SCAAMBattleRoyalePropertiesBackup.CircleSpawnPosition;
    ISM.SpawnItem('SCAAMBattleRoyaleCircle', circleSpawnPos);
end

-- SCAAMBRSitAndRelax
-- Determines a waiting time before starting the next game
function SCAAMBRSitAndRelax()
    -- Calls the game cleanup function for the previous BR game
    SCAAMBRCleanGameMap();

    -- Set the spawns for crates, items, etc
    SCAAMBRSpawnGameItems();

    -- Editor or server specific actions
    if (System.IsEditor()) then
        g_gameRules.game:SendTextMessage(0, g_localActorId, 'Sit back and relax, game will start in 3 minutes');
    else
        g_gameRules.game:SendTextMessage(0, 0, 'Sit back and relax, game will start in 3 minutes');
    end

    local firstCounter = 20000;
    local secondCounter = 80000;
    local thirdCounter = 130000;
    local lastCounter = 140000;

    -- Editor or server specific actions
    if (System.IsEditor()) then
        firstCounter = 20000;
        secondCounter = 40000;
        thirdCounter = 50000;
        lastCounter = 60000;
    end

    Script.SetTimerForFunction(firstCounter, 'SCAAMBRSendMessage', {message = 'Game might start in 2 minutes', sound = 'Play_server_message'}); -- TODO: Change this back to 60000
    Script.SetTimerForFunction(secondCounter, 'SCAAMBRSendMessage', {message = 'Game might start in 1 minute', sound = 'Play_server_message'}); -- TODO: Change this back to 120000
    Script.SetTimerForFunction(thirdCounter, 'SCAAMBRSendMessage', {message = 'Game might start in 10 seconds', sound = 'Play_server_message'}); -- TODO: Change this back to 170000
    Script.SetTimerForFunction(lastCounter, 'SCAAMBRValidateStart', {}); -- TODO: Change this back to 180000
end

-- SCAAMBRValidateStartLoop
-- Checks every 60 seconds if the game can start or not
function SCAAMBRValidateStartLoop()
    Script.SetTimerForFunction(60000, 'SCAAMBRValidateStart', {});
end

-- SCAAMBRPlayerGeneralUpdate
-- Updates the player's stim packs and armor counters for the UI in case there's any change
function SCAAMBRPlayerGeneralUpdate(dummyVar)
    local player = System.GetEntity(g_localActorId);

    -- Checks if the UI was initialized. It doesn't make sense to do something if the player is
    -- InLobby when the UI's haven't been displayed yet
    if (player.SCAAMBRToggledUI == true and player.SCAAMBRToggledLobbyUI == false) then
        player.SCAAMBRItemCheckCounter = player.SCAAMBRItemCheckCounter + 20;

        -- It only performs inventory checking every 300ms
        if (player.SCAAMBRItemCheckCounter >= 300) then
            player.SCAAMBRItemCheckCounter = 0;
            local listOfStimPacks = g_gameRules.game:GetStorageContent(g_localActorId, 'SCAAMStimPack');
            local listOfArmor = g_gameRules.game:GetStorageContent(g_localActorId, 'SCAAMArmor');
            local stimPacksCount = 0;
            local armorCount = 0;

            -- Loops through the list of all the stim packs and counts them
            for key, item in pairs(listOfStimPacks) do
                local itemEntity = System.GetEntity(item);

                stimPacksCount = stimPacksCount + itemEntity.item:GetStackCount();
            end

            -- Loops through the list of all the armor and counts them
            for key, item in pairs(listOfArmor) do
                local itemEntity = System.GetEntity(item);

                armorCount = armorCount + itemEntity.item:GetStackCount();
            end

            -- If the values are different then it means the player used/dropped/etc stim packs so the values
            -- need to be updated in the UI
            if (player.SCAAMBRStimPackCounter ~= stimPacksCount) then
                player.SCAAMBRStimPackCounter = stimPacksCount;

                player:SCAAMBRChangeTheUIStateClient('setstimpackcounter', tostring(player.SCAAMBRStimPackCounter));
            end

            -- If the values are different then it means the player used/dropped/etc armor so the values
            -- need to be updated in the UI
            if (player.SCAAMBRArmorCounter ~= armorCount) then
                player.SCAAMBRArmorCounter = armorCount;

                player:SCAAMBRChangeTheUIStateClient('setarmorcounter', tostring(player.SCAAMBRArmorCounter));
            end
        end

        local playerAngles = player:GetAngles();

        local playerData = {
            Position = player:GetWorldPos(),
            Rotation = playerAngles.z * 180/g_Pi
        }

        SCAAMBRUIFunctions:UpdatePlayerPosAndRotationGame(playerData);
    end

    -- Calls the timer function again
    SCAAMBRStartPlayerGeneralUpdate();
end

-- SCAAMBRStartPlayerGeneralUpdate
-- Starts the timer to update the player's stim packs and armor counters for the UI
-- Also, updates the player position for the map game
function SCAAMBRStartPlayerGeneralUpdate()
    Script.SetTimerForFunction(20, 'SCAAMBRPlayerGeneralUpdate', {});
end

-- SCAAMBRSendMessage
-- Sends a message to all players, this is generally called after a timer
function SCAAMBRSendMessage(messageProperties)

    -- Editor or server specific actions
    if (System.IsEditor()) then
        g_gameRules.game:SendTextMessage(0, g_localActorId, messageProperties.message);
    else
        g_gameRules.game:SendTextMessage(0, 0, messageProperties.message);
    end

    -- If a sound is set, play it for all players
    if (messageProperties.sound ~= nil) then
        SCAAMBRPlayGlobalSound(messageProperties.sound, nil);
    end
end

-- SCAAMBRPlayGlobalSound
-- Plays a sound on all players
function SCAAMBRPlayGlobalSound(soundName, hasPlayerList)
    local playerList = hasPlayerList;

    -- If the function calling this function has gotten a list of players then use it instead of
    -- retrieving the list once again
    if (playerList == nil) then
        playerList = CryAction.GetPlayerList();
    end

    for key, player in pairs(playerList) do
        local playerChannel = player.actor:GetChannel();
        player.onClient:SCAAMBRPlaySoundDat(playerChannel, soundName);
    end
end

-- SCAAMBRUpdateMenuDataGlobally
-- Updates the menu UI data after a game is over in all players which have the Menu opened
function SCAAMBRUpdateMenuDataGlobally()
    local playerList = CryAction.GetPlayerList();

    for key, player in pairs(playerList) do
        local steamId = player.player:GetSteam64Id();
        local playerChannel = player.actor:GetChannel();

        -- Gets the player stats in a simplified form
        local myStats = SCAAMBRPlayerDatabase:GetPage(steamId);
        if (myStats == nil) then
            myStats = {};
        else
            myStats = new(myStats);
            myStats.SoloGames = tostring(myStats.SoloGames);
            myStats.SoloWins = tostring(myStats.SoloWins);
            myStats.Kills = tostring(myStats.Kills);
            myStats.Damage = tostring(myStats.Damage);
            myStats.Deaths = tostring(myStats.Deaths);
        end

        -- Gets the min and max games
        local gameData = {
            MaxGame = tostring(SCAAMBRDatabase:GetPage('GameNumber')),
            MinGame = tostring(SCAAMBRDatabase:GetPage('GameNumberMin'))
        };

        -- Gets the map data in a simplified form
        local playerLocation = '';

        if (player.SCAAMBRSpawnPoint ~= nil) then
            playerLocation = player.SCAAMBRSpawnPoint;
        end

        local mapData = {
            Locations = SCAAMBRGetProcessedLocations();
            Location = playerLocation,
            MapScale = SCAAMBattleRoyaleProperties.MapSize
        };

        local allTheInfo = {
            GameData = gameData,
            MyStats = myStats,
            TopFifteen = SCAAMBRTopFifteen,
            MapData = mapData
        };

        -- Sends the JSON string in small chunks
        SCAAMBRFillMenuData(allTheInfo, 'updatemenudata', player, playerChannel);
    end
end

-- SCAAMBRDeclareWinner
-- Takes remaining players to the lobby, potential future features can go here like saving player stats
function SCAAMBRDeclareWinner(data)

    -- If the data is not empty it means this function was called from a winning event, so it can
    -- perform actions over the winner player
    if (data.player) then

        -- Resets the player's selected position
        data.SCAAMBRSpawnPoint = nil;

        -- Hides the BR UI on the winner player
        local playerChannel = data.actor:GetChannel();
        data.onClient:SCAAMBRChangeTheStates(playerChannel, 'gotoidle', '');

        -- Cleans the player from all the items
        SCAAMBRCleanPlayer(data.id);
    end

    -- Removes all the circle and dummy circle entities
    local listOfCircles = System.GetEntitiesByClass('SCAAMBattleRoyaleCircle');

    for key, circlelocal in pairs(listOfCircles) do
        System.RemoveEntity(circlelocal.id);
    end

    local listOfDummyCircles = System.GetEntitiesByClass('SCAAMBattleRoyaleCircleDummy');

    for key, circleDummy in pairs(listOfDummyCircles) do
        System.RemoveEntity(circleDummy.id);
    end

    -- Takes players to lobby
    SCAAMBRSitAndRelax();
end

-- SCAAMBRSetLocation
-- Sets the location for the player to spawn in
function SCAAMBRSetLocation(playerId, location)
    local player = System.GetEntity(playerId);

    -- Checks if the location was set, otherwise will spawn the player in a random location
    if (location == '') then
        player.SCAAMBRSpawnPoint = nil;

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, 'Removed spawn location, now you will spawn randomly');
        else
            g_gameRules.game:SendTextMessage(0, playerId, 'Removed spawn location, now you will spawn randomly');
        end
    elseif (SCAAMBRPlayerProperties.Positions[location] ~= nil) then
        player.SCAAMBRSpawnPoint = location;

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, 'Set spawn point location to ' .. location);
        else
            g_gameRules.game:SendTextMessage(0, playerId, 'Set spawn point to ' .. location);
        end
    end
end

--------------------------------------------------------------------------
--------------------------- CUSTOM ITEMS SCRIPTS -------------------------
--------------------------------------------------------------------------

-- SCAAMBRUseStimPack
-- Sets a 3s delay to perform a 50hp heal on the player (this to simulate an applying animation and because
-- it would be so OP if it was instantaneous)
function SCAAMBRUseStimPack(itemId, userId)
    local player = System.GetEntity(userId);

    -- Checks if the player is not InLobby so it can use the armor
    if (player.SCAAMBRState ~= 'InLobby') then

        -- Checks if the player is already applying a stim pack so it won't do it twice in the same timeframe
        if (player.SCAAMBRIsApplyingStimPack == false and player.SCAAMBRIsApplyingArmor == false) then
            
            -- Checks if the player has not full HP, so it doesn't waste a stim pack
            if (player.player:GetHealth() < 100) then
                local useProperties = {
                    ['itemId'] = itemId,
                    ['userId'] = userId
                };

                local item = System.GetEntity(itemId);
                local itemStackCount = item.item:GetStackCount();

                -- If the items has more than 1 in the stacks, it removes 1 from the stack, otherwise it removes the entity
                if (itemStackCount > 1) then
                    itemStackCount = itemStackCount - 1;
                    item.item:SetStackCount(itemStackCount);
                else
                    System.RemoveEntity(itemId);
                end

                -- Sets the flag to prevent players from spamming the stim pack application
                player.SCAAMBRIsApplyingStimPack = true;
                
                Script.SetTimerForFunction(3000, 'SCAAMBRUseStimPackComplete', useProperties);

                -- Editor or server specific actions
                if (System.IsEditor()) then
                    g_gameRules.game:SendTextMessage(0, g_localActorId, 'Applying stim pack');
                else
                    g_gameRules.game:SendTextMessage(0, userId, 'Applying stim pack');
                end
            else
                -- Editor or server specific actions
                if (System.IsEditor()) then
                    g_gameRules.game:SendTextMessage(0, g_localActorId, 'You have full HP');
                else
                    g_gameRules.game:SendTextMessage(0, userId, 'You have full HP');
                end
            end
        else
            -- Editor or server specific actions
            if (System.IsEditor()) then
                g_gameRules.game:SendTextMessage(0, g_localActorId, 'Wait for the current stim pack or armor to apply');
            else
                g_gameRules.game:SendTextMessage(0, userId, 'Wait for the current stim pack or armor to apply');
            end
        end
    else

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, "You're in lobby, can't use this item");
        else
            g_gameRules.game:SendTextMessage(0, userId, "You're in lobby, can't use this item");
        end
    end
end

-- SCAAMBRUseStimPackComplete
-- Applies the stim pack on the user
function SCAAMBRUseStimPackComplete(useProperties)
    local player = System.GetEntity(useProperties.userId);

    -- Checks if the player is even alive (could've died on these 3 seconds), so it makes sense to apply the heal
    if (player and player.player and player.SCAAMBRState ~= 'InLobby') then
        local healthToGo = player.player:GetHealth();
        healthToGo = healthToGo + 50;

        -- Limits the health to 100
        if (healthToGo > 100) then
            healthToGo = 100;
        end

        player.player:SetHealth(healthToGo);

        -- Allows the player to use a stim pack again
        player.SCAAMBRIsApplyingStimPack = false;

        -- Plays a 'heal' sound on that specific player
        local playerChannel = player.actor:GetChannel();
        player.onClient:SCAAMBRPlaySoundDat(playerChannel, 'Play_player_hold_breath_out_fp');
    end
end

-- SCAAMBRApplyStimPackByKey
-- Attempts to apply the stim pack using the special keys (first phase)
function SCAAMBRApplyStimPackByKey(keyString)
    local player = System.GetEntity(g_localActorId);
    player.server:SCAAMBRStimPackByKey();
end

-- SCAAMBRAttemptApplyStimPackByKeyInScript
-- Attempts to apply the stim pack using the special keys (second phase)
function SCAAMBRAttemptApplyStimPackByKeyInScript(userId)
    local listOfStimPacks = g_gameRules.game:GetStorageContent(userId, 'SCAAMStimPack');
    local hasStimPack = false;
    local itemId = nil;

    -- Loops through the stim packs to check if the user has at least one in their inventory
    for key, item in pairs(listOfStimPacks) do
        itemId = item;
        hasStimPack = true;
        break;
    end

    -- If it has a stim pack it perform the function normally
    if (hasStimPack == true) then
        SCAAMBRUseStimPack(itemId, userId);
    else

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, "You don't have a stim pack");
        else
            g_gameRules.game:SendTextMessage(0, userId, "You don't have a stim pack");
        end
    end
end

-- SCAAMBRUseArmor
-- Sets a 4s delay to perform a 50 armor increase on the player (this to simulate an applying animation and because
-- it would be so OP if it was instantaneous)
function SCAAMBRUseArmor(itemId, userId)
    local player = System.GetEntity(userId);

    -- Checks if the player is not InLobby so it can use the armor
    if (player.SCAAMBRState ~= 'InLobby') then

        -- Checks if the player is already applying armor so it won't do it twice in the same timeframe
        if (player.SCAAMBRIsApplyingArmor == false and player.SCAAMBRIsApplyingStimPack == false) then
            
            -- Checks if the player has not full armor, so it doesn't waste an armor plate
            if (player.SCAAMBRArmor < 100) then
                local useProperties = {
                    ['itemId'] = itemId,
                    ['userId'] = userId
                };

                local item = System.GetEntity(itemId);
                local itemStackCount = item.item:GetStackCount();

                -- If the items has more than 1 in the stacks, it removes 1 from the stack, otherwise it removes the entity
                if (itemStackCount > 1) then
                    itemStackCount = itemStackCount - 1;
                    item.item:SetStackCount(itemStackCount);
                else
                    System.RemoveEntity(itemId);
                end

                -- Sets the flag to prevent players from spamming the armor application
                player.SCAAMBRIsApplyingArmor = true;
                
                Script.SetTimerForFunction(2000, 'SCAAMBRUseArmorComplete', useProperties);

                -- Editor or server specific actions
                if (System.IsEditor()) then
                    g_gameRules.game:SendTextMessage(0, g_localActorId, 'Applying armor');
                else
                    g_gameRules.game:SendTextMessage(0, userId, 'Applying armor');
                end
            else
                -- Editor or server specific actions
                if (System.IsEditor()) then
                    g_gameRules.game:SendTextMessage(0, g_localActorId, 'You have full armor');
                else
                    g_gameRules.game:SendTextMessage(0, userId, 'You have full armor');
                end
            end
        else
            -- Editor or server specific actions
            if (System.IsEditor()) then
                g_gameRules.game:SendTextMessage(0, g_localActorId, 'Wait for the current armor or stim pack to apply');
            else
                g_gameRules.game:SendTextMessage(0, userId, 'Wait for the current armor or stim pack to apply');
            end
        end
    else

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, "You're in lobby, can't use this item");
        else
            g_gameRules.game:SendTextMessage(0, userId, "You're in lobby, can't use this item");
        end
    end
end

-- SCAAMBRUseArmorComplete
-- Applies the stim pack on the user
function SCAAMBRUseArmorComplete(useProperties)
    local player = System.GetEntity(useProperties.userId);

    -- Checks if the player is even alive (could've died on these 4 seconds), so it makes sense to apply the armor
    if (player and player.player and player.SCAAMBRState ~= 'InLobby') then
        local armorToGo = player.SCAAMBRArmor;
        armorToGo = armorToGo + 50;

        -- Limits the armor to 100
        if (armorToGo > 100) then
            armorToGo = 100;
        end

        player.SCAAMBRArmor = armorToGo;

        -- Allows the player to use an armor again
        player.SCAAMBRIsApplyingArmor = false;

        -- Plays a 'armor apply' sound on that specific player
        local playerChannel = player.actor:GetChannel();
        player.onClient:SCAAMBRPlaySoundDat(playerChannel, 'Play_backpack_close_fp');

        -- Uptades the BR UI with the new armor
        player.onClient:SCAAMBRChangeTheStates(playerChannel, 'setarmor', tostring(player.SCAAMBRArmor));
    end
end

-- SCAAMBRApplyArmorByKey
-- Attempts to apply the stim pack using the special keys (first phase)
function SCAAMBRApplyArmorByKey(keyString)
    local player = System.GetEntity(g_localActorId);
    player.server:SCAAMBRArmorPlateByKey();
end

-- SCAAMBRAttemptApplyArmorByKeyInScript
-- Attempts to apply the stim pack using the special keys (second phase)
function SCAAMBRAttemptApplyArmorByKeyInScript(userId)
    local listOfArmor = g_gameRules.game:GetStorageContent(userId, 'SCAAMArmor');
    local hasArmor = false;
    local itemId = nil;

    -- Loops through the stim packs to check if the user has at least one in their inventory
    for key, item in pairs(listOfArmor) do
        itemId = item;
        hasArmor = true;
        break;
    end

    -- If it has a stim pack it perform the function normally
    if (hasArmor == true) then
        SCAAMBRUseArmor(itemId, userId);
    else

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, "You don't have armor");
        else
            g_gameRules.game:SendTextMessage(0, userId, "You don't have armor");
        end
    end
end

--------------------------------------------------------------------------
------------------------- CUSTOM ITEMS SCRIPTS END -----------------------
--------------------------------------------------------------------------

--------------------------------------------------------------------------
---------------------------- CUSTOM UI SCRIPTS ---------------------------
--------------------------------------------------------------------------

SCAAMBRUIFunctions = {};

-- SCAAMBRUIFunctions:OpenMenu
-- Opens the menu UI and registers the actions
function SCAAMBRUIFunctions:OpenMenu()
    UIAction.ShowElement('mod_SCAAMBRMenuUI', 0);
    UIAction.RegisterElementListener(self, 'mod_SCAAMBRMenuUI', 0, 'onGoNextGame', 'LoadNextGame');
    UIAction.RegisterElementListener(self, 'mod_SCAAMBRMenuUI', 0, 'onGoPrevGame', 'LoadPrevGame');
    UIAction.RegisterElementListener(self, 'mod_SCAAMBRMenuUI', 0, 'onSelectLocation', 'SelectLocation');
end

-- SCAAMBRUIFunctions:UpdateGameData
-- Updates the game data in the scoreboard tab
function SCAAMBRUIFunctions:UpdateGameData(menuData)
    UIAction.CallFunction('mod_SCAAMBRMenuUI', 0, 'UpdateGameData', SCAAMBRJSON.stringify(menuData));
end

-- SCAAMBRUIFunctions:UpdateMenuData
-- Updates the whole menu data for players who have the menu UI opened
function SCAAMBRUIFunctions:UpdateMenuData(menuData)
    UIAction.SetVariable('mod_SCAAMBRMenuUI', 0, 'GlobalPlayerStats', SCAAMBRJSON.stringify(menuData.MyStats));
    UIAction.SetVariable('mod_SCAAMBRMenuUI', 0, 'GlobalTopBoard', SCAAMBRJSON.stringify(menuData.TopFifteen));
    UIAction.SetVariable('mod_SCAAMBRMenuUI', 0, 'GlobalMapData', SCAAMBRJSON.stringify(menuData.MapData));
    UIAction.SetVariable('mod_SCAAMBRMenuUI', 0, 'UpdatedWithoutData', true);
    UIAction.CallFunction('mod_SCAAMBRMenuUI', 0, 'UpdateMenuData', tostring(menuData.GameData.MinGame), tostring(menuData.GameData.MaxGame));
end

-- SCAAMBRUIFunctions:CloseTheNote
-- Closes the note UI, it doesn't perform any action
function SCAAMBRUIFunctions:CloseMenu()
    Script.SetTimerForFunction(100, 'SCAAMBRUIFunctions.CloseTheMenu', self);
    Script.SetTimerForFunction(200, 'SCAAMBRUIFunctions.ReactivateFilters', self);
end

-- SCAAMBRUIFunctions:ActivateMenuAfterDelay
-- Activates the menu after a 25ms delay
function SCAAMBRUIFunctions:ActivateMenuAfterDelay(menuData)
    self.menuData = menuData;
    Script.SetTimerForFunction(25, 'SCAAMBRUIFunctions.ActivateMenu', self);
end

function SCAAMBRUIFunctions:ActivateMenu()
    SCAAMBRUIFunctions:DeactivateFilters();
    UIAction.SetVariable('mod_SCAAMBRMenuUI', 0, 'GlobalPlayerStats', SCAAMBRJSON.stringify(self.menuData.MyStats));
    UIAction.SetVariable('mod_SCAAMBRMenuUI', 0, 'GlobalGameData', SCAAMBRJSON.stringify(self.menuData.GameData));
    UIAction.SetVariable('mod_SCAAMBRMenuUI', 0, 'GlobalTopBoard', SCAAMBRJSON.stringify(self.menuData.TopFifteen));
    UIAction.SetVariable('mod_SCAAMBRMenuUI', 0, 'GlobalMapData', SCAAMBRJSON.stringify(self.menuData.MapData));
    UIAction.CallFunction('mod_SCAAMBRMenuUI', 0, 'FillGameData');
end

-- SCAAMBRUIFunctions:CloseTheMenu
-- Closes the menu UI and unregisters the actions
function SCAAMBRUIFunctions:CloseTheMenu()
    UIAction.CallFunction('mod_SCAAMBRMenuUI', 0, 'goToScoreboard');
    UIAction.HideElement('mod_SCAAMBRMenuUI', 0);
    UIAction.UnregisterElementListener(self, 'mod_SCAAMBRMenuUI', 0, 'onGoNextGame', 'LoadNextGame');
    UIAction.UnregisterElementListener(self, 'mod_SCAAMBRMenuUI', 0, 'onGoPrevGame', 'LoadPrevGame');
    UIAction.UnregisterElementListener(self, 'mod_SCAAMBRMenuUI', 0, 'onSelectLocation', 'SelectLocation');
end

-- SCAAMBRUIFunctions:DeactivateFilters
-- Enables the filters to prevent player movement
function SCAAMBRUIFunctions:DeactivateFilters()
    ActionMapManager.EnableActionFilter('no_mouse', true);
    ActionMapManager.EnableActionFilter('no_mouseX', true);
    ActionMapManager.EnableActionFilter('no_mouseY', true);
    ActionMapManager.EnableActionFilter('no_move', true);
    ActionMapManager.EnableActionFilter('inventory', true);
    ActionMapManager.EnableActionFilter('ladder_only', true);
end

-- SCAAMBRUIFunctions:ReactivateFilters
-- Disables the filters so the player can move again
function SCAAMBRUIFunctions:ReactivateFilters()
    ActionMapManager.EnableActionFilter('no_mouse', false);
    ActionMapManager.EnableActionFilter('no_mouseX', false);
    ActionMapManager.EnableActionFilter('no_mouseY', false);
    ActionMapManager.EnableActionFilter('no_move', false);
    ActionMapManager.EnableActionFilter('inventory', false);
    ActionMapManager.EnableActionFilter('ladder_only', false);
end

-- SCAAMBRUIFunctions:ReactivateInitFilters
-- Disables all the potential filters on respawn to potentially fix the freeze issue
function SCAAMBRUIFunctions:ReactivateInitFilters()
    ActionMapManager.EnableActionFilter('no_mouse', false);
    ActionMapManager.EnableActionFilter('no_mouseX', false);
    ActionMapManager.EnableActionFilter('no_mouseY', false);
    ActionMapManager.EnableActionFilter('no_move', false);
    ActionMapManager.EnableActionFilter('inventory', false);
    ActionMapManager.EnableActionFilter('ladder_only', false);
    ActionMapManager.EnableActionFilter('not_yet_spawned', false);
    ActionMapManager.EnableActionFilter('tutorial_no_move', false);
    ActionMapManager.EnableActionFilter('freezetime', false);
    ActionMapManager.EnableActionFilter('pregamefreeze', false);
    ActionMapManager.EnableActionFilter('only_ui', false);
    ActionMapManager.EnableActionFilter('ingame_menu', false);
    ActionMapManager.EnableActionFilter('scoreboard', false);
    ActionMapManager.EnableActionFilter('infiction_menu', false);
    ActionMapManager.EnableActionFilter('warning_popup', false);
    ActionMapManager.EnableActionFilter('hostmigration', false);
    ActionMapManager.EnableActionFilter('mp_chat', false);
    -- ActionMapManager.EnableActionFilter('cutscene_player_moving', false);
    -- ActionMapManager.EnableActionFilter('cutscene_no_player', false);
    -- ActionMapManager.EnableActionFilter('cutscene_train', false);
    -- ActionMapManager.EnableActionFilter('vehicle_no_seat_change_and_exit', false);
    ActionMapManager.EnableActionFilter('no_connectivity', false);
    -- ActionMapManager.EnableActionFilter('strikePointerDeployed', false);
    ActionMapManager.EnableActionFilter('useKeyOnly', false);
    ActionMapManager.EnableActionFilter('mp_weapon_customization_menu', false);
    -- ActionMapManager.EnableActionFilter('ledge_grab', false);
    -- ActionMapManager.EnableActionFilter('vault', false);
    ActionMapManager.EnableActionFilter('button_mashing_sequence', false);
    -- ActionMapManager.EnableActionFilter('incapacitated_partial', false);
    -- ActionMapManager.EnableActionFilter('incapacitated_full', false);
    ActionMapManager.EnableActionFilter('incapacitated_unconcious', false);

    -- Log('filter not_yet_spawned: ' .. tostring(ActionMapManager.IsFilterEnabled('not_yet_spawned')))
    -- Log('filter tutorial_no_move: ' .. tostring(ActionMapManager.IsFilterEnabled('tutorial_no_move')))
    -- Log('filter freezetime: ' .. tostring(ActionMapManager.IsFilterEnabled('freezetime')))
    -- Log('filter pregamefreeze: ' .. tostring(ActionMapManager.IsFilterEnabled('pregamefreeze')))
    -- Log('filter only_ui: ' .. tostring(ActionMapManager.IsFilterEnabled('only_ui')))
    -- Log('filter ingame_menu: ' .. tostring(ActionMapManager.IsFilterEnabled('ingame_menu')))
    -- Log('filter scoreboard: ' .. tostring(ActionMapManager.IsFilterEnabled('scoreboard')))
    -- Log('filter infiction_menu: ' .. tostring(ActionMapManager.IsFilterEnabled('infiction_menu')))
    -- Log('filter warning_popup: ' .. tostring(ActionMapManager.IsFilterEnabled('warning_popup')))
    -- Log('filter hostmigration: ' .. tostring(ActionMapManager.IsFilterEnabled('hostmigration')))
    -- Log('filter mp_chat: ' .. tostring(ActionMapManager.IsFilterEnabled('mp_chat')))
    -- Log('filter cutscene_player_moving: ' .. tostring(ActionMapManager.IsFilterEnabled('cutscene_player_moving')))
    -- Log('filter cutscene_no_player: ' .. tostring(ActionMapManager.IsFilterEnabled('cutscene_no_player')))
    -- Log('filter cutscene_train: ' .. tostring(ActionMapManager.IsFilterEnabled('cutscene_train')))
    -- Log('filter vehicle_no_seat_change_and_exit: ' .. tostring(ActionMapManager.IsFilterEnabled('vehicle_no_seat_change_and_exit')))
    -- Log('filter no_connectivity: ' .. tostring(ActionMapManager.IsFilterEnabled('no_connectivity')))
    -- Log('filter strikePointerDeployed: ' .. tostring(ActionMapManager.IsFilterEnabled('strikePointerDeployed')))
    -- Log('filter useKeyOnly: ' .. tostring(ActionMapManager.IsFilterEnabled('useKeyOnly')))
    -- Log('filter mp_weapon_customization_menu: ' .. tostring(ActionMapManager.IsFilterEnabled('mp_weapon_customization_menu')))
    -- Log('filter ledge_grab: ' .. tostring(ActionMapManager.IsFilterEnabled('ledge_grab')))
    -- Log('filter vault: ' .. tostring(ActionMapManager.IsFilterEnabled('vault')))
    -- Log('filter button_mashing_sequence: ' .. tostring(ActionMapManager.IsFilterEnabled('button_mashing_sequence')))
    -- Log('filter incapacitated_partial: ' .. tostring(ActionMapManager.IsFilterEnabled('incapacitated_partial')))
    -- Log('filter incapacitated_full: ' .. tostring(ActionMapManager.IsFilterEnabled('incapacitated_full')))
    -- Log('filter incapacitated_unconcious: ' .. tostring(ActionMapManager.IsFilterEnabled('incapacitated_unconcious')))
end

-- SCAAMBRUIFunctions:LoadNextGame
-- Retrieves the game data from the next game if there's one
function SCAAMBRUIFunctions:LoadNextGame()
    local player = System.GetEntity(g_localActorId);
    local currentGame = UIAction.GetVariable('mod_SCAAMBRMenuUI', 0, 'currentGame');
    currentGame = currentGame + 1;

    player.server:SCAAMBRGetTheMenuDat(g_localActorId, tostring(currentGame));
end

-- SCAAMBRUIFunctions:LoadPrevGame
-- Retrieves the game data from the previous game if there's one
function SCAAMBRUIFunctions:LoadPrevGame()
    local player = System.GetEntity(g_localActorId);
    local currentGame = UIAction.GetVariable('mod_SCAAMBRMenuUI', 0, 'currentGame');
    currentGame = currentGame - 1;

    player.server:SCAAMBRGetTheMenuDat(g_localActorId, tostring(currentGame));
end

-- SCAAMBRUIFunctions:LoadPrevGame
-- Sets a location where player will spawn for next game
function SCAAMBRUIFunctions:SelectLocation()
    local player = System.GetEntity(g_localActorId);
    local locationSelected = UIAction.GetVariable('mod_SCAAMBRMenuUI', 0, 'LocationSelected');

    player.server:SCAAMBRALocationDat(g_localActorId, locationSelected);
end

-- SCAAMBRUIFunctions:InitMapGame
-- Opens the menu map from the game, this map has markers for the player position and circle
-- and safe zone position and scale
function SCAAMBRUIFunctions:InitMapGame(gameData)
    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'InitGame', gameData);
end

-- SCAAMBRUIFunctions:OpenMapGame
-- Opens the menu map from the game, this map has markers for the player position and circle
-- and safe zone position and scale
function SCAAMBRUIFunctions:OpenMapGame()
    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'ToggleMap', true);
    SCAAMBRUIFunctions:DeactivateGameMapFilters();
end

-- SCAAMBRUIFunctions:UpdatePlayerPosAndRotationGame
-- Updates the player indicator position and rotation on the map game
function SCAAMBRUIFunctions:UpdatePlayerPosAndRotationGame(playerData)
    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'UpdatePlayerPosAndRotation', SCAAMBRJSON.stringify(playerData));
end

-- SCAAMBRUIFunctions:UpdateCirclePosAndScaleGame
-- Updates the circle position and scale on the map game
function SCAAMBRUIFunctions:UpdateCirclePosAndScaleGame(circleData)
    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'UpdateCirclePosAndScale', SCAAMBRJSON.stringify(circleData));
end

-- SCAAMBRUIFunctions:UpdateSafeZonePosAndScaleGame
-- Updates the safe zone position and scale on the map game
function SCAAMBRUIFunctions:UpdateSafeZonePosAndScaleGame(safeZoneData)
    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'UpdateSafeZonePosAndScale', SCAAMBRJSON.stringify(safeZoneData));
end

-- SCAAMBRUIFunctions:CleanIndicatorsGame
-- Removes all the indicators from the map game
function SCAAMBRUIFunctions:CleanIndicatorsGame()
    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'CleanIndicators');
end

-- SCAAMBRUIFunctions:CloseMapGame
-- Closes the menu map from the game
function SCAAMBRUIFunctions:CloseMapGame()
    UIAction.CallFunction('mod_SCAAMBRStatsUI', 0, 'ToggleMap', false);
    Script.SetTimerForFunction(200, 'SCAAMBRUIFunctions.ReactivateGameMapFilters', self);
end

-- SCAAMBRUIFunctions:DeactivateGameMapFilters
-- Enables the filters to prevent player mouse movement
function SCAAMBRUIFunctions:DeactivateGameMapFilters()
    ActionMapManager.EnableActionFilter('inventory', true);
    ActionMapManager.EnableActionFilter('ladder_only', true);
end

-- SCAAMBRUIFunctions:ReactivateGameMapFilters
-- Disables the filters so the player can use the mouse again
function SCAAMBRUIFunctions:ReactivateGameMapFilters()
    ActionMapManager.EnableActionFilter('inventory', false);
    ActionMapManager.EnableActionFilter('ladder_only', false);
end

-- -- SCAAMBRUIFunctions:DeactivateGameSpectateFilters
-- -- Enables the filters to prevent player movement
-- function SCAAMBRUIFunctions:DeactivateGameSpectateFilters()
--     ActionMapManager.EnableActionFilter('no_move', true);
--     ActionMapManager.EnableActionFilter('inventory', true);
--     ActionMapManager.EnableActionFilter('ladder_only', true);
-- end

-- -- SCAAMBRUIFunctions:ReactivateGameSpectateFilters
-- -- Disables the filters so the player can move again
-- function SCAAMBRUIFunctions:ReactivateGameSpectateFilters()
--     ActionMapManager.EnableActionFilter('no_move', false);
--     ActionMapManager.EnableActionFilter('inventory', false);
--     ActionMapManager.EnableActionFilter('ladder_only', false);
-- end

-- SCAAMBRManageMenu
-- Manages the menu custom keybinds
function SCAAMBRManageMenu(keyString)
    local player = System.GetEntity(g_localActorId);

    -- Checks if the players is not frozen previous game start so it can perform actions
    if (player.SCAAMBRFrozenPlayer == false) then
        if ((System.IsEditor() and keyString == 'backspace') or keyString == 'tilde') then

            -- Checks if the player can perform menu actions
            if (player.SCAAMBRToggledLobbyUI == true and player.SCAAMBRToggledMapUI == false and player.SCAAMBRToggledUI == true) then

                -- Checks in what state the menu is to either open or close it
                if (player.SCAAMBRMenuState == 'idle') then
                    player.server:SCAAMBRGetTheMenuDat(g_localActorId, '');
                else
                    SCAAMBRUIFunctions:CloseMenu();
                    UIAction.ShowElement('mod_SCAAMBRStatsUI', 0);
                    player.SCAAMBRMenuState = 'idle';
                end
            elseif (player.SCAAMBRToggledUI == true) then

                -- Checks if the player is in the lobby area because the maps displayed are coming
                -- from different UI's one does not have a cursor, the other one has to be able to
                -- select spawn points
                if (player.SCAAMBRToggledLobbyUI == true) then

                    if (player.SCAAMBRToggledMapUI == false) then
                        player.SCAAMBRToggledMapUI = true;
                        SCAAMBRUIFunctions:OpenMap();
                    else
                        player.SCAAMBRToggledMapUI = false;
                        SCAAMBRUIFunctions:CloseMap();
                    end
                else
                    if (player.SCAAMBRToggledMapUI == false) then
                        player.SCAAMBRToggledMapUI = true;
                        SCAAMBRUIFunctions:OpenMapGame();
                    else
                        player.SCAAMBRToggledMapUI = false;
                        SCAAMBRUIFunctions:CloseMapGame();
                    end
                end
            end
        -- elseif (keyString == 'backspace') then
        --     local listOfPlayers = System.GetEntitiesInSphereByClass(player:GetWorldPos(), 3, 'Player');
        --     dump(listOfPlayers, nil, 2);
        --     Log("Players found: " .. tostring(table.getn(listOfPlayers)));

        --     -- Perform spectate actions
        --     -- player.SCAAMBRToggledLobbyUI == false
        --     if (player.SCAAMBRToggledSpectateUI == false) then
        --         Log('Entered backspace to activate spectate')
        --         player.server:SCAAMBRManageSpectatePlayer(g_localActorId, 'spectate', 'true');
        --     elseif (player.SCAAMBRToggledSpectateUI == true) then
        --         Log('Entered backspace to deactivate spectate')
        --         SCAAMBRUIFunctions:ReactivateGameSpectateFilters();
        --         player:SetWorldPos(self.SCAAMBRSavedOwnPosition);
        --         player.SCAAMBRToggledSpectateUI = false;
        --         player.server:SCAAMBRManageSpectatePlayer(g_localActorId, 'spectate', 'false');
        --     end
        elseif (keyString == 'escape') then

            -- Checks if the player can perform menu actions
            if (player.SCAAMBRToggledLobbyUI == true and player.SCAAMBRToggledUI == true) then

                -- Checks in what state the menu is to close the menu
                if (player.SCAAMBRMenuState == 'active') then
                    SCAAMBRUIFunctions:CloseMenu();
                    UIAction.ShowElement('mod_SCAAMBRStatsUI', 0);
                    player.SCAAMBRMenuState = 'idle';
                end
            elseif (player.SCAAMBRToggledMapUI == true and player.SCAAMBRToggledUI == true) then

                -- Closes the map during game
                SCAAMBRUIFunctions:CloseMapGame();

                player.SCAAMBRToggledMapUI = false;
            end
        end
    end
end

-- SCAAMBRGetMenuData
-- Retrieves all the needed information from MisDB to pass it to the client menu
function SCAAMBRGetMenuData(playerId, newData)
    local player = System.GetEntity(playerId);
    local steamId = player.player:GetSteam64Id();
    local playerChannel = player.actor:GetChannel();

    -- Creates a table with all the needed information
    if (newData == '') then
        local lastGame = SCAAMBRDatabase:GetPage('GameNumber');

        local gameData = {data = 'noData'};

        if (lastGame ~= nil) then
            gameData = new(SCAAMBRDatabase:GetPage('Game' .. lastGame));
            gameData.MaxGame = tostring(lastGame);
            gameData.MinGame = tostring(SCAAMBRDatabase:GetPage('GameNumberMin'));
            gameData.GameNum = tostring(gameData.GameNum);
            gameData.PlayerCount = tostring(gameData.PlayerCount);

            local simplifiedScoreboard = {};

            -- Creates the simplified table to save characters for the RMI
            for key, value in pairs(gameData.Scoreboard) do
                local scoreRow = {value.Position, value.Name, tostring(value.Kills), tostring(value.Damage), tostring(value.Time)};

                if (value.SteamId == steamId) then
                    table.insert(scoreRow, 1);
                end
                
                table.insert(simplifiedScoreboard, scoreRow);
            end

            gameData.Scoreboard = simplifiedScoreboard;
        end

        -- Gets the player stats in a simplified form
        local myStats = SCAAMBRPlayerDatabase:GetPage(steamId);
        if (myStats == nil) then
            myStats = {};
        else
            myStats = new(myStats);
            myStats.SoloGames = tostring(myStats.SoloGames);
            myStats.SoloWins = tostring(myStats.SoloWins);
            myStats.Kills = tostring(myStats.Kills);
            myStats.Damage = tostring(myStats.Damage);
            myStats.Deaths = tostring(myStats.Deaths);
        end

        -- Gets the top 15 in a simplified form
        local topFifteen = SCAAMBRGetTopFifteen();

        -- Gets the map data in a simplified form
        local playerLocation = '';

        if (player.SCAAMBRSpawnPoint ~= nil) then
            playerLocation = player.SCAAMBRSpawnPoint;
        end
        
        local mapData = {
            Locations = SCAAMBRGetProcessedLocations();
            Location = playerLocation,
            MapScale = SCAAMBattleRoyaleProperties.MapSize
        };

        local allTheInfo = {
            GameData = gameData,
            MyStats = myStats,
            TopFifteen = topFifteen,
            MapData = mapData
        };

        -- Sends the JSON string in small chunks
        SCAAMBRFillMenuData(allTheInfo, 'open', player, playerChannel);
    else
        local gameData = new(SCAAMBRDatabase:GetPage('Game' .. newData));
        gameData.MaxGame = tostring(SCAAMBRDatabase:GetPage('GameNumber'));
        gameData.MinGame = tostring(SCAAMBRDatabase:GetPage('GameNumberMin'));
        gameData.GameNum = tostring(gameData.GameNum);
        gameData.PlayerCount = tostring(gameData.PlayerCount);

        local simplifiedScoreboard = {};

        -- Creates the simplified table to save characters for the RMI
        for key, value in pairs(gameData.Scoreboard) do
            local scoreRow = {value.Position, value.Name, tostring(value.Kills), tostring(value.Damage), tostring(value.Time)};

            if (value.SteamId == steamId) then
                table.insert(scoreRow, 1);
            end
            
            table.insert(simplifiedScoreboard, scoreRow);
        end

        gameData.Scoreboard = simplifiedScoreboard;

        -- Sends the JSON string in small chunks
        SCAAMBRFillMenuData(gameData, 'updategamedata', player, playerChannel);
    end
end

-- SCAAMBRFillMenuData
-- Fills all the information before opening or updating the menu
function SCAAMBRFillMenuData(allTheInfo, operation, player, playerChannel)

    -- Sends the JSON string in small chunks
    local JSONText = SCAAMBRJSON.stringify(allTheInfo);

    local JSONLength = string.len(JSONText);
    local textChunk = math.ceil(JSONLength / 1000);
    local chunkData = {};

    for i = 1, textChunk, 1 do
        if (i == 1) then
            table.insert(chunkData, string.sub(JSONText, 1, 1000));
        else
            table.insert(chunkData, string.sub(JSONText, ((i - 1) * 1000 + 1), (i * 1000)));
        end
    end

    -- Grabs the first 4 chunks of the table and calls the function to fill data
    -- If there's still chunks left, the client will call another server function to retrieve
    -- these chunks
    local chunksToRemove = 4;
    local chunksToGrab = {};
    local stillHasChunks = false;
    local insertedChunks = 0;

    while (chunksToRemove > 0) do

        -- Checks if the table has chunks
        if (table.getn(chunkData) > 0) then
            table.insert(chunksToGrab, table.remove(chunkData, 1));
            insertedChunks = insertedChunks + 1;
        else
            table.insert(chunksToGrab, '');
        end

        chunksToRemove = chunksToRemove - 1;
    end

    -- Checks if the table still has chunks
    if (table.getn(chunkData) > 0) then
        stillHasChunks = true;
        player.SCAAMBRTotalChunks = textChunk;
        player.SCAAMBRRemainingChunks = chunkData;
    end

    player.onClient:SCAAMBRBuildTheDataUI(playerChannel, operation, stillHasChunks, insertedChunks, textChunk, chunksToGrab[1], chunksToGrab[2], chunksToGrab[3], chunksToGrab[4]);
end

-- SCAAMBRAskForChunksData
-- Retrieves the remaining chunks from the temporary player data
function SCAAMBRAskForChunksData(playerId, totalChunks, operation)
    local player = System.GetEntity(playerId);
    local playerChannel = player.actor:GetChannel();

    -- Grabs the first 4 chunks of the table and calls the function to fill data
    -- If there's still chunks left, the client will call another server function to retrieve
    -- these chunks
    local chunksToRemove = 4;
    local chunksToGrab = {};
    local stillHasChunks = false;
    local insertedChunks = 0;

    while (chunksToRemove > 0) do

        -- Checks if the table has chunks
        if (table.getn(player.SCAAMBRRemainingChunks) > 0) then
            table.insert(chunksToGrab, table.remove(player.SCAAMBRRemainingChunks, 1));
            insertedChunks = insertedChunks + 1;
        else
            table.insert(chunksToGrab, '');
        end

        chunksToRemove = chunksToRemove - 1;
    end

    -- Checks if the table still has chunks
    if (table.getn(player.SCAAMBRRemainingChunks) > 0) then
        stillHasChunks = true;
        player.SCAAMBRTotalChunks = totalChunks;
    end

    player.onClient:SCAAMBRBuildTheDataUI(playerChannel, operation, stillHasChunks, insertedChunks, totalChunks, chunksToGrab[1], chunksToGrab[2], chunksToGrab[3], chunksToGrab[4]);
end

-- SCAAMBRGetTopFifteen
-- Generates the table with the top 15 on kills and damage
function SCAAMBRGetTopFifteen()
    local topFifteen = {};
    local topFifteenKills = {};
    local topFifteenDamage = {};
    local topFifteenWins = {};
    
    -- Checks if there's even players to make a top 15 from
    if (SCAAMBRPlayerDatabase.parent.db['SCAAMBattleRoyalePlayerCollection'] ~= nil and SCAAMBRPlayerDatabase.parent.db['SCAAMBattleRoyalePlayerCollection'] ~= {}) then  
        local count = 0;

        for _ in pairs(SCAAMBRPlayerDatabase.parent.db['SCAAMBattleRoyalePlayerCollection']) do
            count = count + 1;
            if (count > 1) then
                break;
            end
        end
        
        if (count > 0) then

            -- Creates a top 15 for killers, damage dealers and winners
            for _, value in pairs(SCAAMBRPlayerDatabase.parent.db['SCAAMBattleRoyalePlayerCollection']) do
                local simplifiedTopFifteen = {};

                local topFifteenRow = {value.Name, value.SoloWins, value.Kills, value.Damage};

                table.insert(topFifteen, topFifteenRow);
            end
    
            table.sort(topFifteen, function(a, b) return a[3] > b[3] end);

            for i = 1, 15, 1 do
                local topFifteenRow = {topFifteen[i][1], tostring(topFifteen[i][2]), tostring(topFifteen[i][3]), tostring(topFifteen[i][4])};
                table.insert(topFifteenKills, topFifteenRow);
            end

            table.sort(topFifteen, function(a, b) return a[4] > b[4] end);

            for i = 1, 15, 1 do
                local topFifteenRow = {topFifteen[i][1], tostring(topFifteen[i][2]), tostring(topFifteen[i][3]), tostring(topFifteen[i][4])};
                table.insert(topFifteenDamage, topFifteenRow);
            end

            table.sort(topFifteen, function(a, b) return a[2] > b[2] end);

            for i = 1, 15, 1 do
                local topFifteenRow = {topFifteen[i][1], tostring(topFifteen[i][2]), tostring(topFifteen[i][3]), tostring(topFifteen[i][4])};
                table.insert(topFifteenWins, topFifteenRow);
            end
        else
            return {data = 'noData'};
        end
    else
        return {data = 'noData'};
    end

    return {
        topFifteenK = topFifteenKills,
        topFifteenD = topFifteenDamage,
        topFifteenW = topFifteenWins
    }
end

-- SCAAMBRGetProcessedLocations
-- Prepares the locations for the UI
function SCAAMBRGetProcessedLocations()
    local locations = {};

    -- Loops through all the locations to get their
    for key, position in pairs(SCAAMBRPlayerProperties.Positions) do
        local locationData = {};
        table.insert(locationData, key);

        local coordinatesData = {};
        table.insert(coordinatesData, position.Main.x);
        table.insert(coordinatesData, position.Main.y);

        table.insert(locationData, coordinatesData);

        -- Finishes inserting the processed data
        table.insert(locations, locationData);
    end

    return locations;
end

--------------------------------------------------------------------------
-------------------------- CUSTOM UI SCRIPTS END -------------------------
--------------------------------------------------------------------------

--------------------------------------------------------------------------
---------------------------- SPECTATOR SCRIPTS ---------------------------
--------------------------------------------------------------------------

-- SCAAMBRManageSpectate
-- It controls the spectator controls, (start/stop spectating, switch next/prev player)
function SCAAMBRManageSpectate(playerId, action, value)
    local player = System.GetEntity(playerId);

    -- Actions for spectating
    Log('Entered Manage spectate')
    if (action == 'spectate') then

        Log('Entered spectate')
        if (value == 'true') then
            Log('Entered spectate true')
            local listOfPlayers = CryAction.GetPlayerList();
            local spectatedPlayer = nil;
            local spectatedPlayerPos = {};

            for key, player2 in pairs(listOfPlayers) do
                if (playerId ~= player2.id) then
                    spectatedPlayer = player2.id;
                    spectatedPlayerPos = player2:GetWorldPos();
                    break;
                end
            end

            if (spectatedPlayer ~= nil) then
                Log('Entered someone to spectate')
                -- Found a player to spectate so it starts the process to spectate them
                local ownPlayerPos = player:GetWorldPos();
                player:Hide(1);
                Log('Entered hidden player')

                local playerChannel = player.actor:GetChannel();

                player.onClient:SCAAMBRWatchThePlayer(playerChannel, spectatedPlayerPos, ownPlayerPos);
            else

                -- Editor or server specific actions
                if (System.IsEditor()) then
                    g_gameRules.game:SendTextMessage(0, g_localActorId, "Couldn't find a player to spectate");
                else
                    g_gameRules.game:SendTextMessage(0, playerId, "Couldn't find a player to spectate");
                end
            end
        else
            Log('Entered spectate false')
            player:Hide(0);
        end
    end
    Log('Finished Manage spectate')
end

-- SCAAMBRSpectatePlayerTimer
-- Calls the Spectate function every 50ms
function SCAAMBRSpectatePlayerTimer()
    Script.SetTimerForFunction(50, 'SCAAMBRSpectatePlayer', {});
end

-- SCAAMBRSpectatePlayer
-- Updates the player position towards the spectated player
function SCAAMBRSpectatePlayer(dummyVar)
    Log('Spectating player after a 50ms delay: ' .. tostring(self.SCAAMBRToggledSpectateUI))
    if (self.SCAAMBRToggledSpectateUI == true) then
        Log('I can spectate right now')
        local player = System.GetEntity(g_localActorId);
        local spectatedPlayer = System.GetEntity(self.SCAAMBRSpectatedPlayerId);

        if (spectatedPlayer and spectatedPlayer.player) then
            player:SetWorldPos(spectatedPlayer:GetWorldPos());
        end
    end
end

--------------------------------------------------------------------------
-------------------------- SPECTATOR SCRIPTS END -------------------------
--------------------------------------------------------------------------

-- Validating if Miscreated:RevivePlayer is set
if not (Miscreated.RevivePlayer) then
    Log("SCAAMBattleRoyale >> Setting a generic Miscreated:RevivePlayer to make it exist");
    Miscreated.RevivePlayer = function (self, playerId)
        Log("SCAAMBattleRoyale >> This is the generic Miscreated:RevivePlayer call");
    end
end

-- Validating if Miscreated:InitPlayer is set
if not (Miscreated.InitPlayer) then
    Log("SCAAMBattleRoyale >> Setting a generic Miscreated:InitPlayer to make it exist");
    Miscreated.InitPlayer = function (self, playerId)
        Log("SCAAMBattleRoyale >> This is the generic Miscreated:InitPlayer call");
    end
end

-- Validating if Miscreated:EquipPlayer is set
if not (Miscreated.EquipPlayer) then
    Log("SCAAMBattleRoyale >> Setting a generic Miscreated:EquipPlayer to make it exist");
    Miscreated.EquipPlayer = function (self, playerId)
        Log("SCAAMBattleRoyale >> This is the generic Miscreated:EquipPlayer call");
    end
end

-- Calling the Miscreated Init player function to teleport the player to the lobby area
RegisterCallbackReturnAware(
    Miscreated,
    'InitPlayer',
    nil,
    function (self, ret, playerId)

        -- Tries to teleport the player to a lobby spawn in hopes to fix the issue with the freeze
        local player = System.GetEntity(playerId);

        player:SetWorldPos(SCAAMBRLobbyProperties.Positions[math.random(table.getn(SCAAMBRLobbyProperties.Positions))].Position);

        return ret;
    end
);

-- Calling the Miscreated Revive player function to initialize the BR script
RegisterCallbackReturnAware(
    Miscreated,
    'RevivePlayer',
    nil,
    function (self, ret, playerId)

        -- Initializes the BR scripts when the first player ever connects to the server
        if (SCAAMBattleRoyalePlayerManagement.HasTheScriptInitialized == false) then

            -- Sets the time and weather to a permantent 14:00 time and ClearSky
            System.ExecuteCommand('wm_forceTime 14');
            System.ExecuteCommand('wm_pattern 1');
            System.ExecuteCommand('g_playerInfiniteStamina 1');

            -- Calls the function to get the general spawners
            SCAAMBRGetSpawners();
            
            -- Editor or server specific actions
            if (not System.IsEditor()) then

                -- Sets the Battle Royale for the first time
                SCAAMBRSitAndRelax();
            end

            SCAAMBattleRoyalePlayerManagement.HasTheScriptInitialized = true;
        end

        local player = System.GetEntity(playerId);

        if (player and player.player) then

            -- Restarts the player selected spawn point
            player.SCAAMBRSpawnPoint = nil;

            -- Sets the player state to be InLobby
            player.SCAAMBRState = 'InLobby';

            -- Set the special item usage flags
            player.SCAAMBRIsApplyingStimPack = false;
            player.SCAAMBRIsApplyingArmor = false;

            -- Sets the armor to 0
            player.SCAAMBRArmor = 0;

            -- Sets the kill count to 0
            player.SCAAMBRKills = 0;

            -- Sets the damage dealt to 0
            player.SCAAMBRDamageDealt = 0;

            -- Assign custom BR keybinds to players
            local playerChannel = player.actor:GetChannel();
            player.onClient:SCAAMBRInitThePlayer(playerChannel);

            -- Inits the custom UI support for players
            player.onClient:SCAAMBRUIInit(playerChannel);

            -- Removes all items from the player after a delay
            Script.SetTimerForFunction(SCAAMBattleRoyalePlayerManagement.WaitingTimer, 'SCAAMBRCleanPlayerAfterDelay', {PlayerId = playerId});
        end

        return ret;
    end
);

-- Calling the Miscreated Equip player function to get the player naked and equip it only when the game starts
RegisterCallbackReturnAware(
    Miscreated,
    'EquipPlayer',
    function (self, ret, playerId)
        -- It does nothing, that's the idea, the player has to spawn with no equipment
        return ret;
    end,
    nil
);

-- Calling the Player Kill function to register kills function on Server init
RegisterCallback(
    Player.Server,
    'OnHit',
    function (player, hit)
        SCAAMBRPreRegisterHit(hit);
    end,
    function (player, hit)
        SCAAMBRRegisterHit(hit);
    end
);

-- !brminplayers <subcommand>
-- Uses the !brminplayers command with a subcommand to set the minimum player required to play
ChatCommands["!brminplayers"] = function(playerId, command)
    local player = System.GetEntity(playerId);
    local steamId = player.player:GetSteam64Id();

    -- Checks if the player has permissions to perform this command
    if (string.match(System.GetCVar('g_gameRules_faction4_steamids'), steamId)) then
        SCAAMBattleRoyalePropertiesBackup.MinPlayers = tonumber(command);

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, 'Min players to play set to ' .. tostring(command));
        else
            g_gameRules.game:SendTextMessage(0, playerId, 'Min players to play set to ' .. tostring(command));
        end
    end
end

-- !brminplayers <subcommand>
-- Uses the !brminplayers command with a subcommand to set the minimum player required to play
ChatCommands["!brwinplayers"] = function(playerId, command)
    local player = System.GetEntity(playerId);
    local steamId = player.player:GetSteam64Id();

    -- Checks if the player has permissions to perform this command
    if (string.match(System.GetCVar('g_gameRules_faction4_steamids'), steamId)) then
        SCAAMBattleRoyalePropertiesBackup.MinToWin = tonumber(command);

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, 'Min players to win set to ' .. tostring(command));
        else
            g_gameRules.game:SendTextMessage(0, playerId, 'Min players to win set to ' .. tostring(command));
        end
    end
end

-- #spawnEntity('SCAAMBattleRoyaleCircle');

-- GENERAL TODO:
-- Try to execute the things that involve times in another thread in hopes to prevent the slowness
-- Make Use of the new CVAR to disable player saving on inventory so InitPlayer and EquipPlayer can work properly and fix the frozen issue
-- Add custom context actions to armor and stim packs
-- Add Vehicles after the update drops
-- Add logic for squad mode

--------------------------------------------------------------------------------
----------------- TESTING FUNCTIONS AND PARAMETERS, DO NOT TOUCH ---------------
--------------------------------------------------------------------------------

-- #SCAAMBRSitAndRelax();
-- #ChatCommands['!brselectspawn'](g_localActorId, 'Forestlands');
-- #ChatCommands['!brcheckspawn'](g_localActorId, '');
-- #Log(player.SCAAMBRSpawnPoint);

-- function testUpdate()
--     local player = System.GetEntity(g_localActorId);
--     -- Updates the player stats with the game's data
--     local playerSteamID = player.player:GetSteam64Id();
--     local playerPersistentData = SCAAMBRPlayerDatabase:GetPage(playerSteamID);

--     if (playerPersistentData == nil) then
--         playerPersistentData = {
--             Name = player:GetName(),
--             Kills = 0,
--             Deaths = 0,
--             SoloGames = 0,
--             SquadGames = 0,
--             SoloWins = 0,
--             SquadWins = 0,
--             Damage = 0
--         };
--     else
--         playerPersistentData.Kills = playerPersistentData.Kills + 12;
--         playerPersistentData.SoloGames = playerPersistentData.SoloGames + 1;
--         playerPersistentData.SoloWins = playerPersistentData.SoloWins + 1;
--         playerPersistentData.Damage = playerPersistentData.Damage + 468;
--     end

--     -- Gets the games played on the server and updates it
--     local gameNumber = SCAAMBRDatabase:GetPage('GameNumber');
            
--     if (gameNumber == nil) then
--         gameNumber = 0;
--     end

--     local gameTable = {
--         Winner = '',
--         PlayerCount = 1,
--         TotalTime = 0,
--         Scoreboard = {}
--     };

--     -- Submits the score to the stats table
--     local stats = {
--         Name = player:GetName(),
--         SteamId = player.player:GetSteam64Id();
--         Kills = 12,
--         Damage = 468,
--         Time = 356,
--         Position = 1
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '2 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 2
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '3 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 3
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '4 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 4
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '5 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 5
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '6 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 6
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '7 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 7
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '8 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 8
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '9 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 9
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '10 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 10
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '11 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 11
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '12 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 12
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '13 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 13
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '14 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 14
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '15 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 15
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '16 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 16
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '17 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 17
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '18 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 18
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '19 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 19
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '20 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 20
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '21 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 21
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '22 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 22
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '23 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 23
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '24 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 24
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '25 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 25
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '26 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 26
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '27 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 27
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '28 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 28
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '29 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 29
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '30 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 30
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '31 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 31
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '32 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 32
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '33 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 33
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '34 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 34
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '35 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 35
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '36 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 36
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '37 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 37
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '38 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 38
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '39 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 39
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '40 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 40
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '41 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 41
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '42 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 42
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '43 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 43
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '44 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 44
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '45 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 45
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '46 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 46
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '47 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 47
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '48 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 48
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '49 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,
--         Damage = 413,
--         Time = 78,
--         Position = 49
--     };

--     table.insert(gameTable.Scoreboard, stats);

--     stats = {
--         Name = '50 Temp player long name',
--         SteamId = '8596954665';
--         Kills = 75,SCAAMBROpenTheMenuDat
--         Damage = 413,
--         Time = 78,
--         Position = 50
--     };

--     table.insert(gameTable.Scoreboard, stats);    

--     gameNumber = gameNumber + 1;
--     SCAAMBRDatabase:SetPage('GameNumber', gameNumber);
    
--     -- Submits the final data to the stats table
--     gameTable.Winner = player:GetName();
--     gameTable.TotalTime = 356;
--     gameTable.GameNum = gameNumber;

--     SCAAMBRDatabase:SetPage('Game' .. tostring(gameNumber), gameTable);
--     SCAAMBRPlayerDatabase:SetPage(playerSteamID, playerPersistentData);

--     -- Removes the 100th game data to save space
--     if (SCAAMBRDatabase:GetPage('Game' .. (gameNumber - 100)) ~= nil) then
--         SCAAMBRDatabase:PurgePage('Game' .. (gameNumber - 100));
--         SCAAMBRDatabase:SetPage('GameNumberMin', gameNumber - 99);
--         SCAAMBRDatabase.parent.db:save();
--     else
--         SCAAMBRDatabase:SetPage('GameNumberMin', 1);
--     end

--     SCAAMBRUpdateMenuDataGlobally();
-- end

-- local angles = player:GetAngles(); Log(tostring(angles.z * 180/g_Pi));

-- !spawnitem <subcommand>
-- Uses the !spawnitem command with a subcommand to spawn an item in the world
ChatCommands["!spawnitem"] = function(playerId, command)
    local player = System.GetEntity(playerId);
    local steamId = player.player:GetSteam64Id();

    -- Checks if the player has permissions to perform this command
    if (string.match(System.GetCVar('g_gameRules_faction4_steamids'), steamId)) then
        local vForwardOffset = {x=0, y=0, z=0};
        local vPointingPosition = {x=0, y=0, z=0};
        FastScaleVector(vForwardOffset, player:GetDirectionVector(), 2.0);
        FastSumVectors(vPointingPosition, vForwardOffset, player:GetWorldPos());

        local spawnParams = {};
        spawnParams.class = command;
        spawnParams.name = player:GetName() .. command .. tostring(math.random(666));
        spawnParams.orientation = player:GetDirectionVector();
        spawnParams.position = vPointingPosition;

        local spawnedEntity = System.SpawnEntity(spawnParams);
    end
end

-- !changetimer <subcommand>
-- Uses the !changetimer command with a subcommand to change the timer
ChatCommands["!changetimer"] = function(playerId, command)
    local player = System.GetEntity(playerId);
    local steamId = player.player:GetSteam64Id();

    -- Checks if the player has permissions to perform this command
    if (string.match(System.GetCVar('g_gameRules_faction4_steamids'), steamId)) then
        SCAAMBattleRoyalePlayerManagement.WaitingTimer = tonumber(command);

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, 'Changed timer to ' .. tostring(command));
        else
            g_gameRules.game:SendTextMessage(0, playerId, 'Changed timer to ' .. tostring(command));
        end
    end
end

-- !hide <subcommand>
-- Uses the !changetimer command with a subcommand to change the timer
ChatCommands["!hide"] = function(playerId, command)
    local player = System.GetEntity(playerId);
    local steamId = player.player:GetSteam64Id();

    -- Checks if the player has permissions to perform this command
    if (string.match(System.GetCVar('g_gameRules_faction4_steamids'), steamId)) then
        player:Hide(tonumber(command));

        -- Editor or server specific actions
        if (System.IsEditor()) then
            g_gameRules.game:SendTextMessage(0, g_localActorId, 'Hiding to ' .. tostring(command) .. ' worked?');
        else
            g_gameRules.game:SendTextMessage(0, playerId, 'Hiding to ' .. tostring(command) .. ' worked?');
        end
    end
end

-- !spectate <subcommand>
-- Uses the !spawnitem command with a subcommand to spawn an item in the world
ChatCommands["!spectate"] = function(playerId, command)
    local player = System.GetEntity(playerId);
    local listOfPlayers = CryAction.GetPlayerList();
    local spectatedPlayer = nil;
    local spectatedPlayerPos = {};

    for key, player2 in pairs(listOfPlayers) do
        if (playerId ~= player2.id) then
            spectatedPlayer = player2.id;
            spectatedPlayerPos = player2:GetWorldPos();
            break;
        end
    end

    if (spectatedPlayer ~= nil) then
        player.SCAAMBRSavedPosition = player:GetWorldPos();
        player:Hide(1);

        local playerChannel = player.actor:GetChannel();

        player.onClient:SCAAMBRSpectatePlayer(playerChannel, spectatedPlayerPos);
    end
end