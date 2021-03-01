% DESCRIPTION:  Startup script for setting Simulink environment
%               variables and automating tests.
% AUTHOR:       James Bennion-Pedley
% DATE CREATED: 19.02.21

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
        
        disp('Initialising environment variables...');
        
        % Get environment variables from JSON
        json = fileread('src/model_parameters.json');
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
%                 assignin('caller', field{:}, active_ws.(field{:}));
                % TODO stop this being called when initialising
                % programatically.
            end
        end
        
        % Simulation output not used when 'self' == true.
        sim_out = [];
        
        disp('Environment Variables Loaded.');
        
    else
        if nargin < 3
            error('Parameters required for initialisation!');
        end
        
        disp('Starting Simulation...');
        
        % Create base simulation input.
        sim_base = Simulink.SimulationInput(name);
        fn = fieldnames(param);
        for field = fn'
            sim_base = sim_base.setVariable(field{:}, param.(field{:}));
        end

        % Create one or many simulation objects.
        if nargin >= 4
            % THIS IS TEMPORARY FOR TESTING!!!
            for i = 1:length(sweep.L)
                sim_par(i) = sim_base;
                sim_par(i) = sim_par(i).setVariable('L', sweep.L(i));
            end
            sim_out = parsim(sim_par);
        else
            sim_out = sim(sim_base);
        end
        
        disp('Simulation Finished!');
        
    end
end