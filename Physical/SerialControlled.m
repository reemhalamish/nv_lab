classdef SerialControlled < matlab.mixin.SetGet
    %SERIALCONTROLLED Object controlled via serial (RS232) connection
    % This object behaves similarly to a serial object, but adjusted for
    % our purposes
    
    properties (Hidden)
        s   % serial. MATLAB representation of the connection
    end
    
    properties (Dependent)
        status
    end
    
    properties
        keepConnected  % logical. Should this connection stay open
        
        % properties of s we want available
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
            obj.s = serial(port);
            
            % We want to "inherit" the serial object, but only selected methods & properties
            obj.port = obj.s.Port;
            obj.baudRate = obj.s.BaudRate;
            obj.dataBits = obj.s.DataBits;
            obj.stopBits = obj.s.StopBits;
            obj.parity = obj.s.Parity;
            obj.flowControl = obj.s.FlowControl;
            obj.terminator = obj.s.Terminator;
        end
        
        function open(obj)
            fopen(obj.s);
        end
        
        function close(obj)
            fclose(obj.s);
        end
        
        function delete(obj)
            delete(obj.s);
        end
        
        function varargout = sendCommand(obj, command)
            if ~ischar(command)
                error('Command should be a string! Cannot send command to device.')
            end
            nargoutchk(0,1)     % Check number of output arguments
            
            if ~obj.keepConnected
                obj.open;
            end
            fprintf(obj.s, command);
            if nargout == 1
                varargout = {fscanf(obj.s)};
            end
            if ~obj.keepConnected
                obj.close;
            end
        end
        
        function string = read(obj, format) % wrapper method
            if exist('format', 'var')
                string = fscanf(obj.s, format);
            else % Realy, you should readAll. But just in case...
                string = fscanf(obj.s);
            end
        end
        
        function string = readAll(obj)
            string = [];
            while obj.s.BytesAvailable > 1    % Might have one char, without terminator
                temp = fscanf(obj.s);
                string = [string temp]; %#ok<AGROW>
            end
        end
    end
    
    methods % Setters & getters
        % setters
        function set(obj, varargin)
            % Validity of values is not checked here, It should be
            % done by programmer, or obj.s will alert about it.
            set(obj.s, varargin{:});
        end
        
        function value = get(obj, varargin)
            value = get(obj.s, varargin{:});
        end
        
        function set.keepConnected(obj, value)
            assert(islogical(value), 'keepConnected must be logical (true/false)!')
                obj.keepConnected = value;
        end
        
        % getters
        function status = get.status(obj)
            status = obj.s.Status;
        end
    end
    
end

