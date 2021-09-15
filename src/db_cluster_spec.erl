-module(db_cluster_spec).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").

-define(TABLE,cluster_spec).
-define(RECORD,cluster_spec).
-record(cluster_spec,{
		      cluster_id,
		      monitor_node,
		      cookie
		     }).
% Git
-define(ClusterConfigPath,"https://github.com/joq62/cluster_config.git").
-define(ClusterConfigDirName,"cluster_config").
-define(ClusterConfigFile,"cluster_config/cluster.config").
-define(ClusterConfigFileName,"cluster.config").

git_init()->
    os:cmd("rm -rf "++?ClusterConfigDirName),
    os:cmd("git clone "++?ClusterConfigPath),
    ClusterConfigFile=filename:join([?ClusterConfigDirName,?ClusterConfigFileName]),
    {ok,Info}=file:consult(ClusterConfigFile),
    ok=init_cluster_specs(Info,[]),
    os:cmd("rm -rf "++?ClusterConfigDirName),
    ok.
init_cluster_specs([],Result)->
    R=[R||R<-Result,
	  R/={atomic,ok}],
    case R of
	[]->
	    ok;
	R->
	    {error,[R]}
    end;
    
init_cluster_specs([[{cluster_name,ClusterName},{hosts,Hosts},{cookie,Cookie}]|T],Acc)->
    R=create(ClusterName,Hosts,Cookie),
    init_cluster_specs(T,[R|Acc]).

% End Special 
create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables([?TABLE], 20000).

create_table(NodeList)->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
				 {disc_copies,NodeList}]),
    mnesia:wait_for_tables([?TABLE], 20000).

create(ClusterId,MonitorNode,Cookie)->
    Record=#?RECORD{
		    cluster_id=ClusterId,
		    monitor_node=MonitorNode,
		    cookie=Cookie
		   },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).
add_node(Node,StorageType)->
    Result=case mnesia:change_config(extra_db_nodes, [Node]) of
	       {ok,[Node]}->
		   mnesia:add_table_copy(schema, node(),StorageType),
		   mnesia:add_table_copy(?TABLE, node(), StorageType),
		   Tables=mnesia:system_info(tables),
		   mnesia:wait_for_tables(Tables,20*1000);
	       Reason ->
		   Reason
	   end,
    Result.

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{ClusterId,MonitorNode,Cookie}||
	{?RECORD,ClusterId,MonitorNode,Cookie}<-Z].

cluster()->
    read(cluster_id).
monitor()->
    read(monitor_node).
cookie()->
    read(cookie).

read(Key)->
    Return=case read() of
	       []->
		   {error,[eexist,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{ClusterId,MonitorNode,Cookie}] ->
		   case  Key of
		       cluster_id->ClusterId;
		       monitor_node->MonitorNode;
		       cookie->Cookie;
		       Err ->
			   {error,['Key eexists',Err,?FUNCTION_NAME,?MODULE,?LINE]}
		   end
	   end,
    Return.
read()->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{ClusterId,MonitorNode,Cookie}||{?RECORD,ClusterId,MonitorNode,Cookie}<-Z].

do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

%%-------------------------------------------------------------------------
