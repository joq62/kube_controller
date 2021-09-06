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
    ok=dbase_controller_lib:init_mnesia(),
    [{"c2","192.168.0.202",22,"joq62","festum01"},
     {"c0","192.168.0.200",22,"joq62","festum01"},
     {"joq62-X550CA","192.168.0.100",22,"joq62",
      "festum01"}]=db_host_info:read_all(),
    
    false=db_lock:is_open(cluster),
    
    ok.

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

    {ok,NodeC2}=vm_handler:create_vm(C2,NodeNameC2,Dirc2,Cookie),
    io:format("NodeC2 ~p~n",[NodeC2]),
    pong=net_adm:ping(NodeC2),
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
