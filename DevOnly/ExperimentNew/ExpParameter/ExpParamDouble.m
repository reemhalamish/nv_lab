classdef (Sealed) ExpParamDouble < double & ExpParameter
    %EXPPARAMDOUBLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        type = ExpParameter.TYPE_DOUBLE;
    end
    
    methods
        function obj = ExpParamDouble(name, value, expName)
            obj@ExpParameter(name, value, expName);
        end
    end
    
    methods (Static)
        function isOK = validateValue(value)
            % Check if a new value is valid, according to obj.type
            isOK = isnumeric(value);
        end
    end
end

