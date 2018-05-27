classdef (Abstract) ViewTrackable <  ViewVBox & EventListener
    %VIEWTRACKABLE Generic view for tracker of some parameter
    % An abstract class for GUI components of trackables, which is
    % also a listener to events from the tracker
    
    % Child objects must implement refresh() and draw() functions, for
    % their views as well as for the common views.
    
    properties
        vAxes1  % graphical axes. Usually, displays the same as the axes of Experiment
        vAxes2  % graphical axes. Usually, history of the tracked parameter
        legend1 % legend. for plot in vAxes1
        
        % Manual control panel
        cbxContinuous   % checkbox
        btnStartStop    % button
        btnReset        % button
        btnSave         % button
        tvMessage       % text-view
        
        % To be filled by each specific trackable
        panelInput      % panel
        panelTracked    % panel
    end
    
    properties (Abstract, SetAccess = protected)
        trackableName   % string. The name of the trackable controlled by this GUI
    end
    
    methods
        function obj = ViewTrackable(trackableName, parent, controller)
            padding = 15;
            spacing = 10;
            lineHeight = 20;
            obj@ViewVBox(parent, controller, padding, spacing);
            obj@EventListener(Experiment.NAME);
            
            obj.trackableName = trackableName;
            
            hboxMain = uix.HBox('Parent', obj.component, ...
                'Spacing', 20, 'Padding', 5);
            
            %%%% Left column - parameters and control %%%%
            vboxLeft = uix.VBox('Parent', hboxMain, ...
                'Spacing', 5);
            obj.panelInput = uix.Panel('Parent', vboxLeft, ...
                'Title', 'Input Paramters');
            obj.panelTracked = uix.Panel('Parent', vboxLeft, ...
                'Title', 'Tracked Paramters');
            
            
            % Manual-Control Panel
            panelManual = uix.Panel('Parent', vboxLeft, ...
                'Title', 'Manual Control', ...
                'Padding', 5);
            vboxManual = uix.VBox('Parent', panelManual, ...
                'Spacing', 5);
            obj.btnStartStop = uicontrol(obj.PROP_BUTTON_BIG_GREEN{:}, ...
                'Parent', vboxManual, ...
                'String', 'Error in Refresh');
            obj.btnReset = uicontrol(obj.PROP_BUTTON{:}, ...
                'Parent', vboxManual, ...
                'String', 'Reset', ...
                'Callback', @obj.btnResetCallback);
            
            obj.cbxContinuous = uicontrol(obj.PROP_CHECKBOX{:}, ...
                'Parent', vboxManual, ...
                'String', 'Track Continuously', ... 
                'Callback', @obj.cbxContinuousCallback);
            vboxManual.Heights = [-1 -1 lineHeight];
            
            manualControlHeight = 200;
            vboxLeft.Heights = [-3 -2 manualControlHeight];
            
            
            %%%% Right column - plots and save %%%%
            vboxRight = uix.VBox('Parent', hboxMain, ...
                'Spacing', 3);
            % While creating legend, the figure gets messed up.
            % Workaround, part 1: place them in their own VBox, and edit it
            vboxAxes = uix.VBox('Parent', vboxRight, ...
                'Spacing', 3);
            obj.vAxes1 = axes('Parent', vboxAxes, ...
                'NextPlot', 'replacechildren', ...
                'ActivePositionProperty', 'outerposition');
            % Workaround, part 2: create legend now, and hide it
            % (encompassed in "newLegend" function)
            obj.legend1 = obj.newLegend(obj.vAxes1);
            obj.vAxes2 = axes('Parent', vboxAxes, ...
                'NextPlot', 'replacechildren', ...
                'ActivePositionProperty', 'outerposition');
            axes()      % to avoid accidental plotting over the data in the axes
            vboxAxes.Heights = [-1 0 -1];
            obj.btnSave = uicontrol(obj.PROP_BUTTON{:}, ...
                'Parent', vboxRight, ...
                'String', 'Save', ...
                'Callback', @obj.btnSaveCallback);
            btnSaveHeight = 50;
            vboxRight.Heights = [-1 btnSaveHeight];
            
            hboxMain.Widths = [280 -1];
            
            %%%% Message textview %%%%
            obj.tvMessage = uicontrol(obj.PROP_TEXT_NO_BG{:}, 'Parent', obj.component, 'HorizontalAlignment', 'center');
            
            obj.setHeights([-1 lineHeight]);
                        
            obj.height = 750;
            obj.width = 800;
            
            % Child objects are in charge of refreshing!

        end     % constructor
        
        function btnStartStopChangeMode(obj, btn, isOn)
            % Takes care of switching the Start/Stop Button operation mode
            %   Note that the button needs to be an input argument;
            %   Otherwise the function will consider the handle to the
            %   button as deleted.
            if isOn
                set(btn,'BackgroundColor', 'red', ...
                    'String', 'Stop', ...
                    'Callback', @obj.btnStopCallback);
            else
                set(btn,'BackgroundColor', 'green', ...
                    'String', 'Start', ...
                    'Callback', @obj.btnStartCallback);
            end
        end
        
        function showMessage(obj, message, colorOptional)
            if exist('colorOptional', 'var')
                color = colorOptional;
            else
                color = 'black';
            end
            
            obj.tvMessage.String = message;
            obj.tvMessage.ForegroundColor = color;
            T = TimedDisplay(obj.tvMessage);
            T.blinkAndHideAfterTime;
        end
        
        function showWarning(obj, message)
            orange = [1 0.3 0]; % RGB
            obj.showMessage(message, orange);
            EventStation.anonymousWarning(message);
        end
        
    end
    
    methods (Abstract)
        refresh(obj)
        % Assigns value to UI objects which need them from the Trackable
        % object. To be used at initializtion and when EVENT_DATA_UPDATED
        % is sent from the tracker
        
        update(obj)
        % Plots relevant data from trackable history on axes, when
        % EVENT_DATA_UPDATED is sent from the tracker
    end
       
    methods (Abstract, Access = protected)
        % Callbacks for all of the defined UIControls
        cbxContinuousCallback(obj)
        btnStartStopCallback(obj)
        btnStartCallback(obj)
        btnStopCallback(obj)
        btnResetCallback(obj)
        btnSaveCallback(obj)
    end
    
%     % Copy this to child classes, for overriding
%     %% overridden from EventListener
%     methods
%         % When events happens, this function jumps.
%         % event is the event sent from the EventSender
%         function onEvent(obj, event)
%             
%         end
%     end

    methods (Access = protected)
        function leg = newLegend(obj, gAxes, labels)
            % This function is introduced for the legend workaround
            % It creates legend in given axes with given labels, before any
            % data is given, so that displaying it later will nor reshuffle
            % the axes in view
            
            if ~exist('labels','var')
                labels = 'a';
            end
            
            warning off MATLAB:legend:IgnoringExtraEntries
            leg = legend(gAxes, labels, 'Location', 'northeast');
            obj.legend1.Visible = 'off';
            warning on MATLAB:legend:IgnoringExtraEntries
        end
    end
    
end

