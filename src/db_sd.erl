-module(db_sd).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").

-define(TABLE,sd_info).
-define(RECORD,sd_info).
-record(sd_info,{
		 node,
		 deployment,
		 apps
		}).

% Start Special 

% End Special 
create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables([?TABLE], 20000).


create_table_copies(CopyType,NodeList)->
    case CopyType of
	ram->
	    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
					 {ram_copies,NodeList}]);
	disc->
	    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
					 {ram_copies,NodeList}]);
	disc_only_copies ->
	    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
					 {disc_only_copies,NodeList}])
    end,
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

create(Node,Deployment,Apps)->
    Record=#?RECORD{
		    node=Node,
		    deployment=Deployment,
		    apps=Apps
		   },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

member(Object)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.node==Object])),
    Member=case Z of
	       []->
		   false;
	       _->
		   true
	   end,
    Member.

get(RequestingNode,WantedApp)->
    Result=case apps(RequestingNode) of
	       {error,_Reason}->
		   [];
	       []->
		   [];
	       Apps->
		   [AppNode||{App,AppNode}<-Apps,
			     WantedApp==App]
	   end,
    Result.

deployment(Object)->
    read(Object,deployment).
apps(Object)->
    read(Object,apps).
read(Object,Key)->
    Return=case read(Object) of
	       []->
		   {error,[eexist,Object,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{_Node,Deployment,Apps}] ->
		   case  Key of
		       deployment->
			  Deployment;
		       apps->
			   Apps;
		       Err ->
			   {error,['Key eexists',Err,?FUNCTION_NAME,?MODULE,?LINE]}
		   end
	   end,
    Return.

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{Node,Deployment,Apps}||{?RECORD,Node,Deployment,Apps}<-Z].

read(Object)->
    Z=do(qlc:q([X || X <- mnesia:read({?TABLE,Object})])),
    Result=case Z of
	       {error,Reason}->
		    {error,Reason};
	       _->
		   [{Node,Deployment,Apps}||{?RECORD,Node,Deployment,Apps}<-Z]
	   end,
    Result.

delete(Object) ->
    F = fun() -> 
		mnesia:delete({?TABLE,Object})
		    
	end,
    mnesia:transaction(F).


do(Q) ->
  F = fun() -> qlc:e(Q) end,
    
    Result = case mnesia:transaction(F) of
		 {atomic, Val}->
		     Val;
		 Error->
		     {error,[Error,?FUNCTION_NAME,?MODULE,?LINE]}
	     end,
    Result.

%%-------------------------------------------------------------------------
