classdef (Sealed) PulseStreamerClass < PulseGenerator
    
    properties (Constant, Hidden)
%         TOTAL_CHANNEL_NUMBER = 8;	% int. channels are indexed (1:obj.TOTAL_CHANNEL_NUMBER)
        MAX_REPEATS = Inf;       	% int. Maximum value for obj.repeats
        MAX_PULSES = 10e6;          % int. Maximum number of pulses in acceptable sequences
        MAX_DURATION = Inf;         % double. Maximum duration of pulse.
        
        AVAILABLE_ADDRESSES = 0:8;	% List of all available physical addresses.
                                    % Should be either vector of doubles or cell of char arrays
        NEEDED_FIELDS = {'ipAddress', 'debugPath'}
    end
    
    properties (Access = private)
        ps          % PulseStreamer object. Scalar local variable for communication with PS.
        trigger     % PSStart object. Probably either hardware or software.
    end
    
    %% 
    methods (Access = private)
        function obj = PulseStreamerClass()
            % Private default constructor
            obj@PulseGenerator;
            obj.trigger = PSStart.Hardware; % can be 'Software' or 'Hardware'
        end
        
        function Initialize(obj, ip, debugPath)
            obj.ps = PulseStreamer(ip);
            obj.ps.enableDebugRecorder(1000, debugPath);
            obj.sequence = Sequence;
        end
    end
    
    %% Channel operation
    methods
        function on(obj, channels)
            obj.On(channels);
        end
        
        function off(obj)
            obj.Off;
        end
        
        function run(obj)
            obj.uploadSequence;
            if obj.trigger == PSStart.Software
                obj.ps.startNow;
            end
        end
        
        function validateSequence(obj)
            if obj.sequenceInMemory && obj.trigger == PSStart.Hardware
                obj.ps.rearm();
                return
            end
            if isempty(obj.sequence)
                error('Cannot upload empty sequence!')
            end
            
            pulses = obj.sequence.pulses;
            for i = 1:length(pulses)
                onCh = pulses(i).getOnChannels;
                mNames = obj.channelNames;
                for j = 1:length(onCh)
                    chan = onCh{j};
                    if ~contains(mNames, chan)
                        errMsg = sprintf('Channel %s could not be found! Aborting.', chan);
                        obj.sendError(errMsg)
                    end
                end
                
                % Consider:
                %       values = round(values); ! 
                % (why was it here to begin with? are there analog channels?)
            end
        end
        
        function sendToHardware(obj)
            % Creates sequence in form legible to hardware
            outputZero = OutputState(0,0,0);
            initialOutputState = outputZero;
            finalOutputState = outputZero;
            underflowOutputState = outputZero;
            start = obj.trigger;
            
            % settings for sequence generation
            numberOfSequences = length(obj.sequence.pulses);
            sequences = [];
            for i = 1:numberOfSequences
                p = obj.sequence.pulses(i);
                onChannels = obj.name2index(p.onChannels);
                newSequence = P(p.duration * 1e3, onChannels, 0, 0);
                sequences = sequences + newSequence;
            end
            obj.ps.stream(sequences, obj.repeats, initialOutputState, finalOutputState, underflowOutputState, start);
        end
    end
    
    %% Old methods
        methods
        function channels = On(obj, channels)
            % Turns on channels specified b yname.
            % Also outputs channels to be opened (0,1,2,...,), as a double
            % vector            
            channels = obj.channelName2Address(channels); %converts from a cell of names to channel numbers, if needed
            if isempty(channels)
                channels = 0;
            else
                if sum(rem(channels,1)) || min(channels) <0 || max(channels)> max(obj.AVAILABLE_ADDRESSES)
                    error('Input must be integers from 0 to %f', obj.maxDigitalChannels)
                end
                channels = sum(2.^channels);
            end
            
            output = OutputState(channels,0,0);
            obj.ps.constant(output);
        end
        
        function Off(obj)
            output = OutputState(0,0,0);
            obj.ps.constant(output);
        end
    end
    
    %% Get instance constructor
    methods (Static, Access = public)
        function obj = getInstance(struct)
            % Returns a singelton instance.
            try
                obj = getObjByName(PulseGenerator.NAME_PULSE_STREAMER);
            catch
                % None exists, so we create a new one
                missingField = FactoryHelper.usualChecks(struct, PulseStreamerClass.NEEDED_FIELDS);
                if ~isnan(missingField)
                    error('Error while creating a PulseStreamer object: missing field "%s"!', missingField);
                end
                
                obj = PulseStreamerClass();
                ip = struct.ipAddress;
                debugPath = struct.debugPath;
                Initialize(obj, ip, debugPath)
                
                addBaseObject(obj);
            end
        end
    end
end