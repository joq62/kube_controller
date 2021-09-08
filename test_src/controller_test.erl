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

  %  io:format("~p~n",[{"Start create_vm()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=create_vm(),
  %  io:format("~p~n",[{"Stop create_vm()",?MODULE,?FUNCTION_NAME,?LINE}]),

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
    standby=controller:status(),
    ok=controller:new("lgh"),
    
    
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
