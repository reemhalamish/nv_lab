classdef deleted < handle
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = deleted
            obj@handle
        end
        
        function delete(obj)
            disp('im deleted!')
        end
    end
    
end

