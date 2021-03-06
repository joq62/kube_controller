%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%
%%%§
%%% Created : 
%%% -------------------------------------------------------------------
-module(controller_server).   
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
-record(state, {status,
	       running_pods,
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


%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

%% Asynchrounus Signals

boot()->
    application:start(?MODULE).

%% Gen server functions

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
    {ok, #state{status=standby}}.
    
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
handle_call({new,ClusterId,MonitorNode,Cookie},_From,State) ->
    Reply=case rpc:call(node(),controller_lib,start_dbase,[ClusterId,MonitorNode,Cookie],5*10*1000) of
	      {error,Reason}->
		  NewState=State,
		  {error,Reason};
	      ok->
		  {ok,_}=kube_logger:start(),
		  case rpc:call(node(),cluster_lib,start_host_nodes,[ClusterId],5*10*1000) of
		      {error,StartReason}->
			  {error,StartReason};
		      {ok,StartList}->
			  Start=[db_host_status:create(HostId,Node)||{ok,HostId,Node}<-StartList],
			  case [StartR||StartR<-Start,StartR/={atomic,ok}] of
			      []->
				  {ok,StartList};
			      Reason ->
				  {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
			  end
		  end
	  end,
    {reply, Reply, State};

handle_call({status},_From,State) ->
    Reply=State#state.status,
    {reply, Reply, State};

handle_call({hosts_status},_From,State) ->
    Reply=rpc:call(node(),host,status_all_hosts,[],3*5*1000),
    {reply, Reply, State};
handle_call({hosts_running},_From,State) ->
    Reply=rpc:call(node(),host,running,[],3*5*1000),
    {reply, Reply, State};
handle_call({hosts_missing},_From,State) ->
    Reply=rpc:call(node(),host,missing,[],3*5*1000),
    {reply, Reply, State};

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
    timer:sleep(10*1000),
    rpc:call(node(),controller_server,cluster_status,[],20*1000),
        
    Status=case rpc:call(node(),controller_lib,status_all_pods,[],10*1000) of
	       {ok,RunningPods,MissingPods}->
		   {RunningPods,MissingPods};
	       _->
		   {[],[]}
	   end,
    StriveResult=rpc:call(node(),controller_lib,strive_desired_state,[Status],90*1000),
    timer:sleep(?ControllerStatusInterval),
    rpc:cast(node(),controller,status_interval,[StriveResult]),
    ok.

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
