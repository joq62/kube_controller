-module(db_deployment_spec).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").

-define(TABLE, deployment_info).
-define(RECORD,deployment_info).
-record(deployment_info,{
			 name,
			 vsn,
			 replicas,
			 apps,
			 cluster_id
			}).

% Start Special 

% End Special 
create_table()->
    Result={atomic,ok}=mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables([?TABLE], 20000),
    Result.

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

%%-------------------------------------------------------------------
create(Name,Vsn,Replicas,Apps,ClusterId)->
    Record=#?RECORD{
		    name=Name,
		    vsn=Vsn,
		    replicas=Replicas,
		    apps=Apps,
		    cluster_id=ClusterId
		   },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{Name,Vsn,Replicas,Apps,ClusterId}||{?RECORD,Name,Vsn,Replicas,Apps,ClusterId}<-Z].

read(Object)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.name==Object])),
    Result=case Z of
	       []->
		   {error,[eexist,Object,?FUNCTION_NAME,?MODULE,?LINE]};
	       _->
		   [{Name,Vsn,Replicas,Apps,ClusterId}||{?RECORD,Name,Vsn,Replicas,Apps,ClusterId}<-Z]
	   end,
    Result.

%%%
key_cluster_id(WantedClusterId)->
    AllSpecs=read_all(),    
    Result=[{Name,Vsn,Replicas,Apps,ClusterId}||{Name,Vsn,Replicas,Apps,ClusterId}<-AllSpecs,
						WantedClusterId==ClusterId],
    Result.

%%%%
vsn(Object)->
    read(Object,vsn).
replicas(Object)->
    read(Object,replicas).
apps(Object)->
    read(Object,apps).
cluster_id(Object)->
    read(Object,cluster_id).
read(Object,Key)->
    Return=case read(Object) of
	      {error,_}->
		   {error,[eexist,Object,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{_Name,Vsn,Replicas,Apps,ClusterId}] ->
		   case  Key of
		       vsn->
			   Vsn;
		       replicas->
			   Replicas;
		       apps->
			   Apps;
		       cluster_id->
			   ClusterId;
		       Err ->
			   {error,['Key eexists',Err,?FUNCTION_NAME,?MODULE,?LINE]}
		   end
	   end,
    Return.




do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

%%-------------------------------------------------------------------------
