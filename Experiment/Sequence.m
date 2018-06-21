classdef Sequence < handle
    %SEQUENCE Ordered set pulses, each with settings for a number of channels
    %   To be interpreted by a pulse generator (PulseBlaster or
    %   PulseStreamer).
    %   The set of sequences has the nice property of being closed under
    %   addition (concatenation). Multiplication by scalar is defined only
    %   for integers, as repeated addition.
    
    properties (SetAccess = private)
        pulses = [];	% array of Pulses.
    end
    
    methods
        function obj = Sequence(varargin)
            % Optional input parameters: Pulses to create the Sequence with
            % This also acts as casting a pulse into a sequence
            obj@handle;
            isPulse = @(x) isa(x, 'Pulse');
            isInputValid = all(cellfun(isPulse, varargin));
            if isInputValid
                obj.pulses = [varargin{:}];
            else
                EventStation.anonymousWarning(['All inputs to Sequence constructor must be of class ''Pulse''! ', ...
                    'Sequence was created empty.'])
            end
        end
        
        % Get methods
        function time = duration(obj)
            if isempty(obj.pulses)
                time = 0;
            else
                time = sum([obj.pulses.duration]);
            end
        end
        
        function timeVector = edgeTimes(obj)
            timeVector = cumsum([obj.pulses.duration]);
            timeVector = [0 timeVector];    % By definition, we always have an edge there
        end
        
        function names = nicknames(obj)
            names = {obj.pulses.nickname};
            names = unique(names);
        end
    end

    %% Manage Pulses
    methods
        function addPulse(obj, pulse)
            assert(isa(pulse, 'Pulse'))
            obj.pulses = [obj.pulses pulse];
        end
        
        function obj = addPulseAtGivenTime(obj, time, pulse)
            % Insert given pulse at required time ("squeeze" in between
            % other pulses), if needed. We might need to add a dummy pulse
            % between the sequence and the new pulse.
            
            assert(isa(pulse, 'Pulse'))
            p = Sequence(pulse);    % Sequence of a single pulse
            pulseDuration = p.duration;
            seqDuration = obj.duration;
            
            % Timeline visualization of cases:
            % (each |##| represents a pulse)
            %                 0                seqDuration  
            % obj = ----------|###|#####|##|###|------------
            %                 |                |
            %              time                |                       0   |time|            seqDuration+|time|
            % (1): --------|####|--------------|------------  -->  ----|####|###|#####|##|###|-------------------------
            %        time     |                |                       0       |time|            seqDuration+|time|
            % (2): --|####|---|----------------|------------  -->  ----|####|---|###|#####|##|###|---------------------
            %                 |                |    time               0                sD   time
            % (3): -----------|----------------|----|####|--  -->  ----|###|#####|##|###|----|####|--------------------
            %                 |              time                      0              time    seqDuration+pulseDuration
            % (4): -----------|--------------|####|---------  -->  ----|###|#####|##|#|####|##|------------------------
            
            if time <= 0 && pulseDuration >= abs(time) %     (1)
                    obj = p + obj;
            elseif time < 0 % && pulseDuration < abs(time)   (2)
                    p0 = Sequence(Pulse(time-pulseDuration)); % Singleton Sequence of "empty" interval in between
                    obj = p + p0 + obj;
            elseif time > seqDuration %                      (3)
                p0 = Sequence(Pulse(seqDuration-time)); % Singleton Sequence of "empty" interval in between
                obj = obj + p0 + p;
            else %                                           (4)
                [S1, S2] = obj.splitByTime(time);
                obj = S1 + p + S2;
            end
        end
        
        function addEvent(obj, duration, channelNames)
            p = Pulse(duration, channelNames);    % New pulse. No nickname here
            obj.addPulse(obj, p);
        end
        
        function addEventAtGivenTime(obj, time, duration, channelNames)
            % Creates a pulse, and adds it to the sequence
            p = Pulse(duration, channelNames);    % New pulse. No nickname here
            addPulseAtGivenTime(obj, time, p)
        end
        
%       Might be useful?        
%         function addSequencePulse(obj, pulse, time)
%             narginchk(2,3)
%             switch nargin
%                 case 2
%                     obj.sequence.addPulse(pulse);
%                 case 3      % input has 'time' variable
%                     obj.sequence.addPulseAtgivenTimes(time, pulse);
%             end
%             obj.sequenceInMemory = false;
%         end
        
        function [S1, S2] = splitByIndex(obj, ind)
            % Splits sequence into 2 parts: [obj(1:ind) obj(ind+1:end)]
            S1 = Sequence(obj.pulses(1:ind));
            S2 = Sequence(obj.pulses(ind+1:end));
        end
        
        function [S1, S2] = splitByTime(obj, time)
            assert(isscalar(time), 'Currently, we Can''t split by vector of times. Sorry!')
            
            if time >= obj.duration || time <= 0
                error('Sequence could not be split in requested time')
            end
            pulseEdges = obj.edgeTimes;
            
            ind = find(pulseEdges <= time, 1, 'last');
            if pulseEdges(ind) == time
                % Easier: we just split the whole sequence into two parts
                % at time 'time'
                [S1, S2] = obj.splitByIndex(ind);
            else
                % Harder: we also need to split a pulse and add it to
                % relevent sequences. We need:
                % a. the pulse we want to split
                pulseToSplit = obj.pulses(ind+1);
                % b. the time we want to split it in
                pulseTime = time - pulseEdges(ind);
                % And now: the actual job
                [P1, P2] = pulseToSplit.split(pulseTime);
                S1 = Sequence([obj.pulses(1:ind), P1]);
                S2 = Sequence([P2, obj.pulses(ind+2:end)]);
            end
        end
        
        function change(obj, nickname, what, newValue)
            index = obj.indexFromNickname(nickname);
            p = obj.pulses(index);
            % Maybe p is an array of multiple pulses, and we are then
            % forced to use a loop to handle it.
            for i = 1:length(p)
                switch lower(what)
                    case {'duration', 't'}
                        p(i).duration = newValue;  % setter will take care of validation
                    case {'sequence', 'event', 'pb'}
                        % Decision: for now, pulse enables adding or removing
                        % individual channels. This function, however, always
                        % removes everything, and then adds *only* the
                        % requested channels.
                        p(i).clear();
                        p(i).setLevels(newValue);  % We assume, for now, only digital cahnnels.
                    otherwise
                        error('Unknown option')
                end
            end
        end
    end
       
    methods (Access = private)
        function ind = indexfromNickname(obj, name)
            % Returns index (or indices) of pulses that have the name
            % 'name'
            if isnumeric(name)
                ind = name;
                if ind > length(obj.pulses)
                    ind = double.empty;
                end
            elseif ischar(name)
                nicknames = {obj.pulses.nickname};
                ind = find(strcmp(name, nicknames));
            else
                error('Unknown indexing system')
            end
            if isempty(ind)
                error('Index not found')
            end
        end
        
    end
    
    %% Operator Overriding
    methods
        function S = plus(S1, S2)
            S = Sequence;
            S.pulses = [S1.pulses S2.pulses];
        end
        
        function S = mtimes(in1, in2)
            if isnumeric(in1)
                n = in1;
                T = in2;
            elseif isnumeric(in2)
                n = in2;
                T = in1;
            else
                error('Operation is undefined! (for now?)')
            end
            S = Sequence(repmat(T.pulses, 1, n));
        end
    end
    
end

