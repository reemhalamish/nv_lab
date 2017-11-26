classdef ViewSpcm < ViewVBox & EventListener
    %VIEWSPCM view for the SPCM counter
    %   
    
    properties
        vAxes           % axes view, to use for the plotting
        
        btnStartStop
        btnReset
        edtIntegrationTime
        
        wrap            % positive integer, how many records in plot
        cbxUsingWrap
        edtWrap
    end
    
    properties(Constant = true)
        BOTTOM_LABEL = 'time [sec]'; % Text for horiz. axis
        LEFT_LABEL = 'kcps';     % Text for vert. axis
        
        DEFAULT_WRAP_VALUE = 50;    % Value of wrap set in initiation
        DEFAULT_USING_WRAP = true;  % boolean, does this window uses wrap
    end
    
    methods
        function obj = ViewSpcm(parent, controller, heightOpt, widthOpt)
            padding = 5;
            obj@ViewVBox(parent, controller, padding);
            spcmCount = getObjByName(SpcmCounter.NAME);
            obj@EventListener(spcmCount.name);
            
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
            vboxIntegrationTime =  uix.VBox('Parent', hboxControls, ...
                'Spacing', 1, 'Padding', 1);
            uicontrol(obj.PROP_LABEL{:}, ...
                'Parent', vboxIntegrationTime, ...
                'String', 'Integration (ms)');
            obj.edtIntegrationTime = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', vboxIntegrationTime, ...
                'String', 'Error in Refresh', ...
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
            if ~exist('heightOpt','var') ||  ~exist('widthOpt','var')
                obj.height = 500;
                obj.width = 850;
            else
                obj.height = heightOpt;
                obj.width = widthOpt;
            end

            controlsHeight = 80;
            obj.setHeights([-1, controlsHeight]);
        end

        
        
        function bool = isUsingWrap(obj)
            bool = obj.cbxUsingWrap.Value;
        end
        
        function refresh(obj)
            spcmCount = getObjByName(SpcmCounter.NAME);
            if spcmCount.isOn
                set(obj.btnStartStop,'BackgroundColor', 'red', ...
                    'String', 'Stop', ...
                    'Callback', @obj.btnStopCallback);
            else
                set(obj.btnStartStop,'BackgroundColor', 'green', ...
                    'String', 'Start', ...
                    'Callback', @obj.btnStartCallback);
            end
            obj.edtIntegrationTime.String = spcmCount.integrationTimeMillisec;
        end
        

        %%%% Callbacks %%%%
        function cbxUsingWrapCallback(obj,~,~)
            obj.recolor(obj.edtWrap,~obj.isUsingWrap)
            % obj.update;           todo: replot with relevant data
        end
        function edtWrapCallback(obj,~,~)
            if ~ValidationHelper.isValuePositiveInteger(obj.edtWrap.String)
                EventStation.anonymousWarning('Wrap needs to be a positive integer! Reverting.')
                obj.edtWrap.String = obj.wrap;
            end
            obj.wrap = str2double(obj.edtWrap.String);
            % obj.update;           todo: replot with relevant data
        end
        function btnStartCallback(~,~,~)
            spcmCount = getObjByName(SpcmCounter.NAME);
            try
                spcmCount.run;
            catch err
                spcmCount.stop;     % sets spcmCount = false
                rethrow(err);
            end
        end
        function btnStopCallback(~,~,~)
            spcmCount = getObjByName(SpcmCounter.NAME);
            spcmCount.stop;
        end
        function btnResetCallback(~,~,~)
            spcmCount = getObjByName(SpcmCounter.NAME);
            spcmCount.reset;
        end
        function edtIntegrationTimeCallback(obj,~,~) 
            spcmCount = getObjByName(SpcmCounter.NAME);
            integrationTime = str2double(obj.edtIntegrationTime.String);
            if ValidationHelper.isValuePositiveInteger(integrationTime)
                spcmCount.integrationTimeMillisec = integrationTime;
            else
                EventStation.anonymousWarning('Integration time needs to be a positive integer. Reverting.')
                obj.edtIntegrationTime.String = spcmCount.integrationTimeMillisec;
            end
        end
        
    end
    
    %% overridden from EventListener
    methods
        % when event happens, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            spcmCount = event.creator;
            if isfield(event.extraInfo, spcmCount.EVENT_SPCM_COUNTER_UPDATED)   % event = update
                % todo: this should be a method, say obj.update(spcm),
                % which can be called also when changing wrap mode
                if obj.isUsingWrap
                    [time,kcps,std] = spcmCount.getRecords(obj.wrap);
                else
                    [time,kcps,std] = spcmCount.getRecords;
                end
                dimNum = 1;
                errorbar(obj.vAxes, time, kcps, std);   % needs to be inside $fillAxes
                AxesHelper.fillAxes(obj.vAxes, kcps, dimNum, time, nan, obj.BOTTOM_LABEL, obj.LEFT_LABEL,std);   %Still requires std implementation

                
                set(obj.vAxes,'XLim',[-inf, inf]);  % Creates smooth "sweep" of data
                drawnow;                            % consider using animatedline
            else
                obj.refresh;
            end
            if isfield(event.extraInfo, spcmCount.EVENT_SPCM_COUNTER_RESET)    % event = reset
                line = obj.vAxes.Children;
                delete(line);
            end
        end
    end
    
end



