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

    io:format("~p~n",[{"Start init_mnesia()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=init_mnesia(),
    io:format("~p~n",[{"Stop init_mnesia()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start create_vm()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=create_vm(),
    io:format("~p~n",[{"Stop create_vm()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start dist_mnesia()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=dist_mnesia(),
    io:format("~p~n",[{"Stop dist_mneisa()",?MODULE,?FUNCTION_NAME,?LINE}]),

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
init_mnesia()->
    
  
    standby_controller=check_status(),
%   io:format("1. ~p~n",[{rpc:call(node(),mnesia,system_info,[],5*1000)}]),
    ok=dbase_controller_lib:initial_start_mnesia(),
 %   io:format("2. ~p~n",[{mnesia:system_info(tables)}]),
     leader_controller_mnesia_not_initated=check_status(),
    ok=dbase_controller_lib:init_tables(),
    [{"c2","192.168.0.202",22,"joq62","festum01"},
     {"c0","192.168.0.200",22,"joq62","festum01"},
     {"joq62-X550CA","192.168.0.100",22,"joq62",
      "festum01"}]=db_host_info:read_all(),
  %  io:format("3. ~p~n",[{mnesia:system_info(tables)}]),
     leader_controller_mnesia_initiated=check_status(),
    
    false=db_lock:is_open(cluster),
    ok.

check_status()->
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
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
create_vm()->
    C0=db_host_info:read("c0"),
    C2=db_host_info:read("c2"),

    Cookie=atom_to_list(erlang:get_cookie()),
    NodeNameC0="controller_"++Cookie++"_"++"c0",
    NodeNameC2="controller_"++Cookie++"_"++"c2",  
    Dirc0=NodeNameC0++".deployment",
    Dirc2=NodeNameC2++".deployment",

    {ok,NodeC0}=vm_handler:create_vm(C0,NodeNameC0,Dirc0,Cookie),
    io:format("NodeC0 ~p~n",[NodeC0]),
    pong=net_adm:ping(NodeC0),

    {ok,Slave1_C0}=rpc:call(NodeC0,slave,start,["c0",slave1_c0,"-setcookie "++Cookie]),
    pong=net_adm:ping(Slave1_C0),
    io:format("Slave1_C0 ~p~n",[Slave1_C0]),

    {ok,NodeC2}=vm_handler:create_vm(C2,NodeNameC2,Dirc2,Cookie),
    io:format("NodeC2 ~p~n",[NodeC2]),
    pong=net_adm:ping(NodeC2),

    {ok,Slave1_C2}=rpc:call(NodeC2,slave,start,["c2",slave1_c2,"-setcookie "++Cookie]),
    pong=net_adm:ping(Slave1_C2),
    io:format("Slave1_C2 ~p~n",[Slave1_C2]),
		
    
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
dist_mnesia()->
    Nodes=nodes(),
    ok=dbase_controller_lib:init_distributed_mnesia(Nodes),
    ok=dbase_controller_lib:add_nodes(Nodes),
%    [{Node,rpc:call(Node,mnesia,system_info,[],5*1000)}||Node<-[node()|nodes()]],
    Z=[{Node,rpc:call(Node,mnesia,dirty_all_keys,[host_info],5*1000)}||Node<-nodes()],		
        io:format("Z ~p~n",[Z]),
    Z1=[{Node,rpc:call(Node,mnesia,dirty_all_keys,[lock],5*1000)}||Node<-nodes()],		
        io:format("Z1 ~p~n",[Z1]),
    Z2=[{Node,rpc:call(Node,mnesia,dirty_all_keys,[sd_info],5*1000)}||Node<-nodes()],		
        io:format("Z2 ~p~n",[Z2]),
    ok.				 
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_1()->

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_5()->

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
