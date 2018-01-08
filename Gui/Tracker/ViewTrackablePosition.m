classdef ViewTrackablePosition < ViewTrackable
    %VIEWTRACKABLEPOSITION View for the trackable position 
    %   
    
    properties (SetAccess = protected)
        trackableName = Tracker.TRACKABLE_POSITION_NAME;
        stageAxes       % The axes of the stage this trackable uses
        
        tvCurPos        % Shows the current position of the stage
    end
    
    properties
        edtStepSize
        edtNumStep
    end
    
    properties (Constant)
        BOTTOM_LABEL1 = 'time [sec]';
        LEFT_LABEL1 = sprintf('%s(position) %s',StringHelper.DELTA,StringHelper.MICRON);
        BOTTOM_LABEL2 = 'time [sec]';
        LEFT_LABEL2 = 'kpcs'
    end
    
    methods
        function obj = ViewTrackablePosition(parent, controller)
            obj@ViewTrackable(Tracker.TRACKABLE_POSITION_NAME, parent, controller)
            
            obj.vAxes1.YLabel.String = obj.LEFT_LABEL1;
            obj.vAxes2.XLabel.String = obj.BOTTOM_LABEL2;
            obj.vAxes2.YLabel.String = obj.LEFT_LABEL2;
            obj.legend1 = obj.newLegend(obj.vAxes1,{'x','y','z'});
            
            trackablePos = getExpByName(obj.trackableName);
            stage = getObjByName(trackablePos.mStageName);
            obj.stageAxes = stage.availableAxes; 
            axesLen = length(obj.stageAxes);
            
            oneForEachAxis = ones(1, axesLen); % might change, depending on the stage
            
            %%%% Fill input parameter panel %%%%
            longLabelWidth = 130;
            shortLabelWidth = 80;
            lineHeight = 30;
            
            vboxInput = uix.VBox('Parent', obj.panelInput, 'Spacing', 5, 'Padding', 5);
            % Number of steps
            hboxNumStep = uix.HBox('Parent', vboxInput, 'Spacing', 0, 'Padding', 0);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', hboxNumStep, 'String', 'Max # of steps');
            obj.edtNumStep = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', hboxNumStep, ...
                'Callback', @obj.edtNumStepCallback);
            hboxNumStep.Widths = [longLabelWidth -1];
            % Step size
            hboxStepSize = uix.HBox('Parent', vboxInput, 'Spacing', 0, 'Padding', 0);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', hboxStepSize, ...
                'String', 'Initial Step Size');
            obj.edtStepSize = gobjects(1, axesLen);
            for i = 1:axesLen
                obj.edtStepSize(i) = uicontrol(obj.PROP_EDIT{:}, ...
                    'Parent', hboxStepSize, ...
                    'Callback', @obj.edtStepSizeCallback);
            end
            hboxStepSize.Widths = [longLabelWidth -oneForEachAxis];

            uix.Empty('Parent', vboxInput);
            vboxInput.Heights = [lineHeight lineHeight -1];
            
            %%%% Fill tracked parameter panel %%%%
            gridTracked = uix.Grid('Parent', obj.panelTracked, 'Spacing', 5, 'Padding', 5);
            obj.tvCurPos = gobjects(1, axesLen);
            for i = 1:axesLen
                uicontrol(obj.PROP_LABEL{:}, 'Parent', gridTracked, 'String', upper(obj.stageAxes(i)));
            end
            obj.tvCurPos = gobjects(1, axesLen);
            for i = 1:axesLen
                obj.tvCurPos(i) = uicontrol(obj.PROP_EDIT{:}, 'Parent', gridTracked, 'Enable', 'off');
            end
            set(gridTracked, 'Widths', [shortLabelWidth -1], 'Heights', -oneForEachAxis );
            
            obj.refresh;
        end

        function refresh(obj)
            trackablePos = getExpByName(obj.trackableName);
            stage = getObjByName(trackablePos.mStageName);
            obj.stageAxes = stage.availableAxes;
            currentPos = stage.Pos(obj.stageAxes);
            
            % If tracking is being performed, Start/Stop should be "Stop"
            % and reset should be disabled
            obj.btnStartStopChangeMode(obj.btnStartStop, trackablePos.isCurrentlyTracking)
            obj.btnReset.Enable = BooleanHelper.boolToOnOff(~trackablePos.isCurrentlyTracking);
            
            obj.edtNumStep.String = trackablePos.NUM_MAX_ITERATIONS; %change this in the future
            axesLen = length(obj.stageAxes);
            for i = 1:axesLen
                obj.edtStepSize(i).String = trackablePos.INITIAL_STEP_VECTOR(i); %change this in the future
                obj.tvCurPos(i).String = currentPos(i);
            end
        end
        
        function draw(obj, history)
            t = cell2mat(history.time);
            pos = cell2mat(history.position);
            
            p_1 = pos(1, :);
            dp = diff([p_1;pos]);
            plot(obj.vAxes1,t,dp); % plots each column (x,y,z) against the time
            drawnow;
            set(obj.legend1,'String', {'x','y','z'}, ... % todo: should use obj.stageAxes
                'Visible', 'on');
            
            kcps = cell2mat(history.value);
            plot(obj.vAxes2,t,kcps);
            
            currentPos = pos(end, :);
            axesLen = length(obj.stageAxes);
            for i = 1:axesLen
                obj.tvCurPos(i).String = num2str(currentPos(i));
            end
        end
        
        % Callbacks
        function btnStartCallback(obj, ~, ~)
            trackablePos = getExpByName(obj.trackableName);
            try
                trackablePos.start;
            catch err
                trackablePos.stop;     % sets trackablePos.isCurrentlyTracking = false
                rethrow(err);
            end
        end
        function btnStopCallback(obj, ~, ~)
            trackablePos = getExpByName(obj.trackableName);
            trackablePos.stop;
            obj.refresh;
        end
        function btnResetCallback(obj, ~, ~)
            trackablePos = getExpByName(obj.trackableName);
            trackablePos.reset;
            obj.refresh;
            cla(obj.vAxes1)
            cla(obj.vAxes2)
            obj.legend1.Visible = 'off';
        end
        function cbxContinuousCallback(obj, ~, ~)
            trackablePos = getExpByName(obj.trackableName);
            trackablePos.isRunningContinuously = obj.cbxContinuous.Value;
        end
        function btnStartStopCallback(obj, ~, ~)
            % If tracking is being performed, Start/Stop should be "Stop"
            % and reset should be disabled, and the opposite should happen
            % otherwise
            trackablePos = getExpByName(obj.trackableName);
            obj.btnStartStopChangeMode(obj.btnStartStop, trackablePos.isCurrentlyTracking);
            obj.btnReset.Enable = BooleanHelper.boolToOnOff(~trackablePos.isCurrentlyTracking);
        end
        function btnSaveCallback(obj, ~, ~) %#ok<INUSD>
            
        end
        function edtStepSizeCallback(obj, ~, ~)
            obj.showMessage('Requested action is not available yet. Reverting.');
            obj.refresh;
        end
        function edtNumStepCallback(obj, ~, ~)
            obj.showMessage('Requested action is not available yet. Reverting.');
            obj.refresh;
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happens, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            creator = event.creator;
            if isprop(creator, 'expName') && strcmp(creator.expName, obj.trackableName)
                trackablePos = creator;
                
                if isfield(event.extraInfo, creator.EVENT_TRACKABLE_EXP_UPDATED)
                    history = trackablePos.convertHistoryToStructToSave;
                    obj.draw(history);
                    obj.refresh;
                elseif isfield(event.extraInfo, creator.EVENT_TRACKABLE_EXP_ENDED)
                    obj.refresh;
                    obj.showMessage(event.extraInfo.text);
                elseif event.isError
                    errorMsg = event.extraInfo.(Event.ERROR_MSG);
                    obj.showMessage(errorMsg);
                end

            end
        end
    end
    
end