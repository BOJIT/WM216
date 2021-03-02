% DESCRIPTION:  Startup script for setting Simulink environment
%               variables and automating tests.
% AUTHOR:       James Bennion-Pedley
% DATE CREATED: 19.02.21

%{
Note for this framework to operate correctly the following code should be
added to the 'InitFcn' callback of any Simulink files:

```
if ~exist('self', 'var')
   SimFramework(true, 'MODEL NAME');
end
```
%}

function sim_out = SimFramework(self, name, param, sweep)
    % SIMINITIALISE Function for setting environment variables
    % for Simulink projects.
    % This function is used for both initialising environment
    % variables from within Simulink as well as batch-computing
    % Simulink models.
    % This framework allows full encapsulation of the Simulink workspace.
    %
    % SELF  if true, default environment variables are passed
    %       to the calling model. If false, batch simulate.
    %
    % NAME  name of workspace to load. These can be any name,
    %       and multiple simulink files can share environments,
    %       but using the simulink file name is recommended.
    %
    % PARAM workspace struct with environment variables.
    % SWEEP struct of value arrays to create parallel simulation pool.
    
    active_ws = [];
    
    if self
        if nargin < 2
            error('Name required for initialisation!');
        end
        
        % Get environment variables from JSON
        json = fileread('model_parameters.json');
        param = jsondecode(json);
        for ws = param.workspace'
            if strcmp(ws{:}.name, name)
                active_ws = ws{:};
            end
        end
        
        % Load environment variables into workspace.
        if isempty(active_ws)
            error('No environment variables found!');
        else
            fn = fieldnames(active_ws);
            for field = fn'
                assignin('caller', field{:}, active_ws.(field{:}));
            end
        end
        
        % Simulation output not used when 'self' == true.
        sim_out = [];
        
    else
        if nargin < 3
            error('Parameters required for initialisation!');
        end
        
        % Add 'self' tag - this stops this file being called back!
        param.self = true;
        
        % Create base simulation input.
        sim_base = Simulink.SimulationInput(name);
        fn = fieldnames(param);
        for field = fn'
            sim_base = sim_base.setVariable(field{:}, param.(field{:}));
        end

        % Create one or many simulation objects.
        if nargin >= 4
            fn = fieldnames(sweep);
            
            % Struct sweep to preallocate simulation array.
            sim_num = 1;
            for field = fn'
                sim_num = length(sweep.(field{:}))*sim_num;
            end
            
%             sim_part = repmat(sim_base, sim_num, 1);
            
            for i = 1:length(sweep.L)
                sim_par(i) = sim_base;
                sim_par(i) = sim_par(i).setVariable('L', sweep.L(i));
            end
            
            sim_out = parsim(sim_par);
        else
            sim_out = sim(sim_base);
        end
        
    end
end