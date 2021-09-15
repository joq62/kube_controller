%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(controller_test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
    io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start cluster_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cluster_1(),
    io:format("~p~n",[{"Stop cluster_1()",?MODULE,?FUNCTION_NAME,?LINE}]),


   % io:format("~p~n",[{"Start node_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
   % ok=node_1(),
   % io:format("~p~n",[{"Stop node_1()",?MODULE,?FUNCTION_NAME,?LINE}]),


   % io:format("~p~n",[{"Start pod_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
   % ok=pod_1(),
   % io:format("~p~n",[{"Stop pod_1()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start node_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=node_1(),
  %  io:format("~p~n",[{"Stop node_1()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start new()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=new(),
 %   io:format("~p~n",[{"Stop new()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start create_slave()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=create_slave(),
 %   io:format("~p~n",[{"Stop create_slave()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start deployment()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=deployment(),
 %   io:format("~p~n",[{"Stop deployment()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start deploy_app()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=deploy_app(),
 %   io:format("~p~n",[{"Stop deploy_app()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start pass_3()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=pass_3(),
%    io:format("~p~n",[{"Stop pass_3()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start pass_4()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=pass_4(),
  %  io:format("~p~n",[{"Stop pass_4()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start pass_5()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=pass_5(),
  %  io:format("~p~n",[{"Stop pass_5()",?MODULE,?FUNCTION_NAME,?LINE}]),
 
    
   
      %% End application tests
    io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
    io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
cluster_1()->

    % Initial setup of the dbase
    ok=cluster_lib:init_dbase(),
    ok=db_cluster_spec:create_table(),
    ok=db_cluster_spec:git_init(),
    [{"lgh",
      [{"c0_lgh","c0"},
       {"c2_lgh","c2"},
       {"asus_lgh","joq62-X550CA"}],
      "lgh_cookie"},
     {"varmdo",
      [{"asus_varmdo","joq62-X550CA"}],
      "varmdo_cookie"}]=db_cluster_spec:read_all(),
    
    ok=db_host_spec:create_table(),
    ok=db_host_spec:git_init(),
    [{"c2","192.168.0.202",22,"joq62","festum01"},
     {"c0","192.168.0.200",22,"joq62","festum01"},
     {"joq62-X550CA","192.168.0.100",22,"joq62","festum01"}]=db_host_spec:read_all(),

    %% Check hosts and strive for desired state
    RunningHosts=host:running(),
    StatusHostNodes=[{host:host_node_running(HostId),HostId}||HostId<-RunningHosts],
    PartOfCluster=[HostId||{true,HostId}<-StatusHostNodes],
    MissingInCluster=[HostId||{false,HostId}<-StatusHostNodes],
    [_,_]=PartOfCluster,
    ["joq62-X550CA"]=MissingInCluster,
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
node_1()->
    ssh:start(),
    ok=db_host_spec:create_table(),
    ok=db_host_spec:git_init(),
    
    {"192.168.0.200",22,"joq62","festum01"}=db_host_spec:ssh_info("c0"),
    {"192.168.0.202",22,"joq62","festum01"}=db_host_spec:ssh_info("c2"),
    {error,_}=db_host_spec:ssh_info("glurk"),
    
    [_,_,_]=host:running(),
    

    StartResult=map_start_vm(),
    ok=db_host:create_table(),
    [db_host:create(HostId,Node)||{HostId,{ok,Node}}<-StartResult],
    ok.

map_start_vm()->
    F1=fun start_vm/2,
    F2=fun check_start/3,

    Cookie=atom_to_list(erlang:get_cookie()),
    AllHostNodes=[{db_host_spec:read(HostId),HostId,Cookie}||HostId<-["c0","c2","joq62-X550CA"]],
    Status=mapreduce:start(F1,F2,[],AllHostNodes), 
    Status.


start_vm(Parent,{SshInfo,NodeName,Cookie})->
    {HostId,_IpAddr,_Port,_User,_PassWd}=SshInfo,
    Result=host:create_vm(SshInfo,NodeName,Cookie),
    Parent!{start_vm,{HostId,Result}}.

check_start(start_vm,Vals,_)->
    io:format("Vals= ~p~n",[{Vals,?MODULE,?LINE}]),
    check_start(Vals,[]).

check_start([],Status)->
    Status;
check_start([{HostId,Result}|T],Acc)->
    check_start(T,[{HostId,Result}|Acc]).



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pod_1()->
    
    ok=db_pod_spec:create_table(),
    ok=db_pod_spec:git_init(),
     [{mymath,"1.0.0",
       "https://github.com/joq62/mymath.git",[]}]=db_pod_spec:application_list("mymath"),
    [{mydivi,"1.0.0",
      "https://github.com/joq62/mydivi.git",[]}]=db_pod_spec:application_list("mydivi"),  
    2=db_pod_spec:replicas("mydivi"),
    ["c0","c2"]=db_pod_spec:host_list("mydivi"),
    
    ActiveHostList=db_host:read_all(),
    [_,_,_]=filtering(db_pod_spec:host_list("mymath"),ActiveHostList),
    [{"c2",c2@c2},{"c0",c0@c0}]=filtering(db_pod_spec:host_list("mydivi"),ActiveHostList),
    
    % Create pod - mymath
    Cookie=atom_to_list(erlang:get_cookie()),
    ActiveHostList=db_host:read_all(),
    FilteredList=filtering(db_pod_spec:host_list("mydivi"),ActiveHostList),
    Replicas=db_pod_spec:replicas("mydivi"),
    NumHosts=lists:flatlength(FilteredList),
    Result=if
	       Replicas>NumHosts ->
		   {error,[missing_hosts,"mydivi",FilteredList,Replicas,?FUNCTION_NAME,?MODULE,?LINE]};
	       true->
		   Args="-setcookie "++Cookie,   
		   StartedPods=[start_pod(HostNode,HostId,"pod_"++HostId,Args)||{HostId,HostNode}<-FilteredList],
		 %  g=StartedPods,
		   Dir="pod.deployment",
		   
		   [{App,_AppVsn,GitPath,Env}]=db_pod_spec:application_list("mydivi"),
		   [vm_handler:load_start_app(PodNode,Dir,App,_AppVsn,GitPath,Env)||{ok,PodNode}<-StartedPods]	  
	   end,
    g=sd:get(mydivi),						%[{mydivi,"1.0.0","https://github.com/joq62/mydivi.git",[]}]=  

    ok.

start_pod(HostNode,HostId,NodeName,Args)->
    {ok,Node}=rpc:call(HostNode,slave,start,[HostId,NodeName,Args],5*1000),
    pong=net_adm:ping(Node),
    {ok,Node}.

filtering([],ActiveHostList)->
    ActiveHostList;
filtering(WantedHosts,ActiveHostList) ->
    filtering(WantedHosts,ActiveHostList,[]).
filtering([],_ActiveHostList,FilteredHosts)->
    FilteredHosts;
filtering([HostId|T],ActiveHostList,Acc)->
    NewAcc=case lists:keyfind(HostId,1,ActiveHostList) of
	       false->
		   Acc;
	       {HostId,HostNode}->
		   [{HostId,HostNode}|Acc]
	   end,
    filtering(T,ActiveHostList,NewAcc).
    
scoring()->
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
new()->
    ClusterId="lgh",
    Cookie=atom_to_list(erlang:get_cookie()),
    MonitorNode=node(),
    standby=controller:status(),
    {ok,StartList}=controller:new(ClusterId,MonitorNode,Cookie),
 %   [db_host_status:create(HostId,Node)||{ok,HostId,Node}<-StartList],
    
    Status=controller:hosts_status(),
  %  io:format("Status ~p~n",[Status]),
    [_,_,_]=controller:hosts_running(),
    []=controller:hosts_missing(),
    [_,_,_]=nodes(),
    
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
create_slave()->
    io:format("db_host_status:read_all() ~p~n",[db_host_status:read_all()]),
    Cookie=atom_to_list(erlang:get_cookie()),
    [N1,N2,N3]=nodes(),
   % io:format("[N1,N2,N3] ~p~n",[{N1,N2,N3}]),
    {ok,N11}=rpc:call(N1,slave,start,[rpc:call(N1,net_adm,localhost,[],5*1000),
				      "n11","-setcookie "++Cookie],5*1000),
    {ok,N22}=rpc:call(N2,slave,start,[rpc:call(N2,net_adm,localhost,[],5*1000),
				      "n22","-setcookie "++Cookie],5*1000),
    {ok,N33}=rpc:call(N3,slave,start,[rpc:call(N3,net_adm,localhost,[],5*1000),
				      "n33","-setcookie "++Cookie],5*1000),
    
    [pong,pong,pong]=[net_adm:ping(Node)||Node<-[N11,N22,N33]],
    
    D=date(),
    [D,D,D]=[rpc:call(Node,erlang,date,[],5*1000)||Node<-[N11,N22,N33]],
    
    [{_,2},{_,2},{_,2}]=host:sort_increase_num_vm_host([]),

   
    {ok,N222}=rpc:call(N2,slave,start,[rpc:call(N2,net_adm,localhost,[],5*1000),
				      "n222","-setcookie "++Cookie],5*1000),
    {ok,N333}=rpc:call(N3,slave,start,[rpc:call(N3,net_adm,localhost,[],5*1000),
				       "n333","-setcookie "++Cookie],5*1000),
    {ok,N334}=rpc:call(N3,slave,start,[rpc:call(N3,net_adm,localhost,[],5*1000),
				       "n334","-setcookie "++Cookie],5*1000),
    
    [pong,pong,pong]=[net_adm:ping(Node)||Node<-[N222,N333,N334]],
   
    
    [{_,_},{_,_},{_,_}]=host:sort_increase_num_vm_host([]),
    [{_,_},{_,_}]=host:sort_increase_num_vm_host(["c0","c2"]),
    [{_,_}]=host:sort_increase_num_vm_host(["c0"]),
    

    rpc:call(N1,init,stop,[],4*1000),
    true=ensure_stopped(N1),
    
    {badrpc,nodedown}=rpc:call(N11,erlang,date,[],5*1000),

    [{_,3},{_,4}]=host:sort_increase_num_vm_host([]),
      
    ok.
ensure_stopped(N)->
    ensure_stopped(N,50,50,pong).

ensure_stopped(N,0,_Time,pong)->
    false;
ensure_stopped(_N,_Num,_Time,pang)->
    true;

ensure_stopped(N,Num,Time,pong)->
  %  io:format("Num ~p~n",[Num]),
  %  R=net_adm:ping(N),
 %   io:format("Ping ~p~n",[R]),
    timer:sleep(Time),
    ensure_stopped(N,Num-1,Time,net_adm:ping(N)).    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
deployment()->
    Object1=mymath,
   
   % io:format("db_app_info:read_all() ~p~n",[db_app_info:read_all()]),
    "https://github.com/joq62/mymath.git"=db_app_info:git(Object1),
    []=db_app_info:env(Object1),
    []=db_app_info:hosts(Object1),
    
   
    Object="math_lgh_1",
    "1.0.0"=db_deployment_spec:vsn(Object),
    {3,[]}=db_deployment_spec:replicas(Object),
    [{"mymath","1.0.0"},{"mydivi","1.0.0"}]=db_deployment_spec:apps(Object),
    "lgh"=db_deployment_spec:cluster_id(Object),
  %  io:format("db_deployment_spec:read_all() ~p~n",[db_deployment_spec:read_all()]),
    
    % Create wanted_state
    {NumReplicas,Hosts}=db_deployment_spec:replicas(Object),
    Apps=db_deployment_spec:apps(Object),
    ClusterId=db_deployment_spec:cluster_id(Object),
    ok.


%
%

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
% Decide on hosts
% Create slaves Num + Hosts
% Create appdirs
% Clone apps
% Start apps
% update deployment dbase
% vm_handler:load_start_app(Node,Dir,App,_AppVsn,GitPath,Env)
%
deployment_info(Deployment)->
    {NumReplicas,PreDefinedHosts}=db_deployment_spec:replicas(Deployment),
    AppList=db_deployment_spec:apps(Deployment),
    ClusterId=db_deployment_spec:cluster_id(Deployment),
    Cookie=db_cluster_info:cookie(),
    AppInfoList=[{list_to_atom(AppId),
		  db_app_info:git(list_to_atom(AppId)),
		  db_app_info:env(list_to_atom(AppId))}||{AppId,_Vsn}<-AppList],
    
    % Get available hosts
    {error,[num_replicas,0]}=host:available_hosts(PreDefinedHosts,0), 
    [_,_,_,_,_]=host:available_hosts(PreDefinedHosts,5), 
    Hosts=host:available_hosts(PreDefinedHosts,NumReplicas),
   
    {ok,Hosts,AppInfoList,Cookie}.
     

deploy_app()->

    %Get deployment information
    Deployment="math_lgh_1",
    {ok,Hosts,AppInfoList,Cookie}=deployment_info(Deployment),
 
% {Result,Deployment,HostId,Worker,Dir,App}
% 
    %Part of start up 
    StartResult=create_deployment(Hosts,AppInfoList,Deployment,Cookie,[]),

    [ {Result,Deployment,HostId,Worker,Dir,App}|_]=StartResult,
    Deployment=db_deployment_status:deployment(Worker),

    % Test sd:get(App),
    [MyDiviNode|_]=db_deployment_status:get(mydivi,Worker),
    
   % io:format("StartResult ~p~n",[StartResult]),
   % io:format("sd:get(mymath) ~p~n",[sd:get(mymath)]),
   % io:format("sd:get(mydivi) ~p~n",[sd:get(mydivi)]),

    10.0=rpc:call(MyDiviNode,mydivi,divi,[20,2],5*1000),
      
    %% 
    db_deployment_status:delete(Deployment),
    []=db_deployment_status:read_all(),
   % io:format("[]=db_deployment_status:read_all() ~p~n",[db_deployment_status:read_all()]),
    ok.


create_deployment([],_AppInfoList,_Deployment,_Cookie,StartResults)->
    OneList=lists:append(StartResults),
    [db_deployment_status:create(Deployment,HostId,Node,Dir,App)||{ok,Deployment,HostId,Node,Dir,App}<-OneList],
    OneList;
create_deployment([HostId|T],AppInfoList,Deployment,Cookie,Acc)->
    StartResult=create_worker_start_apps_on_host(HostId,AppInfoList,Deployment,Cookie),
    create_deployment(T,AppInfoList,Deployment,Cookie,[StartResult|Acc]).


create_worker_start_apps_on_host(HostId,AppInfoList,Deployment,Cookie)->
    Unit=microsecond,
    Unique=integer_to_list(erlang:system_time(Unit)),
    NodeName=Unique++"_"++Deployment,
    Dir=NodeName++".deployment",
    HostNode=db_host_status:node(HostId),
    StartResult =case vm_handler:create_worker(HostNode,HostId,NodeName,Dir,Cookie) of
		     {error,Reason}->
			 {error,Reason};
		     {ok,Worker}->
			 [{vm_handler:load_start_app(Worker,Dir,App,glurk,GitPath,Env),Deployment,HostId,Worker,Dir,App}||{App,GitPath,Env}<-AppInfoList]
		 end, 
    StartResult.

delete_deployment(Deployment)->
    ok.
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_2()->
     ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

setup()->
%    ok=dbase_lib:initial_start_mnesia(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
  %  application:stop(controller),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
