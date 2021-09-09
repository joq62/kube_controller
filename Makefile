all:
#	service
	rm -rf ebin/* varmdo*  *.deployment;
	rm -rf src/*.beam *.beam  test_src/*.beam test_ebin;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf lgh lgh_ebin;
	erlc -I ../interfaces -o ebin src/*.erl;
	echo Done
doc_gen:
	echo glurk not implemented
unit_test:
	rm -rf varmdo_ebin varmdo *.deployment;	
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf *_specs *_config *.log;
	mkdir varmdo_ebin;
	mkdir test_ebin;
#	interface
	erlc -I ../interfaces -o varmdo_ebin ../interfaces/*.erl;
#	support
	erlc -I ../interfaces -o varmdo_ebin ../kube_support/src/*.erl;
#	controller
	cp ../applications/controller/src/*.app varmdo_ebin;
	erlc -I ../interfaces -o varmdo_ebin ../applications/controller/src/*.erl;
	erlc -I ../interfaces -o varmdo_ebin src/*.erl;
#	test application
	cp test_src/*.app test_ebin;
	erlc -o test_ebin test_src/*.erl;
	erl -pa varmdo_ebin -pa test_ebin\
	    -setcookie varmdo_cookie\
	    -sname controller_varmdo\
	    -unit_test monitor_node controller_varmdo\
	    -unit_test cluster_id varmdo\
	    -unit_test cookie varmdo_cookie\
	    -run unit_test start_test test_src/test.config
