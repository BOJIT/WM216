classdef speakerExplorer < handle
    % Tested on r2018b. READ THE COMMENTS BELOW!!!
    
    % The tiling/figure engine is designed so that if the main figure
    % spawns a new figure, the parent is inactive until the child figure is
    % closed.
    
    % Note that this class uses a positioning engine in an event listener.
    % This means that UI items are arranged in stacked panels instead of
    % specifying co-ordinates manually.
    
    properties
        Figure; % Figure handle
        HiddenEntries = struct; % Stores hidden JSON key-value pairs
        Param = struct; % Parameter 'block' handle
        SelectedParam = []; % Rolling selection memory - for checkboxes
        Step;   % Radiobutton Handle
        Sine;   % Radiobutton Handle
        Table;  % Parameter table
        Message;    % General-purpose message box
        Simulate;   % Simulation button handle
        TopAxes;    % Top axes handle
        BottomAxes; % Bottom axes handle
    end

    % Public Methods (non-application-specific):
    methods

        % Create panel that contains items
        function panel = createPanel(obj, parent, stack, border, position)
            panel = uipanel(parent, 'Units', 'Normalized');
            
            if nargin >= 3
                % Add event listener to panel object for child positioning.
                panel.UserData.Stack = stack;
                addlistener(panel, 'ChildAdded', @obj.positionChildren);
            end
            
            % Set border properties if included.
            if nargin >= 4
                if border == false
                    panel.BorderType = 'none';
                end
            end

            % Add user-defined position.
            if nargin >= 5
                panel.Position = position;
            end
        end
        
        % Create basic figure with preferred defaults
        function fig = createFigure(obj)
            % Set default figure environment
            fig = figure('MenuBar', 'none', 'Units', 'Normalized');
% % % % % % % % % % % % % % % % % % % % % % % % %             fig.CloseRequestFcn = @obj.closeUI;
            fig.ResizeFcn = @obj.resizeHandler;
            fig.NumberTitle = 'off';

            % Position figure and add close request function. 
            movegui(fig, 'center');

            % Add listener to normalize all figure items
            fig.UserData.Stack = 'normal';
            addlistener(fig, 'ChildAdded', @obj.positionChildren);
        end
        
        % Close request function
        function closeUI(~, src, ~)
            selection = questdlg("Close Window?");
            if strcmp(selection, 'Yes')
                delete(src);
            end
        end
        
        % Panel children position event (tiling engine)
        % Note that in r2018b and r2019b this causes a log to be
        % sent to the console. This due to be fixed in r2021a.
        function positionChildren(~, src, ~)
            width = 1/length(src.Children);
            switch lower(src.UserData.Stack)
                % Distribute elements vertically in a container.
                case 'vertical'
                    i = 0;
                    for child = src.Children'
                        child.Units = 'normalized';
                        child.Position = [0, i*width, 1, width];
                        i = i + 1;
                    end
                % Distribute elements horizontally in a container.
                case 'horizontal'
                    i = length(src.Children);
                    for child = src.Children'
                        i = i - 1;
                        child.Units = 'normalized';
                        child.Position = [i*width, 0, width, 1];
                    end
                    
                % If not tiled, ensure children use normalized units.
                case 'normal'
                    for child = src.Children'
                        if isprop(child, 'Units')
                            child.Units = 'normalized';
                        end
                    end
            end
        end
        
        % Initialise GUI
        function obj = speakerExplorer()
            
            % TEMP REMOVE LATER!!!
            close all; clc;
            
            % General figure/container structure
            obj.Figure = obj.createFigure();
            obj.Figure.Name = 'Speaker ';
            
            %---------------- Create model control panel -----------------%
            control_panel = obj.createPanel(obj.Figure, 'vertical', ...
                                                true, [0, 0, 0.35, 0.3]);
            control_panel.Title = 'Control';
            
            % Parameter sliders and labels
            obj.initParameter(control_panel, 'Parameter 1', 1);
            obj.initParameter(control_panel, 'Parameter 2', 2);

            % Batch simulation button
            obj.Simulate = uicontrol(control_panel, 'String', 'Simulate', ...
                                                    'Callback', @obj.simulate);
            
            %----------------- Create model config panel -----------------%
            config_panel = obj.createPanel(obj.Figure, 'vertical', ...
                                             true, [0, 0.3, 0.35, 0.2]);
            config_panel.Title = 'Configuration';
            
            % Simulation overview options
            config_options = obj.createPanel(config_panel, 'horizontal', false);
            obj.Step = uicontrol(config_options, 'style', 'radio', ...
                                     'String', 'Step', 'Value', 1, ...
                                     'Callback', @obj.configEditHandler);
            obj.Sine = uicontrol(config_options, 'style', 'radio', ...
                                     'String', 'Sine', 'Value', 0, ...
                                     'Callback', @obj.configEditHandler);
            uicontrol(config_options, 'style', 'check', 'String', 'Coupled', ...
                                  'Value', 1, 'Callback', @obj.configEditHandler);
            
            % Frequency control
            obj.initParameter(config_panel, 'Frequency', 3);

            %--------------- Create model parameter panel ----------------%
            parameter_panel = obj.createPanel(obj.Figure, 'vertical', ...
                                                true, [0, 0.5, 0.35, 0.5]);
            parameter_panel.Title = 'Parameters';
            
            % Add table with responsive resizing:
            obj.Table = obj.initTable(parameter_panel, 'src/model_parameters.json');
            table_position = getpixelposition(obj.Table);
            obj.Table.ColumnWidth = num2cell(repmat(table_position(3)/3, 1, 3));
            obj.Table.CellEditCallback = @obj.parameterEditHandler;
            
            %---------------- Create model results panel -----------------%
            
            % Axes cannot be cascaded like normal UIControls
            obj.TopAxes = axes(obj.Figure, 'OuterPosition', [0.35, 0.525, 0.65, 0.475]);
            grid(obj.TopAxes, 'on');
            obj.BottomAxes = axes(obj.Figure, 'OuterPosition', [0.35, 0.05, 0.65, 0.475]);
            grid(obj.BottomAxes, 'on');
            
            %---------------- Create model message panel -----------------%
            message_panel = obj.createPanel(obj.Figure, 'vertical', ...
                                            false, [0.35, 0, 0.65, 0.05]);
            obj.Message = uicontrol(message_panel, 'style', 'text', ...
                                           'ForegroundColor', [1, 0, 0]);
                                
            % Clear listener logs (see positionChildren note).
%             clc;
        end
        
    end
    
    % Private Methods:
    methods (Access = private)
        
        % Callback for resizing table to fit window
        function resizeHandler(obj, ~, ~)
            % Auto resize the table columns (CSS-like responsiveness)
            table_position = getpixelposition(obj.Table);
            obj.Table.ColumnWidth = num2cell(repmat(table_position(3)/3, 1, 3));
        end
        
        % Callback for editing table parameters
        function parameterEditHandler(obj, src, evt)
            % Set max number of selected parameters. 2 here to match GUI.
            max_parameters = 2;
            
            sel = cell2mat(src.Data(:, 3));
            num = nnz(sel);
            
            % Remove deselected entries.
            if evt.NewData == false
                obj.SelectedParam(obj.SelectedParam == evt.Indices(1)) = [];
            
            % Create rolling 'memory' of selected options.
            elseif num > 0 && num <= max_parameters
                obj.SelectedParam(num) = evt.Indices(1);
            
            % Remove oldest entry.
            elseif num > max_parameters
                obj.SelectedParam = circshift(obj.SelectedParam, -1);
                src.Data{obj.SelectedParam(end), 3} = false;
                obj.SelectedParam(end) = evt.Indices(1);
            end
            
            % Update slider labels.
            obj.updateControl();

            % Simulation is now out of date!
            obj.outOfDate();
        end
        
        % Callback for editing config parameters
        function configEditHandler(obj, src, ~)
            switch src.String
                case 'Step'
                    obj.Step.Value = 1;
                    obj.Sine.Value = 0;
                    obj.Param(3).Label.Enable = 'off';
                    obj.Param(3).Control.Enable = 'off';
                    obj.Param(3).Display.String = '';
                    obj.Param(3).Display.Enable = 'off';
                case 'Sine'
                    obj.Step.Value = 0;
                    obj.Sine.Value = 1;
                    obj.Param(3).Label.Enable = 'on';
                    obj.Param(3).Control.Enable = 'on';
                    obj.Param(3).Control.Value = 0.5;
                    obj.Param(3).Display.String = num2str(obj.HiddenEntries.freq);
                    obj.Param(3).Display.Enable = 'inactive';
            end
            
            % Simulation is now out of date!
            obj.outOfDate();
        end
        
        % Callback for editing control parameters
        function controlEditHandler(obj, src, ~, idx)
            % Logarithmic transform of original value.
%             base = 
%             value = src.v
%             obj.Param(idx).Display.Value = src.Value;
        end
        
        % Update the sliders with selected parameters
        function updateControl(obj, ~, ~)
           for i = 1:length(obj.SelectedParam)
               obj.Param(i).Label.String = obj.Table.Data{obj.SelectedParam(i), 1};
               obj.Param(i).Label.Enable = 'on';
               obj.Param(i).Control.Enable = 'on';
               obj.Param(i).Control.Value = 0.5;
               obj.Param(i).Display.String = obj.Table.Data{obj.SelectedParam(i), 2};
               obj.Param(i).Display.Enable = 'inactive';
           end
           for i = length(obj.SelectedParam) + 1:2
               obj.Param(i).Label.String = ['Parameter ', num2str(i)];
               obj.Param(i).Label.Enable = 'off';
               obj.Param(i).Control.Enable = 'off';
               obj.Param(i).Display.String = '';
               obj.Param(i).Display.Enable = 'off';
               
           end
        end
        
        % Show that simulation is out of date
        function outOfDate(obj, ~, ~)
            obj.Message.String = 'Results out of date! Re-simulate:';
            obj.Simulate.Enable = 'on';
        end
        
        % Run simulation and show results!
        function simulate(obj, ~, ~)
            
            
            obj.Message.String = '';
            obj.Simulate.Enable = 'off';
        end
        
        % Create modifiable parameter block
        function initParameter(obj, parent, label, idx)
            % Initialise block with scaling:
            obj.Param(idx).Control = uicontrol(parent, 'style', 'slider', ...
                                               'Value', 0.5, 'Callback', ...
                                               {@obj.controlEditHandler, idx});
            container = obj.createPanel(parent, 'horizontal', false);
            obj.Param(idx).Label = uicontrol(container, 'style', 'text', ...
                                                     'String', label);
            obj.Param(idx).Display = uicontrol(container, 'style', 'edit');
            
            % Set initial interactivity:
            obj.Param(idx).Label.Enable = 'off';
            obj.Param(idx).Control.Enable = 'off';
            obj.Param(idx).Display.Enable = 'off';
                  
        end
        
        % Read default values to initialise table
        function handle = initTable(obj, parent, path)
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
                    obj.HiddenEntries.(field{:}) = active_ws.(field{:});
                    active_ws = rmfield(active_ws, field{:});
                end
            end
            
            % Generate corresponding data table
            vars = struct2cell(active_ws);
            env = [fieldnames(active_ws), vars, num2cell(false(length(vars), 1))];
            handle = uitable(parent, 'Data', env, 'ColumnEditable', ...
                                 [false, true, true], 'ColumnName', ...
                               {'Variable', 'Value', 'Parameter?'}, ...
                                                          'RowName', []);
        end
        
    end
    
end

