classdef SpcmNiDaqControlled < Spcm & NiDaqControlled
    %SPCMNIDAQCONTROLLED spcm that is controlled by the NiDaq
    %   inherit NiDaqControlled, also inherit Spcm
    
    properties (Access = protected)
        % Backup, for NiDaq reset
        isEnabled   % logical
        
        % For time counter
        counterIntegrationTime
        nTimeCounts
        counterTimeTask
        
        % For scanning
        nScanCounts
        scanTimeoutTime
        counterScanSPCMTask
        counterScanTimeTask
        fastScan
        scanningStageName
        
        % For gated read
        nGatedCounts
        gatedTimeoutTime
        counterGatedTask
        
        % Name
        niDaqGateChannelName
        niDaqCountChannelName
    end
    
    properties (Constant, Hidden)
        NEEDED_FIELDS = [Spcm.SPCM_NEEDED_FIELDS, {'nidaq_channel_gate', 'nidaq_channel_counts'}];
        OPTIONAL_FIELDS = {'nidaq_channel_min_val', 'nidaq_channel_max_val'};
    end
    
    
    methods
        function obj = SpcmNiDaqControlled(name, niDaqGateChannel, niDaqCountsChannel, channelMinValue, channelMaxValue)
            % Contructor, creates the object and registers the channels in
            % the DAQ.
            obj@Spcm(name);
            niDaqGateChannelName = sprintf('%s_gate', name);
            niDaqCountChannelName= sprintf('%s_channel', name);
            obj@NiDaqControlled({niDaqGateChannelName, niDaqCountChannelName}, ...
                {niDaqGateChannel, niDaqCountsChannel}, channelMinValue, channelMaxValue);
            obj.niDaqGateChannelName = niDaqGateChannelName;
            obj.niDaqCountChannelName = niDaqCountChannelName;
            
            daq = getObjByName(NiDaq.NAME);
            obj.isEnabled = daq.readDigital(obj.niDaqGateChannelName);
            obj.nScanCounts = 0;
        end
    end
    
    methods % SPCM functions
        function setSPCMEnable(obj, newBooleanValue)
            % Enables/Disables the SPCM.
            daq = getObjByName(NiDaq.NAME);
            daq.writeDigital(obj.niDaqGateChannelName, newBooleanValue)
            obj.isEnabled = newBooleanValue;
        end
        
    %%% Read by time %%%
        function prepareReadByTime(obj, integrationTimeInSec)
            % Prepare the SPCM to a scan by timer, with integration time of
            % integrationTime in seconds.
            obj.counterIntegrationTime = integrationTimeInSec;
            obj.nTimeCounts = integrationTimeInSec*100e3; % 100kHz basis.
            
            niDaq = getObjByName(NiDaq.NAME);
            obj.counterTimeTask = CreateDAQEdgeCountingMeas(niDaq,  obj.nTimeCounts, obj.niDaqCountChannelName, niDaq.CHANNEL_100kHZ);
            niDaq.startTask(obj.counterTimeTask);
        end
        
        function [kcps, sterr] = readFromTime(obj)
            % Reads from the SPCM for the integration time and returns a
            % single point which is the kcps and also the standard error.
            
            % Actual reading from device
            niDaq = getObjByName(NiDaq.NAME);
            try
                countsSPCM = double(niDaq.ReadDAQCounter(obj.counterTimeTask, obj.nTimeCounts, obj.counterIntegrationTime));
            catch err
                msg = err.message;
                expression = '-200279'; % "The application is not able to keep up with the hardware acquisition."
                if contains(msg, expression)
                    % There was NiDaq reset, we can now safely resume
                    err2warning(err);
                    countsSPCM = double(niDaq.ReadDAQCounter(obj.counterTimeTask, obj.nTimeCounts, obj.counterIntegrationTime));
                    % ^ This *should* work. If it doesn't, there might be a
                    % bigger problem, and we want to let the user know
                    % about it.
                end
            end
            
            % Data processing
            countsSPCM = niDaq.countsDiff(countsSPCM);
            kiloCounts = countsSPCM/1000;
            meanTime = obj.counterIntegrationTime/obj.nTimeCounts; % mean time for each reading
            kcps = mean(kiloCounts/meanTime);
            sterr = ste(kiloCounts/meanTime);   % ste is a home-made function for standard error
        end
        
        function clearTimeRead(obj)
            % Clears the task for reading SPCM by time.
            if obj.nTimeCounts <= 0
                obj.sendError('Can''t clear SPCM task without calling ''prepare()''! ');
            end
            obj.nTimeCounts = 0;
            daq = getObjByName(NiDaq.NAME);
            daq.endTask(obj.counterTimeTask);
        end
    %%% End (by time) %%%
    
    
    %%% By Stage %%%
        function prepareCountByStage(obj, stageName, nPixels, timeout, fastScan)
            % Prepare the SPCM to a scan by a stage. Before a multiline
            % scan, this should be called only once.
            if ~ValidationHelper.isValuePositiveInteger(nPixels)
                obj.sendError('Can''t prepare for reading %s points, only positive integers allowed! Igonring');
            end
            obj.nScanCounts = BooleanHelper.ifTrueElse(fastScan, nPixels+1, nPixels); % Fast scans works by edges, so an extra count is needed.
            obj.scanTimeoutTime = timeout;
            obj.fastScan = fastScan;
            obj.scanningStageName = stageName;
            
            niDaq = getObjByName(NiDaq.NAME);
            prepareCountByStageInternal(obj, niDaq);
        end
        
        function startScanCount(obj)
            % Starts reading by scan, this should be called before every line.
            daq = getObjByName(NiDaq.NAME);
            daq.startTask(obj.counterScanSPCMTask);
            daq.startTask(obj.counterScanTimeTask);
        end
        
        function stopScanCount(obj)
            % Stops at the end of reading line
            daq = getObjByName(NiDaq.NAME);
            daq.stopTask(obj.counterScanSPCMTask);
            daq.stopTask(obj.counterScanTimeTask);
        end
        
        function vectorOfKcps = readFromScan(obj)
            % Read by scan. Reads a single line.
            if obj.nScanCounts <= 0
                obj.sendError('Can''t read from SPCM without calling ''prepare()''! ');
            end
            daq = getObjByName(NiDaq.NAME);
            countsSPCM = double(daq.ReadDAQCounter(obj.counterScanSPCMTask, obj.nScanCounts, obj.scanTimeoutTime));
            countsTime = double(daq.ReadDAQCounter(obj.counterScanTimeTask, obj.nScanCounts, obj.scanTimeoutTime));
            if obj.fastScan
                countsSPCM = daq.countDiff(countsSPCM);
                countsTime = daq.countDiff(countsTime);
            end
            
            kiloCounts = countsSPCM/1000;
            time = countsTime*1e-8; % For seconds
            vectorOfKcps = kiloCounts./time;
            if any(isnan(vectorOfKcps))
                if all(time == 0)
                    obj.sendError('NaN detected in kcps, time is zeros (no data read from the DAQ)')
                else
                    obj.sendError('NaN detected in kcps')
                end
            end
        end
        
        function clearScanRead(obj)
            % Clear the task that scans from stage.
            if obj.nScanCounts <= 0
                obj.sendError('Can''t clear without calling ''prepare()''! ');
            end
            obj.nScanCounts = 0;
            daq = getObjByName(NiDaq.NAME);
            daq.endTask(obj.counterScanSPCMTask);
            daq.endTask(obj.counterScanTimeTask);
        end
    %%% End (By stage) %%%%
        
        
    %%% By gate %%%
        function prepareGatedCount(obj, nReads, timeout)
            % Prepare to read spcm count from opening the spcm window
            if ~ValidationHelper.isValuePositiveInteger(nReads)
                obj.sendError(sprintf('Can''t prepare for reading %d times, only positive integers allowed! Igonring.', nReads));
            end
            obj.nGatedCounts = nReads;
            obj.gatedTimeoutTime = timeout;
            
            daq = getObjByName(NiDaq.NAME);
            daq.writeDigital(obj.niDaqGateChannelName, true); % Turn on gate
            task = daq.CreateDAQPulseWidthMeas(nReads, ...
                obj.niDaqCountChannelName, obj.niDaqGateChannelName); % Set pulse-width measurement
            
            obj.counterGatedTask = task;
        end
        
        function startGatedCount(obj)
            % Actually start the process
            daq = getObjByName(NiDaq.NAME);
            daq.startTask(obj.counterGatedTask);
        end
        
        function counts = readGated(obj)
            % Read vector of signals from the spcm
            if obj.nGatedCounts <= 0
                obj.sendError('Can''t read from SPCM without calling ''prepare()''!');
            end
            daq = getObjByName(NiDaq.NAME);
            counts = double(daq.ReadDAQCounter(obj.counterGatedTask, obj.nGatedCounts, obj.gatedTimeoutTime));
            
            % Error handling
            if any(isnan(counts))
                if isnan(counts)    % i.e. all are NaN
                    obj.sendError('NaN detected in kcps (no data read from the DAQ)')
                else
                    obj.sendError('NaN detected in kcps')
                end
            end
        end
        
        function clearGatedRead(obj)
            % Complete the task of reading the spcm
            if obj.nGatedCounts <= 0
                obj.sendError('Can''t clear without calling ''prepare()''! ');
            end
            obj.nGatedCounts = 0;
            daq = getObjByName(NiDaq.NAME);
            daq.endTask(obj.counterGatedTask);
        end
    %%% End (by gate) %%%
    end
    
    %%%
    methods % DAQ function
        function onNiDaqReset(obj, niDaq)
            % This function jumps when the NiDaq resets
            if obj.nScanCounts > 0
                prepareCountByStageInternal(obj, niDaq);
            end
            if obj.isEnabled
                % When reset, the NiDaq no longer remembers whether the
                % channel was off or on. We need to set the value, but only
                % if needed (since writeDigital is costly)
                obj.setSPCMEnable(obj.isEnabled)
            end
        end
    end
  
    methods (Static)
        function spcmObj = create(spcmName, spcmStruct)
            missingField = FactoryHelper.usualChecks(spcmStruct, SpcmNiDaqControlled.NEEDED_FIELDS);
            if ~isnan(missingField)
                EventStation.anonymousError(...
                    'Can''t initialize NiDaq-controlled SPCM - required field "%s" was not found in initialization struct!', ...
                    missingField);
            end
            
            % We want to get either values set in json, or empty variables
            % (which will be handled by NiDaqControlled constructor):
            spcmStruct = FactoryHelper.supplementStruct(spcmStruct, SpcmNiDaqControlled.OPTIONAL_FIELDS);
            
            counts = spcmStruct.nidaq_channel_counts;
            gate = spcmStruct.nidaq_channel_gate;
            minVal = spcmStruct.nidaq_channel_min_val;
            maxVal = spcmStruct.nidaq_channel_max_val;
            
            spcmObj = SpcmNiDaqControlled(spcmName, gate, counts, minVal, maxVal);
        end
    end
    
    
    methods (Access = protected)
        function prepareCountByStageInternal(obj, niDaq)
            % Creates the measurment in the DAQ according to the parameters
            % in the object.
            if obj.fastScan
                obj.counterScanSPCMTask = niDaq.CreateDAQEdgeCountingMeas(obj.nScanCounts, obj.niDaqCountChannelName, obj.scanningStageName, 0);
                obj.counterScanTimeTask = niDaq.CreateDAQEdgeCountingMeas(obj.nScanCounts, niDaq.CHANNEL_100MHZ, obj.scanningStageName, 1);
            else
                obj.counterScanSPCMTask = niDaq.CreateDAQPulseWidthMeas(obj.nScanCounts, obj.niDaqCountChannelName, obj.scanningStageName, 0);
                obj.counterScanTimeTask = niDaq.CreateDAQPulseWidthMeas(obj.nScanCounts, niDaq.CHANNEL_100MHZ, obj.scanningStageName, 1);
            end
        end
    end
end