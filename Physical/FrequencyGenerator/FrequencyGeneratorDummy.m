classdef (Sealed) FrequencyGeneratorDummy < FrequencyGenerator
    %FREQUENCYGENERATORDUMMY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant, Hidden)
        LIMITS_FREQUENCY = [0, 4.05e9];  %Hz
        LIMITS_AMPLITUDE = [-100, 10];   %dB
        
        TYPE = 'dummy'
        
        NEEDED_FIELDS = {'name'}
    end
    
    methods (Access = private)
        function obj = FrequencyGeneratorDummy(name)
            obj@FrequencyGenerator(name);
        end
    end
    
    methods
        function varargout = sendCommand(~, command, value)
            nargoutchk(0,1)
            
            if nargout == 1
                if ~ischar(value)
                    value = num2str(value);
                end
                varargout = {sprintf('Sent command: ''%s: %s\n', command, value)};
            end
        end
    end
    
    methods (Static)
        function obj = getInstance(struct)
            
            missingField = FactoryHelper.usualChecks(struct, ...
                FrequencyGeneratorDummy.NEEDED_FIELDS);
            if ~isnan(missingField)
                EventStation.anonymousError(...
                    'Trying to create a dummy frequency generator, encountered missing field - "%s". Aborting',...
                    missingField);
            end
            
            obj = FrequencyGeneratorDummy(struct.name);
            addBaseObject(obj);
            
        end
        
        function command = nameToCommandName(name)
            switch lower(name)
               case {'enableoutput', 'output', 'enabled', 'enable'}
                   command = 'output';
               case {'frequency', 'freq'}
                   command = 'frquency';
               case {'amplitude', 'ampl', 'amp'}
                   command = 'amplitude';
               otherwise
                   error('Unknown command type: ''%s''',name)
           end    
        end
    end
    
end

