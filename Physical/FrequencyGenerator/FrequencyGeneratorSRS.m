classdef FrequencyGeneratorSRS < FrequencyGenerator & SerialControlled
    %FREQUENCYGENERATORSRS SRS frequency genarator class
    properties (Constant, Hidden)
        LIMITS_FREQUENCY = [0, 4.05e9];  % Hz
        LIMITS_AMPLITUDE = [-100, 10];   % dB. These values may not be reached, depending on the output type.
        
        TYPE = 'srs';
        NAME = 'srsFrequencyGenerator';
        
        NEEDED_FIELDS = {'address'}
    end
    
    methods (Access = private)
        function obj = FrequencyGeneratorSRS(address)
            obj@FrequencyGenerator(FrequencyGeneratorSRS.NAME);
            obj@SerialControlled(address);
        end
    end
   
    methods
       function varargout = sendCommand(obj, command, value)
           % value - sent value or ?. units can also be added to value
           varargout = {0};
           %%% set the command to be sent to the SRS
           command = nameToCommandName(obj, command);
           
           if strcmp(value,'?')
               command = [command,'?'];
           else
               command=[command, value];
           end
           fopen(obj.address);
           try
           fprintf(obj.address,command);
           % Get the output - if needed
           if strcmp(value,'?')
               varargout = {fscanf(obj.address, '%s')};
           end
           catch err
               fclose(obj.address);
               rethrow(err)
           end
           fclose(obj.address);    
           
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
            
            obj = FrequencyGeneratorSRS(struct.address);
            addBaseObject(obj);
        end
        
        function command = nameToCommandName(name)
           switch lower(name)
               case {'enableoutput','output','enabled','enable'}
                   command='ENBR';
               case {'frequency','freq'}
                   command='FREQ';
               case {'amplitude','ampl','amp'}
                   command='AMPR';
               otherwise
                   error('Unknown command type %s',name)
           end         
       end
    end

end

