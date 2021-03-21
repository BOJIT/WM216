% DESCRIPTION:  Startup script for setting Simulink environment
%               variables and automating tests.
% AUTHOR:       
% DATE CREATED: 21.03.21

path = 'model_parameters.json';
name = 'speakerModel';

% Get environment variables from JSON
json = fileread(path);
param = jsondecode(json);
for ws = param.workspace'
    if strcmp(ws{:}.name, name)
        workspace = ws{:};
    end
end

% Construct swept parameters
sweep.R = linspace(8, 300, 10);
sweep.L = linspace(0.0002, 0.001, 10);

% Process results
results = SimFramework(path, false, name, workspace, sweep);

