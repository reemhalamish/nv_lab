classdef FrequencyGeneratorWindfreak < FrequencyGenerator & SerialControlled
    %FREQUENCYGENERATORWINDFREAK Windfreak frequency generator class
    % includes, for now, synthHD & synthNV
    
    properties (Constant, Hidden)
        LIMITS_FREQUENCY = [0, 4.05e9];  % Hz
        LIMITS_AMPLITUDE = [-60, 18];    % dB. These values may not be reached, depending on the output type.
        
        TYPE = {'synthhd', 'synthnv'};
        
        NEEDED_FIELDS = {'address'}
    end
    
    methods (Access = private)
        function obj=FrequencyGeneratorWindfreak(name, address)
            obj@FrequencyGenerator(name);
            obj@SerialControlled(address);
        end
    end
    
    methods
        function varargout = sendCommand(obj, command, value)
            % value - sent value or ?. units can also be added to value
            varargout={0};
            %%% set the command to be sent to the SRS
            command=nameToCommandName(obj,command);
            if ~strcmp(value,'?') % convert sent values if needed
                switch command
                    case 'f'
                        value=num2str(str2double(value)/1e6);             %%% convert Hz to MHz (SynthHD uses MHz)
                        %case 'W'
                        %    value=num2str(obj.PowerdBtoSynthHD(str2double(value)));  %%% convert dbm to strange units of the SynthHD
                end
            end
            
            fopen(obj.address);
            try
                %fprintf(obj.address,C1r1);
                fprintf(obj.address,[command, value]);
                % Get the output - if needed
                if strcmp(value,'?')
                    varargout = {fscanf(obj.address,'%s')};
                    switch command
                        case 'f'
                            varargout={num2str(str2double(varargout{1})*1e6)};  %%% convert MHz to Hz (SynthHD uses MHz)
                        case 'a'
                            varargout={num2str(obj.PowerSynthHDtodB(str2double(varargout{1})))}; %convert strange units of the SynthHD to dbm
                    end
                end
            catch err
                fclose(obj.address);
                rethrow(err)
            end
            fclose(obj.address);
            
        end
        
        %        function [pdB] = PowerSynthHDtodB(obj,pSynthHD)
        %
        %            if pSynthHD>24000
        %                pdB=((pSynthHD-26100)/(2.1e-11))^0.084531;
        %            else
        %                pdB=(pSynthHD-21520)/233.4;
        %            end
        %
        %        end
        %        function [pSynthHD] = PowerdBtoSynthHD(obj,pdB)
        %            if (pdB<-60)
        %                pdB = -60;
        %            end
        %            if (pdB>18)
        %                pdB = 18;
        %            end
        %
        %            if pdB>10
        %                pSynthHD=round(2.101e-11*pdB^(11.83)+26110);
        %            else
        %                pSynthHD=round(233.4*pdB+21520);
        %            end
        %
        %        end
        
    end
    
    methods (Static)
        function obj = getInstance(struct)
            type = struct.type;     % We already know it exists
            
            missingField = FactoryHelper.usualChecks(struct, ...
                FrequencyGeneratorSRS.NEEDED_FIELDS);
            if ~isnan(missingField)
                EventStation.anonymousError(...
                    'Trying to create a %s frequency generator, encountered missing field - "%s". Aborting',...
                    type, missingField);
            end
            
            name = [lower(type), 'FrequencyGenerator'];
            obj = FrequencyGeneratorSRS(name, struct.address);
            addBaseObject(obj);
        end
        
        function command = nameToCommandName(name)
            switch lower(name)
                case {'channel','chan'}
                    command = 'C';
                case {'enableoutput','output','enable'}
                    command='r';
                case {'frequency','freq','f'}
                    command='f';
                case {'amplitude','ampl','a'}
                    command='W';
                otherwise
                    error('Unknown command type %s',name)
            end
        end
    end
    
end

