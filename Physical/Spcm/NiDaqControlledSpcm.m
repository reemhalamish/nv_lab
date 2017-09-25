classdef NiDaqControlledSpcm < Spcm & NiDaqControlled
    %NIDAQCONTROLLEDSPCM spcm that is controlled by the NiDaq
    %   inherit NiDaqControlled, also inherit Spcm
    
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
        
        % Name
        niDaqGateChannelName
        niDaqCountChannelName
    end
    
    properties(Constant = true, Hidden = true)
        NEEDED_FIELDS = {'nidaq_channel_gate', 'nidaq_channel_counts'};
    end
    
    
    methods
        function obj = NiDaqControlledSpcm(name, niDaqGateChannel, niDaqCountsChannel)
            % Contructor, creates the object and registers the channels in
            % the DAQ.
            obj@Spcm(name);
            niDaqGateChannelName = sprintf('%s_gate', name);
            niDaqCountChannelName= sprintf('%s_channel', name);
            obj@NiDaqControlled({niDaqGateChannelName, niDaqCountChannelName}, {niDaqGateChannel, niDaqCountsChannel});
            obj.niDaqGateChannelName = niDaqGateChannelName;
            obj.niDaqCountChannelName = niDaqCountChannelName;
            obj.nScanCounts = 0;
        end
        
        function prepareReadByTime(obj, integrationTimeInSec)
            % Prepare the SPCM to a scan by timer, with integration time of
            % integrationTime in seconds.
            todo = 'validation on integrationTime';
            obj.counterIntegrationTime = integrationTimeInSec;
            obj.nTimeCounts = integrationTimeInSec*100e3; % 100kHz basis.
            
            niDaq = getObjByName(NiDaq.NAME);
            obj.counterTimeTask = niDaq.CreateDAQEdgeCountingMeas(obj, nCounts, obj.niDaqCountChannelName, niDaq.CHANNEL_100kHZ);
        end
        
        function kcps = readFromTime(obj)
            % Reads from the SPCM for the integration time and returns a
            % single point which is the kcps.
            daq = getObjByName(NiDaq.NAME);
            daq.startTask(obj.counterTimeTask);
            counts = diff(daq.ReadDAQCounter(obj.counterTimeTask, obj.nScanCounts, obj.counterIntegrationTime));
            kiloCounts = double(counts)/1000;
            kcps = sum(kiloCounts)/obj.counterIntegrationTime;
        end
        
        function clearTimeRead(obj)
            % Clears the task for reading SPCM by time.
            if obj.nTimeCounts <= 0
                obj.sendError('can''t clear without calling ''prepare()''! ');
            end
            obj.nTimeCounts = 0;
            daq = getObjByName(NiDaq.NAME);
            daq.endTask(obj.counterScanSPCMTask);
        end
                
        function prepareReadByStage(obj, stageName, nPixels, timeout, fastScan)
            % Prepare the SPCM to a scan by a stage. Before a multiline
            % scan, this should be called only once.
            if ~ValidationHelper.isValuePositiveInteger(readingTimesInt)
                obj.sendError('can''t prepare for reading %s points, only positive integers allowed! Igonring');
            end
            obj.nScanCounts = BooleanHelper.ifTrueElse(fastScan, nPixels+1, nPixels); % Fast scans works by edges, so an extra count is needed.
            obj.scanTimeoutTime = timeout;
            obj.fastScan = fastScan;
            obj.scanningStageName = stageName;
            niDaq = getObjByName(NiDaq.NAME);
            
            prepareReadByStageInternal(obj, niDaq);
        end
        
        function startScanRead(obj)
            % Starts reading by scan, this should be called before every
            % line.
            daq = getObjByName(NiDaq.NAME);
            daq.startTask(obj.counterScanSPCMTask);
            daq.startTask(obj.counterScanTimeTask);
        end
        
        function vectorOfKcps = readFromScan(obj)
            % Read by scan. Reads a single line.
            if obj.nScanCounts <= 0
                obj.sendError('can''t read without calling ''prepare()''! ');
            end
            daq = getObjByName(NiDaq.NAME);
            countsSPCM = daq.ReadDAQCounter(obj.counterScanSPCMTask, obj.nScanCounts, obj.scanTimeoutTime);
            countsTime = daq.ReadDAQCounter(obj.counterScanTimeTask, obj.nScanCounts, obj.scanTimeoutTime);
            if obj.fastScan
                countsSPCM = diff(countsSPCM);
                countsTime = diff(countsTime);
            end
            
            kiloCounts = double(countsSPCM)/1000;
            time = double(countsTime)*1e-8; % For seconds
            vectorOfKcps = kiloCounts./time;
            if nnz(isnan(vectorOfKcps))
                if nnz(time)==0
                    obj.sendError('NaN detected in kcps, time is zeros (no data read from the DAQ)')
                else
                    obj.sendError('NaN detected in kcps')
                end
            end
        end
        
        function clearScanRead(obj)
            % Clear the task that scans from stage.
            if obj.nScanCounts <= 0
                obj.sendError('can''t clear without calling ''prepare()''! ');
            end
            obj.nScanCounts = 0;
            daq = getObjByName(NiDaq.NAME);
            daq.endTask(obj.counterScanSPCMTask);
            daq.endTask(obj.counterScanTimeTask);
        end
        
        function setSPCMEnable(obj, newBooleanValue)
            % Enables/Disables the SPCM.
            daq = getObjByName(NiDaq.NAME);
            daq.writeDigital(obj.niDaqGateChannelName, newBooleanValue)
        end
    end
    
    methods
        function onNiDaqReset(obj, niDaq)
            % This function jumps when the NiDaq resets
            if obj.nScanCounts > 0
                prepareReadByStageInternal(obj, niDaq);
            end
        end
    end
  
    methods(Static = true)
        function spcmObj = create(spcmName, spcmStruct)
            missingField = FactoryHelper.usualChecks(spcmStruct, NiDaqControlledSpcm.NEEDED_FIELDS);
            if ~isnan(missingField)
                error('can''t init NiDaq-controlled SPCM - field "%s" not found in initation struct!', missingField);
            end
            counts = spcmStruct.nidaq_channel_counts;
            gate = spcmStruct.nidaq_channel_gate;
            spcmObj = NiDaqControlledSpcm(spcmName, gate, counts);
        end
    end
    
    
    methods (Access = protected)
        function prepareReadByStageInternal(obj, niDaq)
            % Creates the measurment in the DAQ according to the parameters
            % in the object.
            if obj.fastScan
                obj.counterScanSPCMTask = niDaq.CreateDAQEdgeCountingMeas(obj.nScanCounts, obj.niDaqCountChannelName, obj.stageName);
                obj.counterScanTimeTask = niDaq.CreateDAQEdgeCountingMeas(obj.nScanCounts, niDaq.CHANNEL_100MHZ, obj.stageName);
            else
                obj.counterScanSPCMTask = niDaq.CreateDAQPulseWidthMeas(obj.nScanCounts, obj.niDaqCountChannelName, obj.stageName);
                obj.counterScanTimeTask = niDaq.CreateDAQPulseWidthMeas(obj.nScanCounts, niDaq.CHANNEL_100MHZ, obj.stageName);
            end
        end
    end
end