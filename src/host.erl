%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(host).   

-include("kube_logger.hrl").

-export([
	 host_node_running/1,
	 available_hosts/2,
	 sort_increase_num_vm_host/1,

	 running/0,
	 missing/0,
	 status_all_hosts/0
      
	]).

%% ====================================================================
%% External functions
%% ============================ ========================================

%% -------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
available_hosts(PreDefinedHosts,0)->
    {error,[num_replicas,0]};
available_hosts(PreDefinedHosts,NumReplicas)->
    Result=case host:sort_increase_num_vm_host(PreDefinedHosts) of
	       []->
		   [];
	       SortedHostInfo->
		   NumHosts=lists:flatlength(SortedHostInfo),
		   Trunc=erlang:trunc(NumReplicas/NumHosts),
		   L1=add_hosts(Trunc,SortedHostInfo,SortedHostInfo),
		   L2=lists:sublist(L1,NumReplicas),
		   [HostId||{HostId,_Num}<-L2]
	   end,
    Result.

add_hosts(0,_HostList,AddedList)->
    AddedList;
add_hosts(N,HostList,Acc) ->
    NewAcc=lists:append(HostList,Acc),
    add_hosts(N-1,HostList,NewAcc).


%% -------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
running()->
    {ok,Running,_}=status_all_hosts(),
    Running.
missing()->
    {ok,_,Missing}=status_all_hosts(),
    Missing.

status_all_hosts()->
    F1=fun get_hostname/2,
    F2=fun check_host_status/3,
    
    ssh:start(),
    AllHosts=db_host_spec:read_all(),
 %  io:format("AllHosts = ~p~n",[{?MODULE,?LINE,AllHosts}]),
    Status=mapreduce:start(F1,F2,[],AllHosts),
  %  io:format("Status = ~p~n",[{?MODULE,?LINE,Status}]),
    Running=[HostId||{running,HostId,_Ip,_Port}<-Status],
    Missing=[HostId||{missing,HostId,_Ip,_Port}<-Status],
    {ok,Running,Missing}.

get_hostname(Parent,{HostId,IpAddr,Port,User,PassWd})->    
 %  io:format("get_hostname= ~p~n",[{?MODULE,?LINE,HostId,User,PassWd,IpAddr,Port}]),
    Msg="hostname",
    Result=rpc:call(node(),my_ssh,ssh_send,[IpAddr,Port,User,PassWd,Msg, 7*1000],6*1000),
  %  io:format("Result, HostId= ~p~n",[{?MODULE,?LINE,Result,HostId}]),
    Parent!{machine_status,{HostId,IpAddr,Port,Result}}.

check_host_status(machine_status,Vals,_)->
   io:format("Vals= ~p~n",[{Vals,?MODULE,?LINE}]),
    check_host_status(Vals,[]).

check_host_status([],Status)->
    Status;
check_host_status([{HostId,IpAddr,Port,[HostId]}|T],Acc)->
    NewAcc=[{running,HostId,IpAddr,Port}|Acc],
    check_host_status(T,NewAcc);
check_host_status([{HostId,IpAddr,Port,{error,_Err}}|T],Acc) ->
    check_host_status(T,[{missing,HostId,IpAddr,Port}|Acc]);
check_host_status([{HostId,IpAddr,Port,{badrpc,timeout}}|T],Acc) ->
    check_host_status(T,[{missing,HostId,IpAddr,Port}|Acc]);
check_host_status([X|T],Acc) ->
    check_host_status(T,[{x,X}|Acc]).

				

        

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
sort_increase_num_vm_host([])->
    L1=[misc_node:vmid_hostid(Node)||Node<-nodes()],
    L2=count(L1,[]),
    sort(L2);
sort_increase_num_vm_host(PreDefinedHosts)->
    L1=[misc_node:vmid_hostid(Node)||Node<-nodes()],
    L2=[{VmId,HostId}||{VmId,HostId}<-L1,
		lists:member(HostId,PreDefinedHosts)],
    L3=count(L2,[]),
    sort(L3).


count([],List)->
    List;
count([{_,HostId}|T],Acc) ->
    NewAcc=case lists:keyfind(HostId,1,Acc) of
	       false->
		   [{HostId,1}|Acc];
	       {HostId,Num} ->
		   lists:keyreplace(HostId, 1, Acc, {HostId,Num+1})
	   end,
    count(T,NewAcc).

sort([{H,N}|T]) ->
    sort([ {Hx,Nx} || {Hx,Nx} <- T, Nx < N]) ++
    [{H,N}] ++
    sort([ {Hx,Nx} || {Hx,Nx} <- T, Nx >= N]);
sort([]) -> [].


   
% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
host_node_running(HostId)->
    HostNode=list_to_atom(HostId++"@"++HostId),
    Result=case net_adm:ping(HostNode) of
	       pong->
		   true;
	       _ ->
		   false
	   end,
    Result.
