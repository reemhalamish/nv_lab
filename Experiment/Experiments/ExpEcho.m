classdef ExpEcho < Experiment
    %EXPECHO Echo experiment
    
    properties (Constant, Hidden)
        MAX_FREQ = 5e3; % in MHz (== 5GHz)
        
        MIN_AMPL = -60;   % in dBm
        MAX_AMPL = 3;     % in dBm
        
        MAX_TAU_LENGTH = 1000;
        MIN_TAU = 1e-3; % in \mus (== 1 ns)
        MAX_TAU = 1e3; % in \mus (== 1 ms)
        
        EXP_NAME = 'Echo';
    end
    
    properties
        % Default values (might change during setup)
        frequency = 3029;   %in MHz
        amplitude = -10;    %in dBm
        
        tau = 1:100;        %in us
        halfPiTime = 0.025  %in us
        piTime = 0.05       %in us
        threeHalvesPiTime = 0.075 %in us
        
        timeout             % in ??. If timeout passes, we consider this measurement as failed
        
        
        constantTime = false      % logical
        doubleMeasurement = true  % logical
    end
    
    properties (Access = private)
        freqGenName
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = ExpEcho(FG)
            obj@Experiment;
            
            % First, get a frequency generator
            if nargin == 0; FG = []; end
            obj.freqGenName = obj.getFgName(FG);
            
            % Set properties inherited from Experiment
            obj.repeats = 1000;
            obj.averages = 2000;
            obj.track = true;   % Initialize tracking
            obj.trackThreshhold = 0.7;
            
            obj.detectionDuration = [0.25, 5];      % detection windows, in \mus
            obj.laserInitializationDuration = 20;   % laser initialization in pulsed experiments in \mus (??)
            
            obj.mCurrentXAxisParam = ExpParamDoubleVector('Time', [], StringHelper.MICROSEC, obj.EXP_NAME);
            obj.mCurrentYAxisParam = ExpParamDoubleVector('FL', [], 'normalised', obj.EXP_NAME);
        end
    end
    
    %% Setters
    methods
        function set.frequency(obj, newVal) % newVal is in MHz
            if ~isscalar(newVal)
                obj.sendError('Echo Experiment frequency must be scalar')
            end
            if ~ValidationHelper.isInBorders(newVal, 0, obj.MAX_FREQ)
                errMsg = sprintf(...
                    'Frequency must be between 0 and %d! Frequency reuqested: %d', ...
                    obj.MAX_FREQ, newVal);
                obj.sendError(errMsg);
            end
            % If we got here, then newVal is OK.
            obj.frequency = newVal;
            obj.changeFlag = true;
        end
        
        
        function set.amplitude(obj, newVal) % newVal is in dBm
            if ~isscalar(newVal)
                obj.sendError('Echo Experiment amplitude must be scalar')
            end
            if ~ValidationHelper.isInBorders(newVal ,obj.MIN_AMPL, obj.MAX_AMPL)
                errMsg = sprintf(...
                    'Amplitude must be between %d and %d! Amplitude reuqested: %d', ...
                    obj.MIN_AMPL, obj.MAX_AMPL, newVal);
                obj.sendError(errMsg);
            end
            % If we got here, then newVal is OK.
            obj.amplitude = newVal;
            obj.changeFlag = true;
        end
        
        function set.tau(obj ,newVal)	% newVal in microsec
            if ~ValidationHelper.isValidVector(newVal, obj.MAX_TAU_LENGTH)
                obj.sendError('In Echo Experiment, the length of Tau must be a valid vector! Ignoring.')
            end
            if ~ValidationHelper.isInBorders(newVal, obj.MIN_TAU, obj.MAX_TAU)
                errMsg = sprintf(...
                    'Tau must be between %d and %d! Amplitude reuqested: %d', ...
                    obj.MIN_TAU, obj.MAX_TAU, newVal);
                obj.sendError(errMsg);
            end
            % If we got here, then newVal is OK.
            obj.tau = newVal;
            obj.changeFlag = true;
        end
        
        function checkDetectionDuration(obj, newVal) %#ok<INUSL>
            % Used in set.detectionDuration. Overriding from superclass
            if length(newVal) ~= 2
                error('Exactly 2 detection duration periods are needed in an Echo experiment')
            end
        end
    end
    
    %% Helper functions
    methods
        function sig = readAndShape(obj)
            spcm = getObjByName(Spcm.NAME);
            pg = getObjByName(PulseGenerator.NAME);
            
            kc = 1e3;     % kilocounts
            musec = 1e-6;   % microseconds
            
            spcm.startGatedCount;
            pg.Run;
            s = spcm.readGated(obj.DAQtask, numScans, obj.timeout);
            s = reshape(s, 2, length(s)/2);
            sig = mean(s,2).';
            sig = sig./(obj.detectionDuration*musec)/kc; %kcounts per second
        end
    end
    
    %% Overridden from Experiment
    methods
        function prepare(obj)
            % Create sequence for this experiment
            
            %%% Useful parameters for what follows
            initDuration = obj.laserInitializationDuration-sum(obj.detectionDuration);
            
            if obj.constantTime
                % The length of the sequence will change when we change
                % tau. To counter that, we add some delay at the end.
                % (mwOffDelay is a property of class Experiment)
                lastDelay = obj.mwOffDelay+2*max(obj.tau);
            else
                lastDelay = obj.mwOffDelay;
            end
            
            %%% Creating the sequence
            S = Sequence;
            S.addEvent(obj.laserOnDelay,    'greenLaser')                                   % Calibration of the laser with SPCM (laser on)
            S.addEvent(obj.detectionDuration(1),...
                                            {'greenLaser', 'detector'})                     % Detection
            S.addEvent(initDuration,        'greenLaser')                                   % Initialization
            S.addEvent(obj.detectionDuration(2),...
                                            {'greenLaser', 'detector'})                     % Reference detection
            S.addEvent(obj.laserOffDelay);                                                  % Calibration of the laser with SPCM (laser off)
            S.addEvent(obj.halfPiTime);                                                     % MW
            S.addEvent(obj.tau(end),        '',                         'tau');             % Delay
            S.addEvent(obj.piTime)                                                          % MW
            S.addEvent(obj.tau(end),        '',                         'tau');             % Delay
            S.addPulse(obj.halfPiTime,      'MW',                       'projectionPulse'); % MW
            S.addPulse(lastDelay,           '',                         'lastDelay');       % Last delay, making sure the MW is off
            
            %%% Send to PulseGenerator
            pg = getObjByName(PulseGenerator.NAME);
            pg.sequence = S;
            pg.repeats = obj.repeats;
            obj.changeFlag = false;
            
            %%% Set Frequency Generator
            fg = getObjByName(obj.freqGenName);
            fg.amplitude = obj.amplitude;
            fg.frequency = obj.frequency;
            
            numScans = 2*obj.repeats;
            measurementlength = 1 + double(obj.doubleMeasurement);   % 1 is single, 2 is double
            obj.signal = zeros(2 * measurementlength, length(obj.tau), obj.averages);
            obj.timeout = 15 * numScans * max(obj.PB.time) * 1e-6;
            
            spcm = getObjByName(Spcm.NAME);
            spcm.prepareGatedCount(numScans);
            
            fprintf('Starting %d averages with each average taking %.1f seconds, on average.\n', ...
                obj.averages, 1e-6*obj.repeats*seqTime*length(obj.tau)*(1+obj.doubleMeasurement));
        end
        
        function perform(obj, nIter)
            %%% Initialization
            
            % Devices
            pg = getObjByName(PulseGenerator.NAME);
            seq = pg.sequence;
            spcm = getObjByName(Spcm.NAME);
            
            % Some magic numbers
            maxLastDelay = obj.mwOffDelay + max(obj.tau);
            len = 2*(1 + double(obj.doubleMeasurement));    % 2 for single, 4 for double
            sig = zeros(1, len);   % allocate memory
            
            %%% Run - Go over all tau's, in random order
            for t = randperm(length(obj.tau))
                success = false;
                for trial = 1 : 5
                    try
                        seq.change('tau', 'duration', obj.tau(t));
                        if obj.constantTime
                            seq.change('lastDelay', 'duration', maxLastDelay - 2*obj.tau(t));
                        end
                        obj.setGreenLaserPower; % todo: This is never set anywhere!!!!
                        sig(1:2) = obj.readAndShape;
                        
                        if obj.doubleMeasurement
                            seq.change('projectionPulse', 'duration', obj.threeHalvesPiTime);
                            sig(3:4) = obj.readAndShape;
                            seq.change('projectionPulse', 'duration', obj.halfPi);
                        end
                        obj.signal(:, t, nIter) = sig;
                        
                        Tracker.compareReference(sig(2), Tracker.REFERENCE_TYPE_KCPS, TrackablePosition.EXP_NAME);
                        success = true;     % Since we got till here
                        break;
                    catch err
                        warning(err.message);
                        fprintf('Experiment failed at trial %d, attempting again.\n', trial);
                        try
                            spcm.stopTask(obj.DAQtask);
                        catch
                        end
                    end
                end
                if ~success
                    break
                end
            end
            
            
            
            %%% Plotting: should instead be sendEventDataUpdated
            S1 = squeeze(obj.signal(1,:,:));
            S2 = squeeze(obj.signal(2,:,:));
            
            S = mean(S1./S2,2);
            
            if obj.doubleMeasurement
                S3 = squeeze(obj.signal(3,:,:));
                S4 = squeeze(obj.signal(4,:,:));
                
                SDoubleMeasurement = mean(S3./S4,2);
                S = [S; SDoubleMeasurement];
            end
            
            obj.mCurrentXAxisParam.value = 2*obj.tau;
            obj.mCurrentYAxisParam.value = S;
            
            %%% end (plotting)

            
            % todo: needs to happen after all averages:
            % obj.CloseExperiment(obj.DAQtask)
        end
        
        function analyze(obj)
            % In the future, this will analyze results and fit from it the
            % coherence time.
        end
        
        
    end
    
    %% Helper functions
    methods (Static)
        function name = getFgName(FG)
            % Get name of relevant frequency generator (if there is only
            % one; otherwise, we can't tell which one to use)
            
            if nargin == 0 || isempty(FG)
                % No input -- we take the default FG
                name = FrequencyGenerator.getDefaultFgName;
            elseif ischar(FG)
                getObjByName(FG);
                % If this did not throw an error, then the FG exists
                name = FG;
            elseif isa(FG, 'FrequencyGenerator')
                name = FG.name;
            else
                EventStation.anonymousError('Sorry, but a %s is not a Frequency Generator...', class(FG))
            end
        end
    end
    
end

