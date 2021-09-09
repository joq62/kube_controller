%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : 
%%% ToDo 
%%% 1. New cluster 
%%% 2. Check existing cluster -> restart missing node vms
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(cluster_lib).    
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("kube_logger.hrl").
%%---------------------------------------------------------------------
%% Records & defintions
%%---------------------------------------------------------------------
%missing clusters
%running clusters

%-define(HostNodeName(ClusterId,HostId),HostId++"_"++ClusterId).
%-define(HostNode(ClusterId,HostId),list_to_atom(HostId++"_"++ClusterId++"@"++HostId)).

-define(KubeletNodeName(ClusterId,HostId),ClusterId++"_"++HostId++"_kubelet").
%-define(KubeletNode(ClusterId,Alias,HostId),list_to_atom(ClusterId++"_"++"kubelet"++"_"++Alias++"@"++HostId)).
%% --------------------------------------------------------------------
-export([
	 start_host_nodes/1,
	 stop_node/3,
	 load_start/3,
	 stop_unload/3,

	 strive_desired_state/0
	]).


% Deployment: 
% {name,"math_lgh_1"}.
% {vsn,"1.0.0"}.
% {replicas,{3,[]}.
% {apps,[{"mymath","1.0.0"},
%       {"mydivi","1.0.0"}]}.	
% {cluster_id,"lgh"}.

% {application, support,
% [{description, "SUPPORT" },
% {vsn, "1.0.0" },
% {modules, 
%	  [support_app,support_sup,support,support_server]},
% {registered,[support]},
% {applications, [kernel,stdlib]},
% {mod, {support_app,[]}},
% {start_phases, []},
% {git_path,"https://github.com/joq62/support.git"},
% {env,[]}
% {hosts_needed,[]}
% ]}.



%% ====================================================================
%% External functions
%% ====================================================================  
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start_host_nodes(ClusterId)->
    F1=fun map_start_host_node/2,
    F2=fun host_node_start/3,
    %HostInfo {HostId,Ip,SshPort,UId,Pwd}
    AllHostsInfo=db_host_info:read_all(),
    Cookie=rpc:call(node(),db_cluster_info,cookie,[],5*1000),
    StartList=[{HostId,Ip,SshPort,UId,Pwd,
		"host_"++ClusterId++"_"++HostId,Cookie}||{HostId,Ip,SshPort,UId,Pwd}<-AllHostsInfo],
    StartResult=mapreduce:start(F1,F2,[],StartList),
    Result=case [{error,Reason}||{error,Reason}<-StartResult] of
	       []->
		   {ok,StartResult};
	       _->
		   {error,StartResult}
	   end,
    Result.
    
    

map_start_host_node(Parent,{HostId,Ip,SshPort,UId,Pwd,NodeName,Cookie})->
    Parent!{start_host_node,start_host_node({HostId,Ip,SshPort,UId,Pwd,NodeName,Cookie})}.

start_host_node({HostId,Ip,SshPort,UId,Pwd,NodeName,Cookie})->
    Result=case vm_handler:create_vm({HostId,Ip,SshPort,UId,Pwd},NodeName,Cookie) of
	       {error,Reason}->
		   ?PrintLog(ticket,"error",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,Reason};
	       {badrpc,Reason}->
		   ?PrintLog(ticket,"badrpc",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,[badrpc,Reason]};
	       {ok,Node}->
		   {ok,HostId,Node}
	   end,
    Result.

host_node_start(start_host_node,Vals,_)->
   host_node_start(Vals,[]).
host_node_start([],StartResult)->
    StartResult;
host_node_start([StartResult|T],Acc) ->
    host_node_start(T,[StartResult|Acc]).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
strive_desired_state()->
    ClusterId=rpc:call(node(),db_cluster_info,cluster,[],5*1000),
    Result= case find_nodes_wo_cluster_loaded() of
		 {error,Reason}->
		    {error,Reason};
		{ok,FindNodeWOClusterLoaded,RunningHosts,MissingHosts}->
		    ?PrintLog(debug,"",[FindNodeWOClusterLoaded,RunningHosts,MissingHosts,?FUNCTION_NAME,?MODULE,?LINE]), 
		 %   case strive_desired_state(ClusterId,FindNodeWOClusterLoaded) of
		    case FindNodeWOClusterLoaded of
			{error,Reason}->
			    {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]};
			FindNodeWOClusterLoaded->
			    DeploymentSpecName="node",
			   % StartClusterNodesInfo=start_cluster_nodes(FindNodeWOClusterLoaded,ClusterId,DeploymentSpecName),
			    StartClusterNodesInfo={ok,[]},
			    case StartClusterNodesInfo of
				{error,Reason}->
				    {error,Reason};
				{ok,StartInfo}->
	%			    ?PrintLog(log,"RunningHosts ",[RunningHosts ,?FUNCTION_NAME,?MODULE,?LINE]),
	%			    ?PrintLog(log,"MissingHosts ",[MissingHosts ,?FUNCTION_NAME,?MODULE,?LINE]),
				    ClusterStatus=examine_state(StartInfo,RunningHosts,MissingHosts),
			%	    ?PrintLog(log,"ClusterStatus ",[ClusterStatus ,?FUNCTION_NAME,?MODULE,?LINE]),
				    ClusterStatus			    
			    end
		    end
	    end,
    Result.

examine_state([],_RunningHosts,[])->
    {ok,{"In desired state",[]}};
examine_state(StartInfo,_RunningHosts,[])->
    {error,{"Starting found hosts without cluster",[StartInfo]}};
examine_state([],_RunningHosts,MissingHosts)->
    {error,{"Missing hosts",[MissingHosts]}};
examine_state(StartInfo,_RunningHosts,MissingHosts)->
    {error,{"Starting found Host and missing hosts",[StartInfo,MissingHosts]}}.
%examine_state(StartInfo,RunningHosts,MissingHosts)->
%    {error,{unmatched,[StartInfo,RunningHosts,MissingHosts]}}.

		
find_nodes_wo_cluster_loaded()->
    Result=case rpc:call(node(),host,status_all_hosts,[],20*1000) of
	       {badrpc,Reason}->
		   {error,[badrpc,Reason,?FUNCTION_NAME,?MODULE,?LINE]};
	       {error,Reason}->
		   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]};
	       {ok,RunningHosts,MissingHosts}-> 
		   HostsWithClustere=get_nodes_with_cluster_runing(),
		   FindNodeWOClusterLoaded=[{Alias,HostId}||{Alias,HostId}<-RunningHosts,
							   false==lists:keymember(HostId,2,HostsWithClustere)], 
		   {ok,FindNodeWOClusterLoaded,RunningHosts,MissingHosts}
	   end,
    Result.
get_nodes_with_cluster_runing()->   
    
    ClusterePing=[rpc:call(Node,cluster,ping,[],2*1000)||Node<-[node()|nodes()]],
    X=[{ClusterNode,rpc:call(ClusterNode,inet,gethostname,[],5*1000)}||{pong,ClusterNode,_}<-ClusterePing],
    HostsWithClustere=[{ClusterNode,HostId}||{ClusterNode,{ok,HostId}}<-X],
    HostsWithClustere.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start_cluster_nodes(HostWithOutCluster,ClusterId,DeploymentSpecName)->
    F1=fun map_create_cluster_node/2,
    F2=fun check_cluster_node_start/3,
    StartList=[{HostInfo,ClusterId,DeploymentSpecName}||HostInfo<-HostWithOutCluster],
    StartResult=mapreduce:start(F1,F2,[],StartList),
    Result=case [{error,Reason}||{error,Reason}<-StartResult] of
	       []->
		   {ok,StartResult};
	       _->
		   {error,StartResult}
	   end,
    Result.

map_create_cluster_node(Parent,{HostInfo,ClusterId,DeploymentSpecName})->
    Parent!{create_cluster_node,start_cluster_node(HostInfo,ClusterId,DeploymentSpecName)}.


check_cluster_node_start(create_cluster_node,Vals,_)->
    check_cluster_node_start(Vals,[]).
check_cluster_node_start([],StartResult)->
    StartResult;
check_cluster_node_start([StartResult|T],Acc) ->
    check_cluster_node_start(T,[StartResult|Acc]).
 
start_cluster_node(HostId,ClusterId,DeploymentId)->
 %   DeploymentId="cluster",
    DeploymentVsn=rpc:call(node(),db_deployment_spec,vsn,[DeploymentId],5*1000),
    Cookie=rpc:call(node(),db_cluster_spec,cookie,[ClusterId],5*1000),
    NodeName="cluster"++"_"++ClusterId++"_"++HostId,
    Dir=NodeName++".deployment",  
    {Ip,SshPort,UId,Pwd}=rpc:call(node(),db_host_info,ssh_info,[HostId],5*1000),
    Result=case vm_handler:create_vm({HostId,Ip,SshPort,UId,Pwd},NodeName,Dir,Cookie) of
	       {error,Reason}->
		   ?PrintLog(ticket,"error",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,Reason};
	       {badrpc,Reason}->
		   ?PrintLog(ticket,"badrpc",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
		    {error,[badrpc,Reason]};
	       {ok,Node}->
		   LoadStart=start_cluster_node([support],Node,Dir,[]),
		      
		   ?PrintLog(debug,"LoadStart",[LoadStart,?FUNCTION_NAME,?MODULE,?LINE]),
		   case [{error,Reason}||{error,Reason}<-LoadStart] of
		       []->
			   DbaseAction=[sd:call(etcd,db_deployment,create,[DeploymentId,DeploymentVsn,Node,Dir,XAppId,HostId,ClusterId,running],5*1000)||{{ok,_Info},XAppId}<-LoadStart],
			   ?PrintLog(debug,"DbaseAction",[DbaseAction,?FUNCTION_NAME,?MODULE,?LINE]),
			   case [R||R<-DbaseAction,
				 {atomic,ok}/=R] of
			       []->
				   {ok,LoadStart};
			       Reason->
				   ?PrintLog(ticket,"error",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
				   {error,Reason}
			   end
		   end
	   end,
    Result.
%		   case sd:call(etcd,db_cluster,create,[PodId,HostId,ClusterId,Node,Dir,Node,Cookie,[]],5*1000) of
start_cluster_node([],_,_,LoadStart)->
    LoadStart;
start_cluster_node([App|T],Node,Dir,Acc)->
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
stop_node(Pod,Container,Dir)->
    Result=case container:stop_unload(od,Container,Dir) of
	       {error,Reason}->
		   ?PrintLog(ticket,"error",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,[Reason,Pod,Container,Dir,?FUNCTION_NAME,?MODULE,?LINE]};
	       ok->
		   case pod:stop_node(Pod) of
		       {error,Reason}->
			   ?PrintLog(ticket,"error",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
			   {error,Reason};
		       ok ->
			   case sd:call(etcd,db_deployment,delete,[Pod],5*1000) of
			       {atomic,ok}->
				   ok;
			       Reason->
				   ?PrintLog(ticket,"error",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
				   {error,[Reason,Pod,Container,Dir,?FUNCTION_NAME,?MODULE,?LINE]}			       
			   end
		   end
		  
	   end,
    Result.		 
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
load_start(Pod,Container,Dir)->
    Result=case container:load_start(Pod,Container,Dir) of
	       {error,Reason}->
		   ?PrintLog(ticket,"error",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,Reason};
	       ok->
		   case sd:call(etcd,db_cluster,add_container,[Pod,Container],5*1000) of
		       {atomic,ok}->			   
			   ok;
		       Reason->
			   ?PrintLog(ticket,"error",[Reason,?FUNCTION_NAME,?MODULE,?LINE]),
			   {error,[Reason,Pod,Container,?FUNCTION_NAME,?MODULE,?LINE]}
		   end
	   end,
    Result.	    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
stop_unload(Pod,Container,Dir)->
    Result=case container:stop_unload(Pod,Container,Dir) of
	         {error,Reason}->
		   {error,[Reason,Pod,Container,Dir,?FUNCTION_NAME,?MODULE,?LINE]};
   
	       ok->
		   case sd:call(etcd,db_cluster,delete_container,[Pod,Container],5*1000) of
		       {atomic,ok}->
			   ok;
		       Reason->
			   {error,[Reason,Pod,Container,Dir,?FUNCTION_NAME,?MODULE,?LINE]}			       
		   end
	   end,
    Result.
