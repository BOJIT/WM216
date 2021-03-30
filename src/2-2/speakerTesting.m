clc; clear;

path = 'model_parameters.json';
name = 'speakerModel';
var_investigate = 'R'; %R for resistance, L for inductance
var_output = 1; %1 for current, 2 for displacement (value on the y axis)
var_coupled = 0; %1 for coupled, 0 for uncoupled

% Get environment variables from JSON
json = fileread(path);
param = jsondecode(json);
for ws = param.workspace'
    if strcmp(ws{:}.name, name)
        workspace = ws{:};
    end
end

% Adjust coupling setting
workspace.couple = var_coupled;

% Construct swept parameters
if var_investigate == 'R'
    sweep.R = linspace(8, 300, 10);
elseif var_investigate == 'L'
    sweep.L = linspace(0.0002, 10, 10);
end

% Process results
sims = SimFramework(path, false, name, workspace, sweep);

% Plot overlayed results

node = var_output;

figure;
grid on;
hold on;
xlabel('Time / (seconds)');
ylabel(sims(1).yout{node}.Name);
arrayfun(@(x) plot(x.yout{node}.Values), sims);

% Labels for graphs
if var_investigate == 'R'
    title('Effect of varying resistance R on output current I', 'FontSize',18,'interpreter', 'latex');
    lgd.R = legend(string(round(sweep.R)),'Location','northeast');
    title(lgd.R,'Resistance, R [Ohms]');
elseif var_investigate == 'L'
    title('Effect of varying inductance L on output current I', 'FontSize',18,'interpreter', 'latex');
    xlim([0 2])
    lgd.L = legend([string(round(sweep.L(1)*1000,1)),string(round(sweep.L(2:10)*1000))],'Location','northeast');
    title(lgd.L,'Inductance, L [mH]');
end