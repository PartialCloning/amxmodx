/* AMX Mod X
*   Admin Commands Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*
* This file is part of AMX Mod X.
*
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation,
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
*  In addition, as a special exception, the author gives permission to
*  link the code of this program with the Half-Life Game Engine ("HL
*  Engine") and Modified Game Libraries ("MODs") developed by Valve,
*  L.L.C ("Valve"). You must obey the GNU General Public License in all
*  respects for all of the code used other than the HL Engine and MODs
*  from Valve. If you modify this file, you may extend this exception
*  to your version of the file, but you are not obligated to do so. If
*  you do not wish to do so, delete this exception statement from your
*  version.
*/

#include <amxmodx>
#include <amxmisc>

#define MAXRCONCVARS 16
new g_cvarRcon[ MAXRCONCVARS ][32]
new g_cvarRconNum
new g_pauseCon
new Float:g_pausAble
new bool:g_Paused
new g_addCvar[] = "amx_cvar add %s"

public plugin_init(){
  register_plugin("Admin Commands","0.16","AMXX Dev Team")
  register_concmd("amx_kick","cmdKick",ADMIN_KICK,"<name or #userid> [reason]")
  register_concmd("amx_ban","cmdBan",ADMIN_BAN,"<name or #userid> <id/ip> <minutes> [reason]")
  register_concmd("amx_addban","cmdAddBan",ADMIN_BAN,"<authid or ip> <minutes> [reason]")
  register_concmd("amx_unban","cmdUnban",ADMIN_BAN,"<authid or ip>")
  register_concmd("amx_slay","cmdSlay",ADMIN_SLAY,"<name or #userid>")
  register_concmd("amx_slap","cmdSlap",ADMIN_SLAY,"<name or #userid> [power]")
  register_concmd("amx_leave","cmdLeave",ADMIN_KICK,"<tag> [tag] [tag] [tag]")
  register_concmd("amx_pause","cmdPause",ADMIN_CVAR,"- pause or unpause the game")  
  register_concmd("amx_who","cmdWho",ADMIN_ADMIN,"- displays who is on server")  
  register_concmd("amx_cvar","cmdCvar",ADMIN_CVAR,"<cvar> [value]")
  register_concmd("amx_plugins","cmdPlugins",ADMIN_ADMIN)
  register_concmd("amx_modules","cmdModules",ADMIN_ADMIN)
  register_clcmd("amx_map","cmdMap",ADMIN_MAP,"<mapname>")
  register_clcmd("pauseAck","cmdLBack")
  register_clcmd("amx_cfg","cmdCfg",ADMIN_CFG,"<fliename>")
  register_clcmd("amx_rcon","cmdRcon",ADMIN_RCON,"<command line>")
}

public plugin_cfg(){
  // Cvars which can be changed only with rcon access
  server_cmd( g_addCvar ,"rcon_password")
  server_cmd( g_addCvar ,"amx_show_activity")
  server_cmd( g_addCvar ,"amx_mode")
  server_cmd( g_addCvar ,"amx_password_field")
  server_cmd( g_addCvar ,"amx_default_access")
  server_cmd( g_addCvar ,"amx_reserved_slots")
  server_cmd( g_addCvar ,"amx_reservation")
  server_cmd( g_addCvar ,"amx_conmotd_file")
}

public cmdKick(id,level,cid){
  if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED
  new arg[32]
  read_argv(1,arg,31)
  new player = cmd_target(id,arg,1)
  if (!player) return PLUGIN_HANDLED
  new authid[32],authid2[32],name2[32],name[32],userid2,reason[32]
  get_user_authid(id,authid,31)
  get_user_authid(player,authid2,31)
  get_user_name(player,name2,31)
  get_user_name(id,name,31)
  userid2 = get_user_userid(player)
  read_argv(2,reason,31)
  remove_quotes(reason)
  log_amx("Kick: ^"%s<%d><%s><>^" kick ^"%s<%d><%s><>^" (reason ^"%s^")", 
    name,get_user_userid(id),authid,name2,userid2,authid2,reason)
  switch(get_cvar_num("amx_show_activity")) {
  case 2: client_print(0,print_chat,"ADMIN %s: kick %s",name,name2)
  case 1: client_print(0,print_chat,"ADMIN: kick %s",name2)
  } 
  if ( is_user_bot(player) )
    server_cmd("kick #%d",userid2)
  else
  {
#if !defined NO_STEAM
    if (reason[0])
      server_cmd("kick #%d ^"%s^"",userid2,reason)
    else
      server_cmd("kick #%d",userid2)
#else
    if (reason[0])
      client_cmd(player,"echo ^"Kicked: Reason: %s^";disconnect",reason)
    else
      client_cmd(player,"echo ^"Kicked^";disconnect",reason)
#endif
  }
  console_print(id,"[AMXX] Client ^"%s^" kicked",name2)
  return PLUGIN_HANDLED
}

public cmdUnban(id,level,cid){
  if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED
  new arg[32],authid[32],name[32]
  read_argv(1,arg,31)
  if (contain(arg,".")!=-1) {
    server_cmd("removeip ^"%s^";writeip",arg)
    console_print(id,"[AMXX] Ip ^"%s^" removed from ban list", arg  )
  }
  else {
    server_cmd("removeid ^"%s^";writeid",arg)
    console_print(id,"[AMXX] Authid ^"%s^" removed from ban list", arg  )
  }
  get_user_name(id,name,31)  
  switch(get_cvar_num("amx_show_activity")) {
    case 2: client_print(0,print_chat,"ADMIN %s: unban %s",name,arg)
    case 1: client_print(0,print_chat,"ADMIN: unban %s",arg)
  }
  get_user_authid(id,authid,31)
  log_amx("Cmd: ^"%s<%d><%s><>^" unban ^"%s^"", 
    name,get_user_userid(id),authid, arg )
  return PLUGIN_HANDLED
}

public cmdAddBan(id,level,cid){
  if (!cmd_access(id,level,cid,3))
    return PLUGIN_HANDLED
  new arg[32],authid[32],name[32],minutes[32],reason[32]
  read_argv(1,arg,31)
  read_argv(2,minutes,31)
  read_argv(3,reason,31)
  if (contain(arg,".")!=-1) {
    server_cmd("addip ^"%s^" ^"%s^";wait;writeip",minutes,arg)
    console_print(id,"[AMXX] Ip ^"%s^" added to ban list", arg )
  }
  else {
    server_cmd("banid ^"%s^" ^"%s^";wait;writeid",minutes,arg)
    console_print(id,"[AMXX] Authid ^"%s^" added to ban list", arg )
  }
  get_user_name(id,name,31)  
  switch(get_cvar_num("amx_show_activity")) {
    case 2: client_print(0,print_chat,"ADMIN %s: ban %s",name,arg)
    case 1: client_print(0,print_chat,"ADMIN: ban %s",arg)
  }
  get_user_authid(id,authid,31)
  log_amx("Cmd: ^"%s<%d><%s><>^" ban ^"%s^" (minutes ^"%s^") (reason ^"%s^")", 
    name,get_user_userid(id),authid, arg, minutes, reason )
  return PLUGIN_HANDLED    
}
    
public cmdBan(id,level,cid){
  if (!cmd_access(id,level,cid,4))
    return PLUGIN_HANDLED
  new target[32],mode[3],minutes[8],reason[32]
  read_argv(1,target,31)
  read_argv(2,mode,2)
  strtolower(mode)
  read_argv(3,minutes,7)
  read_argv(4,reason,31)
  if ( (!equal(mode,"id")) && (!equal(mode,"ip")) )
  {
    new hcmd[32],hinfo[128],hflag
    get_concmd(cid,hcmd,31,hflag,hinfo,127,level)
    console_print(id,"Usage:  %s %s",hcmd,hinfo)
    return PLUGIN_HANDLED
  }
  new player = cmd_target(id,target,9)
  if (!player) return PLUGIN_HANDLED
  new authid[32],name2[32],authid2[32],name[32]
  new userid2 = get_user_userid(player)
  get_user_authid(player,authid2,31)
  get_user_authid(id,authid,31)
  get_user_name(player,name2,31)
  get_user_name(id,name,31)
  userid2 = get_user_userid(player)
  log_amx("Ban: ^"%s<%d><%s><>^" ban and kick ^"%s<%d><%s><>^" (mode ^"%s^") (minutes ^"%s^") (reason ^"%s^")", 
    name,get_user_userid(id),authid, name2,userid2,authid2,mode,minutes,reason)

  new temp[64]
  if (str_to_num(minutes))
    format(temp,63,"for %s min.",minutes)
  else
    temp = "permanently"

  if ( equal(mode,"ip") ){
    new address[32]
    get_user_ip(player,address,31,1)
#if !defined NO_STEAM
    if (reason[0])
      server_cmd("kick #%d ^"%s (banned %s)^";wait;addip ^"%s^" ^"%s^";wait;writeip",userid2,reason,temp,minutes,address)
    else
      server_cmd("kick #%d ^"banned %s^";wait;addip ^"%s^" ^"%s^";wait;writeip",userid2,temp,minutes,address)
#else
    if (reason[0])
      client_cmd(player,"echo ^"%s (banned %s)^";disconnect",reason,temp)
    else
      client_cmd(player,"echo ^"banned %s^";disconnect",temp)
    server_cmd("addip ^"%s^" ^"%s^";wait;writeip",minutes,address)
#endif
  }
  else
  {
#if !defined NO_STEAM
    if (reason[0])
      server_cmd("kick #%d ^"%s (banned %s)^";wait;banid ^"%s^" ^"%s^";wait;writeid",userid2,reason,temp,minutes,authid2)
    else
      server_cmd("kick #%d ^"banned %s^";wait;banid ^"%s^" ^"%s^";wait;writeid",userid2,temp,minutes,authid2)
#else
    if (reason[0])
      client_cmd(player,"echo ^"%s (banned %s)^";disconnect",reason,temp)
    else
      client_cmd(player,"echo ^"banned %s^";disconnect",temp)
    server_cmd("banid ^"%s^" ^"%s^";wait;writeip",minutes,authid2)
#endif
  }
    
  new activity = get_cvar_num("amx_show_activity")
  if (activity) {
    new temp2[64]
    if (activity == 1)
      temp2 = "ADMIN:"
    else
      format(temp2,63,"ADMIN %s:",name)
    client_print(0,print_chat,"%s ban %s %s",temp2,name2,temp)
  } 
  
  console_print(id,"[AMXX] Client ^"%s^" banned",name2)
  return PLUGIN_HANDLED
}

public cmdSlay(id,level,cid){
  if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED
  new arg[32]
  read_argv(1,arg,31)
  new player = cmd_target(id,arg,5)
  if (!player) return PLUGIN_HANDLED
  user_kill(player)
  new authid[32],name2[32],authid2[32],name[32]
  get_user_authid(id,authid,31)
  get_user_name(id,name,31)
  get_user_authid(player,authid2,31)
  get_user_name(player,name2,31)
  log_amx("Cmd: ^"%s<%d><%s><>^" slay ^"%s<%d><%s><>^"",
    name,get_user_userid(id),authid, name2,get_user_userid(player),authid2 )
    
  switch(get_cvar_num("amx_show_activity")) {
  case 2: client_print(0,print_chat,"ADMIN %s: slay %s",name,name2)
  case 1: client_print(0,print_chat,"ADMIN: slay %s",name2)
  }   
    
  console_print(id,"[AMXX] Client ^"%s^" slayed",name2)
  return PLUGIN_HANDLED
}

public cmdSlap(id,level,cid){
  if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED
  new arg[32]
  read_argv(1,arg,31)
  new player = cmd_target(id,arg,5)
  if (!player) return PLUGIN_HANDLED
  new spower[32],authid[32],name2[32],authid2[32],name[32]
  read_argv(2,spower,31)
  new damage = str_to_num(spower)
  user_slap(player,damage)
  get_user_authid(id,authid,31)
  get_user_name(id,name,31)
  get_user_authid(player,authid2,31)
  get_user_name(player,name2,31)
  log_amx("Cmd: ^"%s<%d><%s><>^" slap with %d damage ^"%s<%d><%s><>^"",
    name,get_user_userid(id),authid, damage,name2,get_user_userid(player),authid2 )
    
  switch(get_cvar_num("amx_show_activity")) {
  case 2: client_print(0,print_chat,"ADMIN %s: slap %s with %d damage",name,name2,damage)
  case 1: client_print(0,print_chat,"ADMIN: slap %s with %d damage",name2,damage)
  }       
      
  console_print(id,"[AMXX] Client ^"%s^" slaped with %d damage",name2,damage)  
  return PLUGIN_HANDLED
}

public chMap(map[])
	server_cmd("changelevel %s",map)

public cmdMap(id,level,cid){
  if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED
  new arg[32]
  new arglen = read_argv(1,arg,31)
  if ( !is_map_valid(arg) ){
    console_print(id,"[AMXX] Map with that name not found or map is invalid")
    return PLUGIN_HANDLED
  } 
  new authid[32],name[32]
  get_user_authid(id,authid,31)
  get_user_name(id,name,31)
  switch(get_cvar_num("amx_show_activity")) {
    case 2: client_print(0,print_chat,"ADMIN %s: changelevel %s",name,arg)
    case 1: client_print(0,print_chat,"ADMIN: changelevel %s",arg)
  }
  log_amx("Cmd: ^"%s<%d><%s><>^" changelevel ^"%s^"", name,get_user_userid(id),authid, arg)
  message_begin(MSG_ALL, SVC_INTERMISSION)
  message_end()
  set_task(2.0,"chMap",0,arg,arglen+1)
  return PLUGIN_HANDLED
}

onlyRcon( name[] ) {
  for(new a = 0; a < g_cvarRconNum; ++a)
    if ( equal( g_cvarRcon[a] , name) )
      return 1
  return 0
}

public cmdCvar(id,level,cid){
  if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED
  new arg[32], arg2[64]
  read_argv(1,arg,31)
  read_argv(2,arg2,63)
  if (  equal(arg,"add") && (get_user_flags(id) & ADMIN_RCON) ) {
    if ( cvar_exists(arg2) ){
      if ( g_cvarRconNum <  MAXRCONCVARS )
        copy( g_cvarRcon[ g_cvarRconNum++ ] , 31, arg2 )
      else
        console_print(id,"[AMXX] Can't add more cvars for rcon access!")
    }
    return PLUGIN_HANDLED
  }
  if (!cvar_exists(arg)){
    console_print(id,"[AMXX] Unknown cvar: %s",arg)
    return PLUGIN_HANDLED
  }
  if ( onlyRcon(arg) && !(get_user_flags(id) & ADMIN_RCON)){
    console_print(id,"[AMXX] You have no access to that cvar")
    return PLUGIN_HANDLED
  }
  else if (equal(arg,"sv_password") && !(get_user_flags(id) & ADMIN_PASSWORD)){
    console_print(id,"[AMXX] You have no access to that cvar")
    return PLUGIN_HANDLED
  }
  if (read_argc() < 3){
    get_cvar_string(arg,arg2,63)
    console_print(id,"[AMXX] Cvar ^"%s^" is ^"%s^"",arg,arg2)
    return PLUGIN_HANDLED
  }
  new authid[32],name[32]
  get_user_authid(id,authid,31)
  get_user_name(id,name,31)
  log_amx("Cmd: ^"%s<%d><%s><>^" set cvar (name ^"%s^") (value ^"%s^")",
    name,get_user_userid(id),authid, arg,arg2)
  set_cvar_string(arg,arg2)
  
  new activity = get_cvar_num("amx_show_activity")
  if (activity) {
    new temp[64]
    if (activity == 1)
      temp = "ADMIN:"
    else
      format(temp,63,"ADMIN %s:",name)
    if (equal(arg,"rcon_password") || equal(arg,"sv_password"))
      copy(arg2,63,"*** PROTECTED ***")
    client_print(0,print_chat,"%s set cvar %s to ^"%s^"",temp,arg,arg2)
  } 
  
  console_print(id,"[AMXX] Cvar ^"%s^" changed to ^"%s^"",arg,arg2)
  return PLUGIN_HANDLED
}

public cmdPlugins(id,level,cid)
{
  if (!cmd_access(id,level,cid,1))
    return PLUGIN_HANDLED

  new name[32],version[32],author[32],filename[32],status[32]

/*
  new motd_body[MOTD_LEN],state[4]
  new num = get_pluginsnum()
  new running = 0
  new pos = copy(motd_body,MOTD_LEN,"<html><head><body><style type=^"text/css^">")
  pos += copy(motd_body[pos],MOTD_LEN-pos,"body{font-family:Arial,sans-serif;font-size:12px;color:#FFCC99;background-color:#000000;margin-left:8px;margin-top:3px}.header{background-color:#9C0000;}.one{background-color:#310000;}.two{background-color:#630000;}")
  pos += copy(motd_body[pos],MOTD_LEN-pos,"</style></head><body><table><tr class=^"header^"><td>Name</td><td>Version</td><td>Author</td><td>Filename</td><td>status</td></tr>")

  for (new i=0;i<num;i++)
  {
    if (equal(state,"one")) copy(state,3,"two")
    else copy(state,3,"one")
    get_plugin(i,filename,31,name,31,version,31,author,31,status,31)
    pos += format(motd_body[pos],MOTD_LEN-pos,"<tr class=^"%s^"><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>",state,name,version,author,filename,status)
    if (equal(status,"running"))
      running++
  }
  format(motd_body[pos],MOTD_LEN-pos,"</table>%d plugins, %d running</body></html>",num,running)
  show_motd(id,motd_body,"Currently loaded plugins:")
*/
  new num = get_pluginsnum()
  new running = 0
  console_print(id,"Currently loaded plugins:")
  console_print(id,"%-18.17s %-8.7s %-17.16s %-16.15s %-9.8s","name","version","author","file","status")
  for (new i=0;i<num;i++)
  {
    get_plugin(i,filename,31,name,31,version,31,author,31,status,31)
    console_print(id,"%-18.17s %-8.7s %-17.16s %-16.15s %-9.8s",name,version,author,filename,status)
    if (equal(status,"running"))
      running++
  }
  console_print(id,"%d plugins, %d running",num,running)

  return PLUGIN_HANDLED
}

public cmdModules(id,level,cid)
{
  if (!cmd_access(id,level,cid,1))
    return PLUGIN_HANDLED

  new name[32],version[32],author[32],status,sStatus[16]

/*
  new motd_body[MOTD_LEN],state[4]
  new num = get_modulesnum()
  new pos = copy(motd_body,MOTD_LEN,"<html><head><body><style type=^"text/css^">")
  pos += copy(motd_body[pos],MOTD_LEN-pos,"body{font-family:Arial,sans-serif;font-size:12px;color:#FFCC99;background-color:#000000;margin-left:8px;margin-top:3px}.header{background-color:#9C0000;}.one{background-color:#310000;}.two{background-color:#630000;}")
  pos += copy(motd_body[pos],MOTD_LEN-pos,"</style></head><body><table><tr class=^"header^"><td>Name</td><td>Version</td><td>Author</td></tr>")

  for (new i=0;i<num;i++)
  {
    if (equal(state,"one")) copy(state,3,"two")
    else copy(state,3,"one")
    get_module(i,name,31,author,31,version,31)
    pos += format(motd_body[pos],MOTD_LEN-pos,"<tr class=^"%s^"><td>%s</td><td>%s</td><td>%s</td></tr>",state,name,version,author)
  }
  format(motd_body[pos],MOTD_LEN-pos,"</table>%d modules</body></html>",num)
  show_motd(id,motd_body,"Currently loaded modules:")
*/
  new num = get_modulesnum()
  console_print(id,"Currently loaded modules:")
  console_print(id,"%-23.22s %-8.7s %-20.19s","name","version","author")
  for (new i=0;i<num;i++)
  {
    get_module(i,name,31,author,31,version,31,status)
    switch (status)
    {
      case module_loaded: copy(sStatus,15,"running")
      default: copy(sStatus,15,"error")
    }
    console_print(id,"%-23.22s %-8.7s %-20.19s",name,version,author)
  }
  console_print(id,"%d modules",num)

  return PLUGIN_HANDLED
}

public cmdCfg(id,level,cid){
  if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED
  new arg[128]
  read_argv(1,arg,127)
  if (!file_exists(arg)){
    console_print(id,"[AMXX] File ^"%s^" not found",arg)
    return PLUGIN_HANDLED 
  }
  new authid[32],name[32]
  get_user_authid(id,authid,31)
  get_user_name(id,name,31)
  log_amx("Cmd: ^"%s<%d><%s><>^" execute cfg (file ^"%s^")",
    name,get_user_userid(id),authid, arg)
  console_print(id,"[AMXX] Executing file ^"%s^"",arg)
  server_cmd("exec %s",arg)
  
  switch(get_cvar_num("amx_show_activity")) {
      case 2: client_print(0,print_chat,"ADMIN %s: execute config %s",name,arg)
      case 1: client_print(0,print_chat,"ADMIN: execute config %s",arg)
  }
  
  return PLUGIN_HANDLED
}

public cmdLBack(){ 
  set_cvar_float("pausable",g_pausAble)
  console_print(g_pauseCon,"[AMXX] Server %s", g_Paused ? "unpaused" : "paused") 
  if (g_Paused) g_Paused = false
  else g_Paused = true
  return PLUGIN_HANDLED
}

public cmdPause(id,level,cid){ 
  if (!cmd_access(id,level,cid,1))
    return PLUGIN_HANDLED 
  new authid[32],name[32],slayer = id
  get_user_authid(id,authid,31) 
  get_user_name(id,name,31) 
  g_pausAble = get_cvar_float("pausable")
  if (!slayer) slayer = find_player("h") 
  if (!slayer){ 
    console_print(id,"[AMXX] Server was unable to pause the game. Real players on server are needed") 
    return PLUGIN_HANDLED  
  }
  set_cvar_float("pausable",1.0) 
  client_cmd(slayer,"pause;pauseAck")
  log_amx("Cmd: ^"%s<%d><%s><>^" %s server", 
    name,get_user_userid(id),authid, g_Paused ? "unpause" : "pause" )
  console_print(id,"[AMXX] Server proceed %s", g_Paused ? "unpausing" : "pausing")
  
  switch(get_cvar_num("amx_show_activity")) {
    case 2: client_print(0,print_chat,"ADMIN %s: %s server",name,g_Paused ? "unpause" : "pause")
    case 1: client_print(0,print_chat,"ADMIN: %s server",g_Paused ? "unpause" : "pause")
  }
  
  g_pauseCon = id
  return PLUGIN_HANDLED
} 

public cmdRcon(id,level,cid){
  if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED
  new arg[128],authid[32],name[32]
  read_args(arg,127)
  get_user_authid(id,authid,31)
  get_user_name(id,name,31)
  log_amx("Cmd: ^"%s<%d><%s><>^" server console (cmdline ^"%s^")",
    name,get_user_userid(id),authid, arg)
  console_print(id,"[AMXX] Commmand line ^"%s^" sent to server console",arg)
  server_cmd(arg)
  return PLUGIN_HANDLED
}

public cmdWho(id,level,cid){
  if (!cmd_access(id,level,cid,1))
    return PLUGIN_HANDLED

  new players[32], inum, authid[32],name[32], flags, sflags[32]
  get_players(players,inum)
  console_print(id,"^nClients on server:^n #  %-16.15s %-12s %-8s %-4.3s %-4.3s %s",
    "nick","authid","userid","imm","res","access")
  for(new a = 0; a < inum; ++a) {
      get_user_authid(players[a],authid,31)
      get_user_name(players[a],name,31)
      flags = get_user_flags(players[a])
      get_flags(flags,sflags,31)
      console_print(id,"%2d  %-16.15s %-12s %-8d %-4.3s %-4.3s %s", players[a],name,authid,
      get_user_userid(players[a]),(flags&ADMIN_IMMUNITY)?"yes":"no",
      (flags&ADMIN_RESERVATION)?"yes":"no",sflags)
  }
  console_print(id,"Total %d",inum)
  get_user_authid(id,authid,31)
  get_user_name(id,name,31)
  log_amx("Cmd: ^"%s<%d><%s><>^" ask for players list",name,get_user_userid(id),authid) 
  return PLUGIN_HANDLED
}

hasTag(name[],tags[4][32],tagsNum){
  for(new a=0;a<tagsNum;++a)
    if (contain(name,tags[a])!=-1)
      return a
  return -1
}

public cmdLeave(id,level,cid){
  if (!cmd_access(id,level,cid,2))
    return PLUGIN_HANDLED
  new argnum = read_argc()
  new ltags[4][32]
  new ltagsnum = 0
  for(new a=1;a<5;++a){
    if (a<argnum)
      read_argv(a,ltags[ltagsnum++],31)
    else
      ltags[ltagsnum++][0] = 0
  }
  new nick[32], ires, pnum = get_maxplayers() + 1, count = 0
  for(new b=1;b<pnum;++b){
    if (!is_user_connected(b)&&!is_user_connecting(b)) continue
    get_user_name(b,nick,31)
    ires = hasTag(nick,ltags,ltagsnum)
    if (ires!=-1){
      console_print(id,"[AMXX] Skipping ^"%s^" (matching ^"%s^")",nick,ltags[ires])
      continue
    }
    if (get_user_flags(b)&ADMIN_IMMUNITY){
      console_print(id,"[AMXX] Skipping ^"%s^" (immunity)",nick)      
      continue
    }
    console_print(id,"[AMXX] Kicking ^"%s^"",nick)
    if (is_user_bot(b))
      server_cmd("kick #%d",get_user_userid(b))
    else
    {
#if !defined NO_STEAM
      server_cmd("kick #%d ^"You have been dropped because admin has left only specified group of clients^"",get_user_userid(b))
#else
      client_cmd(b,"echo * You have been dropped because admin has left only specified group of clients;disconnect")
#endif
    }
    count++
  }
  console_print(id,"[AMXX] Kicked %d clients",count)
  new authid[32],name[32]
  get_user_authid(id,authid,31)
  get_user_name(id,name,31)
  log_amx("Kick: ^"%s<%d><%s><>^" leave some group (tag1 ^"%s^") (tag2 ^"%s^") (tag3 ^"%s^") (tag4 ^"%s^")",
    name,get_user_userid(id),authid,ltags[0],ltags[1],ltags[2],ltags[3] )
    
  switch(get_cvar_num("amx_show_activity")) {
    case 2: client_print(0,print_chat,"ADMIN %s: leave %s %s %s %s",name,ltags[0],ltags[1],ltags[2],ltags[3])
    case 1: client_print(0,print_chat,"ADMIN: leave %s %s %s %s",ltags[0],ltags[1],ltags[2],ltags[3])
  } 
    
  return PLUGIN_HANDLED
}