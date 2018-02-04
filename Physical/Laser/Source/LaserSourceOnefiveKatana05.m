classdef LaserSourceOnefiveKatana05 < LaserPartAbstract & SerialControlled
    %LASERSOURCEDUMMY dummy laser in which everything works
    
    properties
        COMMAND_ON = 'leg=0'
        COMMAND_OFF = 'leg=1'
        
        COMMAND_POWER_TAKE_CONTROL = 'lps=1'
        COMMAND_POWER_GIVE_CONTROL = 'lps=0'
        COMMAND_POWER_FORMAT_SPEC = 'lp=%4.2f'
        COMMAND_POWER_QUERY = 'lp ?'
    end
    
    methods
        % constructor
        function obj = LaserSourceOnefiveKatana05(name)
            obj@LaserPartAbstract(name);
            baudRate = 38400;
            dataBits = 8;
            stopBits = 1;
            parity = 'none';
            flowControl = 'none';
            terminator = 'LF';
            obj@SerialControlled('COM4', baudRate, dataBits, stopBits, parity, flowControl, terminator);
            obj.initLaserPart();
        end
        
        function out = canSetValue(obj) %#ok<MANU>
            out = true;
        end
        
        function out = canSetEnabled(obj) %#ok<MANU>
            out = true;
        end
    end
    
    methods(Access = protected)
        function setEnabledRealWorld(obj, newBoolValue)
            switch newBoolValue
                case true
                    obj.sendCommand(obj.COMMAND_ON);
                case false
                    obj.sendCommand(obj.COMMAND_OFF);
                otherwise
                    error('Value must be either true or false! Nothing happenned.')
            end
        end
        
        function setValueRealWorld(obj, newValue)
            obj.sendCommand(obj.COMMAND_POWER_TAKE_CONTROL);
            commandPower = sprintf(obj.COMMAND_POWER_FORMAT_SPEC, newValue);
            obj.sendCommand(commandPower);
            obj.sendCommand(obj.COMMAND_POWER_GIVE_CONTROL);
        end
    end
    
end

