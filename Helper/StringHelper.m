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
        
        function string = removeTrailingZeros(numString)
            string = regexprep(numString,'^0*','');     % remove 0's @beginning
            if strfind(string,'.') == 1              % We removed one 0 too many
                string = strcat('0',string);
            end
            string = regexprep(string,'\.*0+$','');     % remove 0's @end (+decimal point, if unneeded)
        end
    end
    
end

