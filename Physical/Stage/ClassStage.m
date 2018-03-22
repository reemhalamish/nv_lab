classdef (Abstract) ClassStage < EventSender & Savable & EventListener
    % Created by Yoav Romach, The Hebrew University, September, 2016
    properties
        availableAxes           % string. for example - "xy"
        scanParams              % object of class StageScanParams
        availableProperties = struct;
        stepSize                % double
    end
    
    properties (Abstract, Constant)
        STEP_MINIMUM_SIZE   % double
        STEP_DEFAULT_SIZE   % double
    end
    
    properties (Constant)
        SCAN_AXES = 'xyz';
        SCAN_AXES_SIZE = 3; % the length of SCAN_AXES
             
        TILT_MIN_LIM_DEG = -5;
        TILT_MAX_LIM_DEG = 5;
        
        HAS_FAST_SCAN = 'hasFastScan';
        HAS_SLOW_SCAN = 'hasSlowScan';
        TILTABLE = 'tiltable';
        HAS_CLOSED_LOOP = 'hasClosedLoop';
        HAS_OPEN_LOOP = 'hasOpenLoop';
        HAS_JOYSTICK = 'hasJoystick';
                    
        EVENT_SCAN_PARAMS_CHANGED = 'scanParamsChanged';
        EVENT_LIM_CHANGED = 'limitChanged';
        EVENT_STEP_SIZE_CHANGED = 'stepSizeChanged';
        EVENT_POSITION_CHANGED = 'positionChanged';
        EVENT_TILT_CHANGED = 'tiltChanged';
    end
    
    methods (Static, Access = public) % Get instance constructor
        function stages = getStages()
            % return an instance of cell{all the stages}
            
            persistent stagesCellContainer
            if isempty(stagesCellContainer) || ~isvalid(stagesCellContainer)
                stagesJson = JsonInfoReader.getJson.stages;
                stagesCellContainer = CellContainer;
                
                for i = 1: length(stagesJson)
                    if iscell(stagesJson)
                        curStageStruct = stagesJson{i};
                    else
                        curStageStruct = stagesJson(i);
                    end
                    stageType = curStageStruct.type;
                    switch stageType
                        case 'LPS-65' % Setup 1 LPS-65
                            try
                                newStage = getObjByName(ClassPILPS65.NAME);
                            catch
                                newStage = ClassPILPS65.create(curStageStruct);
                            end
                        case 'ClassGalvo' % Galvo mirrors for the Cryo setup
                            try
                                newStage = getObjByName(ClassGalvo.NAME);
                            catch
                                newStage = ClassGalvo.create(curStageStruct);
                            end
                        case 'ECC'
                            newStage = ClassECC.GetInstance(); % ECC100 stages used in setup 1 - > Very old and might not be comptiable
                        case 'ClassANC'
                            newStage = ClassANC.GetInstance(); % ANC stages used in setup 3
                        case 'PIP-562'
                            try
                                newStage = getObjByName(ClassPIP562.NAME);
                            catch
                                newStage = ClassPIP562.create(curStageStruct);
                            end
                        case 'PIM-686'
                            newStage = ClassPIM686.GetInstance();
                        case 'PIM-501'
                            newStage = ClassPIM501.GetInstance();
                        case 'PIM-686&PIM-501'
                            newStage = ClassPIM686M501.GetInstance();
                        case 'STEDCoarse'
                            newStage = ClassSTEDCoarse.GetInstance();
                        case 'Dummy'
                            if isfield(curStageStruct, 'name')
                                stageName = curStageStruct.name;
                            else
                                stageName = 'Dummy stage';
                            end
                            
                            if isfield(curStageStruct, 'is_scanable')
                                stageScanable = curStageStruct.is_scanable;
                            else
                                stageScanable = true;
                            end
                            
                            if isfield(curStageStruct, 'axes')
                                stageAxes = curStageStruct.axes;
                            else
                                stageAxes = ClassStage.SCAN_AXES;  % all of them
                            end
                            
                            if isfield(curStageStruct, 'tilt_available')
                                tiltAvailable = curStageStruct.tilt_available;
                            else
                                tiltAvailable = true;
                            end
                            
                            newStage = ClassDummyStage(stageName, stageAxes, stageScanable, tiltAvailable);
                        otherwise
                            EventStation.anonymousError('Unknown stage: %s', stageType);
                    end
                    
                    %%%% init the new stage %%%%
                    newStage.initScanParams();
                    stagesCellContainer.cells{end + 1} = newStage;
                end
            end  % if isempty || ~isvalid
            
            stages = stagesCellContainer.cells;

        end  % function getStages()
        
        function axis = getAxis(axis)
            % Converts x,y,z into the corresponding numeric value (1,2,3).
            % If already in numeric value it does nothing.
            tempAxis = zeros(size(axis)); % Needed because axis could be of type string
            for i=1:length(axis)
                index = axis(i);
                if (index < 1 || index > 3)
                    index = strfind(ClassStage.SCAN_AXES, lower(axis(i)));
                    if isempty(index) || (index < 1 || index > 3)
                        EventStation.anonymousError(['Unknown axis: ' axis(i)]);
                    end
                end
                tempAxis(i) = index;
            end
            axis = tempAxis;
        end
        
        function string = GetLetterFromAxis(axis)
            % Returns a letter from an axis. supports vectorial axis
            axis = ClassStage.getAxis(axis);
            string = ClassStage.SCAN_AXES(axis);
        end
        
    end  % methods(static, public)
    
    methods (Access = protected)
        function obj = ClassStage(name, availableAxes)
            % name - string
            % availableAxes - string. example: "xyz"
            obj@EventSender(name);
            obj@Savable(name);
            obj@EventListener(StageControlEvents.NAME);
            addBaseObject(obj);  % so it can be reached by getObjByName()
            
            obj.availableAxes = availableAxes;
            obj.stepSize = obj.STEP_DEFAULT_SIZE;
        end
        
        function initScanParams(obj)
            axis = ClassStage.getAxis(obj.availableAxes);
            [limNeg, limPos] = obj.ReturnLimits(axis);
            obj.scanParams = StageScanParams;
            obj.scanParams.from(axis) = limNeg;
            obj.scanParams.to(axis) = limPos;
            obj.scanParams.isFixed = ones(1, ClassStage.SCAN_AXES_SIZE);    % all fixed except what the stage supports (look 3 lines below)
            obj.scanParams.isFixed(axis) = false;
            obj.scanParams.fixedPos(axis) = obj.Pos(axis);
            obj.scanParams.fastScan = obj.hasFastScan;
        end
        
        % wrapper for the static method getAxis
        function axes = GetAxis(~, axis)
            axes = ClassStage.getAxis(axis);
        end
        
    end
    
    methods(Abstract = true, Access = public)
        ok = PointIsInRange(obj, axis, point)
        % Checks if the given point is within the soft (and hard)
        % limits of the given axis (x,y,z or 1 for x, 2 for y and 3 for z).
        % Vectorial axis is possible.
        
        [negSoftLimit, posSoftLimit] = ReturnLimits(obj, axis)
        % Return the soft limits of the given axis (x,y,z or 1 for x,
        % 2 for y and 3 for z).
        % Vectorial axis is possible.
        
        [negHardLimit, posHardLimit] = ReturnHardLimits(obj, axis)
        % Return the hard limits of the given axis (x,y,z or 1 for x,
        % 2 for y and 3 for z).
        % Vectorial axis is possible.
        
        pos = Pos(obj, axis)
        % Query and return position of axis (x,y,z or 1 for x, 2 for y
        % and 3 for z)
        % Vectorial axis is possible.
        
        vel = Vel(obj, axis)
        % Query and return velocity of axis (x,y,z or 1 for x, 2 for y
        % and 3 for z)
        % Vectorial axis is possible.
        
        binaryButtonState = ReturnJoystickButtonState(obj)
        % Returns the state of the buttons in 3 bit decimal format.
        % 1 for first button, 2 for second and 4 for the 3rd.
        
        [tiltEnabled, thetaXZ, thetaYZ] = GetTiltStatus(obj)
        % Return the status of the tilt control.
        
        
    end
    
    
    methods (Abstract, Access = public)
        % Classes that have multiple stages need to add a 'stage' argument
        % to the end of every function.
        
        SetSoftLimits(obj, axis, softLimit, negOrPos)
        % Set the new soft limits:
        % if negOrPos = 0 -> then softLimit = lower soft limit
        % if negOrPos = 1 -> then softLimit = higher soft limit
        % This is because each time this function is called only one of
        % the limits updates
        
        SetVelocity(obj, axis, vel)
        % Absolute change in velocity (vel) of axis (x,y,z or 1 for x,
        % 2 for y and 3 for z).
        % Vectorial axis is possible.
        
        CloseConnection(obj)
        % Closes the connection to the stage.
        
        Reconnect(obj)
        % Reconnects the controller.
        
        Move(obj, axis, pos)
        % Absolute change in position (pos) of axis (x,y,z or 1 for x,
        % 2 for y and 3 for z).
        % Vectorial axis is possible.
        
        RelativeMove(obj, axis, change)
        % Relative change in position (pos) of axis (x,y,z or 1 for x,
        % 2 for y and 3 for z).
        % Vectorial axis is possible.
        
        Halt(obj)
        % Halts all stage movements.
        
        ScanX(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%%%%% ONE DIMENSIONAL X SCAN %%%%%%%%%%%%%%%%%
        % Does a scan for x axis.
        % x - A vector with the points to scan, points should have
        % equal distance between them.
        % y/z - The starting points for the other axes.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        ScanY(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%%%%% ONE DIMENSIONAL Y SCAN %%%%%%%%%%%%%%%%%
        % Does a scan for y axis.
        % y - A vector with the points to scan, points should have
        % equal distance between them.
        % x/z - The starting points for the other axes.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        ScanZ(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%%%%% ONE DIMENSIONAL Z SCAN %%%%%%%%%%%%%%%%%
        % Does a scan for z axis.
        % z - A vector with the points to scan, points should have
        % equal distance between them.
        % x/y - The starting points for the other axes.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        PrepareScanX(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%%%%% ONE DIMENSIONAL X SCAN %%%%%%%%%%%%%%%%%
        % Prepares a scan for x axis, to be called before ScanX.
        % x - A vector with the points to scan, points should have
        % equal distance between them.
        % y/z - The starting points for the other axes.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        PrepareScanY(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%%%%% ONE DIMENSIONAL Y SCAN %%%%%%%%%%%%%%%%%
        % Prepares a scan for y axis, to be called before ScanY.
        % y - A vector with the points to scan, points should have
        % equal distance between them.
        % x/z - The starting points for the other axes.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        PrepareScanZ(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%%%%% ONE DIMENSIONAL Z SCAN %%%%%%%%%%%%%%%%%
        % Prepares a scan for z axis, to be called before ScanZ.
        % z - A vector with the points to scan, points should have
        % equal distance between them.
        % x/y - The starting points for the other axes.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        PrepareScanXY(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%% TWO DIMENSIONAL XY SCAN MACRO %%%%%%%%%%%%%%
        % Prepare a macro scan for xy axes!
        % Scanning is done by calling 'ScanNextLine'.
        % Aborting via 'AbortScan'.
        % x/y - Vectors with the points to scan, points should have
        % equal distance between them.
        % z - The starting points for the other axis.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        PrepareScanXZ(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%% TWO DIMENSIONAL XZ SCAN MACRO %%%%%%%%%%%%%%
        % Prepare a macro scan for xz axes!
        % Scanning is done by calling 'ScanNextLine'.
        % Aborting via 'AbortScan'.
        % x/z - Vectors with the points to scan, points should have
        % equal distance between them.
        % y - The starting points for the other axis.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        PrepareScanYX(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%% TWO DIMENSIONAL XY SCAN MACRO %%%%%%%%%%%%%%
        % Prepare a macro scan for xy axes!
        % Scanning is done by calling 'ScanNextLine'.
        % Aborting via 'AbortScan'.
        % x/y - Vectors with the points to scan, points should have
        % equal distance between them.
        % z - The starting points for the other axis.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        PrepareScanYZ(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%% TWO DIMENSIONAL YZ SCAN MACRO %%%%%%%%%%%%%%
        % Prepare a macro scan for yz axes!
        % Scanning is done by calling 'ScanNextLine'.
        % Aborting via 'AbortScan'.
        % y/z - Vectors with the points to scan, points should have
        % equal distance between them.
        % x - The starting points for the other axis.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        PrepareScanZX(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%% TWO DIMENSIONAL XZ SCAN MACRO %%%%%%%%%%%%%%
        % Prepare a macro scan for xz axes!
        % Scanning is done by calling 'ScanNextLine'.
        % Aborting via 'AbortScan'.
        % x/z - Vectors with the points to scan, points should have
        % equal distance between them.
        % y - The starting points for the other axis.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        PrepareScanZY(obj, x, y, z, nFlat, nOverRun, tPixel)
        %%%%%%%%%%%%%% TWO DIMENSIONAL YZ SCAN MACRO %%%%%%%%%%%%%%
        % Prepare a macro scan for yz axes!
        % Scanning is done by calling 'ScanNextLine'.
        % Aborting via 'AbortScan'.
        % y/z - Vectors with the points to scan, points should have
        % equal distance between them.
        % x - The starting points for the other axis.
        % tPixel - Scan time for each pixel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        [forwards, done] = ScanNextLine(obj)
        % Scans the next line for the 2D scan, to be used after
        % 'PrepareScanXX'.
        % forwards is set to 1 when the scan is forward and is set to 0
        % when it's backwards
        % DONE IS CURRENTLY NOT IMPLEMENTED ANYWHERE!
        % done is set to 1 after the last line has been scanned.
        % No other commands should be used between 'PrepareScanXX' and
        % until 'ScanNextLine' has returned done, or until 'AbortScan'
        % has been called.

        
        PrepareRescanLine(obj)
        % Prepares the previous line for rescanning.
        % Scanning is done with "ScanNextLine"
        
        AbortScan(obj)
        % Aborts the 2D scan defined by 'PrepareScanXX';
        
        maxScanSize = ReturnMaxScanSize(obj, nDimensions)
        % Returns the maximum number of points allowed for an
        % 'nDimensions' scan.
        
        JoystickControl(obj, enable)
        % Changes the joystick state for all axes to the value of
        % 'enable' - true to turn Joystick on, false to turn it off.
        
        FastScan(obj, enable)
        % Changes the scan between the fast & the slow modes.
        % 'enable' - 1 for fast scan, 0 for slow scan.
        
        ChangeLoopMode(obj, mode)
        % Changes between closed and open loop.
        % Mode should be either 'Open' or 'Closed'.
        
        success = SetTiltAngle(obj, thetaXZ, thetaYZ)
        % Sets the tilt angles between Z axis and XY axes.
        % Angles should be in degrees, valid angles are between -5 and 5
        % degrees.
        
        success = EnableTiltCorrection(obj, enable)
        % Enables the tilt correction according to the angles.
        
    end
    
    
    methods
        function sendEventScanParamsChanged(obj)
            obj.sendEvent(struct(obj.EVENT_SCAN_PARAMS_CHANGED, true));
        end
        function sendEventLimitsChanged(obj)
            obj.sendEvent(struct(obj.EVENT_LIM_CHANGED, true));
        end
        function sendEventPositionChanged(obj)
            obj.sendEvent(struct(obj.EVENT_POSITION_CHANGED, true));
        end
        
        function sendPosToScanParams(obj)
            % New behavior: update "Fixed Position" to be current position,
            % in all available axes.
            params = obj.scanParams;
            axesIndex = obj.getAxis(obj.availableAxes);
            pos = obj.Pos(axesIndex);
            
            %%%% If we're off bounds by a bit, send bound to fixedPos
            [lowerBound, upperBound] = obj.ReturnLimits(axesIndex);
            pos(pos > upperBound) = upperBound(pos > upperBound);
            pos(pos < lowerBound) = lowerBound(pos < lowerBound);
            %%%%
            
            params.fixedPos(axesIndex) = pos;
            obj.sendEventScanParamsChanged;
            
            % % Old behavior: For all the positions marked as "fixed" in
            % % obj.scanParams, update them by the current position
            % params = obj.scanParams;
            % currentPos = obj.Pos(obj.SCAN_AXES);
            % params.fixedPos(find(params.isFixed)) = currentPos(find(params.isFixed)); %#ok<FNDSB>
            % if any(params.isFixed)
            %     obj.sendEventScanParamsChanged();
            % end
        end
        
        function moveByScanParams(obj)
            % For all the positions marked as "fixed" in obj.scanParams,
            % move to this position
            params = obj.scanParams;
            obj.sanityChecksRaiseErrorIfNeeded(params);
            axes = obj.SCAN_AXES(find(params.isFixed)); %#ok<FNDSB>
            fixedPos = params.fixedPos(find(params.isFixed)); %#ok<FNDSB>
            if isempty(axes)
                obj.sendError('At least one axis needs to be fixed for this operation')
            else
                obj.move(axes, fixedPos);
            end
        end
        
        function move(obj, axis, pos)
            % Calls Move, sends an event. Listens to errors to send errorEvent
            try
                obj.Move(axis, pos);
                obj.sendEventPositionChanged;
            catch matlabError
                obj.sendError(matlabError.message);
            end
        end
        
        function relativeMove(obj, axis, change)
            % Calls RelativeMove, sends an event. Listens to errors to send errorEvent.
            % Vectorial axis is possible
            try
                obj.RelativeMove(axis, change);
                obj.sendEventPositionChanged;
            catch matlabError
                rethrow(matlabError)
                % obj.sendError(matlabError.message);
            end
        end
        
        function setTiltAngle(obj, thetaXZ, thetaYZ)
            % Calls obj.SetTiltAngle to set the tilt angles between Z axis and
            % XY axes, and than sends an event.
            %
            % Angles should be in degrees, valid angles are between -5 and 5
            % degrees.
            try
                if ~obj.tiltAvailable
                    error('This stage doesn''t support tilt!');
                end
                
                if ~ValidationHelper.isInBorders(thetaXZ, obj.TILT_MIN_LIM_DEG, obj.TILT_MAX_LIM_DEG)
                    error('"thetaXZ" is not in borders!\n''thetaXZ'': %d, min: %d, max: %d', thetaXZ, obj.TILT_MIN_LIM_DEG, obj.TILT_MAX_LIM_DEG);
                end
                if ~ValidationHelper.isInBorders(thetaYZ, obj.TILT_MIN_LIM_DEG, obj.TILT_MAX_LIM_DEG)
                    error('"thetaYZ" is not in borders!\n''thetaYZ'': %d, min: %d, max: %d', thetaYZ, obj.TILT_MIN_LIM_DEG, obj.TILT_MAX_LIM_DEG);
                end
                
                obj.SetTiltAngle(thetaXZ, thetaYZ);
                obj.sendEvent(struct(ClassStage.EVENT_TILT_CHANGED, true));
            catch matlabError
                obj.sendError(matlabError.message);
            end
        end
        
        function enableTiltCorrection(obj, enable)
            % Enables the tilt correction according to the angles. than
            % sends an event
            try
                if ~obj.tiltAvailable
                    error('This stage doesn''t support tilt!');
                end
                obj.EnableTiltCorrection(enable);
                obj.sendEvent(struct(obj.EVENT_TILT_CHANGED, true));
            catch matlabError
                obj.sendError(matlabError.message);
            end
        end
        
        
        function sanityChecksRaiseErrorIfNeeded(obj, scanParams)
            % Sanity checks on the scan parameters
            % the way: copy the scan parameters, call updateByLimit() on
            % the new object and see if something has changed.  
            % 
            % If nothing changed, then all the parameters were in the
            % limits in the first place! 
            [limNeg, limPos] = obj.ReturnLimits(obj.availableAxes);
            wasChange = scanParams.copy.updateByLimit(obj.availableAxes, limNeg, limPos);
            if wasChange
                obj.sendError('Sanity checks on the scan parameters failed!');
            end
        end
        
    end
    
    %% setters and getters
    methods
        function set.scanParams(obj, newValue)
            % validates the input, sets the newValue, sends an event
            if isa(newValue, 'StageScanParams')
                [newLimNeg, newLimPos] = obj.ReturnLimits(obj.availableAxes);
                newValue.updateByLimit(obj.availableAxes, newLimNeg, newLimPos);
                obj.scanParams = newValue;
                obj.sendEventScanParamsChanged();
            else
                obj.sendWarning('Can only put object of type "StageScanParams"! Ignoring');
            end
        end
        
        function set.stepSize(obj, newValue)
            % validates the input, sets the newValue, sends an event
            if ~isnumeric(newValue)
                obj.sendError('Step size must be numeric!');
            end
            if newValue < obj.STEP_MINIMUM_SIZE
                obj.sendError(sprintf('Step size minimum is %d! (you tried %d)', obj.STEP_MINIMUM_SIZE, newValue));
            end
            
            obj.stepSize = newValue;
            obj.sendEvent(struct(obj.EVENT_STEP_SIZE_CHANGED, true));
        end
        function setLim(obj, newValue, axis, zeroForLowerOneForUpper)
            % validates the input, sets the newValue, sends an event
            %
            % new value - the new lower limit
            % axis - the axis in whitch to control
            % zeroForLowerOneForUpper - 0 will set the lower limit. 1 for upper
            try
                axis = obj.GetAxis(axis);

                %%%% input checks - that I'm in the relevant limits %%%%
                [lowerSoftLim, upperSoftLim] = obj.ReturnLimits(axis);
                [lowerHardLim, upperHardLim] = obj.ReturnHardLimits(axis);
                
                if zeroForLowerOneForUpper == 0
                    % lower lim should be in [hardLowerLim, softUpperLim]
                    if any(newValue < lowerHardLim) || any(newValue > upperSoftLim)
                        error('New value is out of limits! limits: [%d, %d]', lowerHardLim, upperSoftLim)
                    end
                elseif zeroForLowerOneForUpper == 1
                    % upper lim should be in [softLowerLim, hardUpperLim]
                    if any(newValue < lowerSoftLim) || any(newValue > upperHardLim)
                        error('New value out of limits! limits: [%d, %d]', lowerSoftLim, upperHardLim)
                    end
                else
                    error('Parameter "zeroForLowerOneForUpper" should only be 0 or 1')
                end
                
                
                
                %%%% another check - if need to move the stage %%%%
                stagePos = obj.Pos(axis);
                
                if zeroForLowerOneForUpper
                    [newLimNeg, newLimPos] = deal(lowerSoftLim, newValue);
                else
                    [newLimNeg, newLimPos] = deal(newValue, upperSoftLim);
                end
                if ~ValidationHelper.isInBorders(stagePos, newLimNeg, newLimPos)
                    % need to ask the user if to move the stage or revert
                    
                    if zeroForLowerOneForUpper
                        msgLimUpperOrLower = 'upper';
                    else
                        msgLimUpperOrLower = 'lower';
                    end
                    msgAxis = ClassStage.GetLetterFromAxis(axis);
                    msgStagePos = num2str(obj.Pos(ClassStage.SCAN_AXES));
                    msg = sprintf(...
                        ['You are about to change the %s limit to %d in axis %s.\n', ...
                        'Doing so will move the stage!\n', ....
                        '(Current position in %s: %s,\n', ...
                        'new position in axis %s: %d).\n', ...
                        'Are you sure?'], ...
                        msgLimUpperOrLower, ...
                        newValue, ...
                        msgAxis, ...
                        ClassStage.SCAN_AXES, ...
                        num2str(msgStagePos), ...
                        msgAxis, ...
                        newValue);
                        
                    if ~QuestionUserYesNo('confirm limits change', msg)
                        % stop and don't do anything.
                        error('user canceled the operation');
                    else
                        needToMoveStage = true;
                    end
                    
                else % if the new limits WILL NOT change the stage position
                    needToMoveStage = false;
                end
                
                %%%% actual work %%%%
                obj.SetSoftLimits(axis, newValue, zeroForLowerOneForUpper);
                obj.sendEventLimitsChanged();
                
                [newLimNeg, newLimPos] = obj.ReturnLimits(axis);
                scanParamsChanged = obj.scanParams.updateByLimit(axis, newLimNeg, newLimPos);
                if scanParamsChanged
                    obj.sendEventScanParamsChanged();
                end
                
                if needToMoveStage
                    obj.move(axis, newValue);  % this will send an event by itself
                end
                
            catch matlabError
                obj.sendError(matlabError.message);
            end
        end
        
    end
    
    methods % Available properties    
        function properties = getAvailableProperties(obj)
            properties = obj.avilableProperties;
        end

        function bool = isScannable(obj)
            bool = isfield(obj.availableProperties,obj.HAS_SLOW_SCAN) || ...
                isfield(obj.availableProperties,obj.HAS_FAST_SCAN);
        end
        
        function bool = hasFastScan(obj)
            bool = isfield(obj.availableProperties,obj.HAS_FAST_SCAN);
        end
        
        function bool = hasSlowScan(obj)
            bool = isfield(obj.availableProperties,obj.HAS_SLOW_SCAN);
        end
        
        function bool = tiltAvailable(obj)
            bool = isfield(obj.availableProperties,obj.TILTABLE);
        end
        
        function bool = hasOpenLoop(obj)
            bool = isfield(obj.availableProperties,obj.HAS_OPEN_LOOP);
        end
        
        function bool = hasClosedLoop(obj)
            bool = isfield(obj.availableProperties,obj.HAS_CLOSED_LOOP);
        end
        
        function bool = hasJoystick(obj)
            bool = isfield(obj.availableProperties,obj.HAS_JOYSTICK);
        end
        
    end
    
    %% overriden from Savable
    methods(Access = protected) 
        function outStruct = saveStateAsStruct(obj, category, type) %#ok<INUSL>
            % Saves the state as struct. if you want to save stuff, make
            % (outStruct = struct;) and put stuff inside. If you dont
            % want to save, make (outStruct = NaN;)
            %
            % category - string. Some objects saves themself only with
            %                    specific category (image/experimetns/etc)
            % type - string.     Whether the objects saves at the beginning
            %                    of the run (parameter) or at its end (result)
            if ~strcmp(type, Savable.TYPE_PARAMS)
                outStruct = NaN;
                return
            end
            
            % Save only the stage position
            position = obj.Pos(obj.availableAxes);
            outStruct = struct('position', position);
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory) 
            % Loads the state from a struct.
            % To support older versions, always check for a value in the
            % struct before using it. View example in the first line.
            % category - string
            % subCategory - string. could be empty string
            
            switch category
                case Savable.CATEGORY_IMAGE
                    % save from "image" category - the scan parameters are
                    % saved here.
                    % saves for "image" are divided by sub-categories, only
                    % load if you have to!
                    if any(strcmp(subCategory, {Savable.SUB_CATEGORY_DEFAULT, Savable.CATEGORY_IMAGE_SUBCAT_STAGE}))
                        % ^ only if sub-category includes the stage
                        if isfield(savedStruct, 'scanParams')
                            % For backward compatibility: in later versions,
                            % the scan parameters are saved only in the
                            % stage scanner
                            obj.scanParams = StageScanParams.fromStruct(savedStruct.scanParams);
                            obj.sendEventScanParamsChanged();
                        end
                    end
                    
                case Savable.CATEGORY_EXPERIMENTS
                    position = savedStruct.position;
                    obj.move(ClassStage.SCAN_AXES, position);
            end
        end
        
        function string = returnReadableString(obj, savedStruct) %#ok<INUSD>
            % Return a readable string to be shown. if this object
            % doesn't need a readable string, make (string = NaN;) or
            % (string = '');
            scanner = getObjByName(StageScanner.NAME);
            if strcmp(scanner.mStageName, obj.name)
                % The parameters are already recorded by the stage scanner,
                % and we do not need them from here
                string = NaN;
                return
            end
            
            n = length(obj.availableAxes);
            string = sprintf('%s position:', obj.name);
            
            indentation = 5;
            for i = 1:n
                axLetter = obj.availableAxes(i);
                axNum = obj.getAxis(axLetter);
                position = obj.Pos(axNum);
                axisString = sprintf('%s axis: %.3f', axLetter, position);
                string = sprintf('%s\n%s', string, ...
                    StringHelper.indent(axisString, indentation));
            end
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if isfield(event.extraInfo, StageControlEvents.HALT);               obj.Halt();             end
            if isfield(event.extraInfo, StageControlEvents.CLOSE_CONNECTION);   obj.CloseConnection();  end
        end
    end
end