classdef ViewStagePanelTrack < GuiComponent & EventListener
    %VIEWSTAGEPANELTRACK
    
    properties (Constant)
        TRACKABLE_POSITION_NAME = TrackablePosition.EXP_NAME;
    end
    
    properties
        btnTrack        % button. Starts tracker GUI
        cbxContinuous    % checkbox
        
        mStageName      % string. Name of stage being tracked
    end
        
    methods
        function obj = ViewStagePanelTrack(parent, controller, stage, laser) %#ok<INUSD>
            obj@GuiComponent(parent, controller);
            obj@EventListener(TrackablePosition.EXP_NAME)
            
            obj.mStageName = stage.name;

            panelTracking = uix.Panel('Parent', parent.component, 'Title', 'Tracking', 'Padding', 5);
            hboxMain = uix.HBox('Parent', panelTracking, 'Spacing', 5, 'Padding', 0);
            obj.component = hboxMain;
            
            obj.btnTrack = uicontrol(obj.PROP_BUTTON_BIG_BLUE{:}, ...
                'Parent', hboxMain, ...
                'String', 'Track', ...
                'Callback', @obj.btnTrackCallback);
            vboxContinnuous = uix.VBox('Parent', hboxMain);
                uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxContinnuous, ...
                    'String', 'Continuous?');
                obj.cbxContinuous = uicontrol(obj.PROP_CHECKBOX{:}, ...
                    'Parent', vboxContinnuous, ...
                    'Value', false, ... % By default, don't track continuously
                    'Callback', @obj.cbxContinuousCallback);
            hboxMain.Widths = [-3 -2];
            
            obj.height = 80;
            obj.width = 90;
        end
        
        function refresh(obj)
            trackablePos = getExpByName(obj.TRACKABLE_POSITION_NAME);
            obj.cbxContinuous.Value = trackablePos.isRunningContinuously;
        end
        
        %%%% Callbcaks %%%%
        function btnTrackCallback(obj,~,~)
            % We need to first make sure we have a working experiment, and
            % that it is running the right stage and laser
            try
                trackablePos = getExpByName(obj.TRACKABLE_POSITION_NAME);
                trackablePos.mStageName = obj.mStageName;
            catch
                trackablePos = TrackablePosition(obj.mStageName);
            end
            
            trackablePos.resetTrack;
            trackablePos.startTrack;
        end
        
        function cbxContinuousCallback(obj,~,~)
            trackablePos = getExpByName(obj.TRACKABLE_POSITION_NAME);
            trackablePos.isRunningContinuously = obj.cbxContinuous.Value;
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if (isfield(event.extraInfo, Tracker.EVENT_CONTINUOUS_TRACKING_CHANGED) ...
                    && strcmp(event.creator.EXP_NAME, obj.TRACKABLE_POSITION_NAME)) ...
                    || event.isError
                
                obj.refresh();
            end
        end
    end    
    
end



