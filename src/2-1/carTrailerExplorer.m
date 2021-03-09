% u1943002
% 20/02/2021
% WM216 group coursework
% Part 2.1 car towing a caravan dynamic model
%=========================================================================

function carTrailerExplorer

%clearing workspace and closing any open figures
close all
clear

%% constants

% setting graphic handles that need to be accessed throughout the script
global M1h
global M2h
global kh
global ch
global panel_4
%setting dampening constants to default zero to disable dampening
E = 0;
c = 0;

%% Building GUI layout

%setting up figure and axis location and properties
figure_hadl = figure('Name','Car and Trailer Model','menubar','none','CloseRequestFcn',@Exit);
axes1_hadl = axes(figure_hadl,'Units','normalized','Position',[0.05 0.6 0.9 0.36]);
axes2_hadl = axes(figure_hadl,'Units','normalized','Position',[0.08 0.09 0.9 0.4],'Visible','off');

%setting heading for GUI
uicontrol(figure_hadl,'FontSize', 13.5,'Style', 'Text', 'Unit','Normalized', 'Position', [0.35 0.95 0.3 0.05],'String' ,'Car Trailer Model')

% defining user inputs for GUI
uicontrol(figure_hadl,'Style', 'pushbutton', 'Unit','Normalized','tooltip','This runs the simulation', 'Position', [0.04 0.53 0.2 0.05],'String' ,'Run','callback',@simulate);
uicontrol(figure_hadl,'Style', 'pushbutton', 'Unit','Normalized','tooltip','This sets the environment constants', 'Position', [0.28 0.53 0.2 0.05],'String' ,'Set Constants','callback',@ConstantSet);
uicontrol(figure_hadl,'Style', 'checkbox', 'Unit','Normalized','tooltip','This adds a dampener to the system', 'Position', [0.52 0.53 0.2 0.05],'String' ,'Add Dampener','callback',@AddDampener);
Th = uicontrol(figure_hadl,'FontSize', 10,'Style','edit','String', 475,'tooltip','This is the maximum time of the simulation', 'Units','normalized', 'Position', [0.76 0.53 0.2 0.05],'callback',@ValueSet);

uicontrol(figure_hadl,'FontSize', 10,'Style', 'Text', 'Unit','Normalized', 'Position', [0.69 0.48 0.3 0.05],'String' ,'max time (s)')

%calling constructor functions
constantBoxes() %function to set all input boxes of figure
loadImg() %function to load image
menuBar() % function to build menu bar

%% callback functions

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
        [s,t] = CarTrailerModel(m1,m2,u,a1,a2,g,k,c,E,F,T);
        
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

    function AddDampener(obj,~)%shows dampening possibility of model
        
        if obj.Value %seeing if checkbox is checked
            data = imread('img_ctsd.jpg'); %importing new image
            imshow(data, 'Parent',axes1_hadl) %plotting image
            set(panel_4,'Visible','on')%dampening constant input made visible
            E = 1;%enabling dampening in simulation
        else
            loadImg()%loading stock image
            E = 0; %disabling dampening in simulation
            set(panel_4,'Visible','off')%removing dampening constant input
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

    function disable() % disables all buttons whilst operations are underway.
        
        buttons = findobj(figure_hadl, 'Style', 'pushbutton');  %finding all buttons
        set(buttons, 'enable','off') %disabling all buttons
        edits = findobj(figure_hadl, 'Style', 'edit');  %finding all buttons
        set(edits, 'enable','off') %disabling all buttons
        
    end

    function enable()%enables all buttons after opperation is complete
        
        buttons = findobj(figure_hadl, 'Style', 'pushbutton'); % finding all buttons
        set(buttons, 'enable','on') % enabling all buttons
        edits = findobj(figure_hadl, 'Style', 'edit');  %finding all buttons
        set(edits, 'enable','on')
        
    end

    function Info(~,~)%loads info to be shown when menu item is selected
        
        message =  fileread('README.txt');%loads information
        msgbox(message,'Infomation')%shows information
        
    end

    function Open(~,~)%opens Simulink file so user can examine it
        
        errordlg('this needs to be programmed still.')
        filename = uigetfile('.slx');%asking user for file in directory
        %making sure a file was selected
        
        if  filename == 0
            return; %if no file is selected then exiting function
        end
        
        if ~contains(filename, '.slx') %making sure file is the correct type
            errordlg('File must be of type ......')
            return;
        end
        
    end

    function Exit(~,~)%handles gui closing
        
        %ensuring user wants to exit
        selection = questdlg('Are You Sure?', 'Close Request','No','Yes','No');
        switch selection
            case 'Yes'
                delete(gcf)%closing gui
            case'No'
                return;
        end
        
    end


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
        
        %defining model labels
        uicontrol(figure_hadl,'FontSize', 10,'Style', 'Text', 'Unit','Normalized', 'tooltip','This is the rolling resitance and air resitance of the car','Position', [0.01 0.87 0.18 0.05],'String' ,'Ff1,F1(v)')
        uicontrol(figure_hadl,'FontSize', 10,'Style', 'Text', 'Unit','Normalized','tooltip','This is the rolling resitance and air resitance of the trailer', 'Position', [0.5 0.89 0.2 0.05],'String' ,'Ff2,F2(v)')
        uicontrol(figure_hadl,'FontSize', 10,'Style', 'Text', 'Unit','Normalized','tooltip','This is the driving force of the car', 'Position', [0.165 0.6 0.1 0.03],'String' ,'F')
        
        %adding arrows to image
        annotation('arrow', [0.03 0.2], [0.94 0.94])
        annotation('arrow', [0.72 0.87], [0.89 0.89])
        annotation('arrow', [0.16 0.03], [0.61 0.61])
        
    end

    function loadImg()%loads image of system
        
        data = imread('img_cts.jpg');%loading data
        imshow(data, 'Parent',axes1_hadl)%showing data
        
    end

    function menuBar() % function to build menu bar
        
        file_menu_hadl = uimenu(figure_hadl, 'Label', 'File');%creating file menu
        uimenu(file_menu_hadl, 'Label','Open Simulink Model','Accelerator','o', 'Callback', @Open); %first element
        uimenu(file_menu_hadl, 'Label','Exit','Accelerator','x', 'Callback', @Exit); %second element
        uimenu(file_menu_hadl, 'Label','Infomation','Accelerator','i', 'Callback', @Info); %third element
        
    end
end