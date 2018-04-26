classdef PulseStreamer < handle
    % PulseStreamer is a wrapper class to communicate with the JSON-RPC
    % interface of the Pulse Streamer
    properties (Constant)
        version = 0.5;      % current version of the Pulse Streamer matlab driver
    end
    
    properties (SetAccess = private, GetAccess = public)
        ipAddress           % ip address of the Pulse Streamer
        sequenceStartMode   % method to start the sequence (PSStart enumeration)
        triggerEdge         % trigger edge type for external start (PSTriggerEdge enumeration)
        callbackFinished    % callback function called when the stream of the Pulse Streamer has finished
    end
    
    properties (Access = private)
        pollTimer           % poll timer to detect the start of the sequence
        finishedTimer       % triggers the external callback function
        wasRunning          % variable which stores the last state of the Pulse Streamer to detect the end of the sequences
        sequenceDuration    % length of the sequence in ns including multiple runs
        finishedFlag        % store internally whether the end of the sequence was reached
        nRuns               % store internally the number of runs
        initialOutputState  % store internally the initial state
        underflowOutputState% store internally the underflow state
        debugDepth          % maximum number of requests recorded
        debugFilename       % filename the requests will be recorded to
        debugBuffer         % buffer for stored requests
    end
    
    methods
        % constructor
        function obj = PulseStreamer(ipAddress)
            % ipAdress: hostname or ip address of the pulse streamer (e.g.
            % 'PulseStreamer' or '192.168.178.20')
            obj.debugDepth = 0;
            obj.ipAddress = ipAddress;
            try
                obj.isRunning();
            catch e
                showChars = min(150, length(e.message));
                error(['Could not connect to Pulse Streamer at "' ipAddress '". ' e.message(1:showChars) ' (...)'])
            end
        end
        
        %%%%%%%%%%%%%%%%%%%% wrapped JSON-RPC methods %%%%%%%%%%%%%%%%%%%%%%%%%%%
        function constant(obj, outputState)
            % set a constant output at the Pulse Streamer outputs
            if ~isa(outputState, 'OutputState')
                error('Invalid parameter: outputState must be an OutputState object!');
            end
            obj.stopTimer();
            obj.httpRequest(PulseStreamer.getJsonRpcRequest('constant', outputState.getJsonString()));
            obj.finishedFlag = true;
        end
        
        function rearm(obj)
            % reinitialize the most recent sequence uploaded and rearm
            % WARNING - METHOD NOT TESTET YET
            if (obj.sequenceDuration <= 0)
                error('No valid sequence on the device. cannot rearm!')
            end
            if ~isa(obj.initialOutputState,'OutputState') || ~isa(obj.underflowOutputState,'OutputState')
                error('Invalid parameter: initialState, and underflowState must be a OutputState object!');
            end
            if ~isa(obj.sequenceStartMode,'PSStart')
                error('Invalid parameter: startType must be a PSStart enumeration!');
            end
            if ~(obj.sequenceStartMode == PSStart.Hardware)
                error('Rearm is only supported for hardware trigger!');
            end
            obj.stopTimer();
            obj.wasRunning = false;
            obj.finishedFlag = false;
            obj.httpRequest(PulseStreamer.getJsonRpcRequest('stream', obj.initialOutputState.getJsonString(), obj.underflowOutputState.getJsonString(), num2str(obj.sequenceStartMode)));
            %if ~isempty(obj.callbackFinished) && nRuns > 0
            % this needs to change again if the hasFinished comes from the
            % FPGA itself
            %%% the callback timer is only started if a callback function
            %%% is set by the user and as long the sequence has no infinite runs
            if ~isempty(obj.callbackFinished) && (obj.nRuns > 0)
                obj.pollTimer = timer;
                obj.pollTimer.TimerFcn = @obj.callbackInternalTimer;
                obj.pollTimer.Period = 0.1; %s
                obj.pollTimer.ExecutionMode = 'fixedSpacing';

                start(obj.pollTimer);
            end
        end
        
        function timing = stream(obj, sequence, nRuns, initialState, finalState, underflowState, startType)
            % sends the sequence to the Pulse Streamer
            %  sequence:       PulseMessage object or cell array of PulseMessages
            %                  or PulseSequence or cell array of PulseSequences
            %  initalState:    OutputState object which defines the output
            %                  before the sequence starts
            %  finalState:     OutputState object which defines the output
            %                  after the sequence has ended
            %  underflowState: OutputState object which defines the output
            %                  if an data underflow inside the pulse
            %                  streamer happens
            %  startType:      PSStart enueration which defines how the
            %                  sequence is started
            
            tStart = tic;
            if ~isa(sequence, 'PH')
                error('Invalid parameter: sequence must be a P or PH object or an array of P or PH objects!');                
            end                
            if ~isa(initialState,'OutputState') || ~isa(finalState,'OutputState') || ~isa(underflowState,'OutputState')
                error('Invalid parameter: initialState, finalState and underflowState must be a OutputState object!');
            end
            if ~isa(startType,'PSStart')
                error('Invalid parameter: startType must be a PSStart enumeration!');
            end
            obj.stopTimer();
            obj.wasRunning = false;
            timing.ready = toc(tStart);
            encodedSequence = horzcat('"',sequence.json,'"');                
            timing.encoded = toc(tStart);
            obj.finishedFlag = false;
            numberOfPulses = (length(encodedSequence)-2) / 12;
            if numberOfPulses > 1000000
                error(['Maximum number of pulses within one run exceeded!  pulses: ' num2str(numberOfPulses) '  max: 1000000']);
            end
            json = PulseStreamer.getJsonRpcRequestStream(encodedSequence, nRuns, initialState.getJsonString(), finalState.getJsonString(), underflowState.getJsonString(), startType);
            timing.json = toc(tStart);
            obj.httpRequest(json);
            timing.http = toc(tStart);
            obj.sequenceStartMode = startType;
            obj.initialOutputState = initialState;
            obj.underflowOutputState = underflowState;
            obj.nRuns = nRuns;
            obj.sequenceDuration = P.duration(sequence) * nRuns;
            timing.sum = toc(tStart);
            %if ~isempty(obj.callbackFinished) && nRuns > 0
            % this needs to change again if the hasFinished comes from the
            % FPGA itself
            %%% the callback timer is only started if a callback function
            %%% is set by the user and as long the sequence has no infinite runs
            if ~isempty(obj.callbackFinished) && (nRuns > 0)
                obj.pollTimer = timer;
                obj.pollTimer.TimerFcn = @obj.callbackInternalTimer;
                obj.pollTimer.Period = 0.1; %s
                obj.pollTimer.ExecutionMode = 'fixedSpacing';

                start(obj.pollTimer);
            end
        end
        
        function startNow(obj)
            % starts the sequence if the sequence was uploaded with the
            % PSStart.Software option
            obj.httpRequest(PulseStreamer.getJsonRpcRequest('startNow'));
        end
        
        function setTrigger(obj, triggerEdge)
            % set the trigger edge if the sequence was uploaded with the
            % PSStart.Hardware option
            if ~isa(triggerEdge,'PSTriggerEdge')
                error('Invalid parameter for setTrigger. Use PSTriggerEdge enumeration.');
            end
            obj.httpRequest(PulseStreamer.getJsonRpcRequest('setTrigger', triggerEdge));
            obj.triggerEdge = triggerEdge;
        end
        
        function running = isRunning(obj)
            % check whether the Pulse Streamer is giving out streaming output
            ret = obj.httpRequest(PulseStreamer.getJsonRpcRequest('isRunning'));
            running = PulseStreamer.jsonToBool(ret);
        end
        
        function sequence = hasSequence(obj)
            % check whether a sequence was uploaded
            ret = obj.httpRequest(PulseStreamer.getJsonRpcRequest('hasSequence'));
            sequence = PulseStreamer.jsonToBool(ret);
        end
        
        function finished = hasFinished(obj)
            % check whether all sequences are finished
            finished = obj.finishedFlag;
            return
            %ret = obj.httpRequest(PulseStreamer.getJsonRpcRequest('hasFinished'));
            %finished = PulseStreamer.jsonToBool(ret);
        end
        
        function [underflow, underflowDigital, underflowAnalog] = getUnderflows(obj)
            % check whether an underflow in the Pulse Streamer occured
            % the underflow can happen indpendetly for digital or analog
            % outputs
            ret = obj.httpRequest(PulseStreamer.getJsonRpcRequest('getUnderflow'));
            underflows = PulseStreamer.jsonToUInt32(ret);
            underflow = underflows ~= 0;
            underflowDigital = underflows == 1 || underflows == 3;
            underflowAnalog = underflows == 2 || underflows == 3;
            if underflows > 3
                error('undefined return value');
            end
        end
        
        function value = getDebugRegister(obj)
            ret = obj.httpRequest(PulseStreamer.getJsonRpcRequest('getDebugRegister'));
            value = PulseStreamer.jsonToUInt32(ret);
        end
        
        function setDebugRegister(obj, value, mask)
            obj.httpRequest(PulseStreamer.getJsonRpcRequest('setDebugRegister', value, mask));
        end
        
        %function reset(obj)
        %    error('not implemented yet');
        %    % resets the Pulse Streamer device
        %    obj.stopTimer();
        %    obj.httpRequest(PulseStreamer.getJsonRpcRequest('reset'));
        %end
        
        %function idn = idn(obj)
        %    error('not implemented yet');
        %    % get MAC address and serial number from the Pulse Streamer
        %    obj.httpRequest(PulseStreamer.getJsonRpcRequest('idn'));
        %end
        
        function status(obj)
            % displays the current status of the Pulse Streamer
            tab = char(9);
            display(['running:', tab, PulseStreamer.boolToYesNo(isRunning(obj))]);
            display(['sequence:', tab, PulseStreamer.boolToYesNo(hasSequence(obj))]);
            [~, underflowDigital, underflowAnalog] = getUnderflows(obj);
            display(['underflow d:', PulseStreamer.boolToYesNo(underflowDigital)]);
            display(['underflow a:', PulseStreamer.boolToYesNo(underflowAnalog)]);
            display(['debug:', tab, tab, num2str(getDebugRegister(obj))]);
        end
        
        %%%%%%%% debugging methods %%%%%%%%%%%%%%%%%%%%%
        function enableDebugRecorder(obj, recordedRequests, filename)
            warning(['Recording the pulse streamer communication to file: ', filename]);
            obj.debugDepth = recordedRequests;            
            obj.debugFilename = filename;
            obj.debugBuffer.counter = 0;
            obj.debugBuffer.data = cell(1,recordedRequests);
        end

        %%%%%%%% callback function and event handling %%%%%%%%%%%%%%%%%%%%%
        function setCallbackFinished(obj, func)
            % sets the callback function to detect when the Pulse Streamer
            % is finished with all sequences
            % this must be set before the the sequence is started.
            % e.g. fun: @myCallbackFunction
            %
            % the signature of the callback function must be
            % callbackFunction( ~,~, pulseStreamer)
            
            % check whether the parameter is valid
            if ~isa(func,'function_handle')
                error('Callback function must be a function handle');
            end
            
            if ~(exist(func2str(func)) == 2)
                error(['Callback function not found. ' func2str(func)]);
            end
            obj.callbackFinished = func;
        end
    end
    
    methods (Access = private)        
        function callbackInternalTimer(obj, ~, ~)
            % Internal callback to check the status of the Pulse Streamer
            % and handling the external callback function.
            % The Pulse Streamer is polled only if the external callback function
            % is set by the user.
            %if ~isempty(obj.callbackFinished)
            % detect that the sequence is running
            % wasRunning == false && isRunning == true
            if ~obj.wasRunning
                if obj.isRunning()
                    obj.wasRunning = true;
                    % stop the poll timer
                    obj.stopTimer();
                    % we start a new timer with the known sequence
                    % duration
                    % minimum period according to matlab documentation is 0.001s
                    % and we should round up, this is why we add 0.0005
                    delay = round(max(0.001, double(obj.sequenceDuration) / 1e9 + 0.0005),3);
                    obj.finishedTimer = timer;
                    obj.finishedTimer.TimerFcn = @obj.callbackInternalFinished;
                    obj.finishedTimer.StartDelay = delay; %s
                    obj.finishedTimer.ExecutionMode = 'singleShot';
                    start(obj.finishedTimer);
                end
            end
            %end
            % this is the code if we implement it in the hardware
            % hasFinished = obj.hasFinished();
            % if hasFinished
            %    obj.callbackFinished();
            %    stop(obj.pollTimer);
            %    delete(obj.pollTimer);
            % end
        end
        
        function callbackInternalFinished(obj, ~, ~)
            % internal callback function which is called when the sequence
            % has ended
            obj.finishedFlag = true;
            if ~isempty(obj.callbackFinished)
                obj.callbackFinished(obj);
            end
        end
        
        function stopTimer(obj)
            %checks whether the timer is still alive and stops it
            if ~isempty(obj.pollTimer)
                stop(obj.pollTimer)
                delete(obj.pollTimer)
                obj.pollTimer = [];
            end
            if ~isempty(obj.finishedTimer)
                stop(obj.finishedTimer)
                delete(obj.finishedTimer)
                obj.finishedTimer = [];
            end
        end
        %%%%%%%%%%%%%%%%%%%% internal methods  %%%%%%%%%%%%%%%%%%%%%%%%%%%
        function ret = httpRequest(obj, req)
            if obj.debugDepth > 0
                buffer = obj.debugBuffer;
                buffer.counter = buffer.counter + 1;
                data = circshift(buffer.data,1);
                data{1} = {now, req};
                buffer.data = data;
                obj.debugBuffer = buffer;
                save(obj.debugFilename, 'buffer')
            end
            % http handling
            url = strcat('http://',obj.ipAddress,':8050/json-rpc');
            % set the timeout to 3s
            ret = urlread2(url, 'POST', req, []);            
        end
    end
    
    methods (Static, Access = public)
        function jsonString = getJsonRpcRequest(method, varargin)
            % create a JSON-RPC call
            % method:   name of the RPC call method
            % varagin:  arbitary number of arguments (string or numeric)
            if nargin == 1
                s = strcat('{"jsonrpc":"2.0","id":"1","method":"',method,'"}');
            else
                s = strcat('{"jsonrpc":"2.0","id":"1","method":"',method,'","params":[');
                for i = 1:length(varargin)
                    p = varargin{i};
                    if isnumeric(p)
                        p = num2str(p);
                    end
                    s = strcat(s, p, ',');
                end
                s = strcat(s(1:end-1),']}');
            end
            jsonString = s;
        end

        function jsonString = getJsonRpcRequestStream(encodedSequence, nRuns, initialState, finalState, underflowState, startType)
            % create a JSON-RPC call - optimized for stream
            jsonString = strcat('{"jsonrpc":"2.0","id":"1","method":"stream","params":[', encodedSequence, ',', num2str(nRuns), ',', initialState, ',', finalState, ',', underflowState, ',', num2str(startType), ']}');
        end
        
        function stru = jsonToStruct(string)
            % converts the returned string from an JSON-RPC call to
            % a struct
            stru = parse_json(string);
            stru = stru{1};
        end
        
        function bool = jsonToBool(string)
            % converts the returned string from an JSON-RPC call to
            % a boolean value
            stru = PulseStreamer.jsonToStruct(string);
            if stru.result == 0
                bool = false;
            elseif stru.result == 1
                bool = true;
            else
                error(['return value is not a boolean (0 or 1) but ' num2str(stru.result)]);
            end
        end
        
        function value = jsonToUInt32(string)
            % extracts the returned value from an JSON-RPC call and
            % converts it into a uint32
            stru = PulseStreamer.jsonToStruct(string);
            value = uint32(stru.result);
        end
        
        function c = replace(c,ins,idx)
            c = [c(1:idx-1) ins c(idx+1:end)];
        end
        
        function seqs = split(seq)
            seqs = cell(1,ceil(seq.ticks / 2000000));
            for i=1:length(seqs)-1
                seqs{i} = seq.clone();
                seqs{i}.ticks = uint64(2000000);
            end
            seqs{end} = seq.clone();
            seqs{end}.ticks = mod(seq.ticks, 2000000);
        end
        
        function encodedSequence = encodeSequence(seqs)
            % Convert the sequence into the binary format required.
            % Naitive java is used to do the base64 encoding.
            % seq can either be a PulseMessage or a cell array of
            % PulseMessages
            
            error(javachk('jvm'));

            % split pulses > 2s
            if isa(seqs, 'cell')
                i = 1;
                while true
                    if seqs{i}.ticks > 2000000
                        seqs = PulseStreamer.replace(seqs, PulseStreamer.split(seqs{i}), i);
                    end
                    i = i + 1;
                    if i > length(seqs)
                        break;
                    end
                end
            else
                if seqs.ticks(seqs.ticks > 2000000) 
                    seqs = PulseStreamer.split(seqs);
                end
            end

            n_pulses = length(seqs);
            bufferSize = n_pulses*9;
            
            byteBuffer = java.nio.ByteBuffer.allocate(bufferSize);

            for i = 1:n_pulses
                if ~(isa(seqs, 'cell'))
                    seq = seqs;
                else
                    seq = seqs{i};
                end
                ticks = uint32(seq.ticks);
                digi = seq.digi;
                ao0 = seq.ao0;
                ao1 = seq.ao1;
                byteBuffer.putInt(ticks);
                byteBuffer.put(java.lang.Byte(digi).byteValue());
                byteBuffer.putShort(ao0);
                byteBuffer.putShort(ao1);                
            end
            encodedSequence = transpose(char(org.apache.commons.codec.binary.Base64.encodeBase64(byteBuffer.array(), 0)));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%% string handling %%%%%%%%%%%%%%%%%%%%%%%%%%
        function str = boolToYesNo(bool)
            % converts a boolean value into a 'Yes' or 'No' string
            if bool == 0
                str = 'no';
            elseif bool == 1
                str = 'yes';
            else
                error('not a boolean value');
            end
        end
    end
end

