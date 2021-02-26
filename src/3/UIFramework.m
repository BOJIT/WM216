 classdef UIFramework < handle
    % UIFramework - generic UI class for automating layouts.
    % This entire framework is static, so only one instance of all these
    % functions is required to handle multiple figures.
    
    % Note that this class uses a positioning engine in an event listener.
    % This means that UI items are arranged in stacked panels instead of
    % specifying co-ordinates manually.

    % UIFramework static methods that are exposed to the subclass.
    methods (Access = protected, Static)
        
        % Create base figure with preferred defaults.
        function handle = figure(close)
            % Set default figure environment
            handle = figure('MenuBar', 'none', 'Units', 'Normalized');
            
            % Add close confirmation if required
            if (nargin >= 1) && (close == true)
                handle.CloseRequestFcn = @UIFramework.closeHandler;
            end
            
            handle.ResizeFcn = @UIFramework.resizeHandler;
            handle.NumberTitle = 'off';

            % Position figure and add close request function
            movegui(handle, 'center');

            % Add listener to normalize all figure items
            handle.UserData.Stack = 'normal';
            addlistener(handle, 'ChildAdded', @UIFramework.arrangeHandler);
        end
        
        % Create panel that contains items.
        function handle = panel(parent, stack, border, position)
            handle = uipanel(parent, 'Units', 'Normalized');
            
            if nargin >= 2
                % Add event listener to panel object for child positioning.
                handle.UserData.Stack = stack;
                addlistener(handle, 'ChildAdded', @UIFramework.arrangeHandler);
            end
            
            % Set border properties if included.
            if nargin >= 3
                if border == false
                    handle.BorderType = 'none';
                end
            end

            % Add user-defined position.
            if nargin >= 4
                handle.Position = position;
            end
        end
        
        % Create parameter with label, slider and value.
        function handle = parameter(parent, label, base_value, edit, hook)
            handle = struct;
            
            % Assign object handles to struct fields.
            handle.Container = UIFramework.panel(parent, 'vertical', false);
            handle.Slider = uicontrol(handle.Container, 'style','slider');
            ui_div = UIFramework.panel(handle.Container, 'horizontal', false);
            handle.Label = uicontrol(ui_div, 'style', 'text', 'String', label);
            handle.Display = uicontrol(ui_div, 'style', 'edit');
            handle.Display.UserData.BaseValue = base_value;
            handle.Display.UserData.Value = base_value;
            % Choose whether the display is directly editable.
            if (nargin >= 4) && (edit == true)
                handle.Display.UserData.Editable = 'on';
                handle.Display.Callback = {@UIFramework.parameterEditHandler, handle};
            else
                handle.Display.UserData.Editable = 'inactive';
            end
            
            % Create slider callback with/without hook if required.
            if nargin >= 5
                handle.Slider.Callback = {@UIFramework.parameterSliderHandler, handle, hook};
            else
                handle.Slider.Callback = {@UIFramework.parameterSliderHandler, handle};
            end
            
            % Add function pointers for enabling/disabling the parameter.
            % Structs are passed by copy, so non-referenced field changes
            % will not be visible in the callbacks.
            handle.enable = @() UIFramework.parameterEnableHandler(handle);
            handle.disable = @() UIFramework.parameterDisableHandler(handle);
            
            % Parameter is enabled by default.
            handle.enable();
        end
    end
    
    % UIFramework static methods that are not exposed.
    % Functions with 'Handler' in the name cannot be called explicitly.
    methods (Access = private, Static)
        
        % Handler for arranging UI panels and elements (tiling engine).
        function arrangeHandler(src, ~)
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
        
        % Handler for dealing with figure close prompts.
        function closeHandler(src, ~)
            selection = questdlg("Close Window?");
            if strcmp(selection, 'Yes')
                delete(src);
            end
        end
        
        % Handler for rescaling non-normalised UI components.
        function resizeHandler(src, ~)
            % Auto resize any table columns (CSS-like responsiveness)
            tables = findobj(src, 'Type', 'uitable');
            for table = tables'
                cols = width(table.Data);
                if cols
                    table_pos = getpixelposition(table);
                    table.ColumnWidth = num2cell(repmat(table_pos(3)/cols, 1, cols));
                end
            end
        end
        
        % Handler to enable a parameter block.
        function parameterEnableHandler(src, ~)
            src.Slider.Value = 0.5;
            src.Slider.Enable = 'on';
            src.Label.Enable = 'on';
            src.Display.Enable = src.Display.UserData.Editable;
            src.Display.String = num2str(src.Display.UserData.BaseValue);
        end
        
        % Handler to disable a parameter block.
        function parameterDisableHandler(src, ~)
            src.Slider.Enable = 'off';
            src.Label.Enable = 'off';
            src.Display.Enable = 'off';
        end
        
        % Handler to change a parameter's slider value.
        function parameterSliderHandler(src, evt, handle, hook)
            % Scale base value based on slider and update display.
            val = 2*src.Value*handle.Display.UserData.BaseValue;
            handle.Display.String = num2str(val);
            handle.Display.UserData.Value = val;
            
            % If hook is given, call hook function.
            if nargin >= 4
                hook(src, evt);
            end
        end
        
        % Handler to change a parameter's base value.
        function parameterEditHandler(src, ~, handle)
            val = str2double(src.String);
            if isnan(val)
                errordlg('Please enter a valid numeric value!');
                src.String = num2str(handle.Display.UserData.BaseValue);
            else
                src.UserData.BaseValue = val;
                src.UserData.Value = val;
                handle.Slider.Value = 0.5;
            end
        end
        
    end
    
 end