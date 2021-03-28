clc; clear;

path = 'model_parameters.json';
name = 'speakerModel';
investigate = 'L'; %R for resistance, L for inductance


% Get environment variables from JSON
json = fileread(path);
param = jsondecode(json);
for ws = param.workspace'
    if strcmp(ws{:}.name, name)
        workspace = ws{:};
    end
end

% Construct swept parameters
if investigate == 'R'
    sweep.R = linspace(8, 300, 10);
elseif investigate == 'L'
    sweep.L = linspace(0.0002, 10, 10);
end

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

% Labels for graphs
if investigate == 'R'
    title('Effect of varying resistance R on output current I', 'FontSize',18,'interpreter', 'latex');
    lgd.R = legend(string(round(sweep.R)),'Location','northwest');
    title(lgd.R,'Resistance, R [Ohms]');
elseif investigate == 'L'
    title('Effect of varying inductance L on output current I', 'FontSize',18,'interpreter', 'latex');
    xlim([0 2])
    lgd.L = legend([string(round(sweep.L(1)*1000,1)),string(round(sweep.L(2:10)*1000))],'Location','northwest');
    title(lgd.L,'Inductance, L [mH]');
end