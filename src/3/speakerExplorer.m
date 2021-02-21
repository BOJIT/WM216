classdef speakerExplorer < handle
    % Tested on r2018b. READ THE COMMENTS BELOW!!!
    
    % The tiling/figure engine is designed so that if the main figure
    % spawns a new figure, the parent is inactive until the child figure is
    % closed.
    
    % Note that this class uses a positioning engine in an event listener.
    % This means that UI items are arranged in stacked panels instead of
    % specifying co-ordinates manually.
    
    properties
        Figure;
        Param = struct;
        Table;
    end

    % Public Methods:
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
            obj.Param(1).Control = uicontrol(control_panel, 'style', 'slider');
            obj.Param(1).Label = uicontrol(control_panel, 'style', 'text', ...
                                           'String', 'Parameter 1');
            obj.Param(2).Control = uicontrol(control_panel, 'style', 'slider');
            obj.Param(2).Label = uicontrol(control_panel, 'style', 'text', ...
                                           'String', 'Parameter 2');

            % Batch simulation button
            uicontrol(control_panel, 'String', 'Simulate');
      
            %----------------- Create model config panel -----------------%
            config_panel = obj.createPanel(obj.Figure, 'vertical', ...
                                          true, [0, 0.3, 0.35, 0.2]);
            config_panel.Title = 'Configuration';
            
            % Simulation overview options
            config_options = obj.createPanel(config_panel, 'horizontal', false);
            uicontrol(config_options, 'style', 'radio', 'String', 'Step');
            uicontrol(config_options, 'style', 'radio', 'String', 'Sine');
            uicontrol(config_options, 'style', 'check', 'String', 'Couple');
            
            % Frequency control
            obj.Param(3).Control = uicontrol(config_panel, 'style', 'slider');
            obj.Param(3).Label = uicontrol(config_panel, 'style', 'text', ...
                                           'String', 'Frequency');
            
            %--------------- Create model parameter panel ----------------%
            parameter_panel = obj.createPanel(obj.Figure, 'vertical', ...
                                             true, [0, 0.5, 0.35, 0.5]);
            parameter_panel.Title = 'Parameters';
            
            % Add table with responsive resizing:
            obj.Table = obj.initTable(parameter_panel, 'src/model_parameters.json');
            table_position = getpixelposition(obj.Table);
            obj.Table.ColumnWidth = num2cell(repmat(table_position(3)/3, 1, 3));
            
            %---------------- Create model results panel -----------------%
            results_panel = obj.createPanel(obj.Figure, 'vertical', ...
                                           true, [0.35, 0, 0.65, 1]);
            results_panel.Title = 'Results';
            
            % Clear listener logs (see positionChildren note).
            clc;
        end
        
    end
    
    % Private Methods (Callbacks):
    methods (Access = private)
        
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
        
        % Hook called on resizing of window.
        function resizeHandler(obj, ~, ~)
            % Auto resize the table columns (CSS-like responsiveness)
            table_position = getpixelposition(obj.Table);
            obj.Table.ColumnWidth = num2cell(repmat(table_position(3)/3, 1, 3));
        end
    end
    
    % Static Methods:
    methods (Static)
        
        % Read default values to initialise table.
        function handle = initTable(parent, path)
            active_ws = [];
            % Get environment variables from JSON
            json = fileread(path);
            param = jsondecode(json);
            for ws = param.workspace'
                if strcmp(ws{:}.name, 'speakerModel')
                    active_ws = ws{:};
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

