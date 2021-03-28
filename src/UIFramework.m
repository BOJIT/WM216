% DESCRIPTION:  Framework for automating GUI layout. Not section-specific.
% AUTHORS:      u1942959, u1942961, u1943002, u1943142
% DATE CREATED: 19.02.21

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
        function handle = parameter(parent, label, base_value, edit, minmax, hook, minmax_hook)
            handle = struct;
            
            % Assign object handles to struct fields.
            handle.Container = UIFramework.panel(parent, 'vertical', false);
            handle.Slider = uicontrol(handle.Container, 'style','slider');
            ui_div = UIFramework.panel(handle.Container, 'horizontal', false);
            handle.Label = uicontrol(ui_div, 'style', 'text');
            
            % Choose label type based on arg.
            if isa(label, 'cell')
                handle.Label.UserData.Label = label{1};
                handle.Label.UserData.DisableLabel = label{2};
            else
                handle.Label.UserData.Label = label;
                handle.Label.UserData.DisableLabel = false;
            end
            
            handle.Display = uicontrol(ui_div, 'style', 'edit');
            handle.Display.UserData.BaseValue = base_value;
            handle.Display.UserData.Value = base_value;
            handle.Display.UserData.MinValue = base_value - base_value/2;
            handle.Display.UserData.MaxValue = base_value + base_value/2;
            
            % Choose whether the display is directly editable.
            if (nargin >= 4) && (edit == true)
                handle.Display.UserData.Editable = 'on';
                handle.Display.Callback = {@UIFramework.parameterEditHandler, handle};
            else
                handle.Display.UserData.Editable = 'inactive';
            end
            
            % Add min/max values if required.
            if (nargin >= 5) && (minmax == true)
                minmax_div = UIFramework.panel(handle.Container, 'horizontal', false);
                handle.MinLabel = uicontrol(minmax_div, 'style', 'text' , 'String', 'Min');
                handle.MinDisplay = uicontrol(minmax_div, 'style', 'edit');
                handle.MaxLabel = uicontrol(minmax_div, 'style', 'text' , 'String', 'Max');
                handle.MaxDisplay = uicontrol(minmax_div, 'style', 'edit');
                
                % Add optional min_max hook.
                if nargin >= 7
                    handle.MinDisplay.Callback = {@UIFramework.parameterEditMinHandler, ...
                                                                            handle, minmax_hook};
                    handle.MaxDisplay.Callback = {@UIFramework.parameterEditMaxHandler, ...
                                                                            handle, minmax_hook};
                else
                    handle.MinDisplay.Callback = {@UIFramework.parameterEditMinHandler, handle};
                    handle.MaxDisplay.Callback = {@UIFramework.parameterEditMaxHandler, handle};
                end
            end
            
            % Create slider callback with/without hook if required.
            if nargin >= 6
                handle.Slider.Callback = {@UIFramework.parameterSliderHandler, handle, hook};
                addlistener(handle.Slider, 'Value', 'PostSet', @(src, evt) ...
                    UIFramework.parameterPreviewHandler(src, evt, handle, hook));
            else
                handle.Slider.Callback = {@UIFramework.parameterSliderHandler, handle};
                addlistener(handle.Slider, 'Value', 'PostSet', @(src, evt) ...
                    UIFramework.parameterPreviewHandler(src, evt, handle));
            end
            
            % Add function pointers for enabling/disabling the parameter.
            % Structs are passed by copy, so non-referenced field changes
            % will not be visible in the callbacks.
            handle.enable = @() UIFramework.parameterEnableHandler(handle);
            handle.disable = @() UIFramework.parameterDisableHandler(handle);
            
            % Parameter is enabled by default.
            handle.enable();
        end
        
        % Create table - wrapper to handle correct column resizing.
        function handle = table(varargin)
            handle = uitable(varargin{:});
            UIFramework.resizeHandler(handle);
        end
        
        % Create tab - wrapper to handle tiling engine.
        function handle = tab(varargin)
            handle = uitab(varargin{:});
            % Add event listener to panel object for child positioning.
            handle.UserData.Stack = 'normal';
            addlistener(handle, 'ChildAdded', @UIFramework.arrangeHandler);
        end
    end
    
    % UIFramework static methods that are not exposed.
    % Functions with 'Handler' in the name cannot be called explicitly.
    methods (Access = private, Static)
        
        % Handler for arranging UI panels and elements (tiling engine).
        function arrangeHandler(src, ~)
            % Variable shortenings:
            width = 1/length(src.Children);
            
            i = 0;
            for child = src.Children'
                % Ensure all applicable objects are normalised.
                if any(strcmpi(src.UserData.Stack, {'normal', 'vertical', 'horizontal'}))
                    if isprop(child, 'Units') 
                        child.Units = 'normalized';
                    end
                end
                
                % Distribute elements vertically in a container.
                if strcmpi(src.UserData.Stack, 'vertical')
                    child.Position = [0, i*width, 1, width];
                end
                
                % Distribute elements horizontally in a container.
                if strcmpi(src.UserData.Stack, 'horizontal')
                    child.Position = [(length(src.Children) - 1 - i)*width, 0, width, 1];
                end
                
                % Call resize handler for any non-normalised tables.
                if isgraphics(child, 'uitable')
                    UIFramework.resizeHandler(src);
                end
                
                i = i + 1;
            end
            
            if verLessThan('matlab', '9.8')
                % Clear eventData console print.
                fprintf(repmat('\b', 1, 38));
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
                cols = size(table.Data, 2);
                if cols
                    table_pos = getpixelposition(table);
                    % Set widths excluding scroll bar.
                    table.ColumnWidth = num2cell(repmat(table_pos(3)/cols ...
                                                          - 20/cols, 1, cols));
                end
            end
        end
        
        % Handler to enable a parameter block.
        function parameterEnableHandler(src)
            src.Slider.Value = 0.5;
            src.Slider.Enable = 'on';
            src.Label.Enable = 'on';
            src.Label.String = src.Label.UserData.Label;
            src.Display.Enable = src.Display.UserData.Editable;
            src.Display.UserData.Value = src.Display.UserData.BaseValue;
            src.Display.String = num2str(src.Display.UserData.BaseValue, '%.4g');
            if isfield(src, 'MinLabel')
                src.MinLabel.Enable = 'on';
                src.MinDisplay.Enable = 'on';
                src.MinDisplay.String = num2str(src.Display.UserData.MinValue, '%.4g');
                src.MaxLabel.Enable = 'on';
                src.MaxDisplay.Enable = 'on';
                src.MaxDisplay.String = num2str(src.Display.UserData.MaxValue, '%.4g');
            end
        end
        
        % Handler to disable a parameter block.
        function parameterDisableHandler(src)
            src.Slider.Enable = 'off';
            src.Label.Enable = 'off';
            if src.Label.UserData.DisableLabel ~= false
                src.Label.String = src.Label.UserData.DisableLabel; 
            end
            src.Display.Enable = 'off';
            src.Display.String = '';
            if isfield(src, 'MinLabel')
                src.MinLabel.Enable = 'off';
                src.MinDisplay.Enable = 'off';
                src.MinDisplay.String = '';
                src.MaxLabel.Enable = 'off';
                src.MaxDisplay.Enable = 'off';
                src.MaxDisplay.String = '';
            end
        end
        
        % Handler to change a parameter's slider value.
        function parameterSliderHandler(src, evt, handle, hook)
            % Scale base value based on slider and update display.
            val = handle.Display.UserData.MinValue + ...
                       src.Value*(handle.Display.UserData.MaxValue ...
                                - handle.Display.UserData.MinValue);
            handle.Display.String = num2str(val, '%.4g');
            handle.Display.UserData.Value = val;
            
            % If hook is given, call hook function.
            if nargin >= 4
                hook(src, evt);
            end
        end
        
        % Handler to get live-updating slider value.
        function parameterPreviewHandler(~, evt, handle, hook)
            if isprop(evt, 'AffectedObject')
                new_src = evt.AffectedObject;
                % Edge case - stops initialisation code executing callback.
                if new_src.Value == 0.5
                    return;
                end
                if nargin >= 4
                    UIFramework.parameterSliderHandler(new_src, [], handle, hook);
                else
                    UIFramework.parameterSliderHandler(new_src, [], handle);
                end
            end
        end
        
        % Handler to change a parameter's base value.
        function parameterEditHandler(src, ~, handle)
            val = str2double(src.String);
            if isnan(val)
                errordlg('Please enter a valid numeric value!');
                src.String = num2str(handle.Display.UserData.BaseValue, '%.4g');
            else
                src.UserData.BaseValue = val;
                src.UserData.Value = val;
                handle.Slider.Value = 0.5;
                src.String = num2str(handle.Display.UserData.BaseValue, '%.4g');
            end
        end
        
        % Handler to change a parameter's base value.
        function parameterEditMinHandler(src, evt, handle, hook)
            val = str2double(src.String);
            if isnan(val) || val >= handle.Display.UserData.MaxValue
                errordlg('Please enter a valid numeric value that is less than Max!');
                src.String = num2str(handle.Display.UserData.MinValue, '%.4g');
            else
                handle.Display.UserData.MinValue = val;
                handle.Display.UserData.BaseValue = (val + handle.Display.UserData.MaxValue)/2;
                src.String = num2str(handle.Display.UserData.MinValue, '%.4g');
                
                % If hook is given, call hook function.
                if nargin >= 4
                    hook(src, evt);
                end
            end
            
            
        end
        
            % Handler to change a parameter's base value.
        function parameterEditMaxHandler(src, evt, handle, hook)
            val = str2double(src.String);
            if isnan(val) || val <= handle.Display.UserData.MinValue
                errordlg('Please enter a valid numeric value that is greater than Min!');
                src.String = num2str(handle.Display.UserData.MaxValue, '%.4g');
            else
                handle.Display.UserData.MaxValue = val;
                handle.Display.UserData.BaseValue = (val + handle.Display.UserData.MinValue)/2;
                src.String = num2str(handle.Display.UserData.MaxValue, '%.4g');
                
                % If hook is given, call hook function.
                if nargin >= 4
                    hook(src, evt);
                end
            end
        end
        
    end
    
 end