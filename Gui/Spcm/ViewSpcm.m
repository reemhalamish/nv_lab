classdef ViewSpcm < ViewVBox & EventListener
    %VIEWSPCM view for the SPCM counter
    % This view receives data from the SPCM counter, and displays it
    % according to the requirement of the user (especially, determinines
    % value for wrap (maximum number of data points presented). It can also
    % turn the the SPCMC on and off.
    
    properties
        vAxes           % axes view, to use for the plotting
        
        btnStartStop
        btnReset
        edtIntegrationTime
        
        wrap            % positive integer, how many records in plot
        cbxUsingWrap
        edtWrap
    end
    
    properties (Constant)
        BOTTOM_LABEL = 'time [sec]'; % Text for horiz. axis
        LEFT_LABEL = 'kcps';     % Text for vert. axis
        
        DEFAULT_WRAP_VALUE = 50;    % Value of wrap set in initiation
        DEFAULT_USING_WRAP = true;  % boolean, does this window uses wrap
    end
    
    methods
        function obj = ViewSpcm(parent, controller, heightOpt, widthOpt)
            padding = 5;
            obj@ViewVBox(parent, controller, padding);
            obj@EventListener(Experiment.NAME);
            
            obj.wrap = obj.DEFAULT_WRAP_VALUE;
            
            %%%% Plot Area %%%%
            obj.vAxes = axes('Parent', obj.component, 'ActivePositionProperty', 'outerposition');
            xlabel(obj.vAxes,obj.BOTTOM_LABEL);
            ylabel(obj.vAxes,obj.LEFT_LABEL);
            axes()
            
            %%%% Buttons / Controls %%%%
            hboxButtons = uix.HBox('Parent', obj.component, ...
                'Spacing', 3);
            
            % SPCM Controls Panel
            panelControls = uix.Panel('Parent', hboxButtons, ...
                'Title', 'SPCM Controls');
            hboxControls = uix.HBox('Parent', panelControls, ...
                'Spacing', 3);
            
            obj.btnStartStop = uicontrol(obj.PROP_BUTTON_BIG_GREEN{:}, ...
                'Parent', hboxControls, ...
                'String', 'Error in Refresh');
            obj.btnReset = uicontrol(obj.PROP_BUTTON{:}, ...
                'Parent', hboxControls, ...
                'String', 'Reset', ...
                'Callback', @obj.btnResetCallback);
            
            % Integration time column %
            defaultTime = SpcmCounter.INTEGRATION_TIME_DEFAULT_MILLISEC;
            vboxIntegrationTime =  uix.VBox('Parent', hboxControls, ...
                'Spacing', 1, 'Padding', 1);
            uicontrol(obj.PROP_LABEL{:}, ...
                'Parent', vboxIntegrationTime, ...
                'String', 'Integration (ms)');
            obj.edtIntegrationTime = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', vboxIntegrationTime, ...
                'String', num2str(defaultTime), ...
                'Callback', @obj.edtIntegrationTimeCallback);
            vboxIntegrationTime.Heights = [-1 -1];
            
            % Wrap Panel %
            panelWrap = uix.Panel('Parent', hboxButtons, ...
                'Title', 'Wrap');
            hboxWrapMain = uix.HBox('Parent', panelWrap, ...
                'Spacing', 1, 'Padding', 1);
            obj.cbxUsingWrap = uicontrol(obj.PROP_CHECKBOX{:}, ...
                'Parent', hboxWrapMain, ...
                'Value', obj.DEFAULT_USING_WRAP, ...
                'Callback', @obj.cbxUsingWrapCallback);
            vboxWrapNumber = uix.VBox('Parent', hboxWrapMain);
                uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxWrapNumber, ...
                    'String', '# of Pts');
                obj.edtWrap = uicontrol(obj.PROP_EDIT{:}, ...
                    'Parent', vboxWrapNumber, ...
                    'String', obj.DEFAULT_WRAP_VALUE, ...
                    'Callback', @obj.edtWrapCallback);
                vboxWrapNumber.Heights = [-1 -1];
            hboxWrapMain.Widths = [15 -1];
            
            hboxButtons.Widths = [-3 -1.5];

            obj.refresh;
            
            %%%% Define size %%%%
            if ~exist('heightOpt', 'var') ||  ~exist('widthOpt', 'var')
                obj.height = 500;
                obj.width = 850;
            else
                obj.height = heightOpt;
                obj.width = widthOpt;
            end

            controlsHeight = 80;
            obj.setHeights([-1, controlsHeight]);
        end

        
        
        function tf = isUsingWrap(obj)
            tf = obj.cbxUsingWrap.Value;
        end
        
        function refresh(obj)
            if Experiment.current(SpcmCounter.COUNTER_NAME)
                spcmCount = getObjByName(Experiment.NAME);
                obj.edtIntegrationTime.String = spcmCount.integrationTimeMillisec;
                
                if spcmCount.isOn
                    set(obj.btnStartStop, 'BackgroundColor', 'red', ...
                        'String', 'Stop', ...
                        'Callback', @obj.btnStopCallback);
                    return
                end
            end
            
            % If we got here, it means the counter is not running (either
            % available but off, or unavailable)
            set(obj.btnStartStop, 'BackgroundColor', 'green', ...
                'String', 'Start', ...
                'Callback', @obj.btnStartCallback);
        end
        
        %%%% Callbacks %%%%
        function cbxUsingWrapCallback(obj, ~, ~)
            obj.recolor(obj.edtWrap, ~obj.isUsingWrap)
            % obj.update;           todo: replot with relevant data
        end
        function edtWrapCallback(obj, ~, ~)
            if ~ValidationHelper.isValuePositiveInteger(obj.edtWrap.String)
                EventStation.anonymousWarning('Wrap needs to be a positive integer! Reverting.')
                obj.edtWrap.String = obj.wrap;
            end
            obj.wrap = str2double(obj.edtWrap.String);
            % obj.update;           todo: replot with relevant data
        end
        function btnStartCallback(obj, ~, ~)
            spcmCount = obj.getCounter;
            spcmCount.run;
        end
        function btnStopCallback(obj, ~, ~)
            spcmCount = obj.getCounter;
            spcmCount.stop;
        end
        function btnResetCallback(obj, ~ ,~)
            spcmCount = obj.getCounter;
            spcmCount.reset;
        end
        function edtIntegrationTimeCallback(obj, ~, ~) 
            spcmCount = obj.getCounter;
            integrationTime = str2double(obj.edtIntegrationTime.String);
            if ValidationHelper.isValuePositiveInteger(integrationTime)
                spcmCount.integrationTimeMillisec = integrationTime;
            else
                EventStation.anonymousWarning('Integration time needs to be a positive integer. Reverting.')
                obj.edtIntegrationTime.String = spcmCount.integrationTimeMillisec;
            end
        end
        
    end
    
    methods (Static)
        function spcmCounter = getCounter
            if Experiment.current(SpcmCounter.COUNTER_NAME)
                spcmCounter = getObjByName(Experiment.NAME);
            else
                spcmCounter = SpcmCounter;
            end
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happens, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            % We're listening to all experiments, but only care if the
            % experiment is an SPCM counter.
            if ~Experiment.current(SpcmCounter.COUNTER_NAME)
                return
            end
            
            spcmCounter = event.creator;
            if isfield(event.extraInfo, spcmCounter.EVENT_SPCM_COUNTER_UPDATED)   % event = update
                % todo: this should be a method, say obj.update(spcm),
                % which can be called also when changing wrap mode
                if obj.isUsingWrap
                    [time,kcps,std] = spcmCounter.getRecords(obj.wrap);
                else
                    [time,kcps,std] = spcmCounter.getRecords;
                end
                dimNum = 1;
                AxesHelper.fillAxes(obj.vAxes, kcps, dimNum, time, nan, obj.BOTTOM_LABEL, obj.LEFT_LABEL,std);   %Still requires std implementation
                
                obj.vAxes.Children.HitTest = 'off'; % So as not to be interacted by "marker" cursor
                
                set(obj.vAxes, 'XLim', [-inf, inf]);	% Creates smooth "sweep" of data
                drawnow;                                % consider using animatedline
            else
                obj.refresh;
            end
            if isfield(event.extraInfo, spcmCounter.EVENT_SPCM_COUNTER_RESET)    % event = reset
                line = obj.vAxes.Children;
                delete(line);
            end
        end
    end
    
end
