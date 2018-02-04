classdef ViewTrackablePosition < ViewTrackable
    %VIEWTRACKABLEPOSITION View for the trackable position 
    %   
    
    properties (SetAccess = protected)
        trackableName = Tracker.TRACKABLE_POSITION_NAME;
        
        stageAxes       % string. The axes of the stage this trackable uses
        tvStageName     % text-view. Shows the name of the current stage
        tvCurPos        % text-view. Shows the current position of the stage
    end
    
    properties
        edtInitStepSize % 3x1 edit-input. Initial step size
        edtMinStepSize  % 3x1 edit-input. Minimum step size
        edtNumStep      % edit-input. Maximum number of steps before giving up
        edtPixelTime    % edit-input. Time for reading at each point.
        edtLaserPower   % edit-input. Power of green laser
    end
    
    properties (Constant)
        BOTTOM_LABEL1 = 'time [sec]';
        LEFT_LABEL1 = sprintf('%s(position) %s', StringHelper.DELTA, StringHelper.MICRON);
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
            longLabelWidth = 120;
            shortLabelWidth = 80;
            lineHeight = 30;
            heights = [lineHeight*ones(1,6) -1];
            
            hboxInput = uix.HBox('Parent', obj.panelInput, 'Spacing', 5, 'Padding', 5);
            
            vboxLabels = uix.VBox('Parent', hboxInput, 'Spacing', 5, 'Padding', 0);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxLabels, ...
                'String', 'Tracked Stage');
            uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxLabels, ...
                'String', 'Max # of steps');
            uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxLabels, ...
                'String', 'Pixel Time');
            uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxLabels, ...
                'String', 'Initial Step Size');
            uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxLabels, ...
                'String', 'Min. Step Size');
            uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxLabels, ...
                'String', 'Laser Power')
            uix.Empty('Parent', vboxLabels);
            vboxLabels.Heights = heights;
            
            vboxValues = uix.VBox('Parent', hboxInput, 'Spacing', 5, 'Padding', 0);
            obj.tvStageName = uicontrol(obj.PROP_TEXT_BIG{:}, ...
                'Parent', vboxValues);   % todo: when there is more than one scannable stage, this should be a dropdown box
            obj.edtNumStep = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', vboxValues, ...
                'Callback', @obj.edtNumStepCallback);
            obj.edtPixelTime = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', vboxValues, ...
                'Callback', @obj.edtPixelTimeCallback);
            
            hboxInitStepSize = uix.HBox('Parent', vboxValues, 'Spacing', 5, 'Padding', 0);
                obj.edtInitStepSize = gobjects(1, axesLen);
            hboxMinStepSize = uix.HBox('Parent', vboxValues, 'Spacing', 5, 'Padding', 0);
                obj.edtMinStepSize = gobjects(1, axesLen);
            for i = 1:axesLen
                obj.edtInitStepSize(i) = uicontrol(obj.PROP_EDIT{:}, ...
                    'Parent', hboxInitStepSize, ...
                    'Callback', @(h,e)obj.edtInitStepSizeCallback(i));
                obj.edtMinStepSize(i) = uicontrol(obj.PROP_EDIT{:}, ...
                    'Parent', hboxMinStepSize, ...
                    'Callback', @(h,e)obj.edtMinStepSizeCallback(i));
            end
                hboxInitStepSize.Widths = -oneForEachAxis;
                hboxMinStepSize.Widths = -oneForEachAxis;
                
            hboxLaserPower = uix.HBox('Parent', vboxValues, 'Spacing', 5, 'Padding', 0);
                obj.edtLaserPower = uicontrol(obj.PROP_EDIT{:}, ...
                    'Parent', hboxLaserPower, ...
                    'Callback', @obj.edtLaserPowerCallback);
                uicontrol(obj.PROP_TEXT_NO_BG{:}, 'Parent', hboxLaserPower, ...
                    'String', '%');
                hboxLaserPower.Widths = [-1 10];
            uix.Empty('Parent', vboxValues);

            vboxValues.Heights = heights;

            hboxInput.Widths = [longLabelWidth -1];
            
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
            
            obj.refreshUponStageChange;     % technically, not "refresh", but is needed @init.
        end

        function refresh(obj)
            trackablePos = getExpByName(obj.trackableName);
            stage = getObjByName(trackablePos.mStageName);
            laserGate = getObjByName(trackablePos.mLaserName);
            
            % If tracking is currently performed, Start/Stop should be "Stop"
            % and reset should be disabled
            obj.btnStartStopChangeMode(obj.btnStartStop, trackablePos.isCurrentlyTracking)
            obj.btnReset.Enable = BooleanHelper.boolToOnOff(~trackablePos.isCurrentlyTracking);
            
            obj.cbxContinuous.Value = trackablePos.isRunningContinuously;
            obj.edtNumStep.String = trackablePos.nMaxIterations;
            obj.edtPixelTime.String = trackablePos.pixelTime;
            obj.edtLaserPower.String = laserGate.value;
            
            currentPos = stage.Pos(obj.stageAxes);
            axesLen = length(obj.stageAxes);
            for i = 1:axesLen
                obj.tvCurPos(i).String = StringHelper.formatNumber(currentPos(i));
                obj.edtInitStepSize(i).String = trackablePos.initialStepSize(i);
                obj.edtMinStepSize(i).String = trackablePos.minimumStepSize(i);
            end
        end
        
        function refreshUponStageChange(obj)
            % "Under the hood"
            trackablePos = getExpByName(obj.trackableName);
            stage = getObjByName(trackablePos.mStageName);
            obj.stageAxes = stage.availableAxes;
            
            % On display
            obj.tvStageName.String = trackablePos.mStageName;
            obj.refresh;
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
    end
    
    %% Callbacks
    methods
        % From parent class
        function btnStartCallback(obj, ~, ~)
            trackablePos = getExpByName(obj.trackableName);
            try
                trackablePos.startTrack;
            catch err
                trackablePos.stopTrack;     % sets trackablePos.isCurrentlyTracking = false
                rethrow(err);
            end
        end
        function btnStopCallback(obj, ~, ~)
            trackablePos = getExpByName(obj.trackableName);
            trackablePos.stopTrack;
            obj.refresh;
        end
        function btnResetCallback(obj, ~, ~)
            trackablePos = getExpByName(obj.trackableName);
            trackablePos.resetTrack;
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
        function btnSaveCallback(obj, ~, ~)
            obj.showMessage('Unfortunately, saving is not yet implemented. Sorry...');
        end
        
        % Unique to class
        function edtInitStepSizeCallback(obj, index)
            edt = obj.edtInitStepSize(index);   % For brevity
            trackablePos = getExpByName(obj.trackableName);
            
            if ~ValidationHelper.isStringValueInBorders(edt.String, ...
                    trackablePos.minimumStepSize(index), inf)
                edt.String = trackablePos.initialStepSize(index);
                obj.showWarning('Initial step size is smaller than minimum step size! Reveting.');
            end
            [edt.String, newVal] = StringHelper.formatNumber(str2double(edt.String));
            trackablePos.setInitialStepSize(index, newVal);
        end
        function edtMinStepSizeCallback(obj, index)
            edt = obj.edtMinStepSize(index);   % For brevity
            trackablePos = getExpByName(obj.trackableName);
            
            if ~ValidationHelper.isStringValueInBorders(edt.String, ...
                    0, trackablePos.initialStepSize(index))
                edt.String = trackablePos.minimumStepSize(index);
                obj.showWarning('Minimum step size must be between 0 and initial step size! Reveting.');
            end
            [edt.String, newVal] = StringHelper.formatNumber(str2double(edt.String));
            trackablePos.setMinimumStepSize(index, newVal);
        end
        function edtNumStepCallback(obj, ~, ~)
            obj.showMessage('Requested action is not available yet. Reverting.');
            obj.refresh;
        end
        function edtPixelTimeCallback(obj, ~, ~)
            trackablePos = getExpByName(obj.trackableName);
            if ~ValidationHelper.isValuePositive(obj.edtPixelTime.String)
                obj.edtPixelTime.String = StringHelper.formatNumber(trackablePos.pixelTime);
                obj.showWarning('Pixel time has to be a positive number! Reverting.');
            end
            trackablePos.pixelTime = str2double(obj.edtPixelTime.String);
        end
        function edtLaserPowerCallback(obj, ~, ~)
            trackablePos = getExpByName(obj.trackableName);
            laserGate = getObjByName(trackablePos.mLaserName);
            
            decimalDigits = 1;
            val = str2double(obj.edtLaserPower.String);
            [obj.edtLaserPower.String, laserGate.value] = StringHelper.formatNumber(val, decimalDigits);
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happens, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            creator = event.creator;
            if ~isprop(creator, 'expName') || ~strcmp(creator.expName, obj.trackableName)
                return
            end
            
            trackablePos = creator;
            if isfield(event.extraInfo, trackablePos.EVENT_TRACKABLE_EXP_UPDATED)
                history = trackablePos.convertHistoryToStructToSave;
                obj.draw(history);
                obj.refresh;
            elseif isfield(event.extraInfo, trackablePos.EVENT_TRACKABLE_EXP_ENDED)
                obj.refresh;
                obj.showMessage(event.extraInfo.text);
            elseif isfield(event.extraInfo, trackablePos.EVENT_CONTINUOUS_TRACKING_CHANGED)
                obj.refresh;
            elseif isfield(event.extraInfo, trackablePos.obj.EVENT_STAGE_CHANGED)
                
            elseif event.isError
                errorMsg = event.extraInfo.(Event.ERROR_MSG);
                obj.showMessage(errorMsg);
            end
        end
    end
    
end