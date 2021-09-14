-module(db_pod_spec).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").

-define(TABLE,pod_spec).
-define(RECORD,pod_spec).
-record(pod_spec,{
		  pod_id,
		  pod_vsn,
		  application_list,   %[{app,vsn,git_path,app_env}]
		  replicas,
		  host_list
		  }).

%% Git init 
-define(PodSpecsPath,"https://github.com/joq62/pod_specs.git").
-define(PodSpecsDirName,"pod_specs").

git_init()->
    os:cmd("git clone "++?PodSpecsPath),
    {ok,FileNames}=file:list_dir(?PodSpecsDirName),
    PodSpecFiles=[filename:join([?PodSpecsDirName,FileName])||FileName<-FileNames,
							      ".pod_spec"==filename:extension(FileName)],
    ok=init_pod_specs(PodSpecFiles,[]),
    os:cmd("rm -rf "++?PodSpecsDirName),
    ok.

init_pod_specs([],Result)->
    R=[R||R<-Result,
	  R/={atomic,ok}],
    X=case R of
	  []->
	      ok;
	  R->
	      {error,[R]}
      end,
    X;
init_pod_specs([PodSpecFile|T],Acc)->
    {ok,Info}=file:consult(PodSpecFile),
   
    [{pod_id,PodId},{pod_vsn,PodVsn},{application_list,ApplicationList},{replicas,Replicas},{host_list,HostList}]=Info,
    R=create(PodId,PodVsn,ApplicationList,Replicas,HostList),
    init_pod_specs(T,[R|Acc]).

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

create(PodId,PodVsn,ApplicationList,Replicas,HostList)->
    Record=#?RECORD{
		    pod_id=PodId,
		    pod_vsn=PodVsn,
		    application_list=ApplicationList, 
		    replicas=Replicas,
		    host_list=HostList
		   },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

member(Object)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.pod_id==Object])),
    Member=case Z of
	       []->
		   false;
	       _->
		   true
	   end,
    Member.

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{PodId,PodVsn,ApplicationList,Replicas,HostList}||{?RECORD,PodId,PodVsn,ApplicationList,Replicas,HostList}<-Z].

read(Object)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.pod_id==Object])),
    [Info]=[{PodId,PodVsn,ApplicationList,Replicas,HostList}||{?RECORD,PodId,PodVsn,ApplicationList,Replicas,HostList}<-Z],
    Info.


vsn(Object)->
    read(Object,pod_vsn).
application_list(Object)->
    read(Object,application_list).
replicas(Object)->
    read(Object,replicas).
host_list(Object)->
    read(Object,host_list).
read(Object,Key)->
    Return=case read(Object) of
	       []->
		   {error,[eexist,Object,?FUNCTION_NAME,?MODULE,?LINE]};
	       {_PodId,PodVsn,ApplicationList,Replicas,HostList} ->
		   case  Key of
		       pod_vsn->
			   PodVsn;
		       application_list->
			   ApplicationList;
		       replicas->
			   Replicas;
		       host_list->
			   HostList;
		       Err ->
			   {error,['Key eexists',Err,?FUNCTION_NAME,?MODULE,?LINE]}
		   end
	   end,
    Return.



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
