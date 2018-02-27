classdef PulseGenerator < EventSender
    %PULSEGENERATOR Class for creating a pulse generator
    % For now, it is a wrapper for the old PulseStreamerClass &
    % PulseBlasterClass.
    %   todo: make it an abstract class, from which both the pulse-blaster
    %   and -streamer inherit
    
    properties (SetAccess = private)
        % This information seems unavailable in the PS & PB classes. This
        % is (hopefully) a *temporary* patch
        isOn = struct();	
    end
    
    properties (Access = private)
        pulseGeneratorPrivate
        type
    end
    
    properties (Constant)
        NAME = 'pulseGenerator'
        
        NAME_PULSE_BLASTER = 'pulseBlaster'
        NAME_PULSE_STREAMER = 'pulseStreamer'
    end
    
    methods
        function obj = PulseGenerator(struct)
            name = PulseGenerator.NAME;
            obj@EventSender(name);
            
            removeObjIfExists(name);
            addBaseObject(obj);  % so it can be reached by getObjByName(PulseGenerator.NAME)
            
            obj.type = obj.generatorType(struct);

            if isfield(struct, 'dummy')
                obj.pulseGeneratorPrivate = PulseGeneratorDummyClass.GetInstance;
            else
                switch obj.type
                    case obj.NAME_PULSE_BLASTER
                        obj.pulseGeneratorPrivate = PulseBlasterClass.GetInstance;
                    case obj.NAME_PULSE_STREAMER
                        obj.pulseGeneratorPrivate = PulseStreamerClass.GetInstance;
                end
            end
        end     % constructor
    end
    
    %% wrapper methods
    methods 
        function on(obj, channel)
            obj.pulseGeneratorPrivate.On(channel);
            obj.isOn.(channel) = true;
        end
        
        function off(obj)
            obj.pulseGeneratorPrivate.Off;
            StructHelper.setAllFields(obj.isOn, false);
        end
        
        function ind = name2index(obj, name)
            ind = obj.pulseGeneratorPrivate.Index(name);
        end
    end

    %%
    methods (Static)
        function create(struct)
            try
                type = PulseGenerator.generatorType(struct);
                getObjByName(type);
            catch
                PulseGenerator(struct);
            end
            
            PG = getObjByName(PulseGenerator.NAME);
            names = struct.channelNames;
            values = struct.channelValues;
            PG.pulseGeneratorPrivate.setChannelNameAndValue(names, values);
        end
        
        function type = generatorType(struct)
            % type - string. Type of pulse generator. For now, either
            % 'pulseBlaster' or 'pulseStreamer'
            if ~isfield(struct, 'type')
                type = PulseGenerator.NAME_PULSE_BLASTER;
            else
                type = struct.type;
            end
        end
    end
end

