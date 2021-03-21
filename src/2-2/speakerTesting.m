clc; clear;

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
% sweep.L = linspace(0.0002, 10, 10);

% Process results
sims = SimFramework(path, false, name, workspace, sweep);

% Plot overlayed results

node = 1; % 1 for elec, 2 for mech

figure;
grid on;
hold on;
xlabel('Time / (seconds)');
ylabel(sims(1).yout{node}.Name);
arrayfun(@(x) plot(x.yout{node}.Values), sims);                  