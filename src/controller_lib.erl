%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(controller_lib).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------

% New final ?

-export([
	 desired_state/1,
	 status_all_pods/0,
	 strive_desired_state/1

	]).



%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
desired_state(ClusterId)->
    AllDepSpecs=db_deployment_spec:key_cluster_id(ClusterId),
    DepSpecPodsInfoList=[{DepId,Pods}||{DepId,_,Pods,_}<-AllDepSpecs],
    
    DepSpecPodsInfoList.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
status_all_pods()->
    {ok,ClusterIdAtom}=application:get_env(controller,cluster_id),
    ClusterId=atom_to_list(ClusterIdAtom),
    Pods2Deploy=db_deployment_spec:pods(ClusterId),
 %   io:format("Pods2Deploy ~p~n",[{Pods2Deploy,?FUNCTION_NAME,?MODULE,?LINE}]),

  %  io:format("db_pod_spec ~p~n",[{db_pod_spec:read_all(),?FUNCTION_NAME,?MODULE,?LINE}]),

    AppInfo=[{db_pod_spec:app_id(PodId),DeploymentId,PodId,HostId}||{DeploymentId,PodId,HostId}<-Pods2Deploy],
 %   io:format("PodIds ~p~n",[{AppInfo,?FUNCTION_NAME,?MODULE,?LINE}]),
    
    %% 
    SdGet=[{sd:get(list_to_atom(AppId)),AppId,DeploymentId,PodId,HostId}||{AppId,DeploymentId,PodId,HostId}<-AppInfo],
  %  io:format("SdGet ~p~n",[{SdGet,?FUNCTION_NAME,?MODULE,?LINE}]),
    
    %%
    {Running,Missing}=check_status(SdGet,[],[]),
  %  io:format("Running ~p~n",[{Running,?FUNCTION_NAME,?MODULE,?LINE}]),
  %  io:format("Missing ~p~n",[{Missing,?FUNCTION_NAME,?MODULE,?LINE}]),
    {ok,Running,Missing}.

    %%

check_status([],Running,Missing)->
    {Running,Missing};
check_status([{[],AppId,DeploymentId,PodId,HostId}|T],R,M)->
    check_status(T,R,[{AppId,DeploymentId,PodId,HostId}|M]);
check_status([{Nodes,AppId,DeploymentId,PodId,HostId}|T],R,M)->
    VmIdsHostIds=[misc_node:vmid_hostid(Node)||Node<-Nodes],
    case lists:keymember(HostId,2,VmIdsHostIds) of
	true->
	    NewR=[{AppId,DeploymentId,PodId,HostId}|R],
	    NewM=M;
	false->
	    NewR=R,
	    NewM=[{AppId,DeploymentId,PodId,HostId}|M]
    end,
    check_status(T,NewR,NewM).

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
strive_desired_state({[],[]})->
    {[],[]};
strive_desired_state({_RunningPods,MissingPods})->
    _StarResult=load_start(MissingPods,[]),
   % io:format("StarResult ~p~n",[{StarResult,?FUNCTION_NAME,?MODULE,?LINE}]),
    {ok,Running,Missing}=status_all_pods(),
    {Running,Missing}.

load_start([],StarResult)->
    StarResult;
load_start([{_AppId,_DeploymentId,PodId,HostId}|T],Acc)->
    R=case pod:create(HostId) of
	  {ok,Ref}->
	      pod:load_start(PodId,Ref);
	  Err ->
	      {error,[Err,?FUNCTION_NAME,?MODULE,?LINE]}
      end,
    load_start(T,[R|Acc]).
