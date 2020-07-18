-- Calling OnInitAllLoaded function to register the Battle royale config on level load
RegisterCallback(_G,
    'OnInitAllLoaded',
    nil,
    function ()
        Log("SCAAMBattleRoyale >> Loading BattleRoyale Config");
        SCAAMBRInitModules();

        -- Checks if the PlayerCorpse class has a server table, if not, define it
        if (not _G['PlayerCorpse'].Server) then
            _G['PlayerCorpse'].Server = {};
        end

        -- Overwrites the playercorpse OnHit function to do nothing
        _G['PlayerCorpse'].Server.OnHit = function(self)
            -- Do nothing
        end

        if _G["PatchVars"] then
            Log("Setup DEBUG Vars");
            PatchVars({
                ["g_debugRMI"] = 1,
                ["log_Verbosity"] = 4,
                ["net_log_remote_methods"] = 1,
                ['net_disconnect_on_rmi_error'] = 0
            });
        end
    end
);