#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>
#include <sdktools_entinput>
#include <sdktools_variant_t>
#include <sdkhooks>
#include <vip_core>

public Plugin myinfo = 
{
	name = "[ViP Core] Bullet Effect",
	author = "Nek.'a 2x2 | ggwp.site ",
	version = "1.0.9",
	url = "https://ggwp.site/"
};
static const char g_sFeature[] = "bullet_effect";

ConVar
	cvHide,
	cvEnable,
	cvRadius,
	cvThickMin,
	cvThickMax,
	cvLifetimeMin,
	cvLifetimeMax,
	cvIntervalMin,
	cvIntervalMax,
	cvColor[2],
	cvBeamcCountMin,
	cvBeamcCountMax;

public void OnPluginStart()
{
	cvHide = CreateConVar("sm_vipbulletef_hide", "1", "Настройка отображения 0-команда|1-игрок|2-все");
	
	cvEnable = CreateConVar("sm_vipbulletef_enable", "1", "Включить/выключить плагин", _, true, _, true, 1.0);

	cvRadius = CreateConVar("sm_vipbulletef_radius", "15.0", "Радиус", _, true, 0.1);

	cvThickMin = CreateConVar("sm_vipbulletef_thickmin", "3.0", "минимальная тощена молнии", _, true, 0.1);

	cvThickMax = CreateConVar("sm_vipbulletef_thickmax", "5.0", "максимальная тощена молнии", _, true, 0.1);

	cvLifetimeMin = CreateConVar("sm_vipbulletef_lifetimemin", "0.3", "Минимальное время жизни", _, true, 0.1);

	cvLifetimeMax = CreateConVar("sm_vipbulletef_lifetimemax", "0.7", "Максимальное время жизни", _, true, 0.1);

	cvIntervalMin = CreateConVar("sm_vipbulletef_intervalmin", "0.1", "Интервал появления молний миниум", _, true, 0.1);

	cvIntervalMax = CreateConVar("sm_vipbulletef_intervalmax", "0.2", "Интервал появления молний максимум", _, true, 0.1);

	cvColor[0] = CreateConVar("sm_vipbulletef_color", "45 211 0", "RGB Террористов");

	cvColor[1] = CreateConVar("sm_vipbulletef_color2", "0 0 255", "RGB Контр-Террористов");

	cvBeamcCountMin = CreateConVar("sm_vipbulletef_beamccountmin", "7", "Количество молний минимум");

	cvBeamcCountMax = CreateConVar("sm_vipbulletef_beamccountmax", "10", "Количество молний максимум");
	
	HookEvent("bullet_impact", Event_OnBulletImpact);
	
	AutoExecConfig(true, "bullet_effect", "vip");

	if(VIP_IsVIPLoaded()) VIP_OnVIPLoaded();
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
		VIP_UnregisterFeature(g_sFeature);
}

void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

void Event_OnBulletImpact(Handle hEvent, const char[] name, bool silent) 
{
	if(!cvEnable.BoolValue)
		return;
	
	static int client;
	static bool ver;
	
	if(!(client = GetClientOfUserId(GetEventInt(hEvent, "userid"))) || !IsClientInGame(client)
	|| !VIP_IsClientVIP(client) || !VIP_IsClientFeatureUse(client, g_sFeature))
	return;

	int iTeam = GetClientTeam(client);
	ver = view_as<bool>(GetRandomInt(0, 1));

	float fVec[3] = 0.0;
	fVec[0] = GetEventFloat(hEvent, "x");
	fVec[1] = GetEventFloat(hEvent, "y");
	fVec[2] = GetEventFloat(hEvent, "z");
	
	char sColors[2][18], sBeamcCountMin[5], sBeamcCountMax[5];
	cvColor[0].GetString(sColors[0], sizeof(sColors[]));
	cvColor[1].GetString(sColors[1], sizeof(sColors[]));
	cvBeamcCountMin.GetString(sBeamcCountMin, sizeof(sBeamcCountMin));
	cvBeamcCountMax.GetString(sBeamcCountMax, sizeof(sBeamcCountMax));
	
	int iEntity = -1;
	
	switch(ver)
	{
		case 0:
			if(iTeam == 2)
				CreateEntity(iEntity, client, fVec, sBeamcCountMin, sBeamcCountMax, sColors[0], sColors[1], iTeam);
			else
				CreateEntity(iEntity, client, fVec, sBeamcCountMin, sBeamcCountMax, sColors[0], sColors[1], iTeam);
	}
}

void CreateEntity(int iEntity, int client, float fVec[3], char[] sBeamcCountMin, char[] sBeamcCountMax, char[] sColorsT, char[] sColorsCt, int iTeam)
{
	iEntity = CreateEntityByName("point_tesla", -1);
	DispatchKeyValueFloat(iEntity, "m_flRadius", cvRadius.FloatValue);
	DispatchKeyValue(iEntity, "m_SoundName", "DoSpark");
	DispatchKeyValue(iEntity, "beamcount_min", sBeamcCountMin);
	DispatchKeyValue(iEntity, "beamcount_max", sBeamcCountMax);
	DispatchKeyValue(iEntity, "texture", "sprites/physbeam.vmt");
	DispatchKeyValue(iEntity, "m_Color", iTeam == 2 ? sColorsT : sColorsCt);
	DispatchKeyValueFloat(iEntity, "thick_min", cvThickMin.FloatValue);	
	DispatchKeyValueFloat(iEntity, "thick_max", cvThickMax.FloatValue);	
	DispatchKeyValueFloat(iEntity, "lifetime_min", cvLifetimeMin.FloatValue);
	DispatchKeyValueFloat(iEntity, "lifetime_max", cvLifetimeMax.FloatValue);
	DispatchKeyValueFloat(iEntity, "interval_min", cvIntervalMin.FloatValue);
	DispatchKeyValueFloat(iEntity, "interval_max", cvIntervalMax.FloatValue);
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
	if (!DispatchSpawn(iEntity))
	{
		AcceptEntityInput(iEntity, "Kill");
		LogError("Couldn't create iEntity 'bullet_effect'");
	}
	TeleportEntity(iEntity, fVec, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn", -1, -1, 0);
	AcceptEntityInput(iEntity, "DoSpark", -1, -1, 0);
	SetVariantString("OnUser1 !self:kill::2.0:-1");
	AcceptEntityInput(iEntity, "AddOutput");
	AcceptEntityInput(iEntity, "FireUser1");
	SDKHook(iEntity, SDKHook_SetTransmit, OnTransmit);
}

Action OnTransmit(int iEntity, int client)
{
	if(!(0 < client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;
		
	SetEdictFlags(iEntity, GetEdictFlags(iEntity) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	
	switch(cvHide.IntValue)
	{
		case 0:
		{
			if(GetClientTeam(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")) == GetClientTeam(client))
				return Plugin_Continue;
			else
				return Plugin_Handled;
		}
		
		case 1:
		{
			if(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == client)
				return Plugin_Continue;
			else
				return Plugin_Handled;
		}
		case 2:
		{
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}
