-module(db_host).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").

-define(TABLE,host_status).
-define(RECORD,host_status).
-record(host_status,{
		     host_id,
		     node
		     
		  }).

% Start Special 

% End Special 
create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables([?TABLE], 20000).

create_table(NodeList)->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
				 {disc_copies,NodeList}]),
    mnesia:wait_for_tables([?TABLE], 20000).

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

create(HostId,Node)->
    Record=#?RECORD{
		    host_id=HostId,
		    node=Node
		   },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

member(HostId)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.host_id==HostId])),
    Member=case Z of
	       []->
		   false;
	       _->
		   true
	   end,
    Member.

node(Object)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.host_id==Object])),
    Result=case [{HostId,Node}||{?RECORD,HostId,Node}<-Z] of
	       []->
		   {error,[eexists,Object,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{_HostId,Node}]->
		   Node
	   end,
    Result.
host(Object)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.node==Object])),
    Result=case [{HostId,Node}||{?RECORD,HostId,Node}<-Z] of
	       []->
		   {error,[eexists,Object,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{HostId,_Node}]->
		   HostId
	   end,
    Result.
read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{HostId,Node}||{?RECORD,HostId,Node}<-Z].

delete(Object) ->
    F = fun() -> 
		mnesia:delete({?TABLE,Object})
		    
	end,
    mnesia:transaction(F).


do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

%%-------------------------------------------------------------------------
