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
        frequency = 3029;   %in MHz
        amplitude = -10;    %in dBm
        
        tau = 1:100;        %in us
        halfPiTime = 0.025  %in us
        piTime = 0.05       %in us
        threeHalvesPiTime = 0.075 %in us
        
        
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
    
    %% Overridden from Experiment
    methods
        function prepare(obj)
            %%% Create sequence for this experiment
            
            % Useful parameters for what follows
            initDuration = obj.laserInitializationDuration-sum(obj.detectionDuration);
            
            tauPulse = Pulse(obj.tau(end), '', 'tau');  % Delay
            projectionPulse = Pulse(obj.halfPiTime, 'MW', 'projectionPulse');
            if obj.constantTime
                % The length of the sequence will change when we change
                % tau. To counter that, we add some delay at the end.
                % (mwOffDelay is a property of class Experiment)
                lastDelay = Pulse(obj.mwOffDelay+2*max(obj.tau), '', 'lastDelay');
            else
                lastDelay = Pulse(obj.mwOffDelay, '', 'lastDelay');
            end
            
            % Creating the sequence
            S = Sequence;
            S.addEvent(obj.laserOnDelay,            'greenLaser')               % Calibration of the laser with SPCM (laser on)
            S.addEvent(obj.detectionDuration(1),    {'greenLaser', 'detector'}) % Detection
            S.addEvent(initDuration,                'greenLaser')               % Initialization
            S.addEvent(obj.detectionDuration(2),    {'greenLaser', 'detector'}) % Reference detection
            S.addEvent(obj.laserOffDelay,           '');                        % Calibration of the laser with SPCM (laser off)
            S.addEvent(obj.halfPiTime);     % MW
            S.addPulse(tauPulse);           % Delay
            S.addEvent(obj.piTime)          % MW
            S.addPulse(tauPulse);           % Delay
            S.addPulse(projectionPulse);    % MW
            S.addPulse(lastDelay)           % Last delay, making sure the MW is off
            
            %%% Send to PulseGenerator
            pg = getObjByName(PulseGenerator.NAME);
            pg.sequence = S;
            pg.repeats = obj.repeats;
            obj.changeFlag = false;
            
            % Set Frequency Generator
            fg = getObjByName(obj.freqGenName);
            fg.amplitude = obj.amplitude;
            fg.frequency = obj.frequency;
            
            numScans = 2*obj.repeats;
            obj.signal = zeros(2*(1+obj.doubleMeasurement), length(obj.tau), obj.averages);
            timeout = 15 * numScans * max(obj.PB.time) * 1e-6;
            obj.initialize(numScans);
            
            fprintf('Starting %d averages with each average taking %.1f seconds, on average.\n', ...
                obj.averages, 1e-6*obj.repeats*seqTime*length(obj.tau)*(1+obj.doubleMeasurement));
        end
        
        function perform(obj, nIter)
            % Devices
            pg = getObjByName(PulseGenerator.NAME);
            seq = pg.sequence;
            daq = getObjByName(NiDaq.NAME);
            
            % Some useful constants
            kcps = 1e3;     % kilocounts/sec
            musec = 1e-6;   % microseconds
            maxLastDelay = obj.mwOffDelay + max(obj.tau);
            
            % Go over all tau's, in random order
            for t = randperm(length(obj.tau))
                success = false;
                for trial = 1 : 5
                    try
                        seq.change('tau', 'duration', obj.tau(t));
                        if obj.constantTime
                            seq.change('lastDelay', 'duration', maxLastDelay - 2*obj.tau(t));
                        end
                        daq.startGatedCounting(obj.DAQtask)
                        pg.Run;
                        s = daq.readGatedCounting(obj.DAQtask,numScans,timeout);
                        daq.stopTask(obj.DAQtask);
                        s = reshape(s,2,length(s)/2);
                        s = mean(s,2).';
                        s = s./(obj.detectionDuration*musec)/kcps; %kcounts per second
                        if obj.doubleMeasurement
                            seq.change('projectionPulse', 'duration', obj.threeHalvesPiTime);
                            daq.startGatedCounting(obj.DAQtask)
                            pg.Run;
                            s2 = daq.readGatedCounting(obj.DAQtask,numScans,timeout);
                            daq.stopTask(obj.DAQtask);
                            s2 = reshape(s2,2,length(s2)/2);
                            s2 = mean(s2,2).';
                            s2 = s2./(obj.detectionDuration*musec)/kcps; %kcounts per second
                            s = [s s2]; %#ok<AGROW>
                            seq.change('projectionPulse', 'duration', obj.halfPi);
                        end
                        obj.signal(:, t, nIter) = s;
                        
                        tracked = obj.Tracking(s(2));
                        if tracked
                            obj.LoadExperiment
                            obj.DAQtask = obj.InitializeExperiment(numScans);
                        end
                        success = true;
                        break;
                    catch err
                        warning(err.message);
                        fprintf('Experiment failed at trial %d, attempting again.\n', trial);
                        try
                            daq.stopTask(obj.DAQtask);
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

