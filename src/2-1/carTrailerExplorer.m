% DESCRIPTION:  GUI for looking at
% AUTHOR:       Ross Geddes, James Bennion-Pedley
% DATE CREATED: 20/02/2021

classdef carTrailerExplorer < UIFramework

properties
    % UI Object Handles
    Figure;
    Image;
    TabGroup;
    Axes;
    
    % Workspace Parameters
    Workspace;

    % setting graphic handles that need to be accessed throughout the script
    M1h
    M2h
    kh
    ch
    panel_4
    % setting dampening constants to default zero to disable dampening
    E = 0;
    c = 0;
    
    TimeHandle;
    
    % User Configuration
    ModelName = 'carTrailerModelDampened';
    JSON = 'model_parameters.json';
    AxesTitles =  {'Displacement',    'Velocity',       'Acceleration'        };
    AxesYLabels = {'displacment [m]', 'Velocity [m/s]', 'Acceleration [m/s^2]'};
    
end

methods
    
    % Initialise GUI
    function obj = carTrailerExplorer()
        
        %TEMP!!!!
        close all; clc;
        
        %---------------------- Top Level Elements -----------------------%

        obj.Figure = obj.figure(false);
        obj.Figure.Name = 'Car and Trailer Model';
        obj.Figure.MenuBar = 'none';
        
%         obj.
        
        % Load both images and only display one.
        obj.Image.Frame = axes(obj.Figure, 'Position', [0.05 0.6 0.9 0.36]);
        obj.Image.CTS = imread('img_cts.jpg');
        obj.Image.CTSD = imread('img_ctsd.jpg');
        imshow(obj.Image.CTS, 'Parent', obj.Image.Frame);
        
        % Tab group for graphs and controls.
        obj.TabGroup = uitabgroup(obj.Figure, 'Position', [0.01 0.01 0.98 0.58]);
        
        %---------------------- Create Control Tab -----------------------%
        
        ctrl_tab = obj.tab(obj.TabGroup, 'Title', 'Controls');
        
        uicontrol(ctrl_tab, 'Style', 'pushbutton', 'tooltip', 'This runs the simulation', ...
                  'Position', [0.04 0.8 0.2 0.1], 'String' , 'Run', 'callback', @obj.simulate);
        uicontrol(ctrl_tab,'Style', 'pushbutton', 'tooltip','This sets the environment constants', ...
                  'Position', [0.28 0.8 0.2 0.1], 'String' ,'Set Constants', 'callback', @obj.ConstantSet);

        uicontrol(ctrl_tab, 'Style', 'checkbox','tooltip','This adds a dampener to the system', ...
                  'Position', [0.52 0.8 0.2 0.1], 'String', 'Add Dampener', 'callback', @obj.AddDampener);
        
        % @TODO LOAD SPEED FROM CONFIG!!!
        obj.TimeHandle = uicontrol(ctrl_tab, 'Style', 'edit', 'FontSize', 10, ...
                'String', 475, 'tooltip','This is the maximum time of the simulation', 'Units','normalized', 'Position', [0.76 0.8 0.2 0.1],'callback',@ValueSet);

        uicontrol(ctrl_tab, 'Style', 'Text', 'FontSize', 10, 'Position', [0.69 0.7 0.3 0.1], 'String', 'max time (s)');

        % GUI Constructor Functions
%         obj.constantBoxes() %function to set all input boxes of figure


        %------------------------ Create Axes Tab ------------------------%
        
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
                  'tooltip','This is the rolling resitance and air resitance of the car', ...
                  'Position', [0.01 0.87 0.18 0.05], 'String', 'Ff1,F1(v)');
        uicontrol(obj.Figure, 'Style', 'Text', 'FontSize', 10, ...
                  'tooltip','This is the rolling resitance and air resitance of the trailer', ...
                  'Position', [0.5 0.89 0.2 0.05], 'String', 'Ff2,F2(v)');
        uicontrol(obj.Figure, 'Style', 'Text', 'FontSize', 10, ...
                  'tooltip', 'This is the driving force of the car', ...
                  'Position', [0.165 0.6 0.1 0.03],'String', 'F');
        
        %-----------------------------------------------------------------%
    end

end

%% callback functions

% Private Methods:
methods (Access = private)

    function simulate(~,~)%retrieves variables from gui and sends them to function that runs simulation
        %performs error handling, ensures inputs to simulation are numeric and defined.
        
        disable()% disables all user inputs while simulating
        
        m = getappdata(figure_hadl,'constants');%retrieving constant data
        
        
        if isempty(m)%ensuring constants are set
            errordlg('please set constants.')%warning user
            uiwait%pausing operation
            enable()%re-enabling user input
            ConstantSet()%opening constant setting menu
            return;
        end
        %defining inputs to simulation function
        u = str2double(m{1,1});
        g = str2double(m{2,1});
        F = str2double(m{3,1});
        a1 = str2double(m{4,1});
        a2 = str2double(m{5,1});
        m1 = M1h.Value;
        m2 = M2h.Value;
        k = kh.Value;
        c = ch.Value;
        T = Th.String;
        
        if k < 4 %ensuring simulation can solve problem
            errordlg('constant k is too small, oscillations are to large to calculate. Increase k to above 4.')
            enable()%re-enabling user input
            return;
        end
        
        if sum(isnan([m1,m2,u,a1,a2,g,k,c,E,F]))%ensuring all inputs are numbers
            errordlg('please make sure constants are numbers.')
            enable()%re-enabling user input
            return;
        end
        
        %running function that handles simulation
        [s,t] = OLD_CarTrailerModel_OLD(m1,m2,u,a1,a2,g,k,c,E,F,T);
        
        %plotting velocity output from simulation
        plot(axes2_hadl, t, s(:,1), 'r')
        hold(axes2_hadl, 'on')
        plot(axes2_hadl, t,s(:,2), 'b')
        title(axes2_hadl,'Velocity')
        legend(axes2_hadl,'Car', 'Trailer')
        xlabel(axes2_hadl,'Time [sec]')
        ylabel(axes2_hadl,'Velocity [m/s]')
        enable()%re-enabling user input
        
    end

    
    function AddDampener(obj, src, ~)
        
        if src.Value %seeing if checkbox is checked
            imshow(obj.Image.CTSD, 'Parent', obj.Image.Frame);
            set(obj.panel_4,'Visible','on')%dampening constant input made visible
            E = 1;% enabling dampening in simulation
        else
            imshow(obj.Image.CTS, 'Parent', obj.Image.Frame);
            E = 0; %disabling dampening in simulation
            set(obj.panel_4,'Visible','off')%removing dampening constant input
        end
        
    end

    function ValueSet(obj,~)%sets handle value to handle string, performs error handling
        
        if isnan(str2double(obj.String)) %checking if input is a string
            errordlg('This field must be a number.')
            return;
        end
        
        if str2double(obj.String)<0 %checking if input is positive
            errordlg('This field must be a positive number.')
            return;
        end
        
        obj.Value = str2double(obj.String);%setting value to string
    end

    function ConstantSet(~,~)%sets environment constants
        
        prompt = {'coeficient of friction, u is:','gravity g is:','driving force F is:','friction constant a1 is:','friction constant a2 is:'};
        dlgtitle = 'constants';
        dims = [1 35];%default dimensions
        definput = {'0.002','9.81','5000','5','2.5'};%default values
        answer = inputdlg(prompt,dlgtitle,dims,definput);
        setappdata(figure_hadl,'constants', answer)%setting constant data to be used later in gui
        
    end

    % Disable all GUI Buttons
    function enable(obj, state)
        % Find all buttons and edit boxes under parent figure.
        buttons = findobj(obj.Figure, 'Style', 'pushbutton');
        set(buttons, 'enable', state);
        edits = findobj(obj.Figure, 'Style', 'edit');
        set(edits, 'enable', state);
    end

     % Display contents of README file in a text box.
    function showInfo(~, ~, ~)
        message = fileread('README.txt');
        msgbox(message,'Information');
    end

    function openSim(~, ~, ~)%opens Simulink file so user can examine it
        
        filename = uigetfile('.slx');%asking user for file in directory
        %making sure a file was selected
        
        if  filename == 0
            return; %if no file is selected then exiting function
        end
        
        if ~contains(filename, '.slx') %making sure file is the correct type
            errordlg('File must be of type ......');
            return;
        else
            open_system(filename);
        end
        
    end
    
    % Create constant box
    function handle = createField(obj, name, position, tooltip)
        
    end
    
    % Load JSON Variables into workspace.

%% constructor functions

    function constantBoxes()%defining user input elements that appear on image
        
        panel_1 = uipanel(figure_hadl, 'Position', [0.18 0.72 0.2 0.05]);
        M1h = uicontrol(panel_1,'FontSize', 10,'Style','edit','String', 1400,'Value',1400,'tooltip','This is the mass of the car in Kg', 'Units','normalized', 'Position', [0.35 0.05 0.6 0.9],'callback',@ValueSet);
        uicontrol(panel_1,'FontSize', 10,'Style', 'Text', 'Unit','Normalized', 'Position', [0.01 0.05 0.3 0.9],'String' ,'M1 = ')
        
        panel_2 = uipanel(figure_hadl, 'Position', [0.67 0.77 0.2 0.05]);
        M2h = uicontrol(panel_2,'FontSize', 10,'Style','edit','String', 600,'Value',600,'tooltip','This is the mass of the trailer in kg', 'Units','normalized', 'Position', [0.35 0.05 0.6 0.9],'callback',@ValueSet);
        uicontrol(panel_2,'FontSize', 10,'Style', 'Text', 'Unit','Normalized', 'Position', [0.01 0.05 0.3 0.9],'String' ,'M2 = ','tooltip','This is the mass of the trailer in kg')
        
        panel_3 = uipanel(figure_hadl, 'Position', [0.47 0.61 0.2 0.05]);
        kh = uicontrol(panel_3,'FontSize', 10,'Style','edit','String', 12150,'Value',3*(1800 + 250*9),'tooltip','This is the spring constant', 'Units','normalized', 'Position', [0.35 0.05 0.6 0.9],'callback',@ValueSet);
        uicontrol(panel_3,'FontSize', 10,'Style', 'Text', 'Unit','Normalized', 'Position', [0.01 0.05 0.3 0.9],'String' ,'k = ','tooltip','This is the spring constant')
        
        panel_4 = uipanel(figure_hadl, 'Position', [0.43 0.81 0.2 0.05],'Visible','off');
        ch = uicontrol(panel_4,'FontSize', 10,'Style','edit','String', 1000,'Value',1000,'tooltip','This is the dampening constant', 'Units','normalized', 'Position', [0.35 0.05 0.6 0.9],'callback',@ValueSet);
        uicontrol(panel_4,'FontSize', 10,'Style', 'Text', 'Unit','Normalized', 'Position', [0.01 0.05 0.3 0.9],'String' ,'c = ','tooltip','This is the dampening constant')
    end
end

end