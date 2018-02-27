classdef NiDaq < EventSender
    %NiDaq Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dummyMode;  	% logical. if set to true nothing will actually be passed
        dummyChannel    % vector of doubles. Saves value of write channels, for dummy mode
        
        channelArray
        % 2D array.         (Better make it a struct, when we get to it)
        % 1st column - channels ('dev/...')
        % 2nd column - channel names ('laser green')
        % 3rd column - channel minimum value. by default it is 0.
        % 4th column - channel maximum value. by default it is 1.
        
        deviceName  % string. is used by the library functions
    end
    
    properties (Constant, Hidden)
       IDX_CHANNEL = 1;
       IDX_CHANNEL_NAME = 2;
       IDX_CHANNEL_MIN = 3;
       IDX_CHANNEL_MAX = 4;
       
       MAX_VOLTAGE = 10;
       MIN_VOLTAGE = -10;
       DEFAULT_MIN_VOLTAGE = 0;
       DEFAULT_MAX_VOLTAGE = 1;
       
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
            obj.channelArray = {};
            
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
            % niDaqStruct can have a 'dummy' logical property called
            % "dummy". If set to true, no actual physics will be involved.
            % Good for testing purposes.
            % The default value (if it doesn't exist in struct) is false.
            %
            missingField = FactoryHelper.usualChecks(niDaqStruct, {'deviceName'});
            if ~isnan(missingField)
                error('Can''t find the reserved word "%s" in the niDaq struct', missingField);
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
        function registerChannel(obj, newChannel, newChannelName, minValueOptional, maxValueOptional)
            % We accept also empty values for minValueOptional &
            % maxValueOptional, which allows us to  tell the function to
            % use default values for any of the optional variables
            if exist('minValueOptional', 'var') && ~isempty(minValueOptional)
                minValue = minValueOptional;
            else
                minValue = obj.DEFAULT_MIN_VOLTAGE;
            end
            if exist('maxValueOptional', 'var') && ~isempty(maxValueOptional)
                maxValue = maxValueOptional;
            else
                maxValue = obj.DEFAULT_MAX_VOLTAGE;
            end
            
            if isempty(obj.channelArray)
                obj.channelArray{end + 1, NiDaq.IDX_CHANNEL} = newChannel;
                obj.channelArray{end, NiDaq.IDX_CHANNEL_NAME} = newChannelName;
                obj.channelArray{end, NiDaq.IDX_CHANNEL_MIN} = minValue;
                obj.channelArray{end, NiDaq.IDX_CHANNEL_MAX} = maxValue;
                return
            end
                
            channelAlreadyInIndexes = ...
                find(...
                    contains(...
                        obj.channelArray(1:end, NiDaq.IDX_CHANNEL), ...
                        newChannel...
                    )...
                );
            if ~isempty(channelAlreadyInIndexes)
                errorMsg = 'Can''t assign channel "%s" to "%s", as it has already been captured by "%s"!';
                channelIndex = channelAlreadyInIndexes(1);
                channelCapturedName = obj.getChannelNameFromIndex(channelIndex);
                error(errorMsg, newChannel, newChannelName, channelCapturedName);
            end
            obj.channelArray{end + 1, NiDaq.IDX_CHANNEL} = newChannel;
            obj.channelArray{end, NiDaq.IDX_CHANNEL_NAME} = newChannelName;
            obj.channelArray{end, NiDaq.IDX_CHANNEL_MIN} = minValue;
            obj.channelArray{end, NiDaq.IDX_CHANNEL_MAX} = maxValue;
            
            if obj.dummyMode    % If we are in dummy mode, we want to have default value for value;
                obj.dummyChannel(length(obj.channelArray)) = -1;
            end
        end % func registerChannel
        
        function voltageInt = readVoltage(obj, channelOrChannelName)
            % Reads the voltage at the given channel
            channelIndex = obj.getIndexFromChannelOrName(channelOrChannelName);
            channel = obj.getChannelFromIndex(channelIndex);
            minVal = obj.getChannelMinimumFromIndex(channelIndex);
            maxVal = obj.getChannelMaximumFromIndex(channelIndex);
            
            if obj.dummyMode
                val = obj.dummyChannel(channelIndex);
                if val == -1 % read channel
                    voltageInt = 0.5;
                else    % write channel -- we have value to return
                    voltageInt = val;
                end
                return
            end
            
            % DAQ Constants
            terminalConfig =  daq.ni.NIDAQmx.DAQmx_Val_RSE;
            units =           daq.ni.NIDAQmx.DAQmx_Val_Volts;
            fillmode =        daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber;
            
            % Settings for virtual channel - reading from output channel
            if contains(channel, '/ao')
                channel = regexprep(channel, 'ao(\d+)', '_ao$1_vs_aognd');
                terminalConfig = daq.ni.NIDAQmx.DAQmx_Val_Diff;
            end
            
            % Create channel
            task = obj.createTask();
            physicalChannel = sprintf('/%s/%s', obj.deviceName, channel);
            nameToAssignToChannel = '';
            customScaleName = '';
            status = DAQmxCreateAIVoltageChan(task, physicalChannel, nameToAssignToChannel, terminalConfig, minVal, maxVal, units, customScaleName);
            obj.checkError(status);
            
            % Read from channel
            obj.startTask(task);
            
            numSampsPerChan = 1;
            timeout = 1;
            readArray = zeros(1, 1);
            arraySizeInSamps = 1;
            sampsPerChanRead = 0;   % dummy variable
            [status, voltageInt]= DAQmxReadAnalogF64(task, numSampsPerChan, timeout, fillmode, readArray, arraySizeInSamps, sampsPerChanRead);
            obj.checkError(status);
            
            obj.endTask(task);
        end
        
        function writeVoltage(obj, channelOrChannelName, newVoltage)
            % Writes the given voltage at the given channel
            channelIndex = obj.getIndexFromChannelOrName(channelOrChannelName);
            channel = obj.getChannelFromIndex(channelIndex);
            minVal = obj.getChannelMinimumFromIndex(channelIndex);
            maxVal = obj.getChannelMaximumFromIndex(channelIndex);
            
            if obj.dummyMode
                obj.dummyChannel(channelIndex) = newVoltage;
                return;
            end
            
            % DAQ constants
            units =       daq.ni.NIDAQmx.DAQmx_Val_Volts;
            dataLayout =  daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber;
            
            % Create channel
            task = obj.createTask();
            
            physicalChannel = sprintf('/%s/%s', obj.deviceName, channel);
            status = DAQmxCreateAOVoltageChan(task, physicalChannel, minVal, maxVal, units);
            obj.checkError(status);
            
            % Write to channel
            obj.startTask(task);
            
            numSampsPerChan = 1;
            autoStart = 1;
            timeout = 10;
            sampsPerChanWritten = 0;    % dummy variable (that is, has no meaning)
            status = DAQmxWriteAnalogF64(task, numSampsPerChan, autoStart, timeout, dataLayout, newVoltage, sampsPerChanWritten);
            obj.checkError(status);
            
            obj.endTask(task);
        end
        
        function digitalInt = readDigital(obj, channelOrChannelName)
            % Read the current digital status of the given channel
            channelIndex = obj.getIndexFromChannelOrName(channelOrChannelName);
            channel = obj.getChannelFromIndex(channelIndex);
            
            if obj.dummyMode
                digitalInt = true;
                return
            end
            
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
        
        function writeDigital(obj, channelOrChannelName, newLogicalValue)
            % Writes the given digital status at the given channel
            channelIndex = obj.getIndexFromChannelOrName(channelOrChannelName);
            channel = obj.getChannelFromIndex(channelIndex);
            
            if obj.dummyMode
                % Do nothing
                return
            end
            
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
        
        function task = CreateDAQPulseWidthMeas(obj, nCounts, countChannelName, pixelsChannelName, ctrNumberOpt)
            % Creates a pulse width measurement task
            % (countChannelName, countEdgeChannelName) use cases:
            % For counting photons by stage: (SPCM, Stages)
            % For counting time by stage: (NiDaq.CHANNEL_100MHZ, Stage)
            % For counting photons by time: (SPCM, NiDaq.CHANNEL_100kHZ)
            % ctrNumber can be 0 or 1, if not specified then it is 0.
            if ~exist('ctrNumberOpt', 'var')
                ctrNumberOpt = 0;
            end
            device = sprintf('/%s/Ctr%d', obj.deviceName, ctrNumberOpt);
            
            DAQmx_Val_Rising = daq.ni.NIDAQmx.DAQmx_Val_Rising; % Rising
            DAQmx_Val_FiniteSamps = daq.ni.NIDAQmx.DAQmx_Val_FiniteSamps; % Finite Samples
            DAQmx_Val_Seconds = daq.ni.NIDAQmx.DAQmx_Val_Seconds; % Seconds
            
            task = obj.createTask();
            
            status = DAQmxCreateCIPulseWidthChan(task, device, '', 0.000000100, 18.38860750, DAQmx_Val_Seconds, DAQmx_Val_Rising, '');
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
            
            [status, readArray, nRead] = DAQmxReadCounterU32(task, numSampsPerChan, ...
                timeout, readArray, arraySizeInSamps, sampsPerChanRead);
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
            channelNamesIndexes = find(contains(obj.channelArray(1:end, NiDaq.IDX_CHANNEL_NAME), channelOrChannelName));
            if ~isempty(channelNamesIndexes)
                index = channelNamesIndexes(1);
                return;
            end
            
            channelIndexes = find(contains(obj.channelArray(1:end, NiDaq.IDX_CHANNEL), channelOrChannelName));
            if ~isempty(channelIndexes)
                index = channelIndexes(1);
                return;
            end
            
            error('%s couldn''t find either channel or channel name "%s". Have you registered this channel?', obj.name, channelOrChannelName);
        end
        
        function channelName = getChannelNameFromIndex(obj, index)
            channelName = obj.channelArray{index, NiDaq.IDX_CHANNEL_NAME};
        end
        
        function channel = getChannelFromIndex(obj, index)
            channel = obj.channelArray{index, NiDaq.IDX_CHANNEL};
        end
        
        function min = getChannelMinimumFromIndex(obj, index)
            min = obj.channelArray{index, NiDaq.IDX_CHANNEL_MIN};
            if ~isnumeric(min)
                min = str2double(min);
            end
            if isnan(min)
                min = obj.DEFAULT_MIN_VOLTAGE;
            end
        end
        
        function max = getChannelMaximumFromIndex(obj, index)
            max = obj.channelArray{index, NiDaq.IDX_CHANNEL_MAX};
            if ~isnumeric(max)
                max = str2double(max);
            end
            if isnan(max)
                max = obj.DEFAULT_MAX_VOLTAGE;
            end
        end
    end
end