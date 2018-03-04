/*Credit to ElkTF2 for the idea of this plugin!*/


#include <sourcemod>
#include <tf2_stocks>


bool blueOffclassing = false;
bool redOffclassing = false;

ConVar pluginEnabled, pyroEnabled, heavyEnabled, engiEnabled;

Menu offclassMenu;


public Plugin myinfo = {
	name = "[TF2] Offclass-Control",
	author = "EasyE",
	description = "Prevents pyro/heavy/engi being used when your teams 2nd point has not been captured",
	version = "1",
	url = "http://steamcommunity.com/id/eeeasye/"
}


public void OnPluginStart() {
	//Hooks
	HookEvent("teamplay_point_captured", Event_PointCaptured, EventHookMode_Post);
	HookEvent("player_changeclass", Event_ChangeClass, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("teamplay_team_ready", countdown, EventHookMode_Post);
	//Cvars
	pluginEnabled = CreateConVar("sm_offclassing_enabled", "0", "Enables/Disables the offclasser plugin");
	pyroEnabled = CreateConVar("sm_offclassing_pyro", "0", "Enables/Disables offclassing to pyro");
	heavyEnabled = CreateConVar("sm_offclassing_heavy", "0", "Enables/Disables offclassing to heavy");
	engiEnabled = CreateConVar("sm_offclassing_engi", "0", "Enables/Disables offclassing to engi");
	pluginEnabled.AddChangeHook(OnConVarChange);
	pyroEnabled.AddChangeHook(OnConVarChange);
	heavyEnabled.AddChangeHook(OnConVarChange);
	engiEnabled.AddChangeHook(OnConVarChange);
	//Menu
	offclassMenu = new Menu(OffclassMenuHandler);
	offclassMenu.SetTitle("Offclass Control");
	offclassMenuBuilder();
	//Commands
	RegConsoleCmd("sm_offclass", Command_OffclassMenu);
}


/***HOOKS***/


public Action countdown(Event event, const char[] name, bool dontBroadcast) {
	PrintToChatAll("dbg0");
}
public Action Event_PointCaptured(Event event, const char[] name, bool dontBroadcast) {
	int cp = event.GetInt("cp")
	TFTeam team = view_as<TFTeam>(event.GetInt("team"))
	switch (cp) {
		case 0: {
			blueOffclassing = false;
			redOffclassing = false;
			resetClasses();
		}
		case 1: {
			if (team == TFTeam_Blue) { 
				blueOffclassing = false;
				resetClasses();
			}
			else blueOffclassing = true;
		}
		case 2: {
			blueOffclassing = false;
			redOffclassing = false;
		}
		case 3: {
			if (team == TFTeam_Red) {
				redOffclassing = false;
				resetClasses();
			}
			else redOffclassing = true;
		}
		case 4: {
			blueOffclassing = false;
			redOffclassing = false;
			resetClasses();
		}
	}
}


public Action Event_ChangeClass(Event event, const char[] name, bool dontBroadcast) {
	if (pluginEnabled.BoolValue)return Plugin_Handled;
	int id = event.GetInt("userid");
	int client = GetClientOfUserId(id);
	TFClassType class = view_as<TFClassType>(event.GetInt("class"))
	TFClassType currentClass = TF2_GetPlayerClass(client);
	TFTeam team = TF2_GetClientTeam(client);
	if(checkClass(team, class)) {
		TF2_SetPlayerClass(client, currentClass);
	}
	return Plugin_Handled;
}

//If the class is restricted, full bonk-stuns the player. 
//It would change the class back to there main but this forced class change could be exploited to override the class limits, e.g 3 scouts
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	if (pluginEnabled.BoolValue)return Plugin_Handled;
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFClassType class = TF2_GetPlayerClass(client)
	TFTeam team = view_as<TFTeam>(GetClientTeam(client))
	if(checkClass(team, class)) {
		CreateTimer(0.001, stunPlayer, client);
	}
	return Plugin_Handled;
}


public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
	char name[32];
	convar.GetName(name, sizeof(name));
	int value = StringToInt(newValue);
	if(StrEqual(name, "sm_offclassing_enabled")) {
		if(value == 0) {
			resetClasses();
		}
	}
	else if(value == 0) {
		resetClasses();
	}
}


/***FUNCTIONS***/


//checks a team for any defensive offclasses, and gives them 30 seconds to switch back to there main classes before they are killed.
public void resetClasses() {
	if(!pluginEnabled.BoolValue) {
		for (int i = 1; i < MaxClients; i++) {
			if (!IsValidClient(i))continue;
			TFClassType class = TF2_GetPlayerClass(i);
			TFTeam playerTeam = view_as<TFTeam>(GetClientTeam(i));
			if (checkClass(playerTeam, class)) {
				PrintToChat(i, "\x04[OffClasser] \x070080ff You have 30 seconds to change back to an offensive class!");
				CreateTimer(30.0, killPlayer, i)
			}
		}
	}
}


//checks if class is disabled, if so returns true, if alllowed returns false
public bool checkClass(TFTeam team, TFClassType class) {
	if(team == TFTeam_Blue && !blueOffclassing) {
		if (class == TFClass_Pyro && !pyroEnabled.BoolValue)return true;
		if (class == TFClass_Heavy && !heavyEnabled.BoolValue)return true;
		if (class == TFClass_Engineer && !engiEnabled.BoolValue)return true;
	}
	else if(team == TFTeam_Red && !redOffclassing) {
		if (class == TFClass_Pyro && !pyroEnabled.BoolValue)return true;
		if (class == TFClass_Heavy && !heavyEnabled.BoolValue)return true;
		if (class == TFClass_Engineer && !engiEnabled.BoolValue)return true;
	}
	return false;
}


public Action stunPlayer(Handle timer, int client) {
	TF2_StunPlayer(client, 99999.00, 0.00, TF_STUNFLAG_BONKSTUCK, 0);
	PrintToChat(client, "\x04[OffClasser] \x070080ff This class is restricted!");
}


public Action killPlayer(Handle timer, int client) {
	TFClassType class = TF2_GetPlayerClass(client);
	TFTeam team = view_as<TFTeam>(GetClientTeam(client));
	if (checkClass(team, class)) {
		ForcePlayerSuicide(client);
		PrintToChat(client, "\x04[OffClasser] \x070080ff You did not change your class in time!");
	}
}


//shoutout to TheXeon for giving me this snippet like a year ago <3
public bool IsValidClient(int client) {
	if (client > 4096) client = EntRefToEntIndex(client);
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	return true;
}

/***MENU***/


public Action Command_OffclassMenu(int client, int args) {
	if (!IsValidClient(client))return Plugin_Handled;
	offclassMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public int OffclassMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_Select) {
		char info[32]
		menu.GetItem(param2, info, sizeof(info))
		if(StrEqual("pluginenabled", info)) {
			pluginEnabled.SetInt(!pluginEnabled.BoolValue);
			offclassMenuBuilder()
			offclassMenu.Display(param1, MENU_TIME_FOREVER);
		}
		if(StrEqual("pyroenabled", info)) {
			pyroEnabled.SetInt(!pyroEnabled.BoolValue);
			offclassMenuBuilder()
			offclassMenu.Display(param1, MENU_TIME_FOREVER);
		}
		if(StrEqual("heavyenabled", info)) {
			heavyEnabled.SetInt(!heavyEnabled.BoolValue);
			offclassMenuBuilder()
			offclassMenu.Display(param1, MENU_TIME_FOREVER);
		}
		if(StrEqual("engienabled", info)) {
			engiEnabled.SetInt(!engiEnabled.BoolValue);
			offclassMenuBuilder()
			offclassMenu.Display(param1, MENU_TIME_FOREVER);
		}
	}
}


public void offclassMenuBuilder() {
	offclassMenu.RemoveAllItems();
	char pluginEnable[64], pyroEnable[64], heavyEnable[64], engiEnable[64];
	Format(pluginEnable, sizeof(pluginEnable), "Allow all offclassing: %s", pluginEnabled.BoolValue ? "Enabled" : "Disabled");
	Format(pyroEnable, sizeof(pyroEnable), "Pyro offclassing: %s", pyroEnabled.BoolValue ? "Enabled" : "Disabled");
	Format(heavyEnable, sizeof(heavyEnable), "Heavy offclassing: %s", heavyEnabled.BoolValue ? "Enabled" : "Disabled");
	Format(engiEnable, sizeof(engiEnable), "Engineer offclassing: %s", engiEnabled.BoolValue ? "Enabled" : "Disabled");
	offclassMenu.AddItem("pluginenabled", pluginEnable);
	offclassMenu.AddItem("pyroenabled", pyroEnable);
	offclassMenu.AddItem("heavyenabled", heavyEnable);
	offclassMenu.AddItem("engienabled", engiEnable);
}