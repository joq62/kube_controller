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

  %  io:format("~p~n",[{"Start dist_mnesia()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=dist_mnesia(),
  %  io:format("~p~n",[{"Stop dist_mneisa()",?MODULE,?FUNCTION_NAME,?LINE}]),

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
new()->
    ClusterId="lgh",
    Cookie=atom_to_list(erlang:get_cookie()),
    MonitorNode=node(),
    standby=controller:status(),
    {ok,StartList}=controller:new(ClusterId,MonitorNode,Cookie),
    [db_host_status:create(HostId,Node)||{ok,HostId,Node}<-StartList],
    
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
    
    {ok,N11}=rpc:call(N1,slave,start,[rpc:call(N1,net_adm,localhost,[],5*1000),
				      "n11","-setcookie "++Cookie],5*1000),
    {ok,N22}=rpc:call(N2,slave,start,[rpc:call(N2,net_adm,localhost,[],5*1000),
				      "n22","-setcookie "++Cookie],5*1000),
    {ok,N33}=rpc:call(N3,slave,start,[rpc:call(N3,net_adm,localhost,[],5*1000),
				      "n33","-setcookie "++Cookie],5*1000),
    
    [pong,pong,pong]=[net_adm:ping(Node)||Node<-[N11,N22,N33]],
    
    D=date(),
    [D,D,D]=[rpc:call(Node,erlang,date,[],5*1000)||Node<-[N11,N22,N33]],
    
    io:format("nodes() ~p~n",[nodes()]),
    
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
