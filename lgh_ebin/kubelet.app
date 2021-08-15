%% This is the application resource file (.app file) for the 'base'
%% application.
{application, kubelet,
[{description, "kubelet  " },
{vsn, "1.0.0" },
{modules, 
	  [kubelet_app,kubelet_sup]},
{registered,[kubelet]},
{applications, [kernel,stdlib]},
{mod, {kubelet_app,[]}},
{start_phases, []}
]}.
