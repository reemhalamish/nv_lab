classdef (Sealed) ExpParamDoubleVector < ExpParameter
    %EXPPARAMDOUBLEVECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        type = ExpParameter.TYPE_VECTOR_OF_DOUBLES
    end
    
    methods
        function obj = ExpParamDoubleVector(name, value, expName)
            obj@ExpParameter(name, value, expName);
        end
    end
    
    methods (Static)
        function isOK = validateValue(value)
            % Check if a new value is valid, according to obj.type
            isOK = isnumeric(value) && ~iscalar(value);
        end
    end
    
end

