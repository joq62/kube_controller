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

    io:format("~p~n",[{"Start pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=pass_0(),
    io:format("~p~n",[{"Stop pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start pass_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=pass_1(),
  %  io:format("~p~n",[{"Stop pass_1()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start pass_2()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=pass_2(),
%    io:format("~p~n",[{"Stop pass_2()",?MODULE,?FUNCTION_NAME,?LINE}]),

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
pass_0()->
    ClusterId="lgh",
    AllDepSpecs=db_deployment_spec:key_cluster_id(ClusterId),
    DepSpecPodsInfoList=[{DepId,Pods}||{DepId,_,Pods,_}<-AllDepSpecs],

    %% WantedPods
    WantedPods=lists:append([get_pod_spec(DepId,Pods)||{DepId,Pods}<-DepSpecPodsInfoList]),
    io:format("WantedPods ~p~n",[{WantedPods,?MODULE,?LINE}]),   
 
    AvailableHosts=get_available_hosts(ClusterId),
    io:format("AvailableHosts ~p~n",[{AvailableHosts,?MODULE,?LINE}]),

    DesiredState=lists:append(desired_state(WantedPods,AvailableHosts)),
    io:format("DesiredState ~p~n",[{DesiredState,?MODULE,?LINE}]),
    
    StartResult=create_pod(DesiredState,ClusterId,[]),
    io:format("StartResult ~p~n",[{StartResult,?MODULE,?LINE}]),

    io:format("sd:all() ~p~n",[{sd:all(),?MODULE,?LINE}]),
    
    ok.
create_pod([],_ClusterName,StartResult)->
    StartResult;
create_pod([PodInfo|T],ClusterName,Acc)->
    UniqueId=integer_to_list(erlang:system_time(microsecond)), 
    NodeName=UniqueId++"_"++ClusterName,
    Dir=UniqueId++"."++ClusterName,
    Cookie=db_cluster_spec:cookie(ClusterName),
    io:format("PodInfo ~p~n",[{PodInfo,?MODULE,?LINE}]),
    R=pod_controller:new(PodInfo,NodeName,Dir,Cookie),
    create_pod(T,ClusterName,[{R,PodInfo}|Acc]).
	
desired_state(WantedPods,AvailableHosts)->
    desired_state(WantedPods,AvailableHosts,[]).
    
desired_state([],_AvailableHosts,DesiredState)->
    DesiredState;
desired_state([Pods|T],AvailableHosts,Acc)->
    {info,DepId,Name,Vsn,Num}=lists:keyfind(info,1,Pods),
    {containers,Containers}=lists:keyfind(containers,1,Pods),
    {wanted_hosts,WantedHosts}=lists:keyfind(wanted_hosts,1,Pods),
    Result=case filter_hosts(WantedHosts,AvailableHosts) of
	       {error,Reason}->
		   {error,Reason};
	       Candidates->
		   Len=lists:flatlength(Candidates),
		   case Len<Num of
		       true->
			   {error,['not enough of hosts',Candidates,Num,?MODULE,?FUNCTION_NAME,?LINE]};
		       false->
			   create_deployment(DepId,Name,Vsn,Containers,Candidates,Num,[])
		   end
	   end,
    desired_state(T,AvailableHosts,[Result|Acc]).
   
create_deployment(_DepId,_Name,_Vsn,_Containers,_Candidates,0,DesiredDeployment)-> 
    DesiredDeployment;
create_deployment(DepId,Name,Vsn,Containers,Candidates,Num,Acc)->
    Info=[{info,DepId,Name,Vsn,Num},{containers,Containers},{host,lists:nth(Num,Candidates)}],
    create_deployment(DepId,Name,Vsn,Containers,Candidates,Num-1,[Info|Acc]).

    
filter_hosts(_,[])->
    {error,[eexists,hosts,?MODULE,?FUNCTION_NAME,?LINE]};
filter_hosts([],AvailableHosts)->
    AvailableHosts;
filter_hosts(WantedHosts,AvailableHosts) ->
    [HostInfo||HostInfo<-WantedHosts,
	       lists:member(HostInfo,AvailableHosts)].    

get_available_hosts(ClusterId)->
    AllClusterHosts=db_cluster_spec:hosts(ClusterId),
  %  io:format("AllHosts ~p~n",[{AllHosts,?MODULE,?LINE}]),
    AllRunningHosts=running_hosts(),   
   % io:format("AllRunningHosts ~p~n",[{AllRunningHosts,?MODULE,?LINE}]),

    AvailableHosts=[{Alias,HostId}||{Alias,HostId}<-AllClusterHosts,
				    lists:member({Alias,HostId},AllRunningHosts)],
    %io:format("AvailableHosts ~p~n",[{AvailableHosts,?MODULE,?LINE}]),
    AvailableHosts.

running_hosts()->
    {RunningHosts,_}=iaas:status_all_hosts(),
    Running=[{Alias,HostId}||{running,Alias,HostId,_Ip,_Port}<-RunningHosts],
    Running.
    

p_info(L)->
    io:format("info ~p~n",[{[lists:keyfind(info,1,X)||X<-L],?MODULE,?LINE}]).
    
get_pod_spec(DepId,Pods)->
    get_pod_spec(Pods,DepId,[]).
get_pod_spec([],_DepId,ExtractedList)->
    ExtractedList;
get_pod_spec([{Name,Vsn,Num}|T],DepId,Acc)->
    Containers=db_pod_spec:containers(Name),
    WantedHosts=db_pod_spec:wanted_hosts(Name),
    get_pod_spec(T,DepId,[[{info,DepId,Name,Vsn,Num},{containers,Containers},{wanted_hosts,WantedHosts}]|Acc]).

    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_1()->
 
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_5()->

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_3()->
  
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_4()->
  
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
