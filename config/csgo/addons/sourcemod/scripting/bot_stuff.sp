#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <eItems>
#include <smlib>
#include <navmesh>
#include <dhooks>
#include <botmimic>
#include <PTaH>
#include <ripext>

StringMap g_hBotTemplates; // stores <name, template>

#define MAX_NADES 512
#define MAX_PEEKS 64
#define MAX_SMOKE_DIST 500.0
#define COST_VEST 650
#define COST_VESTHELM 1000
#define MAX_BOTS 64
#define MAX_TEMPLATE_NAME 32

char g_szMap[128];
char g_szCrosshairCode[MAXPLAYERS+1][35], g_szPreviousBuy[MAXPLAYERS+1][128];
bool g_bIsBombScenario, g_bIsHostageScenario, g_bFreezetimeEnd, g_bBombPlanted, g_bEveryoneDead, g_bBombExploded, g_bHalftimeSwitch, g_bIsCompetitive;
bool g_bRoundWonCT, g_bRoundWonT;
bool g_bUseCZ75[MAXPLAYERS+1], g_bUseUSP[MAXPLAYERS+1], g_bUseM4A1S[MAXPLAYERS+1], g_bDontSwitch[MAXPLAYERS+1], g_bDropWeapon[MAXPLAYERS+1], g_bHasGottenDrop[MAXPLAYERS+1];
bool g_bIsProBot[MAXPLAYERS+1], g_bIsIntermediateBot[MAXPLAYERS+1], g_bIsAWPer[MAXPLAYERS+1], g_bThrowGrenade[MAXPLAYERS+1], g_bUncrouch[MAXPLAYERS+1];
bool g_bBotHasForcedBuy[MAXPLAYERS+1]; g_bDidFakePlant[MAXPLAYERS+1], g_bFakePlantRolled[MAXPLAYERS + 1], g_bIsFakeDefusing[MAXPLAYERS+1], g_bDidRun[MAXPLAYERS+1], g_bBotCompromised[MAXPLAYERS+1], g_bDidInitialSwitch[MAXPLAYERS+1];
bool g_bHasSavedAWP[MAXPLAYERS + 1], g_bHasPickedUpAWP[MAXPLAYERS + 1], g_bIsAWPDonor[MAXPLAYERS + 1], g_bBuyDelayed[MAXPLAYERS + 1], g_bAWPDropQueued[MAXPLAYERS + 1], g_bDonationInProgress[MAXPLAYERS + 1], g_bShouldPickupDroppedGun[MAXPLAYERS + 1];
int g_iSavedAWPFor[MAXPLAYERS + 1];
int g_iProfileRank[MAXPLAYERS+1], g_iPlayerColor[MAXPLAYERS+1], g_iTarget[MAXPLAYERS+1], g_iPrevTarget[MAXPLAYERS+1], g_iDoingSmokeNum[MAXPLAYERS+1], g_iActiveWeapon[MAXPLAYERS+1];
int g_iCurrentRound, g_iRoundsPlayed, g_iCTScore, g_iTScore, g_iMaxNades, g_iRoundsLostCT, g_iRoundsLostT;
int g_iProfileRankOffset, g_iPlayerColorOffset;
int g_iCurrentBonusCT, g_iCurrentBonusT; 
int g_iPostPlantNadesStartIndex = 0;
int g_BombsiteEntities[64]; g_NumBombsites = 0;
int g_iBotTargetSpotOffset, g_iBotNearbyEnemiesOffset, g_iFireWeaponOffset, g_iEnemyVisibleOffset, g_iBotProfileOffset, g_iBotSafeTimeOffset, g_iBotEnemyOffset, g_iBotLookAtSpotStateOffset, g_iBotMoraleOffset, g_iBotTaskOffset, g_iBotDispositionOffset;
float g_fBotOrigin[MAXPLAYERS+1][3], g_fTargetPos[MAXPLAYERS+1][3], g_fNadeTarget[MAXPLAYERS+1][3];
float g_fRoundStart, g_fFreezeTimeEnd, g_fCurrentTime, g_fTimeElapsed, g_fRoundTimeRemaining, g_fBombTime, g_fTimeLeft; 
float g_fNadeClaimTime[MAX_NADES], g_fLastMoveTime[MAXPLAYERS + 1], g_fBombsiteDisableTime = 0.0, g_fLastFakeDefuseTime[MAXPLAYERS + 1], g_fLastKill[MAXPLAYERS + 1];
float g_fShootTimestamp[MAXPLAYERS+1], g_fThrowNadeTimestamp[MAXPLAYERS+1], g_fCrouchTimestamp[MAXPLAYERS+1];

ConVar g_hCvarIsAWP;
ConVar g_cvBotEcoLimit;
Handle g_hBotMoveTo;
Handle g_hLookupBone;
Handle g_hGetBonePosition;
Handle g_hBotIsVisible;
Handle g_hBotIsHiding;
Handle g_hBotEquipBestWeapon;
Handle g_hBotSetLookAt;
Handle g_hSetCrosshairCode;
Handle g_hSwitchWeaponCall;
Handle g_hIsLineBlockedBySmoke;
Handle g_hBotBendLineOfSight;
Handle g_hBotThrowGrenade;
Handle g_hAddMoney;
Address g_pTheBots;
CNavArea g_pCurrArea[MAXPLAYERS+1];

//BOT Nades Variables
float g_fNadePos[128][3], g_fNadeLook[128][3];
int g_iNadeDefIndex[128];
char g_szReplay[128][128];
float g_fNadeTimestamp[128];
int g_iNadeTeam[128];

float g_fPistolNadePos[128][3], g_fPistolNadeLook[128][3];
int g_iPistolNadeDefIndex[128], g_iPistolNadeTeam[128], g_iPistolNades;
char g_szPistolReplay[128][128];
float g_fPistolNadeTimestamp[128];

float g_fNormalNadePos[128][3], g_fNormalNadeLook[128][3];
int g_iNormalNadeDefIndex[128], g_iNormalNadeTeam[128], g_iNormalNades;
char g_szNormalReplay[128][128];
float g_fNormalNadeTimestamp[128];

float g_fPostPlantNadePos[128][3], g_fPostPlantNadeLook[128][3];
int g_iPostPlantNadeDefIndex[128], g_iPostPlantNadeTeam[128], g_iPostPlantNades;
char g_szPostPlantReplay[128][128];
float g_fPostPlantNadeTimestamp[128];

//BOT Angle Variables
float g_fAnglePos[128][3], g_fAngleLook[128][3];
int g_iAngleDefIndex[128];
char g_szAngleReplay[128][128];
float g_fAngleTimestamp[128];
int g_iAngleTeam[128];
int g_iMaxAngles;
int g_iHoldingAngleNum[MAXPLAYERS + 1] = {-1, ...};
bool g_bAngleClaimed[128];
bool g_bAngleBlock[MAXPLAYERS + 1] = {false, ...};

//BOT Peek Variables
float g_fPeekPos[MAX_PEEKS][3];
float g_fPeekLook[MAX_PEEKS][3];
int  g_iPeekDefIndex[MAX_PEEKS];
char g_szPeekReplay[MAX_PEEKS][128];
int  g_iPeekTeam[MAX_PEEKS];
int  g_iMaxPeeks = 0;
bool g_bDoingPeek[MAXPLAYERS + 1];
int  g_iCurrentPeekNum[MAXPLAYERS + 1];
bool g_bPeekRolled[MAXPLAYERS + 1];

static char g_szBoneNames[][] =  {
	"neck_0", 
	"pelvis", 
	"spine_0", 
	"spine_1", 
	"spine_2", 
	"spine_3", 
	"clavicle_l",
	"clavicle_r",
	"arm_upper_L", 
	"arm_lower_L", 
	"hand_L", 
	"arm_upper_R", 
	"arm_lower_R", 
	"hand_R", 
	"leg_upper_L",  
	"leg_lower_L", 
	"ankle_L",
	"leg_upper_R", 
	"leg_lower_R",
	"ankle_R"
};

enum RouteType
{
	DEFAULT_ROUTE = 0, 
	FASTEST_ROUTE, 
	SAFEST_ROUTE, 
	RETREAT_ROUTE
}

enum PriorityType
{
	PRIORITY_LOWEST = -1,
	PRIORITY_LOW, 
	PRIORITY_MEDIUM, 
	PRIORITY_HIGH, 
	PRIORITY_UNINTERRUPTABLE
}

enum LookAtSpotState
{
	NOT_LOOKING_AT_SPOT,			///< not currently looking at a point in space
	LOOK_TOWARDS_SPOT,				///< in the process of aiming at m_lookAtSpot
	LOOK_AT_SPOT,					///< looking at m_lookAtSpot
	NUM_LOOK_AT_SPOT_STATES
}

enum GrenadeTossState
{
	NOT_THROWING,				///< not yet throwing
	START_THROW,				///< lining up throw
	THROW_LINED_UP,				///< pause for a moment when on-line
	FINISH_THROW				///< throwing
}

enum TaskType
{
	SEEK_AND_DESTROY,
	PLANT_BOMB,
	FIND_TICKING_BOMB,
	DEFUSE_BOMB,
	GUARD_TICKING_BOMB,
	GUARD_BOMB_DEFUSER,
	GUARD_LOOSE_BOMB,
	GUARD_BOMB_ZONE,
	GUARD_INITIAL_ENCOUNTER,
	ESCAPE_FROM_BOMB,
	HOLD_POSITION,
	FOLLOW,
	VIP_ESCAPE,
	GUARD_VIP_ESCAPE_ZONE,
	COLLECT_HOSTAGES,
	RESCUE_HOSTAGES,
	GUARD_HOSTAGES,
	GUARD_HOSTAGE_RESCUE_ZONE,
	MOVE_TO_LAST_KNOWN_ENEMY_POSITION,
	MOVE_TO_SNIPER_SPOT,
	SNIPING,
	ESCAPE_FROM_FLAMES,
	NUM_TASKS
}

enum DispositionType
{
	ENGAGE_AND_INVESTIGATE,								///< engage enemies on sight and investigate enemy noises
	OPPORTUNITY_FIRE,									///< engage enemies on sight, but only look towards enemy noises, dont investigate
	SELF_DEFENSE,										///< only engage if fired on, or very close to enemy
	IGNORE_ENEMIES,										///< ignore all enemies - useful for ducking around corners, running away, etc
	NUM_DISPOSITIONS
}

enum GamePhase
{
	GAMEPHASE_WARMUP_ROUND,
	GAMEPHASE_PLAYING_STANDARD,	
	GAMEPHASE_PLAYING_FIRST_HALF,
	GAMEPHASE_PLAYING_SECOND_HALF,
	GAMEPHASE_HALFTIME,
	GAMEPHASE_MATCH_ENDED,    
	GAMEPHASE_MAX
}

public Plugin myinfo = 
{
	name = "BetterBotsPlus * LIGA", 
	author = "Rxpev", 
	description = "Edited BetterBotsPlus Plugin fit for use with LIGA: Pro Journey", 
	version = "1.0.0", 
	url = "http://steamcommunity.com/id/rxpev"
};

public void OnPluginStart()
{	
	g_bIsCompetitive = FindConVar("game_mode").IntValue == 1 && FindConVar("game_type").IntValue == 0 ? true : false;
	g_hCvarIsAWP = FindConVar("isAWP");

	HookEventEx("player_spawn", OnPlayerSpawn);
	HookEventEx("round_prestart", OnRoundPreStart);
	HookEventEx("round_start", OnRoundStart);
	HookEventEx("round_end", OnRoundEnd);
	HookEventEx("round_freeze_end", OnFreezetimeEnd);
	HookEventEx("weapon_zoom", OnWeaponZoom);
	HookEventEx("weapon_fire", OnWeaponFire);
	HookEvent("bomb_beginplant", OnBombBeginPlant);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("bomb_planted", OnBombPlanted, EventHookMode_Post);
	HookEvent("bomb_begindefuse", OnBombBeginDefuse);
	HookEvent("bomb_exploded", OnBombExploded);

	
	LoadSDK();
	LoadDetours();
	
	g_cvBotEcoLimit = FindConVar("bot_eco_limit");
	g_hBotTemplates = new StringMap();
}

public void OnMapStart()
{
	LoadBotTemplates();
	g_iProfileRankOffset = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicLevel");
	g_iPlayerColorOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompTeammateColor");

	GetCurrentMap(g_szMap, sizeof(g_szMap));
	GetMapDisplayName(g_szMap, g_szMap, sizeof(g_szMap));

	ParseMapNades(g_szMap, true);
	ParseMapNades(g_szMap, false);
	ParsePostPlantNades(g_szMap);

	g_bIsBombScenario = IsValidEntity(FindEntityByClassname(-1, "func_bomb_target"));
	g_bIsHostageScenario = IsValidEntity(FindEntityByClassname(-1, "func_hostage_rescue"));

	CreateTimer(1.0, Timer_CheckPlayer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Timer_MoveToBomb, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
	
	for (int i = 1; i <= MaxClients; i++)
		g_iPlayerColor[i] = -1;
	  g_NumBombsites = 0;

    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "func_bomb_target")) != -1)
    {
        g_BombsiteEntities[g_NumBombsites++] = entity;
    }

    for (int i = 0; i <= MAXPLAYERS; i++) 
    {
       g_fLastFakeDefuseTime[i] = 0.0;
    }
}

public Action Timer_CheckPlayer(Handle hTimer, any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsFakeClient(i) || !IsPlayerAlive(i))
			continue;

		if (g_bAWPDropQueued[i] || g_bBuyDelayed[i] || g_bIsAWPDonor[i] || g_bDonationInProgress[i])
    	continue;

		int iAccount = GetEntProp(i, Prop_Send, "m_iAccount");
		bool bInBuyZone = !!GetEntProp(i, Prop_Send, "m_bInBuyZone");
		int iTeam = GetClientTeam(i);
		bool bHasDefuser = !!GetEntProp(i, Prop_Send, "m_bHasDefuser");
		int iPrimary = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
		bool bHasPrimary = IsValidEntity(iPrimary);
		int iWeapon = GetPlayerWeaponSlot(i, CS_SLOT_KNIFE);
		int iActiveWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
		bool bHoldingKnife = (iWeapon != -1 && iWeapon == iActiveWeapon);

		char szDefaultPrimary[64];
		GetClientWeapon(i, szDefaultPrimary, sizeof(szDefaultPrimary));

		bool bDefaultPistol = strcmp(szDefaultPrimary, "weapon_hkp2000") == 0 || strcmp(szDefaultPrimary, "weapon_usp_silencer") == 0 || strcmp(szDefaultPrimary, "weapon_glock") == 0;
		bool bEnoughFriendsHavePrimary = GetFriendsWithPrimary(i) >= 2;

		if (bHoldingKnife && IsItMyChance(25.0))
		{
			FakeClientCommand(i, "+lookatweapon");
			FakeClientCommand(i, "-lookatweapon");
		}
		else if (IsItMyChance(2.0))
		{
			FakeClientCommand(i, "+lookatweapon");
			FakeClientCommand(i, "-lookatweapon");
		}

		if (!bInBuyZone)
			continue;

        if (g_iCurrentRound == 0 || g_iCurrentRound == 12)
        {
            if (IsItMyChance(5.0))
            {
                FakeClientCommand(i, "buy %s",
                    (iTeam == CS_TEAM_CT) ? "elite" : "vest");
            }
            else if (IsItMyChance(19.0))
            {
                FakeClientCommand(i, "buy %s",
                    (iTeam == CS_TEAM_CT) ? "defuser" : "p250");
            }
            else if (IsItMyChance(18.0))
            {
                if (iTeam == CS_TEAM_CT)
                {
                    FakeClientCommand(i, "buy smokegrenade");
                    FakeClientCommand(i, "buy hegrenade");
                }
                else
                {
                    FakeClientCommand(i, "buy smokegrenade");
                    FakeClientCommand(i, "buy flashbang");
                }
            }
            else
            {
                FakeClientCommand(i, "buy vest");
            }
            continue;
        }

        if (bHasPrimary || (bEnoughFriendsHavePrimary && !bDefaultPistol))
        {
        	int iArmor = GetEntProp(i, Prop_Data, "m_ArmorValue");
			bool bHasHelmet = !!GetEntProp(i, Prop_Send, "m_bHasHelmet");
            if (iArmor < 50 || !bHasHelmet)
			{
				if (iTeam == CS_TEAM_CT)
				{
					int cost = 0;

					if (!bHasHelmet)
					{
						if (iArmor == 100)
						{
							cost = 350;
						}
						else
						{
							cost = COST_VESTHELM;
						}
					}
					else if (iArmor < 50)
					{
						cost = COST_VEST;
					}

					if (iAccount - cost > 2000)
					{
						if (!bHasHelmet || iArmor < 50)
						{
							FakeClientCommand(i, "buy vesthelm");
						}
					}
					else if (!bHasHelmet && iArmor < 50)
					{
						FakeClientCommand(i, "buy vest");
					}
				}
				else
				{
					FakeClientCommand(i, "buy vesthelm");
				}
			}

            if (ShouldBuyDefuseKit(i))
			{
			    FakeClientCommand(i, "buy defuser");
			}

			if (GetGameTime() - g_fRoundStart > 6.0 && !g_bFreezetimeEnd)
			{
				switch (Math_GetRandomInt(1, 3))
				{
					case 1:
					{
						FakeClientCommand(i, "buy smokegrenade");
						FakeClientCommand(i, "buy flashbang");
						FakeClientCommand(i, "buy flashbang");
						FakeClientCommand(i, "buy hegrenade");
					}
					case 2:
					{
						FakeClientCommand(i, "buy smokegrenade");
						FakeClientCommand(i, "buy flashbang");
						FakeClientCommand(i, "buy flashbang");
						FakeClientCommand(i, "buy molotov");
					}
					case 3:
					{
						FakeClientCommand(i, "buy smokegrenade");
						FakeClientCommand(i, "buy flashbang");
						FakeClientCommand(i, "buy hegrenade");
						FakeClientCommand(i, "buy molotov");
					}
				}
			}
		}

        if ((iAccount < g_cvBotEcoLimit.IntValue && iAccount > 2200 && !bHasPrimary)
            || bEnoughFriendsHavePrimary && !bHasPrimary)
        {
            if (bDefaultPistol)
            {
                switch (Math_GetRandomInt(1, 6))
                {
                    case 1: FakeClientCommand(i, "buy p250");
                    case 2: FakeClientCommand(i, "buy tec9");
                    case 3: FakeClientCommand(i, "buy deagle");
                }
            }
            else
            {
                switch (Math_GetRandomInt(1, 15))
                {
                    case 1:
                        FakeClientCommand(i, "buy vest");
                    case 2:
                    	FakeClientCommand(i, "buy flashbang");
                    case 3:
                    	FakeClientCommand(i, "buy smokegrenade");
                    case 10:
                        FakeClientCommand(i, "buy %s",
                            (iTeam == CS_TEAM_CT && !bHasDefuser) ? "defuser" : "vest");
                }
            }
        }

	        if (g_iCurrentRound != 0 && g_iCurrentRound != 12
	            && iAccount < 3000
	            && !g_bBotHasForcedBuy[i]
	            && !bHasPrimary)
	        {
	            bool bTForce  = (iTeam == CS_TEAM_T && ShouldForce(CS_TEAM_T));
	            bool bCTForce = (iTeam == CS_TEAM_CT && ShouldForce(CS_TEAM_CT));

	            if (bTForce || bCTForce)
	    	{
	        g_bBotHasForcedBuy[i] = true;
	        PrintToServer("[FORCEBUY] %s Bot %d forcing buy", (iTeam == CS_TEAM_T) ? "T" : "CT", i);

		        if (iTeam == CS_TEAM_T)
		        {
		            if (iAccount >= 2800 && iAccount <= 2950)
		            {
		                FakeClientCommand(i, "buy galilar");
		                FakeClientCommand(i, "buy vesthelm");
		            }
		            else if (iAccount >= 2300 && iAccount <= 2750)
		            {
		                FakeClientCommand(i, "buy mac10");
		                FakeClientCommand(i, "buy vesthelm");
		            }
		            else if (iAccount >= 1700 && iAccount <= 2250 && !bHasPrimary)
		            {
		                if (bDefaultPistol)
		                BuyRandomPistolT(i);
		                FakeClientCommand(i, "buy vesthelm");
		            }
		            else if (iAccount < 1700 && !bHasPrimary)
		            {
		                if (bDefaultPistol)
		                    BuyRandomPistolT(i);
		                if (iAccount >= COST_VESTHELM)
						    FakeClientCommand(i, "buy vesthelm");
						else if (iAccount >= COST_VEST)
						    FakeClientCommand(i, "buy vest");
		            }
		        }
		        else if (iTeam == CS_TEAM_CT)
		        {
		            if (iAccount >= 2700 && iAccount <= 2950)
		            {
		                FakeClientCommand(i, "buy famas");
		                FakeClientCommand(i, "buy vest");
		            }
		            else if (iAccount >= 2150 && iAccount <= 2650)
		            {
		                FakeClientCommand(i, "buy mp9");
		                FakeClientCommand(i, "buy vest");
		            }
		            else if (iAccount >= 1700 && iAccount <= 2100 && !bHasPrimary)
		            {
		                if (bDefaultPistol)
		                    BuyRandomPistolCT(i);
		                FakeClientCommand(i, "buy vest");
		            }
		            else if (iAccount < 1650 && !bHasPrimary)
		            {
		                if (bDefaultPistol)
		                    BuyRandomPistolCT(i);
		                if (iAccount >= COST_VEST)
		                    FakeClientCommand(i, "buy vest");
		            }
		        }
		        if (GetGameTime() - g_fRoundStart > 6.0 && !g_bFreezetimeEnd)
				{
					ForceBuyGrenades(i);
				}
	        }
	    }
	    if (bHasPrimary)
	    {
			TryUpgradeWeapon(i);
		}
    }
	return Plugin_Continue;
}

public Action Timer_MoveToBomb(Handle hTimer, any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsFakeClient(i) || !IsPlayerAlive(i))
			continue;

		if (!g_bBombPlanted || GetClientTeam(i) != CS_TEAM_CT)
			continue;

		int iPlantedC4 = FindEntityByClassname(-1, "planted_c4");
		if (!IsValidEntity(iPlantedC4))
			continue;

		float fBombOrigin[3];
		GetEntPropVector(iPlantedC4, Prop_Send, "m_vecOrigin", fBombOrigin);

		float fDistance = GetVectorDistance(g_fBotOrigin[i], fBombOrigin);
		int iEnemiesNearby = GetEntData(i, g_iBotNearbyEnemiesOffset);
		bool bIsLastCT = (GetAliveTeamCount(CS_TEAM_T) == 0 && GetAliveTeamCount(CS_TEAM_CT) == 1);
		bool bShouldMove = (bIsLastCT && fDistance > 30.0 && GetTask(i) != ESCAPE_FROM_BOMB) ||fDistance > 2000.0;

		if (bShouldMove && iEnemiesNearby == 0 && !g_bDontSwitch[i])
		{
			SDKCall(g_hSwitchWeaponCall, i, GetPlayerWeaponSlot(i, CS_SLOT_KNIFE), 0);
			BotMoveTo(i, fBombOrigin, FASTEST_ROUTE);
		}
	}

	return Plugin_Continue;
}

public Action Timer_DropWeapons(Handle hTimer, any data)
{
    if (GetGameTime() - g_fRoundStart <= 4.5)
        return Plugin_Continue;

    static int iDonorClients[MAXPLAYERS + 1];
    int iDonorCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsFakeClient(i) || !IsPlayerAlive(i) || g_bDropWeapon[i])
            continue;

        if (g_bAWPDropQueued[i] || g_bBuyDelayed[i] || g_bIsAWPDonor[i] || g_bDonationInProgress[i])
            continue;

        int iPrimary = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
        if (!IsValidEntity(iPrimary))
            continue;

        int iDefIndex = GetEntProp(iPrimary, Prop_Send, "m_iItemDefinitionIndex");
        CSWeaponID weaponID = CS_ItemDefIndexToID(iDefIndex);
        int iMoney = GetEntProp(i, Prop_Send, "m_iAccount");

        if (weaponID == CSWeapon_NONE || iMoney < CS_GetWeaponPrice(i, weaponID))
            continue;

        GetEntityClassname(iPrimary, g_szPreviousBuy[i], 128);
        ReplaceString(g_szPreviousBuy[i], 128, "weapon_", "");

        iDonorClients[iDonorCount++] = i;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bDonationInProgress[i])
            continue;

        if (g_bHasGottenDrop[i] || !IsValidClient(i) || !IsPlayerAlive(i))
            continue;

        if (g_bFreezetimeEnd)
            continue;

        if (IsBotAWPer(i) && g_bBuyDelayed[i])
            continue;

        bool bInBuyZone = !!GetEntProp(i, Prop_Send, "m_bInBuyZone");
        if (!bInBuyZone)
            continue;

        int iPrimary = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
        if (IsValidEntity(iPrimary))
            continue;

        int iAccount = GetEntProp(i, Prop_Send, "m_iAccount");
        if (iAccount >= g_cvBotEcoLimit.IntValue)
            continue;

        int iTeam = GetClientTeam(i);

        for (int d = 0; d < iDonorCount; d++)
        {
            int iDonor = iDonorClients[d];
            if (GetClientTeam(iDonor) != iTeam)
                continue;

            if (g_bDonationInProgress[iDonor] || g_bAWPDropQueued[iDonor])
                continue;

            float fEyes[3];
            GetClientEyePosition(i, fEyes);

            BotSetLookAt(iDonor, "Use entity", fEyes, PRIORITY_HIGH, 3.0, false, 5.0, false);
            g_bDropWeapon[iDonor] = true;
            g_bHasGottenDrop[i] = true;
            break;
        }
    }

    return g_bFreezetimeEnd ? Plugin_Stop : Plugin_Continue;
}

public void OnMapEnd()
{
	SDKUnhook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
}

public void OnClientPostAdminCheck(int client)
{
    g_iProfileRank[client] = Math_GetRandomInt(1, 40);

    if (IsValidClient(client) && IsFakeClient(client))
    {
        char szBotName[MAX_NAME_LENGTH];
        GetClientName(client, szBotName, sizeof(szBotName));
        g_bIsProBot[client] = false;

        char sTemplate[MAX_TEMPLATE_NAME];
        if (g_hBotTemplates.GetString(szBotName, sTemplate, sizeof(sTemplate)))
        {
            if (StrEqual(sTemplate, "Star", false) ||
                StrEqual(sTemplate, "Fragger", false) ||
                StrEqual(sTemplate, "Solid", false) ||
                StrEqual(sTemplate, "Medium", false) ||
                StrEqual(sTemplate, "Avg", false) ||
                StrEqual(sTemplate, "Low", false) ||
                StrEqual(sTemplate, "Bad", false))
            {
                g_bIsProBot[client] = true;
            }
            else
            {
                g_bIsProBot[client] = false;
                g_bIsIntermediateBot[client] = true;
            }
        }
        else
        {
            g_bIsProBot[client] = false;
        }

        g_bUseUSP[client] = IsItMyChance(99.0) ? true : false;
        g_bUseM4A1S[client] = IsItMyChance(85.0) ? true : false;
        g_bUseCZ75[client] = IsItMyChance(5.0) ? true : false;
        g_pCurrArea[client] = INVALID_NAV_AREA;
    }
}

public void OnRoundPreStart(Event eEvent, char[] szName, bool bDontBroadcast)
{
	 g_iCurrentRound = GameRules_GetProp("m_totalRoundsPlayed");
}

public void OnRoundStart(Event eEvent, char[] szName, bool bDontBroadcast)
{
	g_iMaxNades = 0;
	g_iPostPlantNadesStartIndex = 0;
	BuildActiveNadesForRound();
	ParseMapAngles(g_szMap);
    ParseMapPeeks(g_szMap);

    CheckAWPDonation(CS_TEAM_T);
    CheckAWPDonation(CS_TEAM_CT);

	int iTeam = g_bIsBombScenario ? CS_TEAM_CT : CS_TEAM_T;
	int iOppositeTeam = g_bIsBombScenario ? CS_TEAM_T : CS_TEAM_CT;
    
    for (int i = 0; i < MAX_NADES; i++)
    {
        g_fNadeClaimTime[i] = 0.0;
    }

	for (int i = 0; i < g_iMaxAngles; i++)
	{
	    g_bAngleClaimed[i] = false;
	}
	
	g_bFreezetimeEnd = false;
	g_bEveryoneDead = false;
	g_fRoundStart = GetGameTime();
	g_bBombPlanted = false;
	g_bBombExploded = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsFakeClient(i) && IsPlayerAlive(i))
		{	
			g_bUncrouch[i] = IsItMyChance(50.0) ? true : false;
			g_bDontSwitch[i] = false;
			g_bDropWeapon[i] = false;
			g_bHasGottenDrop[i] = false;
			g_bThrowGrenade[i] = false;
			g_bBotHasForcedBuy[i] = false;
			g_bIsFakeDefusing[i] = false;
			g_bDidRun[i] = false;
			g_bBotCompromised[i] = false;
			g_bAngleBlock[i] = false;
			g_bDidInitialSwitch[i] = false;
			g_bPeekRolled[i] = false;
            g_bDoingPeek[i] = false;
            g_iCurrentPeekNum[i] = -1;
			g_iTarget[i] = -1;
			g_iPrevTarget[i] = -1;
			g_iDoingSmokeNum[i] = -1;
			g_fShootTimestamp[i] = 0.0;				
			g_fThrowNadeTimestamp[i] = 0.0;				
			g_fCrouchTimestamp[i] = 0.0;								
			g_iHoldingAngleNum[i] = -1;
			if(g_bIsBombScenario || g_bIsHostageScenario)
			{
				if(GetClientTeam(i) == iTeam)
					SetEntData(i, g_iBotMoraleOffset, -3);
				if(g_bHalftimeSwitch && GetClientTeam(i) == iOppositeTeam)
					SetEntData(i, g_iBotMoraleOffset, 1);
			}
		}
	}
	
	g_bHalftimeSwitch = false;
	if(g_bIsCompetitive)
		CreateTimer(0.2, Timer_DropWeapons, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	for (int i = 1; i <= MaxClients; i++)
    {
		g_bDidFakePlant[i] = false;
		g_bFakePlantRolled[i] = false;
    }
}

public void OnRoundEnd(Event eEvent, char[] szName, bool bDontBroadcast)
{
    EnableBombSites();
	if (g_iCurrentRound == 0 || g_iCurrentRound == 12)
	{
	    g_iRoundsLostCT = 1;
	    g_iRoundsLostT = 1;
	}
	int iWinner = eEvent.GetInt("winner"); // Get the winner of the round

    g_bRoundWonCT = false;
    g_bRoundWonT = false;

    if (iWinner == CS_TEAM_CT) {
        g_bRoundWonCT = true; // CT won the round
    } else if (iWinner == CS_TEAM_T) {
        g_bRoundWonT = true; // T won the round
    }
	int iTeamNum, iEnt = -1;
	while((iEnt = FindEntityByClassname(iEnt, "cs_team_manager")) != -1 )
	{
		iTeamNum = GetEntProp(iEnt, Prop_Send, "m_iTeamNum");        
		if(iTeamNum == CS_TEAM_CT)
			g_iCTScore = GetEntProp(iEnt, Prop_Send, "m_scoreTotal");
		else if(iTeamNum == CS_TEAM_T)
			g_iTScore = GetEntProp(iEnt, Prop_Send, "m_scoreTotal");
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bIsAWPDonor[i] = false;
	    g_bBuyDelayed[i] = false;
	    g_bAWPDropQueued[i] = false;
	    g_bDropWeapon[i] = false;
		if (IsValidClient(i) && IsFakeClient(i) && BotMimic_IsPlayerMimicing(i))
			BotMimic_StopPlayerMimic(i);
	}
	
	g_iRoundsPlayed = g_iCTScore + g_iTScore;
	
	for(int i = 0; i < g_iMaxNades; i++)
	{			
		g_fNadeTimestamp[i] = 0.0;
	}

	if (g_bRoundWonCT) 
	{
	    UpdateRoundsLost(true, g_iRoundsLostCT); // CT won, update their rounds lost
	    UpdateRoundsLost(false, g_iRoundsLostT); // T lost, update their rounds lost
	} 
	else if (g_bRoundWonT) 
	{
	    UpdateRoundsLost(true, g_iRoundsLostT); // T won, update their rounds lost
	    UpdateRoundsLost(false, g_iRoundsLostCT); // CT lost, update their rounds lost
	}

    // Get current loss bonuses for both teams
    g_iCurrentBonusCT = GetLossBonus(g_iRoundsLostCT); // Get CT's current loss bonus
    g_iCurrentBonusT = GetLossBonus(g_iRoundsLostT); // Get T's current loss bonus
    ResetLossBonusOnOvertimeHalftime();
    PrintToServer("[LOSSBONUS] CT Rounds Lost: %d, T Rounds Lost: %d", g_iRoundsLostCT, g_iRoundsLostT);
	PrintToServer("[LOSSBONUS] CT Bonus: %d, T Bonus: %d", g_iCurrentBonusCT, g_iCurrentBonusT);
}

public void OnFreezetimeEnd(Event eEvent, char[] szName, bool bDontBroadcast)
{
    g_bFreezetimeEnd = true;
    g_fFreezeTimeEnd = GetGameTime();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsFakeClient(i) == false)
            continue;

        g_bDonationInProgress[i] = false;

        if (g_bShouldPickupDroppedGun[i])
            CreateTimer(3.0, Timer_ClearPickupFlag, i, TIMER_FLAG_NO_MAPCHANGE);

        if (g_bIsAWPer[i])
        {
            int iAWP = FindNearestDroppedSpecificGun(i, "weapon_awp");
            if (IsValidEntity(iAWP))
            {
                float fGunPos[3];
                GetEntPropVector(iAWP, Prop_Send, "m_vecOrigin", fGunPos);
                BotLookAt(i, fGunPos);
                PrintToServer("[AWP DEBUG] AWPer %N looking at dropped AWP (ent %d)", i, iAWP);
            }
        }
        else if (g_bShouldPickupDroppedGun[i])
        {
            int iGun = FindNearestDroppedSpecificGun(i, "weapon_ak47");
            if (!IsValidEntity(iGun))
                iGun = FindNearestDroppedSpecificGun(i, "weapon_m4a1");

            if (!IsValidEntity(iGun))
                iGun = FindNearestDroppedSpecificGun(i, "weapon_m4a1_silencer");

            if (IsValidEntity(iGun))
            {
                float fGunPos[3];
                GetEntPropVector(iGun, Prop_Send, "m_vecOrigin", fGunPos);
                BotLookAt(i, fGunPos);
                PrintToServer("[AWP DEBUG] Donor %N looking at dropped rifle (ent %d)", i, iGun);
            }
        }
    }
}

public Action OnBombBeginPlant(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client) || !IsPlayerAlive(client) || !IsFakeClient(client) || GetClientTeam(client) != CS_TEAM_T)
    {
        return Plugin_Continue;
    }

    if (g_bDidFakePlant[client])
    {
        PrintToServer("[FAKEPLANT] client %d already faked a plant", client);
        return Plugin_Continue;
    }

    bool shouldFake = false;

    if (IsLastTAlive(client))
    {
        shouldFake = true;
    }
    else if (IsFarFromTeammates(client, 1000.0))
    {
        shouldFake = true;
    }

    if (!shouldFake)
    {
        return Plugin_Continue;
    }

    if (!ShouldFakePlantOnce(client, 75.0))
    {
        PrintToServer("[FAKEPLANT] client %d failed 75%% RNG", client);
        return Plugin_Continue;
    }

    if (g_fRoundTimeRemaining <= 12.0)
    {
        PrintToServer("[FAKEPLANT] Not enough time left in round: %.2f seconds", g_fRoundTimeRemaining);
        return Plugin_Continue;
    }

    PrintToServer("[FAKEPLANT] client %d is performing FAKEPLANT", client);
    CreateTimer(GetRandomFloat(0.1, 0.25), Timer_CancelFakePlant, client);
    g_bDidFakePlant[client] = true;

    return Plugin_Continue;
}

public void Timer_CancelFakePlant(Handle timer, any client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
    {
        return;
    }

    // Check if the bot is in a primary weapon slot or not
    int primary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
    if (primary != -1 && IsValidEntity(primary))
    {
        SwitchToPrimaryWeapon(client);
    }
    else
    {
        SwitchToSecondaryWeapon(client);
    }

    DisableBombSites();

    CreateTimer(5.0, Timer_ResetBombSites, client);
}

public void OnBombPlanted(Event event, const char[] name, bool dontBroadcast)
{
    g_bBombPlanted = true;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
        {
            if (g_iHoldingAngleNum[i] != -1)
            {
                if (BotMimic_IsPlayerMimicing(i))
                {
                    BotMimic_StopPlayerMimic(i);
                }
                
                g_iHoldingAngleNum[i] = -1;
                
                BotCancelMoveTo(i);
            }
        }
    }
}

public void OnBombExploded(Event event, char[] name, bool dontBroadcast)
{
    g_bBombExploded = true;
}

void BotCancelMoveTo(int client)
{
        float currentPos[3];
        GetClientAbsOrigin(client, currentPos);
        BotMoveTo(client, currentPos, FASTEST_ROUTE);
}

public Action OnBombBeginDefuse(Event event, const char[] name, bool dontBroadcast) 
{
    DataPack pack = new DataPack();
    pack.WriteCell(event.GetInt("userid"));
    pack.WriteString(name);
    pack.WriteCell(dontBroadcast);
    CreateTimer(0.2, Timer_DelayedBombBeginDefuse, pack);
    return Plugin_Continue;
}

public Action Timer_DelayedBombBeginDefuse(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    char eventName[32];
    pack.ReadString(eventName, sizeof(eventName));
    bool dontBroadcast = pack.ReadCell();
    delete pack;

    int client = GetClientOfUserId(userid);
    char clientName[32];
    GetClientName(client, clientName, sizeof(clientName));

    if (!IsValidClient(client) || !IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != CS_TEAM_CT) 
    {
        return Plugin_Continue;
    }

    if (AreAllEnemiesDead(client)) 
    {
        PrintToServer("[FAKEDEFUSE] All enemies are dead. Sticking to defuse without fake defuse.");
        return Plugin_Continue;
    }

    int iPlantedC4 = FindEntityByClassname(-1, "planted_c4");
    if (iPlantedC4 != -1) 
    {
        bool bHasDefuser = !!GetEntProp(client, Prop_Send, "m_bHasDefuser");

        if ((bHasDefuser && g_fTimeLeft >= 10.0) || (!bHasDefuser && g_fTimeLeft >= 14.0)) 
        {
            if (IsLastCTAlive(client))
            {
                if (IsItMyChance(90.0)) 
                {
                    CreateTimer(GetRandomFloat(0.1, 0.25), Timer_CancelFakeDefuse, userid);
                }
                else 
                {
                    PrintToServer("[FAKEDEFUSE] client %d failed 90%% RNG", client);
                }
                return Plugin_Continue;
            }

            // Check if the bot is far enough from its teammates (450 units or more)
            if (CheckDistanceToTeammates(client)) 
            {
                if (IsItMyChance(75.0)) 
                {
                    CreateTimer(GetRandomFloat(0.1, 0.25), Timer_CancelFakeDefuse, userid);
                }
                else 
                {
                    PrintToServer("[FAKEDEFUSE] client %d FAILED 75%% RNG", client);
                }
            } 
            else 
            {
                PrintToServer("[FAKEDEFUSE] client %d is too close to teammates, sticking to actual defuse", client);
            }
        } 
        else 
        {
            PrintToServer("[FAKEDEFUSE] client %d does not have enough time to fake defuse (Time left: %.2f)", client, g_fTimeLeft);
        }
    }

    return Plugin_Continue;
}

public Action Timer_CancelFakeDefuse(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || !IsPlayerAlive(client) || !IsFakeClient(client) || GetClientTeam(client) != CS_TEAM_CT)
    {
        return Plugin_Handled;
    }

    // Initialize fake defuse state
    g_fLastFakeDefuseTime[client] = GetGameTime();
    g_bIsFakeDefusing[client] = true;

    PrintToServer("[FAKEDEFUSE] Started fake defuse for client %d", client);

    // Get bot's yaw angle
    float angles[3];
    GetClientEyeAngles(client, angles);
    float yaw = angles[1];

    // Normalize yaw to [-180, 180]
    while (yaw > 180.0) yaw -= 360.0;
    while (yaw < -180.0) yaw += 360.0;

    char recordingPaths[4][3][PLATFORM_MAX_PATH] = {
        {
            "addons/sourcemod/data/botmimic/fake/fakedefuse_north.rec",
            "addons/sourcemod/data/botmimic/fake/fakedefuse_northB.rec",
            "addons/sourcemod/data/botmimic/fake/fakedefuse_northF.rec"
        },
        {
            "addons/sourcemod/data/botmimic/fake/fakedefuse_east.rec",
            "addons/sourcemod/data/botmimic/fake/fakedefuse_eastB.rec",
            "addons/sourcemod/data/botmimic/fake/fakedefuse_eastF.rec"
        },
        {
            "addons/sourcemod/data/botmimic/fake/fakedefuse_south.rec",
            "addons/sourcemod/data/botmimic/fake/fakedefuse_southB.rec",
            "addons/sourcemod/data/botmimic/fake/fakedefuse_southF.rec"
        },
        {
            "addons/sourcemod/data/botmimic/fake/fakedefuse_west.rec",
            "addons/sourcemod/data/botmimic/fake/fakedefuse_westB.rec",
            "addons/sourcemod/data/botmimic/fake/fakedefuse_westF.rec"
        }
    };

    // Select direction based on yaw
    int direction;
    char directionName[16];
    if (yaw >= -45.0 && yaw < 45.0)
    {
        direction = 0; // North
        strcopy(directionName, sizeof(directionName), "north");
    }
    else if (yaw >= 45.0 && yaw < 135.0)
    {
        direction = 1; // East
        strcopy(directionName, sizeof(directionName), "east");
    }
    else if (yaw >= 135.0 || yaw < -135.0)
    {
        direction = 2; // South
        strcopy(directionName, sizeof(directionName), "south");
    }
    else
    {
        direction = 3; // West
        strcopy(directionName, sizeof(directionName), "west");
    }

    // Randomly pick one of the three recordings for the direction
    int variation = GetRandomInt(0, 2);
    char recordingPath[PLATFORM_MAX_PATH];
    strcopy(recordingPath, sizeof(recordingPath), recordingPaths[direction][variation]);

    BMError error = BotMimic_PlayRecordFromFileRelative(client, recordingPath);
    if (error != BM_NoError)
    {
        PrintToServer("[FAKEDEFUSE] Failed to play recording %s for bot %d: error %d", recordingPath, client, error);
    }
    else
    {
        PrintToServer("[FAKEDEFUSE] Playing %s for bot %d (direction: %s, yaw: %.2f)", recordingPath, client, directionName, yaw);
    }

    CreateTimer(6.5, Timer_ResetFakeDefuse, userid);

    return Plugin_Handled;
}

public Action Timer_ResetFakeDefuse(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return Plugin_Stop;
    }

    g_bIsFakeDefusing[client] = false;
    PrintToServer("[FAKEDEFUSE] Fake defuse ended for bot %d", client);
    return Plugin_Stop;
}

public void OnWeaponZoom(Event eEvent, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(eEvent.GetInt("userid"));
	
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
		g_fShootTimestamp[client] = GetGameTime();
}

public void OnWeaponFire(Event eEvent, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(eEvent.GetInt("userid"));
	if(IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{
		char szWeaponName[64];
		eEvent.GetString("weapon", szWeaponName, sizeof(szWeaponName));
		
		if(IsValidClient(g_iTarget[client]))
		{
			float fTargetLoc[3];
			
			GetClientAbsOrigin(g_iTarget[client], fTargetLoc);
			
			float fRangeToEnemy = GetVectorDistance(g_fBotOrigin[client], fTargetLoc);
			
			if (strcmp(szWeaponName, "weapon_deagle") == 0 && fRangeToEnemy > 100.0)
				SetEntDataFloat(client, g_iFireWeaponOffset, GetEntDataFloat(client, g_iFireWeaponOffset) + Math_GetRandomFloat(0.20, 0.40));
		}
		
		if ((strcmp(szWeaponName, "weapon_awp") == 0 || strcmp(szWeaponName, "weapon_ssg08") == 0) && IsItMyChance(75.0))
			RequestFrame(BeginQuickSwitch, GetClientUserId(client));

		if (g_bBombPlanted && GetClientTeam(client) == CS_TEAM_CT && IsBotNearPlantedBomb(client))
        {
            g_bBotCompromised[client] = true;
            SpreadCompromisedStateFrom(client);
        }
	}
}

public void OnThinkPost(int iEnt)
{
	SetEntDataArray(iEnt, g_iProfileRankOffset, g_iProfileRank, MAXPLAYERS + 1);
	SetEntDataArray(iEnt, g_iPlayerColorOffset, g_iPlayerColor, MAXPLAYERS + 1);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsFakeClient(i))
			SetCrosshairCode(GetEntityAddress(iEnt), i, g_szCrosshairCode[i]);
	}
}

public Action CS_OnBuyCommand(int client, const char[] szWeapon)
{
    if (!(IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client)))
        return Plugin_Continue;

    if (g_bBuyDelayed[client] || g_bDonationInProgress[client])
        return Plugin_Handled;

    static const char szEquipment[][] = 
    {
        "molotov","incgrenade","decoy","flashbang","hegrenade",
        "smokegrenade","vest","vesthelm","defuser"
    };
    static const char szPrimaryWeapons[][] =
    {
        "galilar","famas","ak47","m4a1","ssg08","aug","sg556","awp",
        "scar20","g3sg1","nova","xm1014","mag7","m249","negev",
        "mac10","mp9","mp7","ump45","p90","bizon"
    };
    static const char szSecondaryWeapons[][] = 
    {
        "glock","usp_silencer","hkp2000","p250","fiveseven",
        "tec9","deagle","elite","cz75a","revolver"
    };

    if (IsInArray(szWeapon, szEquipment, sizeof szEquipment))
        return Plugin_Continue;

    if (PlayerHasPrimary(client) && IsInArray(szWeapon, szPrimaryWeapons, sizeof szPrimaryWeapons))
        return Plugin_Handled;

    if (PlayerHasPrimary(client) && IsInArray(szWeapon, szSecondaryWeapons, sizeof szSecondaryWeapons))
        return Plugin_Handled;

    int iAccount = GetEntProp(client, Prop_Send, "m_iAccount");
    return TryReplaceBoughtWeapon(client, szWeapon, iAccount);
}

public Action Timer_DelayedDonorBuy(Handle timer, any clientArg)
{
    int donor = clientArg;

    if (donor <= 0 || donor > MaxClients)
        return Plugin_Stop;
    if (!IsClientInGame(donor) || !IsFakeClient(donor) || !IsPlayerAlive(donor))
    {
        g_bBuyDelayed[donor] = false;
        return Plugin_Stop;
    }
    if (!g_bIsAWPDonor[donor])
    {
        g_bBuyDelayed[donor] = false;
        return Plugin_Stop;
    }

    g_bBuyDelayed[donor] = false;

    int team = GetClientTeam(donor);
    int awper = FindTeamAWPer(team);
    bool awperIsHuman = !IsFakeClient(awper);
    if (awper == -1 || !IsClientInGame(awper))
    {
        if (awper > 0 && awper <= MaxClients)
        	g_bBuyDelayed[awper] = false;
        return Plugin_Stop;
    }
    
    g_bDonationInProgress[donor] = true;
	if (!awperIsHuman)
    g_bDonationInProgress[awper] = true;
    g_bBuyDelayed[awper] = false;

    if (donor == awper)
        return Plugin_Stop;

    if (g_bHasPickedUpAWP[donor] && g_iSavedAWPFor[donor] == awper)
	{
	    int donorPrimary = GetPlayerWeaponSlot(donor, CS_SLOT_PRIMARY);
	    bool donorHasAwp = false;

	    if (IsValidEntity(donorPrimary))
	    {
	        int defIndex = GetEntProp(donorPrimary, Prop_Send, "m_iItemDefinitionIndex");
	        donorHasAwp = (defIndex == 9);
	    }

	    if (!donorHasAwp)
		{
		    g_bHasPickedUpAWP[donor] = false;

		    if (!awperIsHuman)
		        g_bHasSavedAWP[awper] = false;

		    g_iSavedAWPFor[donor] = 0;
		}
	    else
	    {

	        PrintToServer("[AWP_SAVER] Rifler %N has saved AWP for AWPer %N", donor, awper);

	        if (awperIsHuman)
	        {
	            g_bAWPDropQueued[donor] = true;
	            DataPack pack = new DataPack();
	            pack.WriteCell(donor);
	            pack.WriteCell(awper);
	            CreateTimer(0.2, Timer_AWPGiveDrop, pack);

	            CreateTimer(0.8, Timer_BuySelfGun, donor);
	            CreateTimer(1.2, Timer_BuyUtility, donor);

	            g_bHasPickedUpAWP[donor] = false;
	            g_bHasSavedAWP[awper] = false;
	            g_iSavedAWPFor[donor] = 0;
	            g_bIsAWPDonor[donor] = false;

	            return Plugin_Stop;
	        }

	        int awperPrimary = GetPlayerWeaponSlot(awper, CS_SLOT_PRIMARY);
	        bool awperHasRifle = false;

	        if (IsValidEntity(awperPrimary))
	        {
	            char awperClass[64];
	            GetEdictClassname(awperPrimary, awperClass, sizeof(awperClass));
	            if (StrEqual(awperClass, "weapon_m4a1") ||
	                StrEqual(awperClass, "weapon_m4a1_silencer") ||
	                StrEqual(awperClass, "weapon_ak47"))
	            {
	                awperHasRifle = true;
	            }
	        }

	        if (awperHasRifle)
	        {
	            PrintToServer("[AWP_SAVER] AWPer %N has rifle, swapping with rifler %N's saved AWP", awper, donor);

	            g_bAWPDropQueued[awper] = true;
	            DataPack pack1 = new DataPack();
	            pack1.WriteCell(awper);
	            pack1.WriteCell(donor);
	            CreateTimer(0.2, Timer_AWPGiveDrop, pack1);

	            g_bAWPDropQueued[donor] = true;
	            DataPack pack2 = new DataPack();
	            pack2.WriteCell(donor);
	            pack2.WriteCell(awper);
	            CreateTimer(0.2, Timer_AWPGiveDrop, pack2);

	            CreateTimer(0.8, Timer_BuyUtility, awper);
	            CreateTimer(0.8, Timer_BuyUtility, donor);
	        }
	        else
	        {
	            PrintToServer("[AWP_SAVER] AWPer %N has no rifle, rifler %N dropping saved AWP", awper, donor);

	            g_bAWPDropQueued[donor] = true;
	            DataPack pack = new DataPack();
	            pack.WriteCell(donor);
	            pack.WriteCell(awper);
	            CreateTimer(0.2, Timer_AWPGiveDrop, pack);

	            CreateTimer(0.8, Timer_BuySelfGun, donor);
	            CreateTimer(1.2, Timer_BuyUtility, donor);

	            CreateTimer(0.8, Timer_BuyUtility, awper);
	        }

	        g_bHasPickedUpAWP[donor] = false;
	        g_bHasSavedAWP[awper] = false;
	        g_iSavedAWPFor[donor] = 0;
	        g_bIsAWPDonor[donor] = false;

	        return Plugin_Stop;
	    }
	}

    if (!awperIsHuman && g_bHasSavedAWP[awper])
	{
	    PrintToServer("[AWP DEBUG] AWPer %N already has saved AWP from rifler, skipping donation", awper);
	    return Plugin_Stop;
	}

    int donorPrimary = GetPlayerWeaponSlot(donor, CS_SLOT_PRIMARY);
    bool donorHasPrimary = IsValidEntity(donorPrimary);

    if (donorHasPrimary)
    {
        char weaponClass[64];
        GetEdictClassname(donorPrimary, weaponClass, sizeof(weaponClass));

        if (StrEqual(weaponClass, "weapon_awp"))
        {
            PrintToServer("[AWP DEBUG] Donor %N already has an AWP, dropping it to AWPer %N.", donor, awper);

            g_bAWPDropQueued[donor] = true;
            DataPack pack = new DataPack();
            pack.WriteCell(donor);  // Dropper
            pack.WriteCell(awper);  // Target
            CreateTimer(0.2, Timer_AWPGiveDrop, pack);

            CreateTimer(0.8, Timer_BuySelfGun, donor);
            CreateTimer(1.2, Timer_BuyUtility, donor);
            CreateTimer(1.2, Timer_BuyUtility, awper);

            g_bIsAWPDonor[donor] = false;
            g_bBuyDelayed[donor] = false;

            return Plugin_Stop;
        }
    }

    int donorMoney = GetEntProp(donor, Prop_Send, "m_iAccount");
    int awperMoney = GetEntProp(awper, Prop_Send, "m_iAccount");
    bool awperHasPrimary = IsValidEntity(GetPlayerWeaponSlot(awper, CS_SLOT_PRIMARY));

    int awpPrice = CS_GetWeaponPrice(donor, CSWeapon_AWP);
    int m4Price = CS_GetWeaponPrice(donor, CSWeapon_M4A1);
    int akPrice = CS_GetWeaponPrice(donor, CSWeapon_AK47);

    bool isCT = (team == CS_TEAM_CT);

    PrintToServer("[AWP DEBUG] Donor=%N (money=%d, hasPrimary=%b) | AWPer=%N (money=%d, hasPrimary=%b)",
        donor, donorMoney, donorHasPrimary, awper, awperMoney, awperHasPrimary);

    if (isCT)
    {
        // One-player donation: donor buys AWP and drops it, buys gun for himself
        if (!donorHasPrimary && donorMoney >= 8500)
        {
            AddMoney(donor, -awpPrice, true, true, "weapon_awp");
            CSGO_ReplaceWeapon(donor, CS_SLOT_PRIMARY, "weapon_awp");
            PrintToServer("[AWP DEBUG] CT donor %N bought and will drop AWP", donor);

            g_bAWPDropQueued[donor] = true;
            DataPack pack = new DataPack();
            pack.WriteCell(donor);  // Dropper
            pack.WriteCell(awper);  // Target
            CreateTimer(0.3, Timer_AWPGiveDrop, pack);
            CreateTimer(0.8, Timer_BuySelfGun, donor);
            CreateTimer(1.2, Timer_BuyUtility, donor);
            CreateTimer(1.2, Timer_BuyUtility, awper);
        }
        // Donor has primary, just buy and drop AWP
        else if (donorHasPrimary && donorMoney >= 4750)
        {
            int donorPrimary = GetPlayerWeaponSlot(donor, CS_SLOT_PRIMARY);
            if (IsValidEntity(donorPrimary))
            {
                CS_DropWeapon(donor, donorPrimary, true);
                PrintToServer("[AWP DEBUG] Donor %N dropped current primary before buying AWP", donor);
            }

            AddMoney(donor, -awpPrice, true, true, "weapon_awp");
            CSGO_ReplaceWeapon(donor, CS_SLOT_PRIMARY, "weapon_awp");

            g_bAWPDropQueued[donor] = true;
            DataPack pack = new DataPack();
            pack.WriteCell(donor);  // Dropper
            pack.WriteCell(awper);  // Target
            CreateTimer(0.3, Timer_AWPGiveDrop, pack);
            CreateTimer(1.2, Timer_BuyUtility, donor);
            CreateTimer(1.2, Timer_BuyUtility, awper);
        }
        // Two-player exchange (AWPer ↔ donor)
        else if (!donorHasPrimary && donorMoney >= 5400 && awperMoney >= 3750)
        {
        	if (awperIsHuman)
		    {
		    	g_bIsAWPDonor[donor] = false;
    			g_bDonationInProgress[donor] = false;
		        return Plugin_Stop;
		    }
            // AWPer buys M4A1 → donor
            AddMoney(awper, -m4Price, true, true, "weapon_m4a1");
            CSGO_ReplaceWeapon(awper, CS_SLOT_PRIMARY, "weapon_m4a1");
            g_bAWPDropQueued[awper] = true;
            DataPack pack1 = new DataPack();
            pack1.WriteCell(awper);  // Dropper
            pack1.WriteCell(donor);  // Target
            CreateTimer(0.3, Timer_AWPGiveDrop, pack1);
            CreateTimer(0.6, Timer_BuyUtility, awper);

            // Donor buys AWP → AWPer
            AddMoney(donor, -awpPrice, true, true, "weapon_awp");
            CSGO_ReplaceWeapon(donor, CS_SLOT_PRIMARY, "weapon_awp");
            g_bAWPDropQueued[donor] = true;
            DataPack pack2 = new DataPack();
            pack2.WriteCell(donor);  // Dropper
            pack2.WriteCell(awper);  // Target
            CreateTimer(0.3, Timer_AWPGiveDrop, pack2);
            CreateTimer(0.6, Timer_BuyUtility, donor);
        }
    }
    else
    {
        // One-player donation: donor buys AWP and drops it
        if (!donorHasPrimary && donorMoney >= 8450)
        {
            AddMoney(donor, -awpPrice, true, true, "weapon_awp");
            CSGO_ReplaceWeapon(donor, CS_SLOT_PRIMARY, "weapon_awp");

            // Drop to AWPer after short delay
            g_bAWPDropQueued[donor] = true;
            DataPack pack = new DataPack();
            pack.WriteCell(donor);  // Dropper
            pack.WriteCell(awper);  // Target
            CreateTimer(0.3, Timer_AWPGiveDrop, pack);
            CreateTimer(0.8, Timer_BuySelfGun, donor);
            CreateTimer(1.2, Timer_BuyUtility, donor);
            CreateTimer(1.2, Timer_BuyUtility, awper);
        }
        // Donor has primary, just buy and drop AWP
        else if (donorHasPrimary && donorMoney >= 4750)
        {
            // Drop current primary at donor's feet
            int donorPrimary = GetPlayerWeaponSlot(donor, CS_SLOT_PRIMARY);
            if (IsValidEntity(donorPrimary))
            {
                CS_DropWeapon(donor, donorPrimary, true);
                PrintToServer("[AWP DEBUG] Donor %N dropped current primary before buying AWP", donor);
            }

            AddMoney(donor, -awpPrice, true, true, "weapon_awp");
            CSGO_ReplaceWeapon(donor, CS_SLOT_PRIMARY, "weapon_awp");

            g_bAWPDropQueued[donor] = true;
            DataPack pack = new DataPack();
            pack.WriteCell(donor);  // Dropper
            pack.WriteCell(awper);  // Target
            CreateTimer(0.3, Timer_AWPGiveDrop, pack);
            CreateTimer(1.2, Timer_BuyUtility, donor);
            CreateTimer(1.2, Timer_BuyUtility, awper);
        }
        // Two-player exchange (AWPer ↔ donor)
        else if (!donorHasPrimary && donorMoney >= 5750 && awperMoney >= 3700)
        {
        	if (awperIsHuman)
			{
			    g_bIsAWPDonor[donor] = false;
			    g_bDonationInProgress[donor] = false;
			    return Plugin_Stop;
			}
            // AWPer buys AK → donor
            AddMoney(awper, -akPrice, true, true, "weapon_ak47");
            CSGO_ReplaceWeapon(awper, CS_SLOT_PRIMARY, "weapon_ak47");
            g_bAWPDropQueued[awper] = true;
            DataPack pack1 = new DataPack();
            pack1.WriteCell(awper);  // Dropper
            pack1.WriteCell(donor);  // Target
            CreateTimer(0.3, Timer_AWPGiveDrop, pack1);
            CreateTimer(0.6, Timer_BuyUtility, awper);

            // Donor buys AWP → AWPer
            AddMoney(donor, -awpPrice, true, true, "weapon_awp");
            CSGO_ReplaceWeapon(donor, CS_SLOT_PRIMARY, "weapon_awp");
            g_bAWPDropQueued[donor] = true;
            DataPack pack2 = new DataPack();
            pack2.WriteCell(donor);  // Dropper
            pack2.WriteCell(awper);  // Target
            CreateTimer(0.3, Timer_AWPGiveDrop, pack2);
            CreateTimer(0.6, Timer_BuyUtility, donor);
        }
    }

    if (g_bAWPDropQueued[donor] || g_bAWPDropQueued[awper])
	{
	    g_bShouldPickupDroppedGun[donor] = true;
	    if (!awperIsHuman)
        g_bShouldPickupDroppedGun[awper] = true;
	}

    return Plugin_Stop;
}

public Action Timer_BuySelfGun(Handle timer, any client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client) || !IsFakeClient(client))
        return Plugin_Stop;

    int team = GetClientTeam(client);
    bool isCT = (team == CS_TEAM_CT);

    char gun[32];
    if (isCT)
    {
        strcopy(gun, sizeof(gun), "weapon_m4a1");
    }
    else
    {
        strcopy(gun, sizeof(gun), "weapon_ak47");
    }

    int price = CS_GetWeaponPrice(client, isCT ? CSWeapon_M4A1 : CSWeapon_AK47);
    int money = GetEntProp(client, Prop_Send, "m_iAccount");

    if (money >= price)
    {
        AddMoney(client, -price, true, true, gun);
        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, gun);
        PrintToServer("[AWP DEBUG] %N bought self gun %s after drop", client, gun);
    }
    return Plugin_Stop;
}

public Action Timer_AWPGiveDrop(Handle timer, DataPack pack)
{
    pack.Reset();
    int dropper = pack.ReadCell();
    int target = pack.ReadCell();
    delete pack;

    if (!IsValidClient(dropper) || !IsFakeClient(dropper) || !IsPlayerAlive(dropper))
        return Plugin_Stop;
    if (!g_bAWPDropQueued[dropper])
        return Plugin_Stop;
    if (!IsValidClient(target) || !IsPlayerAlive(target))
        return Plugin_Stop;

    float fEyes[3];
    GetClientEyePosition(target, fEyes);
    BotSetLookAt(dropper, "Weapon Drop", fEyes, PRIORITY_HIGH, 3.0, false, 5.0, false);

    g_bDropWeapon[dropper] = true;
    g_bAWPDropQueued[dropper] = false;

    PrintToServer("[AWP DEBUG] Queued drop: %N will drop toward %N", dropper, target);
    return Plugin_Stop;
}

public Action Timer_BuyUtility(Handle timer, any client)
{
    if (!IsValidClient(client) || !IsFakeClient(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    int money = GetEntProp(client, Prop_Send, "m_iAccount");
    bool isCT = GetClientTeam(client) == CS_TEAM_CT;

    if (money >= 1000) {
        AddMoney(client, -1000, true, true, "vesthelm");

        SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
        SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);

        PrintToServer("[AWP DEBUG] %N FORCED full armor (money left: %d)", client, money - 1000);
    }
    else if (money >= 650) {
        AddMoney(client, -650, true, true, "vest");
        SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
        SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
        PrintToServer("[AWP DEBUG] %N FORCED kevlar only (money left: %d)", client, money - 650);
    }
    
    ForceBuyGrenadesDelayed(client);

    return Plugin_Stop;
}

public Action Timer_ClearBuyDelay(Handle timer, any client)
{
    if (IsValidClient(client))
    {
        g_bBuyDelayed[client] = false;
        PrintToServer("[AWP DEBUG] Safety: Cleared buy delay for %N", client);
    }
    return Plugin_Stop;
}

public Action Timer_ClearPickupFlag(Handle timer, any client)
{
    if (IsClientInGame(client))
        g_bShouldPickupDroppedGun[client] = false;
    return Plugin_Stop;
}

public MRESReturn BotCOS(DHookReturn hReturn)
{
	hReturn.Value = 0;
	return MRES_Supercede;
}

public MRESReturn BotSIN(DHookReturn hReturn)
{
	hReturn.Value = 0;
	return MRES_Supercede;
}

public MRESReturn CCSBot_GetPartPosition(DHookReturn hReturn, DHookParam hParams)
{
	int iPlayer = hParams.Get(1);
	int iPart = hParams.Get(2);
	
	if(iPart == 2)
	{
		int iBone = LookupBone(iPlayer, "head_0");
		if (iBone < 0)
			return MRES_Ignored;
		
		float fHead[3], fBad[3];
		GetBonePosition(iPlayer, iBone, fHead, fBad);
		
		fHead[2] += 4.0;
		
		hReturn.SetVector(fHead);
		
		return MRES_Override;
	}
	
	return MRES_Ignored;
}

public MRESReturn CCSBot_SetLookAt(int client, DHookParam hParams)
{
	char szDesc[64];
	
	DHookGetParamString(hParams, 1, szDesc, sizeof(szDesc));
	
	if (strcmp(szDesc, "Defuse bomb") == 0 || strcmp(szDesc, "Use entity") == 0 || strcmp(szDesc, "Open door") == 0 || strcmp(szDesc, "Hostage") == 0)
		return MRES_Ignored;
	else if (strcmp(szDesc, "Avoid Flashbang") == 0)
	{
		DHookSetParam(hParams, 3, PRIORITY_HIGH);
		
		return MRES_ChangedHandled;
	}
	else if (strcmp(szDesc, "Blind") == 0 || strcmp(szDesc, "Face outward") == 0)
		return MRES_Supercede;
	else if (strcmp(szDesc, "Breakable") == 0 || strcmp(szDesc, "Plant bomb on floor") == 0)
	{
		g_bDontSwitch[client] = true;
		CreateTimer(5.0, Timer_EnableSwitch, GetClientUserId(client));
		
		return strcmp(szDesc, "Plant bomb on floor") == 0 ? MRES_Supercede : MRES_Ignored;
	}
	else if(strcmp(szDesc, "GrenadeThrowBend") == 0)
	{
		float fEyePos[3];
		GetClientEyePosition(client, fEyePos);
		hParams.GetVector(2, g_fNadeTarget[client]);
		BotBendLineOfSight(client, fEyePos, g_fNadeTarget[client], g_fNadeTarget[client], 135.0);
		hParams.SetVector(2, g_fNadeTarget[client]);
		hParams.Set(4, 8.0);
		hParams.Set(6, 1.5);
		
		return MRES_ChangedHandled;
	}
	else if(strcmp(szDesc, "Noise") == 0)
	{
		bool bIsWalking = !!GetEntProp(client, Prop_Send, "m_bIsWalking");
		float fClientEyes[3], fNoisePosition[3];
		
		GetClientEyePosition(client, fClientEyes);
		if(IsItMyChance(35.0) && IsPointVisible(fClientEyes, fNoisePosition) && LineGoesThroughSmoke(fClientEyes, fNoisePosition) && !bIsWalking)
			DHookSetParam(hParams, 7, true);
			
		DHookGetParamVector(hParams, 2, fNoisePosition);
		
		if(BotMimic_IsPlayerMimicing(client) && !g_bIsFakeDefusing[client])
		{
			if (g_iDoingSmokeNum[client] != -1)
		    {
		        g_fNadeTimestamp[g_iDoingSmokeNum[client]] = GetGameTime();
		    }
			BotMimic_StopPlayerMimic(client);
			BotEquipBestWeapon(client, true);
		}
		
		if(eItems_GetWeaponSlotByWeapon(g_iActiveWeapon[client]) == CS_SLOT_KNIFE && GetTask(client) != ESCAPE_FROM_BOMB && GetTask(client) != ESCAPE_FROM_FLAMES)
			BotEquipBestWeapon(client, true);
		
		g_bDontSwitch[client] = true;
		CreateTimer(5.0, Timer_EnableSwitch, GetClientUserId(client));
		
		fNoisePosition[2] += 25.0;
		DHookSetParamVector(hParams, 2, fNoisePosition);
		
		return MRES_ChangedHandled;
	}
	else if(strcmp(szDesc, "Nearby enemy gunfire") == 0)
	{
		float fPos[3], fClientEyes[3];
		GetClientEyePosition(client, fClientEyes);
		DHookGetParamVector(hParams, 2, fPos);
		
		fPos[2] += 25.0;
		DHookSetParamVector(hParams, 2, fPos);
		
		return MRES_ChangedHandled;
	}
	else
	{
		float fPos[3];
		
		DHookGetParamVector(hParams, 2, fPos);
		fPos[2] += 25.0;
		DHookSetParamVector(hParams, 2, fPos);
		
		return MRES_ChangedHandled;
	}
}

public MRESReturn CCSBot_PickNewAimSpot(int client, DHookParam hParams)
{
	if (GetDisposition(client) == IGNORE_ENEMIES)
		return MRES_Ignored;

	if (g_bIsProBot[client])
	{
		SelectBestTargetPos(client, g_fTargetPos[client]);
	}
	else if (g_bIsIntermediateBot[client])
	{
		SelectIntermediateTargetPos(client, g_fTargetPos[client]);
	}

	if (!IsValidClient(g_iTarget[client]) || !IsPlayerAlive(g_iTarget[client]) || g_fTargetPos[client][2] == 0)
		return MRES_Ignored;

	SetEntDataVector(client, g_iBotTargetSpotOffset, g_fTargetPos[client]);
	return MRES_Ignored;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2])
{
	g_bBombPlanted = !!GameRules_GetProp("m_bBombPlanted");
	UpdateRoundTime();
	int aliveCTs = GetAliveTeamCount(CS_TEAM_CT);
	int aliveTs = GetAliveTeamCount(CS_TEAM_T);
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	float speed = GetVectorLength(velocity);
	bool bIsEnemyVisible = !!GetEntData(client, g_iEnemyVisibleOffset);
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (speed > 50.0 && GetEntityFlags(client) & FL_ONGROUND)
		{
			g_fLastMoveTime[client] = g_fCurrentTime;
		}
	}

	if (IsValidClient(client) && IsPlayerAlive(client) && IsFakeClient(client))
	{
		if(!g_bFreezetimeEnd && g_bDropWeapon[client] && view_as<LookAtSpotState>(GetEntData(client, g_iBotLookAtSpotStateOffset)) == LOOK_AT_SPOT)
		{
			CS_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY), true);
			FakeClientCommand(client, "buy %s", g_szPreviousBuy[client]);
			g_bDropWeapon[client] = false;
		}
		
		GetClientAbsOrigin(client, g_fBotOrigin[client]);
		g_iActiveWeapon[client] = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (!IsValidEntity(g_iActiveWeapon[client])) return Plugin_Continue;
		
		if(g_bFreezetimeEnd)
		{
			if (g_fTimeElapsed > 0.1 && g_fTimeElapsed < 8.0 && !BotMimic_IsPlayerMimicing(client) && !IsNearBreakable(client) && !g_bDidInitialSwitch[client])
			{
			    SwitchToKnife(client);
			}

			if (g_fTimeElapsed > 8.0 && !BotMimic_IsPlayerMimicing(client) && !g_bDidInitialSwitch[client] 
				|| bIsEnemyVisible && !g_bDidInitialSwitch[client] 
				|| IsNearBreakable(client) && !g_bDidInitialSwitch[client])
			{
				int primary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			    if (primary != -1 && IsValidEntity(primary))
			    {
			        SwitchToPrimaryWeapon(client);
			    }
			    else
			    {
			        SwitchToSecondaryWeapon(client);
			    }
			    g_bDidInitialSwitch[client] = true;
			}

			int iDefIndex = GetEntProp(g_iActiveWeapon[client], Prop_Send, "m_iItemDefinitionIndex");
			float fPlayerVelocity[3], fSpeed;
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fPlayerVelocity);
			fPlayerVelocity[2] = 0.0;
			fSpeed = GetVectorLength(fPlayerVelocity);
			
			g_pCurrArea[client] = NavMesh_GetNearestArea(g_fBotOrigin[client]);
			
			if ((GetAliveTeamCount(CS_TEAM_T) == 0 || GetAliveTeamCount(CS_TEAM_CT) == 0) && !g_bDontSwitch[client])
			{
				SDKCall(g_hSwitchWeaponCall, client, GetPlayerWeaponSlot(client, CS_SLOT_KNIFE), 0);
				g_bEveryoneDead = true;
			}

			// Stop mimicking if all enemies are dead
			if (BotMimic_IsPlayerMimicing(client) && AreAllEnemiesDead(client))
			{
			    BotMimic_StopPlayerMimic(client);
			    g_iDoingSmokeNum[client] = -1;
			}
				
			if (IsItMyChance(0.5) && g_iDoingSmokeNum[client] == -1 && g_iHoldingAngleNum[client] == -1)
		    {
		        g_iDoingSmokeNum[client] = GetNearestGrenade(client);
		    }

			if (g_bBombPlanted && g_iDoingSmokeNum[client] == -1 && g_iHoldingAngleNum[client] == -1)
			{
				int iPostPlantNade = GetNearestPostPlantGrenade(client);

				if (iPostPlantNade != -1)
				{
					g_iDoingSmokeNum[client] = iPostPlantNade;
					g_fNadeTimestamp[iPostPlantNade] = GetGameTime();
				}
			}
			
			if (GetClientTeam(client) == CS_TEAM_CT && eItems_FindWeaponByDefIndex(client, 9) != -1 && 
			    g_iHoldingAngleNum[client] == -1 && g_iDoingSmokeNum[client] == -1 && !g_bBombPlanted &&
			    !g_bAngleBlock[client] && g_fTimeElapsed >= 9.0 && !g_bDoingPeek[client])
			{
			    int availableAngle = -1;
				if (IsItMyChance(20.0)) 
				{
				    availableAngle = GetRandomAngle();
				    if (availableAngle != -1)
				    {
				        PrintToServer("[ANGLES] Bot is moving to random angle %d (20%% chance)", client, availableAngle);
				    }
				} 
				else 
				{
				    availableAngle = GetNearestAngle(client);
				}

				if (availableAngle != -1)
				{
				    g_bAngleClaimed[availableAngle] = true;
				    g_iHoldingAngleNum[client] = availableAngle;
				    g_bAngleBlock[client] = true; 
				    CreateTimer(30.0, ResetAngleBlock, client);
				    PrintToServer("[ANGLES] Bot is moving to nearest angle %d", client, availableAngle);
				}
				else
				{
				    PrintToServer("[ERROR] No valid angle found for bot %d", client);
				    g_iHoldingAngleNum[client] = -1; 
				}
			}

			if (g_iHoldingAngleNum[client] != -1 && g_fRoundTimeRemaining >= 45.0 && aliveCTs >= 3 && aliveTs >= 3)
			{
			    static bool wasPlayerMimicing[MAXPLAYERS+1];
			    bool isCurrentlyMimicing = BotMimic_IsPlayerMimicing(client);
			    
			    if (wasPlayerMimicing[client] && !isCurrentlyMimicing)
			    {
			        g_iHoldingAngleNum[client] = -1;
			    }
			    
			    wasPlayerMimicing[client] = isCurrentlyMimicing;
			    
			    if (!isCurrentlyMimicing)
			    {
			        float fDisToAngle;
			        float fTargetPos[3], fLookPos[3];
			        char szReplayPath[128];
			        Array_Copy(g_fAnglePos[g_iHoldingAngleNum[client]], fTargetPos, 3);
			        Array_Copy(g_fAngleLook[g_iHoldingAngleNum[client]], fLookPos, 3);
			        strcopy(szReplayPath, sizeof(szReplayPath), g_szAngleReplay[g_iHoldingAngleNum[client]]);
			        fDisToAngle = GetVectorDistance(g_fBotOrigin[client], fTargetPos);
			        BotMoveTo(client, fTargetPos, FASTEST_ROUTE);
			        
					if (fDisToAngle < 25.0)
		            {
	                BotSetLookAt(client, "Use entity", fLookPos, PRIORITY_HIGH, 2.0, false, 3.0, false);
		                if (view_as<LookAtSpotState>(GetEntData(client, g_iBotLookAtSpotStateOffset)) == LOOK_AT_SPOT &&
		                    GetVectorLength(velocity) == 0.0 && (GetEntityFlags(client) & FL_ONGROUND))
		                {
		                    BotMimic_PlayRecordFromFile(client, szReplayPath);

		                    if (IsLineBlockedByCloseSmoke(g_fBotOrigin[client], fLookPos))
		                    {
		                    	BotMimic_StopPlayerMimic(client);

		                        PrintToServer("[ANGLES] Bot at %d is abandoning angle %d due to smoke.", client, g_iHoldingAngleNum[client]);

		                        g_iHoldingAngleNum[client] = -1;
		                    }
		                }
				    }
				}
			}

			if (!g_bDoingPeek[client] && g_fTimeElapsed <= 5.0 && !g_bBombPlanted)
			{
			    if (!g_bPeekRolled[client])
			    {
			        g_bPeekRolled[client] = true;

			        int team = GetClientTeam(client);

			        if ((team == CS_TEAM_CT || team == CS_TEAM_T) &&
			            eItems_FindWeaponByDefIndex(client, 9) != -1 && // AWP
			            g_iHoldingAngleNum[client] == -1 &&
			            g_iDoingSmokeNum[client] == -1)
			        {
			            int iOvertimePlaying = GameRules_GetProp("m_nOvertimePlaying");
			            float fPeekChance = (iOvertimePlaying == 1) ? 75.0 : 50.0;

			            if (IsItMyChance(fPeekChance))
			            {
			                int peek = GetRandomPeekForTeam(team);

			                if (peek != -1)
			                {
			                    g_bDoingPeek[client] = true;
			                    g_iCurrentPeekNum[client] = peek;
			                    g_bAngleBlock[client] = true;

			                    CreateTimer(15.0, ResetAngleBlock, client);

			                    PrintToServer("[PEEKS] Bot %d (%s) assigned early peek #%d (Chance %.1f%% | Overtime: %d)",
			                        client, (team == CS_TEAM_CT) ? "CT" : "T", peek, fPeekChance, iOvertimePlaying);
			                }
			            }
			        }
			    }
			}
			
			if (g_bDoingPeek[client] && g_fTimeElapsed <= 5.0)
			{
			    int peek = g_iCurrentPeekNum[client];
			    float fTargetPos[3], fLookPos[3];
			    char szReplayPath[128];

			    Array_Copy(g_fPeekPos[peek], fTargetPos, 3);
			    Array_Copy(g_fPeekLook[peek], fLookPos, 3);
			    strcopy(szReplayPath, sizeof(szReplayPath), g_szPeekReplay[peek]);

			    float fDisToPeek = GetVectorDistance(g_fBotOrigin[client], fTargetPos);

			    BotMoveTo(client, fTargetPos, FASTEST_ROUTE);

			    if (fDisToPeek < 35.0)
			    {
			        BotSetLookAt(client, "Use entity", fLookPos, PRIORITY_HIGH, 1.0, false, 3.0, false);
			        BotMimic_PlayRecordFromFile(client, szReplayPath);
			        PrintToServer("[PEEKS] Bot %d started mimic for peek #%d (%s)", client, peek, szReplayPath);

			        g_bDoingPeek[client] = false;
			        g_iCurrentPeekNum[client] = -1;

			        CreateTimer(15.0, StopPeek_Callback, GetClientUserId(client));
			    }
			}

			if(GetDisposition(client) == SELF_DEFENSE)
				SetDisposition(client, ENGAGE_AND_INVESTIGATE);
			
			if(g_pCurrArea[client] != INVALID_NAV_AREA)
			{							
				if (g_pCurrArea[client].Attributes & NAV_MESH_WALK)
					iButtons |= IN_SPEED;
				
				if (g_pCurrArea[client].Attributes & NAV_MESH_RUN)
					iButtons &= ~IN_SPEED;
			}
			
			if (g_iDoingSmokeNum[client] != -1 && !BotMimic_IsPlayerMimicing(client))
			{
			    float fDisToNade;
			    float fTargetPos[3], fLookPos[3];
			    char szReplayPath[128];

			    Array_Copy(g_fNadePos[g_iDoingSmokeNum[client]], fTargetPos, 3);
			    Array_Copy(g_fNadeLook[g_iDoingSmokeNum[client]], fLookPos, 3);
			    strcopy(szReplayPath, sizeof(szReplayPath), g_szReplay[g_iDoingSmokeNum[client]]);

			    fDisToNade = GetVectorDistance(g_fBotOrigin[client], fTargetPos);
			    BotMoveTo(client, fTargetPos, FASTEST_ROUTE);

			    bool bIsEnemyVisible = !!GetEntData(client, g_iEnemyVisibleOffset);
			    if (fDisToNade > 25.0 && !bIsEnemyVisible && (g_fCurrentTime - g_fLastMoveTime[client]) > 2.0)
			    {
			        int iNade = g_iDoingSmokeNum[client];
			        g_iDoingSmokeNum[client] = -1;
			        BotCancelMoveTo(client);
			        if (iNade != -1)
			        {
			            g_fNadeClaimTime[iNade] = 0.0;
			        }
			    }
			    else if (fDisToNade < 25.0)
			    {
			        BotSetLookAt(client, "Use entity", fLookPos, PRIORITY_HIGH, 2.0, false, 3.0, false);
			        if (view_as<LookAtSpotState>(GetEntData(client, g_iBotLookAtSpotStateOffset)) == LOOK_AT_SPOT &&
			            GetVectorLength(velocity) == 0.0 && (GetEntityFlags(client) & FL_ONGROUND))
			        {
			            BotMimic_PlayRecordFromFile(client, szReplayPath);
			        }
			    }
			}
			
			if(!IsWarmupPeriod() && g_bThrowGrenade[client] && eItems_GetWeaponSlotByDefIndex(iDefIndex) == CS_SLOT_GRENADE)
			{
				BotThrowGrenade(client, g_fNadeTarget[client]);
				g_fThrowNadeTimestamp[client] = GetGameTime();
			}
			
			if(IsSafe(client) || g_bEveryoneDead)
				iButtons &= ~IN_SPEED;
				
			if (g_bIsProBot[client] || g_bIsIntermediateBot[client])
			{
			    int iDroppedC4 = GetNearestEntity(client, "weapon_c4");
			    bool pickupOverride = g_bShouldPickupDroppedGun[client];
			    
			    if ((!g_bBombPlanted || pickupOverride) && (!BotIsHiding(client) || pickupOverride) && (GetTask(client) != COLLECT_HOSTAGES || pickupOverride) && (GetTask(client) != RESCUE_HOSTAGES || pickupOverride))
			    {
			        float fClientEyes[3];
			        GetClientEyePosition(client, fClientEyes);
			    
			        int iAK47 = GetNearestEntity(client, "weapon_ak47");
			        int iM4A1 = GetNearestEntity(client, "weapon_m4a1");
			        int iAWP = GetNearestEntity(client, "weapon_awp");
			        int iPrimary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			        
			        int iPrimaryDefIndex = -1;

			        if (IsValidEntity(iPrimary))
			        {
			            iPrimaryDefIndex = GetEntProp(iPrimary, Prop_Send, "m_iItemDefinitionIndex");
			        }

			        if (g_bIsAWPer[client] && IsValidEntity(iAWP))
			        {
			            float fAWPLocation[3];
			            GetEntPropVector(iAWP, Prop_Send, "m_vecOrigin", fAWPLocation);
			            
			            if (iPrimaryDefIndex != 9)
			            {
			                if (GetVectorLength(fAWPLocation) != 0.0 && IsPointVisible(fClientEyes, fAWPLocation))
			                {
			                    BotMoveTo(client, fAWPLocation, FASTEST_ROUTE);
			                    if (GetVectorDistance(g_fBotOrigin[client], fAWPLocation) < 50.0 && iPrimary != -1)
			                    {
			                        CS_DropWeapon(client, iPrimary, false);
			                    }
			                }
			            }
			        }
			        else if (!IsClientAWPer(client) && IsValidEntity(iAWP) && !g_bHasPickedUpAWP[client] && AreAllEnemiesDead(client))
			        {
			            int awper = FindAWPerWithoutAWP(client);
			            
			            if (awper != 0)
			            {
			                float fAWPLocation[3];
			                GetEntPropVector(iAWP, Prop_Send, "m_vecOrigin", fAWPLocation);
			                
			                if (GetVectorLength(fAWPLocation) != 0.0 && IsPointVisible(fClientEyes, fAWPLocation))
			                {
			                    BotMoveTo(client, fAWPLocation, FASTEST_ROUTE);
			                    
			                    if (GetVectorDistance(g_fBotOrigin[client], fAWPLocation) < 50.0 && iPrimary != -1)
			                    {
			                        CS_DropWeapon(client, iPrimary, false);
			                        g_iSavedAWPFor[client] = awper;
			                    	g_bHasSavedAWP[awper] = true;
			                    	g_bHasPickedUpAWP[client] = true;
			                    }
			                }
			            }
			        }
			        if ((!g_bBombPlanted || pickupOverride) && (!BotIsHiding(client) || pickupOverride) && (GetTask(client) != COLLECT_HOSTAGES || pickupOverride) && (GetTask(client) != RESCUE_HOSTAGES || pickupOverride) && (!IsValidEntity(iDroppedC4) || pickupOverride))
			        {
						if (IsValidEntity(iAK47))
						{
							iPrimaryDefIndex = IsValidEntity(iPrimary) ? GetEntProp(iPrimary, Prop_Send, "m_iItemDefinitionIndex") : 0;
							float fAK47Location[3];
							
							if ((iPrimaryDefIndex != 7 && iPrimaryDefIndex != 9) || iPrimary == -1)
							{
								GetEntPropVector(iAK47, Prop_Send, "m_vecOrigin", fAK47Location);

								if (GetVectorLength(fAK47Location) != 0.0 && (pickupOverride || IsPointVisible(fClientEyes, fAK47Location)))
									BotMoveTo(client, fAK47Location, FASTEST_ROUTE);
							}
						}
						else if (IsValidEntity(iM4A1))
						{
							iPrimaryDefIndex = IsValidEntity(iPrimary) ? GetEntProp(iPrimary, Prop_Send, "m_iItemDefinitionIndex") : 0;
							float fM4A1Location[3];

							if (iPrimaryDefIndex != 7 && iPrimaryDefIndex != 9 && iPrimaryDefIndex != 16 && iPrimaryDefIndex != 60)
							{
								GetEntPropVector(iM4A1, Prop_Send, "m_vecOrigin", fM4A1Location);

								if (GetVectorLength(fM4A1Location) != 0.0 && (pickupOverride || IsPointVisible(fClientEyes, fM4A1Location)))
								{
									BotMoveTo(client, fM4A1Location, FASTEST_ROUTE);
									if (GetVectorDistance(g_fBotOrigin[client], fM4A1Location) < 50.0 && GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1)
										CS_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY), false);
								}
							}
							else if (iPrimary == -1)
							{
								GetEntPropVector(iM4A1, Prop_Send, "m_vecOrigin", fM4A1Location);

								if (pickupOverride || IsPointVisible(fClientEyes, fM4A1Location))
									BotMoveTo(client, fM4A1Location, FASTEST_ROUTE);
							}
						}
						
						//Pistols
						int iUSP = GetNearestEntity(client, "weapon_hkp2000");
						int iP250 = GetNearestEntity(client, "weapon_p250");
						int iFiveSeven = GetNearestEntity(client, "weapon_fiveseven");
						int iTec9 = GetNearestEntity(client, "weapon_tec9");
						int iDeagle = GetNearestEntity(client, "weapon_deagle");
						int iSecondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
						int iSecondaryDefIndex;
						
						if (IsValidEntity(iDeagle))
						{						
							iSecondaryDefIndex = IsValidEntity(iSecondary) ? GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex") : 0;
							float fDeagleLocation[3];
							
							if (iSecondaryDefIndex == 4 || iSecondaryDefIndex == 32 || iSecondaryDefIndex == 61 || iSecondaryDefIndex == 36 || iSecondaryDefIndex == 30 || iSecondaryDefIndex == 3 || iSecondaryDefIndex == 63)
							{
								GetEntPropVector(iDeagle, Prop_Send, "m_vecOrigin", fDeagleLocation);
								
								if (GetVectorLength(fDeagleLocation) != 0.0 && IsPointVisible(fClientEyes, fDeagleLocation))
								{
									BotMoveTo(client, fDeagleLocation, FASTEST_ROUTE);
									if (GetVectorDistance(g_fBotOrigin[client], fDeagleLocation) < 50.0 && GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
										CS_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY), false);
								}
							}
						}
						else if (IsValidEntity(iTec9))
						{						
							iSecondaryDefIndex = IsValidEntity(iSecondary) ? GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex") : 0;
							float fTec9Location[3];
							
							if (iSecondaryDefIndex == 4 || iSecondaryDefIndex == 32 || iSecondaryDefIndex == 61 || iSecondaryDefIndex == 36)
							{
								GetEntPropVector(iTec9, Prop_Send, "m_vecOrigin", fTec9Location);
								
								if (GetVectorLength(fTec9Location) != 0.0 && IsPointVisible(fClientEyes, fTec9Location))
								{
									BotMoveTo(client, fTec9Location, FASTEST_ROUTE);
									if (GetVectorDistance(g_fBotOrigin[client], fTec9Location) < 50.0 && GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
										CS_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY), false);
								}
							}
						}
						else if (IsValidEntity(iFiveSeven))
						{
							iSecondaryDefIndex = IsValidEntity(iSecondary) ? GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex") : 0;
							float fFiveSevenLocation[3];
							
							if (iSecondaryDefIndex == 4 || iSecondaryDefIndex == 32 || iSecondaryDefIndex == 61 || iSecondaryDefIndex == 36)
							{
								GetEntPropVector(iFiveSeven, Prop_Send, "m_vecOrigin", fFiveSevenLocation);
								
								if (GetVectorLength(fFiveSevenLocation) != 0.0 && IsPointVisible(fClientEyes, fFiveSevenLocation))
								{
									BotMoveTo(client, fFiveSevenLocation, FASTEST_ROUTE);
									if (GetVectorDistance(g_fBotOrigin[client], fFiveSevenLocation) < 50.0 && GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
										CS_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY), false);
								}
							}
						}
						else if (IsValidEntity(iP250))
						{
							iSecondaryDefIndex = IsValidEntity(iSecondary) ? GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex") : 0;
							float fP250Location[3];
							
							if (iSecondaryDefIndex == 4 || iSecondaryDefIndex == 32 || iSecondaryDefIndex == 61)
							{
								GetEntPropVector(iP250, Prop_Send, "m_vecOrigin", fP250Location);
								
								if (GetVectorLength(fP250Location) != 0.0 && IsPointVisible(fClientEyes, fP250Location))
								{
									BotMoveTo(client, fP250Location, FASTEST_ROUTE);
									if (GetVectorDistance(g_fBotOrigin[client], fP250Location) < 50.0 && GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
										CS_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY), false);
								}
							}
						}
						else if (IsValidEntity(iUSP))
						{
							iSecondaryDefIndex = IsValidEntity(iSecondary) ? GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex") : 0;
							float fUSPLocation[3];
							
							if (iSecondaryDefIndex == 4)
							{
								GetEntPropVector(iUSP, Prop_Send, "m_vecOrigin", fUSPLocation);
								
								if (GetVectorLength(fUSPLocation) != 0.0 && IsPointVisible(fClientEyes, fUSPLocation))
								{
									BotMoveTo(client, fUSPLocation, FASTEST_ROUTE);
									if (GetVectorDistance(g_fBotOrigin[client], fUSPLocation) < 50.0 && GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
										CS_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY), false);
								}
							}
						}
					}
				}
			}

			if (g_fBombsiteDisableTime > 0.0 && GetGameTime() - g_fBombsiteDisableTime <= 5.0 && GetClientTeam(client) == CS_TEAM_T)
	        {
	            iButtons |= IN_SPEED;
	        }

	        if (g_bBombPlanted && GetClientTeam(client) == CS_TEAM_CT && !BotMimic_IsPlayerMimicing(client))
	        {
	        	int iPlantedC4 = FindEntityByClassname(-1, "planted_c4");
			    if (IsValidEntity(iPlantedC4))
			    {		        	
		        	if (g_bBotCompromised[client])
					{
					    iButtons &= ~IN_SPEED;
					    if (!g_bDidRun[client])
					    {
					        g_bDidRun[client] = true;
					        PrintToServer("[RETAKE] Bot %d discovered - now runs", client);
					    }
					}
		        	if (g_fTimeLeft < 19.0)
		        	{
		        		iButtons &= ~IN_SPEED;
				        if (!g_bDidRun[client])
				        {
				        	g_bDidRun[client] = true;
				        	PrintToServer("[RETAKE] Little time on the bomb - CT Bots now run");
				        }
		        	}
		        	else if (aliveCTs >= 4 && aliveTs == 1)
		        	{
		        		iButtons &= ~IN_SPEED;
		        		if (!g_bDidRun[client])
		        		{
		        			g_bDidRun[client] = true;
		        			PrintToServer("[RETAKE] 4v1 - CT Bots now run");
		        		}
		        	}
		        }
	        }

			if ((g_bIsProBot[client] || g_bIsIntermediateBot[client]) && GetDisposition(client) != IGNORE_ENEMIES)
			{		
				g_iTarget[client] = BotGetEnemy(client);
				
				float fTargetDistance;
				int iZoomLevel;
				bool bIsEnemyVisible = !!GetEntData(client, g_iEnemyVisibleOffset);
				bool bIsHiding = BotIsHiding(client);
				bool bIsDucking = !!(GetEntityFlags(client) & FL_DUCKING);
				bool bIsReloading = IsPlayerReloading(client);
				bool bResumeZoom = !!GetEntProp(client, Prop_Send, "m_bResumeZoom");
				
				if(bResumeZoom)
					g_fShootTimestamp[client] = g_fCurrentTime;
				
				if(HasEntProp(g_iActiveWeapon[client], Prop_Send, "m_zoomLevel"))
					iZoomLevel = GetEntProp(g_iActiveWeapon[client], Prop_Send, "m_zoomLevel");
				
				if(bIsHiding && (iDefIndex == 8 || iDefIndex == 39) && iZoomLevel == 0)
					iButtons |= IN_ATTACK2;
				else if(!bIsHiding && (iDefIndex == 8 || iDefIndex == 39) && iZoomLevel == 1)
					iButtons |= IN_ATTACK2;
				
				if (bIsHiding && g_bUncrouch[client])
					iButtons &= ~IN_DUCK;
					
				if (!IsValidClient(g_iTarget[client]) || !IsPlayerAlive(g_iTarget[client]) || g_fTargetPos[client][2] == 0)
				{
					g_iPrevTarget[client] = g_iTarget[client];
					return Plugin_Continue;
				}

				if(BotMimic_IsPlayerMimicing(client) && !g_bIsFakeDefusing[client])
				{
					if (g_iDoingSmokeNum[client] != -1)
				    {
				        g_fNadeTimestamp[g_iDoingSmokeNum[client]] = GetGameTime();
				    }
					BotMimic_StopPlayerMimic(client);
					int primary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
				    if (primary != -1 && IsValidEntity(primary))
				    {
				        SwitchToPrimaryWeapon(client);
				    }
				    else
				    {
				        SwitchToSecondaryWeapon(client);
				    }
				}

				if (BotMimic_IsPlayerMimicing(client) && g_bIsFakeDefusing[client])
				{
				    float fClientOrigin[3];
				    GetClientAbsOrigin(client, fClientOrigin);

				    bool bEnemyNearby = false;
				    float fEnemyDir[3];

				    for (int i = 1; i <= MaxClients; i++)
				    {
				        if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) == GetClientTeam(client))
				            continue;

				        float fEnemyOrigin[3];
				        GetClientAbsOrigin(i, fEnemyOrigin);

				        float fDist = GetVectorDistance(fClientOrigin, fEnemyOrigin);

				        if (fDist < 1200.0)
				        {
				            int iButtons = GetClientButtons(i);
				            float fEnemyVel[3];
				            GetEntPropVector(i, Prop_Data, "m_vecVelocity", fEnemyVel);

				            bool bIsShooting = (iButtons & IN_ATTACK) != 0;
				            bool bIsRunning = GetVectorLength(fEnemyVel) > 135.0; // running threshold

				            if (bIsShooting || bIsRunning)
				            {
				                bEnemyNearby = true;

				                SubtractVectors(fEnemyOrigin, fClientOrigin, fEnemyDir);
				                NormalizeVector(fEnemyDir, fEnemyDir);
				                break;
				            }
				        }
				    }

				    if (bEnemyNearby)
				    {
				        BotMimic_StopPlayerMimic(client);
				        PrintToServer("[FAKEDEFUSE] Enemy nearby - stopping recording");
				        g_bIsFakeDefusing[client] = false;

				        float fLookAngles[3];
				        GetVectorAngles(fEnemyDir, fLookAngles);
				        TeleportEntity(client, NULL_VECTOR, fLookAngles, NULL_VECTOR);
				        return Plugin_Stop;
				    }
				}
				
				if ((eItems_GetWeaponSlotByDefIndex(iDefIndex) == CS_SLOT_KNIFE || eItems_GetWeaponSlotByDefIndex(iDefIndex) == CS_SLOT_GRENADE) && GetTask(client) != ESCAPE_FROM_BOMB && GetTask(client) != ESCAPE_FROM_FLAMES)
						BotEquipBestWeapon(client, true);
				
				if (bIsEnemyVisible && GetEntityMoveType(client) != MOVETYPE_LADDER)
				{
					if(g_iPrevTarget[client] == -1)
						g_fCrouchTimestamp[client] = GetGameTime() + Math_GetRandomFloat(0.23, 0.25);
					fTargetDistance = GetVectorDistance(g_fBotOrigin[client], g_fTargetPos[client]);
					
					float fClientEyes[3], fClientAngles[3], fAimPunchAngle[3], fToAimSpot[3], fAimDir[3];
						
					GetClientEyePosition(client, fClientEyes);
					SubtractVectors(g_fTargetPos[client], fClientEyes, fToAimSpot);
					GetClientEyeAngles(client, fClientAngles);
					GetEntPropVector(client, Prop_Send, "m_aimPunchAngle", fAimPunchAngle);
					ScaleVector(fAimPunchAngle, (FindConVar("weapon_recoil_scale").FloatValue));
					AddVectors(fClientAngles, fAimPunchAngle, fClientAngles);
					GetViewVector(fClientAngles, fAimDir);
					
					float fRangeToEnemy = NormalizeVector(fToAimSpot, fToAimSpot);
					float fOnTarget = GetVectorDotProduct(fToAimSpot, fAimDir);
					float fAimTolerance = Cosine(ArcTangent(32.0 / fRangeToEnemy));
					
					if(g_iPrevTarget[client] == -1 && fOnTarget > fAimTolerance)
						g_fCrouchTimestamp[client] = GetGameTime() + Math_GetRandomFloat(0.23, 0.25);
						
					switch(iDefIndex)
					{
						case 7, 8, 10, 13, 14, 16, 17, 19, 23, 24, 25, 26, 28, 33, 34, 39, 60:
						{
							if (fOnTarget > fAimTolerance && !bIsDucking && fTargetDistance < 2000.0 && iDefIndex != 17 && iDefIndex != 19 && iDefIndex != 23 && iDefIndex != 24 && iDefIndex != 25 && iDefIndex != 26 && iDefIndex != 33 && iDefIndex != 34)
								AutoStop(client, fVel, fAngles);
							else if (fTargetDistance > 2000.0 && GetEntDataFloat(client, g_iFireWeaponOffset) == GetGameTime())
								AutoStop(client, fVel, fAngles);
						
							if (fOnTarget > fAimTolerance && fTargetDistance < 2000.0)
							{
								iButtons &= ~IN_ATTACK;
							
								if(!bIsReloading && (fSpeed < 50.0 || bIsDucking || iDefIndex == 17 || iDefIndex == 19 || iDefIndex == 23 || iDefIndex == 24 || iDefIndex == 25 || iDefIndex == 26 || iDefIndex == 33 || iDefIndex == 34))
								{
									iButtons |= IN_ATTACK;
									SetEntDataFloat(client, g_iFireWeaponOffset, g_fCurrentTime);
								}
							}
						}
						case 1:
						{
							if (GetGameTime() - GetEntDataFloat(client, g_iFireWeaponOffset) < 0.15 && !bIsDucking && !bIsReloading)
								AutoStop(client, fVel, fAngles);
						}
						case 9, 40:
						{
							if (fTargetDistance < 2750.0 && !bIsReloading && GetEntProp(client, Prop_Send, "m_bIsScoped") && GetGameTime() - g_fShootTimestamp[client] > 0.4 && GetClientAimTarget(client, true) == g_iTarget[client])
							{
								iButtons |= IN_ATTACK;
								SetEntDataFloat(client, g_iFireWeaponOffset, g_fCurrentTime);
							}	
						}
					}
					
					float fClientLoc[3];
					Array_Copy(g_fBotOrigin[client], fClientLoc, 3);
					fClientLoc[2] += HalfHumanHeight;
					
					if (GetGameTime() >= g_fCrouchTimestamp[client] && !GetEntProp(g_iActiveWeapon[client], Prop_Data, "m_bInReload") && IsPointVisible(fClientLoc, g_fTargetPos[client]) && fOnTarget > fAimTolerance && fTargetDistance < 2000.0 && (iDefIndex == 7 || iDefIndex == 8 || iDefIndex == 10 || iDefIndex == 13 || iDefIndex == 14 || iDefIndex == 16 || iDefIndex == 39 || iDefIndex == 60 || iDefIndex == 28))
						iButtons |= IN_DUCK;
						
					g_iPrevTarget[client] = g_iTarget[client];
				}
			}
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (IsValidClient(victim) && IsFakeClient(victim) && !IsPlayerAlive(victim) && g_fBombsiteDisableTime > 0.0 && GetGameTime() - g_fBombsiteDisableTime <= 5.0 && GetClientTeam(victim) == CS_TEAM_T)
    {
        PrintToServer("[FAKEPLANT] Bot %d died, resetting Bombsite Timer", victim);
        EnableBombSites();
    }

    if (g_bBombPlanted && IsValidClient(attacker) && IsFakeClient(attacker) && GetClientTeam(attacker) == CS_TEAM_CT && IsBotNearPlantedBomb(attacker))
    {
        g_fLastKill[attacker] = GetGameTime();
        g_bBotCompromised[attacker] = true;
        SpreadCompromisedStateFrom(attacker);
    }

    if (g_bAngleBlock[victim])
    {
    	CreateTimer(0.1, ResetAngleBlock, victim);
    }

    if (g_bDoingPeek[victim])
    {
    	CreateTimer(0.1, StopPeek_Callback, victim);
    }
    return Plugin_Continue; 
}

public void OnPlayerSpawn(Event eEvent, const char[] szName, bool bDontBroadcast)
{
    int client = GetClientOfUserId(eEvent.GetInt("userid"));
    SetPlayerTeammateColor(client);

    if (IsValidClient(client) && IsFakeClient(client))
    {
        if (g_bUseUSP[client] && GetClientTeam(client) == CS_TEAM_CT)
        {
            char szUSP[32];
            GetClientWeapon(client, szUSP, sizeof(szUSP));
            if (strcmp(szUSP, "weapon_hkp2000") == 0)
                CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_usp_silencer");
        }
    }
}

public void BotMimic_OnPlayerStopsMimicing(int client, char[] szName, char[] szCategory, char[] szPath) 
{
    // Update the timestamp for this grenade position
    if (g_iDoingSmokeNum[client] != -1) {
        g_fNadeTimestamp[g_iDoingSmokeNum[client]] = GetGameTime();
    }
    
    g_iDoingSmokeNum[client] = -1;
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client) && IsFakeClient(client))
		g_iProfileRank[client] = 0;
}

public OnClientPutInServer(client)
{
    if (!IsFakeClient(client))
        return;

    LoadAWPers();
}

public void eItems_OnItemsSynced()
{
	ServerCommand("changelevel %s", g_szMap);
}

void ParseMapNades(const char[] szMap, bool bPistolNades)
{
    char szPath[PLATFORM_MAX_PATH];
    
    if (bPistolNades)
    {
        BuildPath(Path_SM, szPath, sizeof(szPath), "configs/bot_nades_pistol.txt");
    }
    else
    {
        BuildPath(Path_SM, szPath, sizeof(szPath), "configs/bot_nades.txt");
    }
    
    if (!FileExists(szPath))
    {
        PrintToServer("Configuration file %s is not found.", szPath);
        return;
    }
    
    KeyValues kv = new KeyValues("Nades");
    
    if (!kv.ImportFromFile(szPath))
    {
        delete kv;
        PrintToServer("Unable to parse Key Values file %s.", szPath);
        return;
    }
    
    if (!kv.JumpToKey(szMap))
    {
        delete kv;
        PrintToServer("No nades found for %s.", szMap);
        return;
    }
    
    if (!kv.GotoFirstSubKey())
    {
        delete kv;
        PrintToServer("Nades are not configured right for %s.", szMap);
        return;
    }
    
    int i = 0;
    do
    {
        char szTeam[4];
        
		if (bPistolNades)
        {
            kv.GetVector("position", g_fPistolNadePos[i]);
            kv.GetVector("lookat", g_fPistolNadeLook[i]);
            g_iPistolNadeDefIndex[i] = kv.GetNum("nadedefindex");
            kv.GetString("replay", g_szPistolReplay[i], 128);
            g_fPistolNadeTimestamp[i] = kv.GetFloat("timestamp");
        }
        else
        {
            kv.GetVector("position", g_fNormalNadePos[i]);
            kv.GetVector("lookat", g_fNormalNadeLook[i]);
            g_iNormalNadeDefIndex[i] = kv.GetNum("nadedefindex");
            kv.GetString("replay", g_szNormalReplay[i], 128);
            g_fNormalNadeTimestamp[i] = kv.GetFloat("timestamp");
        }

        kv.GetString("team", szTeam, sizeof(szTeam));
        if(strcmp(szTeam, "CT", false) == 0)
            {
            if (bPistolNades)
                g_iPistolNadeTeam[i] = CS_TEAM_CT;
            else
                g_iNormalNadeTeam[i] = CS_TEAM_CT;
        }
        else if(strcmp(szTeam, "T", false) == 0)
            {
            if (bPistolNades)
                g_iPistolNadeTeam[i] = CS_TEAM_T;
            else
                g_iNormalNadeTeam[i] = CS_TEAM_T;
        }
        
        i++;
    } while (kv.GotoNextKey());
    
    delete kv;

    if (bPistolNades)
        g_iPistolNades = i;
    else
        g_iNormalNades = i;
}

void ParsePostPlantNades(const char[] szMap)
{
    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof(szPath), "configs/bot_nades_postplant.txt");
    if (!FileExists(szPath))
    {
        PrintToServer("Configuration file %s is not found.", szPath);
        return;
    }
    KeyValues kv = new KeyValues("PostPlantNades");
    if (!kv.ImportFromFile(szPath))
    {
        delete kv;
        PrintToServer("Unable to parse Key Values file %s.", szPath);
        return;
    }
    if (!kv.JumpToKey(szMap))
    {
        delete kv;
        PrintToServer("No post-plant nades found for %s.", szMap);
        return;
    }
    if (!kv.GotoFirstSubKey())
    {
        delete kv;
        PrintToServer("Post-plant nades are not configured right for %s.", szMap);
        return;
    }
    
    int i = 0;
    do
    {
        char szTeam[4];
        kv.GetVector("position", g_fPostPlantNadePos[i]);
        kv.GetVector("lookat", g_fPostPlantNadeLook[i]);
        g_iPostPlantNadeDefIndex[i] = kv.GetNum("nadedefindex");
        kv.GetString("replay", g_szPostPlantReplay[i], 128);
        g_fPostPlantNadeTimestamp[i] = kv.GetFloat("timestamp");
        kv.GetString("team", szTeam, sizeof(szTeam));
        
        if (strcmp(szTeam, "CT", false) == 0)
            g_iPostPlantNadeTeam[i] = CS_TEAM_CT;
        else if (strcmp(szTeam, "T", false) == 0)
            g_iPostPlantNadeTeam[i] = CS_TEAM_T;
        i++;
    } while (kv.GotoNextKey());
    
    g_iPostPlantNades = i;
    delete kv;
}

void BuildActiveNadesForRound()
{
    bool bPistolRound = (g_iCurrentRound == 0 || g_iCurrentRound == 12);
    int iMainNades = bPistolRound ? g_iPistolNades : g_iNormalNades;

    for (int i = 0; i < iMainNades; i++)
    {
        if (bPistolRound)
        {
            for (int j = 0; j < 3; j++)
            {
                g_fNadePos[i][j] = g_fPistolNadePos[i][j];
                g_fNadeLook[i][j] = g_fPistolNadeLook[i][j];
            }
            g_iNadeDefIndex[i] = g_iPistolNadeDefIndex[i];
            strcopy(g_szReplay[i], sizeof(g_szReplay[]), g_szPistolReplay[i]);
            g_fNadeTimestamp[i] = g_fPistolNadeTimestamp[i];
            g_iNadeTeam[i] = g_iPistolNadeTeam[i];
        }
        else
        {
            for (int j = 0; j < 3; j++)
            {
                g_fNadePos[i][j] = g_fNormalNadePos[i][j];
                g_fNadeLook[i][j] = g_fNormalNadeLook[i][j];
            }
            g_iNadeDefIndex[i] = g_iNormalNadeDefIndex[i];
            strcopy(g_szReplay[i], sizeof(g_szReplay[]), g_szNormalReplay[i]);
            g_fNadeTimestamp[i] = g_fNormalNadeTimestamp[i];
            g_iNadeTeam[i] = g_iNormalNadeTeam[i];
        }
    }

    g_iPostPlantNadesStartIndex = iMainNades;

    for (int i = 0; i < g_iPostPlantNades; i++)
    {
        int iTarget = g_iPostPlantNadesStartIndex + i;
        for (int j = 0; j < 3; j++)
        {
            g_fNadePos[iTarget][j] = g_fPostPlantNadePos[i][j];
            g_fNadeLook[iTarget][j] = g_fPostPlantNadeLook[i][j];
        }
        g_iNadeDefIndex[iTarget] = g_iPostPlantNadeDefIndex[i];
        strcopy(g_szReplay[iTarget], sizeof(g_szReplay[]), g_szPostPlantReplay[i]);
        g_fNadeTimestamp[iTarget] = g_fPostPlantNadeTimestamp[i];
        g_iNadeTeam[iTarget] = g_iPostPlantNadeTeam[i];
    }

    g_iMaxNades = g_iPostPlantNadesStartIndex + g_iPostPlantNades;
}

void ParseMapAngles(const char[] szMap)
{
    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof(szPath), "configs/bot_angles.txt");

    if (!FileExists(szPath))
    {
        PrintToServer("Configuration file %s not found.", szPath);
        return;
    }

    KeyValues kv = new KeyValues("Angles");

    if (!kv.ImportFromFile(szPath))
    {
        delete kv;
        PrintToServer("Unable to parse KeyValues file %s.", szPath);
        return;
    }

    if (!kv.JumpToKey(szMap))
    {
        delete kv;
        PrintToServer("No angles found for %s.", szMap);
        return;
    }

    if (!kv.GotoFirstSubKey())
    {
        delete kv;
        PrintToServer("Angles not configured correctly for %s.", szMap);
        return;
    }

    int i = 0;
    do
    {
        char szTeam[4];
        kv.GetVector("position", g_fAnglePos[i]);
        kv.GetVector("lookat", g_fAngleLook[i]);
        g_iAngleDefIndex[i] = kv.GetNum("nadedefindex");
        kv.GetString("replay", g_szAngleReplay[i], 128);
        g_fAngleTimestamp[i] = kv.GetFloat("timestamp");
        kv.GetString("team", szTeam, sizeof(szTeam));
        g_iAngleTeam[i] = (strcmp(szTeam, "CT", false) == 0) ? CS_TEAM_CT : CS_TEAM_T;
        i++;
    } while (kv.GotoNextKey());

    delete kv;
    g_iMaxAngles = i;
}

void ParseMapPeeks(const char[] szMap)
{
    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof(szPath), "configs/bot_peeks.txt");

    if (!FileExists(szPath))
    {
        PrintToServer("[PEEKS] Configuration file %s not found.", szPath);
        return;
    }

    KeyValues kv = new KeyValues("Peeks");

    if (!kv.ImportFromFile(szPath))
    {
        delete kv;
        PrintToServer("[PEEKS] Unable to parse KeyValues file %s.", szPath);
        return;
    }

    if (!kv.JumpToKey(szMap))
    {
        delete kv;
        PrintToServer("[PEEKS] No peeks found for map %s.", szMap);
        return;
    }

    if (!kv.GotoFirstSubKey())
    {
        delete kv;
        PrintToServer("[PEEKS] Peeks not configured correctly for map %s.", szMap);
        return;
    }

    int i = 0;
    do
    {
        char szTeam[4];
        kv.GetVector("position", g_fPeekPos[i]);
        kv.GetVector("lookat", g_fPeekLook[i]);
        g_iPeekDefIndex[i] = kv.GetNum("nadedefindex", 9);
        kv.GetString("replay", g_szPeekReplay[i], sizeof(g_szPeekReplay[]));
        kv.GetString("team", szTeam, sizeof(szTeam));
        g_iPeekTeam[i] = (strcmp(szTeam, "CT", false) == 0) ? CS_TEAM_CT : CS_TEAM_T;
        i++;
    }
    while (kv.GotoNextKey() && i < MAX_PEEKS);

    g_iMaxPeeks = i;
    delete kv;
}

void LoadAWPers()
{
    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof(szPath), "configs/awpers.txt");

    if (!FileExists(szPath))
    {
        PrintToServer("AWPer configuration file not found: %s", szPath);
        return;
    }

    KeyValues kv = new KeyValues("AWPers");

    if (!kv.ImportFromFile(szPath))
    {
        delete kv;
        PrintToServer("Error parsing AWPers file: %s", szPath);
        return;
    }

    if (!kv.GotoFirstSubKey())
    {
        delete kv;
        PrintToServer("No AWPer entries found.");
        return;
    }

    for (int i = 1; i <= MAXPLAYERS; i++)
    {
        g_bIsAWPer[i] = false;
    }

    int count = 0;
    do
    {
        char name[64];
        kv.GetSectionName(name, sizeof(name));

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsFakeClient(i))
            {
                char botName[64];
                GetClientName(i, botName, sizeof(botName));

                if (strcmp(name, botName) == 0)
                {
                    g_bIsAWPer[i] = true;
                    PrintToServer("Loaded AWPer: %s (Client %d)", name, i);
                    count++;
                }
            }
        }
    } while (kv.GotoNextKey());

    PrintToServer("Loaded %d AWPers from file.", count);
    delete kv;
}

void LoadBotTemplates()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/bot_templates.json");

    if (!FileExists(sPath))
    {
        PrintToServer("[LIGA] bot_templates.json not found at %s", sPath);
        return;
    }

    g_hBotTemplates.Clear();

    File hFile = OpenFile(sPath, "r");
    if (hFile == null)
    {
        PrintToServer("[LIGA] Could not open bot_templates.json!");
        return;
    }

    char buffer[4096];
    char botName[64];
    char templateName[64];

    while (!IsEndOfFile(hFile) && ReadFileLine(hFile, buffer, sizeof(buffer)))
    {
        // parse lines like: "BOT Dusty": "Abysmal",
        if (StrContains(buffer, ":") != -1)
        {
            TrimString(buffer);
            ReplaceString(buffer, sizeof(buffer), "\"", ""); // remove quotes
            ReplaceString(buffer, sizeof(buffer), ",", "");  // remove commas

            char parts[2][128];
            ExplodeString(buffer, ":", parts, sizeof(parts), sizeof(parts[]));

            TrimString(parts[0]);
            TrimString(parts[1]);

            strcopy(botName, sizeof(botName), parts[0]);
            strcopy(templateName, sizeof(templateName), parts[1]);

            g_hBotTemplates.SetString(botName, templateName);
        }
    }

    delete hFile;
    PrintToServer("[LIGA] Loaded bot_templates.json (%d entries)", g_hBotTemplates.Size);
}

bool IsProBot(const char[] szName, char[] szCrosshairCode, int iSize)
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), "data/bot_info.json");
	
	if (!FileExists(szPath))
	{
		PrintToServer("Configuration file %s is not found.", szPath);
		return false;
	}
	
	JSONObject jData = JSONObject.FromFile(szPath);
	if(jData.HasKey(szName))
	{
		JSONObject jInfoObj = view_as<JSONObject>(jData.Get(szName));
		jInfoObj.GetString("crosshair_code", szCrosshairCode, iSize);
		delete jInfoObj;
		delete jData;
		return true;
	}
	
	delete jData;
	
	return false;
}

bool IsBotAWPer(int client)
{
    return g_bIsAWPer[client];
}

bool IsHumanAWPer(int client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client) || IsFakeClient(client)) return false;
    int team = GetClientTeam(client);
    if (team != CS_TEAM_T && team != CS_TEAM_CT) return false;

    return (g_hCvarIsAWP != null && g_hCvarIsAWP.IntValue == 1);
}

int FindTeamAWPer(int team)
{
    int human = FindHumanAWPerOnTeam(team);
    if (human != -1)
        return human;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == team && IsBotAWPer(i))
            return i;
    }
    return -1;
}

int FindAWPerWithoutAWP(int rifler)
{
    int team = GetClientTeam(rifler);
    int awper = FindTeamAWPer(team);
    if (awper <= 0) return 0;

    if (!IsClientInGame(awper) || !IsPlayerAlive(awper))
        return 0;

    int primary = GetPlayerWeaponSlot(awper, CS_SLOT_PRIMARY);
    if (!IsValidEntity(primary))
        return awper;

    if (GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex") != 9)
        return awper;

    return 0;
}


int FindHumanAWPerOnTeam(int team)
{
    if (g_hCvarIsAWP == null || g_hCvarIsAWP.IntValue != 1)
        return -1;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
            return i; // In LIGA there is effectively "the user".
    }
    return -1;
}


bool IsClientAWPer(int client)
{
    if (!IsClientInGame(client)) return false;
    int team = GetClientTeam(client);
    if (team != CS_TEAM_T && team != CS_TEAM_CT) return false;

    int awper = FindTeamAWPer(team);
    return (awper == client);
}

public void LoadSDK()
{
	GameData hGameConfig = new GameData("botstuff.games");
	if (hGameConfig == null)
		SetFailState("Failed to find botstuff.games game config.");
	
	if(!(g_pTheBots = hGameConfig.GetAddress("TheBots")))
		SetFailState("Failed to get TheBots address.");
	
	if ((g_iBotTargetSpotOffset = hGameConfig.GetOffset("CCSBot::m_targetSpot")) == -1)
		SetFailState("Failed to get CCSBot::m_targetSpot offset.");
	
	if ((g_iBotNearbyEnemiesOffset = hGameConfig.GetOffset("CCSBot::m_nearbyEnemyCount")) == -1)
		SetFailState("Failed to get CCSBot::m_nearbyEnemyCount offset.");
	
	if ((g_iFireWeaponOffset = hGameConfig.GetOffset("CCSBot::m_fireWeaponTimestamp")) == -1)
		SetFailState("Failed to get CCSBot::m_fireWeaponTimestamp offset.");
	
	if ((g_iEnemyVisibleOffset = hGameConfig.GetOffset("CCSBot::m_isEnemyVisible")) == -1)
		SetFailState("Failed to get CCSBot::m_isEnemyVisible offset.");
	
	if ((g_iBotProfileOffset = hGameConfig.GetOffset("CCSBot::m_pLocalProfile")) == -1)
		SetFailState("Failed to get CCSBot::m_pLocalProfile offset.");
	
	if ((g_iBotSafeTimeOffset = hGameConfig.GetOffset("CCSBot::m_safeTime")) == -1)
		SetFailState("Failed to get CCSBot::m_safeTime offset.");
	
	if ((g_iBotEnemyOffset = hGameConfig.GetOffset("CCSBot::m_enemy")) == -1)
		SetFailState("Failed to get CCSBot::m_enemy offset.");
	
	if ((g_iBotLookAtSpotStateOffset = hGameConfig.GetOffset("CCSBot::m_lookAtSpotState")) == -1)
		SetFailState("Failed to get CCSBot::m_lookAtSpotState offset.");
	
	if ((g_iBotMoraleOffset = hGameConfig.GetOffset("CCSBot::m_morale")) == -1)
		SetFailState("Failed to get CCSBot::m_morale offset.");
	
	if ((g_iBotTaskOffset = hGameConfig.GetOffset("CCSBot::m_task")) == -1)
		SetFailState("Failed to get CCSBot::m_task offset.");
	
	if ((g_iBotDispositionOffset = hGameConfig.GetOffset("CCSBot::m_disposition")) == -1)
		SetFailState("Failed to get CCSBot::m_disposition offset.");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CCSBot::MoveTo");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer); // Move Position As Vector, Pointer
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // Move Type As Integer
	if ((g_hBotMoveTo = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CCSBot::MoveTo signature!");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CBaseAnimating::LookupBone");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if ((g_hLookupBone = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CBaseAnimating::LookupBone signature!");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CBaseAnimating::GetBonePosition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	if ((g_hGetBonePosition = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CBaseAnimating::GetBonePosition signature!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CCSBot::IsVisible");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if ((g_hBotIsVisible = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CCSBot::IsVisible signature!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CCSBot::IsAtHidingSpot");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if ((g_hBotIsHiding = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CCSBot::IsAtHidingSpot signature!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CCSBot::EquipBestWeapon");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	if ((g_hBotEquipBestWeapon = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CCSBot::EquipBestWeapon signature!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CCSBot::SetLookAt");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	if ((g_hBotSetLookAt = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CCSBot::SetLookAt signature!");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "SetCrosshairCode");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	if ((g_hSetCrosshairCode = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for SetCrosshairCode signature!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Virtual, "Weapon_Switch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	if ((g_hSwitchWeaponCall = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for Weapon_Switch offset!");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CBotManager::IsLineBlockedBySmoke");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if ((g_hIsLineBlockedBySmoke = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CBotManager::IsLineBlockedBySmoke offset!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CCSBot::BendLineOfSight");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if ((g_hBotBendLineOfSight = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CCSBot::BendLineOfSight signature!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CCSBot::ThrowGrenade");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	if ((g_hBotThrowGrenade = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CCSBot::ThrowGrenade signature!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "CCSPlayer::AddAccount");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	if ((g_hAddMoney = EndPrepSDKCall()) == null)SetFailState("Failed to create SDKCall for CCSPlayer::AddAccount signature!");
	
	delete hGameConfig;
}

public void LoadDetours()
{
	GameData hGameData = new GameData("botstuff.games");   
	if (hGameData == null)
	{
		SetFailState("Failed to load botstuff gamedata.");
		return;
	}
	
	//CCSBot::SetLookAt Detour
	DynamicDetour hBotSetLookAtDetour = DynamicDetour.FromConf(hGameData, "CCSBot::SetLookAt");
	if(!hBotSetLookAtDetour.Enable(Hook_Pre, CCSBot_SetLookAt))
		SetFailState("Failed to setup detour for CCSBot::SetLookAt");
	
	//CCSBot::PickNewAimSpot Detour
	DynamicDetour hBotPickNewAimSpotDetour = DynamicDetour.FromConf(hGameData, "CCSBot::PickNewAimSpot");
	if(!hBotPickNewAimSpotDetour.Enable(Hook_Post, CCSBot_PickNewAimSpot))
		SetFailState("Failed to setup detour for CCSBot::PickNewAimSpot");
	
	//BotCOS Detour
	DynamicDetour hBotCOSDetour = DynamicDetour.FromConf(hGameData, "BotCOS");
	if(!hBotCOSDetour.Enable(Hook_Pre, BotCOS))
		SetFailState("Failed to setup detour for BotCOS");
	
	//BotSIN Detour
	DynamicDetour hBotSINDetour = DynamicDetour.FromConf(hGameData, "BotSIN");
	if(!hBotSINDetour.Enable(Hook_Pre, BotSIN))
		SetFailState("Failed to setup detour for BotSIN");
	
	//CCSBot::GetPartPosition Detour
	DynamicDetour hBotGetPartPosDetour = DynamicDetour.FromConf(hGameData, "CCSBot::GetPartPosition");
	if(!hBotGetPartPosDetour.Enable(Hook_Pre, CCSBot_GetPartPosition))
		SetFailState("Failed to setup detour for CCSBot::GetPartPosition");
	
	delete hGameData;
}

public int LookupBone(int iEntity, const char[] szName)
{
	return SDKCall(g_hLookupBone, iEntity, szName);
}

public void GetBonePosition(int iEntity, int iBone, float fOrigin[3], float fAngles[3])
{
	SDKCall(g_hGetBonePosition, iEntity, iBone, fOrigin, fAngles);
}

public void BotMoveTo(int client, float fOrigin[3], RouteType routeType)
{
	SDKCall(g_hBotMoveTo, client, fOrigin, routeType);
}

bool BotIsVisible(int client, float fPos[3], bool bTestFOV, int iIgnore = -1)
{
	return SDKCall(g_hBotIsVisible, client, fPos, bTestFOV, iIgnore);
}

public bool BotIsHiding(int client)
{
	return SDKCall(g_hBotIsHiding, client);
}

public void BotEquipBestWeapon(int client, bool bMustEquip)
{
	SDKCall(g_hBotEquipBestWeapon, client, bMustEquip);
}

public void BotSetLookAt(int client, const char[] szDesc, const float fPos[3], PriorityType pri, float fDuration, bool bClearIfClose, float fAngleTolerance, bool bAttack)
{
	SDKCall(g_hBotSetLookAt, client, szDesc, fPos, pri, fDuration, bClearIfClose, fAngleTolerance, bAttack);
}

public bool BotBendLineOfSight(int client, const float fEye[3], const float fTarget[3], float fBend[3], float fAngleLimit)
{
	return SDKCall(g_hBotBendLineOfSight, client, fEye, fTarget, fBend, fAngleLimit);
}

public void BotThrowGrenade(int client, const float fTarget[3])
{
	SDKCall(g_hBotThrowGrenade, client, fTarget);
}

public int BotGetEnemy(int client)
{
	return GetEntDataEnt2(client, g_iBotEnemyOffset);
}

public void SetCrosshairCode(Address pCCSPlayerResource, int client, const char[] szCode)
{
	SDKCall(g_hSetCrosshairCode, pCCSPlayerResource, client, szCode);
}

public void AddMoney(int client, int iAmount, bool bTrackChange, bool bItemBought, const char[] szItemName)
{
	SDKCall(g_hAddMoney, client, iAmount, bTrackChange, bItemBought, szItemName);
}

bool IsWarmupPeriod()
{
    return (GameRules_GetProp("m_bWarmupPeriod") != 0);
}

public int GetNearestGrenade(int client)
{
    if (IsWarmupPeriod()) return -1;
    if (g_bBombPlanted) return -1;
    if (AreAllEnemiesDead(client)) return -1;
    if (g_bBombExploded) return -1;
    if (g_fRoundTimeRemaining < 0.0) return -1;

    int team = GetClientTeam(client);
    bool bLastOnTeam =
        (team == CS_TEAM_T  && IsLastTAlive(client)) ||
        (team == CS_TEAM_CT && IsLastCTAlive(client));

    int enemyTeam = (team == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;

    if (bLastOnTeam && GetAliveTeamCount(enemyTeam) < 4)
        return -1;

    int iNearestEntity = -1;
    float fVecOrigin[3];

    GetClientAbsOrigin(client, fVecOrigin);

    float fDistance, fNearestDistance = -1.0;

    for (int i = 0; i < g_iPostPlantNadesStartIndex; i++)
    {
        // Check if grenade is on cooldown
        if ((g_fCurrentTime - g_fNadeTimestamp[i]) < 25.0)
            continue;
        
        // Check if another bot has claimed this grenade recently
        if ((g_fCurrentTime - g_fNadeClaimTime[i]) < 10.0)
            continue;

        if (!IsValidEntity(eItems_FindWeaponByDefIndex(client, g_iNadeDefIndex[i])))
            continue;

        if (GetClientTeam(client) != g_iNadeTeam[i])
            continue;

        fDistance = GetVectorDistance(fVecOrigin, g_fNadePos[i]);

        if (fDistance > 250.0)
            continue;

        if (fDistance < fNearestDistance || fNearestDistance == -1.0)
        {
            iNearestEntity = i;
            fNearestDistance = fDistance;
        }
    }

    // If we found a valid grenade, claim it
    if (iNearestEntity != -1)
    {
        g_fNadeClaimTime[iNearestEntity] = g_fCurrentTime;
    }

    return iNearestEntity;
}

public int GetNearestPostPlantGrenade(int client)
{
    if (IsWarmupPeriod()) return -1;
    if (!g_bBombPlanted) return -1;
    if (AreAllEnemiesDead(client)) return -1;
    if (!IsBotNearPlantedBomb(client)) return -1; // Check if bot is near bomb

    int iNearestEntity = -1;
    float fVecOrigin[3];

    GetClientAbsOrigin(client, fVecOrigin);
    float fDistance, fNearestDistance = -1.0;

    int iPlantedC4 = FindEntityByClassname(-1, "planted_c4");
    if (!IsValidEntity(iPlantedC4))
        return -1;

    if (g_fTimeLeft < 19.0)
    {
        // Not enough time left to justify throwing
        return -1;
    }
    
    // Only loop through post-plant grenades
    for (int i = g_iPostPlantNadesStartIndex; i < g_iMaxNades; i++)
    {
        if ((g_fCurrentTime - g_fNadeTimestamp[i]) < 25.0)
            continue;
            
        if ((g_fCurrentTime - g_fNadeClaimTime[i]) < 10.0)
            continue;
            
        if (!IsValidEntity(eItems_FindWeaponByDefIndex(client, g_iNadeDefIndex[i])))
            continue;
            
        if (GetClientTeam(client) != g_iNadeTeam[i])
            continue;
            
        fDistance = GetVectorDistance(fVecOrigin, g_fNadePos[i]);
        
        if (fDistance > 250.0)
            continue;
            
        if (fDistance < fNearestDistance || fNearestDistance == -1.0)
        {
            iNearestEntity = i;
            fNearestDistance = fDistance;
        }
    }
    
    // If we found a valid grenade, claim it
    if (iNearestEntity != -1)
    {
        g_fNadeClaimTime[iNearestEntity] = g_fCurrentTime;
    }
    
    return iNearestEntity;
}

int GetNearestAngle(int client)
{
    if (g_bBombPlanted) return -1;
    if (g_iMaxAngles == 0) return -1;

    int nearestAngle = -1;
    float fVecOrigin[3];
    float fDistance, fNearestDistance = -1.0;

    GetClientAbsOrigin(client, fVecOrigin);

    for (int i = 0; i < g_iMaxAngles; i++)
    {
        if (g_bAngleClaimed[i]) continue;

        if (g_iAngleTeam[i] != CS_TEAM_CT) continue;
        if (g_iAngleDefIndex[i] != 9) continue;

        if ((g_fCurrentTime - g_fAngleTimestamp[i]) < 10.0) continue;

        fDistance = GetVectorDistance(fVecOrigin, g_fAnglePos[i]);

        if (fDistance < fNearestDistance || fNearestDistance == -1.0)
        {
            nearestAngle = i;
            fNearestDistance = fDistance;
        }
    }

    if (nearestAngle != -1)
    {
        g_fAngleTimestamp[nearestAngle] = g_fCurrentTime;
    }

    return nearestAngle;
}

int GetRandomAngle()
{
    if (g_bBombPlanted) return -1;
    if (g_iMaxAngles == 0) return -1;
    
    int validAngles[128];
    int validAngleCount = 0;
    
    for (int i = 0; i < g_iMaxAngles; i++)
    {
        if (g_bAngleClaimed[i]) continue;
        
        if (g_iAngleTeam[i] != CS_TEAM_CT) continue;
        if (g_iAngleDefIndex[i] != 9) continue;
        
        validAngles[validAngleCount] = i;
        validAngleCount++;
    }
    
    if (validAngleCount == 0) return -1;
    
    int randomIndex = GetRandomInt(0, validAngleCount - 1);
    return validAngles[randomIndex];
}

int GetRandomPeekForTeam(int team)
{
    int validPeeks[MAX_PEEKS];
    int count = 0;

    for (int i = 0; i < g_iMaxPeeks; i++)
    {
        if (g_iPeekTeam[i] == team && g_iPeekDefIndex[i] == 9)
        {
            validPeeks[count++] = i;
        }
    }

    if (count == 0)
        return -1;

    return validPeeks[GetRandomInt(0, count - 1)];
}

stock int GetNearestEntity(int client, char[] szClassname)
{
	int iNearestEntity = -1;
	float fClientOrigin[3], fEntityOrigin[3];
	
	GetClientAbsOrigin(client, fClientOrigin);
	
	//Get the distance between the first entity and client
	float fDistance, fNearestDistance = -1.0;
	
	//Find all the entity and compare the distances
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, szClassname)) != -1)
	{
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin); // Line 2610
		fDistance = GetVectorDistance(fClientOrigin, fEntityOrigin);
		
		if (fDistance < fNearestDistance || fNearestDistance == -1.0)
		{
			iNearestEntity = iEntity;
			fNearestDistance = fDistance;
		}
	}
	
	return iNearestEntity;
}

int FindNearestDroppedSpecificGun(int client, const char[] className)
{
    float fClientOrigin[3];
    GetClientAbsOrigin(client, fClientOrigin);

    int nearest = -1;
    float bestDist = 99999.0;

    int ent = -1;
    while ((ent = FindEntityByClassname(ent, className)) != -1)
    {
        if (!IsValidEntity(ent))
            continue;

        float fPos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fPos);

        float dist = GetVectorDistance(fClientOrigin, fPos);
        if (dist < bestDist && dist < 600.0) // limit search radius
        {
            bestDist = dist;
            nearest = ent;
        }
    }

    return nearest;
}

bool IsInArray(const char[] szWeapon, const char[][] szList, int iSize)
{
    for (int i = 0; i < iSize; i++)
    {
        if (strcmp(szWeapon, szList[i]) == 0)
            return true;
    }
    return false;
}

stock void CSGO_SetMoney(int client, int iAmount)
{
	if (iAmount < 0)
		iAmount = 0;
	
	int iMax = FindConVar("mp_maxmoney").IntValue;
	
	if (iAmount > iMax)
		iAmount = iMax;
	
	SetEntProp(client, Prop_Send, "m_iAccount", iAmount);
}

stock int CSGO_ReplaceWeapon(int client, int iSlot, const char[] szClass)
{
	int iWeapon = GetPlayerWeaponSlot(client, iSlot);
	
	if (IsValidEntity(iWeapon))
	{
		if (GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity") != client)
			SetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity", client);
		
		CS_DropWeapon(client, iWeapon, false, true);
		AcceptEntityInput(iWeapon, "Kill");
	}
	
	iWeapon = GivePlayerItem(client, szClass);
	
	if (IsValidEntity(iWeapon))
		EquipPlayerWeapon(client, iWeapon);
	
	return iWeapon;
}

bool IsPlayerReloading(int client)
{	
	if(!IsValidEntity(g_iActiveWeapon[client]))
		return false;
	
	//Out of ammo?
	if(GetEntProp(g_iActiveWeapon[client], Prop_Data, "m_iClip1") == 0)
		return true;
	
	//Reloading?
	if(GetEntProp(g_iActiveWeapon[client], Prop_Data, "m_bInReload"))
		return true;
	
	//Ready to fire?
	if(GetEntPropFloat(g_iActiveWeapon[client], Prop_Send, "m_flNextPrimaryAttack") <= GetGameTime())
		return false;
	
	return true;
}

bool ShouldBuyDefuseKit(int client)
{
    int iOvertimePlaying = GameRules_GetProp("m_nOvertimePlaying");
    if (iOvertimePlaying > 0)
        return true;

    if (GetClientTeam(client) != CS_TEAM_CT)
        return false;

    bool bHasDefuser = !!GetEntProp(client, Prop_Send, "m_bHasDefuser");
    if (bHasDefuser)
        return false;

    int defuserCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i))
            continue;

        if (GetClientTeam(i) != CS_TEAM_CT)
            continue;

        if (!!GetEntProp(i, Prop_Send, "m_bHasDefuser"))
            defuserCount++;
    }

    int account = GetEntProp(client, Prop_Send, "m_iAccount");

    if (defuserCount < 2)
        return (account >= 400);

    return (account >= 2500);
}

public void BeginQuickSwitch(int client)
{
	client = GetClientOfUserId(client);
	
	if(client != 0 && IsClientInGame(client))
	{
		SDKCall(g_hSwitchWeaponCall, client, GetPlayerWeaponSlot(client, CS_SLOT_KNIFE), 0);
		RequestFrame(FinishQuickSwitch, GetClientUserId(client));
	}
}

public void FinishQuickSwitch(int client)
{
	client = GetClientOfUserId(client);
	
	if(client != 0 && IsClientInGame(client))
		SDKCall(g_hSwitchWeaponCall, client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY), 0);
}

public Action Timer_EnableSwitch(Handle hTimer, any client)
{
	client = GetClientOfUserId(client);
	
	if(client != 0 && IsClientInGame(client))
		g_bDontSwitch[client] = false;	
	
	return Plugin_Stop;
}

public Action Timer_ResetBombSites(Handle timer, any client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
    {
        return Plugin_Stop;
    }

    EnableBombSites();
    return Plugin_Stop;
}

public void SwitchToPrimaryWeapon(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
    {
        return;
    }

    SDKCall(g_hSwitchWeaponCall, client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY), 0);
}

void SwitchToSecondaryWeapon(int client)
{
    int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
    if (weapon != -1 && IsValidEntity(weapon))
    {
        SDKCall(g_hSwitchWeaponCall, client, weapon, 0);
    }
}

public void SwitchToKnife(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
    {
        return;
    }

    int weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
    if (weapon != -1 && IsValidEntity(weapon))
    {
        SDKCall(g_hSwitchWeaponCall, client, weapon, 0);
    }
}

public void DisableBombSites()
{
    for (int i = 0; i < g_NumBombsites; i++)
    {
        AcceptEntityInput(g_BombsiteEntities[i], "Disable");
    }
    
    g_fBombsiteDisableTime = GetGameTime();
}

public void EnableBombSites()
{
    for (int i = 0; i < g_NumBombsites; i++)
    {
        AcceptEntityInput(g_BombsiteEntities[i], "Enable");
    }
    
    g_fBombsiteDisableTime = 0.0;
}


void BotLookAt(int client, float fTarget[3])
{
    float fEyes[3];
    GetClientEyePosition(client, fEyes);

    float vec[3];
    MakeVectorFromPoints(fEyes, fTarget, vec);
    NormalizeVector(vec, vec);

    float angles[3];
    GetVectorAngles(vec, angles);

    TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
}

public Action ResetAngleBlock(Handle timer, int client)
{
    if (IsClientInGame(client))
    {
        g_bAngleBlock[client] = false;
        PrintToServer("[ANLGLES] Angle reset due to death or timer.", client);
    }
    return Plugin_Stop;
}

public Action StopPeek_Callback(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client))
    {
        g_bDoingPeek[client] = false;
        g_iCurrentPeekNum[client] = -1;
    }
    return Plugin_Stop;
}

public Action Timer_DontForceThrow(Handle hTimer, any client)
{
	client = GetClientOfUserId(client);
	
	if(client != 0 && IsClientInGame(client))
	{
		g_bThrowGrenade[client] = false;
		BotEquipBestWeapon(client, true);
	}
	
	return Plugin_Stop;
}

public void DelayThrow(any client)
{
	client = GetClientOfUserId(client);
	
	if(client != 0 && IsClientInGame(client))
	{
		g_bThrowGrenade[client] = true;
		CreateTimer(3.0, Timer_DontForceThrow, GetClientUserId(client));
	}
}

public void SelectBestTargetPos(int client, float fTargetPos[3])
{
	if(IsValidClient(g_iTarget[client]) && IsPlayerAlive(g_iTarget[client]))
	{
		int iBone = LookupBone(g_iTarget[client], "head_0");
		int iSpineBone = LookupBone(g_iTarget[client], "spine_3");
		if (iBone < 0 || iSpineBone < 0)
			return;
		
		bool bShootSpine;
		float fHead[3], fBody[3], fBad[3];
		GetBonePosition(g_iTarget[client], iBone, fHead, fBad);
		GetBonePosition(g_iTarget[client], iSpineBone, fBody, fBad);
		
		fHead[2] += 4.0;
		
		if (BotIsVisible(client, fHead, false, -1))
		{
			if (BotIsVisible(client, fBody, false, -1))
			{
				if (!IsValidEntity(g_iActiveWeapon[client])) return;
				
				int iDefIndex = GetEntProp(g_iActiveWeapon[client], Prop_Send, "m_iItemDefinitionIndex");
				
				switch(iDefIndex)
				{
					case 7, 8, 10, 13, 14, 16, 17, 19, 23, 24, 25, 26, 27, 28, 29, 33, 34, 35, 39, 60:
					{
						float fTargetDistance = GetVectorDistance(g_fBotOrigin[client], fHead);
						if (IsItMyChance(70.0) && fTargetDistance < 2000.0)
							bShootSpine = true;
					}
					case 9, 11, 38:
					{
						bShootSpine = true;
					}
				}
			}
		}
		else
		{
			//Head wasn't visible, check other bones.
			for (int b = 0; b <= sizeof(g_szBoneNames) - 1; b++)
			{
				iBone = LookupBone(g_iTarget[client], g_szBoneNames[b]);
				if (iBone < 0)
					return;
				
				GetBonePosition(g_iTarget[client], iBone, fHead, fBad);
				
				if (BotIsVisible(client, fHead, false, -1))
					break;
				else
					fHead[2] = 0.0;
			}
		}
		
		if(bShootSpine)
			fTargetPos = fBody;
		else
			fTargetPos = fHead;
	}
}

public void SelectIntermediateTargetPos(int client, float fTargetPos[3])
{
	if (IsValidClient(g_iTarget[client]) && IsPlayerAlive(g_iTarget[client]))
	{
		int iBoneHead = LookupBone(g_iTarget[client], "head_0");
		int iBoneSpine = LookupBone(g_iTarget[client], "spine_3");
		if (iBoneHead < 0 || iBoneSpine < 0)
			return;

		float fHead[3], fBody[3], fBad[3];
		GetBonePosition(g_iTarget[client], iBoneHead, fHead, fBad);
		GetBonePosition(g_iTarget[client], iBoneSpine, fBody, fBad);

		fHead[2] += GetRandomFloat(1.0, 3.0);

		bool bVisibleHead = BotIsVisible(client, fHead, false, -1);
		bool bVisibleBody = BotIsVisible(client, fBody, false, -1);

		bool bShootSpine = false;

		if (bVisibleHead || bVisibleBody)
		{
			// Headshots less frequent than ProBots (15–25% chance)
			if (bVisibleHead && IsItMyChance(25.0))
			{
				fTargetPos = fHead;
			}
			else
			{
				bShootSpine = true;
			}
		}
		else
		{
			// Try other bones if both invisible
			for (int b = 0; b < sizeof(g_szBoneNames); b++)
			{
				int iBone = LookupBone(g_iTarget[client], g_szBoneNames[b]);
				if (iBone < 0)
					continue;

				float fAlt[3];
				GetBonePosition(g_iTarget[client], iBone, fAlt, fBad);

				if (BotIsVisible(client, fAlt, false, -1))
				{
					fTargetPos = fAlt;
					break;
				}
			}
		}

		if (bShootSpine)
		{
			fTargetPos = fBody;
		}

		// Apply small random offset to simulate less accurate aim
		float offset[3];
		offset[0] = GetRandomFloat(-2.5, 2.5);
		offset[1] = GetRandomFloat(-2.5, 2.5);
		offset[2] = GetRandomFloat(-1.0, 2.0);
		AddVectors(fTargetPos, offset, fTargetPos);
	}
}

void BuyRandomPistolT(int client)
{
    if (IsItMyChance(50.0))
        FakeClientCommand(client, "buy tec9");
    else
        FakeClientCommand(client, "buy deagle");
}

void BuyRandomPistolCT(int client)
{
    int random = Math_GetRandomInt(1, 3);
    switch (random)
    {
        case 1: FakeClientCommand(client, "buy p250");
        case 2: FakeClientCommand(client, "buy fiveseven");
        case 3: FakeClientCommand(client, "buy deagle");
    }
}

void ForceBuyGrenades(int client)
{
    switch (Math_GetRandomInt(1, 3))
    {
        case 1:
        {
            FakeClientCommand(client, "buy smokegrenade");
            FakeClientCommand(client, "buy flashbang");
            FakeClientCommand(client, "buy flashbang");
            FakeClientCommand(client, "buy hegrenade");
        }
        case 2:
        {
            FakeClientCommand(client, "buy flashbang");
            FakeClientCommand(client, "buy flashbang");
            FakeClientCommand(client, "buy smokegrenade");
            FakeClientCommand(client, "buy molotov");
        }
        case 3:
        {
            FakeClientCommand(client, "buy smokegrenade");
            FakeClientCommand(client, "buy flashbang");
            FakeClientCommand(client, "buy hegrenade");
            FakeClientCommand(client, "buy molotov");
        }
    }
}

void ForceBuyGrenadesDelayed(int client)
{
    if (!IsValidClient(client) || !IsFakeClient(client) || !IsPlayerAlive(client))
        return;

    int money = GetEntProp(client, Prop_Send, "m_iAccount");
    if (money < 200)
        return;

    bool isCT = (GetClientTeam(client) == CS_TEAM_CT);

    // grenade costs
    const int costFlash = 200;
    const int costSmoke = 300;
    const int costHE    = 300;
    int costFire        = isCT ? 600 : 400;
    char fireGrenade[32];
    if (isCT)
        strcopy(fireGrenade, sizeof(fireGrenade), "weapon_incgrenade");
    else
        strcopy(fireGrenade, sizeof(fireGrenade), "weapon_molotov");

    if (money >= (costFlash + costSmoke + costHE + costFire))
    {
        GivePlayerItem(client, "weapon_flashbang");
        GivePlayerItem(client, "weapon_smokegrenade");
        GivePlayerItem(client, "weapon_hegrenade");
        GivePlayerItem(client, fireGrenade);
        AddMoney(client, -(costFlash + costSmoke + costHE + costFire), true, true, "grenade_full");
        PrintToServer("[AWP DEBUG] %N bought full grenade set (%s).", client, isCT ? "CT" : "T");
        return;
    }
    if (money >= (costFlash + costSmoke + costHE))
    {
        GivePlayerItem(client, "weapon_flashbang");
        GivePlayerItem(client, "weapon_smokegrenade");
        GivePlayerItem(client, "weapon_hegrenade");
        AddMoney(client, -(costFlash + costSmoke + costHE), true, true, "grenade_triple");
        PrintToServer("[AWP DEBUG] %N bought 3-grenade set.", client);
        return;
    }
    if (money >= (costFlash + costSmoke))
    {
        GivePlayerItem(client, "weapon_flashbang");
        GivePlayerItem(client, "weapon_smokegrenade");
        AddMoney(client, -(costFlash + costSmoke), true, true, "grenade_duo");
        PrintToServer("[AWP DEBUG] %N bought 2-grenade set.", client);
        return;
    }
    if (money >= costFlash)
    {
        GivePlayerItem(client, "weapon_flashbang");
        AddMoney(client, -costFlash, true, true, "grenade_flash");
        PrintToServer("[AWP DEBUG] %N bought flash only.", client);
        return;
    }

    PrintToServer("[AWP DEBUG] %N could not afford any grenades.", client);
}

Action TryReplaceBoughtWeapon(int client, const char[] szWeapon, int iAccount)
{
    int iTeam = GetClientTeam(client);

    if (strcmp(szWeapon, "ak47") == 0 && iTeam == CS_TEAM_T)
	{
	    int galilPrice = CS_GetWeaponPrice(client, CSWeapon_GALILAR);
	    int mac10Price = CS_GetWeaponPrice(client, CSWeapon_MAC10);
	    int ssg08Price = CS_GetWeaponPrice(client, CSWeapon_SSG08);
	    int vesthelmPrice = COST_VESTHELM;

	    if (iAccount < 3700)
	    {
	    	if (g_bIsAWPer[client] && iAccount >= ssg08Price + vesthelmPrice && IsItMyChance(10.0))
	    	{
	    		AddMoney(client, -ssg08Price, true, true, "weapon_ssg08");
	    		CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_ssg08");
	    		FakeClientCommand(client, "buy vesthelm");
	    		return Plugin_Changed;
	    	}
	        else if (iAccount >= galilPrice + vesthelmPrice)
	        {
	            AddMoney(client, -galilPrice, true, true, "weapon_galilar");
	            CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_galilar");
	            FakeClientCommand(client, "buy vesthelm");
	            return Plugin_Changed;
	        }
	        else if (iAccount >= mac10Price + vesthelmPrice)
	        {
		            AddMoney(client, -mac10Price, true, true, "weapon_mac10");
		            CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_mac10");
		            FakeClientCommand(client, "buy vesthelm");
		            return Plugin_Changed;
	        }
	    }
	}

    if (strcmp(szWeapon, "m4a1") == 0 && iTeam == CS_TEAM_CT)
    {
        bool useSilencer = g_bUseM4A1S[client];

        if (useSilencer)
        {
            if (iAccount >= 2900 && iAccount <= 3000)
            {
            	if (g_bIsAWPer[client] && IsItMyChance(25.0))
            	{
            		int ssg08Price = CS_GetWeaponPrice(client, CSWeapon_SSG08);
            		int vestPrice = COST_VEST;
            		if (iAccount >= ssg08Price + vestPrice)
            		{
            			AddMoney(client, -ssg08Price, true, true, "weapon_ssg08");
            			CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_ssg08");
            			FakeClientCommand(client, "buy vest");
            			return Plugin_Changed;
            		}
            	}
                else if (IsItMyChance(50.0))
                {
                    int mp9Price = CS_GetWeaponPrice(client, CSWeapon_MP9);
                    int vesthelmPrice = COST_VESTHELM;
                    if (iAccount >= mp9Price + vesthelmPrice)
                    {
                        AddMoney(client, -mp9Price, true, true, "weapon_mp9");
                        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_mp9");
                        FakeClientCommand(client, "buy vesthelm");
                        return Plugin_Changed;
                    }
                }
                else
                {
                    int famasPrice = CS_GetWeaponPrice(client, CSWeapon_FAMAS);
                    int vestPrice = COST_VEST;
                    if (iAccount >= famasPrice + vestPrice)
                    {
                        AddMoney(client, -famasPrice, true, true, "weapon_famas");
                        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_famas");
                        FakeClientCommand(client, "buy vest");
                        return Plugin_Changed;
                    }
                }
            }
            else if (iAccount >= 3050 && iAccount <= 3500)
            {
                if (IsItMyChance(20.0))
                {
                    int mp9Price = CS_GetWeaponPrice(client, CSWeapon_MP9);
                    int vesthelmPrice = COST_VESTHELM;
                    if (iAccount >= mp9Price + vesthelmPrice)
                    {
                        AddMoney(client, -mp9Price, true, true, "weapon_mp9");
                        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_mp9");
                        FakeClientCommand(client, "buy vesthelm");
                        return Plugin_Changed;
                    }
                }
                else
                {
                    int famasPrice = CS_GetWeaponPrice(client, CSWeapon_FAMAS);
                    int vesthelmPrice = COST_VESTHELM;
                    if (iAccount >= famasPrice + vesthelmPrice)
                    {
                        AddMoney(client, -famasPrice, true, true, "weapon_famas");
                        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_famas");
                        FakeClientCommand(client, "buy vesthelm");
                        return Plugin_Changed;
                    }
                }
            }
        }
        else
        {
            if (iAccount >= 3100 && iAccount <= 3300)
            {
                if (IsItMyChance(35.0))
                {
                    int mp9Price = CS_GetWeaponPrice(client, CSWeapon_MP9);
                    int vesthelmPrice = COST_VESTHELM;
                    if (iAccount >= mp9Price + vesthelmPrice)
                    {
                        AddMoney(client, -mp9Price, true, true, "weapon_mp9");
                        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_mp9");
                        FakeClientCommand(client, "buy vesthelm");
                        return Plugin_Changed;
                    }
                }
                else
                {
                    int famasPrice = CS_GetWeaponPrice(client, CSWeapon_FAMAS);
                    int vestPrice = COST_VEST;
                    if (iAccount >= famasPrice + vestPrice)
                    {
                        AddMoney(client, -famasPrice, true, true, "weapon_famas");
                        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_famas");
                        FakeClientCommand(client, "buy vest");
                        return Plugin_Changed;
                    }
                }
            }
            else if (iAccount >= 3350 && iAccount <= 3700)
            {
                if (IsItMyChance(20.0))
                {
                    int mp9Price = CS_GetWeaponPrice(client, CSWeapon_MP9);
                    int vesthelmPrice = COST_VESTHELM;
                    if (iAccount >= mp9Price + vesthelmPrice)
                    {
                        AddMoney(client, -mp9Price, true, true, "weapon_mp9");
                        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_mp9");
                        FakeClientCommand(client, "buy vesthelm");
                        return Plugin_Changed;
                    }
                }
                else
                {
                    int famasPrice = CS_GetWeaponPrice(client, CSWeapon_FAMAS);
                    int vesthelmPrice = COST_VESTHELM;
                    if (iAccount >= famasPrice + vesthelmPrice)
                    {
                        AddMoney(client, -famasPrice, true, true, "weapon_famas");
                        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_famas");
                        FakeClientCommand(client, "buy vesthelm");
                        return Plugin_Changed;
                    }
                }
            }
        }

        if (g_bUseM4A1S[client])
        {
            int iPrice = CS_GetWeaponPrice(client, CSWeapon_M4A1_SILENCER);
            if (iAccount >= iPrice)
            {
                AddMoney(client, -iPrice, true, true, "weapon_m4a1_silencer");
                CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_m4a1_silencer");
                return Plugin_Changed;
            }
        }

        if (IsItMyChance(5.0))
        {
            int iPrice = CS_GetWeaponPrice(client, CSWeapon_AUG);
            if (iAccount >= iPrice)
            {
                AddMoney(client, -iPrice, true, true, "weapon_aug");
                CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_aug");
                return Plugin_Changed;
            }
        }
    }

    if (strcmp(szWeapon, "galilar") == 0)
	{
	    int galilPrice = CS_GetWeaponPrice(client, CSWeapon_GALILAR);
	    int mac10Price = CS_GetWeaponPrice(client, CSWeapon_MAC10);
	    int vesthelmPrice = COST_VESTHELM;

	    if (iAccount >= galilPrice + vesthelmPrice)
	    {
	        AddMoney(client, -galilPrice, true, true, "weapon_galilar");
	        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_galilar");
	        FakeClientCommand(client, "buy vesthelm");
	        return Plugin_Changed;
	    }
	    else if (iAccount >= mac10Price + vesthelmPrice)
	    {
	        AddMoney(client, -mac10Price, true, true, "weapon_mac10");
	        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_mac10");
	        FakeClientCommand(client, "buy vesthelm");
	        return Plugin_Changed;
	    }
	}

	if (strcmp(szWeapon, "famas") == 0)
	{
	    int famasPrice = CS_GetWeaponPrice(client, CSWeapon_FAMAS);
	    int mp9Price = CS_GetWeaponPrice(client, CSWeapon_MP9);
	    int vestPrice = COST_VEST;
	    int vesthelmPrice = COST_VESTHELM;

	    if (iAccount >= famasPrice + vestPrice)
	    {
	        AddMoney(client, -famasPrice, true, true, "weapon_famas");
	        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_famas");
	        FakeClientCommand(client, "buy vest");
	        return Plugin_Changed;
	    }
	    else if (iAccount >= mp9Price + vesthelmPrice)
	    {
	        AddMoney(client, -mp9Price, true, true, "weapon_mp9");
	        CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_mp9");
	        FakeClientCommand(client, "buy vesthelm");
	        return Plugin_Changed;
	    }
	}

    if (strcmp(szWeapon, "mac10") == 0)
    {
        if (iAccount < 2050)
        {
            int vesthelmPrice = COST_VESTHELM;
            int minPistolPrice = 500;
            if (iAccount >= vesthelmPrice + minPistolPrice)
            {
                FakeClientCommand(client, "buy vesthelm");
                BuyRandomPistolT(client);
                return Plugin_Changed;
            }
        }
    }

    if (strcmp(szWeapon, "mp9") == 0)
    {
        if (iAccount < 1900)
        {
            int vestPrice = COST_VEST;
            int minPistolPrice = 300;
            if (iAccount >= vestPrice + minPistolPrice)
            {
                FakeClientCommand(client, "buy vest");
                BuyRandomPistolCT(client);
                return Plugin_Changed;
            }
        }
    }

    if (strcmp(szWeapon, "tec9") == 0 || strcmp(szWeapon, "fiveseven") == 0)
    {
        if (g_bUseCZ75[client])
        {
            int iPrice = CS_GetWeaponPrice(client, CSWeapon_CZ75A);
            if (iAccount >= iPrice)
            {
                AddMoney(client, -iPrice, true, true, "weapon_cz75a");
                CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_cz75a");
                return Plugin_Changed;
            }
        }
    }

    return Plugin_Continue;
}

bool TryUpgradeWeapon(int client)
{
    if (!IsValidClient(client) || !IsFakeClient(client) || !IsPlayerAlive(client))
        return false;
        
    int iTeam = GetClientTeam(client);
    int iAccount = GetEntProp(client, Prop_Send, "m_iAccount");
    int iPrimary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
    bool bShouldUpgrade = ShouldUpgrade(client);
    
    if (!bShouldUpgrade || !IsValidEntity(iPrimary))
        return false;
    
    char szCurrentWeapon[64] = "";
    if (IsValidEntity(iPrimary))
    {
        GetEntityClassname(iPrimary, szCurrentWeapon, sizeof(szCurrentWeapon));
    }

    if (g_bIsAWPer[client] && iAccount >= 10000 && strcmp(szCurrentWeapon, "weapon_awp") != 0)
	{
	    char szNewWeapon[64] = "weapon_awp";
	    int cost = 4750;
	    
	    CS_DropWeapon(client, iPrimary, true, false);
	    AddMoney(client, -cost, true, true, szNewWeapon);
	    CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, szNewWeapon);
	    PrintToServer("[BUY] Bot %N upgraded weapon to AWP", client);
	    return true;
	}
    
    if (iTeam == CS_TEAM_CT)
    {
        if (strcmp(szCurrentWeapon, "weapon_m4a1") != 0 && 
            strcmp(szCurrentWeapon, "weapon_m4a1_silencer") != 0 && 
            strcmp(szCurrentWeapon, "weapon_awp") != 0 && 
            strcmp(szCurrentWeapon, "weapon_ak47") != 0)
        {
            char szNewWeapon[64];
            int cost = 0;
            
            if (g_bUseM4A1S[client] && iAccount >= 2900)
            {
                strcopy(szNewWeapon, sizeof(szNewWeapon), "weapon_m4a1_silencer");
                cost = 2900;
            }
            else if (!g_bUseM4A1S[client] && iAccount >= 3100)
            {
                strcopy(szNewWeapon, sizeof(szNewWeapon), "weapon_m4a1");
                cost = 3100;
            }
            else
            {
                return false;
            }
            
            CS_DropWeapon(client, iPrimary, true, false);
            AddMoney(client, -cost, true, true, szNewWeapon);
            CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, szNewWeapon);
            PrintToServer("[BUY] BOT %N Upgraded current weapon to %s", client, szNewWeapon);
            return true;
        }
    }
    else if (iTeam == CS_TEAM_T)
    {
        if (strcmp(szCurrentWeapon, "weapon_ak47") != 0 && 
            strcmp(szCurrentWeapon, "weapon_awp") != 0)
        {
            if (iAccount >= 2700)
            {
                char szNewWeapon[64] = "weapon_ak47";
                int cost = 2700;
                
                CS_DropWeapon(client, iPrimary, true, false);
                AddMoney(client, -cost, true, true, szNewWeapon);
                CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, szNewWeapon);
                return true;
            }
        }
    }
    
    return false;
}

stock void GetViewVector(float fVecAngle[3], float fOutPut[3])
{
	fOutPut[0] = Cosine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[1] = Sine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[2] = -Sine(fVecAngle[0] / (180 / FLOAT_PI));
}

stock float AngleNormalize(float fAngle)
{
	fAngle -= RoundToFloor(fAngle / 360.0) * 360.0;
	
	if (fAngle > 180)
		fAngle -= 360;
	
	if (fAngle < -180)
		fAngle += 360;

	return fAngle;
}

stock bool IsPointVisible(float fStart[3], float fEnd[3])
{
	TR_TraceRayFilter(fStart, fEnd, MASK_VISIBLE_AND_NPCS, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuff(int iEntity, int iMask)
{
	return iEntity > MaxClients;
} 

stock bool IsLineBlockedByCloseSmoke(float fFrom[3], float fTo[3])
{
    int entity = -1;
    float smokePos[3];

    while ((entity = FindEntityByClassname(entity, "smokegrenade_projectile")) != -1)
    {
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", smokePos);

        float distance = GetVectorDistance(fFrom, smokePos);
        if (distance > MAX_SMOKE_DIST)
        {
            continue;
        }

        if (LineGoesThroughSmoke(fFrom, fTo))
        {
            PrintToServer("[ANGLES] Line of sight blocked by close smoke at distance: %.2f units", distance);
            return true;
        }
    }
    return false;
}

stock bool IsInsideSmoke(int client)
{
	float eyes[3];
	GetClientEyePosition(client, eyes);
	int entity = -1;
	float smokePos[3];
	while ((entity = FindEntityByClassname(entity, "smokegrenade_projectile")) != -1)
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", smokePos);
		if (GetVectorDistance(eyes, smokePos) < 144.0)
			return true;
	}
	return false;
}

stock bool IsNearBreakable(int client, float maxDistance = 200.0)
{
    float botPos[3];
    GetClientAbsOrigin(client, botPos);

    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "func_breakable")) != -1)
    {
        if (!IsValidEntity(entity))
            continue;

        float breakablePos[3];
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", breakablePos);

        float distance = GetVectorDistance(botPos, breakablePos);
        if (distance <= maxDistance)
        {
            return true;
        }
    }

    return false;
}

public void ProcessGrenadeThrow(int client, float fTarget[3])
{
	NavMesh_GetGroundHeight(fTarget, fTarget[2]);
	if(!GetGrenadeToss(client, fTarget))
		return;
	
	Array_Copy(fTarget, g_fNadeTarget[client], 3);
	SDKCall(g_hSwitchWeaponCall, client, GetPlayerWeaponSlot(client, CS_SLOT_GRENADE), 0);
	RequestFrame(DelayThrow, GetClientUserId(client));
}

stock bool GetGrenadeToss(int client, float fTossTarget[3])
{
	float fEyePosition[3], fTo[3];
	GetClientEyePosition(client, fEyePosition);
	SubtractVectors(fTossTarget, fEyePosition, fTo);
	float fRange = GetVectorLength(fTo);

	const float fSlope = 0.2; // 0.25f;
	float fTossHeight = fSlope * fRange;

	float fHeightInc = fTossHeight / 10.0;
	float fTarget[3];
	float fSafeSpace = fTossHeight / 2.0;

	// Build a box to sweep along the ray when looking for obstacles
	float fMins[3] = { -16.0, -16.0, 0.0 };
	float fMaxs[3] = { 16.0, 16.0, 72.0 };
	fMins[2] = 0.0;
	fMaxs[2] = fHeightInc;


	// find low and high bounds of toss window
	float fLow = 0.0;
	float fHigh = fTossHeight + fSafeSpace;
	bool bGotLow = false;
	float fLastH = 0.0;
	for(float h = 0.0; h < 3.0 * fTossHeight; h += fHeightInc)
	{
		fTarget[0] = fTossTarget[0];
		fTarget[1] = fTossTarget[1];
		fTarget[2] = fTossTarget[2] + h;

		// make sure toss line is clear
		Handle hTraceResult = TR_TraceHullFilterEx(fEyePosition, fTarget, fMins, fMins, MASK_VISIBLE_AND_NPCS | CONTENTS_GRATE, TraceEntityFilterStuff);
		
		if (TR_GetFraction(hTraceResult) == 1.0)
		{
			// line is clear
			if (!bGotLow)
			{
				fLow = h;
				bGotLow = true;
			}
		}
		else
		{
			// line is blocked
			if (bGotLow)
			{
				fHigh = fLastH;
				break;
			}
		}

		fLastH = h;
		
		delete hTraceResult;
	}

	if (bGotLow)
	{
		// throw grenade into toss window
		if (fTossHeight < fLow)
		{
			if (fLow + fSafeSpace > fHigh)
				// narrow window
				fTossHeight = (fHigh + fLow)/2.0;
			else
				fTossHeight = fLow + fSafeSpace;
		}
		else if (fTossHeight > fHigh - fSafeSpace)
		{
			if (fHigh - fSafeSpace < fLow)
				// narrow window
				fTossHeight = (fHigh + fLow)/2.0;
			else
				fTossHeight = fHigh - fSafeSpace;
		}
		
		fTossTarget[2] += fTossHeight;
		return true;
	}
	
	return false;
}

stock bool LineGoesThroughSmoke(float fFrom[3], float fTo[3])
{	
	return SDKCall(g_hIsLineBlockedBySmoke, g_pTheBots, fFrom, fTo);
} 

stock int GetAliveTeamCount(int iTeam)
{
	int iNumber = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam)
			iNumber++;
	}
	return iNumber;
}

stock bool IsSafe(int client)
{
	if(!IsFakeClient(client))
		return false;
	
	if((GetGameTime() - g_fFreezeTimeEnd) < GetEntDataFloat(client, g_iBotSafeTimeOffset))
		return true;
	
	return false;
}

stock int GetFriendsWithPrimary(int client)
{
	int iCount = 0;
	int iPrimary;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if(!IsValidClient(i)) 
			continue;	
			
		if(client == i)
			continue;

		if(GetClientTeam(i) != GetClientTeam(client))
			continue;

		iPrimary = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
		if(IsValidEntity(iPrimary))
			iCount++;
	}

	return iCount;
}

stock TaskType GetTask(int client)
{
	if(!IsFakeClient(client))
		return view_as<TaskType>(-1);
		
	return view_as<TaskType>(GetEntData(client, g_iBotTaskOffset));
}

stock DispositionType GetDisposition(int client)
{
	if(!IsFakeClient(client))
		return view_as<DispositionType>(-1);
		
	return view_as<DispositionType>(GetEntData(client, g_iBotDispositionOffset));
}

stock void SetDisposition(int client, DispositionType iDisposition)
{
	if(!IsFakeClient(client))
		return;
		
	SetEntData(client, g_iBotDispositionOffset, iDisposition);
}

stock void SetPlayerTeammateColor(int client)
{
	if(GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		if(g_iPlayerColor[client] > -1)
			return;
		
		int nAssignedColor;
		bool bColorInUse = false;
		for (int ii = 0; ii < 5; ii++ )
		{
			nAssignedColor = nAssignedColor % 5;

			bColorInUse = false;
			for ( int j = 1; j <= MaxClients; j++ )
			{
				if (IsValidClient(j) && GetClientTeam(j) == GetClientTeam(client))
				{
					if (nAssignedColor == g_iPlayerColor[j] && j != client)
					{
						bColorInUse = true;
						nAssignedColor++;
						break;
					}
				}
			}

			if (bColorInUse == false )
				break;
		}
		nAssignedColor = bColorInUse == false ? nAssignedColor : -1;
		g_iPlayerColor[client] = nAssignedColor;
	}
}

public void AutoStop(int client, float fVel[3], float fAngles[3])
{
	float fPlayerVelocity[3], fVelAngle[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fPlayerVelocity);
	GetVectorAngles(fPlayerVelocity, fVelAngle);
	float fSpeed = GetVectorLength(fPlayerVelocity);
	
	if(fSpeed < 1.0)
		return;
	
	fVelAngle[1] = fAngles[1] - fVelAngle[1];
	
	float fNegatedDirection[3], fForwardDirection[3];
	GetAngleVectors(fVelAngle, fForwardDirection, NULL_VECTOR, NULL_VECTOR);
	
	fNegatedDirection[0] = fForwardDirection[0] * (-fSpeed);
	fNegatedDirection[1] = fForwardDirection[1] * (-fSpeed);
	fNegatedDirection[2] = fForwardDirection[2] * (-fSpeed);
	
	fVel[0] = fNegatedDirection[0];
	fVel[1] = fNegatedDirection[1];
}

int GetLossBonus(int& g_iRoundsLost)
{
    if (g_iRoundsLost <= 0) {
        return 1400;
    } else if (g_iRoundsLost == 1) {
        return 1900;
    } else if (g_iRoundsLost == 2) {
        return 2400;
    } else if (g_iRoundsLost == 3) {
        return 2900;
    } else {
        return 3400;
    }
}

void UpdateRoundsLost(bool won, int& roundsLost)
{
    if (won) {
        // If the team won, decrease rounds lost
        if (roundsLost > 0) {
            roundsLost--;
        }
    } else {
        // If the team lost, increase rounds lost
        if (roundsLost < 4) {
            roundsLost++;
        }
    }
}

public void UpdateRoundTime()
{
    g_fCurrentTime = GetGameTime();
    
    g_fTimeElapsed = g_fCurrentTime - g_fFreezeTimeEnd;
    g_fRoundTimeRemaining = 115.0 - g_fTimeElapsed;

    int iPlantedC4 = FindEntityByClassname(-1, "planted_c4");
    if (IsValidEntity(iPlantedC4)) 
    {
        g_fBombTime = GetEntPropFloat(iPlantedC4, Prop_Send, "m_flC4Blow");
        g_fTimeLeft = g_fBombTime - g_fCurrentTime;
    }
    else
    {
        g_fBombTime = 0.0;
        g_fTimeLeft = 0.0;
    }
}

void CheckAWPDonation(int team)
{
    if (g_iCurrentRound == 0 || g_iCurrentRound == 1 || g_iCurrentRound == 12 || g_iCurrentRound == 13)
        return;

    int awper = FindTeamAWPer(team);
    if (awper == -1)
        return;

    int donor = -1;
    int richestMoney = -1;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != team)
            continue;

        int money = GetEntProp(i, Prop_Send, "m_iAccount");
        if (money > richestMoney)
        {
            donor = i;
            richestMoney = money;
        }
    }

    if (donor == -1 || donor == awper)
        return;

    bool awperIsHuman = (!IsFakeClient(awper));

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsFakeClient(i) || !IsPlayerAlive(i))
            continue;
            
        if (GetClientTeam(i) != team)
            continue;
            
        if (g_bHasPickedUpAWP[i] && g_iSavedAWPFor[i] == awper)
        {
            int primary = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
            if (IsValidEntity(primary) && GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex") == 9)
            {
                PrintToServer("[AWP_SAVER] Rifler %N has saved AWP for AWPer %N, setting up donation", i, awper);
                
                g_bIsAWPDonor[i] = true;
                g_bBuyDelayed[i] = true;
                g_bBuyDelayed[awper] = true;
                
                CreateTimer(2.0, Timer_DelayedDonorBuy, i, TIMER_FLAG_NO_MAPCHANGE);
                CreateTimer(3.5, Timer_ClearBuyDelay, i, TIMER_FLAG_NO_MAPCHANGE);
                CreateTimer(3.5, Timer_ClearBuyDelay, awper, TIMER_FLAG_NO_MAPCHANGE);
                
                return;
            }
        }
    }


    if (donor == awper || donor == -1)
        return;

    bool isCT = (team == CS_TEAM_CT);

    char awperClass[64], donorClass[64];
    int awperPrimary = GetPlayerWeaponSlot(awper, CS_SLOT_PRIMARY);
    int donorPrimary = GetPlayerWeaponSlot(donor, CS_SLOT_PRIMARY);

    bool awperHasPrimary = IsValidEntity(awperPrimary);
    bool donorHasPrimary = IsValidEntity(donorPrimary);

    bool awperHasAWP = false;
    bool donorHasAWP = false;
    bool awperHasRifle = false;
    bool donorHasRifle = false;

    if (awperHasPrimary)
    {
        GetEdictClassname(awperPrimary, awperClass, sizeof(awperClass));
        if (StrEqual(awperClass, "weapon_awp"))
            awperHasAWP = true;
        else if (StrEqual(awperClass, "weapon_m4a1") || StrEqual(awperClass, "weapon_m4a1_silencer") || StrEqual(awperClass, "weapon_ak47"))
            awperHasRifle = true;
    }

    if (donorHasPrimary)
    {
        GetEdictClassname(donorPrimary, donorClass, sizeof(donorClass));
        if (StrEqual(donorClass, "weapon_awp"))
            donorHasAWP = true;
        else if (StrEqual(donorClass, "weapon_m4a1") || StrEqual(donorClass, "weapon_m4a1_silencer") || StrEqual(donorClass, "weapon_ak47"))
            donorHasRifle = true;
    }

    if (awperHasAWP)
    {
        PrintToServer("[AWP DEBUG] AWPer %N already has an AWP, skipping donation.", awper);
        return;
    }

    int awperMoney = GetEntProp(awper, Prop_Send, "m_iAccount");
    if (awperMoney >= 5750)
    {
        PrintToServer("[AWP DEBUG] AWPer %N can afford own AWP (%d$), skipping donation.", awper, awperMoney);
        return;
    }

    if (awperHasRifle && !donorHasAWP)
    {
        PrintToServer("[AWP DEBUG] AWPer %N already has rifle (%s) and donor %N has no AWP, skipping donation.",
            awper, awperClass, donor);
        return;
    }

    if (donorHasAWP && awperHasRifle)
    {
        PrintToServer("[AWP DEBUG] Donor %N already has AWP and AWPer %N has rifle (%s) → swapping weapons.",
            donor, awper, awperClass);

        g_bIsAWPDonor[donor] = true;
        g_bBuyDelayed[donor] = true;
        CreateTimer(2.0, Timer_DelayedDonorBuy, donor, TIMER_FLAG_NO_MAPCHANGE);
        CreateTimer(3.5, Timer_ClearBuyDelay, donor, TIMER_FLAG_NO_MAPCHANGE);
        CreateTimer(3.5, Timer_ClearBuyDelay, awper, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }

    g_bIsAWPDonor[donor] = true;
    int donorMoney = GetEntProp(donor, Prop_Send, "m_iAccount");
    PrintToServer("[AWP DEBUG] Evaluating donor %N (money=%d) & AWPer %N (money=%d)",
        donor, donorMoney, awper, awperMoney);

    bool donorCanDonate = false;

    if (isCT)
	{
	    if ((!donorHasPrimary && donorMoney >= 8500) ||
	        (donorHasPrimary && donorMoney >= 4750) ||
	        (!donorHasPrimary && donorMoney >= 5400 && awperMoney >= 3750))
	    {
	        donorCanDonate = true;

	        if (IsPlayerAlive(awper) && IsPlayerAlive(donor))
	        {
	            g_bBuyDelayed[awper] = true;
	            CreateTimer(3.5, Timer_ClearBuyDelay, awper, TIMER_FLAG_NO_MAPCHANGE);
	            PrintToServer("[AWP DEBUG] AWPer %N buy delayed because donor %N can donate", awper, donor);
	        }

	        g_bBuyDelayed[donor] = true;
	        CreateTimer(2.0, Timer_DelayedDonorBuy, donor, TIMER_FLAG_NO_MAPCHANGE);
	        CreateTimer(3.5, Timer_ClearBuyDelay, donor, TIMER_FLAG_NO_MAPCHANGE);
	        PrintToServer("[AWP DEBUG] CT donor %N scheduled for delayed buy", donor);
	    }
	}
	else
	{
	    if ((!donorHasPrimary && donorMoney >= 8450) ||
	        (donorHasPrimary && donorMoney >= 4750) ||
	        (!donorHasPrimary && donorMoney >= 5750 && awperMoney >= 3700))
	    {
	        donorCanDonate = true;

	        if (IsPlayerAlive(awper) && IsPlayerAlive(donor))
	        {
	            g_bBuyDelayed[awper] = true;
	            CreateTimer(3.5, Timer_ClearBuyDelay, awper, TIMER_FLAG_NO_MAPCHANGE);
	            PrintToServer("[AWP DEBUG] AWPer %N buy delayed because donor %N can donate", awper, donor);
	        }

	        g_bBuyDelayed[donor] = true;
	        CreateTimer(2.0, Timer_DelayedDonorBuy, donor, TIMER_FLAG_NO_MAPCHANGE);
	        CreateTimer(3.5, Timer_ClearBuyDelay, donor, TIMER_FLAG_NO_MAPCHANGE);
	        PrintToServer("[AWP DEBUG] T donor %N scheduled for delayed buy", donor);
	    }
	}
}

void ResetLossBonusOnOvertimeHalftime()
{
    int iOvertimePlaying = GameRules_GetProp("m_nOvertimePlaying");
    if (iOvertimePlaying > 0)
    {
        int iRoundsPerOvertimeHalf = FindConVar("mp_overtime_maxrounds").IntValue / 2;
        int iTotalOvertimeRounds = g_iCurrentRound - FindConVar("mp_maxrounds").IntValue;
        int iRoundsInCurrentOvertime = iTotalOvertimeRounds - (iOvertimePlaying - 1) * FindConVar("mp_overtime_maxrounds").IntValue;

        if (iTotalOvertimeRounds == 0)
        {
            g_iRoundsLostCT = 1;
            g_iRoundsLostT = 1;
            PrintToServer("[LOSSBONUS] Start of overtime (round %d). Resetting CT and T rounds lost to 1.", g_iCurrentRound + 1);
        }
        else if (iRoundsInCurrentOvertime == iRoundsPerOvertimeHalf)
        {
            g_iRoundsLostCT = 1;
            g_iRoundsLostT = 1;
            PrintToServer("[LOSSBONUS] Overtime halftime switch after round %d. Resetting CT and T rounds lost to 1.", g_iCurrentRound + 1);
        }
    }
}

stock bool ShouldForce(int iTeam)
{
    int currentBonus = (iTeam == CS_TEAM_CT) ? g_iCurrentBonusCT : g_iCurrentBonusT;
    if (currentBonus == 1400 || currentBonus == 1900)
    {
        return true;
    }

    int iOvertimePlaying = GameRules_GetProp("m_nOvertimePlaying");
    GamePhase pGamePhase = view_as<GamePhase>(GameRules_GetProp("m_gamePhase"));

    if (FindConVar("mp_halftime").BoolValue && pGamePhase == GAMEPHASE_PLAYING_FIRST_HALF)
    {
        int iRoundsBeforeHalftime;
        if (iOvertimePlaying)
        {
            // Overtime halftime: mp_maxrounds + (2 * iOvertimePlaying - 1) * (mp_overtime_maxrounds / 2)
            iRoundsBeforeHalftime = FindConVar("mp_maxrounds").IntValue + 
                (2 * iOvertimePlaying - 1) * (FindConVar("mp_overtime_maxrounds").IntValue / 2);
        }
        else
        {
            iRoundsBeforeHalftime = FindConVar("mp_maxrounds").IntValue / 2;
        }

        if (iRoundsBeforeHalftime > 0 && g_iRoundsPlayed == iRoundsBeforeHalftime - 1)
        {
            g_bHalftimeSwitch = true;
            return true;
        }
    }

    // Check if either team is one win away from clinching the match
    int iNumWinsToClinch = GetNumWinsToClinch();
    if (pGamePhase != GAMEPHASE_PLAYING_FIRST_HALF && 
        (g_iCTScore == iNumWinsToClinch - 1 || g_iTScore == iNumWinsToClinch - 1))
    {
        return true;
    }

    // Check if this is the last possible round
    int iMaxRounds = FindConVar("mp_maxrounds").IntValue;
    int iOvertimeMaxRounds = FindConVar("mp_overtime_maxrounds").IntValue;
    int iTotalRounds = iMaxRounds + iOvertimePlaying * iOvertimeMaxRounds;
    if (iMaxRounds > 0 && g_iCurrentRound == iTotalRounds - 1)
    {
        return true;
    }

    return false;
}

stock bool ShouldUpgrade(int client)
{
    int iAccount = GetEntProp(client, Prop_Send, "m_iAccount");
    
    if ((g_iCurrentRound == 11 || g_iCurrentRound == 23) || iAccount > 8000)
    {
        return true;
    }
    
    return false;
}

stock int GetNumWinsToClinch()
{
	int iOvertimePlaying = GameRules_GetProp("m_nOvertimePlaying");
	int iNumWinsToClinch = (FindConVar("mp_maxrounds").IntValue > 0 && FindConVar("mp_match_can_clinch").BoolValue) ? (FindConVar("mp_maxrounds").IntValue / 2 ) + 1 + iOvertimePlaying * (FindConVar("mp_overtime_maxrounds").IntValue / 2) : -1;
	return iNumWinsToClinch;
}

stock bool IsItMyChance(float fChance = 0.0)
{
	float flRand = Math_GetRandomFloat(0.0, 100.0);
	if( fChance <= 0.0 )
		return false;
	return flRand <= fChance;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client);
}

stock bool IsLastTAlive(int client)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client) continue;
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			count++;
		}
	}
	return count == 0;
}

stock bool IsLastCTAlive(int client)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client) continue;
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			count++;
		}
	}
	return count == 0;
}

stock bool AreAllEnemiesDead(int client)
{
    int team = GetClientTeam(client);
    if (team == CS_TEAM_CT)
        return GetAliveTeamCount(CS_TEAM_T) == 0;
    if (team == CS_TEAM_T)
        return GetAliveTeamCount(CS_TEAM_CT) == 0;
    return false;
}

stock bool ShouldFakePlantOnce(int client, float fChance)
{
	if (g_bFakePlantRolled[client])
	{
		return false;
	}

	g_bFakePlantRolled[client] = true;

	float roll = Math_GetRandomFloat(0.0, 100.0);
	PrintToServer("[FAKEPLANT] Client %d rolled %.2f for %.2f%% chance", client, roll, fChance);

	return roll <= fChance;
}

stock bool CheckDistanceToTeammates(int defuserBot) 
{
    if (!IsValidClient(defuserBot) || !IsFakeClient(defuserBot) || !IsPlayerAlive(defuserBot) || GetClientTeam(defuserBot) != CS_TEAM_CT) 
    {
        return false;
    }

    float defuserPos[3];
    GetClientAbsOrigin(defuserBot, defuserPos);

    for (int i = 1; i <= MaxClients; i++) 
    {
        if (i != defuserBot && IsValidClient(i) && IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT) 
        {
            float teammatePos[3];
            GetClientAbsOrigin(i, teammatePos);

            float distance = GetVectorDistance(defuserPos, teammatePos);

            if (distance < 450.0) 
            {
                return false; //
            }
        }
    }

    return true;
}

stock bool IsFarFromTeammates(int botClient, float minDistance)
{
    if (!IsValidClient(botClient) || !IsFakeClient(botClient) || !IsPlayerAlive(botClient) || GetClientTeam(botClient) != CS_TEAM_T)
    {
        return false;
    }

    float botPos[3];
    GetClientAbsOrigin(botClient, botPos);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == botClient) continue;

        if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
        {
            float teammatePos[3];
            GetClientAbsOrigin(i, teammatePos);

            float distance = GetVectorDistance(botPos, teammatePos);

            if (distance < minDistance)
            {
                return false;
            }
        }
    }

    return true;
}

stock void SpreadCompromisedStateFrom(int compromisedBot)
{
    if (!IsValidClient(compromisedBot) || !IsFakeClient(compromisedBot) || !IsPlayerAlive(compromisedBot))
        return;

    float compromisedPos[3];
    GetClientAbsOrigin(compromisedBot, compromisedPos);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == compromisedBot)
            continue;

        if (!IsValidClient(i) || !IsFakeClient(i) || !IsPlayerAlive(i))
            continue;

        if (GetClientTeam(i) != GetClientTeam(compromisedBot))
            continue;

        if (g_bBotCompromised[i])
            continue; // Already compromised

        float teammatePos[3];
        GetClientAbsOrigin(i, teammatePos);

        if (GetVectorDistance(compromisedPos, teammatePos) <= 100.0)
        {
            g_bBotCompromised[i] = true;
            PrintToServer("[RETAKE] Bot %d compromised due to proximity to bot %d", i, compromisedBot);
        }
    }
}

stock bool IsBotNearPlantedBomb(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return false;

    int iPlantedC4 = FindEntityByClassname(-1, "planted_c4");
    if (!IsValidEntity(iPlantedC4))
        return false;

    float fBotPos[3], fPlantedC4Location[3];
    GetClientAbsOrigin(client, fBotPos);
    GetEntPropVector(iPlantedC4, Prop_Send, "m_vecOrigin", fPlantedC4Location);

    float fDistance = GetVectorDistance(fBotPos, fPlantedC4Location);
    return fDistance <= 1200.0;
}

stock bool PlayerHasPrimary(int client)
{
    int h = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
    return (h != -1 && IsValidEntity(h));
}

stock float MyRoundToNearest(float value, float nearest)
{
    return nearest * RoundToNearest(value / nearest);
}
