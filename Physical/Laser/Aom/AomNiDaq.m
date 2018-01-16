classdef AomNiDaq < LaserPartAbstract & NiDaqControlled
    %AOMNIDAQ Laser controlled by NiDaq
    
    properties
        niDaqChannel;
    end
    
    properties(Constant)
        NEEDED_FIELDS = {'channel'};
    end
    
    methods
        % constructor
        function obj = AomNiDaq(name, niDaqChannel)            
            obj@LaserPartAbstract(name);
            obj@NiDaqControlled(name, niDaqChannel);
            obj.niDaqChannel = niDaqChannel;
            obj.initLaserPart();
        end
        
        function out = canSetValue(obj) %#ok<*MANU>
            out = true;
        end
        
        function out = canSetEnabled(obj)
            out = false;
        end
    end
    
    methods(Access = protected)
        function out = setValueRealWorld(obj, newValue)
            niDaq = getObjByName(NiDaq.NAME);
            niDaq.writeVoltage(obj.name, newValue);
            out = true;
        end
        
        function out = setEnabledRealWorld(obj, newValue) %#ok<*INUSD>
            out = false;
        end
    end
    
    methods
        function onNiDaqReset(obj, niDaq)
            % This function jumps when the NiDaq resets
            % Each component can decide what to do
            obj.setValue(obj.currentValue);
        end
    end
    
    methods(Static)
        function obj = create(name, jsonStruct)
            missingField = FactoryHelper.usualChecks(jsonStruct, AomNiDaq.NEEDED_FIELDS);
            if ~isnan(missingField)
                error(['While trying to create an AOM part for laser "%s",', ...
                    'could not find "%s" field. Aborting'], ...
                    name, missingField);
            end
            
            niDaqChannel = jsonStruct.channel;
            obj = AomNiDaq(name, niDaqChannel);
        end
    end
    
end