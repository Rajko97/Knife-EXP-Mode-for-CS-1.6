#include <amxmodx> 
#include <engine> 
#include <cstrike> 

#define DATE 	  "15.1.2018" 		// Datum kada istice plugin

public plugin_init() 
{ 
	register_plugin("HE Remover", "1.0", "Rajk0");

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
		set_fail_state("Istekla vam je demo verzija plugina");
	#endif
	
	new WepID = -1;
	while((WepID = find_ent_by_model(WepID,"armoury_entity","models/w_hegrenade.mdl")) != 0)
	{
		remove_entity(WepID);
	}
	WepID = -1;
	while((WepID = find_ent_by_model(WepID,"armoury_entity","models/p_knife.mdl")) != 0)
	{
		remove_entity(WepID);
	}
	WepID = -1;
	while((WepID = find_ent_by_class(WepID, "game_player_hurt")) != 0 )
		remove_entity(WepID);

}