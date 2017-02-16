#include <amxmodx>
#include <amxmisc>

#define PLUGIN_VERSION "1.0.0b"

#define SERVER 	  "176.57.188.24:27040" // Explosion Knife Arena
#define DATE 	  "15.1.2018" 		// Datum kada istice plugin

new Changing[33];
new AdminType[33];
new AdminID[33];
new AdminPW[33][32];
new AdminComment[33][32];
new AdminName[33][64];
new AuthID[33][64];

new g_msg_saytext;

enum 
{
	None,
	Admin,
	VIPm,
	VIPz,
	HeadAdmin
};

new const Vrste[][] = 
{
	"Obican Admin", 
	"VIP Admin (M)",
	"VIP Admin (Z)",
	"Head Admin"
};

public plugin_init() {
	register_plugin("Admin Manager", PLUGIN_VERSION, "Rajk0");
	
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
		set_fail_state("Istekla vam je demo verzija plugina. kontakt: rmilanrajkovic@gmail.com");
	#endif
	
	register_clcmd("chooseteam", "PromenaTima");
	register_concmd("lozinka", "ChangePassword");
	register_concmd("komentar", "ChangeComment");
	register_clcmd("say /asd", "PromenaTima");
	
	g_msg_saytext = get_user_msgid("SayText");
}

public plugin_precache()
{
	precache_sound("EXP/select.wav");
	precache_sound("EXP/level_up.wav");
	precache_sound("EXP/deny.wav");
}

public client_putinserver(id)
{
	Changing[id]=false;
}

public PromenaTima(id)
{
	if (get_user_flags(id) & ADMIN_RCON)
	{
		if (Changing[id])
		{
			Changing[id]=false;
			return PLUGIN_CONTINUE;
		}
		else
		{
			Menu(id);
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public Menu(id)
{
	new menu = menu_create("\rIzaberi Komandu\w:", "PromenaTima_Handle");
	menu_additem(menu, "\yPromeni tim");
	menu_additem(menu, "\yDodaj admina");
	menu_setprop(menu, MPROP_EXITNAME, "\rZatvori")
	menu_display(id, menu);
}

public PromenaTima_Handle(id, menu, item)
{
	switch(item)
	{
		case MENU_EXIT: menu_destroy(menu);
		case 0:
		{
			Changing[id]=true;
			client_cmd(id, "chooseteam");
		}
		case 1: 
		{
			AdminID[id]=0;
			AdminType[id]=0;
			AdminPW[id][0]='^0'
			AdminComment[id][0]='^0'
			DodajAdmina(id);
			client_cmd(id, "spk EXP/select.wav");
		}
	}
}

public DodajAdmina(id)
{
	new menu = menu_create("\rDodavanje novog admina:", "DodajAdmina_Handle");
	static item[64];
	
	if (!AdminID[id]) 
		formatex(item, charsmax(item), "\rIgrac:\y Izaberi");
	else
		formatex(item, charsmax(item), "\rIgrac:\y %s",AdminName[id]);
	menu_additem(menu, item);
	
	if(!AdminType[id])
		formatex(item, charsmax(item), "\rVrsta: \yIzaberi");
	else
		formatex(item, charsmax(item), "\rVrsta: \y%s", Vrste[AdminType[id]-1]);
	menu_additem(menu, item);
	
	if(!AdminPW[id][0])
		formatex(item, charsmax(item), "\rLozinka:\y Unesi");
	else
		formatex(item, charsmax(item), "\rLozinka:\y %s",AdminPW[id]);
	menu_additem(menu, item);
	
	if(!AdminComment[id][0])
		formatex(item, charsmax(item), "\rKomentar:\y Nema^n");
	else
		formatex(item, charsmax(item), "\rKomentar:\y %s^n",AdminComment[id]);
	menu_additem(menu, item);
	if(!AdminID[id] || !AdminType[id] || !AdminPW[id][0])
		menu_additem(menu, "\dPotvrdi");
	else
		menu_additem(menu, "\yPotvrdi");
	
	menu_setprop(menu, MPROP_EXITNAME, "\yOtkazi");
	menu_display(id, menu);
}

public DodajAdmina_Handle(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	item++;
	switch(item)
	{
		case 1: ChoosePlayer(id);
		case 2: ChooseType(id);
		case 3:
		{
			client_cmd(id, "messagemode lozinka");
			DodajAdmina(id);
		}
		case 4:
		{
			client_cmd(id,"messagemode komentar");
			DodajAdmina(id);
		}
		case 5:
		{
			if(!AdminID[id])
			{
				PrintChat(id, "Niste izabrali kome cete dati admina.");
				DodajAdmina(id);
				client_cmd(id, "spk EXP/deny.wav");
				return PLUGIN_CONTINUE;
			}
			if(is_user_admin(AdminID[id]))
			{
				PrintChat(id, "!t%s!y vec ima admina.",AdminName[AdminID[id]]);
				PrintChat(id, "Morate obrisati njegov steam id iz !tusers.ini!y fajla!");
				client_cmd(id, "spk EXP/deny.wav");
				DodajAdmina(id);
				return PLUGIN_CONTINUE;
			}
			if(!AdminType[id])
			{
				PrintChat(id, "Niste izabrali vrstu admina.");
				DodajAdmina(id);
				client_cmd(id, "spk EXP/deny.wav");
				return PLUGIN_CONTINUE;
			}
			if(!AdminPW[id][0])
			{
				PrintChat(id, "Niste uneli sifru za admina.");
				DodajAdmina(id);
				client_cmd(id, "spk EXP/deny.wav");
				return PLUGIN_CONTINUE;
			}
			new const usersini[] = "addons/amxmodx/configs/users.ini";
			new data[128], flags[32];
			if (is_user_connected(AdminID[id]))
			{
				client_cmd(AdminID[id], "setinfo _pw ^"%s^"",AdminPW[id]);
				set_user_info(AdminID[id], "_pw", AdminPW[id]);
				PrintChat(AdminID[id], "Cestitamo! Uspesno ste postali !t%s!y.",Vrste[AdminType[id]-1]);
				PrintChat(id, "Uspesno ste igracu !t%s!y dodelili!t %s!y.", AdminName[id], Vrste[AdminType[id]-1]);
			}
			else
			{
				PrintChat(id, "Igrac !t%s!y se diskonektovao.");
				PrintChat(id, "Obavestite ga da ukuca: !tsetinfo _pw ^"%s^"!y u konzoli", AdminPW[id]);
			}
			switch (AdminType[id])
			{
				case Admin: formatex(flags, charsmax(flags), "bcdeioprtu");
				case VIPm: formatex(flags, charsmax(flags), "mz");
				case VIPz: formatex(flags, charsmax(flags), "mnz");
				case HeadAdmin: formatex(flags, charsmax(flags), "abcdefghijklmnopqrstu");
			}
			client_cmd(id, "spk EXP/level_up.wav");
			//"STEAM_0:0:12345678" "password" "abcdefghijklmnopqrstu" "ac" ; komentar
			formatex(data, charsmax(data), "^"%s^"	^"%s^"	^"%s^"	^"ac^" ; %s", AuthID[id], AdminPW[id], flags, AdminComment[id])
			write_file(usersini,  data);
			server_cmd("amx_reloadadmins");
		}
	}
	return PLUGIN_CONTINUE;
}

public ChoosePlayer(id)
{
	new menu = menu_create("\rIzaberi igraca:", "ChoosePlayer_Handle");
	
	new players[32], pnum, Player;
	new szName[32], szUserId[32];
	get_players(players, pnum, "ch"); 
	new item[34];
	for(new i=0; i<pnum; i++)
	{
		Player = players[i];
		get_user_name(Player, szName, charsmax(szName));
		formatex(item, charsmax(item), "\y%s", szName);
		formatex(szUserId, charsmax(szUserId), "%d", get_user_userid(Player));
		menu_additem(menu, item, szUserId, 0);
	}
	menu_setprop(menu, MPROP_BACKNAME, "\yPrethodna strana");
	menu_setprop(menu, MPROP_NEXTNAME, "\ySledeca strana");
	menu_setprop(menu, MPROP_EXITNAME, "\yNazad");
	menu_display(id, menu); 
	client_cmd(id, "spk EXP/select.wav");
} 

public ChoosePlayer_Handle(id, menu, item) 
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		client_cmd(id, "spk EXP/deny.wav");
		DodajAdmina(id);
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
		PrintChat(id, "Igrac se diskonektovao");
		ChoosePlayer(id)
		return PLUGIN_CONTINUE;
	}
	AdminID[id] = player;
	get_user_authid(player, AuthID[id], charsmax(AuthID[]));
	get_user_name(player, AdminName[id], charsmax(AdminName[]));
	client_cmd(id, "spk EXP/select.wav");
	menu_destroy(menu);
	DodajAdmina(id);
	return PLUGIN_CONTINUE;
} 

public ChooseType(id)
{
	new menu = menu_create("\rIzaberi vrstu admina\w:", "ChooseType_Handle");
	
	menu_additem(menu, "\yDodaj obicnog admina");
	menu_additem(menu, "\yDodaj muskog VIP admina");
	menu_additem(menu, "\yDodaj zenskog VIP admina");
	menu_additem(menu, "\yDodaj HEAD admina");
	
	menu_setprop(menu, MPROP_EXITNAME, "\yNazad");
	menu_display(id, menu); 
	client_cmd(id, "spk EXP/select.wav");
}

public ChooseType_Handle(id, menu, item) 
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		DodajAdmina(id);
		client_cmd(id, "spk EXP/deny.wav");
		return PLUGIN_CONTINUE;
	}
	client_cmd(id, "spk EXP/select.wav");
	AdminType[id]=item+1;
	DodajAdmina(id);
	return PLUGIN_CONTINUE;
} 

public ChangePassword(id)
{
	client_cmd(id, "spk EXP/select.wav");
	read_args(AdminPW[id], charsmax(AdminPW[]));
	remove_quotes(AdminPW[id]);
	DodajAdmina(id);
}

public ChangeComment(id)
{
	client_cmd(id, "spk EXP/select.wav");
	read_args(AdminComment[id], charsmax(AdminComment[]));
	remove_quotes(AdminComment[id]);
	DodajAdmina(id);
}

stock PrintChat(const id, const input[], any:...) 
{
	static prefix[33], message[191];
	get_cvar_string("knife_chat_prefix", prefix, charsmax(prefix));
	new len = formatex(message, charsmax(message), "^4%s^1 ", prefix);
	vformat(message[len], 190-len, input, 3);
	
	replace_all(message, charsmax(message), "!g", "^4");
	replace_all(message, charsmax(message), "!y", "^1");
	replace_all(message, charsmax(message), "!t", "^3");
	
	message_begin(MSG_ONE_UNRELIABLE, g_msg_saytext, _, id);
	write_byte(id);
	write_string(message);
	message_end();
}
