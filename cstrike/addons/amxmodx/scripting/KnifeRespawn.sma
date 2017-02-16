//#define SERVER  "176.57.188.24:27040" //explosion knife arena
//#define DATE 	  "15.1.2018"	//Datum kada istice plugin

#include <amxmodx>
#include <fun>
#include <engine>
#include <hamsandwich>

#define TASK_RESPAWN 666
#define TASK_PROTECT 777
#define TASK_COUNT 888

#define TEAM_T 1
#define TEAM_CT 2

#define FFADE_FADE_IN	0x0001
#define FFADE_STAYOUT	0x0004

new g_msg_screenfade;

new SyncHudObj;

new Float: protect_time[33];

new p_respawn, p_delay, p_protect;

new map_mode = 0;
new const Health[] = {100, 1, 35, 65, 200};

public plugin_init()
{
	register_plugin("EXP Knife Respawn", "1.0b", "Rajko");
	register_cvar("EXPknifeRES", "1", FCVAR_SERVER|FCVAR_SPONLY);
	
	#if defined SERVER
	/*new IP[64], PORT[16];
	get_cvar_string( "ip", IP, charsmax(IP));
	get_cvar_string("port", PORT, charsmax(PORT));
	add(IP, charsmax(IP), ":");
	add(IP, charsmax(IP), PORT);*/
	new IP[64];
	get_user_ip(0, IP, charsmax(IP));
	if(!equal(SERVER, IP) && containi(IP, "192.168" ) == -1)
		set_fail_state("Plugin nije odobren na ovom serveru. kontakt: rmilanrajkovic@gmail.com");
	#endif
	#if defined DATE
	new cDATE[12], eDATE[12];
	new szD1[3], szM1[3], szG1[5];
	new szD2[3], szM2[3], szG2[5];
	get_time("%d %m %Y", cDATE, charsmax(cDATE));
	copy(eDATE, charsmax(eDATE), DATE);
	replace_all(eDATE, charsmax(eDATE), ".", " ");
	replace_all(eDATE, charsmax(eDATE), "/", " ");
	parse(eDATE, szD1, charsmax(szD1), szM1, charsmax(szM1), szG1, charsmax(szG1));
	parse(cDATE, szD2, charsmax(szD2), szM2, charsmax(szM2), szG2, charsmax(szG2));
	new D1 = str_to_num(szD1); new D2 = str_to_num(szD2);
	new M1 = str_to_num(szM1); new M2 = str_to_num(szM2);
	new G1 = str_to_num(szG1); new G2 = str_to_num(szG2);
	new bool:fail=false;
	if (G2>G1)
		fail=true;
	else if(G2==G1)
	{
		if (M2>M1)
		{
			fail=true;
		}
		else if(M2==M1)
		{
			if(D2>D1)
				fail=true;
		}
	}
	if(fail)
		set_fail_state("Istekla vam je demo verzija plugina. Kontakt: rmilanrajkovic@gmail.com");
	#endif
	
	RegisterHam(Ham_Killed, "player", "PlayerKilled", 1);
	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	
	register_clcmd("jointeam", "ChangeTeam");
	
	p_respawn = register_cvar("knife_respawn", "0", ADMIN_RCON);
	p_delay = register_cvar("knife_respawn_delay", "2.0", ADMIN_CVAR);
	p_protect = register_cvar("knife_spawn_protect", "2.0", ADMIN_CVAR);
	
	g_msg_screenfade = get_user_msgid("ScreenFade");
	SyncHudObj = CreateHudSyncObj();
	
	new MapName[32], MapPrefix[6];
	get_mapname(MapName, charsmax(MapName));
	for (new i=0; i<sizeof Health; i++)
	{
		formatex(MapPrefix, charsmax(MapPrefix), "%ihp",Health[i]);
		if(contain(MapName, MapPrefix) != -1)
		{
			map_mode=i;
			break;
		}
	}
	new WepID = -1;
	while((WepID = find_ent_by_model(WepID,"armoury_entity","models/p_knife.mdl")) != 0)
	{
		remove_entity(WepID);
	}
	WepID = -1;
	while((WepID = find_ent_by_class(WepID, "game_player_hurt")) != 0 )
		remove_entity(WepID);
		
	set_task(5.0, "CheckForDeads", _,_,_,"b", 1);
}

public PlayerSpawn(id)
{
	if (!is_user_connected(id) || get_pcvar_float(p_protect) < 0.1)
		return PLUGIN_CONTINUE;
	set_user_health(id, Health[map_mode]);
	ProtectON(id);
	Count(id+TASK_COUNT);
	set_task(get_pcvar_float(p_protect), "ProtectOFF", id+TASK_PROTECT);
	return PLUGIN_CONTINUE;
}

public ProtectON(id)
{
	protect_time[id] = 2.0;
	set_user_godmode(id, 1);
	
	new team = get_user_team(id), red, blue;
	red = team == TEAM_T?255:0;
	blue = team == TEAM_CT?255:0;
	
	set_rendering(id,kRenderFxGlowShell,red,0,blue ,kRenderTransAlpha, 120);
	DisplayFade(id, FFADE_STAYOUT, red, blue, 50);
}

public Count(id)
{
	id -= TASK_COUNT;
	if (protect_time[id] < 0.0)
		return PLUGIN_CONTINUE;
	new team = get_user_team(id);
	if (team == TEAM_T)
		set_hudmessage(255, 0, 0, -1.0, 0.80, 0, 6.0, 0.1);
	else
		set_hudmessage(0, 0, 255, -1.0, 0.80, 0, 6.0, 0.1);
	ShowSyncHudMsg(id, SyncHudObj, "Spawn Protect: %.2fs left!",protect_time[id])
	protect_time[id]-=0.1;
	set_task(0.1, "Count", id+TASK_COUNT);
	return PLUGIN_CONTINUE;
}

public ProtectOFF(id)
{
	id -=TASK_PROTECT;
	if (!is_user_connected(id))
		return PLUGIN_CONTINUE;
	set_user_godmode(id);
	set_rendering(id,kRenderFxGlowShell,0,0,0 ,kRenderTransAlpha, 255);
	DisplayFade(id, FFADE_FADE_IN, 0, 0, 0);
	protect_time[id] = 0.0;
	return PLUGIN_CONTINUE;
}

public PlayerKilled(id)
{
	SetTask(id);
}

public ChangeTeam(id)
{
	SetTask(id);
}

public SetTask(id)
{
	if (!task_exists(id+TASK_RESPAWN))
		set_task(get_pcvar_float(p_delay), "Respawn", id+TASK_RESPAWN);
}

public Respawn(id)
{
	id -= TASK_RESPAWN;
	if (get_pcvar_num(p_respawn) == 1 &&!is_user_alive(id) && (get_user_team(id) == TEAM_T || get_user_team(id) == TEAM_CT))
		ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public client_disconnect(id)
{
	if(task_exists(id+TASK_RESPAWN))
		remove_task(id+TASK_RESPAWN);
	if(task_exists(id+TASK_COUNT))
		remove_task(id+TASK_COUNT);
	if(task_exists(id+TASK_PROTECT))
		remove_task(id+TASK_PROTECT);
	protect_time[id] = 0.0;
}

stock DisplayFade(id, FadeType, red, blue, alpha)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msg_screenfade,_, id)
	write_short(12288)    // Duration
	write_short(12288)    // Hold time
	write_short(FadeType)    //
	write_byte (red)        // Red
	write_byte (0)    // Green
	write_byte (blue)        // Blue
	write_byte (alpha)    // Alpha
	message_end()
}

public CheckForDeads()
{
	for (new id = 1; id<=get_maxplayers(); id++)
	{
		if (!is_user_connected(id))
			continue;
		SetTask(id);
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
