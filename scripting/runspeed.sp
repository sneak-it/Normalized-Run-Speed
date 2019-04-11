#include <sourcemod>
#include <dhooks>

public Plugin myinfo =
{
	name = "Normalized Run Speed",
	author = "sneaK",
	description = "Allows customizable run speed with any weapon",
	version = "0.5",
	url = "https://snksrv.com"
};

Handle g_hGetPlayerMaxSpeed = null;

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "dhooks"))
	{
		Dhooks();
	}
}

void Dhooks()
{
	// Optionally setup a hook on CCSPlayer::GetPlayerMaxSpeed to allow full run speed with all weapons.
	if(g_hGetPlayerMaxSpeed == null) {
		Handle hGameData = LoadGameConfigFile("runspeed.games");

		if (hGameData != null) {
			int iOffset = GameConfGetOffset(hGameData, "GetPlayerMaxSpeed");
			CloseHandle(hGameData);

			if (iOffset != -1) {
				g_hGetPlayerMaxSpeed = DHookCreate(iOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, DHook_GetMaxPlayerSpeed);
			}
		}
	}
}

public void OnPluginStart()
{
	if (LibraryExists("dhooks"))
	{
		Dhooks();
	}
}
	
public void OnClientPutInServer(int client)
{
	if (LibraryExists("dhooks"))
	{
		DHookEntity(g_hGetPlayerMaxSpeed, true, client);
	}
}


public MRESReturn DHook_GetMaxPlayerSpeed(int client, Handle hReturn)
{
	if (!IsValidClient(client))
	{
		return MRES_Ignored;
	}

	DHookSetReturn(hReturn, 260.0);

	return MRES_Override;
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}