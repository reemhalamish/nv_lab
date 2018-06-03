classdef (Sealed) ExpParamLogical < ExpParameter
    %EXPPARAMLOGICAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        type = ExpParameter.TYPE_LOGICAL;
    end
   
    methods
        function obj = ExpParamLogical(name, value, expName)
            obj@ExpParameter(name, value, expName);
        end
        
    end
    
    methods (Static)
        function isOK = validateValue(value)
            % Check if a new value is valid, according to obj.type
            isOK = ValidationHelper.isTrueOrFalse(value);
        end
    end
    
end

