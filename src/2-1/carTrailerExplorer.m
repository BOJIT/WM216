% DESCRIPTION:  GUI for analysing the car trailer model.
% AUTHORS:      u1942959, u1942961, u1943002, u1943142
% DATE CREATED: 20.02.21

classdef carTrailerExplorer < UIFramework

properties
    % UI Object Handles
    Figure;
    Image;
    TabGroup;
    Axes;
    
    % Workspace Environment Parameters (From JSON)
    Workspace;
    
    % User Configuration
    ModelName = 'carTrailerModel';
    JSON = 'model_parameters.json';
    AxesTitles =  {'Displacement',    'Velocity',       'Acceleration'        };
    AxesYLabels = {'displacment [m]', 'Velocity [m/s]', 'Acceleration [m/s^2]'};
    
end

methods
    
    % Initialise GUI
    function obj = carTrailerExplorer()
        %---------------------- Top Level Elements -----------------------%

        obj.Figure = obj.figure(false);
        obj.Figure.Name = 'Car and Trailer Model';
        obj.Figure.MenuBar = 'none';
        
        obj.Workspace = obj.loadJSON();
        
        % Load both images and only display one.
        obj.Image.Frame = axes(obj.Figure, 'Position', [0.05 0.6 0.9 0.36]);
        obj.Image.CTS = imread('img_cts.jpg');
        obj.Image.CTSD = imread('img_ctsd.jpg');
        imshow(obj.Image.CTS, 'Parent', obj.Image.Frame);
        
        % Tab group for graphs and controls.
        obj.TabGroup = uitabgroup(obj.Figure, 'Position', [0.01 0.01 0.98 0.58]);
        
        %---------------------- Create Annotations -----------------------%
        
        % GUI Heading.
        uicontrol(obj.Figure, 'Style', 'Text', 'FontSize', 13.5, ...
                  'Position', [0.35 0.95 0.3 0.05], 'String', 'Car Trailer Model');
                                 
        % Add arrow overlay.
        annotation(obj.Figure, 'arrow', [0.03 0.20], [0.94 0.94]);
        annotation(obj.Figure, 'arrow', [0.72 0.87], [0.89 0.89]);
        annotation(obj.Figure, 'arrow', [0.16 0.03], [0.61 0.61]);
        
        % Model labels.
        uicontrol(obj.Figure, 'Style', 'Text', 'FontSize', 10, ...
                  'tooltip','This is the rolling resistance and air resistance of the car', ...
                  'Position', [0.01 0.87 0.18 0.05], 'String', 'Ff1,F1(v)');
        uicontrol(obj.Figure, 'Style', 'Text', 'FontSize', 10, ...
                  'tooltip','This is the rolling resistance and air resistance of the trailer', ...
                  'Position', [0.5 0.89 0.2 0.05], 'String', 'Ff2,F2(v)');
        uicontrol(obj.Figure, 'Style', 'Text', 'FontSize', 10, ...
                  'tooltip', 'This is the driving force of the car', ...
                  'Position', [0.165 0.6 0.1 0.03],'String', 'F');
        
        % Model parameters.
        obj.createField('m1', [0.18 0.72 0.2 0.05], 'M1 = ', 'This is the mass of the car in Kg');
        obj.createField('m2', [0.67 0.77 0.2 0.05], 'M2 = ', 'This is the mass of the trailer in kg');
        obj.createField('k', [0.47 0.61 0.2 0.05], 'k = ', 'This is the spring constant');
        ch = obj.createField('c', [0.43 0.81 0.2 0.05], 'c = ', 'This is the dampening constant');
        ch.Panel.Visible = 'off'; % Hide panel.
        
        %---------------------- Create Control Tab -----------------------%
        
        ctrl_tab = obj.tab(obj.TabGroup, 'Title', 'Controls');
        
        uicontrol(ctrl_tab, 'Style', 'pushbutton', 'tooltip', 'This runs the simulation', ...
                  'Position', [0.04 0.8 0.2 0.1], 'String' , 'Run', 'callback', @obj.simulate);
        uicontrol(ctrl_tab,'Style', 'pushbutton', 'tooltip','This sets the environment constants', ...
                  'Position', [0.28 0.8 0.2 0.1], 'String' ,'Set Constants', 'callback', @obj.setConstants);

        uicontrol(ctrl_tab, 'Style', 'checkbox','tooltip','This adds a dampener to the system', ...
                  'Position', [0.52 0.8 0.2 0.1], 'String', 'Add Dampener', 'callback', {@obj.setDamping, ch});
        
        th = uicontrol(ctrl_tab, 'Style', 'edit', 'FontSize', 10, ...
                       'String', obj.Workspace.StopTime, 'tooltip', ...
                       'This is the maximum time of the simulation', ...
                       'Position', [0.76 0.8 0.2 0.1], 'callback', @obj.setField);
        th.UserData.Key = 'StopTime';

        uicontrol(ctrl_tab, 'Style', 'Text', 'FontSize', 10, 'Position', ...
                                [0.69 0.7 0.3 0.1], 'String', 'Stop Time (s)');

        %------------------------ Create Axes Tabs -----------------------%
        
        for i = 1:length(obj.AxesTitles)
            tab = obj.tab(obj.TabGroup, 'Title', obj.AxesTitles{i});
            obj.Axes{i} = axes(tab); % Ignore MATLAB warning here.
            xlabel(obj.Axes{i}, 'Time [sec]');
            ylabel(obj.Axes{i}, obj.AxesYLabels{i});
        end
  
        %------------------------ Create Menu Bar ------------------------%
        
        menu = uimenu(obj.Figure, 'Label', 'File');
        uimenu(menu, 'Label', 'Open Simulink Model', 'Accelerator', ...
                                          'o', 'Callback', @obj.openSim);
        uimenu(menu, 'Label', 'Exit', 'Accelerator', 'x', ...
                        'Callback', @(~, ~) close(obj.Figure));
        uimenu(menu, 'Label', 'Information', 'Accelerator', 'i', ...
                                           'Callback', @obj.showInfo);

        %-----------------------------------------------------------------%
    end

end

%% callback functions

% Private Methods:
methods (Access = private)

    % Run simulation using SimFramework and populate graphs
    function simulate(obj, ~, ~)
        obj.enableUI('off'); % Disables all user inputs while simulating.
        
        if obj.Workspace.k < 4 % Ensure simulation can solve problem
            errordlg('constant k is too small, oscillations are to large to calculate. Increase k to above 4.');
            obj.enableUI('on'); % Re-enables user inputs.
            return;
        end
        
        % Get simulation data.
        results = SimFramework(obj.JSON, false, obj.ModelName, obj.Workspace);
        
        % Add simulation data to plots.
        for i = 1:length(obj.Axes)
            plot(results.yout{i}.Values, 'Parent', obj.Axes{i});
            legend(obj.Axes{i}, 'Car', 'Trailer');
        end

        obj.enableUI('on'); % Re-enables user inputs.
        
        % Auto-switch to first graph.
        obj.TabGroup.SelectedTab = obj.Axes{1}.Parent;
    end

    % Update workspace variable with input conditioning.
    function setField(obj, src, ~)
        
        val = str2double(src.String);
        if isnan(val) % Checking if input is numeric.
            errordlg('This field must be a number.')
            return;
        end
        
        if val < 0 % Checking if input is positive.
            errordlg('This field must be a positive number.')
            return;
        end
        
        % If valid, assign to workspace.
        obj.Workspace.(src.UserData.Key) = val;
    end

    % Prompt for model constants.
    function setConstants(obj, ~ , ~)
        prompt = {'coefficient of friction, u is:', 'gravity g is:', ...
                  'driving force F is:','friction constant a1 is:', ...
                  'friction constant a2 is:'};
        dlgtitle = 'Constants';
        dims = [1 35]; % Default dimensions
        
        keys = {'u', 'g', 'F', 'a1', 'a2'}; % Pull default values from Workspace.
        
        definput = cellfun(@(x) num2str(obj.Workspace.(x)), keys, 'UniformOutput', false);
        answer = inputdlg(prompt, dlgtitle, dims, definput)';
        
        for i = 1:length(keys)
            if ~isnan(str2double(answer{i}))
                obj.Workspace.(keys{i}) = str2double(answer{i});
            end
        end
    end
    
    % Enable/Disable damping
    function setDamping(obj, src, ~, ch)
        if src.Value % Check state of checkbox.
            imshow(obj.Image.CTSD, 'Parent', obj.Image.Frame);
            ch.Panel.Visible = 'on'; % Show C user field.
        else
            imshow(obj.Image.CTS, 'Parent', obj.Image.Frame);
            ch.Panel.Visible = 'off'; % Hide C user field.
        end
        obj.Workspace.E = src.Value; % Update workspace parameter.  
    end

    % Disable all GUI Buttons
    function enableUI(obj, state)
        % Find all buttons and edit boxes under parent figure.
        buttons = findobj(obj.Figure, 'Style', 'pushbutton');
        set(buttons, 'enable', state);
        edits = findobj(obj.Figure, 'Style', 'edit');
        set(edits, 'enable', state);
    end

     % Display contents of README file in a text box
    function showInfo(~, ~, ~)
        message = fileread('README.txt');
        msgbox(message, 'Information');
    end

    % Open Simulink file so user can examine it
    function openSim(~, ~, ~)
        filename = uigetfile('.slx');

        if  filename == 0
            return;         % if no file is selected then exit function
        end
        
        if ~contains(filename, '.slx')                % check file type
            errordlg('File must be of type .slx');
            return;
        else
            open_system(filename);
        end
        
    end
    
    % Create an editable field with workspace key
    function field = createField(obj, key, position, string, tooltip)
        field.Panel = obj.panel(obj.Figure, 'normal', true, position);
        field.Control = uicontrol(field.Panel, 'Style', 'edit', 'FontSize', 10, ...
              'String', obj.Workspace.(key), 'tooltip', tooltip, 'Position', ...
                                     [0.35 0.05 0.6 0.9], 'callback', @obj.setField);
        field.Control.UserData.Key = key;
        field.Label = uicontrol(field.Panel, 'Style', 'Text', 'FontSize', 10, ...
                                'Position', [0.01 0.05 0.3 0.9],'String' ,string);
    end
    
    % Load JSON Variables into workspace
    function workspace = loadJSON(obj)
        workspace = [];
        
        json = fileread(obj.JSON);
        param = jsondecode(json);
        for ws = param.workspace'
            if strcmp(ws{:}.name, obj.ModelName)
                workspace = ws{:};
            end
        end
        
        if isempty(workspace)
            error('Workspace not found!');
        end
    end

end

end