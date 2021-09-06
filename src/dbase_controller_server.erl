%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc : represent a logical vm  
%%%  
%%% Supports the system with standard erlang vm functionality, load and start
%%% of an erlang application (downloaded from git hub) and "dns" support 
%%% 
%%% Make and start the board start SW.
%%%  boot_service initiates tcp_server and l0isten on port
%%%  Then it's standby and waits for controller to detect the board and start to load applications
%%% 
%%%     
%%% -------------------------------------------------------------------
-module(dbase_controller_server). 

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%
%% --------------------------------------------------------------------
-define(check_started_extra_node_time_out,10000).

%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{}).

%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================


%% server interface
-export([
	 cluster_info/0,
	 cluster_info/1,
	 catalog_info/0,
	 host_info/0
	]).


-export([is_leader/0,
	 host_info_create/5,
	 host_info_delete/5,
	 host_info_read/1,
	 host_info_all/0,
	 cluster_info_create/2,
	 cluster_name/0,
	 cluster_cookie/0]).

-export([install/0]).

-export([add_node/1,
	 delete_node/1,
	 add_table/3,
	 create_table/2,
	 sys_info/0,
	 check_started_extra_node/0
	]).

-export([init_table_info/1,
	 delete_schema_file/0,
	 load_textfile/2,
	 load_textfile/1,
	 ping/0	 
	]).




-export([start/0,
	 stop/0
	 ]).
%% internal 
%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

install()->
    {ok,node(),?MODULE,?FUNCTION_NAME,?LINE}.
%C="https://"++Uid++":"++Pwd++"@github.com/"++Uid++"/"++SId++".git".

%% Asynchrounus Signals
%boot_strap()->
 %   PortStr=atom_to_list(PortArg),
 %   Port=list_to_integer(PortStr),
   % application:set_env([{boot_service,{port,Port}}]),
%    application:start(boot_service).
       
%% Gen server function

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).


%%---------------- Etcd ------------------------------------------------
cluster_info()->
    gen_server:call(?MODULE,{cluster_info},infinity).
cluster_info(Name)->
    gen_server:call(?MODULE,{cluster_info,Name},infinity).

catalog_info()->
    gen_server:call(?MODULE,{catalog_info},infinity).
host_info()->
    gen_server:call(?MODULE,{host_info},infinity).


cluster_info_create(ClusterName,Cookie)->
    gen_server:call(?MODULE,{cluster_info_create,ClusterName,Cookie},infinity).

cluster_name()->
    gen_server:call(?MODULE,{cluster_name},infinity).
cluster_cookie()->
    gen_server:call(?MODULE,{cluster_cookie},infinity).

is_leader()->
    gen_server:call(?MODULE,{is_leader},infinity).
host_info_create(HostId,Ip,SshPort,UId,Pwd)->
    gen_server:call(?MODULE,{host_info_create,HostId,Ip,SshPort,UId,Pwd},infinity).
host_info_delete(HostId,Ip,SshPort,UId,Pwd)->
    gen_server:call(?MODULE,{host_info_delete,HostId,Ip,SshPort,UId,Pwd},infinity).
host_info_read(HostId)->
    gen_server:call(?MODULE,{host_info_read,HostId},infinity).
host_info_all()->
    gen_server:call(?MODULE,{host_info_all},infinity).


%%----------------------------------------------------------------------
sys_info()->
    gen_server:call(?MODULE,{sys_info},infinity).
add_table(Vm,Table,StorageType)->
      gen_server:call(?MODULE,{add_table,Vm,Table,StorageType},infinity).
create_table(Table,Args)->
    gen_server:call(?MODULE,{create_table,Table,Args},infinity).
add_node(Vm)->
    gen_server:call(?MODULE,{add_node,Vm},infinity).
delete_node(Vm)->
    gen_server:call(?MODULE,{delete_node,Vm},infinity).


init_table_info(Info)->
    gen_server:call(?MODULE,{init_table_info,Info},infinity).

delete_schema_file()->
    gen_server:call(?MODULE,{delete_schema_file},infinity).

load_textfile(Filename,Bin)->    
    gen_server:call(?MODULE,{load_textfile,Filename,Bin},infinity).
load_textfile(FileName)->    
    gen_server:call(?MODULE,{load_textfile,FileName},infinity).
    
ping()->
    gen_server:call(?MODULE,{ping},infinity).

%%___________________________________________________________________

check_started_extra_node()->
    gen_server:cast(?MODULE,{check_started_extra_node}).

%%-----------------------------------------------------------------------


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%
%% --------------------------------------------------------------------
init([]) ->
    dbase_controller_lib:init(),
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (aterminate/2 is called)
%% --------------------------------------------------------------------

handle_call({ping}, _From, State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply, State};


handle_call({cluster_info}, _From, State) ->
    Reply=db_cluster_info:read_all(),
    {reply, Reply, State};
handle_call({cluster_info,Name}, _From, State) ->
    Reply=db_cluster_info:info(Name),
    {reply, Reply, State};

handle_call({catalog_info}, _From, State) ->
    Reply=db_catalog:read_all(),
    {reply, Reply, State};
handle_call({host_info}, _From, State) ->
    Reply=db_host_info:read_all(),
    {reply, Reply, State};
%-----------------
handle_call({cluster_info_create,ClusterName,Cookie}, _From, State) ->
    Reply=db_cluster_info:create(ClusterName,Cookie),
    {reply, Reply, State};
handle_call({cluster_name}, _From, State) ->
    Reply=db_cluster_info:name(),
    {reply, Reply, State};
handle_call({cluster_cookie}, _From, State) ->
    Reply=db_cluster_info:cookie(),
    {reply, Reply, State};

%-------------------------
handle_call({host_info_all}, _From, State) ->
    Reply=db_host_info:read_all(),
    {reply, Reply, State};

handle_call({host_info_create,HostId,Ip,SshPort,UId,Pwd}, _From, State) ->
    Reply=db_host_info:create(HostId,Ip,SshPort,UId,Pwd),
    {reply, Reply, State};

handle_call({host_info_delete,HostId,Ip,SshPort,UId,Pwd}, _From, State) ->
    Reply=db_host_info:delete(HostId,Ip,SshPort,UId,Pwd),
    {reply, Reply, State};
handle_call({host_info_read,HostId}, _From, State) ->
    Reply=db_host_info:read(HostId),
    {reply, Reply, State};

%--------------------------

handle_call({sys_info}, _From, State) ->
    Reply=mnesia:system_info(),
    {reply, Reply, State};

handle_call({create_table,Table,Args}, _From, State) ->
    Reply=rpc:call(node(),gen_mnesia_lib,create_table,[Table,Args]),
    {reply, Reply, State};

handle_call({add_table,Vm,Table,StorageType}, _From, State) ->
    Reply=rpc:call(node(),gen_mnesia_lib,add_table,[Vm,Table,StorageType]),
    {reply, Reply, State};


handle_call({delete_node,Vm}, _From, State) ->
    Reply=rpc:call(Vm,application,stop,[gen_mnesia]),
    {reply, Reply, State};

handle_call({add_node,Vm}, _From, State) ->
   Reply=rpc:call(node(),gen_mnesia_lib,add_node,[Vm]),
    {reply, Reply, State};

handle_call({init_table_info,Info}, _From, State) ->
    Reply=gen_mnesia_lib:create_table(Info),
    {reply, Reply, State};

handle_call({delete_schema_file}, _From, State) ->
    Reply=os:cmd("rm -rf Mne*"),
    {reply, Reply, State};

handle_call({load_textfile,FileName}, _From, State) ->
    Reply=mnesia:load_textfile(FileName),
 %   file:delete(Filename),
    {reply, Reply, State};

handle_call({load_textfile,Filename,Bin}, _From, State) ->
    file:delete(Filename),
    ok=file:write_file(Filename,Bin),
    Reply=mnesia:load_textfile(Filename),
 %   file:delete(Filename),
    {reply, Reply, State};


handle_call({stop}, _From, State) ->
    mnesia:stop(),
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,?LINE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_cast({check_started_extra_node}, State) ->
    spawn(fun()->local_check_started_extra_node() end),  
    {noreply, State};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)

handle_info(Info, State) ->
    io:format("unmatched match info ~p~n",[{?MODULE,?LINE,Info}]),
    {noreply, State}.


%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------
local_check_started_extra_node()->
    timer:sleep(?check_started_extra_node_time_out),
    Locked=db_lock:is_open(),
    io:format("~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,Locked}]),
    case Locked of
	false->
	    do_nothing;
	true->
	    rpc:call(node(),gen_mnesia_lib,check_stopped_db_nodes,[])
    end,
    gen_mnesia:check_started_extra_node().
