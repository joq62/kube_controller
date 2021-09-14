%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% --------------------------------------------------------------------
-module(node).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("kube_logger.hrl").
%% --------------------------------------------------------------------

% New final ?
 
-export([
	 create_vm/3,
	 delete_vm/1
	]).

%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
create_vm({HostId,Ip,SshPort,UId,Pwd},NodeName,Cookie)->
   
    ssh:start(),
    Node=list_to_atom(NodeName++"@"++HostId),
		  
    true=erlang:set_cookie(Node,list_to_atom(Cookie)),
    true=erlang:set_cookie(node(),list_to_atom(Cookie)),
    Result=case delete_vm(Node) of
	       {error,Reason}->
		   {error,Reason};
	       ok->
		   ErlCmd="erl_call -s "++"-sname "++NodeName++" "++"-c "++Cookie,
		   SshCmd="nohup "++ErlCmd++" &",
		   case rpc:call(node(),my_ssh,ssh_send,[Ip,SshPort,UId,Pwd,SshCmd,2*5000],3*5000) of
		       {badrpc,Reason}->
			  {error,[badrpc,Reason,Ip,SshPort,UId,Pwd,NodeName,Cookie,
				  ?FUNCTION_NAME,?MODULE,?LINE]};
		       {error,Reason}->
			   {error,[Reason,Ip,SshPort,UId,Pwd,NodeName,Cookie,
				   ?FUNCTION_NAME,?MODULE,?LINE]};	
		       ErlcCmdResult->
			   case node_started(Node) of
			       false->
				   ?PrintLog(ticket,"Failed ",[Node,Ip,SshPort,UId,Pwd,NodeName,Cookie,ErlcCmdResult
							      ,?FUNCTION_NAME,?MODULE,?LINE]),
				   {error,['failed to start', Ip,SshPort,UId,Pwd,NodeName,Cookie,ErlcCmdResult,
					   ?FUNCTION_NAME,?MODULE,?LINE]};
			       true->
				   case rpc:call(Node,file,list_dir,["."],5*1000) of
				       {badrpc,Reason}->
					   {error,[badrpc,Reason,Ip,SshPort,UId,Pwd,NodeName,Cookie,
						   ?FUNCTION_NAME,?MODULE,?LINE]};
				       {error,Reason}->
					   {error,[Reason,Ip,SshPort,UId,Pwd,NodeName,Cookie,
						   ?FUNCTION_NAME,?MODULE,?LINE]};
				       {ok,Files}->
					   DeploymentDirs=[File||File<-Files,
								".deployment"==filename:extension(File)],
					   [rpc:call(Node,os,cmd,["rm -rf "++DeploymentDir],5*1000)||DeploymentDir<-DeploymentDirs],
					   timer:sleep(100),
					   ?PrintLog(log,"Started ",[Node,HostId,NodeName,ErlcCmdResult,?FUNCTION_NAME,?MODULE,?LINE]),
					   {ok,Node}
				   end
			   end
		   end
	   end,
    Result.


   
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
delete_vm(Node)->
  %  rpc:call(Node,os,cmd,["rm -rf "++Dir],5*1000),
    rpc:call(Node,init,stop,[],5*1000),		   
    Result=case node_stopped(Node) of
	       false->
		   ?PrintLog(ticket,"Failed to stop node ",[Node,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,["node not stopped",Node,?FUNCTION_NAME,?MODULE,?LINE]};
	       true->
		   ?PrintLog(log,"Stopped ",[Node,?FUNCTION_NAME,?MODULE,?LINE]),
		   ok
	   end,
    Result.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
	      
node_started(Node)->
    check_started(100,Node,50,false).
    
check_started(_N,_Vm,_SleepTime,true)->
   true;
check_started(0,_Vm,_SleepTime,Result)->
    Result;
check_started(N,Vm,SleepTime,_Result)->
 %   io:format("net_Adm ~p~n",[net_adm:ping(Vm)]),
    NewResult= case net_adm:ping(Vm) of
	%case rpc:call(node(),net_adm,ping,[Vm],1000) of
		  pong->
		     true;
		  pang->
		       timer:sleep(SleepTime),
		       false;
		   {badrpc,_}->
		       timer:sleep(SleepTime),
		       false
	      end,
    check_started(N-1,Vm,SleepTime,NewResult).

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------

node_stopped(Node)->
    check_stopped(100,Node,50,false).
    
check_stopped(_N,_Vm,_SleepTime,true)->
   true;
check_stopped(0,_Vm,_SleepTime,Result)->
    Result;
check_stopped(N,Vm,SleepTime,_Result)->
 %   io:format("net_Adm ~p~n",[net_adm:ping(Vm)]),
    NewResult= case net_adm:ping(Vm) of
	%case rpc:call(node(),net_adm,ping,[Vm],1000) of
		  pang->
		     true;
		  pong->
		       timer:sleep(SleepTime),
		       false;
		   {badrpc,_}->
		       true
	       end,
    check_stopped(N-1,Vm,SleepTime,NewResult).

