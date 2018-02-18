classdef AomNiDaqControlled < LaserPartAbstract & NiDaqControlled
    %AOMNIDAQCONTROLLED Laser controlled by NiDaq
    
    properties
        niDaqChannel;

        canSetEnabled = true;
        canSetValue = false;  
    end
    
    properties (Access = private)
        valuePrivate
    end
    
    properties(Constant)
        NEEDED_FIELDS = {'channel'};
    end
    
    methods
        % constructor
        function obj = AomNiDaqControlled(name, niDaqChannel)            
            obj@LaserPartAbstract(name);
            obj@NiDaqControlled(name, niDaqChannel);
            obj.niDaqChannel = niDaqChannel;
            obj.initLaserPart();
        end
    end
    
    methods(Access = protected)
        function setValueRealWorld(obj, newValue)
            niDaq = getObjByName(NiDaq.NAME);
            niDaq.writeVoltage(obj.name, newValue);
            obj.valuePrivate = newValue;        % patch. see obj.getValueRealWorld()
        end
        
        function out = setEnabledRealWorld(obj, newValue) %#ok<*INUSD>
            out = false;
        end
    end
    
    methods
        function value = getValueRealWorld(obj)
            value = obj.valuePrivate;           % patch. todo: actually read value from NiDaq
        end
    end
    
    methods
        function onNiDaqReset(obj, niDaq)
            % This function jumps when the NiDaq resets
            % Each component can decide what to do
            obj.setValue(obj.value);
        end
    end
    
    methods(Static)
        function obj = create(name, jsonStruct)
            missingField = FactoryHelper.usualChecks(jsonStruct, AomNiDaqControlled.NEEDED_FIELDS);
            if ~isnan(missingField)
                error(['While trying to create an AOM part for laser "%s",', ...
                    'could not find "%s" field. Aborting'], ...
                    name, missingField);
            end
            
            niDaqChannel = jsonStruct.channel;
            obj = AomNiDaqControlled(name, niDaqChannel);
        end
    end
    
end