classdef FrequencyGeneratorSRS < FrequencyGenerator & SerialControlled
    %FREQUENCYGENERATORSRS SRS frequency genarator class
    properties (Constant, Hidden)
        LIMITS_FREQUENCY = [0, 4.05e9];  % Hz
        LIMITS_AMPLITUDE = [-100, 10];   % dB. These values may not be reached, depending on the output type.
        
        TYPE = 'srs';
        MY_NAME = 'srsFrequencyGenerator'; % We can't call it just NAME, because we inherit from matlab.mixin.SetGet
        
        NEEDED_FIELDS = {'address', 'serialNumber'}
    end
    
    methods (Access = private)
        function obj = FrequencyGeneratorSRS(name, address)
            obj@FrequencyGenerator(name);
            obj@SerialControlled(address);
        end
    end
   
    methods
       function value = readOutput(obj)
           value = obj.read;
       end
    end
    
    methods (Static)
        function obj = getInstance(struct)
            missingField = FactoryHelper.usualChecks(struct, ...
                FrequencyGeneratorSRS.NEEDED_FIELDS);
            if ~isnan(missingField)
                EventStation.anonymousError(...
                    'Trying to create an SRS frequency generator, encountered missing field - "%s". Aborting',...
                    missingField);
            end
            
            name = [FrequencyGeneratorSRS.MY_NAME, '-', struct.serialNum];
            obj = FrequencyGeneratorSRS(name, struct.address);
            addBaseObject(obj);
        end
        
        function command = nameToCommandName(name)
           switch lower(name)
               case {'enableoutput', 'output', 'enabled', 'enable'}
                   command = 'ENBR';
               case {'frequency', 'freq'}
                   command = 'FREQ';
               case {'amplitude', 'ampl', 'amp'}
                   command = 'AMPR';
               otherwise
                   error('Unknown command type %s', name)
           end         
       end
    end

end

