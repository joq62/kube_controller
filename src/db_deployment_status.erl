-module(db_deployment_status).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").

-define(DeploymentSpecDirName,"deployment").
-define(DeploymentSpecPath,"https://github.com/joq62/deployment.git").

-define(TABLE, deployment_status).
-define(RECORD,deployment_status).
-record(deployment_status,{
			   name,
			   host_id,
			   node,
			   dir,
			   app
			}).

% Start Special 

% End Special 
create_table()->
    Result={atomic,ok}=mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
						   {type,bag}]),
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
create(Name,HostId,Node,Dir,App)->
    Record=#?RECORD{
		    name=Name,
		    host_id=HostId,
		    node=Node,
		    dir=Dir,
		    app=App
		   },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

delete(Object)->
    F = fun() -> 
		RecordList=do(qlc:q([X || X <- mnesia:table(?TABLE),
					  X#?RECORD.name==Object])),
		case RecordList of
		    []->
			mnesia:abort({error,[eexists,Object,?FUNCTION_NAME,?MODULE,?LINE]});
		    _->
			[mnesia:delete_object(S1)||S1<-RecordList]			
		end
		    
	end,
    mnesia:transaction(F).



read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{Name,HostId,Node,Dir,App}||{?RECORD,Name,HostId,Node,Dir,App}<-Z].


read(Object)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.name==Object])),
    [{Name,HostId,Node,Dir,App}||{?RECORD,Name,HostId,Node,Dir,App}<-Z].

deployment(Node)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		 X#?RECORD.node==Node])),
    Result=case Z of
	       []->
		  {error,[eexists,Node,?FUNCTION_NAME,?MODULE,?LINE]};
	       
	       [{?RECORD,Name,_HostId,_Node,_Dir,_App}|_]->
		   Name
	   end,
    Result.

get(WantedApp)->
    get(WantedApp,node()).
get(WantedApp,MyNode)->
    All=read_all(),
    {WantedDeployment,_HostId,_Node,_Dir,_App}=lists:keyfind(MyNode,3,All),
    [Node|| {Deployment,_HostId,Node,_Dir,App}<-All,
	    WantedApp==App,
	    WantedDeployment==Deployment].
	    
	    

do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

%%-------------------------------------------------------------------------
