classdef JsonInfoReader
    %MAINJSONINFOREADER reads the main JsonInfo setup-file
    
    
    properties
    end
    
    methods (Static)
        function jsonStruct = getJson()
            %%%% get the json %%%%
            jsonTxt = fileread('C:\\lab\\setupInfo.json');
            jsonStruct = jsondecode(jsonTxt);
            
            %%%% add extra fields %%%%
            if ~isfield(jsonStruct, 'debugMode')
                jsonStruct.debugMode = false;
            end
        end
        
        function [f, minim, maxim, units] = getFunctionFromLookupTable(tabl)
            % Creates linear interpolation from lookup table.
            %
            % table - string. Path of lookup table file
            arr = importdata(tabl);
            data = arr.data;
            percentage = data(:,1);
            physicalValue = data(:,2);
            f = @(x) interp1(percentage, physicalValue, x);
            
            minim = min(percentage);
            maxim = max(percentage);
            headers = arr.colheaders;
            if size(headers)>=2
                units = headers{2};
            else
                units = '';
            end
        end
    end
    
end

