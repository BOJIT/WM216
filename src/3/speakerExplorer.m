classdef speakerExplorer < UIFramework
    
    properties
        % Simulation workspace dataset:
        Workspace = struct;
        
        % Parameters
        Param = {}; % Parameter 'block' handles
        CurrentParam = []; % Rolling selection memory - for checkboxes
        
        % UI object handles
        Step;
        Sine;
        Couple;
        Frequency;
        Table;
        Message;
        Simulate;
        Axes = {};
        
        % Application configuration:
        NumParams = 2;
        ParamResolution = 10;
        ModelName = 'speakerModel';
        Blacklist = {'name', 'freq', 'step', 'couple'}; % Special fields.
        
        % Be mindful setting these parameters. The max number of parallel
        % simulations initiated is set by ParamResolution^NumParams.
        % Setting these numbers too high will lead to long simulation times.
    end

    % Public Methods:
    methods
        
        % Initialise GUI
        function obj = speakerExplorer()
            
            % TEMP REMOVE LATER!!!
            close all; clc;
            
            % General figure/container structure
            fig = obj.figure();
            fig.Name = 'Speaker Explorer';

            %--------------- Create model parameter panel ----------------%
            parameter_panel = obj.panel(fig, 'vertical', true, [0, 0.5, 0.35, 0.5]);
            parameter_panel.Title = 'Parameters';
            
            % Add table with responsive resizing:
            obj.Table = obj.loadWorkspace(parameter_panel, 'model_parameters.json');
            
            %---------------- Create model control panel -----------------%
            control_panel = obj.panel(fig, 'vertical', true, [0, 0, 0.35, 0.3]);
            control_panel.Title = 'Control';
            
            % Custom model parameters/controls
            for i = 1:obj.NumParams
                obj.Param{i} = obj.parameter(control_panel, {'null', ...
                                ['Parameter ', num2str(i)]}, 0, 0, false);
                obj.Param{i}.disable();
            end

            % Simulation button
            obj.Simulate = uicontrol(control_panel, 'String', 'Simulate', ...
                                              'Callback', {@obj.startSim, fig});
            
            %----------------- Create model config panel -----------------%
            config_panel = obj.panel(fig, 'vertical', true, [0, 0.3, 0.35, 0.2]);
            config_panel.Title = 'Configuration';

            % Simulation overview options
            config_options = obj.panel(config_panel, 'horizontal', false);
            obj.Step = uicontrol(config_options, 'style', 'radio', ...
                                     'String', 'Step', 'Value', 1, ...
                                     'Callback', @obj.configEditHandler);
            obj.Sine = uicontrol(config_options, 'style', 'radio', ...
                                     'String', 'Sine', 'Value', 0, ...
                                     'Callback', @obj.configEditHandler);
            obj.Couple = uicontrol(config_options, 'style', 'check', ...
                                      'String', 'Couple', 'Value', 1, ...
                                      'Callback', @obj.configEditHandler);
            
            % Frequency parameter/control
            obj.Frequency = obj.parameter(config_panel, 'Frequency', ...
                                          obj.Workspace.freq, obj.Workspace.freq, true);
            obj.Frequency.disable();
            
            %---------------- Create model results panel -----------------%
            uicontrol(fig, 'style', 'text', 'String', 'Simulation Results:', ...
                            'FontSize', 15, 'Position', [0.35, 0.95, 0.65, 0.05]);
            obj.Axes{1} = axes(fig, 'OuterPosition', [0.35, 0.5, 0.65, 0.45]);
            obj.Axes{1}.NextPlot = 'add';
            obj.Axes{2} = axes(fig, 'OuterPosition', [0.35, 0.05, 0.65, 0.45]);
            obj.Axes{2}.NextPlot = 'add';
            
            %---------------- Create model message panel -----------------%
            message_panel = obj.panel(fig, 'vertical', false, [0.35, 0, 0.65, 0.05]);
            obj.Message = uicontrol(message_panel, 'style', 'text', ...
                                           'ForegroundColor', [1, 0, 0]);
            
        end
        
    end
    
    % Private Methods:
    methods (Access = private)
        
        % Callback for editing table parameters
        function parameterEditHandler(obj, src, evt)
            % Get selection column from the table.
            sel = cell2mat(src.Data(:, 3));
            num = nnz(sel);
            
            % Remove deselected entries.
            if evt.NewData == false
                obj.CurrentParam(obj.CurrentParam == evt.Indices(1)) = [];
            
            % Create rolling 'memory' of selected options.
            elseif num > 0 && num <= obj.NumParams
                obj.CurrentParam(num) = evt.Indices(1);
            
            % Remove oldest entry.
            elseif num > obj.NumParams
                obj.CurrentParam = circshift(obj.CurrentParam, -1);
                src.Data{obj.CurrentParam(end), 3} = false;
                obj.CurrentParam(end) = evt.Indices(1);
            end
            
            % Update slider labels and values.
            for i = 1:obj.NumParams
                if i <= length(obj.CurrentParam)
                    % Change labels and re-enable.
                    obj.Param{i}.Label.UserData.Label = obj.Table.Data{obj.CurrentParam(i), 1};
                    obj.Param{i}.Display.UserData.BaseValue = obj.Table.Data{obj.CurrentParam(i), 2};
                    obj.Param{i}.Display.UserData.Range = obj.Table.Data{obj.CurrentParam(i), 2};
                    obj.Param{i}.enable();
                else
                    obj.Param{i}.disable();
                end
            end

            % Simulation is now out of date!
            obj.allowSim(true);
        end
        
        % Callback for editing config parameters
        function configEditHandler(obj, src, ~)
            switch src.String
                case 'Step'
                    obj.Step.Value = 1;
                    obj.Sine.Value = 0;
                    obj.Frequency.disable();
                case 'Sine'
                    obj.Step.Value = 0;
                    obj.Sine.Value = 1;
                    obj.Frequency.enable();
            end
            
            % Simulation is now out of date!
            obj.allowSim(true);
        end
        
        % Show that simulation is out of date
        function allowSim(obj, state)
            if state == true
                obj.Message.String = 'Results out of date! Re-simulate:';
                obj.Simulate.Enable = 'on';
            else
                obj.Message.String = '';
                obj.Simulate.Enable = 'off'; 
            end
        end
        
        % Run simulation and show results!
        function startSim(obj, ~, ~, load_handle)
            % Set pointer to loading symbol:
            set(load_handle, 'pointer', 'watch');
            drawnow;
            
            % Update workspace struct with current variables.
            for row = obj.Table.Data'
                obj.Workspace.(row{1}) = row{2};
            end
            
            % Get special config options.
            obj.Workspace.freq = obj.Frequency.Display.UserData.Value;
            obj.Workspace.step = obj.Step.Value;
            obj.Workspace.couple = obj.Couple.Value;
            
            % Request headless simulation (single or parallel).
            if isempty(obj.CurrentParam)
                results = SimFramework(false, obj.ModelName, obj.Workspace);
            else
                sweep = struct;
                for i = 1:length(obj.CurrentParam)
                    % Create sweep struct from parameter ranges.
                    param = obj.Param{i}.Label.UserData.Label;
                    base_val = obj.Param{i}.Display.UserData.BaseValue;
                    range = obj.Param{i}.Display.UserData.Range;
                    sweep.(param) = linspace(base_val - range/2, ...
                                             base_val + range/2, ...
                                             obj.ParamResolution);                          
                end
                results = SimFramework(false, obj.ModelName, obj.Workspace, sweep);
            end
            
            % Clear previous graph content and set labels using Simulink.
            for i = 1:length(obj.Axes)
                cla(obj.Axes{i});
                grid(obj.Axes{i}, 'on');
                if i <= numElements(results(1).yout)
                    xlabel(obj.Axes{i}, 'Time / (seconds)');
                    ylabel(obj.Axes{i}, results(1).yout{i}.Name);
                    % Plot all data on graph.
                    for j = 1:length(results)
                        disp(j);
                        plot(results(j).yout{i}.Values, 'Parent', obj.Axes{i});
                    end
                end
            end    
            
            % Call control callback handlers directly.
            
            % Reset pointer to arrow:
            set(load_handle, 'pointer', 'arrow');
            
            % Don't allow another simulation until change is made.
            obj.allowSim(false);
        end
        
        % Read default values to initialise table
        function handle = loadWorkspace(obj, parent, path)
            active_ws = [];
            
            % Get environment variables from JSON
            json = fileread(path);
            param = jsondecode(json);
            for ws = param.workspace'
                if strcmp(ws{:}.name, obj.ModelName)
                    active_ws = ws{:};
                end
            end
            
            % Make special fields non-editable.
            for field = obj.Blacklist
                if isfield(active_ws, field{:})
                    obj.Workspace.(field{:}) = active_ws.(field{:});
                    active_ws = rmfield(active_ws, field{:});
                end
            end
            
            % Generate corresponding data table
            vars = struct2cell(active_ws);
            env = [fieldnames(active_ws), vars, num2cell(false(length(vars), 1))];
            
            handle = obj.table(parent, 'Data', env, 'ColumnEditable', ...
                               [false, true, true], 'ColumnName', ...
                               {'Variable', 'Value', 'Parameter?'}, ...
                               'RowName', [], 'CellEditCallback', ...
                               @obj.parameterEditHandler);
        end
        
    end
    
end

