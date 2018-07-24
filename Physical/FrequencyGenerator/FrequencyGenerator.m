classdef (Abstract) FrequencyGenerator < BaseObject
    %FREQUENCYGENERATOR Abstract class for frequency generators
    % Has 3 public (and Dependent) properties:
    % # output (On/Off),
    % # frequency (in Hz) and
    % # amplitude (in dB)
    %
    % Subclasses need to:
    % 1. specify values for the constants:
    %       LIMITS_FREQUENCY
    %       LIMITS_AMPLITUDE
    % 2. implement the functions:
    %       varargout = sendCommand(obj, command, value)
    %       (Static) newFG = getInstance(struct)
    %       (Static) command = nameToCommandName(name)
    
    properties (Dependent)
        frequency   % Hz
        amplitude   % dB
        output      % logical. On/off
    end
    
    properties (Abstract, Constant)
        % Minimum and maximum values
        LIMITS_FREQUENCY    % for MW frequency
        LIMITS_AMPLITUDE    % for MW amplitude
        
        TYPE    % for now, one of: {'srs', 'synthhd', 'synthnv'}
    end
    
    properties (Constant, Access = private)
        NEEDED_FIELDS = {'address'}
    end
    
    properties (Access = private)
        % Store values internally, to reduce time spent over serial connection
        frequencyPrivate    % double
        amplitudePrivate    % double.
        outputPrivate       % logical. Output on or off;
    end
    
    methods (Access = protected)
        function obj = FrequencyGenerator(name)
            obj@BaseObject(name);
            obj.frequencyPrivate = obj.queryValue('frequency');
            obj.amplitudePrivate = obj.queryValue('amplitude');
            obj.outputPrivate    = obj.queryValue('enableOutput');
        end
    end
    
    methods
        function frequency = get.frequency(obj)
            frequency = obj.frequencyPrivate;
        end
        function amplitude = get.amplitude(obj)
            amplitude = obj.amplitudePrivate;
        end
        function output = get.output(obj)
            output = obj.outputPrivate;
        end
        
        function set.output(obj, value)
            switch value
                case {'1', 1, 'on', true}
                    obj.setValue('enableOutput', '1')
                    obj.outputPrivate = true;
                case {'0', 0, 'off', false}
                    obj.setValue('enableOutput', '0')
                    obj.outputPrivate = false;
                otherwise
                    error('Unknown command. Ignoring')
            end
        end
        
        function set.amplitude(obj, newAamplitude)  % in dB
            % Change amplitude level of the frequency generator
            if ~ValidationHelper.isInBorders(newAamplitude, obj.LIMITS_AMPLITUDE(1), obj.LIMITS_AMPLITUDE(2))
                error('MW amplitude must be between %d and %d.\nRequested: %d', ...
                    obj.LIMITS_AMPLITUDE(1), obj.LIMITS_AMPLITUDE(2), newAamplitude)
            end
            
            switch length(newAmplitude)
                case 1
                    obj.setValue('amplitude', newAamplitude);
                    obj.amplitudePrivate(1) = newAamplitude;
                case length(obj.amplitudePrivate)
                    obj.setValue('amplitude', newAamplitude);
                    obj.amplitudePrivate = newAamplitude;
                otherwise
                    EventStation.anonymousError('Frequency Generator: amplitude vector size mismatch!');
            end
            
            
        end
        
        function set.frequency(obj, newFrequency)      % in Hz
            % Change frequency level of the frequency generator
            if ~ValidationHelper.isInBorders(newFrequency, obj.LIMITS_FREQUENCY(1), obj.LIMITS_FREQUENCY(2))
                error('MW frequency must be between %d and %d.\nRequested: %d', ...
                    obj.LIMITS_FREQUENCY(1), obj.LIMITS_FREQUENCY(2), newFrequency)
            end
            
            switch length(newFrequency)
                case 1
                    obj.setValue('frequency', newFrequency);
                    obj.frequencyPrivate(1) = newFrequency;
                case length(obj.frequencyPrivate)
                    obj.setValue('frequency', newFrequency);
                    obj.frequencyPrivate = newFrequency;
                otherwise
                    EventStation.anonymousError('Frequency Generator: frequency vector size mismatch!');
            end
        end
        
        
        function value = queryValue(obj, what)
            command = [obj.nameToCommandName(what), '?'];
            sendCommand(obj, command);
            value = str2double(obj.readOutput);
        end
        
        function setValue(obj, what, value)
            % Can be overridden by children
            if isnumeric(value)
                value = num2str(value);
            end
            
            command = [obj.nameToCommandName(what), value];
            sendCommand(obj, command);
        end
    end
    
    methods (Abstract)
        sendCommand(obj, command)
        % Actually sends command to hardware
        
        value = readOutput(obj)
        % Get value returned from object
    end
    
    methods (Abstract, Static)
        obj = getInstance(struct)
        % So that the constructor remains private
        
        command = nameToCommandName(obj, name)
        % Converts request type to a command that can be sent to Hardware.
    end
    
    methods (Static)
        function freqGens = getFG()
            % Returns an instance of cell{all FG's}
            %
            % The cell is ordered, so that the first one is the default FG
            
            persistent fgCellContainer
            if isempty(fgCellContainer) || ~isvalid(fgCellContainer)
                FGjson = JsonInfoReader.getJson.frequencyGenerators;
                fgCellContainer = CellContainer;
                isDefault = false(size(FGjson));    % initialize
                
                for i = 1: length(FGjson)
                    %%% Checks on each individual struct %%%
                    if iscell(FGjson); curFgStruct = FGjson{i}; ...
                        else; curFgStruct = FGjson(i); end
                    
                    % If there is no type, then it is a dummy
                    if isfield(curFgStruct, 'type'); type = curFgStruct.type; ...
                        else; type = FrequencyGeneratorDummy.TYPE; end
                    
                    % Usual checks on fields
                    missingField = FactoryHelper.usualChecks(struct, ...
                        FrequencyGenerator.NEEDED_FIELDS);
                    if ~isnan(missingField) && ...  Some field is missing
                            ~strcmp(type, FrequencyGeneratorDummy.TYPE) % This FG is not dummy
                        EventStation.anonymousError(...
                            'Trying to create a %s frequency generator, encountered missing field - "%s". Aborting',...
                            type, missingField);
                    end
                    
                    % Check whether this is THE default FG
                    if isfield(curFgStruct, 'default'); isDefault(i) = true; end
            
                    %%% Get instance (create, if one doesn't exist) %%%
                    t = lower(type);
                    switch t
                        case FrequencyGeneratorSRS.TYPE
                            try
                                newFG = getObjByName(FrequencyGeneratorSRS.MY_NAME);
                            catch
                                newFG = FrequencyGeneratorSRS.GetInstance(curFgStruct);
                            end
                        case FrequencyGeneratorWindfreak.TYPE
                            try
                                name = [t, 'FrequencyGenerator'];
                                newFG = getObjByName(name);
                            catch
                                newFG = FrequencyGeneratorWindfreak.getInstance(curFgStruct);
                            end
                        case FrequencyGeneratorDummy.TYPE
                            newFG = FrequencyGeneratorDummy.GetInstance(curFgStruct);
                        otherwise
                            EventStation.anonymousWarning('Could not create Frequency Generator of type %s!', type)
                    end
                    fgCellContainer.cells{end + 1} = newFG;
                end
                
                nDefault = sum(isDefault);
                switch nDefault
                    case 0
                        % Nothing.
                    case 1
                        % We move the default one to index 1
                        ind = 1:find(isDefault);
                        indNew = circshift(ind, 1); % = [ind, 1, 2, ..., ind-1]
                        fgCellContainer.cells{ind} = fgCellContainer.cells{indNew};
                    otherwise
                        EventStation.anonymousError('Too many Frequency Generators were set as default! Aborting.')
                end
                
            end
            
            freqGens = fgCellContainer.cells;
        end
        
        function name = getDefaultFgName()
            fgCells = FrequencyGenerator.getFG;
            if isempty(fgCells.cells)
                EventStation.anonymousError('There is no active frequency generator!')
            end
            fg = fgCells.cells{1};   % We sorted the array so that the default FG is first
            name = fg.name;
        end

    end
    
end

