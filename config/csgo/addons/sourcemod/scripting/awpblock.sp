#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo =
{
    name        = "Block AWP Fire (ConVar & Team-Based)",
    author      = "Rxpev",
    description = "Blocks AWP for humans while they have alive teammates, unless isAWP = 1.",
    version     = "1.7",
    url         = "http://steamcommunity.com/id/rxpev"
};

Handle g_hIsAwp;

float g_fLastAwpWarn[MAXPLAYERS + 1];
bool  g_bAwpRestricted[MAXPLAYERS + 1];

public void OnPluginStart()
{
    g_hIsAwp = CreateConVar(
        "isAWP",
        "0",
        "0 = restrict AWP usage for non-awpers; 1 = allow normal AWP usage.",
        FCVAR_NOTIFY,
        true, 0.0,
        true, 1.0
    );

    PrintToServer("[PRO JOURNEY] Block AWP plugin loaded. isAWP = %d", GetConVarInt(g_hIsAwp));
}

public void OnClientDisconnect(int client)
{
    if (0 < client <= MaxClients)
    {
        g_fLastAwpWarn[client]   = 0.0;
        g_bAwpRestricted[client] = false;
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed,int mouse[2])
{
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    if (IsFakeClient(client))
        return Plugin_Continue;

    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (activeWeapon <= 0)
        return Plugin_Continue;

    char classname[64];
    if (!GetEntityClassname(activeWeapon, classname, sizeof(classname)))
        return Plugin_Continue;

    if (!StrEqual(classname, "weapon_awp", false))
        return Plugin_Continue;

    int team = GetClientTeam(client);
    if (team <= CS_TEAM_SPECTATOR)
        return Plugin_Continue;

    float now = GetGameTime();

    // Allow normal AWP usage during warmup or when isAWP = 1.
    if (GameRules_GetProp("m_bWarmupPeriod") == 1 || GetConVarInt(g_hIsAwp) == 1)
    {
        if (g_bAwpRestricted[client])
        {
            g_bAwpRestricted[client] = false;

            SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack",  now);
            SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextSecondaryAttack", now);
            SetEntPropFloat(client,       Prop_Send, "m_flNextAttack",          now);

            g_fLastAwpWarn[client] = 0.0;
        }

        return Plugin_Continue;
    }

    bool hasTeammateAlive = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == client)
            continue;

        if (!IsClientInGame(i) || !IsPlayerAlive(i))
            continue;

        if (GetClientTeam(i) != team)
            continue;

        hasTeammateAlive = true;
        break;
    }

    if (!hasTeammateAlive)
    {
        if (g_bAwpRestricted[client])
        {
            g_bAwpRestricted[client] = false;

            SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack",  now);
            SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextSecondaryAttack", now);
            SetEntPropFloat(client,       Prop_Send, "m_flNextAttack",          now);
        }

        return Plugin_Continue;
    }

    g_bAwpRestricted[client] = true;

    // Warn the player every 5 seconds while they hold the AWP
    if (now - g_fLastAwpWarn[client] >= 5.0)
    {
        g_fLastAwpWarn[client] = now;

        PrintToChat(client, "[PRO JOURNEY] You are not allowed to use the AWP.");
        PrintCenterText(client, "You are not an AWPer.\nDrop the AWP to your AWPer!");
    }

    float blockTime = now + 3600.0;

    SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack",  blockTime);
    SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextSecondaryAttack", blockTime);
    SetEntPropFloat(client,       Prop_Send, "m_flNextAttack",          blockTime);

    if (buttons & IN_ATTACK)
        buttons &= ~IN_ATTACK;
    if (buttons & IN_ATTACK2)
        buttons &= ~IN_ATTACK2;

    return Plugin_Changed;
}
