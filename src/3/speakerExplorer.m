classdef speakerExplorer < UIFramework
    
    properties
        Workspace = struct; % Stores simulation workspace variables
        
        Param = {}; % Parameter 'block' handles
        CurrentParam = []; % Rolling selection memory - for checkboxes
        
        % UI Handles
        Step;   % Radiobutton Handle
        Sine;   % Radiobutton Handle
        Table;  % Parameter table
        Message;    % General-purpose message box
        Simulate;   % Simulation button handle
        
        Axes = {};
        
        % Application Configuration:
        NumParams = 2;
        NumAxes = 2;
    end

    % Public Methods (non-application-specific):
    methods
        
        % Initialise GUI
        function obj = speakerExplorer()
            
            % TEMP REMOVE LATER!!!
            close all; clc;
            
            % General figure/container structure
            fig = obj.figure();
            fig.Name = 'Speaker Explorer';
            
            %---------------- Create model control panel -----------------%
            control_panel = obj.panel(fig, 'vertical', true, [0, 0, 0.35, 0.3]);
            control_panel.Title = 'Control';
            
            % Custom model parameters/controls
            for i = 1:obj.NumParams
                obj.Param{i} = obj.parameter(control_panel, {'null', ...
                                  ['Parameter ', num2str(i)]}, 10, false);
                obj.Param{i}.disable();
            end

            % Simulation button
            obj.Simulate = uicontrol(control_panel, 'String', 'Simulate', ...
                                                    'Callback', @obj.startSim);
            
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
            uicontrol(config_options, 'style', 'check', 'String', 'Coupled', ...
                                  'Value', 1, 'Callback', @obj.configEditHandler);
            
            % Frequency parameter/control
            obj.Param{obj.NumParams + 1} = obj.parameter(config_panel, 'Frequency', 1000, true);
            obj.Param{obj.NumParams + 1}.disable();
            
            %--------------- Create model parameter panel ----------------%
            parameter_panel = obj.panel(fig, 'vertical', true, [0, 0.5, 0.35, 0.5]);
            parameter_panel.Title = 'Parameters';
            
            % Add table with responsive resizing:
            obj.Table = obj.loadWorkspace(parameter_panel, 'src/model_parameters.json');
            %---------------- Create model results panel -----------------%
            
            % Create graph axes
%             results_panel = obj.panel(fig, 'vertical', true, [0.35, 0.05, 0.65, 0.95]);
%             results_panel.Title = 'Results';
            
%             for i = 1:obj.NumAxes
%                 obj.Axes{i} = axes(results_panel);
%                 grid(obj.Axes{i}, 'on');
%             end
            obj.Axes{1} = axes(fig, 'OuterPosition', [0.35, 0.525, 0.65, 0.475]);
            grid(obj.Axes{1}, 'on');
            obj.Axes{2} = axes(fig, 'OuterPosition', [0.35, 0.05, 0.65, 0.475]);
            grid(obj.Axes{2}, 'on');
            
            %---------------- Create model message panel -----------------%
            message_panel = obj.panel(fig, 'vertical', false, [0.35, 0, 0.65, 0.05]);
            obj.Message = uicontrol(message_panel, 'style', 'text', ...
                                           'ForegroundColor', [1, 0, 0]);

            % Clear listener logs (see positionChildren note).
%             clc;
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
                    obj.Param{end}.disable();
                case 'Sine'
                    obj.Step.Value = 0;
                    obj.Sine.Value = 1;
                    obj.Param{end}.enable();
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
        function startSim(obj, ~, ~)
            
            
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
                if strcmp(ws{:}.name, 'speakerModel')
                    active_ws = ws{:};
                end
            end
            
            % Remove fields with special functionality
            blacklist = {'name', 'freq'};
            for field = blacklist
                if isfield(active_ws, field{:})
                    obj.Workspace.(field{:}) = active_ws.(field{:});
                    active_ws = rmfield(active_ws, field{:});
                end
            end
            
            % Generate corresponding data table
            vars = struct2cell(active_ws);
            env = [fieldnames(active_ws), vars, num2cell(false(length(vars), 1))];
            
            handle = uitable(parent, 'Data', env, 'ColumnEditable', ...
                             [false, true, true], 'ColumnName', ...
                             {'Variable', 'Value', 'Parameter?'}, ...
                             'RowName', [], 'CellEditCallback', ...
                             @obj.parameterEditHandler);
        end
        
    end
    
end

