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
        sim_base = sim_struct(param, sim_base);

        % Create one or many simulation objects.
        if nargin >= 4
            % Struct recursion to preallocate simulation array.
            sim_vars = struct_combinations(sweep);
            sim_in = repmat(sim_base, size(sim_vars));
            
            % Create simulation objects with each parameter.
            sim_in = arrayfun(@(x, y) sim_struct(x, y), sim_vars, sim_in);

            sim_out = parsim(sim_in);
        else
            sim_out = sim(sim_base);
        end
        
    end
end

% Function for generating the combinations of all struct inputs.
function output = struct_combinations(input)
    % Get fields and lengths.
    fn = fieldnames(input);
    output_dim = zeros(1, length(fn));
    for i = 1:length(fn)
        output_dim(i) = length(input.(fn{i}));
    end

    % Create dynamic slicing parameters (remove trailing singleton).
    output_dim = output_dim(1:find(output_dim - 1,1,'last'));
    dim = length(output_dim);
    slice = repmat({':'}, 1, length(output_dim));

    % Preallocate output struct.
    output = repmat(input, [output_dim, 1]);

    % Fill struct slices recursively.
    for i = 1:size(output, dim)
         temp = input;
         temp.(fn{dim}) = input.(fn{dim})(i);
         slice{dim} = i;
         % Check if recursion has reached limit.
        if dim > 1
            output(slice{:}) = struct_combinations(temp);
        else
            % Pass input if singleton.
            output(slice{:}) = temp;
        end
    end
end

% Function to add struct fields to a simulink input.
function sim_in = sim_struct(sim_struct, sim_in)
    fn = fieldnames(sim_struct);
    for field = fn'
        sim_in = sim_in.setVariable(field{:}, sim_struct.(field{:}));
    end
end

