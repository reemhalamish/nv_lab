classdef Tilda
    %TILDA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function setDefaultsIfNotExist(obj, arg1, arg2, arg3)
            if ~exist('arg1', 'var') || isempty(arg1); arg1 = 1; end
            if ~exist('arg2', 'var') || isempty(arg2); arg2 = 2; end
            if ~exist('arg3', 'var') || isempty(arg3); arg3 = 3; end
            
            obj.display2(arg1, arg2, arg3)
        end
        
        function display2(obj, arg1, arg2, arg3)
            vector = [arg1, arg2, arg3];
            disp(vector)
        end
    end
    
end

