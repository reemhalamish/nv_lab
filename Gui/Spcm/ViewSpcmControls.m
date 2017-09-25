classdef ViewSpcmControls < ViewVBox & EventListener
    %VIEWSPCMCONTROLS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        btnStartStop
        btnReset
        edtIntegrationTime
    end
    
    methods
        function obj = ViewSpcmControls(parent, controller)
            spcmCount = getObjByName(SpcmCounter.NAME);
            obj@ViewVBox(parent, controller);
            obj@EventListener(spcmCount.name);
            
            hboxFirstRow =  uix.HBox('Parent', obj.component, ...
                'Spacing', 3, 'Padding', 1);
            obj.btnStartStop = uicontrol(obj.PROP_BUTTON_BIG_GREEN{:}, ...
                'Parent', hboxFirstRow, ...
                'String', 'todo: refresh');
            obj.btnReset = uicontrol(obj.PROP_BUTTON{:}, ...
                'Parent', hboxFirstRow, ...
                'String', 'Reset');
            hboxFirstRow.Widths = [-1 -1];
            
            hboxSecondRow =  uix.HBox('Parent', obj.component, ...
                'Spacing', 3, 'Padding', 1);
            uix.Empty('Parent', hboxSecondRow);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', hboxSecondRow, ...
                'String', 'Integration (ms)');
            obj.edtIntegrationTime = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', hboxSecondRow, ...
                'String', 'todo: refresh');
            uix.Empty('Parent', hboxSecondRow);
            hboxSecondRow.Widths = [-1 -1 -1 -1];
            
            obj.refresh;
            
            %%%% Define controls callbacks %%%%
            obj.btnReset.Callback = @obj.btnResetCallback;
            obj.edtIntegrationTime.Callback = @obj.edtIntegrationTimeCallback;
            
            %%%% Define size %%%%
            obj.width = 450;
            obj.height = 60;
            
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
        function btnStartCallback(~,~,~)
            spcmCount = getObjByName(SpcmCounter.NAME);
            spcmCount.run;
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
        % when event happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if isfield(event.extraInfo, event.creator.EVENT_SPCM_COUNTER_UPDATED); return; end
            obj.refresh;
        end
    end
    
end

