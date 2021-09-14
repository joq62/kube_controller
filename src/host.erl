%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(host).   

-include("kube_logger.hrl").

-export([
	 create_vm/3,
	 delete_vm/1,

	 available_hosts/2,
	 sort_increase_num_vm_host/1,

	 running/0,
	 missing/0,
       	 start_node/0,
	 status_all_hosts/0,
	 status/1,
	 update_status/1,
	 read_status/1
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
start_node()->
    ok.

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
  %  io:format("Vals= ~p~n",[{Vals,?MODULE,?LINE}]),
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

%% -------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
read_status(all)->
    AllServers=if_db:server_read_all(),
    AllServersStatus=[{Status,HostId}||{HostId,_User,_PassWd,_IpAddr,_Port,Status}<-AllServers],
    Running=[HostId||{running,HostId}<-AllServersStatus],
    Missing=[HostId||{missing,HostId}<-AllServersStatus],
    [{running,Running},{missing,Missing}];

read_status(XHostId) ->
    AllServers=if_db:server_read_all(),
    [ServersStatus]=[Status||{HostId,_User,_PassWd,_IpAddr,_Port,Status}<-AllServers,
		     XHostId==HostId],
    ServersStatus.
					
    
%% -------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
update_status( [{running,Running},{missing,Missing}])->
    [if_db:server_update(HostId,running)||HostId<-Running],
    [if_db:server_update(HostId,Missing)||HostId<-Missing],    
    ok.

%% -------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
status(all)->
    Status=status(),
    Running=[HostId||{running,HostId}<-Status],
    NotAvailable=[HostId||{not_available,HostId}<-Status],
    [{running,Running},{not_available,NotAvailable}];

status(HostId) ->
    Status=status(),
    Result=[XHostIdStatus||{XHostIdStatus,XHostId}<-Status,
	   HostId==XHostId],
    Result.

status()->
    F1=fun get_hostname/2,
    F2=fun check_host_status/3,
    
    AllServers=if_db:server_read_all(),
  %  io:format("AllServers = ~p~n",[{?MODULE,?LINE,AllServers}]),
    Status=mapreduce:start(F1,F2,[],AllServers),
  %  io:format("Status = ~p~n",[{?MODULE,?LINE,Status}]),
    Status.
        

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
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
create_vm({HostId,Ip,SshPort,UId,Pwd},NodeName,Cookie)->
   
    ssh:start(),
    Node=list_to_atom(NodeName++"@"++HostId),
		  
    true=erlang:set_cookie(Node,list_to_atom(Cookie)),
    true=erlang:set_cookie(node(),list_to_atom(Cookie)),
    Result=case delete_vm(Node) of
	       {error,Reason}->
		   {error,Reason};
	       ok->
		   ErlCmd="erl_call -s "++"-sname "++NodeName++" "++"-c "++Cookie,
		   SshCmd="nohup "++ErlCmd++" &",
		   case rpc:call(node(),my_ssh,ssh_send,[Ip,SshPort,UId,Pwd,SshCmd,2*5000],3*5000) of
		       {badrpc,Reason}->
			  {error,[badrpc,Reason,Ip,SshPort,UId,Pwd,NodeName,Cookie,
				  ?FUNCTION_NAME,?MODULE,?LINE]};
		       {error,Reason}->
			   {error,[Reason,Ip,SshPort,UId,Pwd,NodeName,Cookie,
				   ?FUNCTION_NAME,?MODULE,?LINE]};	
		       ErlcCmdResult->
			   case node_started(Node) of
			       false->
				   ?PrintLog(ticket,"Failed ",[Node,Ip,SshPort,UId,Pwd,NodeName,Cookie,ErlcCmdResult
							      ,?FUNCTION_NAME,?MODULE,?LINE]),
				   {error,['failed to start', Ip,SshPort,UId,Pwd,NodeName,Cookie,ErlcCmdResult,
					   ?FUNCTION_NAME,?MODULE,?LINE]};
			       true->
				   case rpc:call(Node,file,list_dir,["."],5*1000) of
				       {badrpc,Reason}->
					   {error,[badrpc,Reason,Ip,SshPort,UId,Pwd,NodeName,Cookie,
						   ?FUNCTION_NAME,?MODULE,?LINE]};
				       {error,Reason}->
					   {error,[Reason,Ip,SshPort,UId,Pwd,NodeName,Cookie,
						   ?FUNCTION_NAME,?MODULE,?LINE]};
				       {ok,Files}->
					   DeploymentDirs=[File||File<-Files,
								".deployment"==filename:extension(File)],
					   [rpc:call(Node,os,cmd,["rm -rf "++DeploymentDir],5*1000)||DeploymentDir<-DeploymentDirs],
					   timer:sleep(100),
					   ?PrintLog(log,"Started ",[Node,HostId,NodeName,ErlcCmdResult,?FUNCTION_NAME,?MODULE,?LINE]),
					   {ok,Node}
				   end
			   end
		   end
	   end,
    Result.


   
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
delete_vm(Node)->
  %  rpc:call(Node,os,cmd,["rm -rf "++Dir],5*1000),
    rpc:call(Node,init,stop,[],5*1000),		   
    Result=case node_stopped(Node) of
	       false->
		   ?PrintLog(ticket,"Failed to stop node ",[Node,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,["node not stopped",Node,?FUNCTION_NAME,?MODULE,?LINE]};
	       true->
		   ?PrintLog(log,"Stopped ",[Node,?FUNCTION_NAME,?MODULE,?LINE]),
		   ok
	   end,
    Result.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
	      
node_started(Node)->
    check_started(100,Node,50,false).
    
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

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------

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

