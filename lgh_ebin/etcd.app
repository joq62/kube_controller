%% This is the application resource file (.app file) for the 'base'
%% application.
{application, etcd,
[{description, "etcd  " },
{vsn, "1.0.0" },
{modules, 
	  [etcd_app,etcd_sup,etcd]},
{registered,[etcd]},
{applications, [kernel,stdlib]},
{mod, {etcd_app,[]}},
{start_phases, []}
]}.
