/*    	  -=[ PLUGIN INFO ]=-	    */

#define TITLE	  "EXP Knife Mode"
#define VERSION	  "1.0.0b"
#define AUTHOR	  "Rajk0"
#define PUBLICVAR "EPGknfMOD"
//#define SERVER 	  "176.57.188.24:27040" //explosion knife arena
#define DATE 	  "15.1.2016" 		//Datum kada istice plugin
#define SHOP	  "on"
/*==================================*/

#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <hamsandwich>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <engine>

#define MAX_SLOTS 32
#define MAX_KNIFES 33
#define MAX_CHARS  33
#define TaskSpawn 64
#define TaskInfo 99
#define MenuKeys MENU_KEY_1|MENU_KEY_2
#define	FL_WATERJUMP	(1<<11)	// player jumping out of water
#define	FL_ONGROUND	(1<<9)	// At rest / on the ground
#define is_user_vip(%1) (get_user_flags(%1) & ADMIN_LEVEL_A)

#define KNIFE_NONE 0
#define KNIFE_DEFAULT 1

new vault;

new SyncHudObj[2];

enum  Cvars {
	MoneyFKill = 0,
	MoneyFWinR,
	LevelsON,
	LevelRATIO,
	HappyHour,
	HappyHourStart,
	HappyHourStop,
	LoadLastUsedKnife,
	ChangeDelay,
	HUDRefreshRate,
	ChatPrefix,
	HideCommandInput,
	RestoreHP,
	AdminLog
};
new cvar_pointer[Cvars];

new knife_names[MAX_KNIFES+2][MAX_CHARS];
new file_names[MAX_KNIFES][MAX_CHARS];
new knife_price[MAX_KNIFES+2];
new bool: knife_premium[MAX_KNIFES+2];
new bool: p_model_exist[MAX_KNIFES+2];
new knifes_loaded;

new g_msg_bartime;
new g_msg_saytext;
new g_msg_screenfade;
new g_msg_money;

new user_knife[MAX_SLOTS+1];
new user_new_knife[MAX_SLOTS+1];
new user_would_buy[MAX_SLOTS+1];
new bool:user_unlocked_knifes[MAX_SLOTS+1][MAX_KNIFES+2];
new bool:user_using_trial[MAX_SLOTS+1];
new user_max_points[MAX_SLOTS+1];
new user_left_points[MAX_SLOTS+1];
new user_killstreak[MAX_SLOTS+1];
new user_total_unlockeds[MAX_SLOTS+1];
new bool:user_hud[MAX_SLOTS+1];
new user_current_menu[MAX_SLOTS+1];
new user_is_paying_to[MAX_SLOTS+1];
new user_is_paying_amount[MAX_SLOTS+1];

new user_level[MAX_SLOTS+1] = 1;
new user_xp[MAX_SLOTS+1];
new user_xpForLVL[MAX_SLOTS+1];

new AuthID[MAX_SLOTS+1][35];
new PlayerName[MAX_SLOTS+1][35];

new bool:is_happy_hour;

enum Emith { 
	Select = 0,
	LevelUP,
	Exit,
	Cash 
};

new const sound[Emith][] = {"EXP/select.wav","EXP/level_up.wav",  "EXP/deny.wav","EXP/cash.wav"};	

#if defined SHOP
new bool:g_respawned[33] = false; 
new g_double_jump[33] = 0;
new bool:double_jump[33] = false;
new g_autobhop[33] = 0;
new bool:g_double_exp[33] = false;
new p_respawn, p_jump, p_bhop, p_exp, p_speed;
#endif

public plugin_init() 
{
	register_plugin(TITLE, VERSION, AUTHOR);
	register_cvar(PUBLICVAR, VERSION, FCVAR_SERVER|FCVAR_SPONLY);
	
	#if defined SERVER
	/*new IP[64], PORT[16];
	get_cvar_string( "ip", IP, charsmax(IP));
	get_cvar_string("port", PORT, charsmax(PORT));
	add(IP, charsmax(IP), ":");
	add(IP, charsmax(IP), PORT);*/
	new IP[64];
	get_user_ip(0, IP, charsmax(IP));
	if(!equal(SERVER, IP) && containi(IP, "192.168" ) == -1)
		set_fail_state("Failed to load models");
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
	
	RegisterHam(Ham_Killed, "player", "PlayerKilled", 1);
	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	
	register_event("CurWeapon", "CurWeapon", "be", "1=1");
	register_event("SendAudio", "PobedaTerro" , "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "PobedaCT", "a", "2&%!MRAD_ctwin");
	
	register_clcmd("say", "SayHandle");
	register_clcmd("say_team", "SayHandle");
	register_clcmd("money", "InputMoney");
	
	register_concmd("knife_give_money", "CmdAddPoints", ADMIN_RCON, "<nick> <money>");
	register_concmd("knife_setlvl", "CmdSetLvl", ADMIN_RCON, "<nick> <level>")
	
	register_dictionary("EXP_KnifeMode.txt");
	
	vault = nvault_open("EXPKnifeMode");
	
	g_msg_bartime	= get_user_msgid("BarTime");
	g_msg_saytext	= get_user_msgid("SayText");
	g_msg_screenfade= get_user_msgid("ScreenFade");
	g_msg_money	= get_user_msgid("Money");
	
	SyncHudObj[0] = CreateHudSyncObj();
	SyncHudObj[1] = CreateHudSyncObj();
	
	register_menucmd(register_menuid("BuyMenu"), MenuKeys, "AskToBuyHandle");
	register_menucmd(register_menuid("TrialMenu"), MenuKeys, "AskForTrialHandle");
	
	register_message(g_msg_money, "MoneyChanged");
	register_message(g_msg_saytext,"handleSayText");
	
	new const cvar_name[Cvars][] = 
	{	"knife_kill_money", "knife_win_money",
		"knife_levels_on", "knife_level_ratio",
		"knife_happy_hour", "knife_happy_hour_start",
		"knife_happy_hour_stop", "knife_instant_load",
		"knife_change_delay", "knife_hud_rate",
		"knife_chat_prefix", "knife_hide_command_input",
		"knife_restore_hp", "knife_admin_log"
	};
	new const cvar_default[Cvars][] = 
	{		"250",	"50",
		"1", 	"100",
		"0", 	"22",
		"10", 	"1",
		"6.0", "1.0",
		"!y[!tExplosion !gKnife Arena!y]:", "1",
		"1", "1" 
	};
	
	for(new Cvars:cvar =  MoneyFKill; cvar < Cvars; cvar++)
		cvar_pointer[cvar] = register_cvar(cvar_name[cvar], cvar_default[cvar]);
	
	new const cfg_file[] = "addons/amxmodx/configs/EXP/settings.cfg";
	if(!file_exists(cfg_file))
	{
		new const cvar_description[Cvars][] = 
		{	"CD_KILL_M",	"CD_WIN_M",
			"CD_LEVELS",	"CD_LVLRATIO",
			"CD_HAPPY_HOUR", "CD_START",
			"CD_STOP", "CD_INST_LOAD",
			"CD_DELAY", "CD_HUD_RATE",
			"CD_PREFIX", "CD_HIDE_INPUT",
			"CD_RESTORE_HP", "CD_LOG" 
		};
		new line[128];
		for(new Cvars:cvar = MoneyFKill; cvar < Cvars; cvar++)
		{
			formatex(line, charsmax(line), "%s ^"%s^" // %L^n", cvar_name[cvar], cvar_default[cvar], LANG_SERVER, cvar_description[cvar]);
			write_file(cfg_file, line);
		}
	}
	
	server_cmd("exec %s", cfg_file);
	set_task (60.0, "HappyHourCheck",_,_,_,"b");
	set_task (120.0,"Advertisement",_,_,_,"b");
	
	#if defined SHOP
	register_forward(FM_CmdStart, "CmdStart");
	
	register_clcmd("say /shop", "ShopMenu");
	register_clcmd("say_team /shop", "ShopMenu");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");  
	
	p_respawn = register_cvar("shop_respawn_cost", "40000");
	p_jump = register_cvar("shop_double_jump_cost", "10000");
	p_bhop = register_cvar("shop_auto_bhop_cost", "25000");
	p_exp = register_cvar("shop_double_exp_cost", "30000");
	p_speed = register_cvar("auto_bhop_speed_limit", "400.0");
	#endif
}

public plugin_precache() 
{
	load_knifes_cfg();
	
	precache_model("models/v_knife.mdl");
	precache_model("models/p_knife.mdl");
	
	new path[64]; 
	
	for(new i = 0; i <= knifes_loaded-2; i++)
	{
		formatex(path, charsmax(path), "models/EXP/v_%s.mdl", file_names[i]);
		precache_model(path);
		
		if (p_model_exist[i])
		{
			formatex(path, charsmax(path), "models/EXP/p_%s.mdl", file_names[i]);
			if(file_exists(path))
				precache_model(path);
		}
	}
	
	for (new Emith:i = Select; i<Emith; i++)
		precache_sound(sound[i]);
	
	if(!dir_exists("addons\amxmodx\configs\EXP\logs"))
	{
		mkdir("addons\amxmodx\configs\EXP");
		mkdir("addons\amxmodx\configs\EXP\logs");
	}
}

public load_knifes_cfg()
{
	knife_names[0]="KNIFE_NONE"; knife_price[0]= 0;
	knife_names[1]="KNIFE_DEFAULT"; knife_price[1] = 0;
	knifes_loaded = 1;
	
	new const file[42] = "addons\amxmodx\configs\EXP\knifes.cfg";
	
	if (!file_exists(file))
	{
		log_error(AMX_ERR_NOTFOUND, "Can't load knifes becaus file 'knifes.cfg' not found!");
		return PLUGIN_CONTINUE;
	}
	
	new line, txtlen;
	new text[64],  arg[4][16];
	
	while (read_file(file, line, text, charsmax(text), txtlen) != 0) 
	{
		line++;
		
		if (!txtlen  ||  text[0] == ';') 
			continue;
		
		if (knifes_loaded == MAX_KNIFES)
		{
			log_error(AMX_ERR_BOUNDS, "Reached maximum ammount of loading knifes!");
			break;
		}
		knifes_loaded++;
		parse(text,arg[0],charsmax(arg[]),arg[1],charsmax(arg[]),arg[2],charsmax(arg[]), arg[3], charsmax(arg[]));
		knife_names[knifes_loaded] = arg[0];
		file_names[knifes_loaded-2]= arg[1];
		knife_price[knifes_loaded] = str_to_num(arg[2]);
		if (containi(arg[3], "da") != -1)
			knife_premium[knifes_loaded] = true;
		else
			knife_premium[knifes_loaded] = false;
		new szVFile[64], szPFile[64];
		formatex(szVFile, 63, "models/EXP/v_%s.mdl", arg[1]);
		if(!file_exists(szVFile))
		{
			knifes_loaded--;
			log_error(AMX_ERR_NOTFOUND, "Model %s not found!",szVFile);
		}
		else if (file_exists(szPFile))
			p_model_exist[knifes_loaded-2] = true;
		else	
			p_model_exist[knifes_loaded-2] = false;
	}
	return PLUGIN_CONTINUE;
}

public ChooseFraction(id)
{
	static szText[128];
	formatex(szText, charsmax(szText), "\w[\rExplosion\w]\r %L\w", id, "MENU_TITLE");
	new menu = menu_create(szText, "Fraction_Handle");
	formatex(szText, charsmax(szText), "\y%L", id, "MENU_LABEL_POCKET");
	menu_additem(menu, szText);
	formatex(szText, charsmax(szText), "\y%L",id,"MENU_LABEL_MARKET");
	menu_additem(menu, szText);
	formatex(szText, charsmax(szText), "\y%L",id, "MENU_LABEL_VIP");
	menu_additem(menu, szText);
	if (user_knife[id] == KNIFE_NONE  && !task_exists(id+TaskSpawn))
		menu_setprop (menu, MPROP_EXIT, MEXIT_NEVER );
	else
	{
		formatex(szText, charsmax(szText), "\y%L",id, "MENU_EXIT", PriceToString(user_left_points[id]));
		menu_setprop(menu, MPROP_EXITNAME, szText);
	}
	menu_display(id, menu);
}
public Fraction_Handle(id, menu2, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu2);
		client_cmd(id, "spk ^"%s", sound[Exit]);
		return PLUGIN_CONTINUE;
	}
	static szText[128];
	formatex(szText, charsmax(szText), "\w[\rExplosion\w]\r %L\w", id, "MENU_TITLE");
	new menu = menu_create(szText, "KnifeMenu_Handle");
	new vip_knifes;
	for (new i = 1; i<=knifes_loaded; i++)
		if (knife_premium[i])
			vip_knifes++;
	switch(item)
	{
		case 0: // dzep
		{
			client_cmd(id, "spk ^"%s", sound[Select]);
			new len;
			for (new i = 1; i <= knifes_loaded; i++)
			{
				len = 0;
				if ((user_unlocked_knifes[id][i] || knife_price[i] == 0))
				{
					if (knife_premium[i])
						len = formatex(szText, charsmax(szText), "\y%L \w[\rVIP\w] ", id, knife_names[i]);
					else
						len = formatex(szText, charsmax(szText), "\y%L ", id, knife_names[i]);
					if (get_pcvar_num(cvar_pointer[LevelsON]))
					{
						LoadLevels(id, i);
						len+=formatex(szText[len], charsmax(szText), "\r[\wLevel: \y%i\r]", user_level[id]);
					}
					if (!get_pcvar_num(cvar_pointer[LevelsON]))
					{
						if (!knife_price[i])
							formatex(szText[len], charsmax(szText)-len, "\r[\d%L\r]", id, "MENU_FREE");
						else
							formatex(szText[len], charsmax(szText)-len, "\r[\d%L $%s\r]",id, "MENU_BOUGHT", PriceToString(knife_price[i]));
					}
					menu_additem(menu, szText);
				}
			}
			LoadLevels(id, user_knife[id])
		}
		case 1: // market
		{
			client_cmd(id, "spk ^"%s", sound[Cash]);
			if (knifes_loaded-vip_knifes-user_total_unlockeds[id] >0) 
			{
				//new count = 0; new len;
				new len;
				for (new i = 1; i<=knifes_loaded; i++)
					if((!user_unlocked_knifes[id][i] && knife_price[i] > 0) && !knife_premium[i])
					{
						len = formatex(szText, charsmax(szText), "\y%L ", id, knife_names[i]);
						if (user_left_points[id]>=knife_price[i])
							formatex(szText[len], charsmax(szText)-len,"\r[\w$%s\r]", PriceToString(knife_price[i]));
						else
							formatex(szText[len], charsmax(szText)-len, "\r[\d$%s\r]", PriceToString(knife_price[i]));
						menu_additem(menu, szText);
						//count++;
						//if (count>=knifes_loaded-user_total_unlockeds[id]-vip_knifes)
						///	break;
					}
			}
			else
			{
				PrintChat(id, "%L", id, "CHAT_EMPTY_MARKET");
				ChooseFraction(id);
				client_cmd(id, "spk ^"%s", sound[Exit]);
				return PLUGIN_CONTINUE;
			}
		}
		case 2: //vip
		{
			client_cmd(id, "spk ^"%s", sound[Select]);
			new count = 0; new len;
			for (new i=1; i<=knifes_loaded; i++)
				if(knife_premium[i] && !user_unlocked_knifes[id][i])
				{
					len = formatex(szText, charsmax(szText), "\y%L",id, knife_names[i]);
					if (!used_trial(id, i) && !is_user_vip(id))
						len+=formatex(szText[len], charsmax(szText)-len, "\w[\rVIP \w-\y%L\w]",id, "MENU_TEST");
					else
					{
						if (user_left_points[id]>=knife_price[i])
							len+=formatex(szText[len], charsmax(szText)-len,"\r[\w$%s\r]", PriceToString(knife_price[i]));
						else
							len+=formatex(szText[len], charsmax(szText)-len, "\r[\d$%s\r]", PriceToString(knife_price[i]));
					
						if (get_pcvar_num(cvar_pointer[LevelsON]))
						{
							LoadLevels(id, i);
							if(is_user_vip(id))
								len+=formatex(szText[len], charsmax(szText)-len, "\d[\rV\d.\rI\d.\rP\d.]\r[\wLevel: \y%i\r]", user_level[id]);
							else
								len+=formatex(szText[len], charsmax(szText)-len, "\w[\rV\w.\rI\w.\rP\w.]\w[\dLevel: \w%i\d]", user_level[id]);
						}
						else
							add(szText, charsmax(szText), is_user_vip(id)?"\d[\rV\d.\rI\d.\rP\d.]":"\w[\rV\w.\rI\w.\rP\w.]");
					}
					menu_additem(menu, szText);
					count++;
					if (count>=vip_knifes)
						break;
				}
			LoadLevels(id, user_knife[id]);
		}
	}
	user_current_menu[id] = item;
	formatex(szText, charsmax(szText), "\y%L",id, "MENU_NEXT"); 
	menu_setprop(menu, MPROP_NEXTNAME, szText);
	formatex(szText, charsmax(szText), "\y%L",id, "MENU_BACK");
	menu_setprop(menu, MPROP_BACKNAME, szText);
	formatex(szText, charsmax(szText), "\y%L",id, "MENU_EXIT", PriceToString(user_left_points[id]));
	menu_setprop(menu, MPROP_EXITNAME, szText);
	menu_display(id, menu);
	return PLUGIN_CONTINUE;
}

public KnifeMenu_Handle(id, menu, item)
{
	
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		ChooseFraction(id);
		client_cmd(id, "spk ^"%s", sound[Exit]);
		return PLUGIN_CONTINUE;
	}
	item++;
	
	new count = 0; 
	for(new i=1; i<= knifes_loaded; i++) 
	{
		switch (user_current_menu[id])
		{
			case 0:
				if (user_unlocked_knifes[id][i] || knife_price[i] == 0)
					count++;
			case 1:
				if((!user_unlocked_knifes[id][i] && knife_price[i] > 0) && !knife_premium[i])
					count++;
			case 2:
				if (knife_premium[i] && !user_unlocked_knifes[id][i])
					count++;
		}
		if(count == item) 
		{ 
			item = i; 
			break; 
		} 
	} 
	
	if(user_new_knife[id] != KNIFE_NONE && is_user_alive(id)) 
	{
		client_cmd(id, "spk ^"%s",sound[Exit]);
		menu_destroy(menu);
		PrintChat(id, "%L", id, "CHAT_CHANGE_PROGRES");
		return PLUGIN_CONTINUE;
	}
	if(item == user_knife[id])
	{
		client_cmd(id, "spk ^"%s",sound[Exit]);
		menu_display(id, menu);
		PrintChat(id, "%L", id, "CHAT_ALREADY_HAVE");
		return PLUGIN_CONTINUE;
	}
	
	if(knife_premium[item] && !used_trial(id, item) && !is_user_vip(id))
	{
		user_would_buy[id]=item;
		AskForTrial(id);
		client_cmd(id, "spk ^"%s",sound[Select]);
		return PLUGIN_CONTINUE;
	}
	if(knife_premium[item] && !is_user_vip(id))
	{
		PrintChat(id, "%L",id, "CHAT_ONLY_VIPS");
		menu_display(id, menu);
		client_cmd(id, "spk ^"%s",sound[Exit]);
		return PLUGIN_CONTINUE;
	}
	if (!user_unlocked_knifes[id][item] && knife_price[item] != 0)
	{
		if (user_left_points[id] >= knife_price[item])
		{
			user_would_buy[id]=item;
			client_cmd(id, "spk ^"%s",sound[Cash]);
			AskToBuyMenu(id);
			return PLUGIN_CONTINUE;
		}
		menu_display(id, menu);
		PrintChat(id, "%L", id, "CHAT_DONT_HAVE_MONEY", PriceToString(knife_price[item]-user_left_points[id]));
		client_cmd(id, "spk ^"%s",sound[Exit]);
		return PLUGIN_CONTINUE;
	}
	
	if(user_knife[id] > KNIFE_NONE)
	{
		user_new_knife[id] = item;
		
		if(is_user_alive(id)) 
		{
			//AskToChangeNow
			SaveLevels(id);
			user_knife[id] = KNIFE_NONE;
			LoadLevels(id, KNIFE_NONE);
			strip_user_weapons(id);
			SetTask(id);
			PrintChat(id, "%L", id, "CHAT_WILL_BE_CHANGED");
		}
		else 
			PrintChat(id, "%L", id, "CHAT_WILL_NEXT_ROUND");
	}
	else 
	{
		if(is_user_alive(id))
		{
			strip_user_weapons(id);
			give_item(id, "weapon_knife");
		}
		SaveLevels(id);
		user_knife[id] = item;
		LoadLevels(id, item);
	}
	client_cmd(id, "spk ^"%s",sound[Select]);
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public AskToBuyMenu(id)
{
	static MenuBody[128];
	new len = formatex(MenuBody, charsmax(MenuBody),"\y%L^n^n",id, "MENU_QUESTION",id, knife_names[user_would_buy[id]], PriceToString(knife_price[user_would_buy[id]]));
	if (user_left_points[id]<knife_price[user_would_buy[id]])
		len+=formatex(MenuBody[len], charsmax(MenuBody)-len, "\d1. %L^n",id, "MENU_LABEL_YES");
	else
		len+=formatex(MenuBody[len], charsmax(MenuBody)-len, "\r1. \y%L^n",id, "MENU_LABEL_YES");
	len+=formatex(MenuBody[len], charsmax(MenuBody)-len, "\r2. \y%L^n",id, "MENU_LABEL_NO");
	show_menu(id, MenuKeys , MenuBody, -1, "BuyMenu");
}
public AskToBuyHandle(id, key)
{
	switch(key)
	{
		case 0:
		{
			if (user_left_points[id]<knife_price[user_would_buy[id]])
			{
				PrintChat(id, "%L", id, "CHAT_DONT_HAVE_MONEY", PriceToString(knife_price[user_would_buy[id]]-user_left_points[id]));
				client_cmd(id, "spk ^"%s",sound[Exit]);
				return PLUGIN_CONTINUE;
			}
			if (is_user_alive(id))
			{
				strip_user_weapons(id);
				SetTask(id);
			}
			SaveLevels(id);
			user_left_points[id]-=knife_price[user_would_buy[id]];
			user_unlocked_knifes[id][user_would_buy[id]]=true;
			user_new_knife[id]=user_would_buy[id];
			user_knife[id]=KNIFE_NONE;
			LoadLevels(id, KNIFE_NONE);
			user_total_unlockeds[id]++;
			cs_set_user_money(id, user_left_points[id], 1);
			PrintChat(id, "%L",id, "CHAT_SUCCESFULL_BUY",id, knife_names[user_would_buy[id]], PriceToString(knife_price[user_would_buy[id]]));
			SaveData(id, 1);
			client_cmd(id, "spk ^"%s",sound[LevelUP]);
		}
		case 1:
		{
			if (knife_premium[user_would_buy[id]])
				Fraction_Handle(id, 0, 2);
			else
				Fraction_Handle(id, 0, 1);
			user_would_buy[id]=0;
			client_cmd(id, "spk ^"%s",sound[Exit]);
		}
	}
	return PLUGIN_CONTINUE;
}

public AskForTrial(id)
{
	static MenuBody[128];
	new len = formatex(MenuBody, charsmax(MenuBody),"\y%L^n^n",id, "MENU_TRIAL", id, knife_names[user_would_buy[id]]);
	len+=formatex(MenuBody[len], charsmax(MenuBody)-len, "\r1. \y%L^n",id, "MENU_TEST_NOW");
	len+=formatex(MenuBody[len], charsmax(MenuBody)-len, "\r2. \y%L^n",id ,"MENU_CANCEL");
	show_menu(id, MenuKeys , MenuBody, -1, "TrialMenu");
}

public AskForTrialHandle(id, key)
{
	key++
	switch(key)
	{
		case 1:
		{
			if (is_user_alive(id))
			{
				strip_user_weapons(id);
				SetTask(id);
				PrintChat(id, "%L", id, "CHAT_WILL_BE_CHANGED");
			}
			else 
				PrintChat(id, "%L", id, "CHAT_WILL_NEXT_ROUND");
			SaveLevels(id);
			user_using_trial[id] = true;
			user_knife[id] = KNIFE_NONE;
			user_new_knife[id] = user_would_buy[id];
			LoadLevels(id, KNIFE_NONE);
			client_cmd(id, "spk ^"%s",sound[LevelUP]);
			
		}
		case 2:
		{
			client_cmd(id, "spk ^"%s",sound[Exit]);
			Fraction_Handle(id,0,2);
		}
	}
	return PLUGIN_CONTINUE;
}

public CreatePayMenu(id)
{
	static item[64];
	formatex(item, charsmax(item), "\w[\rExplosion\w]\r %L", id, "MENU_PAY");
	new menu = menu_create(item, "PayMenu_Handler");
	if (!user_is_paying_to[id]) 
		formatex(item, charsmax(item), "\r%L\y %L",id, "MENU_PLAYER", id ,"MENU_CHOOSE_PLAYER");
	else
		formatex(item, charsmax(item), "\r%L\y %s", id, "MENU_PLAYER", PlayerName[user_is_paying_to[id]]);
	menu_additem(menu, item);
	
	if(!user_is_paying_amount[id])
		formatex(item, charsmax(item), "\r%L \y%L^n", id, "MENU_AMOUNT", id, "MENU_INPUT" );
	else
		formatex(item, charsmax(item), "\r%L \y%s^n", id , "MENU_AMOUNT", PriceToString(user_is_paying_amount[id]));
	menu_additem(menu, item);
	
	if(user_is_paying_to[id] && user_is_paying_amount[id])
		formatex(item, charsmax(item), "\y%L", id , "MENU_CONFIRM");
	else
		formatex(item, charsmax(item), "\d%L", id, "MENU_CONFIRM");
	menu_additem(menu, item);
	
	formatex(item, charsmax(item), "\y%L", id, "MENU_CANCEL2", PriceToString(user_left_points[id]));
	menu_setprop(menu, MPROP_EXITNAME, item);
	menu_display(id, menu);
}

public PayMenu_Handler(id, menu, item)
{
	switch(item)
	{
		case  0:
		{
			ChoosePlayer(id);
			client_cmd(id, "spk ^"%s", sound[Select]);
		}
		case 1:
		{
			CreatePayMenu(id);
			client_cmd(id,"messagemode money");
			client_cmd(id, "spk ^"%s", sound[Select]);
		}
		case 2:
		{
			if(!user_is_paying_to[id] &&  !user_is_paying_amount[id])
			{
				PrintChat(id, "%L", id, "CHAT_BOTH_ERROR");
				CreatePayMenu(id);
				client_cmd(id, "spk ^"%s", sound[Exit]);
				return PLUGIN_CONTINUE;
			}
			else if(!user_is_paying_to[id])
			{
				PrintChat(id, "%L", id, "CHAT_SELECT_PLAYER");
				CreatePayMenu(id);
				client_cmd(id, "spk ^"%s", sound[Exit]);
				return PLUGIN_CONTINUE;
			}
			else if(!user_is_paying_amount[id])
			{
				PrintChat(id, "%L",id, "CHAT_INPUT_AMOUNT");
				CreatePayMenu(id);
				client_cmd(id, "spk ^"%s", sound[Exit]);
				return PLUGIN_CONTINUE;
			}
			else if(user_is_paying_amount[id] > user_left_points[id])
			{
				PrintChat(id, "%L",id, "CHAT_NO_MONEY");
				CreatePayMenu(id);
				client_cmd(id, "spk ^"%s", sound[Exit]);
				return PLUGIN_CONTINUE;
			}
			new target = user_is_paying_to[id];
			new amount = user_is_paying_amount[id];
			user_left_points[id]-= amount;
			user_max_points[id]-= amount;
			cs_set_user_money(id, user_left_points[id], 1);
			client_cmd(id, "spk ^"%s", sound[LevelUP]);
			SaveData(id);
			user_left_points[target]+=amount;
			user_max_points[target]+=amount;
			cs_set_user_money(target, user_left_points[target], 1);
			client_cmd(target, "spk ^"%s", sound[Cash]);
			SaveData(target);
			CheckForNewUnlocks(target, amount);
			new Players[32], playerCount;
			get_players(Players, playerCount, "ch");
			for (new i=0; i<playerCount; i++)
				if (is_user_connected(Players[i]))
				{
					if (Players[i] != id && Players[i] != target)
						PrintChat(Players[i], "%L", Players[i], "CHAT_SOMEONE_PAID", PlayerName[id], PlayerName[target], PriceToString(amount));
					else if(Players[i] == id)
						PrintChat(Players[i], "%L", Players[i], "CHAT_YOU_SUC_PAID", PlayerName[target], PriceToString(amount));
					else if(Players[i] == target)
						PrintChat(Players[i], "%L", Players[i], "CHAT_YOU_GET_PAID",PlayerName[id], PriceToString(amount) );
				}
			user_is_paying_to[id]=0;
			user_is_paying_amount[id]=0;
		}
		/*case MENU_EXIT:
		{
			user_is_paying_to[id] = 0;
			user_is_paying_amount[id]=0;
			menu_destroy(menu);
			client_cmd(id, "spk ^"%s", sound[Exit]);
		}*/
	}
	return PLUGIN_CONTINUE;
}
	
public ChoosePlayer(id)
{
	new item[34], szUserId[32];
	new players[32], pnum, Player;

	formatex(item, charsmax(item), "\w[\rExplosion\w]\r %L",id, "MENU_CHOOSEPLAYER");
	new menu = menu_create(item, "ChoosePlayer_Handler");
	
	get_players(players, pnum, "ch"); 
	for(new i=0; i<pnum; i++)
	{
		if (players[i] == id)
			continue;
		Player = players[i];
		formatex(item, charsmax(item), "\y%s", PlayerName[Player]);
		formatex(szUserId, charsmax(szUserId), "%d", get_user_userid(Player));
		menu_additem(menu, item, szUserId, 0);
	} 
	formatex(item, charsmax(item), "\y%L",  id, "MENU_BACK");
	menu_setprop(menu, MPROP_BACKNAME, item);
	formatex(item, charsmax(item), "\y%L", id, "MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, item);
	formatex(item, charsmax(item), "\r%L",id, "MENU_CANCEL3");
	menu_setprop(menu, MPROP_EXITNAME, item);
	menu_display(id, menu); 
}

public ChoosePlayer_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		CreatePayMenu(id);
		client_cmd(id, "spk ^"%s",sound[Exit]);
		return PLUGIN_CONTINUE;
	}
	new szData[6], szName[64];
	new _access, item_callback;
	menu_item_getinfo(menu, item, _access, szData, charsmax(szData), szName, charsmax(szName), item_callback);
	new userid = str_to_num(szData);
	new player = find_player("k", userid); 
	if(!player)
	{
		menu_destroy(menu);
		client_cmd(id, "spk EXP/deny.wav");
		PrintChat(id, "%L",id, "CHAT_PLAYER_DISCON");
		ChoosePlayer(id)
		return PLUGIN_CONTINUE;
	}
	user_is_paying_to[id] = player;
			
	client_cmd(id, "spk ^"%s",sound[Select]);
	menu_destroy(menu);
	CreatePayMenu(id);
	return PLUGIN_CONTINUE;
}

public InputMoney(id)
{
	new input[64];
	read_args(input, charsmax(input));
	remove_quotes(input);
	user_is_paying_amount[id] = str_to_num(input);
	
	if (!user_is_paying_amount[id])
	{
		PrintChat(id, "%L",id, "CHAT_INPUT_AMOUNT");
		CreatePayMenu(id);
		client_cmd(id, "spk ^"%s",sound[Exit]);
		return PLUGIN_CONTINUE;
	}
	if (user_is_paying_amount[id] > user_left_points[id])
	{
		PrintChat(id, "%L",id, "CHAT_NO_MONEY");
		user_is_paying_amount[id] = user_left_points[id];
		CreatePayMenu(id);
		client_cmd(id, "spk ^"%s",sound[Select]);
		return PLUGIN_CONTINUE;
	}
	if (user_is_paying_amount[id] < 0)
	{
		user_is_paying_amount[id] = 0;
		CreatePayMenu(id);
		PrintChat(id, "%L",id, "CHAT_MINUS_MONEY");
		client_cmd(id, "spk ^"%s", sound[Exit]);
		return PLUGIN_CONTINUE;
	}
	client_cmd(id, "spk ^"%s", sound[Select]);
	CreatePayMenu(id);
	return PLUGIN_CONTINUE;
}

public SaveTrial(id, knife)
{
	new VaultKey[64];
	formatex(VaultKey,  charsmax(VaultKey),"%s-%s-trial", AuthID[id], knife_names[knife]);
	nvault_set(vault, VaultKey, "1");
}

public used_trial(id, knife)
{
	new VaultKey[64], VaultData[2], trial;
	formatex(VaultKey,  charsmax(VaultKey),"%s-%s-trial", AuthID[id], knife_names[knife]);
	nvault_get(vault, VaultKey, VaultData, charsmax(VaultData));
	trial = str_to_num(VaultData);
	return trial;
}

public SaveLevels(id)
{
	new VaultKey[64], VaultData[32];
	formatex(VaultKey, charsmax(VaultKey), "%s-%s-level", AuthID[id], knife_names[user_knife[id]]); 
	formatex(VaultData, charsmax(VaultData), "%i#%i",user_level[id], user_xp[id]);
	nvault_set(vault, VaultKey, VaultData);
}

public LoadLevels(id, knife)
{
	if (!knife)
	{
		user_xp[id]=0;
		user_level[id] = 1;
		return PLUGIN_CONTINUE;
	}
	
	new VaultKey[64], VaultData[32];
	new Data[2][16];
	formatex(VaultKey, charsmax(VaultKey), "%s-%s-level", AuthID[id], knife_names[knife]); 
	nvault_get(vault, VaultKey, VaultData, charsmax(VaultData));
	replace_all(VaultData, charsmax(VaultData), "#", " ");
	parse(VaultData, Data[0], charsmax(Data[]), Data[1], charsmax(Data[]));
	user_level[id] = str_to_num(Data[0])>0?str_to_num(Data[0]):1;
	user_xp[id] = str_to_num(Data[1]);
	if (knife == user_knife[id])
		user_xpForLVL[id] = ExpForLevel(user_level[id]);
	return PLUGIN_CONTINUE;
}

public PriceToString(price)
{
	new szPrice[12], len=0; // ovo moze jos sa while petjom
	if(price>=1000000)
	{
		len+=formatex(szPrice[len], charsmax(szPrice)-len, "%i.",price/1000000);
		price%=1000000;
		if (price < 100000) 
		{
			add(szPrice, charsmax(szPrice), "0");
			len++;
		}
		if (price < 10000)
		{
			add(szPrice, charsmax(szPrice), "0");
			len++;
		}
	}
	if(price>=1000)
	{
		len+=formatex(szPrice[len], charsmax(szPrice)-len, "%i.",price/1000);
		price%=1000;
		if (price < 100) 
		{
			add(szPrice, charsmax(szPrice), "0");
			len++;
		}
		if (price < 10)
		{
			add(szPrice, charsmax(szPrice), "0");
			len++;
		}
	}
	len+=formatex(szPrice[len], charsmax(szPrice)-len, "%i",price);
	return szPrice;
}

public client_putinserver(id)
{
	user_knife[id] = KNIFE_NONE;
	user_new_knife[id] = KNIFE_NONE;
	user_would_buy[id] = KNIFE_NONE;
	user_left_points[id] = 0;
	user_max_points[id] = 0;
	user_killstreak[id] = 0;
	user_total_unlockeds[id] = 1;
	user_hud[id] = true;
	user_using_trial[id]=false;
	user_level[id] = 1;
	user_xp[id] = 0;
	user_xpForLVL[id] = ExpForLevel(user_level[id]);
	user_is_paying_to[id]=0;
	user_is_paying_amount[id]=0;
	
	#if defined SHOP
	g_double_jump[id] = 0;
	g_autobhop[id] = 0;
	g_double_exp[id] = false;
	#endif
	
	for (new knife=2; knife<= knifes_loaded; knife++)
		user_unlocked_knifes[id][knife] = false;
	
	get_user_authid(id, AuthID[id], charsmax(AuthID));
	get_user_name(id, PlayerName[id], charsmax(PlayerName));
	LoadData(id);
	
	set_task(3.0, "DisplayInfo", id+TaskInfo);
}

public client_disconnect(id) 
{
	SaveLevels(id);
	SaveData(id);
	SetTask(id, 0);
	
	new Players[32], playerCount, user;
	get_players(Players, playerCount, "ch");
	for (new i=0; i<playerCount; i++)
	{
		user = Players[i];
		if (user_is_paying_to[user] == id)
		{
			PrintChat(user, "%L",id, "CHAT_PLAYER_DISCON");
			CreatePayMenu(user);
			user_is_paying_to[user] = 0;
		}
	}
}

public DisplayInfo(id)
{
	id-=TaskInfo;
	
	if(!is_user_connected(id) || !user_hud[id])
		return PLUGIN_CONTINUE;
	
	
	set_task(0.1, "DisplayInfo", id+TaskInfo);
	
	if(!is_user_alive(id))
	{
		new target = entity_get_int(id, EV_INT_iuser2);
		
		if(!target || target == id)
			return PLUGIN_CONTINUE;
	
		set_hudmessage(0, 255, 255, 0.59, 0.48, 0, 0.0, 0.3, 0.0, 0.0, -1);
		if (get_pcvar_num(cvar_pointer[LevelsON]))
		{
			new killsForLVL;
			new xp_for_kill = g_double_exp[target]?200:100;
			if ((user_xpForLVL[target]-user_xp[target])/xp_for_kill<1)
				killsForLVL = 1;
			else
				killsForLVL = (user_xpForLVL[target]-user_xp[target])/xp_for_kill;			
			ShowSyncHudMsg(id, SyncHudObj[0], "%L: %s^n%L: %L^n%L: %i^n%L: %s^n%L: %i^n%L: %i^n%L: %i/%i^n%L",
			id, "HUD_NAME", PlayerName[target],
			id, "HUD_KNIFE", id, knife_names[user_knife[target]],
			id, "HUD_EARNED", user_total_unlockeds[target],
			id, "HUD_MONEY", PriceToString(user_left_points[target]),
			id, "HUD_KS", user_killstreak[target],
			id, "HUD_LEVEL", user_level[target],
			id, "HUD_EXP", user_xp[target], user_xpForLVL[target],
			id, "HUD_KILLS", killsForLVL
			);
		}
		else
			ShowSyncHudMsg(id, SyncHudObj[0], "%L: %s^n%L: %L^n%L: %i^n%L: %s^n%L: %i",
		id, "HUD_NAME", PlayerName[target],
		id, "HUD_KNIFE", id, knife_names[user_knife[target]],
		id, "HUD_EARNED", user_total_unlockeds[target],
		id, "HUD_MONEY", PriceToString(user_left_points[target]),
		id, "HUD_KS", user_killstreak[target]
		);
		return PLUGIN_CONTINUE;
	}
	if(!user_knife[id])
		return PLUGIN_CONTINUE;
	
	set_hudmessage(255, 0, 0, 0.02, 0.17, 0, 0.0, 0.3, 0.0, 0.0, -1);
	if (get_pcvar_num(cvar_pointer[LevelsON]))
	{
		new killsForLVL;
		new xp_for_kill = g_double_exp[id]?200:100;
		if ((float(user_xpForLVL[id]-user_xp[id]))/float(xp_for_kill)<1)
			killsForLVL = 1;
		else
			killsForLVL = floatround(float(user_xpForLVL[id]-user_xp[id])/float(xp_for_kill));
		
		ShowSyncHudMsg(id, SyncHudObj[0], "%L: %L^n%L: %i^n%L: %i^n%L: %i^n%L: %i^n%L: %i/%i^n%L",
		id, "HUD_KNIFE",id, knife_names[user_knife[id]],
		id, "HUD_EARNED", user_total_unlockeds[id],
		id, "HUD_MONEY", user_left_points[id],
		id, "HUD_KS", user_killstreak[id],
		id, "HUD_LEVEL", user_level[id],
		id, "HUD_EXP", user_xp[id], user_xpForLVL[id],
		id, "HUD_KILLS", killsForLVL);
	}
	else
		ShowSyncHudMsg(id, SyncHudObj[0], "%L: %L^n%L: %i^n%L: %i^n%L: %i",
		id, "HUD_KNIFE",id, knife_names[user_knife[id]],
		id, "HUD_EARNED", user_total_unlockeds[id],
		id,"HUD_MONEY", user_left_points[id],
		id,"HUD_KS",user_killstreak[id]);
	return PLUGIN_CONTINUE;
}

public handleSayText()
{
	new id = get_msg_arg_int(1);
	
	if(!is_user_connected(id) || !get_pcvar_num(cvar_pointer[LevelsON]))
		return PLUGIN_CONTINUE;
	
	new szTmp[256], szTmp2[256];
	get_msg_arg_string(2, szTmp, charsmax(szTmp));
	
	new szPrefix[64];
	
	formatex(szPrefix, charsmax(szPrefix),"^x04[^x01Level:^x03 %d^x04]", user_level[id]);
	
	if(!equal(szTmp,"#Cstrike_Chat_All"))
	{
		add(szTmp2,charsmax(szTmp2),szPrefix);
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

public SayHandle(id)
{
	static cmd[3][25], argv[25]; 
	formatex(cmd[0], charsmax(cmd[]), "%L", id, "SAY_CMD_MENU");
	formatex(cmd[1], charsmax(cmd[]), "%L", id, "SAY_CMD_HUD");
	formatex(cmd[2], charsmax(cmd[]), "%L", id, "SAY_CMD_PAY"); 
	read_argv(1, argv, charsmax(argv)); 
	
	if(containi(argv, cmd[0]) == 0)
		ChooseFraction(id);
	else if(containi(argv, cmd[1]) == 0)
	{
		if (!task_exists(id+TaskInfo))
			set_task(1.0, "DisplayInfo", id+TaskInfo);
		user_hud[id]=!user_hud[id];
		user_hud[id]? PrintChat(id, "%L",id, "CHAT_HUD_ON"):PrintChat(id, "%L", id, "CHAT_HUD_OFF");
	}
	else if(containi(argv, cmd[2]) == 0)
	{
		user_is_paying_to[id] =0;
		user_is_paying_amount[id]=0;
		CreatePayMenu(id);
	}
	else
		return PLUGIN_CONTINUE;
	client_cmd(id, "spk ^"%s",sound[Select]);
	if (get_pcvar_num(cvar_pointer[HideCommandInput]) == 1)
		return PLUGIN_HANDLED_MAIN;
	return PLUGIN_CONTINUE;
}

public PlayerSpawn(id)
{
	if(id<TaskSpawn)
		user_killstreak[id] = 0;
	if(id>=TaskSpawn) 
		id-= TaskSpawn;
	
	SetTask(id, 0);
	if (is_user_alive(id))
		strip_user_weapons(id);
	
	if (!user_unlocked_knifes[id][user_knife[id]] && !user_using_trial[id] && user_knife[id] > KNIFE_DEFAULT)
	{
		PrintChat(id, "%L",id, "CHAT_TRIAL_END");
		client_cmd(id, "spk ^"%s",sound[Exit]);
		user_knife[id] = KNIFE_NONE;
		LoadLevels(id, KNIFE_NONE);
	}
	
	if(user_new_knife[id] > KNIFE_NONE)
	{
		if (user_using_trial[id])
		{
			user_using_trial[id] = false;
			SaveTrial(id, user_new_knife[id]);
		}
		SaveLevels(id);
		user_knife[id] = user_new_knife[id];
		user_new_knife[id] = 0;
		LoadLevels(id, user_knife[id]);
	}
	
	if(user_knife[id] > KNIFE_NONE && is_user_alive(id))
		give_item(id, "weapon_knife");
	else
		ChooseFraction(id);
}

public PlayerKilled(victim, attacker)
{
	user_killstreak[victim] = 0;
	if(user_new_knife[victim]) 
	{
		SetTask(victim, 0);
		PrintChat(victim, "%L", victim, "CHAT_WILL_NEXT_ROUND");
		SaveLevels(victim);
		user_knife[victim] = user_new_knife[victim];
		user_new_knife[victim] = KNIFE_NONE;
		LoadLevels(victim, user_knife[victim]);
	}
	if (attacker > get_maxplayers() || attacker < 1)
		return PLUGIN_CONTINUE;
	
	if (attacker != victim)
	{
		new default_money = get_pcvar_num(cvar_pointer[MoneyFKill]);
		new new_money = default_money+default_money*user_killstreak[attacker]/10;
		new_money = is_happy_hour? new_money*2:new_money;
		new_money = is_user_vip(attacker)? new_money*2:new_money;
		user_max_points[attacker]+=new_money;
		user_left_points[attacker]+=new_money;
		user_killstreak[attacker]++;
		cs_set_user_money(attacker, user_left_points[attacker], 1);
		SaveData(attacker);
		CheckForNewUnlocks(attacker, new_money);
		if (get_pcvar_num(cvar_pointer[LevelsON]) && user_knife[attacker])
		{
			new new_xp = 100;
			if (g_double_exp[attacker]) 
				new_xp*=2;
			client_print(attacker, print_center, "+%i", new_xp);
			user_xp[attacker]+=new_xp;
			CheckLevel(attacker);
		}
	}
	if(is_user_alive(attacker) && get_pcvar_num(cvar_pointer[RestoreHP]))
	{
		static MapName[32], MapPrefix[6];
		get_mapname(MapName, charsmax(MapName));
		
		new const  Health[] = {35, 65, 200};
		new user_health = get_user_health(attacker);
		
		for (new i=0; i<sizeof Health; i++)
		{
			formatex(MapPrefix, charsmax(MapPrefix), "%ihp", Health[i]);
			if(contain(MapName, MapPrefix) != -1 && user_health<Health[i])
			{
				set_user_health(attacker, Health[i]);
				client_cmd(attacker, "spk ^"%s",sound[LevelUP]); // spk healed
				set_hudmessage(255, 0, 0, 0.02, 0.84, 0, 0.0, 2.0, 0.5, 0.5, -1);
				ShowSyncHudMsg(attacker, SyncHudObj[1], "+%i",Health[i]-user_health)
				Display_Fade(attacker, 1<<10, 1<<10, 0x0000, 255, 0, 0, 75);
				break;
			}	
		}
	}	
	return PLUGIN_CONTINUE;
}

public ExpForLevel(level)
	return level*get_pcvar_num(cvar_pointer[LevelRATIO]);

public PobedaTerro()
	PobednjenaRunda("TERRORIST");

public PobedaCT()
	PobednjenaRunda("CT");

public PobednjenaRunda(const Team[])
{
	new Players[32], playerCount, id;
	get_players(Players, playerCount, "ceh", Team);
	
	if(get_playersnum() < 3)
		return;
	new money = get_pcvar_num(cvar_pointer[MoneyFWinR]);
	
	for (new i=0; i<playerCount; i++)
	{
		id = Players[i];
		
		if(!is_user_connected(id))
			continue;
		
		if (is_user_vip(id))
		{
			user_max_points[id]+=money*2;
			user_left_points[id]+=money*2;
		}
		else
		{
			user_max_points[id]+=money;
			user_left_points[id]+=money;
		}
		cs_set_user_money(id, user_left_points[id], 1);
		SaveData(id);
		CheckForNewUnlocks(id, money);
	}
}

public CmdAddPoints(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
	{
		client_cmd(id, "spk ^"%s",sound[Exit]);
		return PLUGIN_HANDLED;
	}
	
	new argv[35];
	read_argv(1, argv, charsmax(argv));
	new target = cmd_target(id, argv, 0);
	
	if(!target)
		return PLUGIN_CONTINUE;
	
	read_argv(2, argv, charsmax(argv));
	new value = str_to_num(argv);
	
	user_max_points[target]+=value;
	user_left_points[target]+=value;
	cs_set_user_money(target, user_left_points[target], 1);
	SaveData(target);
	CheckForNewUnlocks(target, value);
	
	client_cmd(id, "spk ^"%s",sound[LevelUP]);
	console_print(id, "%L", id ,"CMD_SUCCESS1",PlayerName[target], value);
	
	if(get_pcvar_num(cvar_pointer[AdminLog]))
		LogCommand(id, target, "knife_give_money", value);
	
	return PLUGIN_CONTINUE;
}

public CmdSetLvl(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
	{
		client_cmd(id, "spk ^"%s",sound[Exit]);
		return PLUGIN_HANDLED;
	}
	
	new argv[35];
	read_argv(1, argv, charsmax(argv));
	new target = cmd_target(id, argv, 0);
	
	if(!target)
		return PLUGIN_CONTINUE;
	
	read_argv(2, argv, charsmax(argv));
	new value = str_to_num(argv);
	
	if (value < 1)
		value = 1;
	
	user_level[target]=value;
	user_xp[target]=0;
	user_xpForLVL[target]=ExpForLevel(user_level[target]);
	SaveLevels(target);
	
	client_cmd(id, "spk ^"%s",sound[LevelUP]);
	console_print(id, "%L", id ,"CMD_SUCCESS2",PlayerName[target], value);
	
	if(get_pcvar_num(cvar_pointer[AdminLog]))
		LogCommand(id, target, "knife_setlvl", value);
	
	return PLUGIN_CONTINUE;
}

public CheckLevel(id)
{
	if(!user_knife[id])
	{
		user_xp[id]=0;
		return PLUGIN_CONTINUE;
	}
	
	if (user_xp[id]>=user_xpForLVL[id])
	{
		user_level[id]++;
		user_xp[id]=0;
		user_xpForLVL[id]=ExpForLevel(user_level[id]);
		client_cmd(id, "spk ^"%s",sound[LevelUP]);
		PrintChat(id, "%L", id, "CHAT_WELLCOME_LEVEL", user_level[id]);
		//dobrodosli na nivo
	}
	SaveLevels(id);
	return PLUGIN_CONTINUE;
}

public CheckForNewUnlocks(id, points)
{
	if (points <= 0)
		return;
	new message[191], lang_or[10], unlockeds=0; 
	new len = formatex(message, charsmax(message), "%L ",id, "CHAT_EARNED_ENOUGH");
	formatex(lang_or, charsmax(lang_or), " %L ",id, "CHAT_ADD_OR");
	
	for (new knife=1; knife<=knifes_loaded; knife++)
		if(!knife_premium[knife] && !user_unlocked_knifes[id][knife])
			if ((user_left_points[id]>=knife_price[knife]) && (user_left_points[id]-points<knife_price[knife]))
			{
				len+=formatex(message[len], charsmax(message)-len, "!y%s!t%L",unlockeds>0?lang_or:"",id, knife_names[knife]); 
				unlockeds++;
			}
	if (unlockeds > 4)
	{
		PrintChat(id, "%L",id, "CHAT_EARNED_NEW_KNIFES");
		client_cmd(id, "spk ^"%s", sound[LevelUP]);
	}
	else if (unlockeds>0)
	{
		add(message, charsmax(message), "!y.");
		PrintChat(id, message);
		client_cmd(id, "spk ^"%s", sound[LevelUP]);
	}
}
stock LogCommand(admin, target, command[], value)
{
	new LogFile[58],  LogText[196], Time[9], Date[9];
	
	get_time("%H:%M:%S", Time, charsmax(Time));
	get_time("%y%m%d", Date, charsmax(Date));
	formatex(LogFile, charsmax(LogFile), "addons/amxmodx/configs/EXP/logs/%s.log", Date);
	formatex(LogText, charsmax(LogText), "[%s] Admin: %s^"<%s>^" %L: %s  ^"%s<%s>^" %L %i",Time, PlayerName[admin], AuthID[admin], LANG_SERVER, "CMD_COMMAND", command, PlayerName[target], AuthID[target], LANG_SERVER, "CMD_VALUE", value);
	write_file(LogFile, LogText);
}

public CurWeapon(id) 
{	
	if(get_user_weapon(id) != CSW_KNIFE || !is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if(user_knife[id] == KNIFE_NONE || user_knife[id] == KNIFE_DEFAULT)
	{
		entity_set_string(id, EV_SZ_viewmodel, "models/v_knife.mdl");
		entity_set_string(id, EV_SZ_weaponmodel, "models/p_knife.mdl");
		return PLUGIN_CONTINUE;
	}
	
	static Model[40];
	formatex(Model, charsmax(Model), "models/EXP/v_%s.mdl", file_names[user_knife[id]-2]);
	entity_set_string(id, EV_SZ_viewmodel, Model);
	if (p_model_exist[user_knife[id]-2])
	{
		formatex(Model, charsmax(Model), "models/EXP/p_%s.mdl", file_names[user_knife[id]-2]);
		entity_set_string(id, EV_SZ_weaponmodel, Model);
	}
	else	
		entity_set_string(id, EV_SZ_weaponmodel, "models/p_knife.mdl");
	
	return PLUGIN_CONTINUE;
}

public MoneyChanged(MsgId, MsgDest, id)
{
	if(is_user_connected(id))
		cs_set_user_money(id, user_left_points[id], 0);
	return PLUGIN_HANDLED;
}

stock SaveData(id, unlock = 0) 
{
	static VaultKey[64], VaultData[MAX_CHARS+4];
	
	if (unlock)
	{
		formatex(VaultKey,  charsmax(VaultKey),"%s-%s-lock", AuthID[id], knife_names[user_would_buy[id]]);
		formatex(VaultData, charsmax(VaultData),"%i",user_unlocked_knifes[id][user_would_buy[id]]?1:0);
		nvault_set(vault, VaultKey, VaultData);
		user_would_buy[id] = 0;
	}
	
	formatex(VaultKey,  charsmax(VaultKey), "%s-stats", AuthID[id]); 
	formatex(VaultData, charsmax(VaultData), "#%i#%s", user_max_points[id], knife_names[user_knife[id]]);
	nvault_set(vault, VaultKey, VaultData);
}

public LoadData(id)
{
	static VaultKey[64], VaultData[MAX_CHARS+4], PlayerData[2][MAX_CHARS+4];
	
	for (new knife = 2; knife<=knifes_loaded; knife++) 
	{
		formatex(VaultKey, charsmax(VaultKey), "%s-%s-lock", AuthID[id], knife_names[knife]);
		nvault_get(vault, VaultKey, VaultData, charsmax(VaultData));
		user_unlocked_knifes[id][knife] = str_to_num(VaultData) == 1?true:false;
		if (user_unlocked_knifes[id][knife])
			user_total_unlockeds[id]++;
		
	}
	
	formatex(VaultKey,  charsmax(VaultKey), "%s-stats", AuthID[id]);
	nvault_get(vault, VaultKey, VaultData, charsmax(VaultData));
	replace_all(VaultData, charsmax(VaultData), "#", " ");
	parse(VaultData, PlayerData[0], charsmax(PlayerData[]), PlayerData[1], charsmax(PlayerData[]));
	
	user_max_points[id] = str_to_num(PlayerData[0]);
	user_left_points[id] = user_max_points[id];
	
	for (new i = 0; i<=knifes_loaded; i++) 
	{
		if (user_unlocked_knifes[id][i])
			user_left_points[id]-=knife_price[i];
	}
	if (get_pcvar_num(cvar_pointer[LoadLastUsedKnife]))
	{	
		for  (new knife = 1; knife<=knifes_loaded; knife++)
			if (equal(PlayerData[1], knife_names[knife]))
		{
			if (knife_premium[knife] && !is_user_vip(id))
			{
				user_knife[id] = KNIFE_NONE;
				LoadLevels(id, KNIFE_NONE);
			}
			else
			{
				user_knife[id] = knife;
				LoadLevels(id, knife);
				user_xpForLVL[id] = ExpForLevel(user_level[id]);
			}
		}
	}
}

public HappyHourCheck()
{
	if(get_pcvar_num(cvar_pointer[HappyHour]) == 1)
		is_happy_hour = true;
	else if(get_pcvar_num(cvar_pointer[HappyHour]) == -1)
		is_happy_hour = false;
	else {
		new Hours = time(Hours);
		
		new BeginHour = get_pcvar_num(cvar_pointer[HappyHourStart]);
		new EndHour  = get_pcvar_num(cvar_pointer[HappyHourStop]);
		
		if(BeginHour == EndHour)
			is_happy_hour = false;
		
		else if((BeginHour > EndHour && (Hours >= BeginHour || Hours < EndHour))
			|| 	(BeginHour < EndHour && (Hours >= BeginHour || Hours < EndHour)))
		is_happy_hour = true;
		else
			is_happy_hour = false;
	}
}

public Advertisement()
{
	for (new id = 1; id <= get_maxplayers(); id++)
	{
		if (!is_user_connected(id))
			continue;
		
		switch(random(6))
		{
			case 0: PrintChat(id, "%L",id, "ADVERT1");
			case 1: PrintChat(id, "%L",id, "ADVERT2");
			case 2: PrintChat(id, "%L",id, "ADVERT3");
			case 3: PrintChat(id, "%L",id, "ADVERT4");
			case 4: PrintChat(id, "%L",id, "ADVERT5");
			case 5: PrintChat(id, "%L",id, "ADVERT6");
		}
	}
}

stock PrintChat(const id, const input[], any:...) 
{
	static prefix[64], message[191];
	get_pcvar_string(cvar_pointer[ChatPrefix], prefix, charsmax(prefix));
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

stock MakeBarTime(id, seconds)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msg_bartime, _, id);
	write_short(seconds);
	message_end();
}

stock SetTask(id, set = 1)
{
	new changing = task_exists(id+TaskSpawn);
	if(set == 1 )
	{
		if (changing)
			remove_task(id+TaskSpawn);
		new seconds = get_pcvar_num(cvar_pointer[ChangeDelay]);
		set_task(float(seconds), "PlayerSpawn", id+TaskSpawn);
		MakeBarTime(id, seconds);
		
	}
	if(set == 0 && changing)
	{
		remove_task(id+TaskSpawn);
		MakeBarTime(id, 0);
	}
}

stock Display_Fade(id, duration, holdtime, fadetype, red, green, blue, alpha)
{
	message_begin(MSG_ONE, g_msg_screenfade, {0,0,0}, id );
	write_short(duration);	// Duration of fadeout
	write_short(holdtime);	// Hold time of color
	write_short(fadetype);	// Fade type
	write_byte (red);	// Red
	write_byte (green);	// Green
	write_byte (blue);	// Blue
	write_byte (alpha);	// Alpha
	message_end();
}

#if defined SHOP
public ShopMenu(id)
{
	new item[81], price;
	formatex(item, charsmax(item), "\w[\rExplosion\w]\r %L\w:",id, "SHOP_TITLE");
	new menu = menu_create(item, "ShopMenu_Handler");
	price = get_pcvar_num(p_respawn);
	if(g_respawned[id] || is_user_alive(id) || user_left_points[id] < price)
		formatex(item, 80, "\d%L \w%L\d (%L) [%L:\w $%s\d]",id, "SHOP_MENU_BUY",id ,"SHOP_ITEM_RESPAWN",id, "SHOP_MENU_ONE_IN_ROUND",id, "SHOP_MENU_PRICE", PriceToString(price));
	else
		formatex(item, 80, "\y%L %L \d(%L) \w[\r%L: $%s\w]",id, "SHOP_MENU_BUY",id, "SHOP_ITEM_RESPAWN",id, "SHOP_MENU_ONE_IN_ROUND",id, "SHOP_MENU_PRICE", PriceToString(price));
	menu_additem(menu, item);
	price = get_pcvar_num(p_jump);
	if(g_double_jump[id] || get_user_flags(id) & ADMIN_LEVEL_H || user_left_points[id] < price)
		formatex(item, 80, "\d%L \w%L\d (%L) [%L:\w$%s\d]",id, "SHOP_MENU_BUY",id, "SHOP_ITEM_DOUBLE_JUMP",id, "SHOP_MENU_ONE_ROUND",id, "SHOP_MENU_PRICE", PriceToString(price));
	else
		formatex(item, 80, "\y%L %L \d(%L) \w[\r%L: $%s\w]",id, "SHOP_MENU_BUY",id, "SHOP_ITEM_DOUBLE_JUMP",id, "SHOP_MENU_ONE_ROUND",id, "SHOP_MENU_PRICE", PriceToString(price));
	menu_additem(menu, item);
	price = get_pcvar_num(p_bhop);
	if(g_autobhop[id] || user_left_points[id] < price)
		formatex(item, 80, "\d%L \w%L\d (%L) [%L:\w$%s\d]",id, "SHOP_MENU_BUY",id, "SHOP_ITEM_ABHOP",id, "SHOP_MENU_ONE_ROUND",id, "SHOP_MENU_PRICE", PriceToString(price));
	else
		formatex(item, 80, "\y%L %L \d(%L) \w[\r%L: $%s\w]",id, "SHOP_MENU_BUY",id, "SHOP_ITEM_ABHOP",id, "SHOP_MENU_ONE_ROUND",id, "SHOP_MENU_PRICE", PriceToString(price));
	menu_additem(menu, item);
	price = get_pcvar_num(p_exp);
	if(g_double_exp[id] || user_left_points[id] < price)
		formatex(item, 80, "\d%L \w%L\d (%L) [%L:\w $%s\d]",id, "SHOP_MENU_BUY",id, "SHOP_ITEM_EXP",id, "SHOP_MENU_MAPCHANGE",id, "SHOP_MENU_PRICE", PriceToString(price));
	else
		formatex(item, 80, "\y%L %L \d(%L) \w[\r%L: $%s\w]",id, "SHOP_MENU_BUY",id, "SHOP_ITEM_EXP",id, "SHOP_MENU_MAPCHANGE",id, "SHOP_MENU_PRICE", PriceToString(price));
	menu_additem(menu, item);
	formatex(item, 80, "\r%L",id, "SHOP_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, item);
	client_cmd(id, "spk ^"%s", sound[Select]);
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public ShopMenu_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		client_cmd(id, "spk ^"%s", sound[Exit]);
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	item++;
	new cena;
	switch(item)
	{
		case 1: // respawn
		{
			cena = get_pcvar_num(p_respawn);
			if (is_user_alive(id))
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "%L",id, "SHOP_ONLY_FOR_DEADS");
				return PLUGIN_CONTINUE;
			}
			if(g_respawned[id])
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "%L",id, "SHOP_ONLY_ONCE_IN_ROUND");
				return PLUGIN_CONTINUE;
			}
			if(user_left_points[id] - cena < 0)
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "%L",id, "SHOP_NOT_ENOUGH_MONEY");
				return PLUGIN_CONTINUE;
			}
			new CsTeams:Team = cs_get_user_team(id);
			if(Team == CS_TEAM_SPECTATOR || Team == CS_TEAM_UNASSIGNED)
			{
				if (is_user_connected(id))
					PrintChat(id, "%L", id, "SHOP_CHAT_NO_SPEC");
				return PLUGIN_CONTINUE;
			}
			user_left_points[id] -= cena;
			user_max_points[id] -= cena;
			cs_set_user_money(id, user_left_points[id]);
			g_respawned[id] = true;
			ExecuteHamB(Ham_CS_RoundRespawn, id);
			PrintChat(id, "%L ^3%L^1.",id, "SHOP_SUC_BUY",id, "SHOP_ITEM_RESPAWN");
		}
		case 2: // dupli skok
		{
			cena = get_pcvar_num(p_jump);
			if(get_user_flags(id)& ADMIN_LEVEL_H)
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "%L",id, "SHOP_VIP_GOTS");
				return PLUGIN_CONTINUE;
			}
			if(g_double_jump[id])
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "^3%L^1 %L",id, "SHOP_ITEM_DOUBLE_JUMP",id, "SHOP_ALREADY_ACTIVATED"); 
				return PLUGIN_CONTINUE;
			}
			if(user_left_points[id] - cena < 0)
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "%L",id, "SHOP_NOT_ENOUGH_MONEY");
				return PLUGIN_CONTINUE;
			}
			g_double_jump[id] = is_user_alive(id)?1:2;
			user_left_points[id] -= cena;
			user_max_points[id] -= cena;
			cs_set_user_money(id, user_left_points[id]);
			PrintChat(id, "%L^3 %L^1.",id, "SHOP_SUC_ACT", id, "SHOP_ITEM_DOUBLE_JUMP");
		}
		case 3: //auto bhop
		{
			cena = get_pcvar_num(p_bhop);
			if(g_autobhop[id])
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "^3%L^1 %L",id, "SHOP_ITEM_ABHOP",id, "SHOP_ALREADY_ACTIVATED");
				return PLUGIN_CONTINUE;
			}
			if(user_left_points[id] - cena < 0)
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "%L",id, "SHOP_NOT_ENOUGH_MONEY");
				return PLUGIN_CONTINUE;
			}
			g_autobhop[id] = is_user_alive(id)?1:2;
			user_left_points[id] -= cena;
			user_max_points[id] -= cena;
			cs_set_user_money(id, user_left_points[id]);
			PrintChat(id, "%L^3 %L^1.",id, "SHOP_SUC_ACT", id, "SHOP_ITEM_ABHOP");
		}
		case 4: // double exp
		{
			cena = get_pcvar_num(p_exp);
			if(g_double_exp[id])
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "^3%L^1 %L",id, "SHOP_ITEM_EXP",id, "SHOP_ALREADY_ACTIVATED"); 
				return PLUGIN_CONTINUE;
			}
			if(user_left_points[id] - cena < 0) 
			{
				client_cmd(id, "spk ^"%s", sound[Exit]);
				PrintChat(id, "%L",id, "SHOP_NOT_ENOUGH_MONEY");
				return PLUGIN_CONTINUE;
			}
			user_left_points[id] -= cena;
			user_max_points[id] -= cena;
			cs_set_user_money(id, user_left_points[id]);
			g_double_exp[id] = true;
			PrintChat(id, "%L^3 %L^1.",id, "SHOP_SUC_ACT", id, "SHOP_ITEM_EXP");
		}
	}
	client_cmd(id, "spk ^"%s", sound[Cash]);
	return PLUGIN_CONTINUE;
}
public NewRound()
{
	for (new id=1; id<=get_maxplayers(); id++)
	{
		g_respawned[id] = false;
		new message = 0;
		if(g_double_jump[id])
		{
			g_double_jump[id]--;
			if(!g_double_jump[id])
				message++;
		}
		if(g_autobhop[id])
		{
			g_autobhop[id]--;
			if(!g_autobhop[id])
				message+=2;
		}

		if (!is_user_connected(id))
			continue;

		switch(message)
		{
			case 1: PrintChat(id, "%L",id, "SHOP_CHAT_DJUMP");
			case 2: PrintChat(id, "%L",id, "SHOP_CHAT_ABHOP");
			case 3: PrintChat(id, "%L",id, "SHOP_CHAT_BOTH");
		}
	}
}

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id) || !g_double_jump[id])
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

public client_PreThink(id) 
{
	if(!g_autobhop[id])
		return PLUGIN_CONTINUE;

	entity_set_float(id, EV_FL_fuser2, 0.0);	// Disable slow down after jumping
	
	new Float:limit = get_pcvar_float(p_speed);
	
	new Float:velocity[3];
	entity_get_vector(id, EV_VEC_velocity, velocity);
	
	if(limit > 0.0)
	{
		if (velocity[1] > limit)
			velocity[1] = limit;
		if (velocity[0] > limit)
			velocity[0] = limit;
	}
	// Code from CBasePlayer::Jump (player.cpp)	Make a player jump automatically
	if (entity_get_int(id, EV_INT_button) & 2) 
	{	// If holding jump
		new flags = entity_get_int(id, EV_INT_flags)

		if (flags & FL_WATERJUMP)
			return PLUGIN_CONTINUE
		if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
			return PLUGIN_CONTINUE
		if ( !(flags & FL_ONGROUND) )
			return PLUGIN_CONTINUE

		velocity[2] += 250.0;
		entity_set_int(id, EV_INT_gaitsequence, 6)	// Play the Jump Animation
	}
	entity_set_vector(id, EV_VEC_velocity, velocity)
	return PLUGIN_CONTINUE;
}
#endif

public plugin_end()
	nvault_close(vault);
