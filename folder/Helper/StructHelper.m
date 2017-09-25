classdef StructHelper
    %STRUCTHELPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant = true)
        WHITESPACES_STRUCT_DISP_AMNT = 4
    end
    
    methods(Static)
        function string = structAsString(inputStruct)
            % returns a string repr. of the input struct, which can hold
            % some nested structures inside.
            %
            % inputStruct - one struct. not array.
            %
            string = StructHelper.recGetStructOut(inputStruct, 0);
        end
    end
    
    methods(Static = true, Access = private)
        function string = recGetStructOut(inputStruct, whitespaecesAmount)
            % recuresively get the struct out as a string
            % 
            % inputStruct        - the struct to display
            % whitespaecesAmount - the amount od whitespaces to show before
            %                      every line
            %
            fields = fieldnames(inputStruct);
            string = '';
            whitespaces = repmat(sprintf(' '), 1,whitespaecesAmount);
            for i = 1 : length(fields)
                fieldCell = fields(i);
                field = fieldCell{:};
                value = inputStruct.(field);
                if ischar(value)
                    fieldStr = value;
                elseif islogical(value)
                    if value
                        fieldStr = 'true';
                    else
                        fieldStr = 'false';
                    end
                elseif isnumeric(value)
                    fieldStr = num2str(value);
                elseif isstruct(value)
                    fieldStr = sprintf('\n%s', StructHelper.recGetStructOut(value, whitespaecesAmount + StructHelper.WHITESPACES_STRUCT_DISP_AMNT));
                else
                    fieldStr = 'ERROR: UNKNOWN!';
                end
                line = sprintf('%s%s : %s\n', whitespaces, field, fieldStr);
                string = sprintf('%s%s', string, line);
            end
            
            string = string(1 : end - 1);  % remove last end-line ('\n')     
        end
    end
end

