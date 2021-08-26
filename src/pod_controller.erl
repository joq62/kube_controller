%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : 
%%% ToDo 
%%% 1. New cluster
%%% 2. Check existing cluster -> restart missing node vms
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(pod_controller).     
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("kube_logger.hrl").
%%---------------------------------------------------------------------
%% Records & defintions
%%---------------------------------------------------------------------
%missing clusters
%running clusters

%% --------------------------------------------------------------------

-export([
	 new/4,
	 delete_pod/2,
	 create_node/7,  
	 delete_node/1,
	 delete_node/2
	]).

%% ====================================================================
%% External functions
%% ====================================================================  

% [{info,"dep_2","support_c0_lgh","1.0.0",1},
%  {containers,[{"support","1.0.0","https://github.com/joq62/support.git",[]}]},
%  {host,{"c0_lgh","c0"}}]

new(PodInfo,NodeName,Dir,Cookie)->
    io:format("PodInfo,NodeName,Dir,Cookie ~p~n",[{PodInfo,NodeName,Dir,Cookie,?MODULE,?LINE}]),
    {host,{Alias,_HostId}}=lists:keyfind(host,1,PodInfo),
    Result=case create_vm(Alias,NodeName,Dir,Cookie) of
	       {error,Reason}->
		   {error,Reason};
	       {ok,Pod}->
		   {containers,ContainerInfo}=lists:keyfind(containers,1,PodInfo),
		   start_containers(ContainerInfo,Pod,Dir,[])
	   end,
    Result.
		   

create_vm(Alias,NodeName,Dir,Cookie)->
    [{Alias,HostId,Ip,SshPort,UId,Pwd}]=db_host_info:read(Alias),
    ErlCallArgs="-c "++Cookie++" "++"-sname "++NodeName,
    Node=list_to_atom(NodeName++"@"++HostId),    
    true=erlang:set_cookie(Node,list_to_atom(Cookie)),
    true=erlang:set_cookie(node(),list_to_atom(Cookie)),
    Result=case create_node(Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs) of
	       {error,Reason}->
		   {error,Reason};
	       {ok,Pod}->
		   case rpc:call(Pod,file,make_dir,[Dir],5*1000) of
		       {error,Reason} ->
			   {error,[Reason,Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs,?FUNCTION_NAME,?MODULE,?LINE]};
		       ok->
			   {ok,Pod}
		   end
	   end, 
    Result.


start_containers([],_Pod,_Dir,StartResult)->
    StartResult;
start_containers([{AppId,AppVsn,GitPath,AppEnv}|T],Pod,Dir,Acc)->
    NewAcc=case container:load(AppId,AppVsn,GitPath,AppEnv,Pod,Dir) of
	       {error,Reason}->
		   [{error,[Reason,AppId,AppVsn,GitPath,AppEnv,Pod,Dir,?FUNCTION_NAME,?MODULE,?LINE]}|Acc];
	       ok->
		   case container:start(AppId,Pod) of
		       {error,Reason}->
			   [{error,[Reason,AppId,AppVsn,GitPath,AppEnv,Pod,Dir,?FUNCTION_NAME,?MODULE,?LINE]}|Acc];
		       ok->
			   [{ok,AppId}|Acc]
		   end
	   end,
    start_containers(T,Pod,Dir,NewAcc).  
   
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Creates a slave node via HostNode 
%% NodeName=pod_microseconds_clusterId_HostId
%% PodDir=clusterId/pod_microseconds
%% AppDir=PodDir/AppId
%% AppPa=AppDir/ebin
%% Returns: non
%% --------------------------------------------------------------------
delete_pod(PodName,Pod)->
    Result=case db_pod_spec:deployment(PodName,Pod) of
	       []->
		   {error,["eexists",PodName,?FUNCTION_NAME,?MODULE,?LINE]};
	       {Pod,Dir,_HostId,_PodStatus,_ContainerStatus}->
		   [container:unload_stop(AppId,Pod)||{AppId,_Vsn,_GitPath,_Env}<-db_pod_spec:containers(PodName)],
		   rpc:call(Pod,os,cmd,["rm -rf "++Dir],5*1000),
		   rpc:call(Pod,init,stop,[],5*1000),		   
		   case node_stopped(Pod) of
		       false->
			   {error,["node not stopped",PodName,Pod,?FUNCTION_NAME,?MODULE,?LINE]};
		       true->
			   ok
		   end
	   end,
    Result.

delete_node(Node)->
    rpc:call(Node,init,stop,[],5*1000),
    ok.
delete_node(Node,Dir)->
    rpc:call(Node,os,cmd,["rm -rf "++Dir],5*1000),
    rpc:call(Node,init,stop,[],5*1000),
    ok.

%create_node(Alias,NodeName,Cookie)->
%    [{Alias,HostId,Ip,SshPort,UId,Pwd}]=db_host_info:read(Alias),
%    ErlCallArgs="-c "++Cookie++" "++"-sname "++NodeName,
%    Node=list_to_atom(NodeName++"@"++HostId),    
%    true=erlang:set_cookie(Node,list_to_atom(Cookie)),
%    true=erlang:set_cookie(node(),list_to_atom(Cookie)),
%    Result=create_node(Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs),
%    Result.

create_node(Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs)->    
    ErlCmd="erl_call -s "++ErlCallArgs, 
    SshCmd="nohup "++ErlCmd++" &",
    ErlCallResult=rpc:call(node(),my_ssh,ssh_send,[Ip,SshPort,UId,Pwd,SshCmd,3*5000],4*5000),
    Result=case ErlCallResult of
	       {badrpc,timeout}->
		   ?PrintLog(ticket,"Failed to start node",[Ip,SshPort,UId,Pwd,NodeName,ErlCallArgs,badrpc,timeout,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,[{badrpc,timeout},Ip,SshPort,UId,Pwd,NodeName,ErlCallArgs,?FUNCTION_NAME,?MODULE,?LINE]};
	       {error,Reason}->
		   ?PrintLog(ticket,"Failed to start node",[Ip,SshPort,UId,Pwd,NodeName,ErlCallArgs,error,Reason,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]};
	       StartResult->
		   Node=list_to_atom(NodeName++"@"++HostId),
		   case node_started(Node) of
		       true->
			  % ?PrintLog(debug,"  {atomic,ok}",[ClusterAddResult,Node,HostId,?FUNCTION_NAME,?MODULE,?LINE]),
			   {ok,Node};
		       false->
			   ?PrintLog(ticket,"Failed to connect to node",[Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs,?FUNCTION_NAME,?MODULE,?LINE]),
			   {error,["Failed to connect to node",Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs,?MODULE,?FUNCTION_NAME,?LINE]}
		   end
	   end,
    Result.
		   
	      
node_started(Node)->
    check_started(50,Node,10,false).
    
check_started(_N,_Vm,_SleepTime,true)->
   true;
check_started(0,_Vm,_SleepTime,Result)->
    Result;
check_started(N,Vm,SleepTime,_Result)->
 %   io:format("net_Adm ~p~n",[net_adm:ping(Vm)]),
    NewResult= case net_adm:ping(Vm) of
	%case rpc:call(node(),net_adm,ping,[Vm],1000) of
		  pong->
		     true;
		  pang->
		       timer:sleep(SleepTime),
		       false;
		   {badrpc,_}->
		       timer:sleep(SleepTime),
		       false
	      end,
    check_started(N-1,Vm,SleepTime,NewResult).

node_stopped(Node)->
    check_stopped(100,Node,50,false).
    
check_stopped(_N,_Vm,_SleepTime,true)->
   true;
check_stopped(0,_Vm,_SleepTime,Result)->
    Result;
check_stopped(N,Vm,SleepTime,_Result)->
 %   io:format("net_Adm ~p~n",[net_adm:ping(Vm)]),
    NewResult= case net_adm:ping(Vm) of
	%case rpc:call(node(),net_adm,ping,[Vm],1000) of
		  pang->
		     true;
		  pong->
		       timer:sleep(SleepTime),
		       false;
		   {badrpc,_}->
		       true
	       end,
    check_stopped(N-1,Vm,SleepTime,NewResult).

