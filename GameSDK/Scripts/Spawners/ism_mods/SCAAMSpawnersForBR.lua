ItemSpawnerManager = {
    itemCategories = {
        {
			-- The cargo drop crate has 30 slots
			category = "SCAAMBRRandomAirDropCrate",
			group =
			{
				{ category = "RandomAirDropCrate", percent = 100 },
			},
        },
        
        {
			category = "RandomAirDropCrate",
			group =
			{
                { category = "RandomBigPrimaryWeapon", percent = 100 },
                { category = "RandomBigPrimaryWeapon", percent = 100 },
                { category = "RandomBigSecondaryWeapon", percent = 100 },
                { category = "RandomBigSecondaryWeapon", percent = 100 },
                { category = "RandomBigMeleeWeapon", percent = 100 },
                { category = "RandomBigMeleeWeapon", percent = 100 },
                { category = "RandomUtilitaryWeapon", percent = 100 },
                { category = "RandomUtilitaryWeapon", percent = 100 },
                { category = "RandomMedicalItem", percent = 100 },
                { category = "RandomMedicalItem", percent = 100 },
                { class = "SCAAMStimPack", percent = 100 },
                { class = "SCAAMStimPack", percent = 100 },
                { class = "SCAAMArmor", percent = 100 },
                { class = "SCAAMArmor", percent = 100 },
                { category = "RandomRuggedPack", percent = 100 },
			},
        },

        {
			category = "RandomBigPrimaryWeapon",
			classes =
			{
                { category = "AKMGoldSet", percent = 10 },
                { category = "Mk18ReaverSet", percent = 13 },
				{ category = "ACAWSet", percent = 13 },
				{ category = "M40A5Set", percent = 13 },
				{ category = "AUMP45Set", percent = 13 },
				{ category = "MP5Set", percent = 13 },
                { category = "AKValSet", percent = 13 },
                { category = "AK5DSet", percent = 12 },
			},
        },

        {
			category = "AKMGoldSet",
			group =
			{
                { class = "AKMGold_jack_gold", percent = 100 },
                { class = "762x39_magazine", percent = 100, min = 30, max = 30 },
				{ class = "762x39_magazine", percent = 100, min = 30, max = 30 },
			},
        },

        {
			category = "Mk18ReaverSet",
			group =
			{
                { class = "Mk18Reaver_jack_gold", percent = 100 },
                { class = "556x45_magazine", percent = 100, min = 30, max = 30 },
                { class = "556x45_magazine", percent = 100, min = 30, max = 30 },
                { category = "RandomRifleScopeAttachment", percent = 100 },
			},
        },

        {
			category = "ACAWSet",
			group =
			{
                { class = "ACAW_jack_gold", percent = 100 },
                { class = "762x51_magazine", percent = 100, min = 5, max = 5 },
                { class = "762x51_magazine", percent = 100, min = 5, max = 5 },
                { category = "RandomBoltScopeAttachment", percent = 100 },
			},
        },

        {
			category = "M40A5Set",
			group =
			{
                { class = "M40A5_jack_gold", percent = 100 },
                { class = "762x51_magazine", percent = 100, min = 5, max = 5 },
                { class = "762x51_magazine", percent = 100, min = 5, max = 5 },
                { category = "RandomBoltScopeAttachment", percent = 100 },
			},
        },

        {
			category = "AUMP45Set",
			group =
			{
                { class = "AUMP45_jack_gold", percent = 100 },
                { class = "acp_45_ext_magazine", percent = 100, min = 30, max = 30 },
                { class = "acp_45_ext_magazine", percent = 100, min = 30, max = 30 },
                { category = "RandomSMGScopeAttachment", percent = 100 },
			},
        },

        {
			category = "MP5Set",
			group =
			{
                { class = "MP5_jack_gold", percent = 100 },
                { class = "10mm_ext_magazine", percent = 100, min = 30, max = 30 },
                { class = "10mm_ext_magazine", percent = 100, min = 30, max = 30 },
                { category = "RandomSMGScopeAttachment", percent = 100 },
			},
        },

        {
			category = "AKValSet",
			group =
			{
                { class = "AKVal_jack_gold", percent = 100 },
                { class = "762x39_magazine", percent = 100, min = 20, max = 20 },
                { class = "762x39_magazine", percent = 100, min = 20, max = 20 },
                { category = "RandomRifleScopeAttachment", percent = 100 },
			},
        },

        {
			category = "AK5DSet",
			group =
			{
                { class = "AK5D_jack_gold", percent = 100 },
                { class = "556x45_magazine", percent = 100, min = 30, max = 30 },
                { class = "556x45_magazine", percent = 100, min = 30, max = 30 },
                { category = "RandomRifleScopeAttachment", percent = 100 },
			},
        },

        {
			category = "RandomRifleScopeAttachment",
			classes =
			{
                { class = "ReddotSight", percent = 17 },
                { class = "T1Micro", percent = 17 },
				{ class = "ReflexSight", percent = 17 },
                { class = "OpticScope", percent = 17 },
                { class = "OPKSight", percent = 17 },
                { class = "R3Sight", percent = 15 },
			},
        },

        {
			category = "RandomBoltScopeAttachment",
			classes =
			{
                { class = "ReddotSight", percent = 15 },
                { class = "T1Micro", percent = 15 },
				{ class = "ReflexSight", percent = 15 },
                { class = "OpticScope", percent = 15 },
                { class = "HuntingScope", percent = 15 },
                { class = "OPKSight", percent = 15 },
                { class = "R3Sight", percent = 10 },
			},
        },

        {
			category = "RandomSMGScopeAttachment",
			classes =
			{
                { class = "ReddotSight", percent = 17 },
                { class = "T1Micro", percent = 17 },
				{ class = "ReflexSight", percent = 17 },
                { class = "OpticScope", percent = 17 },
                { class = "OPKSight", percent = 17 },
                { class = "R3Sight", percent = 15 },
			},
        },

        {
			category = "RandomBigSecondaryWeapon",
			classes =
			{
                { category = "ColtPythonGrimeyRickSet", percent = 20 },
                { category = "PX4Set", percent = 20 },
				{ category = "hk45Set", percent = 20 },
				{ category = "m1911a1Set", percent = 20 },
				{ category = "P350Set", percent = 20 },
			},
        },

        {
			category = "ColtPythonGrimeyRickSet",
			group =
			{
                { class = "ColtPythonGrimeyRick_jack_gold", percent = 100 },
                { class = "Pile_357", percent = 100, min = 6, max = 6 },
				{ class = "Pile_357", percent = 100, min = 6, max = 6 },
			},
        },

        {
			category = "PX4Set",
			group =
			{
                { class = "PX4_jack_gold", percent = 100 },
                { class = "acp_45_small_magazine", percent = 100, min = 10, max = 10 },
                { class = "acp_45_small_magazine", percent = 100, min = 10, max = 10 },
                { class = "PistolSilencer", percent = 100 },
			},
        },

        {
			category = "hk45Set",
			group =
			{
                { class = "hk45_jack_gold", percent = 100 },
                { class = "acp_45_small_magazine", percent = 100, min = 10, max = 10 },
                { class = "acp_45_small_magazine", percent = 100, min = 10, max = 10 },
                { class = "PistolSilencer", percent = 100 },
			},
        },

        {
			category = "m1911a1Set",
			group =
			{
                { class = "m1911a1_jack_gold", percent = 100 },
                { class = "acp_45_smaller_magazine", percent = 100, min = 7, max = 7 },
                { class = "acp_45_smaller_magazine", percent = 100, min = 7, max = 7 },
                { class = "PistolSilencer", percent = 100 },
			},
        },

        {
			category = "P350Set",
			group =
			{
                { class = "P350_jack_gold", percent = 100 },
                { class = "357_magazine", percent = 100, min = 14, max = 14 },
                { class = "357_magazine", percent = 100, min = 14, max = 14 },
                { class = "PistolSilencer", percent = 100 },
			},
        },

        {
			category = "RandomBigMeleeWeapon",
			classes =
			{
                { class = "AxePatrick", percent = 20 },
                { class = "BaseballBatHerMajesty", percent = 20 },
				{ class = "KatanaBlackWidow", percent = 20 },
				{ class = "Machete", percent = 20 },
				{ class = "Crowbar", percent = 20 },
			},
        },

        {
			category = "RandomUtilitaryWeapon",
			classes =
			{
                { class = "GrenadePickup", percent = 20 },
                { class = "GrenadeMolotovPickup", percent = 15 },
				{ class = "C4TimedPickup", percent = 15 },
				{ class = "PipebombPickup", percent = 15 },
                { class = "GrenadeSmokeWhitePickup", percent = 15 },
                { class = "FlashbangPickup", percent = 20 },
			},
        },

        {
			category = "RandomMedicalItem",
			classes =
			{
                { class = "Bandage", percent = 20 },
                { class = "AntibioticBandage", percent = 30 },
				{ class = "AdvancedBandage", percent = 50 },
			},
        },

        {
			category = "RandomRuggedPack",
			classes =
			{
                { class = "RuggedPack", percent = 10 },
                { class = "RuggedPackBlack", percent = 15 },
				{ class = "RuggedPackBrown", percent = 15 },
				{ class = "RuggedPackCamo1", percent = 15 },
				{ class = "RuggedPackCamo2", percent = 15 },
				{ class = "RuggedPackCamo3", percent = 15 },
				{ class = "RuggedPackCamo4", percent = 15 },
			},
        },
    }
}