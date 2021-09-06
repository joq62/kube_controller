-module(db_deployment_spec).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").

-define(TABLE, deployment_info).
-define(RECORD,deployment_info).
-record(deployment_info,{
			 name,
			 vsn,
			 pods,
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

create(Name,Vsn,Pods,ClusterId)->
    Record=#?RECORD{
		    name=Name,
		    vsn=Vsn,
		    pods=Pods,
		    cluster_id=ClusterId
		   },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{Name,Vsn,Pods,ClusterId}||{?RECORD,Name,Vsn,Pods,ClusterId}<-Z].

read(Name)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.name==Name])),
    Result=case Z of
	       []->
		   {error,[eexist,Name,?FUNCTION_NAME,?MODULE,?LINE]};
	       _->
		   [{XName,Vsn,Pods,ClusterId}||{?RECORD,XName,Vsn,Pods,ClusterId}<-Z]
	   end,
    Result.

%%%
key_cluster_id(WantedClusterId)->
    AllSpecs=read_all(),    
    Result=[{Name,Vsn,Pods,ClusterId}||{Name,Vsn,Pods,ClusterId}<-AllSpecs,
				       WantedClusterId==ClusterId],
    Result.

%%%%
vsn(Name)->
    read(Name,vsn).
pods(Name)->
    read(Name,pods).
cluster_id(Name)->
    read(Name,cluster_id).
read(Name,Key)->
    Return=case read(Name) of
	      {error,_}->
		   {error,[eexist,Name,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{_Name,Vsn,Pods,ClusterId}] ->
		   case  Key of
		       vsn->
			   Vsn;
		       pods->
			   Pods;
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
