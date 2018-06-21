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
    
    properties
        NEEDED_FIELDS = {'address'}
    end
    
    properties (Access = private)
        % Store values internally, to reduce time spent over serial connection
        frequencyPrivate
        amplitudePrivate
        outputPrivate       % Output on or off;
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
                case {'1',1,'on',true}
                    obj.sendCommand('enableOutput','1') %test this is the correct value to be sent!!!!!
                    obj.outputPrivate = true;
                case {'0',0,'off',false}
                    obj.sendCommand('enableOutput','0') %test this is the correct value to be sent!!!!!
                    obj.outputPrivate = false;
                otherwise
                    error('Unknown command. Ignoring')
            end
        end
        
        function set.amplitude(obj, newAamplitude)  % in dB
            % Change amplitude level of the frequency generator
            % Test value, and compare to memory !!!!!!!!!!!!!
            if ~ValidationHelper.isInBorders(newAamplitude, obj.LIMITS_AMPLITUDE(1), obj.LIMITS_AMPLITUDE(2))
                error('MW amplitude must be between %d and %d.\nRequested: %d', ...
                    obj.LIMITS_AMPLITUDE(1), obj.LIMITS_AMPLITUDE(2), newAamplitude)
            end
            obj.sendCommand('amplitude',num2str(newAamplitude));
            obj.amplitudePrivate = newAamplitude;
        end
        
        function set.frequency(obj, newFrequency)      % in Hz
            % Change frequency level of the frequency generator
            % Test value, and compare to memory !!!!!!!!!!!!!!!
            if ~ValidationHelper.isInBorders(newFrequency, obj.LIMITS_FREQUENCY(1), obj.LIMITS_FREQUENCY(2))
                error('MW frequency must be between %d and %d.\nRequested: %d', ...
                    obj.LIMITS_FREQUENCY(1), obj.LIMITS_FREQUENCY(2), newFrequency)
            end
            obj.sendCommand('frequency', num2str(newFrequency));
            obj.frequencyPrivate = newFrequency;
        end
        
        function value = queryValue(obj, what)
            value = sendCommand(obj, what, '?');
            value = str2double(value);
        end
    end
    
    methods (Abstract)
        sendCommand(obj, what, value)
        % Actually sends command to hardware
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
            
            persistent fgCellContainer
            if isempty(fgCellContainer) || ~isvalid(fgCellContainer)
                FGjson = JsonInfoReader.getJson.frequencyGenerators;
                fgCellContainer = CellContainer;
                
                for i = 1: length(FGjson)
                    %%% Checks on each individual struct %%%
                    if iscell(FGjson); curFgStruct = FGjson{i}; ...
                        else; curFgStruct = FGjson(i); end
                
                    if isfield(curFgStruct, 'type'); type = curFgStruct.type; ...
                        else; type = FrequencyGeneratorDummy.TYPE; end
            
                    missingField = FactoryHelper.usualChecks(struct, ...
                        FrequencyGenerator.NEEDED_FIELDS);
                    if ~isnan(missingField) && ...  Some field is missing
                            ~strcmp(type, FrequencyGeneratorDummy.TYPE) % This FG is not dummy
                        EventStation.anonymousError(...
                            'Trying to create a %s frequency generator, encountered missing field - "%s". Aborting',...
                            type, missingField);
                    end
            
                    %%% Get instance (create, if one doesn't exist) %%%
                    t = lower(type);
                    switch t
                        case FrequencyGeneratorSRS.TYPE
                            try
                                newFG = getObjByName(FrequencyGeneratorSRS.NAME);
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
            end
            
            freqGens = fgCellContainer.cells;
        end
    end
    
end

