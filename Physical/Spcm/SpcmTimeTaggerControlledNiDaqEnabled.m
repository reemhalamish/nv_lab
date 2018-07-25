classdef SpcmTimeTaggerControlledNiDaqEnabled < Spcm & NiDaqControlled
    %SpcmTimeTaggerControlledNiDaqEnabled spcm that is controlled by the
    % Time Tagger and enabled by NiDaq
    
    properties (Access = protected)
        % For scanning
        nScanCounts
        scanTimeoutTime
        counterScanSPCMTask
        counterScanTimeTask
        fastScan
        scanningStageName
        
        % For time counter
        counterIntegrationTime
        nTimeCounts
        counterTimeTask
        
        % Channels
        niDaqGateChannelName
        timeTaggerCountChannelName
        
        % Two counters
        timeTaggerCount2ChannelName % When there are two counters
        
        % Pulsed lasers
        timeTaggerLaserChannelName % For pulsed lasers
        
        % Configuration
        channelsDelay
        hardwareFilter
    end
    
    properties (Constant, Hidden)
        NEEDED_FIELDS_SPCM_NIDAQ_TIMETAGGER = {'nidaq_channel_gate', 'timeTagger_channel_counts'};
        OPTIONAL_FIELDS_SPCM_NIDAQ_TIMETAGGER = {'timeTagger_channel_counts2', 'timeTagger_channel_laser'};
    end
    
    
    methods
        function obj = SpcmTimeTaggerControlledNiDaqEnabled(name, niDaqGateChannel, timeTaggerCountChannel, timeTaggerCount2Channel, timeTaggerLaserChannel)
            % Contructor, creates the object and registers the channels in
            % the DAQ and Time Tagger.
            obj@Spcm(name);
            niDaqGateChannelName = sprintf('%s_gate', name);
            timeTaggerCountChannelName= sprintf('%s_count', name);
            obj@NiDaqControlled({niDaqGateChannelName}, {niDaqGateChannel});
            obj.niDaqGateChannelName = niDaqGateChannelName;
            obj.timeTaggerCountChannelName = timeTaggerCountChannelName;
            if ~isempty('timeTaggerLaserChannel')
                timeTaggerLaserChannelName= sprintf('%s_laser', name);
                obj.timeTaggerLaserChannelName = timeTaggerLaserChannelName;
                obj.availableProperties.(obj.HAS_LIFETIME) = true;
                % register
            end
            if ~isempty('timeTaggerCount2Channel')
                timeTaggerCount2ChannelName= sprintf('%s_count2', name);
                obj.timeTaggerCount2ChannelName = timeTaggerCount2ChannelName;
                obj.availableProperties.(obj.HAS_G2) = true;
                % register
            end
            
            obj.nScanCounts = 0;
            obj.availableProperties.(obj.HAS_BINNING) = true;
        end
        
        function prepareReadByTime(obj, integrationTimeInSec)
            % Prepare the SPCM to a scan by timer, with integration time of
            % integrationTime in seconds.
%             obj.counterIntegrationTime = integrationTimeInSec;
%             obj.nTimeCounts = integrationTimeInSec*100e3; % 100kHz basis.
%             
%             niDaq = getObjByName(NiDaq.NAME);
%             obj.counterTimeTask = CreateDAQEdgeCountingMeas(niDaq,  obj.nTimeCounts, obj.niDaqCountChannelName, niDaq.CHANNEL_100kHZ);
%             niDaq.startTask(obj.counterTimeTask);
        end
        
        function [kcps, stdev] = readFromTime(obj)
            % Reads from the SPCM for the integration time and returns a
            % single point which is the kcps and also the standard error.

%             % Actual reading from device
%             niDaq = getObjByName(NiDaq.NAME);
%             try
%                 countsSPCM = double(niDaq.ReadDAQCounter(obj.counterTimeTask, obj.nTimeCounts, obj.counterIntegrationTime));
%             catch err
%                 msg = err.message;
%                 expression = '-200279'; % "The application is not able to keep up with the hardware acquisition."
%                 if contains(msg, expression)
%                     % There was NiDaq reset, we can now safely resume
%                     err2warning(err);
%                     countsSPCM = double(niDaq.ReadDAQCounter(obj.counterTimeTask, obj.nTimeCounts, obj.counterIntegrationTime));
%                     % ^ This *should* work. If it doesn't, there might be a
%                     % bigger problem, and we want to let the user know
%                     % about it.
%                 end
%             end
%             
%             % Data processing
%             countsSPCM = diff(countsSPCM);
%             countsSPCM(countsSPCM<0) = countsSPCM(countsSPCM<0)+2^32; % If an overflow occured then the point would be negative, and we need to add 2^32.
%             kiloCounts = countsSPCM/1000;
%             meanTime = obj.counterIntegrationTime/obj.nTimeCounts; % mean time for each reading
%             kcps = mean(kiloCounts/meanTime);
%             stdev = std(kiloCounts/meanTime)/sqrt(length(kiloCounts));
        end
        
        function clearTimeRead(obj)
            % Clears the task for reading SPCM by time.
%             if obj.nTimeCounts <= 0
%                 obj.sendError('Can''t clear SPCM task without calling ''prepare()''! ');
%             end
%             obj.nTimeCounts = 0;
%             daq = getObjByName(NiDaq.NAME);
%             daq.endTask(obj.counterTimeTask);
        end
                
        function prepareCountByStage(obj, stageName, nPixels, timeout, fastScan)
            % Prepare the SPCM to a scan by a stage. Before a multiline
            % scan, this should be called only once.
            if ~ValidationHelper.isValuePositiveInteger(nPixels)
                obj.sendError('Can''t prepare for reading %s points, only positive integers allowed! Igonring');
            end
%             obj.nScanCounts = BooleanHelper.ifTrueElse(fastScan, nPixels+1, nPixels); % Fast scans works by edges, so an extra count is needed.
%             obj.scanTimeoutTime = timeout;
%             obj.fastScan = fastScan;
%             obj.scanningStageName = stageName;
%             niDaq = getObjByName(NiDaq.NAME);
%             
%             prepareCountByStageInternal(obj, niDaq);
        end
        
        function startScanCount(obj)
            % Starts reading by scan, this should be called before every
            % line.
%             daq = getObjByName(NiDaq.NAME);
%             daq.startTask(obj.counterScanSPCMTask);
%             daq.startTask(obj.counterScanTimeTask);
        end
        
        function stopScanCount(obj)
            % Stops at the end of reading line
%             daq = getObjByName(NiDaq.NAME);
%             daq.stopTask(obj.counterScanSPCMTask);
%             daq.stopTask(obj.counterScanTimeTask);
        end
        
        function vectorOfKcps = readFromScan(obj)
            % Read by scan. Reads a single line.
%             if obj.nScanCounts <= 0
%                 obj.sendError('Can''t read from SPCM without calling ''prepare()''! ');
%             end
%             daq = getObjByName(NiDaq.NAME);
%             countsSPCM = double(daq.ReadDAQCounter(obj.counterScanSPCMTask, obj.nScanCounts, obj.scanTimeoutTime));
%             countsTime = double(daq.ReadDAQCounter(obj.counterScanTimeTask, obj.nScanCounts, obj.scanTimeoutTime));
%             if obj.fastScan
%                 countsSPCM = diff(countsSPCM);
%                 countsSPCM(countsSPCM<0) = countsSPCM(countsSPCM<0)+2^32; % If an overflow occured then the point would be negative, and we need to add 2^32.
%                 countsTime = diff(countsTime);
%                 countsTime(countsTime<0) = countsTime(countsTime<0)+2^32; % If an overflow occured then the point would be negative, and we need to add 2^32.
%             end
%             
%             kiloCounts = countsSPCM/1000;
%             time = countsTime*1e-8; % For seconds
%             vectorOfKcps = kiloCounts./time;
%             if nnz(isnan(vectorOfKcps))
%                 if nnz(time)==0
%                     obj.sendError('NaN detected in kcps, time is zeros (no data read from the DAQ)')
%                 else
%                     obj.sendError('NaN detected in kcps')
%                 end
%             end
        end
        
        function clearScanRead(obj)
            % Clear the task that scans from stage.
%             if obj.nScanCounts <= 0
%                 obj.sendError('Can''t clear without calling ''prepare()''! ');
%             end
%             obj.nScanCounts = 0;
%             daq = getObjByName(NiDaq.NAME);
%             daq.endTask(obj.counterScanSPCMTask);
%             daq.endTask(obj.counterScanTimeTask);
        end
        
        function setSPCMEnable(obj, newBooleanValue)
            % Enables/Disables the SPCM.
            daq = getObjByName(NiDaq.NAME);
            daq.writeDigital(obj.niDaqGateChannelName, newBooleanValue)
        end
    end
    
    methods
        function onNiDaqReset(obj, niDaq) %#ok<INUSD>
            % This function jumps when the NiDaq resets
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
            missingField = FactoryHelper.usualChecks(spcmStruct, SpcmNiDaqControlled.NEEDED_FIELDS_SPCM_NIDAQ_TIMETAGGER);
            if ~isnan(missingField)
                EventStation.anonymousError(...
                    'Can''t initialize NiDaq-controlled SPCM - required field "%s" was not found in initialization struct!', ...
                    missingField);
            end
            counts = spcmStruct.timeTagger_channel_counts;
            gate = spcmStruct.nidaq_channel_gate;
            
            % We want to get either values set in json, or empty variables
            % (which will be handled by the constructor):
            spcmStruct = FactoryHelper.supplementStruct(spcmStruct, SpcmTimeTaggerControlledNiDaqEnabled.OPTIONAL_FIELDS_SPCM_NIDAQ_TIMETAGGER);
            
            counts2 = spcmStruct.timeTagger_channel_counts2;
            laser = spcmStruct.timeTagger_channel_laser;
            spcmObj = SpcmTimeTaggerControlledNiDaqEnabled(spcmName, gate, counts, counts2, laser);
        end
    end
    
    
    methods (Access = protected)
        function prepareCountByStageInternal(obj, niDaq)
            % Creates the measurment in the DAQ according to the parameters
            % in the object.
%             if obj.fastScan
%                 obj.counterScanSPCMTask = niDaq.CreateDAQEdgeCountingMeas(obj.nScanCounts, obj.niDaqCountChannelName, obj.scanningStageName, 0);
%                 obj.counterScanTimeTask = niDaq.CreateDAQEdgeCountingMeas(obj.nScanCounts, niDaq.CHANNEL_100MHZ, obj.scanningStageName, 1);
%             else
%                 obj.counterScanSPCMTask = niDaq.CreateDAQPulseWidthMeas(obj.nScanCounts, obj.niDaqCountChannelName, obj.scanningStageName, 0);
%                 obj.counterScanTimeTask = niDaq.CreateDAQPulseWidthMeas(obj.nScanCounts, niDaq.CHANNEL_100MHZ, obj.scanningStageName, 1);
%             end
        end
    end
end