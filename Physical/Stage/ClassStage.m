classdef (Abstract) ClassStage < EventSender & Savable & EventListener
    % Created by Yoav Romach, The Hebrew University, September, 2016
    properties
        availableAxes           % string. for example - "xy"
        scanParams              % object of type StageScanParams
        isScanable              % logical
        stepSize                % double
        tiltAvailable           % logical
    end
    
    properties(Abstract = true, Constant = true)
        STEP_MINIMUM_SIZE   % double
        STEP_DEFAULT_SIZE   % double
    end
    
    properties(Constant = true)
        SCAN_AXES = 'xyz';
        SCAN_AXES_SIZE = 3; % the length of SCAN_AXES
             
        TILT_MIN_LIM_DEG = -5;
        TILT_MAX_LIM_DEG = 5;
                    
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
                    curStage = stagesJson(i);
                    stageType = curStage.type;
                    switch stageType
                        case 'LPS-65'
                            newStage = ClassPILPS65.GetInstance(); % Setup 1 LPS-65
                        case 'ClassGalvo'
                            newStage = ClassGalvo.GetInstance(); % Galvo mirrors for the Cryo setup - > Very old and might not be comptiable
                        case 'ECC'
                            newStage = ClassECC.GetInstance(); % ECC100 stages used in setup 1 - > Very old and might not be comptiable
                        case 'ClassANC'
                            newStage = ClassANC.GetInstance(); % ANC stages used in setup 3
                        case 'P562'
                            newStage = ClassPI562.GetInstance();
                        case 'STEDCoarse'
                            newStage = ClassSTEDCoarse.GetInstance();
                        case 'Dummy'
                            if isfield(curStage, 'name')
                                stageName = curStage.name;
                            else
                                stageName = 'Dummy stage';
                            end
                            
                            if isfield(curStage, 'is_scanable')
                                stageScanable = curStage.is_scanable;
                            else
                                stageScanable = true;
                            end
                            
                            if isfield(curStage, 'axes')
                                stageAxes = curStage.axes;
                            else
                                stageAxes = ClassStage.SCAN_AXES;  % all of them
                            end
                            
                            if isfield(curStage, 'tilt_available')
                                tiltAvailable = curStage.tilt_available;
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
        
        function axis = GetAxis(axis)
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
            % returns a letter from an axis. supports vectorial axis
            axis = ClassStage.GetAxis(axis);
            string = ClassStage.SCAN_AXES(axis);
        end
        
    end  % methods(static, public)
    
    methods (Access = protected)
        function obj = ClassStage(name, availableAxes, isScanable, tiltAvailable)
            % name - string
            % availableAxes - string. example: "xyz"
            obj@EventSender(name);
            obj@Savable(name);
            obj@EventListener(StageControlEvents.NAME);
            BaseObject.addObject(obj);  % so it can be reached by BaseObject.getByName()
            
            obj.availableAxes = availableAxes;
            obj.isScanable = isScanable;
            obj.stepSize = obj.STEP_DEFAULT_SIZE;
            obj.tiltAvailable = tiltAvailable;
        end
        
        function initScanParams(obj)
            [limNeg, limPos] = obj.ReturnLimits(obj.SCAN_AXES);
            obj.scanParams = StageScanParams;
            obj.scanParams.from = limNeg;
            obj.scanParams.to = limPos;
            obj.scanParams.isFixed = ones(1, ClassStage.SCAN_AXES_SIZE);    % all fixed except what the stage supports (look 3 lines below)
            for axis = obj.availableAxes
                axisIndex = ClassStage.GetAxis(axis);
                obj.scanParams.isFixed(axisIndex) = false;
            end
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
        % Prepares a scan for x axis, to be called before ScanY.
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
        
        [done, forwards] = ScanNextLine(obj)
        % Scans the next line for the 2D scan, to be used after
        % 'PrepareScanXX'.
        % done is set to 1 after the last line has been scanned.
        % No other commands should be used between 'PrepareScanXX' and
        % until 'ScanNextLine' has returned done, or until 'AbortScan'
        % has been called.
        % forwards is set to 1 when the scan is forward and is set to 0
        % when it's backwards
        
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
        % 'enable' - 1 to turn Joystick on, 0 to turn it off.
        
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
        
        function sendPosToScanParams(obj)
            % for all the positions marked as "fixed" in obj.scanParams,
            % update them by the current position
            params = obj.scanParams;
            currentPos = obj.Pos(obj.SCAN_AXES);
            params.fixedPos(find(params.isFixed)) = currentPos(find(params.isFixed)); %#ok<FNDSB>
            if any(params.isFixed)
                obj.sendEventScanParamsChanged();
            end
        end
        
        function moveByScanParams(obj)
            % for all the positions marked as "fixed" in obj.scanParams,
            % move to this position
            params = obj.scanParams;
            obj.sanityChecksRaiseErrorIfNeeded(params);
            axes = obj.SCAN_AXES(find(params.isFixed)); %#ok<FNDSB>
            fixedPos = params.fixedPos(find(params.isFixed)); %#ok<FNDSB>
            obj.move(axes, fixedPos);
        end
        
        function move(obj, axis, pos)
            % calls Move, sends an event. listens to errors to send errorEvent
            try
                obj.Move(axis, pos);
                obj.sendEvent(struct(ClassStage.EVENT_POSITION_CHANGED, true));
            catch matlabError
                obj.sendError(matlabError.message);
            end
        end
        
        function setTiltAngle(obj, thetaXZ, thetaYZ)
            % calls obj.SetTiltAngle to set the tilt angles between Z axis and
            % XY axes, and than sends an event.
            %
            % Angles should be in degrees, valid angles are between -5 and 5
            % degrees.
            try
                if ~obj.tiltAvailable
                    error('this stage doesn''t support tilt!');
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
                    error('this stage doesn''t support tilt!');
                end
                obj.EnableTiltCorrection(enable);
                obj.sendEvent(struct(obj.EVENT_TILT_CHANGED, true));
            catch matlabError
                obj.sendError(matlabError.message);
            end
        end
        
        
        function sanityChecksRaiseErrorIfNeeded(obj, scanParams)
            % sanity checks on the scan parameters
            % the way: copy the scan parameters, call updateByLimit() on
            % the new object and see if something has changed.  
            % 
            % if nothing changed, than all the parameters were in the
            % limits from the first place! 
            [limNeg, limPos] = obj.ReturnLimits(ClassStage.SCAN_AXES);
            wasChange = scanParams.copy.updateByLimit(ClassStage.SCAN_AXES, limNeg, limPos);
            if wasChange
                obj.sendError('sanity checks on the scan parameters failed!');
            end
        end
        
    end
    
    %% setters and getters
    methods
        function set.scanParams(obj, newValue)
            % validates the input, sets the newValue, sends an event
            if isa(newValue, 'StageScanParams')
                [newLimNeg, newLimPos] = obj.ReturnLimits(ClassStage.SCAN_AXES);
                newValue.updateByLimit(ClassStage.SCAN_AXES, newLimNeg, newLimPos);
                obj.scanParams = newValue;
                obj.sendEventScanParamsChanged();
            else
                obj.sendWarning('can only put object of type "StageScanParams"! ignoring');
            end
        end
        
        function set.stepSize(obj, newValue)
            % validates the input, sets the newValue, sends an event
            if ~isnumeric(newValue)
                obj.sendError('step size must be numeric!');
            end
            if newValue < obj.STEP_MINIMUM_SIZE
                obj.sendError(sprintf('step size minimum is %d! (you tried %d)', obj.STEP_MINIMUM_SIZE, newValue));
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
                        error('new value out of limits! limits: [%d, %d]', lowerHardLim, upperSoftLim)
                    end
                elseif zeroForLowerOneForUpper == 1
                    % upper lim should be in [softLowerLim, hardUpperLim]
                    if any(newValue < lowerSoftLim) || any(newValue > upperHardLim)
                        error('new value out of limits! limits: [%d, %d]', lowerSoftLim, upperHardLim)
                    end
                else
                    error('parameter "zeroForLowerOneForUpper" should only be 0 or 1')
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
                        ['you are about to change the %s limit to %d in axis %s.\n', ...
                        'Doing so will move the stage!\n', ....
                        '(current position in %s: %s,\n', ...
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
    
    %% overriding from Savable
    methods(Access = protected) 
        function outStruct = saveStateAsStruct(obj, category) %#ok<*MANU>
            % saves the state as struct. if you want to save stuff, make 
            % (outStruct = struct;) and put stuff inside. if you dont 
            % want to save, make (outStruct = NaN;)
            %
            % category - string. some objects saves themself only with 
            % specific category (image/experimetns/etc)
            if startsWith(category, Savable.CATEGORY_IMAGE)
                % save only the scan parameters
                outStruct = struct('scanParams', obj.scanParams.asStruct);
            elseif startsWith(category, Savable.CATEGORY_EXPERIMENTS)
                % save only the stage position
                position = obj.Pos(ClassStage.SCAN_AXES);
                outStruct = struct('position', position);
            end
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<*INUSD>
            % loads the state from a struct.
            % to support older versoins, always check for a value in the
            % struct before using it. view example in the first line.
            % category - string
            % subCategory - string. could be empty string

            if strcmp(category, Savable.CATEGORY_IMAGE)
                % save from "image" category - the scan parameters are
                % saved here.
                % saves for "image" are divided by sub-categories, only
                % load if you have to!
               if any(strcmp(subCategory, {Savable.SUB_CATEGORY_DEFAULT, Savable.CATEGORY_IMAGE_SUBCAT_STAGE}))
                   % ^ only if sub-category includes the stage
                   obj.scanParams = StageScanParams.fromStruct(savedStruct.scanParams);
                   obj.sendEventScanParamsChanged();
               end
               
            elseif strcmp(category, Savable.CATEGORY_EXPERIMENTS)
                position = savedStruct.position;
                obj.move(ClassStage.SCAN_AXES, position);
            end
        end
        
        function string = returnReadableString(obj, savedStruct)
            % return a readable string to be shown. if this object
            % doesn't need a readable string, make (string = NaN;) or
            % (string = '');
            string = NaN;
        end
    end
    
    %% overridden from EventListener
    methods
        % when event happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if isfield(event.extraInfo, StageControlEvents.HALT);               obj.Halt();             end
            if isfield(event.extraInfo, StageControlEvents.CLOSE_CONNECTION);   obj.CloseConnection();  end
        end
    end
end