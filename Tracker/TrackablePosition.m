classdef TrackablePosition < Trackable
    %TRACKABLEPOSITION Makes sure that the experiment is still focused on
    %the desired NV center 
    % The function uses (todo: name algorithm) to counter mechanical drift
    % of the stage
    
    
    % Maybe inherit from StageScanner???
    properties (SetAccess = private)
        timer       % Stores tic from beginning of tracking
        stopFlag = false;
        mCurrentlyTracking = false;
        stepNum = 0 % int. Counts steps dince beginning of tracking

        mSignal
        mScanParams     % Object of class StageScanParams, to store current running scan
        stepSize        % 3x1 double. Holds the current size of position step
        
        mStageName
        mLaserName
    end
    
    properties (Constant)
        THRESHOLD_FRACTION = 0.02;  % Change is significant if dx/x > threshold fraction
        NUM_MAX_ITERATIONS = 100;   % After that many steps, convergence is improbable
        DETECTION_DURATION = 0.1 ;  % in seconds
        
        % vector constants, for [X Y Z]
        INITIAL_STEP_VECTOR = [0.1 0.1 0.2];    %[0.1 0.1 0.05];
        MINIMUM_STEP_VECTOR = [0.02 0.02 0.05]; %[0.01 0.01 0.01];
        STEP_RATIO_VECTOR = 0.5*ones(1, 3);
        ZERO_VECTOR = [0 0 0];
        
        HISTORY_FIELDS = {'position', 'step', 'time', 'value'}
    end
    
    methods
        function obj = TrackablePosition(stageName,laserName)
            obj@Trackable;
            obj.mStageName = stageName;
            obj.mLaserName = laserName;
            
            obj.mScanParams = StageScanParams;
        end

        function start(obj)
            obj.reset
            
            stage = getObjByName(obj.mStageName);
            axes = stage.getAxis(stage.availableAxes);
            spcm = getObjByName(Spcm.NAME);
            scanner = StageScanner.init;
            
            % Initialize scan parameters for scanning
            sp = obj.mScanParams;
            sp.fixedPos = stage.Pos(axes);
            sp.numPoints = 3 * ones(1,length(axes));
            sp.isFixed = true(size(sp.isFixed));    % all axes are fixed on initalization
            sp.fastScan = stage.hasFastScan;        % scan fast, if possible
            
            obj.timer = tic;
            obj.recordToHistory;    % record starting point
            % todo: if laser and spcm are off, turn them on
            while ~obj.stopFlag && any(obj.stepSize > obj.MINIMUM_STEP_VECTOR) && ~obj.isDivergent
                if obj.stepSize(currAxis) > obj.MINIMUM_STEP_VECTOR(currAxis)
                    obj.stepNum = obj.stepNum + 1;
                    pos = sp.fixedPos(currAxis);
                    step = obj.stepSize(currAxis);
                    
                    % scan to find forward and backward 'derivative'
                    sp.isFixed(currAxis) = false;
                    sp.from(currAxis) = pos - step;
                    sp.to(currAxis) = pos + step;
                    
                    signals = scanner.scan(stage, spcm, sp);    % scans [p-dp, p, p+dp]
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
                            negativeForBackPositiveForFwd = -1;
                            newSignal = signals(1);   % value @ best position yet
                            shouldContinue = true;
                        end
                            
                    else
                        if shouldMoveFwd
                            % should go forward and look for maximum:
                            % prepare for next step
                            negativeForBackPositiveForFwd = +1;
                            newSignal = signals(3);   % value @ best position yet
                            shouldContinue = true;
                        else
                            % local maximum or plateau; don't move
                        end
                    end
                            
                    while shouldContinue && ~obj.isDivergent && ~obj.stopFlag
                        % we are still iterating; save current position before moving on
                        obj.mSignal = newSignal;    % Save value @ best position yet
                        obj.recordToHistory;
                        
                        obj.stepNum = obj.stepNum + 1;
                        % New pos = (pos + step), if you should move forward;
                        %           (pos - step), if you should move backwards
                        pos = pos + (negativeForBackPositiveForFwd * step);
                        sp.fixedPos(currAxis) = pos;
                        newSignal = scanner.scanPoint(stage, spcm, sp);
                        
                        shouldContinue = isDifferenceAboveThreshhold(newSignal, obj.mSignal);
                    end
                    obj.stepSize(currAxis) = step/2;
                end
                sp.isFixed(currAxis) = true;    % We are done with this axis, for now
                currAxis = mod(currAxis,3) + 1; % Cycle through [1 2 3]
            end
            
            % Prepare output text
            if all(obj.stepSize <= obj.MINIMUM_STEP_VECTOR)
                obj.textOutput = sprintf('Local maximum was found in %u steps', obj.stepNum);
            elseif obj.stopFlag
                obj.textOutput = 'Operation terminated by user';
            elseif obj.isDivergent
                obj.textOutput = 'Maximum number of iterations reached without convergence';
            else
                obj.textOutput = 'This shouldn''t have happenned...';
            end
            
            obj.sendEventTrackableExpEnded;
        end
        
        function reset(obj)
            obj.timer = [];
            obj.stopFlag = false;
            obj.mCurrentlyTracking = false;
            obj.stepNum = 0;
            
            obj.mSignal = [];
            obj.mScanParams = StageScanParams;
            obj.stepSize = obj.INITIAL_STEP_VECTOR;

            obj.clearHistory;
        end
        
        function params = getAllTrackalbeParameter(obj) %#ok<MANU>
        % Returns a cell of values/paramters from the trackable experiment
        params = NaN;
        end
    end
        
    methods (Access = private)
        function intialize(obj)
            obj.reset;
%             stage = getObjByName(obj.stageName);    
        end
        
        function Stop(obj)
            obj.stopFlag=1;
        end
        
        function bool = isDivergent(obj)
            % If we arrive at the maximum number of iterations, we assume
            % the tracking sequence will not converge, and we stop it
            bool = (obj.stepNum >= obj.NUM_MAX_ITERATIONS);
        end
        
        function recordToHistory(obj)
            record = struct;
            record.position = obj.mScanParams.fixedPos;
            record.step = obj.stepSize;
            record.time = toc(obj.timer);
            record.value = obj.mSignal;
            
            obj.mHistory{end+1} = record;
        end

    end
    
    methods (Static)
        function bool = isDifferenceAboveThreshhold(x0, x1)
            bool = (x1-x0) > TrackablePosition.THRESHOLD_FRACTION;
        end
    end
    
end

