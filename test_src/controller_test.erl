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

    io:format("~p~n",[{"Start new()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=new(),
    io:format("~p~n",[{"Stop new()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start create_slave()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=create_slave(),
    io:format("~p~n",[{"Stop create_slave()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start deployment()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=deployment(),
    io:format("~p~n",[{"Stop deployment()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start deploy_app()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=deploy_app(),
    io:format("~p~n",[{"Stop deploy_app()",?MODULE,?FUNCTION_NAME,?LINE}]),

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
new()->
    ClusterId="lgh",
    Cookie=atom_to_list(erlang:get_cookie()),
    MonitorNode=node(),
    standby=controller:status(),
    {ok,StartList}=controller:new(ClusterId,MonitorNode,Cookie),
 %   [db_host_status:create(HostId,Node)||{ok,HostId,Node}<-StartList],
    
    Status=controller:hosts_status(),
    io:format("Status ~p~n",[Status]),
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
    io:format("[N1,N2,N3] ~p~n",[{N1,N2,N3}]),
    {ok,N11}=rpc:call(N1,slave,start,[rpc:call(N1,net_adm,localhost,[],5*1000),
				      "n11","-setcookie "++Cookie],5*1000),
    {ok,N22}=rpc:call(N2,slave,start,[rpc:call(N2,net_adm,localhost,[],5*1000),
				      "n22","-setcookie "++Cookie],5*1000),
    {ok,N33}=rpc:call(N3,slave,start,[rpc:call(N3,net_adm,localhost,[],5*1000),
				      "n33","-setcookie "++Cookie],5*1000),
    
    [pong,pong,pong]=[net_adm:ping(Node)||Node<-[N11,N22,N33]],
    
    D=date(),
    [D,D,D]=[rpc:call(Node,erlang,date,[],5*1000)||Node<-[N11,N22,N33]],
    
    [{_,2},{_,2},{_,2}]=host:sort_increase_num_vm_host(),

   
    {ok,N222}=rpc:call(N2,slave,start,[rpc:call(N2,net_adm,localhost,[],5*1000),
				      "n222","-setcookie "++Cookie],5*1000),
    {ok,N333}=rpc:call(N3,slave,start,[rpc:call(N3,net_adm,localhost,[],5*1000),
				       "n333","-setcookie "++Cookie],5*1000),
    {ok,N334}=rpc:call(N3,slave,start,[rpc:call(N3,net_adm,localhost,[],5*1000),
				       "n334","-setcookie "++Cookie],5*1000),
    
    [pong,pong,pong]=[net_adm:ping(Node)||Node<-[N222,N333,N334]],
   
    [{_,2},{_,3},{_,4}]=host:sort_increase_num_vm_host(),

    rpc:call(N1,init,stop,[],4*1000),
    true=ensure_stopped(N1),
    
    {badrpc,nodedown}=rpc:call(N11,erlang,date,[],5*1000),

    [{_,3},{_,4}]=host:sort_increase_num_vm_host(),
      
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
   
    io:format("db_app_info:read_all() ~p~n",[db_app_info:read_all()]),
    "https://github.com/joq62/mymath.git"=db_app_info:git(Object1),
    []=db_app_info:env(Object1),
    []=db_app_info:hosts(Object1),
    
   
    Object="math_lgh_1",
    "1.0.0"=db_deployment_spec:vsn(Object),
    {3,[]}=db_deployment_spec:replicas(Object),
    [{"mymath","1.0.0"},{"mydivi","1.0.0"}]=db_deployment_spec:apps(Object),
    "lgh"=db_deployment_spec:cluster_id(Object),
    io:format("db_deployment_spec:read_all() ~p~n",[db_deployment_spec:read_all()]),
    
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
deploy_app()->
    Deplyoment="math_lgh_1",
    {Num,PreDefinedHosts}=db_deployment_spec:replicas(Deplyoment),
    AppList=db_deployment_spec:apps(Deplyoment),
    Cookie=db_deployment_spec:cluster_id(Deplyoment),

    AppInfoList=[{list_to_atom(AppId),
		  db_app_info:git(list_to_atom(AppId)),
		  db_app_info:env(list_to_atom(AppId)),
		  db_app_info:hosts(list_to_atom(AppId))}||{AppId,_Vsn}<-AppList],
    
    HostLoad=host:sort_increase_num_vm_host(),   
    ok=check_availability_hosts(PreDefinedHosts,HostLoad),
    
    

    ok.

check_availability_hosts(PreDefinedHosts,HostLoad)->
    Member=[lists:member(PreDefinedHost,HostLoad)||PreDefinedHost<-PreDefinedHosts],
    case [R||R<-Member,R==false] of
	[]->
	    ok;
	NotMember->
	    {error,[NotMember]}
    end.
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
