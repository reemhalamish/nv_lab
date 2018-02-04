classdef SerialControlled < matlab.mixin.SetGet
    %SERIALCONTROLLED Object controlled via serial (RS232) connection
    
    properties (Hidden)
        serialObj   % serial. MATLAB representation of the connection
        
        keepConnected  % logical. Should this connection stay open
    end
    
    properties (Dependent)
        port
        baudRate
        dataBits
        stopBits
        parity
        flowControl
        terminator
    end
    
    methods
        function obj = SerialControlled(port)
            obj@matlab.mixin.SetGet;
            obj.serialObj = serial(port);
        end
        
        function set(obj, varargin)
            % Validity of values is not checked, and should be
            % done by programmer, or MATLAB will alert about it.
            set(obj.serialObj, varargin);
        end
        
        function value = get(obj, varargin)
            value = get(obj.serialObj, varagin);
        end
        
        function open(obj)
            fopen(obj.serialObj);
        end
        
        function close(obj)
            fclose(obj.serialObj);
        end
        
        function delete(obj)
            delete(obj.serialObj);
        end
        
        function varargout = sendCommand(obj, command)
            if ~ischar(command)
                error('Command should be a string! Cannot send command to device.')
            end
            nargoutchk(0,1)     % Check number of out arguments
            if ~obj.keepConnected
                obj.open;
            end
            fprintf(obj.serialObj, command);
            if nargout == 1
                varargout = fscanf(obj.serialObj);
            end
            if ~obj.keepConnected
                obj.close;
            end
        end
    end
    
end

