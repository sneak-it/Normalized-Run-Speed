#include <sourcemod>
#include <dhooks>

public Plugin myinfo =
{
	name = "Normalized Run Speed",
	author = "sneaK",
	description = "Allows customizable run speed with any weapon",
	version = "0.6",
	url = "https://snksrv.com"
};

ConVar gCV_RunspeedEnabled;
ConVar gCV_SetPlayerMaxSpeed;

Handle g_hGetPlayerMaxSpeed = null;

bool g_bLateLoaded;
bool g_bRunspeedEnabled;

float g_fSetPlayerMaxSpeed;

int g_iHookID;

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
	if(g_hGetPlayerMaxSpeed == null && g_bRunspeedEnabled) {
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

void ConVarInit() {
	gCV_RunspeedEnabled = CreateConVar("sm_rs_enabled", "1", "1: plugin enabled (default); 0: plugin disabled", FCVAR_NOTIFY);
	gCV_SetPlayerMaxSpeed = CreateConVar("sm_rs_playerspeed", "250.0", "Maximum runspeed for players");

	g_bRunspeedEnabled = GetConVarBool(gCV_RunspeedEnabled);
	HookConVarChange(gCV_RunspeedEnabled, OnRunspeedSettingsChanged);

	g_fSetPlayerMaxSpeed = GetConVarFloat(gCV_SetPlayerMaxSpeed);
	HookConVarChange(gCV_SetPlayerMaxSpeed, OnRunspeedSettingsChanged);

	AutoExecConfig(true, "runspeed");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoaded = true;
	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVarInit();
	if (LibraryExists("dhooks"))
	{
		Dhooks();
	}

	if (g_bLateLoaded) {
		for(int i = 0; i < MaxClients; i++)
			if (IsValidClient(i))
				OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client)
{
	if (LibraryExists("dhooks") && g_bRunspeedEnabled)
	{
		g_iHookID = DHookEntity(g_hGetPlayerMaxSpeed, true, client);
	}
	//Remove the hooks
	if (g_hGetPlayerMaxSpeed != null && !g_bRunspeedEnabled)
	{
		DHookRemoveHookID(g_iHookID);
	}
}


public MRESReturn DHook_GetMaxPlayerSpeed(int client, Handle hReturn)
{
	if (!IsValidClient(client))
	{
		return MRES_Ignored;
	}

	DHookSetReturn(hReturn, g_fSetPlayerMaxSpeed);

	return MRES_Override;
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}

void OnRunspeedSettingsChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	if (convar == gCV_RunspeedEnabled)
 		g_bRunspeedEnabled = StringToInt(newValue[0]) != 0;

	if (convar == gCV_SetPlayerMaxSpeed)
		g_fSetPlayerMaxSpeed = StringToFloat(newValue[0]);

	for (int i = 0; i < MaxClients; i++)
		if (IsValidClient(i))
			OnClientPutInServer(i);
}
