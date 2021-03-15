% WM216 - Assignment Section 1: Data Acquisition
% Group 9
% written and tested in Matlab R2018b

% file purpose - a solution with data acquisition and GUI to control and
% collect data from an NI Elivs board, modelling a basic audio mixer.


% group 9 signals:
% output 1 voltage range 0.1-0.7
% output 2 voltage range 1-3
% output frequency range 3-6khz

function section1
    % variable definitions
    global peakData
    frequencyLow = 3000;  % min frequency in Hz
    frequencyHigh = 6000;  % max frequency in Hz
    input1VLow = 100; % input 1 min voltage in mV
    input1VHigh = 700; % input 1 min voltage in mV
    input2VLow = 1000; % input 1 min voltage in mV
    input2VHigh = 3000; % input 1 min voltage in mVv
    
    
    % create figure with no deafault menubar, normalised units and resize
    f = figure('name','WM216 Data Acquisition', ...
        'Position',[300 300 1000 600], 'MenuBar','none',...
        'Units', 'Normalized', 'Resize', 'off', ...
        'CloseRequestFcn',@exitCallback); 
    
    % GUI Title
    guiTitle = uicontrol('Style','text','Units','normalized',...
        'Position',[.01 .9 .8 .1],'String', ...
        'WM216 Data Acquisition - Group 9','FontWeight','bold',...
        'HorizontalAlignment', 'left', 'FontSize', 14);  
    
    % create GUI Tabs
    tabGroup = uitabgroup(f,'Position',[.01 .08 .98 .87]);
    configTab = uitab(tabGroup,'Title','Configuration');
    acquisitionTab = uitab(tabGroup,'Title','Data Acquisition');
    resultsTab = uitab(tabGroup,'Title','Results');
    
    % create uibutton to show help page
    helpBtn = uicontrol('Style','pushbutton','Units', 'normalized', ...
        'Position', [.67 .02 .15 .05],'String','Help', ...
        'callback',@help);
    
    % create uibutton to exit program
    exitBtn = uicontrol('Style','pushbutton','Units', 'normalized', ...
        'Position', [.84 .02 .15 .05],'String','Exit', ...
        'callback',@exitCallback);
    
    %% 1. Create configuration tab GUI
    
    % create input controls title
    inputsSubtitle = uicontrol(configTab, 'Style','text',...
        'Position',[12 440 250 20],'String', ...
        'Input Signal Configuration','FontWeight','bold',...
        'HorizontalAlignment', 'left', 'FontSize', 12);  
    
    % create slider for Frequency and voltage inputs
    frequencySlider = uicontrol(configTab,'Style','slider','Min',...
        frequencyLow,'Max',frequencyHigh,'Value',frequencyLow,...
        'Position',[20 380 200 30],'callback',@sliderUpdate,'Enable',...
        'on','TooltipString', 'Frequency of input signals');
    % slider value field to show current slider value
    frequencySliderVal = uicontrol(configTab,'Style','edit','String',...
        string(frequencyLow),'Position',[240 380 50 30],'Enable','on',...
        'callback',@sliderUpdate, 'TooltipString', 'Frequency of input signals');
    frequencySlider.UserData.sibling = frequencySliderVal;  % set siblings
    frequencySliderVal.UserData.sibling = frequencySlider;
    
    frequencyLabel = uicontrol(configTab,'Style','text','Position', ...
        [12 410 150 20],'String','Input Frequency (Hz)','FontWeight',...
        'bold');
    
    v1Slider = uicontrol(configTab,'Style','slider','Min',input1VLow,...
        'Max',input1VHigh,'Value',input1VLow,'Position',[20 320 200 30],...
        'callback',@sliderUpdate,'Enable','on', ...
        'TooltipString', 'Input 1 Amplitude (mV)');
    % slider value field to show current slider value
    v1SliderVal = uicontrol(configTab,'Style','edit','String',...
        string(input1VLow),'Position',[240 320 50 30],'Enable','on',...
        'callback',@sliderUpdate, 'TooltipString', 'Input 1 Amplitude (mV)');
    
     v1Slider.UserData.sibling = v1SliderVal;  % set siblings
    v1SliderVal.UserData.sibling = v1Slider;
    
    v1Label = uicontrol(configTab,'Style','text','Position', ...
        [12 350 150 20],'String','Input 1 Amplitude (mV)',...
        'FontWeight','bold');
    
    v2Slider = uicontrol(configTab,'Style','slider','Min',input2VLow,...
        'Max',input2VHigh,'Value',input2VLow,'Position',[20 260 200 30],...
        'callback',@sliderUpdate,'Enable','on', ...
        'TooltipString', 'Input 2 Amplitude (mV)');
    % slider value field to show current slider value
    v2SliderVal = uicontrol(configTab,'Style','edit','String',...
        string(input2VLow),'Position',[240 260 50 30],'Enable','on',...
        'callback',@sliderUpdate, 'TooltipString', 'Input 2 Amplitude (mV)');
    
    v2Slider.UserData.sibling = v2SliderVal;  % set siblings
    v2SliderVal.UserData.sibling = v2Slider;
    
    v2Label = uicontrol(configTab,'Style','text','Position', ...
        [12 290 150 20],'String','Input 2 Amplitude (mV)',...
        'FontWeight','bold');
    
    % sampling duration edit field
    lengthField = uicontrol(configTab,'Style','edit','String','1',...
        'Position',[20 200 200 30],'Enable','on','callback',@IntVerify,...
        'TooltipString', 'Length of Acquisition (S)');
    
    lengthLabel = uicontrol(configTab,'Style','text','Position', ...
        [12 230 150 20],'String','Acquisition Length (s)',...
        'FontWeight','bold');
    
    % slider callback
    function sliderUpdate (src,~)
        % if slider is src, update the value box
        if isequal(src.Style, 'slider') 
            %This keeps slider value as a whole number
            src.Value = round(src.Value); 
            %Sets SliderVal to the sliders value
            src.UserData.sibling.String = src.Value;
        % if source is value box, update slider
        elseif isequal(src.Style, 'edit') 
            slider = src.UserData.sibling;  % sibling slider for edit field
            % check input is a number
            if ~isempty(str2double(src.String))
                % convert string to number
                newVal = str2double(src.String);
                % check if number is greater than slider max
                if newVal > slider.Max
                    % set label and slider to max
                    src.String = slider.Max;
                    slider.Value = round(slider.Max);
                    % check if number is less than slider min
                elseif newVal < slider.Min
                    % set label and slider to min
                    src.String = slider.Min;
                    src.UserData.sibling.Value = round(slider.Min);
                % if number is within slider range, update slider
                else
                    src.String = round(newVal);
                    slider.Value = round(newVal);
                end
            end
        end
    end

    % create uifields and labels for user to select output/input channels
    inputChannelLabel = uicontrol(configTab,'Style','text','Position', ...
        [442 410 150 20],'String','Input Channel (0-31)','FontWeight',...
        'bold');
    inputChannel = uicontrol(configTab,'Style','edit','String','0',...
        'Position',[450 380 200 30],'callback',@IntVerify, 'TooltipString',...
        'Input channel number for input signal.');
    output1ChannelLabel = uicontrol(configTab,'Style','text','Position',...
        [442 350 150 20],'String','Output 1 Channel (0-31)',...
        'FontWeight','bold');
    output1Channel = uicontrol(configTab,'Style','edit','String','0',...
        'Position',[450 320 200 30],'callback',@IntVerify, 'TooltipString',...
        'Output channel number for output 1 signal.');
    
    output2ChannelLabel = uicontrol(configTab,'Style','text','Position',...
        [442 290 150 20],'String','Output 2 Channel (0-31)',...
        'FontWeight','bold');
    output2Channel = uicontrol(configTab,'Style','edit','String','1',...
        'Position',[450 260 200 30],'callback',@IntVerify, 'TooltipString',...
        'Output channel number for output 2 signal.');
    
    
    %% Create Data acquisition tab GUI
    
    % input 1 axis
    a1 = axes(acquisitionTab, 'Position',[.05 .65 .42 .3]);
    a1.Title.String = "Input 1 Signal";
    a1.XLabel.String = "Time (s)";
    a1.YLabel.String = "Amplitude";
    grid on;  % turn on grid
    hold on;
    
    %input 2 axis
    a2 = axes(acquisitionTab, 'Position',[.55 .65 .42 .3]);
    a2.Title.String = "Input 2 Signal";
    a2.XLabel.String = "Time (s)";
    a2.YLabel.String = "Amplitude";
    grid on;  % turn on grid
    hold on;
    
    %output axis
    a3 = axes(acquisitionTab, 'Position',[.05 .2 .42 .3]);
    a3.Title.String = "Output Signal";
    a3.XLabel.String = "Time (s)";
    a3.YLabel.String = "Amplitude";
    grid on;  % turn on grid
    hold on;
    
    % FFT axis
    a4 = axes(acquisitionTab, 'Position',[.55 .2 .42 .3]);
    a4.Title.String = "Continuous FFT";
    a4.XLabel.String = "Frequency (Hz)";
    a4.YLabel.String = "Relative Amplitude";
    grid on;  % turn on grid
    hold on;
    
    % create uibutton to start data capture
    runBtn = uicontrol(acquisitionTab,'Style','pushbutton','Units', ...
        'normalized','Position', [.4 .02 .2 .1],'String',...
        'Run Data Acquisition','callback',@runCallback,...
        'TooltipString', 'Press to begin data acquisition.');
    
    %% Create Results tab GUI
    
    % FFT axis
    a5 = axes(resultsTab, 'Position',[.05 .2 .55 .7]);
    a5.Title.String = "Data Acquisition FFT";
    a5.XLabel.String = "Frequency (Hz)";
    a5.YLabel.String = "Relative Amplitude";
    grid on;  % turn on grid
    hold on;
   

    % create UITable for FFT frequencies
    frequencyTable = uitable(resultsTab,'Units', 'normalized', ...
        'Position',[.65 .2 .3 .7],'ColumnName',{'Frequency Component',...
        'Relative Amplitude'},'ColumnWidth', {130 130}, 'FontSize', 10);
    
    %% Help figure
    function help(~, ~)
        helpFig = figure('name','Data Acquisition - Help', ...
            'numbertitle','off', 'Position',[1300 300 300 600],...
            'MenuBar','none','Units','Normalized','Resize','on'); 
        % Advice Title
        adviceTitle = uicontrol('Style','text','Units','normalized',...
            'Position',[0 .75 1 .2],'String', ...
            'Help','FontWeight','bold','FontSize',12); 
        %Advice String to display
        adviceString = ['- To use this tool, first go to the configuration tab and enter the desired frequency, voltages, and sample time for the acquisition.',newline, '- Next, select the IO channels corresponding to those used on your NI Elvis board.',newline,'- Go to Data Acquisition tab and select the "run data acquisition" button to run. As results are collected, the graphs will update in real time.',newline,'- Results are shown on the Results tab, showing an FFT including main frequency components detected.',newline,'- For individual field advice, hover and see the ToolsTips.'];
        % Advice Text box
        adviceTextBox = uicontrol('Style','text','Units','normalized',...
            'Position',[.1 .15 .8 .7],'String', adviceString,'FontSize',...
            12,'HorizontalAlignment','left'); 
        % create uibutton to close help
        exitBtn = uicontrol('Style','pushbutton','Units', 'normalized', ...
            'Position',[.1 .03 .8 .1],'String','Close Help',...
            'callback','close');
    end

    
    %% 2. Data Acquisition Initialisation
    function runCallback(~, ~)
        inChannel = inputChannel.String;
        out1Channel = output1Channel.String;
        out2Channel = output2Channel.String;
        % ensure output channels are unique
        if ~isequal(out1Channel, out2Channel)
            % NIElvis channel for opamp input
            opampInputChannel = strcat('ai', inChannel); 
            % NIElvis channel for signal 1 and 2 output
            signal1OutputChannel = strcat('ao', out1Channel); 
            signal2OutputChannel = strcat('ao', out2Channel);

            % get user inputted values from config tab
            freq = frequencySlider.Value;  % Input 1 and 2 frequency in Hz
            v1 = v1Slider.Value/1000; % Input 1 Voltage/peak ampltiude in V
            v2 = v2Slider.Value/1000; % Input 2 Voltage/peak ampltiude in V
            sampleLength = str2num(lengthField.String);  % acquition length in s
            
            % NI Elvis communication configuration
            try  
                dq = daq('ni'); % creates an NI data acquisition session
                dq.Rate = 1000; % set the sampling rate (scans/second)
                % set total duration of the acquisition based on user input
                dq.DurationInSeconds =  sampleLength; 

                % create session input/output channels
                input1 = addinput(dq,'Dev1', opampInputChannel, 'Voltage');
                % sine output 1 and 2
                output1=addoutput(dq,"cDAQ1Mod2", signal1OutputChannel,"Voltage"); 
                output =addoutput(dq,"cDAQ1Mod2", signal2OutputChannel,"Voltage");

                % create sine signals using user inputted freq and peak amplitudes
                outputSignal1 = v1*sin(linspace(0,2*freq*pi,sampleLength)');
                outputSignal2 = v2*sin(linspace(0,2*freq*pi,sampleLength)');
                outputSignal = [outputSignal1 outputSignal2];  % format waveforms
                write(dq, outputSignal)  % set output channels to produce waveforms 
                
                 % input (opamp output) channel configuration
                input1.TerminalConfig = 'SingleEnded';
                input1.Range = [-5 5]; % set V range of analogue input channel
                input1.Name = 'AudioMixerOutput'; % Label the analogue channel
                % create session listener
                output = @(src, event) continuous_data(event.TimeStamps,...
                    event.Data, src.Rate);
                hl = addlistener(s, 'DataAvailable', output);
            
            % catch statement to show user a message if DAQ comm doesn't work
            catch
                warndlg("Error communicating with NI Elvis, please check your connections.")
                return
            end


            %% 3. Data acquisition loop
            % initialise data acquisition
            startBackground(s); % Start the acquisition in background operation

            if dq.IsDone  % once acquisition has finished for specified length
                tabGroup.SelectedTab = resultsTab; % move current tab to result
                stop(dq);
                dq.IsContinuous = false;
                delete(hl);
                RunFFT(a5, true)  % run final fft function to plot and show peaks
                % call final result function for fft
            end
        else
            warndlg("NI Elvis output channels must be unique")
        end
    end

    %% 4. Continuous data function 
    function continuous_data(time, data, rate)
        persistent reading
        persistent timeaxis
        global Time
        global Data
        reading = [reading;data];
        timeaxis = [timeaxis;time];
        
        RunFFT(a4, false);  % plot fft on axis 4
        
        % create sine waves to represent opamp inputs
        freq = frequencySlider.Value;  % Input 1 and 2 frequency in Hz
        s1 = (v1Slider.Value/1000)*sin(2*pi*freq*time);
        s2 = (v2Slider.Value/1000)*sin(2*pi*freq*time);
        
        % update plots
        plot(a1, time, s1); % plot input 1 signal
        plot(a2, time, s2); % plot input 2 signal
        plot(a3, time, data); % plot opamp output data
        
        % save data to global variabls
        Time = timeaxis;
        Data = AudioReading;
    end

    %% 5. Function to perform and plot an FFT
    function RunFFT(axisToPlot, peakTable)
        % using data given, an FFT is run and plotted with limits
        
        tData = Time;  % time vector (from global variables)
        sData = Data;  % amplitude vector (from global variables)

        n = length(tData);  % number of sample points
        dt = tData(2,1)- tData(1,1);  % time delta between samples
        fs = 1/dt;  % sample frequency
        fN = fs / 2.0;  % nyquist frequency for XLim
        freq = zeros(n,1);  % frequency range
        for i = 1:1:n  % populate frequency 
            freq(i,1) = fs*(double(i-1)/double(n)) - fN;
        end
        dft = fft(sData);  % run FFT
        dfts = fftshift(dft);  % shift to centre of f
        dfta = abs(dfts);  % convert to absolute
        relAmp = dfta/max(dfta);  % normalise so relative peak amp is 1
        % split data in half, take positive side (fft is symmetric)
        relAmp = fliplr(abs(relAmp(1:length(relAmp)/2+1)));
        freq = fliplr(abs(freq(1:length(freq)/2+1)));

        plot(axisToPlot, freq,relAmp);  % plot fft
        % if Nyquist freq > 100, set max to 100 so is 
        % easier to read on graph
        if fN > 100  
            fN = 100;
        end
        % set x and y limits for fft plot
        axisToPlot.XLim =[0 fN];
        axisToPlot.YLim=[0 1];
        
        % is a peak frequency table wanted? FOr the final tab, populated
        % frequencyTable.
        if isequal(peakTable, true)
            % find peaks using number of peaks requested
            [sortedAmp, Inds] = sort(relAmp(:),'descend');
            peakInds = Inds(1:10);  % shows first 10 peak amplitudes
            peakFreqs = freq(peakInds);
            peakRelAmps = relAmp(peakInds);
            plot(peakFreqs, peakRelAmps, 'r*');  % plot markers for these points
            % vector of peak frequencies and associated relative amplitudes
            peakData = [peakFreqs, peakRelAmps];
            frequencyTable.Data = peakData;  % shows peak values in table
        end
    end


    %% exit callback. Called by CloseRequestFcn
    function exitCallback(~,~)
        % warning prompt to user to confirm they wish to exit the GUI
        selection = questdlg('Exit?','Warning','Yes','No', 'Yes');
        switch selection
            case 'Yes'
                delete(gcf)  % close figure
            case 'No'
                return
        end 
    end 

    %% Helper functions
    % create callback to check data entered is a numeric integer
    function IntVerify(src,~)
        if isempty(str2double(src.String))  % check if value is number
            set(src,'string','1');  % set string back to default
            warndlg('Input must be an integer');
        end
        src.String = nearest(str2double(src.String));  % round to int
        % bound checks to prevent too greater or small entries
        if str2double(src.String) > 31
            src.String = 31;
        elseif str2double(src.String) < 0
            src.String = 0;
        end
    end
end