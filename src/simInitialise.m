% DESCRIPTION:  Startup script for setting Simulink environment
%               variables and automating tests.
% AUTHOR:       James Bennion-Pedley
% DATE CREATED: 19.02.21

function sim = simInitialise(self, name, param)
    % SIMINITIALISE Function for setting environment variables
    % for Simulink projects.
    % This function is used for both initialising environment
    % variables from within Simulink as well as batch-computing
    % Simulink models.
    %
    % SELF  if true, default environment variables are passed
    %       to the calling model. If false, batch simulate.
    %
    % NAME  name of workspace to load. These can be any name,
    %       and multiple simulink files can share environments,
    %       but using the simulink file name is recommended.
    %
    % PARAM environment struct to pass in if doing batch operations.
    disp('Initialising environment variables...');
    
    active_ws = [];
    
    if self
        if nargin < 2
            error('Name required for initialisation!');
        end
        
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
                assignin('caller', field{:}, active_ws.(field{:}));
            end
        end
        
        % Simulation output not used when 'self' == true.
        sim = [];
        
    else
        if nargin < 3
            error('Parameters required for initialisation!');
        end
    end
end