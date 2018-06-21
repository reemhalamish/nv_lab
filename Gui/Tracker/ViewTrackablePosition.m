classdef ViewTrackablePosition < ViewTrackable
    %VIEWTRACKABLEPOSITION View for the trackable position 
    %   
    
    properties (SetAccess = protected)
        stageAxes       % string. The axes of the stage this trackable uses
        laserPartNames	% cell. names of laser parts that can set their value (power)
        uiStageName     % text-view. Shows the name of the current stage
        tvCurPos        % text-view. Shows the current position of the stage
        lblCurPos       % label. Name of axes (Used for visibility)
    end
    
    properties
        % n is the length of stageAxes
        edtInitStepSize % nx1 edit-input. Initial step size
        edtMinStepSize  % nx1 edit-input. Minimum step size
        edtNumStep      % edit-input. Maximum number of steps before giving up
        edtPixelTime    % edit-input. Time for reading at each point.
        edtLaserPower   % edit-input. Power of green laser
    end
    
    properties (Constant)
        BOTTOM_LABEL1 = 'time [sec]';
        LEFT_LABEL1 = sprintf('%s(position) [%s]', StringHelper.DELTA, StringHelper.MICRON);
        BOTTOM_LABEL2 = 'time [sec]';
        LEFT_LABEL2 = 'kpcs'
    end
    
    methods
        function obj = ViewTrackablePosition(parent, controller)
            obj@ViewTrackable(TrackablePosition.EXP_NAME, parent, controller)
            
            % Set parameters for graphic axes
            obj.vAxes1.YLabel.String = obj.LEFT_LABEL1;
            obj.vAxes2.XLabel.String = obj.BOTTOM_LABEL2;
            obj.vAxes2.YLabel.String = obj.LEFT_LABEL2;
            obj.legend1 = obj.newLegend(obj.vAxes1,{'x','y','z'});
            
            %%%% Get objects we will work with: %%%%
            % first and foremost: the trackable experiment
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            % list of all available stages
            stages = ClassStage.getScannableStages;
            stagesNames = cellfun(@(x) x.name, stages, 'UniformOutput', false);
            % gneral stage parameters
            axesLen = ClassStage.SCAN_AXES_SIZE;
            % green laser
            laser = getObjByName(trackablePos.mLaserName);
            obj.laserPartNames = laser.getContollableParts;
            laserPartsLen = length(obj.laserPartNames);
            laserParts = cell(1, laserPartsLen);
            for i = 1:laserPartsLen
                laserParts{i} = getObjByName(obj.laserPartNames{i});
                obj.startListeningTo(laserParts{i}.name);
            end
            
            %%%% Fill input parameter panel %%%%
            longLabelWidth = 120;
            shortLabelWidth = 80;
            lineHeight = 30;
            heights = [lineHeight*ones(1,5), lineHeight*ones(1,laserPartsLen), -1];
            
            hboxInput = uix.HBox('Parent', obj.panelInput, 'Spacing', 5, 'Padding', 5);
            
            % Label column
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
            for i = 1:laserPartsLen
                label = uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxLabels);
                switch class(laserParts{i})
                    case {'LaserSourceOnefiveKatana05', 'LaserSourceDummy'}
                        label.String = 'Laser Source';
                    case {'AomDoubleNiDaqControlled', 'AomDummy', 'AomNiDaqControlled'}
                        label.String = 'Laser AOM';
                end
            end
            uix.Empty('Parent', vboxLabels);
            vboxLabels.Heights = heights;
            
            % Values column
            vboxValues = uix.VBox('Parent', hboxInput, 'Spacing', 5, 'Padding', 0);
            obj.uiStageName = obj.uiTvOrPopup(vboxValues, stagesNames);     % might be a text-view or a dropdown-menu
                obj.uiStageName.Callback = @obj.uiStageNameCallback;
            obj.edtNumStep = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', vboxValues, ...
                'Callback', @obj.edtNumStepCallback);
            hboxPixelTime = uix.HBox('Parent', vboxValues, ...
                    'Spacing', 5, 'Padding', 0);
                obj.edtPixelTime = uicontrol(obj.PROP_EDIT{:}, ...
                    'Parent', hboxPixelTime, ...
                    'Callback', @obj.edtPixelTimeCallback);
                uicontrol(obj.PROP_TEXT_UNITS{:}, ...
                    'Parent', hboxPixelTime, ...
                    'String', 's');
                hboxPixelTime.Widths = [-1 15];
            
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
                
            hboxLaserPower = gobjects(1, laserPartsLen);
            obj.edtLaserPower = gobjects(1, laserPartsLen);
            for i = 1:laserPartsLen
                hboxLaserPower(i) = uix.HBox('Parent', vboxValues, ...
                    'Spacing', 5, 'Padding', 0, ...
                    'UserData', obj.laserPartNames{i});
                obj.edtLaserPower(i) = uicontrol(obj.PROP_EDIT{:}, ...
                    'Parent', hboxLaserPower(i), ...
                    'Callback', @obj.edtLaserPowerCallback);
                uicontrol(obj.PROP_TEXT_UNITS{:}, 'Parent', hboxLaserPower(i), ...
                    'String', laserParts{i}.units);
                hboxLaserPower(i).Widths = [-1 15];
            end
            uix.Empty('Parent', vboxValues);
            vboxValues.Heights = heights;

            hboxInput.Widths = [longLabelWidth -1];
            
            %%%% Fill tracked parameter panel %%%%
            gridTracked = uix.Grid('Parent', obj.panelTracked, 'Spacing', 5, 'Padding', 5);
            obj.lblCurPos = gobjects(1, axesLen);
            obj.tvCurPos = gobjects(1, axesLen);
            % First column
            for i = 1:axesLen
                obj.lblCurPos(i) = uicontrol(obj.PROP_LABEL{:}, 'Parent', gridTracked, 'String', upper(ClassStage.SCAN_AXES(i)));
            end
            % Second column
            for i = 1:axesLen
                obj.tvCurPos(i) = uicontrol(obj.PROP_EDIT{:}, 'Parent', gridTracked, 'Enable', 'off');
            end
            set(gridTracked, 'Widths', [shortLabelWidth -1]);
            
            % Get information from all devices
            obj.totalRefresh;
        end
    end
    
    methods % Called to update GUI
        % We have several levels of refreshing\updating:
        % 1. When the tracker finishes one step. Here we only want to check
        %    that how are scanned parameters are doing, and redraw on the
        %    axes. Dubbed: update.
        % 2. When user changes other tracking parameters. We then make sure
        %    that all other tracking parameters are is in place.
        %    Dubbed: refresh.
        % 3. When stage is changed: this requires checking almost
        %    everything. This is very costly, but will rarely happen.
        %    Dubbed: totalRefresh.
        
        function update(obj) % (#1)
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            history = trackablePos.convertHistoryToStructToSave;
            t = cell2mat(history.time);
            pos = cell2mat(history.position);
            
            p_1 = pos(1, :);
            dp = diff([p_1;pos]);
            plot(obj.vAxes1, t, dp); % plots each column (x,y,z) against the time
            drawnow;
            axesLetters = num2cell(obj.stageAxes);     % Odd, but this usefully turns 'xyz' into {'x', 'y', 'z'}
            set(obj.legend1, 'String', axesLetters, 'Visible', 'on');
            
            kcps = cell2mat(history.value);
            plot(obj.vAxes2,t,kcps);
            
            currentPos = pos(end, :);
            axesLen = length(obj.stageAxes);
            for i = 1:axesLen
                axisIndex = ClassStage.getAxis(obj.stageAxes(i));
                obj.tvCurPos(axisIndex).String = num2str(currentPos(i));
            end
        end
        
        function refresh(obj) % (#2)
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            stage = getObjByName(trackablePos.mStageName);
            
            % If tracking is currently performed, Start/Stop should be "Stop"
            % and reset should be disabled
            obj.btnStartStopChangeMode(obj.btnStartStop, trackablePos.isCurrentlyTracking)
            obj.btnReset.Enable = BooleanHelper.boolToOnOff(~trackablePos.isCurrentlyTracking);
            
            obj.cbxContinuous.Value = trackablePos.isRunningContinuously;
            obj.edtNumStep.String = trackablePos.nMaxIterations;
            obj.edtPixelTime.String = trackablePos.pixelTime;
            
            currentPos = stage.Pos(obj.stageAxes);
            axesLen = length(obj.stageAxes);
            for i = 1:axesLen
                obj.tvCurPos(i).String = StringHelper.formatNumber(currentPos(i));
                obj.edtInitStepSize(i).String = trackablePos.initialStepSize(i);
                obj.edtMinStepSize(i).String = trackablePos.minimumStepSize(i);
            end
            
            laserPartsLen = length(obj.laserPartNames);
            for i = 1:laserPartsLen
                part = getObjByName(obj.laserPartNames{i});
                val = StringHelper.formatNumber(part.value);
                obj.edtLaserPower(i).String = val;
            end
        end
        
        function totalRefresh(obj) % (#3)
            %%% "Under the hood" %%%
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            stage = getObjByName(trackablePos.mStageName);
            obj.stageAxes = stage.availableAxes;
            
            %%% On display %%%
            % Update stage name
            obj.uiStageName.String = trackablePos.mStageName;
            % Set all as visible ("init")
            axesIndex = ClassStage.getAxis(obj.stageAxes);
            obj.setAxisVisible(axesIndex, 'on')
            % Hide irrelevent ones
            unavailableAxes = setdiff(ClassStage.SCAN_AXES, obj.stageAxes);
            axesIndex = ClassStage.getAxis(unavailableAxes);
            obj.setAxisVisible(axesIndex, 'off')
            
            obj.refresh;
        end
        
        function setAxisVisible(obj, index, value)
            % Helps with setting visibility of elements related to stage
            objects = [obj.edtInitStepSize(index), obj.edtMinStepSize(index), ...
                obj.lblCurPos(index), obj.tvCurPos(index) ];
            set(objects, 'Visible', value);
        end
        
    end
    
    %% Callbacks
    methods (Access = protected)
        % From parent class
        function btnStartCallback(obj, ~, ~)
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            try
                trackablePos.startTrack;
            catch err
                trackablePos.stopTrack;     % sets trackablePos.isCurrentlyTracking = false
                rethrow(err);
            end
        end
        function btnStopCallback(obj, ~, ~)
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            trackablePos.stopTrack;
            obj.refresh;
        end
        function btnResetCallback(obj, ~, ~)
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            trackablePos.resetTrack;
            obj.refresh;
            cla(obj.vAxes1)
            cla(obj.vAxes2)
            obj.legend1.Visible = 'off';
        end
        function cbxContinuousCallback(obj, ~, ~)
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            trackablePos.isRunningContinuously = obj.cbxContinuous.Value;
        end
        function btnStartStopCallback(obj, ~, ~)
            % If tracking is being performed, Start/Stop should be "Stop"
            % and reset should be disabled, and the opposite should happen
            % otherwise
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            obj.btnStartStopChangeMode(obj.btnStartStop, trackablePos.isCurrentlyTracking);
            obj.btnReset.Enable = BooleanHelper.boolToOnOff(~trackablePos.isCurrentlyTracking);
        end
        function btnSaveCallback(obj, ~, ~)
            obj.showMessage('Unfortunately, saving is not yet implemented. Sorry...');
        end
        
        % Unique to class
        function uiStageNameCallback(obj)
            newStageName = obj.uiStageName;
            trackablePos = getObjByName(TrackablePosition.EXP_NAME);
            trackablePos.mStageName = newStageName;
        end
        function edtInitStepSizeCallback(obj, index)
            edt = obj.edtInitStepSize(index);   % For brevity
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            
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
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            
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
            trackablePos = getExpByName(TrackablePosition.EXP_NAME);
            if ~ValidationHelper.isValuePositive(obj.edtPixelTime.String)
                obj.edtPixelTime.String = StringHelper.formatNumber(trackablePos.pixelTime);
                obj.showWarning('Pixel time has to be a positive number! Reverting.');
            end
            trackablePos.pixelTime = str2double(obj.edtPixelTime.String);
        end
        function edtLaserPowerCallback(obj, edtHandle, ~)
            val = str2double(edtHandle.String);
            decimalDigits = 1;
            [string, numeric] = StringHelper.formatNumber(val, decimalDigits);
            
            laserPart = obj.getLaerPart(edtHandle);
            try
                laserPart.value = numeric;
            catch err
                % Laser did not accept the value. Reverting.
                numeric = laserPart.value;
                string = StringHelper.formatNumber(numeric, decimalDigits);
                EventStation.anonymousWarning(err.message);
            end
            edtHandle.String = string;
        end
    end
    
    methods (Static, Access = protected)
        % Helper function for laser parts
        function laserPart = getLaerPart(handle)
            partName = handle.Parent.UserData;
            laserPart = getObjByName(partName);
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happens, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            creator = event.creator;
            % Maybe it is one of the laser parts:
                if isfield(event.extraInfo, 'value')
                    obj.refresh;    % check values of all devices (level 2 refresh)
                end
            % Besides that, we only want to listen to trackablePos
            if ~isprop(creator, 'EXP_NAME') || ~strcmp(creator.EXP_NAME, TrackablePosition.EXP_NAME)
                
                return
            end
            
            trackablePos = creator;
            if isfield(event.extraInfo, trackablePos.EVENT_TRACKABLE_EXP_UPDATED)
                obj.update;
            elseif isfield(event.extraInfo, trackablePos.EVENT_TRACKABLE_EXP_ENDED)
                obj.refresh;
                obj.showMessage(event.extraInfo.text);
            elseif isfield(event.extraInfo, trackablePos.EVENT_CONTINUOUS_TRACKING_CHANGED)
                obj.refresh;
            elseif isfield(event.extraInfo, trackablePos.obj.EVENT_STAGE_CHANGED)
                obj.totalRefresh;
            elseif event.isError
                errorMsg = event.extraInfo.(Event.ERROR_MSG);
                obj.showMessage(errorMsg);
            end
        end
    end
    
end