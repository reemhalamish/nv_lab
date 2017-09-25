classdef PropertiesDisplaySorted < handle & matlab.mixin.CustomDisplay
    %DISPLAYPROPERTIESSORTED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = PropertiesDisplaySorted
            obj@handle;
            obj@matlab.mixin.CustomDisplay;
        end
        
        function stringCell = getAllConstProperties(obj)
             mc = metaclass(obj);
            allProps = mc.PropertyList;
            stringCell = sort({allProps(and(not([allProps.Hidden]) ,[allProps.Constant])).Name});
        end
        
        function stringCell = getAllNonConstProperties(obj)
            mc = metaclass(obj);
            allProps = mc.PropertyList;
            
            stringCell = sort({allProps(and(not([allProps.Hidden]) ,not([allProps.Constant]))).Name});
        end
    end
    
    % from matlab.mixin.CustomDisplay
    % https://www.mathworks.com/help/matlab/matlab_oop/use-cases.html
    methods (Access = protected)
        function propgrp = getPropertyGroups(obj)
            % show only the NON-CONST properties
            propgrp = matlab.mixin.util.PropertyGroup(obj.getAllNonConstProperties);
        end
    end
end

