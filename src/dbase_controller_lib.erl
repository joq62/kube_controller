%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dbase_controller_lib).   

    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-define(ClusterConfigPath,"https://github.com/joq62/cluster_config.git").
-define(ClusterConfigDirName,"cluster_config").
-define(ClusterConfigFile,"cluster_config/cluster.config").
-define(ClusterConfigFileName,"cluster.config").

-define(HostConfigPath,"https://github.com/joq62/host_config.git").
-define(HostConfigDirName,"host_config").
-define(HostConfigFile,"host_config/hosts.config").
-define(HostConfigFileName,"hosts.config").

-define(PodSpecsPath,"https://github.com/joq62/pod_specs.git").
-define(PodSpecsDirName,"pod_specs").

-define(DeploymentSpecsPath,"https://github.com/joq62/deployment.git").
-define(DeploymentSpecsDirName,"deployment").

-define(TempDir,"temp_dir").

-define(LockId,controller).
%% --------------------------------------------------------------------


%% External exports
-export([
	 check_mnesia_status/0,
	 initial_start_mnesia/0,
	 init_tables/0,
	 create_tables/0,
	 init_distributed_mnesia/1,
	 add_nodes/1
	]).

-define(WAIT_FOR_TABLES,5000).

%% ====================================================================
%% External functions
%% ====================================================================

check_mnesia_status()->
    Status=case mnesia:system_info() of
	       no->
		   standby_controller;
	       yes ->
		   case mnesia:system_info(tables) of
		       []->
			   {error,[mnesia,system_info,?FUNCTION_NAME,?MODULE,?LINE]};
		       [schema]->
			   leader_controller_mnesia_not_initated;
		       _Tables ->
			   leader_controller_mnesia_initiated
		   end
	   end,
    Status.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
initial_start_mnesia()->
    mnesia:stop(),
    mnesia:delete_schema([node]),
    mnesia:start(),
    ok.
init_tables()->
    ok=db_host_info:create_table(),
    ok=init_host_info(),

    ok=db_sd:create_table(),
    ok=db_lock:create_table(),
    {atomic,ok}=db_lock:create(?LockId,0),
    true=db_lock:is_open(?LockId),    
    ok.

init_distributed_mnesia(Nodes)->
    StopResult=[rpc:call(Node,mnesia,stop,[],5*1000)||Node<-Nodes],
    Result=case [Error||Error<-StopResult,Error/=stopped] of
	       []->
		   case mnesia:delete_schema(Nodes) of
		       ok->
			   StartResult=[rpc:call(Node,mnesia,start,[],5*1000)||Node<-Nodes],
			   case [Error||Error<-StartResult,Error/=ok] of
			       []->
				   ok;
			       Reason->
				   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
			   end;
		       Reason->
			   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
		   end;
	       Reason->
		   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
create_tables()->
    %% 
    ok=db_host_info:create_table(),
    [db_host_info:add_node(Node,ram_copies)||Node<-nodes()],
    ok=init_host_info(),

    ok=db_sd:create_table(),
    [db_sd:add_node(Node,ram_copies)||Node<-nodes()],
    
    ok=db_lock:create_table(),
    [db_lock:add_node(Node,ram_copies)||Node<-nodes()],
    {atomic,ok}=db_lock:create(?LockId,0),
    false=db_lock:is_open(?LockId),
    ok.

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
add_nodes(Nodes)->
    [db_host_info:add_node(Node,ram_copies)||Node<-Nodes],
    [db_lock:add_node(Node,ram_copies)||Node<-Nodes],
    [db_sd:add_node(Node,ram_copies)||Node<-Nodes],
    ok.

    
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
init_host_info()->
    os:cmd("rm -rf "++?HostConfigDirName),
    os:cmd("git clone "++?HostConfigPath),
    HostConfigFile=filename:join([?HostConfigDirName,?HostConfigFileName]),
    {ok,Info}=file:consult(HostConfigFile),
   % io:format("~p~n",[{Debug,?MODULE,?LINE}]),
    ok=init_host_info(Info,[]),
    os:cmd("rm -rf "++?HostConfigDirName),
    ok.
init_host_info([],Result)->
    R=[R||R<-Result,
	  R/={atomic,ok}],
    case R of
	[]->
	    ok;
	R->
	    {error,[R]}
    end;
    
init_host_info([[{host_id,HostId},{ip,Ip},{ssh_port,SshPort},{uid,UId},{pwd,Pwd}]|T],Acc)->
    R=db_host_info:create(HostId,Ip,SshPort,UId,Pwd),
    init_host_info(T,[R|Acc]).
    

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
