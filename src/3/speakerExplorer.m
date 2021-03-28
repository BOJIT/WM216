% DESCRIPTION:  GUI for manipulating speaker simulink model from Section
%               2.2. Based on the UIFramework.
% AUTHOR:       James Bennion-Pedley
% DATE CREATED: 07.03.21

% IMPORTANT NOTE!
% If running this on a PC with the parallel computing toolbox installed, it
% is advisable to turn it off while running this script. True parallel
% processing only results in a speed increase for longer simulations than
% the ones in this submission.

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
        Trace;
        
        % Application configuration:
        NumParams = 2; % Note for MATLAB < 2018b this must be less than 2.
        ParamResolution = 11; % 5 sims either side of centre.
        ModelName = 'speakerModel';
        Blacklist = {'name', 'freq', 'step', 'couple'}; % Special fields.
        JSON = 'model_parameters.json';
        
        % Be mindful setting these parameters. The max number of parallel
        % simulations initiated is set by ParamResolution^NumParams.
        % Setting these numbers too high will lead to long simulation times.
    end

    % Public Methods:
    methods
        
        % Initialise GUI
        function obj = speakerExplorer()
            % General figure/container structure
            fig = obj.figure(false);
            fig.Name = 'Speaker Explorer';

            %--------------- Create model parameter panel ----------------%
            parameter_panel = obj.panel(fig, 'vertical', true, [0, 0.65, 0.4, 0.35]);
            parameter_panel.Title = 'Parameters';
            
            % Add table with responsive resizing:
            obj.Table = obj.loadWorkspace(parameter_panel);
            
            %---------------- Create model control panel -----------------%
            control_panel = obj.panel(fig, 'vertical', true, [0, 0, 0.4, 0.45]);
            control_panel.Title = 'Control';
            
            % Custom model parameters/controls
            for i = 1:obj.NumParams
                obj.Param{i} = obj.parameter(control_panel, {'null', ...
                                             ['Parameter ', num2str(i)]}, ...
                                             0, false, true, ...
                                             @obj.controlEditHandler, ...
                                             @obj.minMaxEditHandler);
                obj.Param{i}.disable();

                obj.Param{i}.Slider.Tooltip
            end

            % Simulation button
            obj.Simulate = uicontrol(control_panel, 'String', 'Simulate', ...
                                              'Callback', {@obj.startSim, fig});
            
            %----------------- Create model config panel -----------------%
            config_panel = obj.panel(fig, 'vertical', true, [0, 0.45, 0.4, 0.2]);
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
                                          obj.Workspace.freq, true, ...
                                          false, @obj.configEditHandler);
            obj.Frequency.disable();
            
            %---------------- Create model results panel -----------------%
            uicontrol(fig, 'style', 'text', 'String', 'Simulation Results:', ...
                            'FontSize', 15, 'Position', [0.4, 0.95, 0.6, 0.05]);
            obj.Axes{1} = axes(fig, 'OuterPosition', [0.4, 0.5, 0.6, 0.45]);
            obj.Axes{1}.NextPlot = 'add';
            obj.Axes{1}.ButtonDownFcn = @obj.axesPopoutHandler;
            obj.Axes{2} = axes(fig, 'OuterPosition', [0.4, 0.05, 0.6, 0.45]);
            obj.Axes{2}.NextPlot = 'add';
            obj.Axes{2}.ButtonDownFcn = @obj.axesPopoutHandler;
            
            %---------------- Create model message panel -----------------%
            message_panel = obj.panel(fig, 'vertical', false, [0.4, 0, 0.6, 0.05]);
            obj.Message = uicontrol(message_panel, 'style', 'text', ...
                                           'ForegroundColor', [1, 0, 0]);    
                                       
            %-------------- Create tooltips for UI Elements --------------%
            obj.Step.Tooltip = 'select to use a step function as the simulation input';
            obj.Sine.Tooltip = 'select to use a sine function as the simulation input';
            obj.Couple.Tooltip = 'select to couple the electrical and mechanical subsystems';
            
            for i = 1:obj.NumParams
                msg = ['Parameter Block: Use sliders to change ', ...
                        'the value of the parameter.\n The current ', ...
                        'value will display in the box below:\n' ...
                        'Use the "min" and "max" fields to change ', ...
                        'the default slider limits.\n Changing these', ...
                        'fields will require re-simulation.'];
                obj.Param{i}.Slider.Tooltip = sprintf(msg);
            end
            
        end
        
    end
    
    % Private Methods:
    methods (Access = private)
        
        % Callback for editing table parameters
        function parameterEditHandler(obj, src, evt)
            % Check numerical entry is valid.
            if isnan(evt.NewData)
               errordlg('Value must be numeric!');
               src.Data{evt.Indices(1), evt.Indices(2)} = evt.PreviousData;
               return;
            end
            
            % Exit if control checkboxes were not edited.
            if evt.Indices(2) == 2
                obj.allowSim(true);
                return;
            end
            
            % Get selection column from the table.
            sel = cell2mat(src.Data(:, 4));
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
                src.Data{obj.CurrentParam(end), 4} = false;
                obj.CurrentParam(end) = evt.Indices(1);
            end
            
            % Update slider labels and values.
            for i = 1:obj.NumParams
                if i <= length(obj.CurrentParam)
                    % Change labels and re-enable.
                    obj.Param{i}.Label.UserData.Label = obj.Table.Data{obj.CurrentParam(i), 1};
                    base_val = obj.Table.Data{obj.CurrentParam(i), 2};
                    obj.Param{i}.Display.UserData.BaseValue = base_val;
                    obj.Param{i}.Display.UserData.MinValue = base_val - base_val/2;
                    obj.Param{i}.Display.UserData.MaxValue = base_val + base_val/2;
                    
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
        
        % Callback for editing control parameters
        function controlEditHandler(obj, ~, ~)
            % Get index of correct plot.
            location = cell(1, length(obj.CurrentParam));
            for i = 1:length(obj.CurrentParam)
                % Create sweep struct from parameter ranges.
                val = obj.Param{i}.Slider.Value;
                if val == 0
                    location{i} = 1; % This is why arrays start at zero!!!
                else
                    location{i} = ceil(val*obj.ParamResolution);
                end
                % Quantize displayed value to nearest step.
                if obj.Param{i}.Display.Enable
                    [~, idx] = min(abs(obj.Param{i}.UserData.Sweep - ...
                                    obj.Param{i}.Display.UserData.Value));
                    quantised = obj.Param{i}.UserData.Sweep(idx);
                    obj.Param{i}.Display.String = num2str(quantised, '%.4g');
                end
            end
            
            % Hide all lines except active one.
            for i = 1:length(obj.Axes)
                x_lim = xlim(obj.Axes{i});
                y_lim = ylim(obj.Axes{i});

                arrayfun(@(x) set(x, 'Visible', 'off'), obj.Trace{i});
                obj.Trace{i}(location{:}).Visible = 'on';
                
                xlim(obj.Axes{i}, x_lim);
                ylim(obj.Axes{i}, y_lim);
            end
        end
        
        % Callback for dealing with min/max without clearing simulation.
        function minMaxEditHandler(obj, ~, ~)
            obj.allowSim(true);
        end
        
        % Callback for popping axes out to an independent figure.
        function axesPopoutHandler(~, src, ~)
            figure;
            copyobj(src, gcf);
            set(gca,'Position',[.13 .11 .77 .815],'ButtonDownFcn',[]);
        end
        
        % Show that simulation is out of date
        function allowSim(obj, state)
            if state == true
                obj.Message.String = 'Results out of date! Re-simulate:';
                obj.Simulate.Enable = 'on';
                for i = 1:length(obj.CurrentParam)
                    obj.Param{i}.disable();
                end
            else
                obj.Message.String = '';
                obj.Simulate.Enable = 'off';
                for i = 1:length(obj.CurrentParam)
                    obj.Param{i}.enable();
                end
            end
        end
        
        % Run simulation and show results!
        function startSim(obj, ~, ~, load_handle)
            % Set pointer to loading symbol.
            set(load_handle, 'pointer', 'watch');
            drawnow;

            % Don't allow another simulation until change is made.
            obj.allowSim(false);

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
                results = SimFramework(obj.JSON, false, obj.ModelName, obj.Workspace);
            else
                sweep = struct;
                for i = 1:length(obj.CurrentParam)
                    % Create sweep struct from parameter ranges.
                    param = obj.Param{i}.Label.UserData.Label;
                    min_val = obj.Param{i}.Display.UserData.MinValue;
                    max_val = obj.Param{i}.Display.UserData.MaxValue;
                    sweep.(param) = linspace(min_val, max_val, obj.ParamResolution);
                    obj.Param{i}.UserData.Sweep = sweep.(param);
                end
                results = SimFramework(obj.JSON, false, obj.ModelName, obj.Workspace, sweep);
            end

            % Clear previous graph content and set labels using Simulink.
            for i = 1:length(obj.Axes)
                cla(obj.Axes{i});
                grid(obj.Axes{i}, 'on');
                if i <= numElements(results(1).yout)
                    % Reset axes scaling and add labels.
                    xlim(obj.Axes{i}, 'auto');
                    ylim(obj.Axes{i}, 'auto');
                    xlabel(obj.Axes{i}, 'Time / (seconds)');
                    ylabel(obj.Axes{i}, results(1).yout{i}.Name);
                    % Plot all data on graph.
                    obj.Trace{i} = arrayfun(@(x) plot(x.yout{i}.Values, 'b', ...
                                                 'Parent', obj.Axes{i}), results);                       
                end
            end    

            % If applicable call control callback handlers directly.
            if ~isempty(obj.CurrentParam)
                obj.controlEditHandler();
            end

            % Reset pointer to arrow:
            set(load_handle, 'pointer', 'arrow');
        end
        
        % Read default values to initialise table
        function handle = loadWorkspace(obj, parent)
            active_ws = [];

            % Get environment variables from JSON
            json = fileread(obj.JSON);
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

            % Add units column if units are provided.
            names = fieldnames(active_ws);
            vars = struct2cell(active_ws);
            units = cell(size(vars));

            for i = 1:length(names)
                if isfield(param.metadata.units, names{i})
                    units{i} = param.metadata.units.(names{i});
                end
            end

            % Generate corresponding data table
            env = [fieldnames(active_ws), vars, units, num2cell(false(length(vars), 1))];

            handle = obj.table(parent, 'Data', env, 'ColumnEditable', ...
                               [false, true, false, true], 'ColumnName', ...
                               {'Variable', 'Value', 'Units', 'Control'}, ...
                               'RowName', [], 'CellEditCallback', ...
                               @obj.parameterEditHandler);
        end
        
    end
    
end

