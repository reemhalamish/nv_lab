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
        frequency       %in MHz
        amplitude       %in MHz
        tau             %in us
        pi              %in us
        halfPi          %in us
        threeHalvesPi   %in us
        constantTime        % logical
        doubleMeasurement   % logical
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = ExpEcho % Defult values go here
            obj@Experiment;
            obj.repeats = 1000;
            obj.averages = 2000;
            obj.track = true; %initialize tracking
            obj.trackThreshhold = 0.7;
            
            obj.frequency = 3029;   %MHz
            obj.amplitude = -10;    %dBm
            
            obj.halfPi = 0.026;     %\mus
            obj.pi = 2*obj.halfPi;
            obj.threeHalvesPi = 3*obj.halfPi;
            obj.tau = 1:1:100;          %\mus
            obj.detectionDuration = [0.25, 5];      % detection windows, in \mus
            obj.laserInitializationDuration = 20;   % laser initialization in pulsed experiments in \mus (??)
            
            obj.constantTime = false;
            obj.doubleMeasurement = true;
        end
        
        function set.frequency(obj, newVal) % newVal in MHz
            OK1 = isscalar(newVal);
            OK2 = ValidationHelper.isInBorders(newVal, 0, obj.MAX_FREQ);
            if OK1 && OK2
                obj.frequency = newVal;
                obj.changeFlag = true;
            end
        end
        
        function set.amplitude(obj, newVal) % newVal in dBm
            maxVectorLength = length(obj.FG);
            OK1 = ValidationHelper.isValidVector(newVal, maxVectorLength); 
            OK2 = ValidationHelper.isInBorders(newVal ,obj.MIN_AMPL, obj.MAX_AMPL);
            if OK1 && OK2
                obj.amplitude = newVal;
                obj.changeFlag = true;
            end
        end
        
        function set.tau(obj ,newVal)	% newVal in microsec
            OK1 = ValidationHelper.isValidVector(newVal, obj.MAX_TAU_LENGTH);
            OK2 = ValidationHelper.isInBorders(newVal, obj.MIN_TAU, obj.MAX_TAU);
            if OK1 && OK2
                obj.tau = newVal;
                obj.changeFlag = true;
            end
        end

        %%%%%
        function LoadExperiment(obj) %X - detection times, in us
            %%% Create sequence for this experiment %%%
            if length(obj.detectionDuration) ~= 2
                error('Two detection duration periods are needed in an Echo experiment')
            end
            % Useful parameters for what follows
            initDuration = obj.laserInitializationDuration-sum(obj.detectionDuration);
            tauPulse = Pulse(obj.tau(end), '', 'tau');  % Delay
            projectionPulse = Pulse(obj.halfPi, 'MW', 'projectionPulse');
            if obj.constantTime
                lastDelay = Pulse(obj.mwOffDelay+2*max(obj.tau), '', 'lastDelay');
            else
                lastDelay = Pulse(obj.mwOffDelay, '', 'lastDelay');
            end
            
            % Creating the sequence
            S = Sequence;
            S.addEvent(obj.laserOnDelay,            'greenLaser')               % Calibration of the laser with SPCM (laser on)
            S.addEvent(obj.detectionDuration(1),    {'greenLaser','detector'})	% Detection
            S.addEvent(initDuration,                'greenLaser')               % Initialization
            S.addEvent(obj.detectionDuration(2),    {'greenLaser','detector'})  % Reference detection
            S.addEvent(obj.laserOffDelay,           '');                        % Calibration of the laser with SPCM (laser off)
            S.addEvent(obj.halfPi,  'MW');	% MW
            S.addPulse(tauPulse); % ''      % Delay
            S.addEvent(obj.pi,      'MW')   % MW
            S.addPulse(tauPulse); % ''      % Delay
            S.addPulse(projectionPulse);    % MW
            S.addPulse(lastDelay) % ''      % Last delay, making sure the MW is off
            
            %%% Send to PulseGenerator
            pg = getObjByName(PulseGenerator.NAME);
            pg.sequence = S;
            pg.repeats = obj.repeats;
            obj.changeFlag = false;
        end
        
        function Run(obj) %X is the MW duration vector
            obj.LoadExperiment;
            obj.stopFlag = 0;
            obj.SetAmplitude(obj.amplitude(1), 1)
            obj.SetFrequency(obj.frequency(1), 1)
            numScans = 2*obj.PB.repeats;
            obj.signal = zeros(2*(1+obj.doubleMeasurement), length(obj.tau), obj.averages);
            timeout = 15 * numScans * max(obj.PB.time) * 1e-6;
            obj.DAQtask = obj.InitializeExperiment(numScans);
            if obj.constantTime
                seqTime = max(obj.tau)+obj.laserInitializationDuration+obj.lastDeley;
            else
                seqTime = mean(obj.tau)+obj.laserInitializationDuration+obj.lastDeley;
            end
            fprintf('Starting %d averages with each average taking %.1f seconds, on average.\n', obj.averages, 1e-6*obj.repeats*seqTime*length(obj.tau)*(1+obj.doubleMeasurement));
            for a = 1:obj.averages
                for t = randperm(length(obj.tau))
                    success = false;
                    for trial = 1 : 5
                        try
                            obj.PB.changeSequence('tau', 'duration', obj.tau(t));
                            if obj.constantTime
                                obj.PB.changeSequence('lastDelay', 'duration', obj.lastDeley+(max(obj.tau)-obj.tau(t))*2);
                            end
                            obj.DAQ.startGatedCounting(obj.DAQtask)
                            obj.PB.Run;
                            s = obj.DAQ.readGatedCounting(obj.DAQtask,numScans,timeout);
                            obj.DAQ.stopTask(obj.DAQtask);
                            s = reshape(s,2,length(s)/2);
                            s = mean(s,2).';
                            s = s./(obj.detectionDuration*1e-6)*1e-3;%kcounts per second
                            if obj.doubleMeasurement
                                obj.PB.changeSequence('projectionPulse', 'duration', obj.threeHalvesPi);
                                obj.DAQ.startGatedCounting(obj.DAQtask)
                                obj.PB.Run;
                                s2 = obj.DAQ.readGatedCounting(obj.DAQtask,numScans,timeout);
                                obj.DAQ.stopTask(obj.DAQtask);
                                s2 = reshape(s2,2,length(s2)/2);
                                s2 = mean(s2,2).';
                                s2 = s2./(obj.detectionDuration*1e-6)*1e-3; %kcounts per second
                                s = [s s2]; %#ok<AGROW>
                                obj.PB.changeSequence('projectionPulse', 'duration', obj.halfPi);
                            end
                            obj.signal(:,t,a) = s;
                            
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
                                obj.DAQ.stopTask(obj.DAQtask);
                            catch
                            end
                        end
                    end
                    if ~success
                        break
                    end
                end
                fprintf('%s%%\n',num2str(a/obj.averages*100))
                obj.PlotResults(a);
                drawnow
                if ~success || obj.stopFlag
                    break
                end
                obj.SaveExperiment('temp_exp');
            end
            obj.CloseExperiment(obj.DAQtask)
            end
        
        function PlotResults(obj,index)
            new = 0;
            if isempty(obj.figHandle) || ~isvalid(obj.figHandle)
                figure; 
                obj.figHandle = gca;
                % add apushbutton
                obj.gui.stopButton = uicontrol('Parent',gcf,'Style','pushbutton','String','Stop','Position',[0.0 0.5 100 20],'Visible','on','Callback',@obj.PushBottonCallback);
                new = 1;
            end
            if nargin<2
                index = size(obj.signal_,3);
            end
            S1 = squeeze(obj.signal_(1,:,1:index));
            S2 = squeeze(obj.signal_(2,:,1:index));
            
            if index == 1
                S = S1./S2;
            else
                S = mean(S1./S2,2);
            end

            plot(obj.figHandle, 2*obj.tau, S)
            xlabel('Time (\mus)')
            ylabel('FL (norm)')
            
            if obj.doubleMeasurement
                S3 = squeeze(obj.signal_(3,:,1:index));
                S4 = squeeze(obj.signal_(4,:,1:index));
                
                if index == 1
                    S = S3./S4;
                else
                    S = mean(S3./S4,2);
                end
                hold(obj.figHandle, 'on')
                plot(obj.figHandle, 2*obj.tau, S)
                hold(obj.figHandle, 'off')
            end
            
            if new
                addTopXAxis(obj.figHandle, 'xLabStr', '\tau (\mus)', 'exp', '0.5*argu');
            end
        end
        
        function PushBottonCallback(obj,PushButton, EventData)
           obj.stopFlag = 1; 
        end
    end
    
end

