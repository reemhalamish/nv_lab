classdef StringHelper
    %STRINGHELPER Useful functions for strings
    
    properties (Constant)
        % Useful html codes, to be used in GUI with sprintf
        MICRON = sprintf('[\x03bcm]');
        DELTA = sprintf('\x0394');
        LEFT_ARROW = sprintf('\x2190');
        RIGHT_ARROW = sprintf('\x2192');
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
            % uses regex (regular expressions) to remove trailing zeros in
            % the beginning of strings which represents numbers
            string = regexprep(numString,'^0*','');     % remove 0's @beginning
            if strfind(string,'.') == 1                 % We removed one 0 too many
                string = strcat('0',string);
            end
            string = regexprep(string,'\.*0+$','');     % remove 0's @end (+decimal point, if unneeded)
        end
        
        function [string, roundedNum] = formatNumber(num, decimalDigits)
            % Formats variable num (of any of the number types) as string,
            % while removing trailing zeros. Optionally, returns also the
            % rounded number as double.
            % If not specified, variables of type double will have 3
            % decimal digits (at most)
            
            if ~exist('decimalDigits','var')
                decimalDigits = 3;
            end
            roundedNum = round(num, decimalDigits);
            stringWithZeros = sprintf('%f', roundedNum);
            string = regexprep(stringWithZeros, '\.*0+$', '');     % remove 0's @end (+decimal point, if unneeded)
            
            if strcmp(string, '-0'); string='0'; end
        end
    end
end

