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
            fig.CloseRequestFcn = @obj.closeUI;
            fig.NumberTitle = 'off';

            % Position figure and add close request function. 
            movegui(fig, 'center');

            % Add listener to normalize all figure items
            fig.UserData.Stack = 'normal';
            addlistener(fig, 'ChildAdded', @obj.positionChildren);
        end
        
        % Initialise GUI
        function obj = speakerExplorer()
            % General figure/container structure
            obj.Figure = obj.createFigure();
            obj.Figure.Name = 'Speaker ';
      
            % Create button layout panel
            ButtonPanel = obj.createPanel(obj.Figure, 'vertical', ...
                                               true, [0.05, 0.05, 0.5, 0.9]);
            ButtonPanel.Title = 'Controls';
            
            % Clear listener logs (see positionChildren note).
            clc;
        end
        
    end
    
    % Private Methods (Callbacks):
    methods (Access = private)
        
        % Close request function
        function closeUI(obj, src, ~)
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
    end
end

