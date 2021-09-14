-module(db_host_spec).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").

-define(TABLE,host_spec).
-define(RECORD,host_spec).
-record(host_spec,{
		   host_id,
		   ip,
		   ssh_port,
		   uid,
		   pwd
		  }).

% Git init
-define(HostConfigPath,"https://github.com/joq62/host_config.git").
-define(HostConfigDirName,"host_config").
-define(HostConfigFile,"host_config/hosts.config").
-define(HostConfigFileName,"hosts.config").

git_init()->
    os:cmd("rm -rf "++?HostConfigDirName),
    os:cmd("git clone "++?HostConfigPath),
    HostConfigFile=filename:join([?HostConfigDirName,?HostConfigFileName]),
    {ok,Info}=file:consult(HostConfigFile),
   % io:format("~p~n",[{Debug,?MODULE,?LINE}]),
    ok=init_host_info(Info,[]),
    os:cmd("rm -rf "++?HostConfigDirName),
    ok.
init_host_info([],Result)->
    R=[R||R<-Result,
	  R/={atomic,ok}],
    case R of
	[]->
	    ok;
	R->
	    {error,[R]}
    end;
    
init_host_info([[{host_id,HostId},{ip,Ip},{ssh_port,SshPort},{uid,UId},{pwd,Pwd}]|T],Acc)->
    R=create(HostId,Ip,SshPort,UId,Pwd),
    init_host_info(T,[R|Acc]).   

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

create(HostId,Ip,SshPort,UId,Pwd)->
    Record=#?RECORD{
		    host_id=HostId,
		    ip=Ip,
		    ssh_port=SshPort,
		    uid=UId,
		    pwd=Pwd
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

ssh_info(WantedHost)->
    read(WantedHost,ssh_info).
read(WantedHost,Key)->
    Return=case read(WantedHost) of
	       []->
		   {error,[eexist,WantedHost,?FUNCTION_NAME,?MODULE,?LINE]};
	       {_HostId,Ip,SshPort,UId,Pwd} ->
		   case  Key of
		       ssh_info->
			   {Ip,SshPort,UId,Pwd};
		       Err ->
			   {error,['Key eexists',Err,?FUNCTION_NAME,?MODULE,?LINE]}
		   end
	   end,
    Return.

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{HostId,Ip,SshPort,UId,Pwd}||{?RECORD,HostId,Ip,SshPort,UId,Pwd}<-Z].

read(Object)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.host_id==Object])),
    Result=case Z of
	       []->
		  [];
	       _->
		   [Info]=[{HostId,Ip,SshPort,UId,Pwd}||{?RECORD,HostId,Ip,SshPort,UId,Pwd}<-Z],
		   Info
	   end,
    Result.

delete(Object) ->
    F = fun() -> 
		mnesia:delete({?TABLE,Object})
		    
	end,
    mnesia:transaction(F).


do(Q) ->
    F = fun() -> qlc:e(Q) end,
    Result=case mnesia:transaction(F) of
	       {atomic, Val} ->
		   Val;
	       {error,Reason}->
		   {error,Reason}
	   end,
    Result.

%%-------------------------------------------------------------------------
