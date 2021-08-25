%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Manage Computers
%%% Install Cluster
%%% Install cluster
%%% Data-{HostId,Ip,SshPort,Uid,Pwd}
%%% available_hosts()-> [{HostId,Ip,SshPort,Uid,Pwd},..]
%%% install_leader_host({HostId,Ip,SshPort,Uid,Pwd})->ok|{error,Err}
%%% cluster_status()->[{running,WorkingNodes},{not_running,NotRunningNodes}]

%%% Created : 
%%% -------------------------------------------------------------------
-module(controller).  
-behaviour(gen_server).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("kube_logger.hrl").
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state, {running_pods,
		missing_pods}).

%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------
-define(ControllerStatusInterval,20*1000).
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------





% OaM related
-export([
	 status_interval/1,
	 boot/0,
	 ping/0
	]).


-export([start/0,
	 stop/0
	]).

%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

%% Asynchrounus Signals

boot()->
    application:start(?MODULE).

%% Gen server functions

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).


%%---------------------------------------------------------------
status_interval(PodsStatus)->
  gen_server:cast(?MODULE,{status_interval,PodsStatus}).


%%---------------------------------------------------------------

ping()-> 
    gen_server:call(?MODULE, {ping},infinity).

%%-----------------------------------------------------------------------

%%----------------------------------------------------------------------


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: 
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%
%% --------------------------------------------------------------------
init([]) ->
     
   ?PrintLog(log,"1/6 Start ",[?FUNCTION_NAME,?MODULE,?LINE]),
%    ?PrintLog(log,"2/6 Check pods ",[?FUNCTION_NAME,?MODULE,?LINE]),
%    case rpc:call(node(),controller_lib,status_all_pods,[],10*1000) of
%	{ok,Running,Missing}->
%	    RunningPods=Running,
%	    MissingPods=Missing;
%	_->
%	    RunningPods=[],
%	    MissingPods=[]
%    end,
   
 %   ?PrintLog(log,"3/6 RunningPods ",[RunningPods,?FUNCTION_NAME,?MODULE,?LINE]),
 %   ?PrintLog(log,"4/6 MissingPods ",[MissingPods,?FUNCTION_NAME,?MODULE,?LINE]),

 %  ?PrintLog(log,"5/6 Start controller_status_interval() ",[?FUNCTION_NAME,?MODULE,?LINE]),   
 %   spawn(fun()->controller_status_interval() end),    

    ?PrintLog(log,"6/6 Successful starting of server",[?MODULE]),
    RunningPods=[],
    MissingPods=[],
    {ok, #state{running_pods=RunningPods,missing_pods=MissingPods
	       }
    }.
    
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

handle_call({ping},_From,State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% -------------------------------------------------------------------
handle_cast({status_interval,StriveResult}, State) ->
    case  StriveResult of
	{RunningPods,MissingPods}->
	    ?PrintLog(log," RunningPods ",[RunningPods,?FUNCTION_NAME,?MODULE,?LINE]),
	    ?PrintLog(log," MissingPods ",[MissingPods,?FUNCTION_NAME,?MODULE,?LINE]),
	    NewState=State#state{running_pods=RunningPods,missing_pods=MissingPods};
	Err->
	    ?PrintLog(ticket," Error ",[Err,?FUNCTION_NAME,?MODULE,?LINE]),
	    NewState=State
    end,
    spawn(fun()->controller_status_interval() end), 
    {noreply, NewState};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

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
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
controller_status_interval()->
    timer:sleep(?ControllerStatusInterval),
 %   spawn(fun()->check_status_pods() end),
    spawn(fun()->ctrl_strive_desired_state() end).

ctrl_strive_desired_state()->
    
    Status=case rpc:call(node(),controller_lib,status_all_pods,[],10*1000) of
	       {ok,RunningPods,MissingPods}->
		   {RunningPods,MissingPods};
	       _->
		   {[],[]}
	   end,
    StriveResult=rpc:call(node(),controller_lib,strive_desired_state,[Status],90*1000),
    rpc:cast(node(),controller,status_interval,[StriveResult]).
   

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
