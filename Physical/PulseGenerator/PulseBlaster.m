classdef PulseBlaster < EventSender
    %PULSEBLASTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        dummyMode  % boolean. if set to true, no physics will be changed!
        seqDuration %mus 1D array of length(y)
        seqNicknames % 1D array of strings, (cell array) of length(y)
        seqSequence % 2D array, matric with size = [y * MAX_PB_CHANNEL] of 1s and 0s.
        seqRepeats  % scalar. how many times do this sequence
    end
    
    properties (Dependent)
        seqTime  % sum() on seqDuration
        channelNames % 1D array of length(x)
        channelValues % 1D array of length(x)
        channelStatuses % 1D array of length(x)
    end
    
    properties (Access = private)
        mChannels;          % vector of integers
        mChannelNames;      % 1D cell of strings
        mChannelStatuses;   % vector of logicals
        libPathName         % name of the folder where the PB library is found
        
    end
    
    properties (Constant)
        NAME = 'PulseBlaster';
    end
    
    properties (Constant, Access = private)
        FREQUENCY=500; % in MHz %500e6;% Hz
        MAX_PB_CHANNEL = 16;
        MIN_DURATION = 0;
        MAX_DURATION = 1e5;
        MAX_REPEATS=1e6;
        ERROR = -1;
        PBl_LIB_NAME = 'PB_LIB_NAME'; %Alias name of the PB library
    end
    
    methods (Access = private)
        function obj = PulseBlaster(libPathName, dummyModeOptional)
            % dummyModeOptional - if exists and set to true, no actual physics will be
            % involved. good for testing purposes
            obj@EventSender(PulseBlaster.NAME);
            replaceBaseObject(obj);	%   % in base object map, so it can be reached by getObjByName(PulseBlaster.NAME)
            
            obj.dummyMode = and(exist('dummyModeOptional', 'var'), dummyModeOptional == true);
            obj.mChannels = [];
            obj.mChannelNames = {};
            obj.mChannelStatuses = [];
            obj.libPathName = libPathName;
            fprintf('pulseBlaster library path: %s\n', libPathName);
            if ~ obj.dummyMode
                obj.initialize()
            end
        end
        
        function initialize(obj)
            obj.LoadPBESR;
            obj.PBesrSetClock();
        end
    end
    
%     methods (Static, Sealed)
%         function out=getInstance(newObjectInstanceOptional)
%             % one can call getInstance() with no args to get the object
%             % the function create() calls getInstance(with some newObject)
%             % with the object as argument, to initiate it!
%          persistent instance;
%          if exist('newObjectInstanceOptional', 'var')
%              instance = newObjectInstanceOptional;
%          end
%          out=instance; 
%         end
%     end
    
    methods (Static)
        function obj = create(pbStruct)
            % Create a new instance of the pulse blaster, to be retreived
            % via getInstance()
            % 
            % "pbStruct" - a struct. 
            % if the struct contains the optional property "dummy" with the value true, 
            % no actual physics will be involved. good for testing purposes
            % if "dummy" isn't in the struct, it will be considered as false
            %
            if ~isfield(pbStruct, 'libPathName')
                EventStation.anonymousError('"libPathName must be in the struct for the pulse blaster!')
            end
            
            libPathName = strrep(pbStruct.libPathName, '[NV Lab]\', PathHelper.getPathToNvLab());
            
            if isfield(pbStruct, 'dummy')
%                 obj = PulseBlaster.getInstance(PulseBlaster(libPathName, pbStruct.dummy));
                obj = PulseBlaster(libPathName, pbStruct.dummy);
            else
%                 obj = PulseBlaster.getInstance(PulseBlaster(libPathName));
                obj = PulseBlaster(libPathName);
            end
        end
    end
    
    methods (Access = private)
        function channel = getChannel(obj, channelNameOrNumber)
            % Get the channel from a name or number:
            % if it's a name, search for it;
            % if it's a number - use it
            %
            % returns - the channel if exists or PulseBlaster.ERROR
            if ischar(channelNameOrNumber)
                index = obj.getIndexFromName(channelNameOrNumber);
                if index == PulseBlaster.ERROR
                    channel = PulseBlaster.ERROR;
                    return
                end
                channel = obj.mChannels(index);
                
            elseif isnumeric(channelNameOrNumber)
                % the user wants us to switch channel 5, for example
                channel = channelNameOrNumber;
            else
                obj.sendError('could not understand your parameter "channelNameOrNumber"');
                channel = PulseBlaster.ERROR;
                return
            end
        end
        
    end
    
    methods
        function addNewChannel(obj, newChannelName, newChannelValue)
            % newChannelName - char vector
            % newChannelValue - int
            rowsAmnt = length(obj.mChannelNames);
            if rowsAmnt >= obj.MAX_PB_CHANNEL
                msg = sprintf('Can''t add channel "%s", since the pulse blaster is full! Aborting.\nChannels taken: [%s]', newChannelName, obj.mChannelNames);
                obj.sendError(msg);
            end
            
            if ~ischar(newChannelName)
                obj.sendError(sprintf('''newChannelName'' has to be some string! (got: "%s")', newChannelName));
            end
            if ~isnumeric(newChannelValue)
                obj.sendError(sprintf('''newChannelValue'' has to be an int!(got: "%s")', newChannelValue));
            end
            
            captured = find(obj.mChannels == newChannelValue);
            if ~isempty(captured)
                obj.sendError(sprintf('Can''t asign channel %d to "%s" as it is already taken by "%s"!\nAborting.', ...
                    newChannelValue, newChannelName, obj.mChannelNames{captured(1)}));
            end
            
            obj.mChannels(end + 1) = newChannelValue;
            obj.mChannelNames{end + 1} = newChannelName;
            obj.mChannelStatuses(end + 1) = 0;
        end
        
        function boolean = isOn(obj, channelNameOrNumber)
            % check if a certian channel is now on or not
            channel = obj.getChannel(channelNameOrNumber);
            if (channel == PulseBlaster.ERROR)
                boolean = false;
                return
            end
            boolean = obj.mChannelStatuses(obj.mChannels == channel) == true;
        end
        
        function activatedChannels = switchOnly(obj, channelNameOrNumber, newBooleanValue)
            % Switches only one channel, leaving the others unharmed
            %
            % channelNameOrNumber - can be a char vector or an int
            %
            % returns - the activated channels
            %
            if ~all(or(newBooleanValue==0, newBooleanValue==1))
                obj.sendError('''newBooleanValue'' has to be false or true only! Aborting.')
            end
            
            if ischar(channelNameOrNumber)
                argChannelLength = 1;
            else
                argChannelLength = length(channelNameOrNumber);
            end
            if argChannelLength ~= length(newBooleanValue)
                obj.sendError('''newBooleanValue'' and ''channelNameOrNumber'' must be of the same length! Aborting.')
            end
            
            if argChannelLength > 1
                activatedChannels = obj.switchArrayOnly(channelNameOrNumber, newBooleanValue);
                return
            end
            
            channel = obj.getChannel(channelNameOrNumber);
            if (channel == PulseBlaster.ERROR)
                activatedChannels = obj.getActiveChannels();
                return
            end
            
            obj.setInternalChannelStatusIfExist(channel, newBooleanValue);
            if ~obj.dummyMode
                obj.Output();
            end
            activatedChannels = obj.getActiveChannels();
            obj.sendEvent(struct('activatedChannels', activatedChannels));
            
            
        end
        
        function activatedChannels = switchArrayOnly(obj, channelNameCellOrIntegerArray, newBooleanValue)
            % sugar syntax for obj.switchOnly(). it does a for loop on channelNameArrayOrIntegerArray
            % channelNameArrayOrIntegerCell - cell array of strings / integers
            % newBooleanValue - array of [1s or 0s]
            
            if ~all(or(newBooleanValue==0, newBooleanValue==1))
                obj.sendError('''newBooleanValue'' has to be either false or true! Aborting.')
            end
            
            if length(channelNameCellOrIntegerArray) ~= length(newBooleanValue)
                obj.sendError('''newBooleanValue'' and ''channelNameCellOrIntegerArray'' must be of the same length! Aborting.')
                return
            end
            
            switch class(channelNameCellOrIntegerArray)
                case 'cell'
                    for k = 1 : length(channelNameCellOrIntegerArray)
                        channelNameOrNumber = channelNameCellOrIntegerArray{k};
                        channel = obj.getChannel(channelNameOrNumber);
                        boolValue = newBooleanValue(k);
                        obj.setInternalChannelStatusIfExist(channel, boolValue);
                    end
                case 'double'
                    for k = 1 : length(channelNameCellOrIntegerArray)
                        channelNameOrNumber = channelNameCellOrIntegerArray(k);
                        channel = obj.getChannel(channelNameOrNumber);
                        boolValue = newBooleanValue(k);
                        obj.setInternalChannelStatusIfExist(channel, boolValue);
                    end
                otherwise
                    obj.sendWarning('Input ''channelNameArrayOrIntegerCell'' must be of a 1D class ''cell'' or a vector of integers!');
                    activatedChannels = obj.getActiveChannels();
                    return
            end
            
            if ~obj.dummyMode 
                obj.Output();
            end
            
            activatedChannels = obj.getActiveChannels();
            obj.sendEvent(struct('activatedChannels', activatedChannels));
        end
        
        
        function activatedChannels = allOff(obj)
            % switches OFF all the channels
            
            obj.mChannelStatuses = zeros(size(obj.mChannelStatuses));
            if ~obj.dummyMode
                obj.Output()
            end
            activatedChannels = obj.getActiveChannels();
            obj.sendEvent(struct('activatedChannels', activatedChannels));
        end
        
    end
    
    
    methods % for all the dependent properties + the 'setter's
        function channelNames = get.channelNames(obj)
            channelNames = obj.mChannelNames(1:end); % copy
        end
        function channelValues = get.channelValues(obj)
            channelValues = obj.mChannels(1:end); % copy
        end
        function channelStatuses = get.channelStatuses(obj)
            channelStatuses = obj.mChannelStatuses(1:end); % copy
        end
        function time = get.seqTime(obj)
            time = cumsum(obj.seqDuration);  % sum
        end
        
        function set.seqRepeats(obj,newVal)
            if ~isnumeric(newVal)
                obj.sendError('''newVal'' must be numeric!');
            end
            
            if newVal < 1 || newVal > obj.MAX_REPEATS
                obj.sendError('Value out of range. Range: [%d, %d]', 1, obj.MAX_REPEATS);
            end
            obj.seqRepeats = newVal;
        end
    end
    
    methods (Access = private)
        % helper methods
        
        function setInternalChannelStatusIfExist(obj, channel, newBooleanValue)
            % set the value for a channel
            indices = find(obj.mChannels == channel);
            if isempty(indices)
                warningMsg = sprintf('Channel (%d) not registered! Ignoring.\n(Call obj.addNewChannel() to register this channel)', channel);
                obj.sendError(warningMsg);
                return
            end
            index = indices(1);
            obj.mChannelStatuses(index) = newBooleanValue;
        end
        
        function activeChannels = getActiveChannels(obj)
            activeChannels = obj.mChannelNames(obj.mChannelStatuses == true);
        end
        
        function index = getIndexFromName(obj, channelName)
            % returns the index if found 
            % or PulseBlaster.ERROR if not found
            indices = find(strcmp(obj.mChannelNames,channelName));
            if isempty(indices)
                obj.sendError(sprintf('No channel with name "%s" exists!', channelName));
            end
            index = indices(1);
        end
        
        function label = Output(obj)
            % Send (constant) outputs state to pulse blaster
            % based on the values given by channels    
            
            obj.PBesrStartProgramming(); % enter the programming mode
            
            % todo - is there a cleaner way to do so without this "if"?
            if ~any(obj.mChannelStatuses)
                channels = 0;
            else 
                channels = sum(2.^(obj.mChannels(obj.mChannelStatuses)));
            end
            label = obj.PBesrInstruction(channels, 'ON', 'CONTINUE', 0, 100);
            obj.PBesrInstruction(channels, 'ON', 'BRANCH', label, 100);
            obj.PBesrStopProgramming(); % exit the programming mode            
            obj.PBesrStop();
            obj.PBesrStart();
        end
    end
    
    methods (Access = protected)
        % Pulse communication methods - calling to the PB library
        function [PBready] = PBisReady(obj)
            stat = obj.PBesrReadStatus;
            % the check for stat<100 is supposed to capture an uninitialized board.
            % This is not fool-proof, and should be fixed somehow
            if (stat>0) && (stat<100)
                PBready=1;
            else
                PBready=0;
            end
        end
        function LoadPBESR(obj)
            if ~libisloaded(obj.PBl_LIB_NAME)
                disp('Matlab: Load spinapi.dll')
                loadlibrary([obj.libPathName,'spinapi64.dll'],[obj.libPathName,'spinapi.h'],'alias',obj.PBl_LIB_NAME); %keep name & library in a property !!!!!!!!!!!!!!!!!!!!!!!!!!!
            end
            disp('Matlab: spinapi.dll loaded')
        end
        function PBesrSetClock(obj)
            %End communication with the board. This is generally called as the last line in a program.
            % Once this is called, no further communication can take place with the board
            % unless the board is reinitialized with pb_init(). However, any pulse program that
            % is loaded and running at the time of calling this function will continue to
            % run indefinitely.
            %
            % \return A negative number is returned on failure, and spinerr is set to a
            % description of the error. 0 is returned on success.
            %calllib('mypbesr','pb_set_clock',obj.frequencyPrivate*1e-6);%in MHz
            calllib(obj.PBl_LIB_NAME,'pb_set_clock',obj.FREQUENCY);%in MHz
        end
        function status = PBesrClose(obj)
            status = calllib(obj.PBl_LIB_NAME,'pb_close');
        end
        function status = PBesrInit(obj)
            status = calllib(obj.PBl_LIB_NAME,'pb_init');
        end
        function inst_num = PBesrInstruction(obj,flag, flag_option, inst, inst_arg, length)
            %added by Sungkun
            %input arguments
            %flag : flag of set of channels to be on
            %flag_option : options to be associated with flag. string type.
            %inst : specific instruction including loop, branch, etc.. string type.
            %inst_arg : instruction specific arguments. usually integer.
            %length : length of pulse in nanosecond.
            
            %output argument : number of instruction.
            
            
            %flag_option map. string-to-bits
            ALL_FLAGS_ON	= hex2dec('1FFFFF');
            ONE_PERIOD		= hex2dec('200000');
            TWO_PERIOD		= hex2dec('400000');
            THREE_PERIOD	= hex2dec('600000');
            FOUR_PERIOD		= hex2dec('800000');
            FIVE_PERIOD		= hex2dec('A00000');
            SIX_PERIOD      = hex2dec('C00000');
            ON				= hex2dec('E00000');
            
            %instruction map. string-to-bits
            CONTINUE = 0;
            STOP = 1;
            LOOP = 2;
            END_LOOP = 3;
            JSR = 4;
            RTS = 5;
            BRANCH = 6;
            LONG_DELAY = 7;
            WAIT = 8;
            
            switch flag_option
                case 'ON'
                    flag = bitor(flag, ON);
                case 'ONE_PERIOD'
                    flag = bitor(flag, ONE_PERIOD);
                case 'TWO_PERIOD'
                    flag = bitor(flag, TWO_PERIOD);
                case 'THREE_PERIOD'
                    flag = bitor(flag, THREE_PERIOD);
                case 'FOUR_PERIOD'
                    flag = bitor(flag, FOUR_PERIOD);
                case 'FIVE_PERIOD'
                    flag = bitor(flag, FIVE_PERIOD);
                case 'SIX_PERIOD'
                    flag = bitor(flag, SIX_PERIOD);
                case 'ALL_FLAGS_ON'
                    flag = ALL_FLAGS_ON;
                otherwise
            end
            
            switch inst
                case 'CONTINUE'
                    inst = CONTINUE;
                case 'STOP'
                    inst = STOP;
                case 'LOOP'
                    inst = LOOP;
                case 'END_LOOP'
                    inst = END_LOOP;
                case 'JSR'
                    inst = JSR;
                case 'RTS'
                    inst = RTS;
                case 'BRANCH'
                    inst = BRANCH;
                case 'LONG_DELAY'
                    inst = LONG_DELAY;
                case 'WAIT'
                    inst = WAIT;
                otherwise
            end
            
            inst_num = calllib(obj.PBl_LIB_NAME,'pb_inst_pbonly',flag, inst, inst_arg, length);
        end
        function status = PBesrReadStatus(obj)
            status = calllib(obj.PBl_LIB_NAME,'pb_read_status');
        end
        function status = PBesrStart(obj)
            status = calllib(obj.PBl_LIB_NAME,'pb_start');
        end
        function status = PBesrStartProgramming(obj)
            
            PULSE_PROGRAM  = 0;
            FREQ_REGS      = 1; %#ok<*NASGU>
            
            PHASE_REGS     = 2;
            TX_PHASE_REGS  = 2;
            PHASE_REGS_1   = 2;
            
            RX_PHASE_REGS  = 3;
            PHASE_REGS_0   = 3;
            
            status = calllib(obj.PBl_LIB_NAME, 'pb_start_programming',PULSE_PROGRAM);
        end
        function status = PBesrStop(obj)
            status = calllib(obj.PBl_LIB_NAME, 'pb_stop');
        end
        function status = PBesrStopProgramming(obj)
            status = calllib(obj.PBl_LIB_NAME, 'pb_stop_programming');
        end
        
    end
end