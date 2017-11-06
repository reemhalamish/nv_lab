classdef NiDaq < EventSender
    %NiDaq Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dummyMode;
        % logical. if set to true nothing will actually be passed
        
        channelsToChannelNames
        % 2D array. 
        % first column - channels ('dev/...')
        % second column - channel names ('laser green')
        
        deviceName
        % string. is used by the library functions
    end
    
    properties(Constant = true, Hidden = true)
       IDX_CHANNEL = 1;
       IDX_CHANNEL_NAME = 2;
       
       MAX_VOLTAGE = 10;
       MIN_VOLTAGE = -10;
       
       CHANNEL_100MHZ = '100MHz';
       CHANNEL_100kHZ = '100kHz';
    end
    properties(Constant = true)
        NAME = 'NiDaq';
        
        EVENT_NIDAQ_RESET = 'Ni_Daq_reset';
    end
    
    methods(Access = protected)
        function obj = NiDaq(deviceName, dummyModeBoolean)
            obj@EventSender(NiDaq.NAME);
            addBaseObject(obj);  % so it can be reached by getObjByName()
            obj.channelsToChannelNames = {};
            
            % Internal channels that are being used by someone
            obj.registerChannel('100MHzTimebase', obj.CHANNEL_100MHZ)
            obj.registerChannel('100kHzTimebase', obj.CHANNEL_100kHZ)
            
            obj.dummyMode = dummyModeBoolean;
            obj.deviceName = deviceName;
            if ~dummyModeBoolean
                LoadNIDAQmx;
            end
            
        end
    end
  
    methods(Static)
        function obj = create(niDaqStruct) %#ok<*INUSD>
            % this method is used to load the NiDAQ as new
            %
            % the "niDaqStruct" HAS TO HAVE this property (or an error will be thrown):
            % "deviceName" - a string
            %
            % the niDaqStruct can have a 'dummy' property which called
            % "dummy" - which is a boolean. 
            % if set to true, no actual physics will be
            % involved. good for testing purposes. 
            % if not exists, treated like a false
            %
            missingField = FactoryHelper.usualChecks(niDaqStruct, {'deviceName'});
            if ~isnan(missingField)
                error('Can''t find the preserved word "%s" in the niDaq struct', missingField);
            end
            if isfield(niDaqStruct, 'dummy')
                dummy = niDaqStruct.dummy;
            else
                dummy = false;
            end
            removeObjIfExists(NiDaq.NAME); 
            obj = NiDaq(niDaqStruct.deviceName,dummy);
        end
    end
    
    methods
        function registerChannel(obj, newChannel, newChannelName)
            if isempty(obj.channelsToChannelNames)
                obj.channelsToChannelNames{end + 1, NiDaq.IDX_CHANNEL} = newChannel;
                obj.channelsToChannelNames{end, NiDaq.IDX_CHANNEL_NAME} = newChannelName;
                return
            end
                
            channelAlreadyInIndexes = ...
                find(...
                    contains(...
                        obj.channelsToChannelNames(1:end, NiDaq.IDX_CHANNEL), ...
                        newChannel...
                    )...
                );
            if ~isempty(channelAlreadyInIndexes)
                errorMsg = 'Can''t assign channel "%s" to "%s", as it has already been captured by "%s"!';
                channelIndex = channelAlreadyInIndexes(1);
                channelCapturedName = obj.getChannelNameFromIndex(channelIndex);
                error(errorMsg, newChannel, newChannelName, channelCapturedName);
            end
            obj.channelsToChannelNames{end + 1, NiDaq.IDX_CHANNEL} = newChannel;
            obj.channelsToChannelNames{end, NiDaq.IDX_CHANNEL_NAME} = newChannelName;
        end % func registerChannel
        
        function voltageInt = readVoltage(obj, channelOrChannelName)
            % Reads the voltage at the given channel
            channelIndex = obj.getIndexFromChannelOrName(channelOrChannelName);
            channel = obj.getChannelFromIndex(channelIndex);
            if obj.dummyMode
                voltageInt = 0.5;
            else
                DAQmx_Val_RSE = daq.ni.NIDAQmx.DAQmx_Val_RSE;
                DAQmx_Val_Volts = daq.ni.NIDAQmx.DAQmx_Val_Volts;
                DAQmx_Val_GroupByScanNumber = daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber;
                
                task = obj.createTask();
                
                status = DAQmxCreateAIVoltageChan(task, sprintf('/%s/%s', obj.deviceName, channel), '', DAQmx_Val_RSE, 0, 1, DAQmx_Val_Volts, '');
                obj.checkError(status);
                
                obj.startTask(task);
                
                readArray = zeros(1, 1);
                [status, voltageInt]= DAQmxReadAnalogF64(task, 1, 1, DAQmx_Val_GroupByScanNumber, readArray, 1, int32(0));
                obj.checkError(status);
                
                obj.endTask();
            end
        end
        
        function writeVoltage(obj, channelOrChannelName, newVoltage)
            % Writes the given voltage at the given channel
            channelIndex = obj.getIndexFromChannelOrName(channelOrChannelName);
            channel = obj.getChannelFromIndex(channelIndex);
            if obj.dummyMode
                % Do Nothing
            else
                DAQmx_Val_Volts = daq.ni.NIDAQmx.DAQmx_Val_Volts;
                DAQmx_Val_GroupByScanNumber = daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber;
                
                task = obj.createTask();
                
                status = DAQmxCreateAOVoltageChan(task, sprintf('/%s/%s', obj.deviceName, channel), 0, 1, DAQmx_Val_Volts);
                obj.checkError(status);
                
                obj.startTask(task);
                
                status = DAQmxWriteAnalogF64(task, 1, 1, 10, DAQmx_Val_GroupByScanNumber, newVoltage, 0);
                obj.checkError(status);
                
                obj.endTask();
            end
        end
        
        function digitalInt = readDigital(obj, channelOrChannelName)
            % Read the current digital status of the given channel
            channelIndex = obj.getIndexFromChannelOrName(channelOrChannelName);
            channel = obj.getChannelFromIndex(channelIndex);
            if obj.dummyMode
                digitalInt = true;
            else
                DAQmx_Val_ChanForAllLines = daq.ni.NIDAQmx.DAQmx_Val_ChanForAllLines;
                DAQmx_Val_GroupByChannel = daq.ni.NIDAQmx.DAQmx_Val_GroupByChannel;
                
                task = obj.createTask();
                
                status = DAQmxCreateDOChan(task, sprintf('/%s/%s', obj.deviceName, channel), '', DAQmx_Val_ChanForAllLines);
                obj.checkError(status);
                
                obj.startTask(task);
                
                % todo - check read function (probably it is wrong now)
                [status, digitalInt] = DAQmxReadDigitalU32(task, 1, 1, DAQmx_Val_GroupByChannel, gate*2^line, 1);
                
                obj.checkError(status);
                
                obj.endTask(task);
            end
        end
        
        function writeDigital(obj, channelOrChannelName, newLogicalValue)
            % Writes the given digital status at the given channel
            channelIndex = obj.getIndexFromChannelOrName(channelOrChannelName);
            channel = obj.getChannelFromIndex(channelIndex);
            if obj.dummyMode
                % Do nothing
            else
                DAQmx_Val_ChanForAllLines = daq.ni.NIDAQmx.DAQmx_Val_ChanForAllLines;
                DAQmx_Val_GroupByChannel = daq.ni.NIDAQmx.DAQmx_Val_GroupByChannel;
                
                task = obj.createTask();
                
                status = DAQmxCreateDOChan(task, sprintf('/%s/%s', obj.deviceName, channel), '', DAQmx_Val_ChanForAllLines);
                obj.checkError(status);
                line = str2double(channel(end));
                
                obj.startTask(task);
                               
                status = DAQmxWriteDigitalU32(task, 1, 1, 10, DAQmx_Val_GroupByChannel, newLogicalValue*2^line, 1);
                obj.checkError(status);
                
                obj.endTask(task);
            end
        end
        
        function task = CreateDAQEdgeCountingMeas(obj, nCounts, countChannelName, pixelsChannelName, ctrNumberOpt)
            % Creates an edge counting measurement task.
            % (countChannelName, countEdgeChannelName) use cases:
            % For counting photons by stage: (SPCM, Stage)
            % For counting time by stage: (NiDaq.CHANNEL_100MHZ, Stage)
            % For counting photons by time: (SPCM, NiDaq.CHANNEL_100kHZ)
            % ctrNumber can be 0 or 1, if not specified then it is 0.
            if ~exist('ctrNumberOpt', 'var')
                ctrNumberOpt = 0;
            end
            device = sprintf('/%s/Ctr%d', obj.deviceName, ctrNumberOpt);
            
            DAQmx_Val_Rising = daq.ni.NIDAQmx.DAQmx_Val_Rising;
            DAQmx_Val_Falling = daq.ni.NIDAQmx.DAQmx_Val_Falling;
            DAQmx_Val_ContSamps = daq.ni.NIDAQmx.DAQmx_Val_ContSamps;
            DAQmx_Val_CountUp = daq.ni.NIDAQmx.DAQmx_Val_CountUp;
            
            task = obj.createTask();
            
            status = DAQmxCreateCICountEdgesChan(task, device, '', DAQmx_Val_Rising, 0, DAQmx_Val_CountUp);
            obj.checkError(status);
            
            pixelsChannel = obj.getChannelFromIndex(obj.getIndexFromChannelOrName(pixelsChannelName));
            switch pixelsChannelName
                case obj.CHANNEL_100kHZ
                    sampleRate = 100e3;
                otherwise
                    sampleRate = 1e6;
            end
            status = DAQmxCfgSampClkTiming(task, sprintf('/%s/%s', obj.deviceName, pixelsChannel), sampleRate, DAQmx_Val_Falling, DAQmx_Val_ContSamps, nCounts);
            obj.checkError(status);
            
            countChannel = obj.getChannelFromIndex(obj.getIndexFromChannelOrName(countChannelName));
            status = DAQmxSet(task, 'CI.CountEdgesTerm', device, sprintf('/%s/%s', obj.deviceName, countChannel));
            obj.checkError(status);
        end
        
        function task = CreateDAQPulseWidthMeas(obj, nCounts, countChannelName, pixelsChannelName)
            % Creates a pulse width measurement task
            % (countChannelName, countEdgeChannelName) use cases:
            % For counting photons by stage: (SPCM, Stages)
            % For counting time by stage: (NiDaq.CHANNEL_100MHZ, Stage)
            % For counting photons by time: (SPCM, NiDaq.CHANNEL_100kHZ)
            
            DAQmx_Val_Rising = daq.ni.NIDAQmx.DAQmx_Val_Rising; % Rising
            DAQmx_Val_FiniteSamps = daq.ni.NIDAQmx.DAQmx_Val_FiniteSamps; % Finite Samples
            DAQmx_Val_Seconds = daq.ni.NIDAQmx.DAQmx_Val_Seconds; % Seconds
            
            task = obj.createTask();
            
            status = DAQmxCreateCIPulseWidthChan(task, obj.deviceName, '', 0.000000100, 18.38860750, DAQmx_Val_Seconds, DAQmx_Val_Rising, '');
            obj.checkError(status);
            
            status = DAQmxCfgImplicitTiming(task, DAQmx_Val_FiniteSamps , nCounts);
            obj.checkError(status);
            
            countChannelName = obj.getChannelFromIndex(obj.getIndexFromChannelOrName(countChannelName));
            DAQmxSet(task, 'CI.CtrTimebaseSrc', device, sprintf('/%s/%s', obj.deviceName, countChannelName));
            obj.checkError(status);
            
            pixelsChannel = obj.getChannelFromIndex(obj.getIndexFromChannelOrName(pixelsChannelName));
            DAQmxSet(task, 'CI.PulseWidthTerm', device, sprintf('/%s/%s', obj.deviceName, pixelsChannel));
            obj.checkError(status);
                       
            status = DAQmxSet(task, 'CI.DupCountPrevent', device, 1);
            obj.checkError(status);
        end
        
        function [readArray, nRead] = ReadDAQCounter(obj, task, nCounts, timeout)
            numSampsPerChan = nCounts;
            readArray = zeros(1, nCounts);
            arraySizeInSamps = nCounts;
            sampsPerChanRead = int32(0);
            
            [status, readArray, nRead] = DAQmxReadCounterU32(task, numSampsPerChan, timeout, readArray, arraySizeInSamps, sampsPerChanRead);
            obj.checkError(status);
        end
        
        function startTask(obj, task)
            status = DAQmxStartTask(task);
            obj.checkError(status)
        end
        
        function endTask(obj, task)
            obj.stopTask(task);
            obj.clearTask(task)
        end
        
    end % methods
    
    methods(Access = protected)
        % helper methods
        function checkError(obj, status)
            % Checks for DAQ errors according to the status and sends an error event.
            if status ~= 0
                bufferSize = uint32(500);
                errorString = char(ones(1,bufferSize));
                [statusInternal, errorString]=daq.ni.NIDAQmx.DAQmxGetErrorString(status, errorString, bufferSize);
                obj.reset;
                if statusInternal ~= 0 || isempty(errorString)
                    obj.sendError(['NIDAQ Error ' num2str(status)])
                else
                    obj.sendError(['NIDAQ Error ' num2str(status) ':' errorString]);
                end
            end
%             lh = addlistener(s,'ErrorOccurred' @(src,event), disp(getReport(event.Error)));
        end
        
        function reset(obj)
            DAQmxResetDevice(obj.deviceName);
            fprintf('DAQ Card Ready! (reset)\n');
            obj.sendEvent(struct(NiDaq.EVENT_NIDAQ_RESET, true));
        end
        
        function task = createTask(obj)
            [status, ~, task] = DAQmxCreateTask([]);
           obj.checkError(status);
        end
        
        function stopTask(obj, task)
            status = DAQmxStopTask(task);
            obj.checkError(status)
        end
        
        function clearTask(obj, task)
            status = DAQmxClearTask(task);
            obj.checkError(status)
        end
        
        function index = getIndexFromChannelOrName(obj, channelOrChannelName)
            channelNamesIndexes = find(contains(obj.channelsToChannelNames(1:end, NiDaq.IDX_CHANNEL_NAME), channelOrChannelName));
            if ~isempty(channelNamesIndexes)
                index = channelNamesIndexes(1);
                return;
            end
            
            channelIndexes = find(contains(obj.channelsToChannelNames(1:end, NiDaq.IDX_CHANNEL), channelOrChannelName));
            if ~isempty(channelIndexes)
                index = channelIndexes(1);
                return;
            end
            
            error('%s couln''t find channel nor channel name "%s". have you registered this channel?', obj.name, channelOrChannelName);
        end
        
        function channelName = getChannelNameFromIndex(obj, index)
            channelName = obj.channelsToChannelNames{index, NiDaq.IDX_CHANNEL_NAME};
        end
        
        function channel = getChannelFromIndex(obj, index)
            channel = obj.channelsToChannelNames{index, NiDaq.IDX_CHANNEL};
        end
    end
end