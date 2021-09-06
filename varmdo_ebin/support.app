%% This is the application resource file (.app file) for the 'base'
%% application.
{application, support,
[{description, "SUPPORT" },
{vsn, "1.0.0" },
{modules, 
	  [support_app,support_sup,support,support_server]},
{registered,[support]},
{applications, [kernel,stdlib]},
{mod, {support_app,[]}},
{start_phases, []}
]}.
