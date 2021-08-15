all:
#	service
	rm -rf ebin/*;
	rm -rf src/*.beam *.beam  test_src/*.beam test_ebin;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf lgh lgh_ebin;
	erlc -I ../interfaces -o ebin src/*.erl;
	echo Done
doc_gen:
	echo glurk not implemented
unit_test:
	rm -rf lgh_ebin;	
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf *_specs *_config *.log;
	mkdir lgh_ebin;	
#	interface
	erlc -I ../interfaces -o lgh_ebin ../interfaces/*.erl;
#	support
	cp ../applications/support/src/*.app lgh_ebin;
	erlc -I ../interfaces -o lgh_ebin ../kube_support/src/*.erl;
	erlc -I ../interfaces -o lgh_ebin ../applications/support/src/*.erl;
#	kubelet
	cp ../applications/kubelet/src/*.app lgh_ebin;
	erlc -I ../interfaces -o lgh_ebin ../node/src/*.erl;
	erlc -I ../interfaces -o lgh_ebin ../applications/kubelet/src/*.erl;
#	etcd
	cp ../applications/etcd/src/*.app lgh_ebin;
	erlc -I ../interfaces -o lgh_ebin ../kube_dbase/src/*.erl;
	erlc -I ../interfaces -o lgh_ebin ../applications/etcd/src/*.erl;
#	iaas
	cp ../applications/iaas/src/*.app lgh_ebin;
	erlc -I ../interfaces -o lgh_ebin ../kube_iaas/src/*.erl;
	erlc -I ../interfaces -o lgh_ebin ../applications/iaas/src/*.erl;
#	Controller
	cp ../applications/controller/src/*.app lgh_ebin;
	erlc -I ../interfaces -o lgh_ebin ../applications/controller/src/*.erl;
	erlc -I ../interfaces -o lgh_ebin src/*.erl;
#	test application
	mkdir test_ebin;
	cp test_src/*.app test_ebin;
	erlc -o test_ebin test_src/*.erl;
	erl -pa lgh_ebin -pa test_ebin\
	    -setcookie lgh_cookie\
	    -sname controller_lgh\
	    -unit_test monitor_node controller_lgh\
	    -unit_test cluster_id lgh\
	    -unit_test start_host_id asus_lgh\
	    -run unit_test start_test test_src/test.config
