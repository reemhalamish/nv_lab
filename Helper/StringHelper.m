classdef StringHelper
    %STRINGHELPER usefull functions with strings
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static = true)
        function booleanAnswer = isAllCapsAndUnderscore(string)
            booleanAnswer = strcmp(string, upper(string));
        end
        
        function newCell = getOnlyUpperCaseStrings(cellOfStrings)
            find = cellfun(@(x) strcmp(x, upper(x)), cellOfStrings);
            newCell = cellOfStrings(find);
        end
        
        function newCell = getAllExceptUpperCaseStrings(cellOfStrings)
            find = cellfun(@(x) ~strcmp(x, upper(x)), cellOfStrings);
            newCell = cellOfStrings(find);
        end
    end
    
end

