classdef deletedParent < handle
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        a
    end
    
    methods
        function obj = deletedParent
            obj@handle;
            obj.a = deleted;
        end
    end
    
end

