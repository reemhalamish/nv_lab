 classdef ValidationHelper
    %PHYSICSGUARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function bool = isInBorders(valueNumber, minBorder, maxBorder)
            bool = and(all(valueNumber >= minBorder), all(valueNumber <= maxBorder));
        end
        
        function bool = isTrueOrFalse(value)
            bool = (value == 1 || value == 0 || islogical(value));
        end
        
        function bool = isValuePositiveInteger(inputValue)
            % Checks if a string\numeric value is a positive integer
            if ischar(inputValue)
                value = str2double(inputValue);
            else
                value = inputValue;
            end
            if (any(isnan(value)) || any(mod(value,1)) ~= 0 || any(value <= 0))
                bool = false;
            else
                bool = true;
            end
        end
        
        function bool = isStringValueANumber(stringValues)
            % Checks if all the string values are inside the borders
            % stringValues - can be a string or a cell string
            value = str2double(stringValues);
            bool = ~any(isnan(value));
        end
        
        function bool = isStringValueInBorders(stringValues, lowerBorder, upperBorder)
            % Checks if all the string values are inside the borders
            % stringValues - can be a string or a cell string
            value = str2double(stringValues);
            if any(isnan(value)) || any(value < lowerBorder) || any(value > upperBorder)
                bool = false;
            else
                bool = true;
            end
        end
        
        function bool = isValuePositive(stringValues)
            % Checks if the value written in a string is a positive number
            % stringValues - can be a string or a cell string
            value = str2double(stringValues);
            if any(isnan(value)) || any(value <= 0)
                bool = false;
            else
                bool = true;
            end
        end
        
        function bool = isValueNonNegative(stringValues)
            % Checks if the value written in a string is a positive number
            % stringValues - can be a string or a cell string
            bool = ValidationHelper.isStringValueInBorders(stringValues, 0, inf);
        end
        
    end
    
end

