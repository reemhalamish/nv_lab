classdef DeveloperFunctions
    %DEVELOPERFUNCTIONS Functions for developers, which have special access
    %to some of the functions, that others don't
    
    properties
    end
    
    methods (Static)
        function map = GetBaseObjectMap
            % For debug mode: gives map of all existing BaseObjects
            
            handle = BaseObject.allObjects;
            map = handle.wrapped;
            
        end
    end
    
end

