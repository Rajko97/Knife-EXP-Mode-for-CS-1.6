#include <amxmodx> 
#include <fakemeta> 
#include <fun>
#include <nvault>
#include <hamsandwich> 

//#define SERVER 	  "176.57.188.24:27040" //explosion Knife Arena
#define DATE 	  "15.1.2016" 		//Datum kada istice plugin

#define SCORE_NONE    0
#define SCORE_DEAD    (1 << 0)
#define SCORE_BOMB    (1 << 1)
#define SCORE_VIP     (1 << 2)

#define is_user_vip(%1) (get_user_flags(%1) & ADMIN_LEVEL_A)

#define DEFAULT_MAXSPEED 250.0

new Model[33][32];

new MuskiModel[] = "muski";
new ZenskiModel[] = "zenski";

new bool:double_jump[33];

new bool:vip_jump[33];
new bool:vip_speed[33];
new bool:vip_model[33];
new bool:vip_score[33];
new bool:vip_chat[33];
new bool:vip_respawn[33];
new bool:respawned[33];
new vault;

new g_msg_saytext;

new cvar_chat_prefix;

public plugin_precache() 
{ 
	precache_model("models/player/muski/muski.mdl"); 
	precache_model("models/player/zenski/zenski.mdl");
	precache_sound("EXP/select.wav");
	precache_sound("EXP/deny.wav");
} 

public plugin_init() 
{
	register_plugin("VIP", "1.1", "Rajk0");
	
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
		set_fail_state("Failed to load models");
	#endif
	register_dictionary("EXP_VipSettings.txt");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	RegisterHam(Ham_Killed, "player", "PlayerKilled", 1);
	
	register_forward(FM_CmdStart, "CmdStart");
	register_forward(FM_SetClientKeyValue, "SetKeyValue");
	
	register_clcmd("say /vips", "VipSettings");
	register_clcmd("say_team /vips", "VipSettings");
	
	g_msg_saytext = get_user_msgid("SayText");
	
	register_message(get_user_msgid("ClCorpse"), "ClCorpse");
	register_message(get_user_msgid("ScoreAttrib"), "MessageScoreAttrib");
	register_message(g_msg_saytext,"handleSayText");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");  
	
	vault = nvault_open("EXPVipUserSettings");
	
	cvar_chat_prefix = register_cvar("knife_chat_prefix", "!y[!tExplosion !gKnife Arena!y]:");
} 

public client_putinserver(id) 
{ 
	Model[id][0] = '^0';
	if(is_user_vip(id))
		UcitajVIPa(id);
	else
	{
		vip_speed[id] = false;
		vip_jump[id] = false;
		vip_model[id] = false;
		vip_score[id] = false;
		vip_chat[id] = false;
	}
}

public UcitajVIPa(id)
{
	new VaultKey[64], VaultData[64], AuthID[33], VipDATA[6][2];
	
	get_user_authid(id, AuthID, charsmax(AuthID));
	formatex(VaultKey, charsmax(VaultKey), "%s-vips-settings", AuthID);
	
	nvault_get(vault, VaultKey, VaultData, charsmax(VaultData))
	replace_all(VaultData, charsmax(VaultData), "#", " ");
	parse(VaultData, VipDATA[0], 1, VipDATA[1], 1, VipDATA[2], 1, VipDATA[3], 1, VipDATA[4], 1, VipDATA[5], 1)
	
	vip_speed[id] = str_to_num(VipDATA[0])==1;
	vip_jump[id] = str_to_num(VipDATA[1])==1;
	vip_model[id] = str_to_num(VipDATA[2])==1;
	vip_score[id] = str_to_num(VipDATA[3])==1;
	vip_chat[id] = str_to_num(VipDATA[4])==1;
	vip_respawn[id] = str_to_num(VipDATA[5])==1;
}

public SacuvajVIPa(id)
{
	new VaultKey[64], VaultData[64], AuthID[33], DATA[6];
	DATA[0] = vip_speed[id];
	DATA[1] = vip_jump[id];
	DATA[2] = vip_model[id];
	DATA[3] = vip_score[id];
	DATA[4] = vip_chat[id];
	DATA[5] = vip_respawn[id];
	get_user_authid(id, AuthID, charsmax(AuthID));
	formatex(VaultKey, charsmax(VaultKey), "%s-vips-settings", AuthID);
	formatex(VaultData, charsmax(VaultData), "#%i#%i#%i#%i#%i%i",DATA[0], DATA[1], DATA[2], DATA[3], DATA[4], DATA[5]);
	nvault_set(vault, VaultKey, VaultData);
}

public VipSettings(id)
{
	if(!is_user_vip(id))
	{
		PrintChat(id, "%L",id, "CHAT_VIPS_ONLY");
		client_cmd(id, "spk EXP/deny.wav");
		return PLUGIN_CONTINUE;
	}
	new item[64], status_on[33], status_off[33];

	formatex(status_on, charsmax(status_on), "\d[\r%L\d]",id, "MENU_ON");
	formatex(status_off, charsmax(status_off), "\d[%L]",id, "MENU_OFF");
	
	formatex(item, charsmax(item), "\w[\rExplosion\y VIP\w]\r %L\w:",id, "MENU_SETTINGS");
	new menu = menu_create(item, "VipSettings_Handler");
	
	formatex(item, charsmax(item), "\y%L\w: %s",id, "MENU_SPEED",vip_speed[id]?status_on:status_off);
	menu_additem(menu, item);
	formatex(item, charsmax(item), "\y%L\w: %s",id, "MENU_JUMP", vip_jump[id]?status_on:status_off);
	menu_additem(menu, item);
	formatex(item, charsmax(item), "\y%L\w: %s",id, "MENU_MODEL",vip_model[id]?status_on:status_off);
	menu_additem(menu, item);
	formatex(item, charsmax(item), "\y%L\w: %s",id, "MENU_SCORE", vip_score[id]?status_on:status_off);
	menu_additem(menu, item);
	formatex(item, charsmax(item), "\y%L\w: %s",id, "MENU_CHAT",vip_chat[id]?status_on:status_off);
	menu_additem(menu, item);
	formatex(item, charsmax(item), "\y%L\w: %s",id, "MENU_RESPAWN",vip_respawn[id]?status_on:status_off);
	menu_additem(menu, item);
	formatex(item, charsmax(item), "\r%L", id, "MENU_CLOSE");
	menu_setprop(menu, MPROP_EXITNAME, item);
	menu_display(id, menu);
	client_cmd(id, "spk EXP/select.wav");
	return PLUGIN_CONTINUE;
}

public VipSettings_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		client_cmd(id, "spk EXP/deny.wav");
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	item++;
	switch(item)
	{
		case 1: vip_speed[id] = !vip_speed[id];
		case 2: vip_jump[id] = !vip_jump[id];
		case 3: vip_model[id] = !vip_model[id];
		case 4: vip_score[id] = !vip_score[id]
		case 5: vip_chat[id] = !vip_chat[id];
		case 6: vip_respawn[id] = !vip_respawn[id];
	}
	PlayerSpawn(id);
	SacuvajVIPa(id);
	VipSettings(id);
	return PLUGIN_CONTINUE;
}

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id) || !is_user_vip(id) || !vip_jump[id])
		return FMRES_IGNORED;
	
	new button = get_uc(uc_handle, UC_Buttons);
	new flags = pev(id, pev_flags);
	new oldbutton = pev(id, pev_oldbuttons);
	if((button & IN_JUMP) && !(flags & FL_ONGROUND) && !(oldbutton & IN_JUMP) && double_jump[id])
	{
		double_jump[id]=false;
		new Float:velocity[3];
		pev(id, pev_velocity,velocity);
		velocity[2] = random_float(265.0,285.0);
		set_pev(id, pev_velocity,velocity);
	}
	else if(flags & FL_ONGROUND)
		double_jump[id]=true;
		
	return FMRES_IGNORED;
}

public PlayerSpawn(id) 
{ 
	if(!is_user_vip(id) || !is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	if(!(get_user_flags(id) & ADMIN_RCON) && vip_model[id])
	{
		if(get_user_flags(id) & ADMIN_LEVEL_B)
			SetUserModel(id, ZenskiModel);
		else
			SetUserModel(id, MuskiModel);
		set_user_info(id, "model", Model[id]);
	}

	if (vip_speed[id])
		set_user_maxspeed(id, DEFAULT_MAXSPEED*1.1);
	else
		set_user_maxspeed(id, DEFAULT_MAXSPEED);
	return PLUGIN_CONTINUE;
} 

public PlayerKilled(id)
{
	if (is_user_vip(id) && vip_respawn[id] && !respawned[id])
	{
		respawned[id] = true;
		ExecuteHamB(Ham_CS_RoundRespawn, id);
	}
}

public NewRound()
{
	for (new id = 1; id <= get_maxplayers(); id++)
		respawned[id] = false;
}
public SetKeyValue(id, const InfoBuffer[], const Key[], const Value[]) 
{ 
	if(Model[id][0] && equal(Key, "model") && !equal(Value, Model[id]))
	{ 
		set_user_info(id, "model", Model[id]);
		return FMRES_SUPERCEDE;
	} 
	return FMRES_IGNORED;
} 
 
public ClCorpse() 
{ 
	new id = get_msg_arg_int(12); 
	if(Model[id][0]) 
		set_msg_arg_string(1, Model[id]);
} 

stock SetUserModel(id, sModelName[]) 
	return copy(Model[id], charsmax(Model), sModelName); 

public MessageScoreAttrib(iMsgID, iDest, iReceiver)
{
	new Player = get_msg_arg_int(1)
		
	if(is_user_connected(Player) && is_user_vip(Player) && vip_score[Player])
		set_msg_arg_int(2, ARG_BYTE, is_user_alive(Player)? SCORE_VIP: SCORE_DEAD)
}

public handleSayText()
{
	new id = get_msg_arg_int(1);
	
	if(!is_user_connected(id) || !is_user_vip(id) || !vip_chat[id])
		return PLUGIN_CONTINUE;
	
	new szTmp[256], szTmp2[256];
	get_msg_arg_string(2, szTmp, charsmax(szTmp));
	new szPrefix[33];
	formatex(szPrefix, charsmax(szPrefix), "^4[^3VIP^4]");
	if(!equal(szTmp,"#Cstrike_Chat_All"))
	{
		add(szTmp2, charsmax(szTmp2), szPrefix);
		add(szTmp2,charsmax(szTmp2)," ");
		add(szTmp2,charsmax(szTmp2),szTmp);
	}
	else
	{
		add(szTmp2,charsmax(szTmp2),szPrefix);
		add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 :  %s2");
	}
	
	set_msg_arg_string(2, szTmp2);
	return PLUGIN_CONTINUE;
}

stock PrintChat(const id, const input[], any:...) 
{
	static prefix[64], message[191];
	get_pcvar_string(cvar_chat_prefix, prefix, charsmax(prefix));
	new len = formatex(message, charsmax(message), "^4%s^1 ", prefix);
	vformat(message[len], 190-len, input, 3);
	
	replace_all(message, charsmax(message), "!g", "^4");
	replace_all(message, charsmax(message), "!y", "^1");
	replace_all(message, charsmax(message), "!t", "^3");
	replace_all(message, charsmax(message), "!n", "^1");
	
	message_begin(MSG_ONE_UNRELIABLE, g_msg_saytext, _, id);
	write_byte(id);
	write_string(message);
	message_end();
}

public plugin_end()
	nvault_close(vault);
