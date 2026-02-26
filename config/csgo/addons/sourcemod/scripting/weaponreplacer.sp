#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

public Plugin myinfo =
{
    name = "Weapon Replacer",
    author = "Rxpev",
    description = "Replaces P2000 with USP-S on spawn and M4A4 with M4A1-S on purchase for CTs with toggle commands",
    version = "1.3",
    url = "https://steamcommunity.com/id/rxpev/"
};

// Cookies for storing player preferences
Handle g_hCookieUSPToggle = null;
Handle g_hCookieM4A1Toggle = null;

// Arrays to store in-memory toggle states
bool g_bUSPToggle[MAXPLAYERS + 1];
bool g_bM4A1Toggle[MAXPLAYERS + 1];

public void OnPluginStart()
{
    // Hook the player spawn event
    HookEvent("player_spawn", Event_PlayerSpawn);
    
    // Register chat commands
    RegConsoleCmd("sm_usp", Command_ToggleUSP, "Toggles USP-S replacement for P2000 on spawn");
    RegConsoleCmd("sm_m4a1", Command_ToggleM4A1, "Toggles M4A1-S replacement for M4A4 on purchase");
    
    // Initialize client cookies
    g_hCookieUSPToggle = RegClientCookie("weapon_replace_usp", "Toggle USP-S replacement", CookieAccess_Protected);
    g_hCookieM4A1Toggle = RegClientCookie("weapon_replace_m4a1", "Toggle M4A1-S replacement", CookieAccess_Protected);
    
    // Load cookie data for connected clients
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && AreClientCookiesCached(client))
        {
            OnClientCookiesCached(client);
        }
    }
}

public void OnClientCookiesCached(int client)
{
    char buffer[8];
    
    // Load USP toggle state
    GetClientCookie(client, g_hCookieUSPToggle, buffer, sizeof(buffer));
    g_bUSPToggle[client] = (buffer[0] != '\0' && StringToInt(buffer) == 1);
    
    // Load M4A1 toggle state
    GetClientCookie(client, g_hCookieM4A1Toggle, buffer, sizeof(buffer));
    g_bM4A1Toggle[client] = (buffer[0] != '\0' && StringToInt(buffer) == 1);
}

public void OnClientDisconnect(int client)
{
    // Reset toggle states when client disconnects
    g_bUSPToggle[client] = false;
    g_bM4A1Toggle[client] = false;
}

public Action Command_ToggleUSP(int client, int args)
{
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    // Toggle USP preference
    g_bUSPToggle[client] = !g_bUSPToggle[client];
    
    // Save to cookie
    char buffer[8];
    IntToString(g_bUSPToggle[client] ? 1 : 0, buffer, sizeof(buffer));
    SetClientCookie(client, g_hCookieUSPToggle, buffer);
    
    // Notify player
    PrintToChat(client, "USP-S replacement %s.", g_bUSPToggle[client] ? "enabled" : "disabled");
    
    return Plugin_Handled;
}

public Action Command_ToggleM4A1(int client, int args)
{
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    // Toggle M4A1 preference
    g_bM4A1Toggle[client] = !g_bM4A1Toggle[client];
    
    // Save to cookie
    char buffer[8];
    IntToString(g_bM4A1Toggle[client] ? 1 : 0, buffer, sizeof(buffer));
    SetClientCookie(client, g_hCookieM4A1Toggle, buffer);
    
    // Notify player
    PrintToChat(client, "M4A1-S replacement %s.", g_bM4A1Toggle[client] ? "enabled" : "disabled");
    
    return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != CS_TEAM_CT || !g_bUSPToggle[client])
        return;

    int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);

    // Only act when they have *no* pistol or specifically the P2000
    if (weapon == -1)
    {
        GivePlayerItem(client, "weapon_usp_silencer");
        return;
    }

    char weaponName[32];
    GetEntityClassname(weapon, weaponName, sizeof(weaponName));

    if (StrEqual(weaponName, "weapon_hkp2000"))
    {
        RemovePlayerItem(client, weapon);
        AcceptEntityInput(weapon, "Kill");
        GivePlayerItem(client, "weapon_usp_silencer");
    }
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
    // Check if the client is valid, on CT team, and has M4A1 toggle enabled
    if (IsValidClient(client) && GetClientTeam(client) == CS_TEAM_CT && g_bM4A1Toggle[client])
    {
        // Check if the player is buying an M4A4
        if (StrEqual(weapon, "m4a1", false))
        {
            // Delay the replacement to ensure proper handling
            DataPack pack;
            CreateDataTimer(0.1, Timer_ReplaceM4A4, pack);
            pack.WriteCell(GetClientUserId(client));
            return Plugin_Handled; // Block the default M4A4 purchase
        }
    }
    
    return Plugin_Continue;
}

public Action Timer_ReplaceM4A4(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        // Check player's money
        int money = GetEntProp(client, Prop_Send, "m_iAccount");
        const int M4A1S_PRICE = 2900;
        
        if (money >= M4A1S_PRICE)
        {
            // Deduct $2900 for M4A1-S
            SetEntProp(client, Prop_Send, "m_iAccount", money - M4A1S_PRICE);
            
            // Remove M4A4 if equipped
            int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
            if (weapon != -1 && IsValidEntity(weapon))
            {
                char weaponName[32];
                GetEntityClassname(weapon, weaponName, sizeof(weaponName));
                if (StrEqual(weaponName, "weapon_m4a1"))
                {
                    RemovePlayerItem(client, weapon);
                    AcceptEntityInput(weapon, "Kill");
                }
            }
            
            // Give M4A1-S
            GivePlayerItem(client, "weapon_m4a1_silencer");
        }
    }
    
    return Plugin_Stop;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}