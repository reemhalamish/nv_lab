classdef TrackablePosition < Trackable % & StageScanner
    %TRACKABLEPOSITION Makes sure that the experiment is still focused on the desired NV center 
    % The class uses a simple algorithm to counter mechanical drift
    % of the stage

    properties (SetAccess = private)
        stepNum = 0;	% int. Steps since beginning of tracking
        currAxis = 1;   % int. Numerical value of currently scanned axis (1 for X, etc.)

        mSignal
        mScanParams     % Object of class StageScanParams, to store current running scan
        stepSize        % 3x1 double. Holds the current size of position step
        
        % Tracking options
        initialStepSize
        minimumStepSize
    end
    
    properties % have setters
        mStageName
        mLaserName
        
        thresholdFraction
        pixelTime
        nMaxIterations
    end
    
    properties (Constant)
        EVENT_STAGE_CHANGED = 'stageChanged'
        
        % Default properties
        THRESHOLD_FRACTION = 0.01;  % Change is significant if dx/x > threshold fraction
        NUM_MAX_ITERATIONS = 120;   % After that many steps, convergence is improbable
        PIXEL_TIME = 1 ;  % in seconds
        
        % vector constants, for [X Y Z]
        INITIAL_STEP_VECTOR = [0.1 0.1 0.2];    %[0.1 0.1 0.05];
        MINIMUM_STEP_VECTOR = [0.02 0.02 0.02]; %[0.01 0.01 0.01];
        STEP_RATIO_VECTOR = 0.5*ones(1, 3);
        ZERO_VECTOR = [0 0 0];
        
        HISTORY_FIELDS = {'position', 'step', 'time', 'value'}
        
        DEFAULT_CONTINUOUS_TRACKING = false;
    end
    
    methods
        function obj = TrackablePosition(stageName)
            expName = Tracker.TRACKABLE_POSITION_NAME;
            obj@Trackable(expName);
            obj.mStageName = stageName;
            obj.mLaserName = LaserGate.GREEN_LASER_NAME;
            
            obj.mScanParams = StageScanParams;
            
            % Set default tracking properties
            obj.initialStepSize = obj.INITIAL_STEP_VECTOR;
            obj.minimumStepSize = obj.MINIMUM_STEP_VECTOR;
            obj.thresholdFraction = obj.THRESHOLD_FRACTION;
            obj.pixelTime = obj.PIXEL_TIME;
            obj.nMaxIterations = obj.NUM_MAX_ITERATIONS;
        end

        function startTrack(obj)
            %%%% Initialize %%%%
            obj.resetAlgorithm;
            obj.isCurrentlyTracking = true;
            stage = getObjByName(obj.mStageName);
            spcm = getObjByName(Spcm.NAME);
            spcm.setSPCMEnable(true);
            try
                laser = getObjByName(obj.mLaserName);
                laser.isOn = true;
            catch err
                disp(err.message)
            end    % If it fails, it means that laser is already on
            
            %%%% Get initial position and signal value, for history %%%%
            % Set parameters for scan
            axes = stage.getAxis(stage.availableAxes);
            sp = obj.mScanParams;
            sp.fixedPos = stage.Pos(axes);
            sp.isFixed = true(size(sp.isFixed));    % all axes are fixed on initalization
            sp.pixelTime = obj.pixelTime;
            scanner = StageScanner.init;
            if ~ischar(scanner.mStageName) || ~strcmp(scanner.mStageName, obj.mStageName)
                scanner.switchTo(obj.mStageName)
            end
            
            obj.mSignal = scanner.scanPoint(stage, spcm, sp);
            obj.recordCurrentState;     % record starting point (time == 0)

            % Execution of at least one iteration is acheived by using
            % {while(true) {statements} if(condition) {break}}
            while true
                obj.HovavAlgorithm;
                obj.recordCurrentState;
                if ~obj.isRunningContinuously; break; end
                obj.sendEventTrackableExpEnded;
            end
            
            obj.isCurrentlyTracking = false;
            obj.sendEventTrackableExpEnded;     % We want the GUI to catch that the tracker is not tracking anymore
        end
                
        function stopTrack(obj)
            obj.stopFlag = true;
            obj.isCurrentlyTracking = false;
            obj.sendEventTrackableExpEnded;
        end
        
        function resetTrack(obj)
            obj.resetAlgorithm;
            obj.timer = [];
            obj.clearHistory;
        end
        
        function params = getAllTrackalbeParameter(obj) %#ok<MANU>
        % Returns a cell of values/paramters from the trackable experiment
        params = NaN;
        end
        
        function str = textOutput(obj)
            if all(obj.stepSize <= obj.MINIMUM_STEP_VECTOR)
                str = sprintf('Local maximum was found in %u steps', obj.stepNum);
            elseif obj.stopFlag
                str = 'Operation terminated by user';
            elseif obj.isDivergent
                str = 'Maximum number of iterations reached without convergence';
            else
                str = 'This shouldn''t have happenned...';
            end
        end
    end
    
    %% setters
    methods
        function set.mStageName(obj, newStageName)
            if ~strcmp(obj.mStageName, newStageName)    % MATLAB doc says this check is done internally, but we don't count on it
                if obj.isCurrentlyTracking
                    obj.sendWarning('Can''t switch stage while tracking. Try again later.')
                else
                    obj.mStageName = newStageName;
                    obj.sendEvent(struct(obj.EVENT_STAGE_CHANGED, true));
                end
            end
        end
        
        function setMinimumStepSize(obj, index, newSize)
            % Allows for vector input
            if length(newSize) ~= length(index)
                error('Inputs are incompatible. Cannot Complete action.')
            elseif  any (index > length(obj.minimumStepSize)) || any(newSize <= 0)
                error('Cannot set this step size!')
            elseif any(newSize > obj.initialStepSize(index))
                error('Minimum step size can''t be larger than the initial step size, or tracking will LITERALLY take forever.')
            elseif any(newSize <= 0)
                error('There is no point in setting negative step size.')
            end
            obj.minimumStepSize(index) = newSize;
        end
        
        function setInitialStepSize(obj, index, newSize)
            % Allows for vector input
            if length(newSize) ~= length(index)
                error('Inputs are incompatible. Cannot Complete action.')
            elseif  any (index > length(obj.minimumStepSize)) || any(newSize <= 0)
                error('Cannot set this step size!')
            elseif any(newSize < obj.minimumStepSize(index))
                error('Initial step size can''t be smaller than the minimum step size, or tracking will LITERALLY take forever.')
            end
            obj.initialStepSize(index) = newSize;
        end
        
        function set.thresholdFraction(obj, newFraction)
            if ~isnumeric(newFraction) || newFraction <= 0 || newFraction >= 1
                error('Fraction must be a numeric value between 0 and 1');
            end
            obj.thresholdFraction = newFraction;
        end
        
        function set.pixelTime(obj, newTime)
            if ~(newTime > 0)       % False if zero or less, and also if not a number
                error('Pixel time must be a positive number');
            end
            obj.pixelTime = newTime;
        end
        
        function set.nMaxIterations(obj, newNum)
            if isnumeric(newNum)
                num = uint32(newNum);
            else
                num = uint32(str2double(newNum));
            end
            
            if num == 0
                error('We don''t allow for %s iterations', newNum);
            elseif num ~= newNum
                warning('Maximum number of iterations was rounded to nearest integer')
            end
                obj.nMaxIterations = num;     
        end
        
    end
        
    methods (Access = private)
        function initialize(obj)
            obj.reset;   
        end
        
        function tf = isDivergent(obj)
            % If we arrive at the maximum number of iterations, we assume
            % the tracking sequence will not converge, and we stop it
            tf = (obj.stepNum >= obj.NUM_MAX_ITERATIONS);
        end
        
        function recordCurrentState(obj)
            record = struct;
            record.position = obj.mScanParams.fixedPos;
            record.step = obj.stepSize;
            record.value = obj.mSignal;
            record.time = obj.myToc;  % personalized toc function
            
            obj.mHistory{end+1} = record;
            obj.sendEventTrackableUpdated;
        end
        
        function resetAlgorithm(obj)
            obj.stopFlag = false;
            obj.stepNum = 0;
            obj.currAxis = 1;
            
            obj.mSignal = [];
            obj.mScanParams = StageScanParams;
            obj.stepSize = obj.initialStepSize;
        end
    end
    
    methods (Static)
        function tf = isDifferenceAboveThreshhold(x0, x1)
            tf = (x0-x1) > TrackablePosition.THRESHOLD_FRACTION;
        end
    end

    %% Scanning algoithms.
    % For now, only one, should include more in the future
    methods
        function HovavAlgorithm(obj)
            % Moves axis-wise (cyclicly) to the direction of the
            % derivative. In other words, this is a simple axis-wise form
            % of gradient ascent.
            stage = getObjByName(obj.mStageName);
            spcm = getObjByName(Spcm.NAME);
            axes = stage.getAxis(stage.availableAxes);
            scanner = StageScanner.init;
            
            % Initialize scan parameters for search
            sp = obj.mScanParams;
            sp.fixedPos = stage.Pos(axes);
            sp.pixelTime = obj.pixelTime;
            
            while ~obj.stopFlag && any(obj.stepSize > obj.MINIMUM_STEP_VECTOR) && ~obj.isDivergent
                if obj.stepSize(obj.currAxis) > obj.MINIMUM_STEP_VECTOR(obj.currAxis)
                    obj.stepNum = obj.stepNum + 1;
                    pos = sp.fixedPos(obj.currAxis);
                    step = obj.stepSize(obj.currAxis);
                    
                    % scan to find forward and backward 'derivative'
                    % backward
                    sp.fixedPos(obj.currAxis) = pos - step;
                    signals(1) = scanner.scanPoint(stage, spcm, sp);
                    % current
                    sp.fixedPos(obj.currAxis) = pos;
                    signals(2) = scanner.scanPoint(stage, spcm, sp);
                    % forward
                    sp.fixedPos(obj.currAxis) = pos + step;
                    signals(3) = scanner.scanPoint(stage, spcm, sp);
                    
                    shouldMoveBack = obj.isDifferenceAboveThreshhold(signals(1), signals(2));
                    shouldMoveFwd = obj.isDifferenceAboveThreshhold(signals(3), signals(2));
                    
                    shouldContinue = false;
                    if shouldMoveBack
                        if shouldMoveFwd
                            % local minimum; don't move
                            disp('Conflict.... make longer scans?')
                        else
                            % should go back and look for maximum:
                            % prepare for next step
                            newStep = -step;
                            pos = pos + newStep;
                            newSignal = signals(1);   % value @ best position yet
                            shouldContinue = true;
                        end
                        
                    else
                        if shouldMoveFwd
                            % should go forward and look for maximum:
                            % prepare for next step
                            newStep = step;
                            pos = pos + newStep;
                            newSignal = signals(3);   % value @ best position yet
                            shouldContinue = true;
                        else
                            % local maximum or plateau; don't move
                        end
                    end
                    
                    while shouldContinue
                        if obj.isDivergent || obj.stopFlag; return; end
                        % we are still iterating; save current position before moving on
                        obj.mSignal = newSignal;    % Save value @ best position yet
                        obj.recordCurrentState;
                        
                        obj.stepNum = obj.stepNum + 1;
                        % New pos = (pos + step), if you should move forward;
                        %           (pos - step), if you should move backwards
                        pos = pos + newStep;
                        sp.fixedPos(obj.currAxis) = pos;
                        sp.isFixed(obj.currAxis) = true;
                        newSignal = scanner.scanPoint(stage, spcm, sp);
                        
                        shouldContinue = obj.isDifferenceAboveThreshhold(newSignal, obj.mSignal);
                    end
                    obj.stepSize(obj.currAxis) = step/2;
                end
                sp.isFixed(obj.currAxis) = true;        % We are done with this axis, for now
                obj.currAxis = mod(obj.currAxis,3) + 1; % Cycle through [1 2 3]
            end
        end
    end
    
end

