classdef PulseGenerator < EventSender
    %PULSEGENERATOR Class for creating a pulse generator
    % For now, it is also a wrapper for the old PulseStreamerClass.
    %   todo: make it an abstract class, from which both the pulse-blaster
    %   and -streamer inherit
    
    properties
        type
    end
    
    properties
        pulseStreamer
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
            
            obj.type = obj.generatorType(struct);
            switch obj.type
                case obj.NAME_PULSE_BLASTER
                    PulseBlaster.create(struct);
                case obj.NAME_PULSE_STREAMER
                    removeObjIfExists(name);
                    addBaseObject(obj);  % so it can be reached by getObjByName(PulseGenerator.NAME)
                    obj.pulseStreamer = obj.createPulseStreamer(struct);
            end
        end
    end

    methods (Static)
        function create(struct)
            try
                type = PulseGenerator.generatorType(struct);
                getObjByName(type);
            catch
                PulseGenerator(struct);
            end
            switch type
                case PulseGenerator.NAME_PULSE_STREAMER
                    PG = getObjByName(PulseGenerator.NAME);
                    names = struct.channelNames;
                    values = struct.channelValues;
                    PG.pulseStreamer.setChannelNameAndValue(names, values);
                case PulseGenerator.NAME_PULSE_BLASTER
                    warning('You will have to add channels to the pulseBlaster manually')
            end
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
    
    %% PulseStreamer Control
    
    methods
        % Exists here for now, in order not to interact with Old class
        % Experiment
    function ps = createPulseStreamer(~, psstruct)
            % create a new instance of the pulse streamer, to be retreived
            % via getInstance()
            % 
            % "psStruct" - a struct. 
            % If the struct contains the optional property "dummy" with the value true, 
            % no actual physics will be involved. Good for testing purposes
            % If "dummy" isn't in the struct, it will be considered as false
            %
            if ~isfield(psstruct, 'libPathName')
                error('"libPathName must be in the struct! (pulse streamer)')
            end
            
            if isfield(psstruct, 'dummy')
                ps = PulseStreamerClass.GetInstance;
            else
                ps = PulseStreamerClass.GetInstance;
            end
        end
    end
        
    
end

