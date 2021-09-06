%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dbase_controller).   
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------


%% External exports
-export([]). 


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

    io:format("~p~n",[{"Start create_nodes()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=create_nodes(),
    io:format("~p~n",[{"Stop create_nodes()",?MODULE,?FUNCTION_NAME,?LINE}]),


%    io:format("~p~n",[{"Start single",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=single(),
%    io:format("~p~n",[{"Stop single",?MODULE,?FUNCTION_NAME,?LINE}]),



    io:format("~p~n",[{"Start init_mnesia()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=init_mnesia(),
    io:format("~p~n",[{"Stop init_mnesia()",?MODULE,?FUNCTION_NAME,?LINE}]),

 
    io:format("~p~n",[{"Start create_tables()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=create_tables(),
    io:format("~p~n",[{"Stop create_tables()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start data_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=data_1(),
    io:format("~p~n",[{"Stop data_1()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start loose_restart_node()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=loose_restart_node(),
    io:format("~p~n",[{"Stop loose_restart_node()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start lock()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=lock(),
    io:format("~p~n",[{"Stop lock()",?MODULE,?FUNCTION_NAME,?LINE}]),
 
    io:format("~p~n",[{"Start sd()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=sd(),
    io:format("~p~n",[{"Stop sd()",?MODULE,?FUNCTION_NAME,?LINE}]),
 
        
   
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
sd()->
    ok=db_sd:create_table(),
    Apps1=[{a1,n1},{a2,n2},{a2,n3}],
    Apps2=[{a1,n10},{a3,n11},{a2,n12}],
    
    {atomic,ok}=db_sd:create(n1,d1,Apps1),
    {atomic,ok}=db_sd:create(n2,d1,Apps1),
    {atomic,ok}=db_sd:create(n3,d1,Apps1),
    
    {atomic,ok}=db_sd:create(n10,d2,Apps2),
    {atomic,ok}=db_sd:create(n11,d2,Apps2),
    {atomic,ok}=db_sd:create(n12,d2,Apps2),    

    [n12]=db_sd:get(n12,a2),
    [n2,n3]=db_sd:get(n1,a2),
    []=db_sd:get(n23,a2),
    []=db_sd:get(n1,a452),

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
-define(NodeNames,["host_lgh_c0","host_lgh_c1","host_lgh_c2"]).
create_nodes()->
    Cookie=atom_to_list(erlang:get_cookie()),
    NodeInfo=[{NodeName,"-pa test_ebin -mnesia dir "++NodeName++" -setcookie "++Cookie}||NodeName<-?NodeNames],
    SlaveStart=[slave:start(net_adm:localhost(),NodeName,Arg)||{NodeName,Arg}<-NodeInfo],
    [{ok,'host_lgh_c0@joq62-X550CA'},
     {ok,'host_lgh_c1@joq62-X550CA'},
     {ok,'host_lgh_c2@joq62-X550CA'}]=SlaveStart,
    Slaves=[Slave||{ok,Slave}<-SlaveStart],
   
    [pong,pong,pong]=[net_adm:ping(Slave)||Slave<-Slaves],
    
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
init_mnesia()->
    % Inititade mnesia on the nodes 
    AllNodes=[node()|nodes()],
  %  io:format("AllNodes= ~p~n",[{AllNodes,?FUNCTION_NAME,?LINE,?MODULE}]),
    ok=init_distributed_mnesia(AllNodes),

    ok.

init_distributed_mnesia(Nodes)->
    StopResult=[rpc:call(Node,mnesia,stop,[],5*1000)||Node<-Nodes],
    Result=case [Error||Error<-StopResult,Error/=stopped] of
	       []->
		   case mnesia:delete_schema(Nodes) of
		       ok->
			   StartResult=[rpc:call(Node,mnesia,start,[],5*1000)||Node<-Nodes],
			   case [Error||Error<-StartResult,Error/=ok] of
			       []->
				   ok;
			       Reason->
				   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
			   end;
		       Reason->
			   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
		   end;
	       Reason->
		   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
	   end,
    Result.
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


create_tables()->
    ok=db_host_info:create_table(),
    [db_host_info:add_node(Node,ram_copies)||Node<-nodes()],
    ok.

%add_node([],Result)->
 %   Result;
%add_node([Node|T],Acc)->
 %   R=case mnesia:change_config(extra_db_nodes, [Node]) of
%	{ok,[Node]}->
%	    mnesia:add_table_copy(schema, node(),ram_copies),
%	    mnesia:add_table_copy(person, node(), ram_copies),
%	    mnesia:add_table_copy(info, node(), ram_copies),
%	    Tables=mnesia:system_info(tables),
%	    mnesia:wait_for_tables(Tables,20*1000);
%	Reason ->
%	      Reason
%      end,
 %   add_node(T,[R|Acc]).
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
data_1()->
    HostId=net_adm:localhost(),
    Ip="192.168.0.100",
    SshPort=22,
    UId="joq62",
    Pwd="festum01",
    GeoLocation="lgh",
    Status=available,
    {atomic,ok}=db_host_info:create(HostId,Ip,SshPort,UId,Pwd,GeoLocation,Status),
    [{"joq62-X550CA","192.168.0.100",22,"joq62",
      "festum01","lgh",available}]=db_host_info:read(HostId),
    
    
   DistR1 =[{Node,rpc:call(Node,db_host_info,read,[HostId],5*1000)}||Node<-nodes()],
    [{'host_lgh_c0@joq62-X550CA',[{"joq62-X550CA","192.168.0.100",22,
				   "joq62","festum01","lgh",available}]},
     {'host_lgh_c1@joq62-X550CA',[{"joq62-X550CA","192.168.0.100",22,
				   "joq62","festum01","lgh",available}]},
     {'host_lgh_c2@joq62-X550CA',[{"joq62-X550CA","192.168.0.100",22,
				   "joq62","festum01","lgh",available}]}]=DistR1, 



						
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
loose_restart_node()->
    HostId=net_adm:localhost(),    
    KilledNode='host_lgh_c0@joq62-X550CA',
    DistR1 =[{Node,rpc:call(Node,db_host_info,read,[HostId],5*1000)}||Node<-nodes()],
    [{'host_lgh_c0@joq62-X550CA',[{"joq62-X550CA","192.168.0.100",22,
				   "joq62","festum01","lgh",available}]},
     {'host_lgh_c1@joq62-X550CA',[{"joq62-X550CA","192.168.0.100",22,
				   "joq62","festum01","lgh",available}]},
     {'host_lgh_c2@joq62-X550CA',[{"joq62-X550CA","192.168.0.100",22,
				   "joq62","festum01","lgh",available}]}]=DistR1,

    {atomic,ok}=rpc:call(KilledNode,db_host_info,create,["c1","192.168.0.201",23,"uid_c1","pwd_c1","varmdo",glurk],5*1000),
	
    slave:stop(KilledNode),
   % timer:sleep(100),
    pang=net_adm:ping(KilledNode),
    DistR2 =[{Node,rpc:call(Node,db_host_info,read_all,[],5*1000)}||Node<-nodes()],
   [{'host_lgh_c1@joq62-X550CA',
     [{"c1","192.168.0.201",23,"uid_c1","pwd_c1","varmdo",glurk},
      {"joq62-X550CA","192.168.0.100",22,"joq62","festum01","lgh",available}]},
    {'host_lgh_c2@joq62-X550CA',
     [{"c1","192.168.0.201",23,"uid_c1","pwd_c1","varmdo",glurk},
      {"joq62-X550CA","192.168.0.100",22,"joq62","festum01","lgh",available}]}]
	=DistR2, 
    
    %Leader checks if a node is absent
  
    MissingNodes=check_missing_nodes(),
    [_KilledNode]=MissingNodes,
    
    % Restart node
    [NodeName,HostId]=string:tokens(atom_to_list(KilledNode),"@"),
    Cookie=atom_to_list(erlang:get_cookie()),
    Arg="-pa test_ebin -mnesia dir "++NodeName++" -setcookie "++Cookie,
    {ok,KilledNode}=slave:start(HostId,NodeName,Arg),    
    
    % Add to cluster
    stopped=rpc:call(KilledNode,mnesia,stop,[],5*1000),
    ok=rpc:call(KilledNode,mnesia,start,[],5*1000),
    db_host_info:add_node(KilledNode,ram_copies),

    DistR3 =[{Node,rpc:call(Node,db_host_info,read_all,[],5*1000)}||Node<-nodes()],
    [{'host_lgh_c1@joq62-X550CA',
      [{"c1","192.168.0.201",23,"uid_c1","pwd_c1","varmdo",glurk},
       {"joq62-X550CA","192.168.0.100",22,"joq62","festum01","lgh",available}]},
     {'host_lgh_c2@joq62-X550CA',
      [{"c1","192.168.0.201",23,"uid_c1","pwd_c1","varmdo",glurk},
       {"joq62-X550CA","192.168.0.100",22,"joq62","festum01","lgh",available}]},
     {'host_lgh_c0@joq62-X550CA',
      [{"c1","192.168.0.201",23,"uid_c1","pwd_c1","varmdo",glurk},
       {"joq62-X550CA","192.168.0.100",22,"joq62","festum01","lgh",available}]}]
	=DistR3, 
    
    
    ok. 
check_missing_nodes()->
    DBNodes=mnesia:system_info(db_nodes),
    RunningDBNodes=mnesia:system_info(running_db_nodes),
    MissingNodes=[Node||Node<-DBNodes,
		       false==lists:member(Node,RunningDBNodes)],
    MissingNodes.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
lock()->
    ok=db_lock:create_table(),
    [db_lock:add_node(Node,ram_copies)||Node<-nodes()],
    {atomic,ok}=db_lock:create(host_lock,1),
  
    DistR1 =[{Node,rpc:call(Node,db_lock,read_all_info,[],5*1000)}||Node<-nodes()],
    [{'host_lgh_c1@joq62-X550CA',
      [{host_lock,1,'etcd_test@joq62-X550CA'}]},
     {'host_lgh_c2@joq62-X550CA',
      [{host_lock,1,'etcd_test@joq62-X550CA'}]},
     {'host_lgh_c0@joq62-X550CA',
       [{host_lock,1,'etcd_test@joq62-X550CA'}]}]=DistR1,
    
    DistR2 =[{Node,rpc:call(Node,db_host_info,read_all,[],5*1000)}||Node<-nodes()],
    [{'host_lgh_c1@joq62-X550CA',_},
     {'host_lgh_c2@joq62-X550CA',_},
     {'host_lgh_c0@joq62-X550CA',_}]=DistR2,

    ['etcd_test@joq62-X550CA']=db_lock:leader(host_lock),
    timer:sleep(1200),
    true=rpc:call('host_lgh_c2@joq62-X550CA',db_lock,is_open,[host_lock],5*1000),
    false=db_lock:is_open(host_lock),
    Lock1 =[{Node,rpc:call(Node,db_lock,leader,[host_lock],5*1000)}||Node<-nodes()],
    [{'host_lgh_c1@joq62-X550CA',['host_lgh_c2@joq62-X550CA']},
     {'host_lgh_c2@joq62-X550CA',['host_lgh_c2@joq62-X550CA']},
     {'host_lgh_c0@joq62-X550CA',['host_lgh_c2@joq62-X550CA']}]=Lock1,
    

    

    ok.



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
     
  %  [io:format(" ~p~n",[{Node,rpc:call(Node,mnesia,system_info,[],5000),?FUNCTION_NAME,?LINE,?MODULE}])||Node<-AllNodes],  
  %  application:stop(etcd),
  %  init:stop(),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
